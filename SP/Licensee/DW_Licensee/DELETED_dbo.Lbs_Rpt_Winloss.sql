USE [bodb_Licensee]

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Lbs_Rpt_Winloss]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Lbs_Rpt_Winloss]
GO

CREATE PROCEDURE [dbo].Lbs_Rpt_Winloss
	@LicenseeID int
	,@FromDate smalldatetime
	,@ToDate smalldatetime
	,@SportType tinyint=0
	,@BetType tinyint=0
	,@CurrencyID int
	,@IsLive bit
	,@ReportBy tinyint
	,@MovingBetDay smalldatetime
	,@PageIndex int =1
	,@PageSize int =-1	
	,@IsTotalRow bit=0
	,@Debug bit =0
AS
/*
Created: Elly
Task : Get winloss for a licensee

DB: bodb_Licensee
Original:

Revisions:	
	
Param's Explanation:
	*@CurrencyID int
		-3: based MYR
		-2: base EURO
		-1: base USD
		>0: filter by a specific CurrencyID
	*@IsLive
		0: non live bet
		1: live bet
		NULL: all
	*@SportType
		0: all sport type
		>0: a specific sport type
	*@BetType
		0: all bet type
		>0: a particular bet type			
	*@ReportBy
		1: Daily
		2: Weekly
		3: Monthly
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @sql nvarchar(max)
		,@Select nvarchar(1000)
		,@From nvarchar(max)
		,@Where nvarchar(4000)		
		,@GroupBy nvarchar(500)
		,@OrderBy nvarchar(500)
		,@ReportPeriod nvarchar(100)		
		,@SubWhere1 nvarchar(1000)
		,@SubWhere2 nvarchar(1000)
--select * from bodb02.dbo.ExchangeDaily
	SELECT 			
		@ReportPeriod=CASE @ReportBy
				WHEN 1 THEN 'ReportDate' --Daily		
				WHEN 2 THEN '''Week '' + DATENAME(WW,ReportDate) + '', '' + DATENAME(YYYY,ReportDate)' --Weekly
				WHEN 3 THEN 'DATENAME(M,ReportDate) + '' '' + DATENAME(YYYY,ReportDate)' --Monthly
			END
		
		,@SubWhere1= CASE 
				WHEN @IsLive IS NULL THEN '1=1'
				ELSE 'liveindicator=@IsLive'
			END
		,@SubWhere2= CASE 
				WHEN @IsLive IS NULL THEN '1=1'
				ELSE 'IsLive=@IsLive'
			END				
	
	IF @BetType>0
	BEGIN
		SELECT		
			@SubWhere1=@SubWhere1+'
							AND b1.bettype=@BetType'				
			,@SubWhere2=@SubWhere2+'
							AND b2.bettype=@BetType'
	END
	ELSE
		SELECT 
			@SubWhere1=@SubWhere1+'
							AND 1=1'
			,@SubWhere2=@SubWhere2+'
							AND 1=1'	
			
	SELECT 
			@SubWhere1=@SubWhere1+'
							AND ' + 
			CASE WHEN @SportType>0 THEN 'EXISTS (SELECT 1
												FROM dbo.match AS m
												WHERE m.matchid=b1.matchid AND m.sporttype=@SportType)'
				ELSE '1=1'
			END
			,@SubWhere2=@SubWhere2+'
							AND ' + 
			CASE WHEN @SportType>0 THEN 'EXISTS (SELECT 1
												FROM bodb02.dbo.league AS l
												WHERE l.leagueid=b2.leagueid AND l.sporttype=@SportType)'
				ELSE '1=1'
			END
	
	SELECT @SubWhere1=@SubWhere1+'
							AND EXISTS(SELECT 1
									FROM bodb02.dbo.customer c with (nolock)
										INNER JOIN bodb02.dbo.Site ibcsite with (nolock) on c.site=ibcsite.site
											AND b1.recommend = c.custid and c.roleid = 2
										INNER JOIN dbo.view_site_list [site] with (nolock) on ibcsite.siteid=site.IbcSiteID
											AND [site].siteid=@LicenseeID)'
		,@SubWhere2=@SubWhere2+'
							AND b2.SiteID=@LicenseeID'				
						
	
	SELECT @SubWhere1=@SubWhere1+'
							AND '+
			CASE 
				WHEN @CurrencyID>0 THEN 'b1.currency=@CurrencyID'
				ELSE '1=1'
			END
		,@SubWhere2=@SubWhere2+'
							AND '+
			CASE 
				WHEN @CurrencyID>0 THEN 'b2.CurrencyID=@CurrencyID'
				ELSE '1=1'
			END			
	SELECT 
		@From=
		CASE 
			WHEN @MovingBetDay<@FromDate --get all data from bettran
				THEN 
					'(SELECT winlostdate AS ReportDate
						,currency AS CurrencyID						
						,SUM(stake) AS Turnover
						,SUM(winlost-actual_stake) AS WinLoss
						,SUM(playercomm) AS Comm
						,SUM(winlost-actual_stake+awinlost+mwinlost+swinlost) AS Fee
						,COUNT(1) AS BetCount
					FROM bodb02.dbo.bettrans AS b1 WITH(NOLOCK)
					WHERE winlostdate BETWEEN @FromDate AND @ToDate						
						AND bettype <19999
						AND '+@SubWhere1+'	
					GROUP BY winlostdate,currency
					) AS t'						
			WHEN @MovingBetDay>=@FromDate AND @MovingBetDay<@ToDate --get data from both bettran and rpt_Betting
				THEN 
					'(SELECT rptdate AS ReportDate
						,CurrencyID
						,SUM(Turnover) AS Turnover
						,SUM(WinLoss) AS WinLoss
						,SUM(Comm) AS Comm
						,SUM(Fee) AS Fee
						,SUM(BetCount) AS BetCount
					FROM dbo.rpt_Betting AS b2 WITH(NOLOCK)	
					WHERE $PARTITION.pf_rptBetting_monthly(rptdate) BETWEEN $PARTITION.pf_rptBetting_monthly(@FromDate) AND $PARTITION.pf_rptBetting_monthly(@MovingBetDay)
						AND rptdate BETWEEN @FromDate AND @MovingBetDay
						AND '+@SubWhere2+'
					GROUP BY rptdate,CurrencyID
					
					UNION ALL
					
					SELECT winlostdate AS ReportDate
						,currency AS CurrencyID						
						,SUM(stake) AS Turnover
						,SUM(winlost-actual_stake) AS WinLoss
						,SUM(playercomm) AS Comm
						,SUM(winlost-actual_stake+awinlost+mwinlost+swinlost) AS Fee
						,COUNT(1) AS BetCount		
					FROM bodb02.dbo.bettrans AS b1 WITH(NOLOCK)
					WHERE b1.winlostdate>@MovingBetDay AND b1.winlostdate<=@ToDate
						AND bettype <19999
						AND '+@SubWhere1+'
					GROUP BY winlostdate,currency					
					)AS t'
			ELSE --get all data from rpt_Betting
					'(SELECT rptdate AS ReportDate
						,CurrencyID
						,SUM(Turnover) AS Turnover
						,SUM(WinLoss) AS WinLoss
						,SUM(Comm) AS Comm
						,SUM(Fee) AS Fee
						,SUM(BetCount) AS BetCount
					FROM dbo.rpt_Betting AS b2 WITH(NOLOCK)	
					WHERE $PARTITION.pf_rptBetting_monthly(rptdate) BETWEEN $PARTITION.pf_rptBetting_monthly(@FromDate) AND $PARTITION.pf_rptBetting_monthly(@ToDate)
						AND rptdate BETWEEN @FromDate AND @ToDate
						AND '+@SubWhere2+'
					GROUP BY rptdate,CurrencyID
					) AS t'
		END
	
	SELECT @From=@From+'
				INNER JOIN bodb02.dbo.ExchangeDaily AS e ON e.ExchangeID=t.CurrencyID
					AND e.ExchangeDate=t.ReportDate'
					
						
	SELECT 
		@Select =@ReportPeriod+' AS ReportDate
					,t.Currency
					,SUM(t.Turnover*t.ExchangeRate) AS Turnover
					,SUM(t.Winloss*t.ExchangeRate) AS Winloss
					,SUM(t.Comm*t.ExchangeRate) AS Comm
					,SUM(t.Fee*t.ExchangeRate) AS Fee
					,SUM(t.BetCount) AS TransactionCount'
		,@From='
				(SELECT t.ReportDate
					,'+CASE @CurrencyID WHEN -1 THEN '''USD'''
						WHEN -2 THEN '''EUR'''
						WHEN -3 THEN '''MYR'''
						ELSE 'e.Code'
						END +' AS Currency
					,t.Turnover
					,t.WinLoss
					,t.Comm
					,t.Fee
					,t.BetCount
					,'+CASE @CurrencyID WHEN -1 THEN 'e.USD'
						WHEN -2 THEN 'e.EUR'
						WHEN -3 THEN 'e.MYR'
						ELSE '1.0'
						END +' AS ExchangeRate
				FROM '+@From + '				
				) AS t'
		,@Where ='1=1'
		,@GroupBy=@ReportPeriod+',Currency'
		,@OrderBy = CASE @ReportBy
			WHEN 3 THEN 'DATEPART(M,ReportDate)'
				ELSE 'ReportDate'
			END
	SET @From='
			(SELECT '+@Select+'
			FROM '+@From+'
			WHERE '+@Where+'
			GROUP BY '+@GroupBy+'
			) AS t'
	
	SET @sql=''
	
	IF @IsTotalRow =1
			SET @sql =@sql+
				'SELECT COUNT(1) AS TotalRow'+CHAR(10)+
				'FROM '+@From
				
	ELSE --@IsTotalRow =0
	BEGIN			
		IF @PageSize>0 --paging
		BEGIN			
			SET @sql =@sql+
				'WITH Paging AS 
					(SELECT
					ROW_NUMBER() OVER(ORDER BY '+@OrderBy+') AS RowNumber
					,*
					FROM '+@From+'
					)
					SELECT *
					FROM Paging
					WHERE RowNumber BETWEEN (@PageIndex-1)*@PageSize+1 AND @PageIndex*@PageSize'
		
		END
		ELSE
			SET @sql =@sql+
					'SELECT *'+CHAR(10)+
					'FROM '+@From+CHAR(10)+					
					'ORDER BY '+@OrderBy
	END -- @IsTotalRow =0
	IF @Debug =1
	BEGIN
		PRINT @sql
		SELECT @FromDate
			,@ToDate
			,@SportType
			,@BetType
			,@MovingBetDay							
			,@IsLive
			,@CurrencyID
	END	
	--ELSE
		EXEC sp_executesql @sql,N'@LicenseeID int
								,@FromDate smalldatetime
								,@ToDate smalldatetime
								,@SportType tinyint=0
								,@BetType tinyint=0
								,@MovingBetDay smalldatetime								
								,@IsLive bit
								,@CurrencyID int
								,@PageIndex int
								,@PageSize int'
								,@LicenseeID
								,@FromDate
								,@ToDate
								,@SportType
								,@BetType
								,@MovingBetDay							
								,@IsLive
								,@CurrencyID
								,@PageIndex
								,@PageSize
		
	SET NOCOUNT OFF
END
/*
--non paging
EXEC dbo.Lbs_Rpt_Winloss
		@LicenseeID=1
		,@FromDate='2011-01-01'
		,@ToDate='2011-07-10'
		,@SportType=1
		,@BetType=1		
		,@IsLive=NULL
		,@ReportBy=1
		,@MovingBetDay='2011-07-01'	
		,@CurrencyID=1	
		,@Debug=1

EXEC dbo.Lbs_Rpt_Winloss
		@LicenseeID=1
		,@FromDate='2011-01-01'
		,@ToDate='2011-07-10'
		,@SportType=1
		,@BetType=1		
		,@IsLive=0
		,@ReportBy=2
		,@MovingBetDay='2011-07-01'
		,@CurrencyID=-1
		,@Debug=1

EXEC dbo.Lbs_Rpt_Winloss
		@LicenseeID=1
		,@FromDate='2011-01-01'
		,@ToDate='2011-07-10'
		,@SportType=1
		,@BetType=1		
		,@IsLive=1
		,@ReportBy=3
		,@MovingBetDay='2011-07-01'
		,@CurrencyID=-2
		,@Debug=1
		
EXEC dbo.Lbs_Rpt_Winloss
		@LicenseeID=1
		,@FromDate='2011-07-02'
		,@ToDate='2011-07-10'
		,@SportType=1
		,@BetType=1		
		,@IsLive=1
		,@ReportBy=1
		,@MovingBetDay='2011-07-01'
		,@CurrencyID=-3
		,@Debug=1
--paging
EXEC dbo.Lbs_Rpt_Winloss
		@LicenseeID=1
		,@FromDate='2011-01-01'--'2011-06-26'
		,@ToDate='2011-07-10'
		,@SportType=1
		,@BetType=1		
		,@IsLive=NULL
		,@ReportBy=1
		,@MovingBetDay='2011-07-01'
		,@PageSize=12
		,@PageIndex=1
		,@CurrencyID=-1 --1	
		,@Debug=1

EXEC dbo.Lbs_Rpt_Winloss
		@LicenseeID=1
		,@FromDate='2011-01-01'
		,@ToDate='2011-07-10' --'2011-06-26'
		,@SportType=1
		,@BetType=1		
		,@IsLive=0
		,@ReportBy=2
		,@MovingBetDay='2011-07-01'
		,@PageSize=10
		,@CurrencyID=-1	
		,@Debug=1

EXEC dbo.Lbs_Rpt_Winloss
		@LicenseeID=1
		,@FromDate='2011-01-01'
		,@ToDate='2011-07-01'
		,@SportType=1
		,@BetType=1		
		,@IsLive=1
		,@ReportBy=3
		,@MovingBetDay='2011-07-01'
		,@PageSize=10
		,@CurrencyID=-2	
		,@Debug=1

EXEC dbo.Lbs_Rpt_Winloss
		@LicenseeID=1
		,@FromDate='2011-01-01'
		,@ToDate='2011-07-10'
		,@SportType=1
		,@BetType=1		
		,@IsLive=1
		,@ReportBy=3
		,@MovingBetDay='2011-07-01'
		,@PageSize=10
		,@CurrencyID=-3
		,@Debug=1
--Total Row of paging
EXEC dbo.Lbs_Rpt_Winloss
		@LicenseeID=1
		,@FromDate='2011-07-01'
		,@ToDate='2011-07-10'
		,@SportType=1
		,@BetType=1		
		,@IsLive=NULL
		,@ReportBy=1
		,@MovingBetDay='2011-07-01'
		,@IsTotalRow=1
		,@CurrencyID=-1 --1	
		,@Debug=1

EXEC dbo.Lbs_Rpt_Winloss
		@LicenseeID=1
		,@FromDate='2011-07-01'
		,@ToDate='2011-07-10'
		,@SportType=1
		,@BetType=1		
		,@IsLive=0
		,@ReportBy=2
		,@MovingBetDay='2011-07-01'
		,@IsTotalRow=1
		,@CurrencyID=-1 --1	
		,@Debug=1

EXEC dbo.Lbs_Rpt_Winloss
		@LicenseeID=1
		,@FromDate='2011-01-01'
		,@ToDate='2011-07-10'
		,@SportType=1
		,@BetType=1		
		,@IsLive=1
		,@ReportBy=3
		,@MovingBetDay='2011-07-01'
		,@IsTotalRow=1
		,@CurrencyID=-2 -- -1	
		,@Debug=1

EXEC dbo.Lbs_Rpt_Winloss
		@LicenseeID=1
		,@FromDate='2011-01-01'
		,@ToDate='2011-07-10'
		,@SportType=1
		,@BetType=1		
		,@IsLive=1
		,@ReportBy=3
		,@MovingBetDay='2011-07-01'
		,@IsTotalRow=1
		,@CurrencyID=-3 -- -1	
		,@Debug=1
*/
GO