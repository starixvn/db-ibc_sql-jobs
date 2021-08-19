USE [bodb_Licensee]

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Lbs_Rpt_GetTotalTicket]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[Lbs_Rpt_GetTotalTicket]
GO

CREATE PROCEDURE [dbo].DELETED_Lbs_Rpt_GetTotalTicket
	@LicenseeID int
	,@FromDate smalldatetime
	,@ToDate smalldatetime
	,@SportType tinyint=0
	,@BetType tinyint=0	
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
Task : Get transaction count and transaction cost for a licensee

DB: bodb_Licensee
Original:

Revisions:	
	
Param's Explanation:	
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
		,@ReportPeriod1 nvarchar(100)
		,@ReportPeriod2 nvarchar(100)
		,@SubWhere1 nvarchar(1000)
		,@SubWhere2 nvarchar(1000)

	SELECT @ReportPeriod1=CASE @ReportBy
				WHEN 1 THEN 'winlostdate' --Daily		
				WHEN 2 THEN '''Week '' + DATENAME(WW,winlostdate) + '', '' + DATENAME(YYYY,winlostdate)' --Weekly
				WHEN 3 THEN 'DATENAME(M,winlostdate) + '' '' + + DATENAME(YYYY,winlostdate)' --Monthly
			END
		,@ReportPeriod2=CASE @ReportBy
				WHEN 1 THEN 'rptdate'--Daily
				WHEN 2 THEN '''Week '' + DATENAME(WW,rptdate) + '', '' + DATENAME(YYYY,rptdate)'--Weekly
				WHEN 3 THEN 'DATENAME(M,rptdate) + '' '' + DATENAME(YYYY,rptdate)' --Monthly
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
							
	SELECT 
		@Select ='t.ReportDate
					,t.BetCount AS TransactionCount
					,TransactionCost=t.BetCount*(SELECT TxnRate FROM dbo.Licensees AS l WITH(NOLOCK) WHERE l.LicenseeID=@LicenseeID)'
		,@From=
		CASE 
			WHEN @MovingBetDay<@FromDate --get all data from bettran
				THEN '(SELECT '+@ReportPeriod1+' AS ReportDate
							,COUNT(1) AS BetCount
						FROM bodb02.dbo.bettrans AS b1 WITH(NOLOCK)
						WHERE winlostdate BETWEEN @FromDate AND @ToDate						
							AND bettype <19999
							AND '+@SubWhere1+'	
						GROUP BY '+@ReportPeriod1+'
					) AS t'						
			WHEN @MovingBetDay>=@FromDate AND @MovingBetDay<@ToDate --get data from both bettran and rpt_Betting
				THEN '(
					SELECT ReportDate
						,SUM(BetCount) AS BetCount
					FROM (SELECT '+@ReportPeriod2 +' AS ReportDate
								,SUM(BetCount) AS BetCount
						FROM dbo.rpt_Betting AS b2 WITH(NOLOCK)	
						WHERE $PARTITION.pf_rptBetting_monthly(rptdate) BETWEEN $PARTITION.pf_rptBetting_monthly(@FromDate) AND $PARTITION.pf_rptBetting_monthly(@MovingBetDay)
							AND rptdate BETWEEN @FromDate AND @MovingBetDay
							AND '+@SubWhere2+'
						GROUP BY '+@ReportPeriod2+'
						
						UNION ALL
						
						SELECT '+@ReportPeriod1 +' AS ReportDate
							,COUNT(1) AS BetCount					
						FROM bodb02.dbo.bettrans AS b1 WITH(NOLOCK)
						WHERE b1.winlostdate > @MovingBetDay AND b1.winlostdate<=@ToDate
							AND bettype <19999
							AND '+@SubWhere1+'
						GROUP BY '+@ReportPeriod1+'
						) AS t1
					GROUP BY ReportDate
					)AS t'
			ELSE --get all data from rpt_Betting
				'(SELECT '+@ReportPeriod2 +' AS ReportDate
						,SUM(BetCount) AS BetCount
				FROM dbo.rpt_Betting AS b2 WITH(NOLOCK)	
				WHERE $PARTITION.pf_rptBetting_monthly(rptdate) BETWEEN $PARTITION.pf_rptBetting_monthly(@FromDate) AND $PARTITION.pf_rptBetting_monthly(@MovingBetDay)
					AND rptdate BETWEEN @FromDate AND @ToDate
					AND '+@SubWhere2+'
				GROUP BY '+@ReportPeriod2+'
				) AS t'
		END
		,@Where ='1=1'
		,@OrderBy = CASE @ReportBy
			WHEN 3 THEN 'DATEPART(M,ReportDate)'
				ELSE 'ReportDate'
			END
	SET @sql =''
	
	IF @IsTotalRow =1
			SET @sql =@sql+
				'SELECT COUNT(1) AS TotalRow'+CHAR(10)+
				'FROM '+@From+CHAR(10)+
				'WHERE ' + @where
	ELSE --@IsTotalRow =0
	BEGIN			
		IF @PageSize>0 --paging
		BEGIN			
			SET @sql =@sql+
				'WITH Paging AS 
					(SELECT
					ROW_NUMBER() OVER(ORDER BY '+@OrderBy+') AS RowNumber
					,'+@Select+'
					FROM '+@From+'
					WHERE ' + @where +')
					SELECT *
					FROM Paging
					WHERE RowNumber BETWEEN (@PageIndex-1)*@PageSize+1 AND @PageIndex*@PageSize'
		
		END
		ELSE
			SET @sql =@sql+
					'SELECT '+@Select+CHAR(10)+
					'FROM '+@From+CHAR(10)+
					'WHERE ' + @Where +CHAR(10)+
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
			,len(@From)
	END	
	--ELSE
		EXEC sp_executesql @sql,N'@LicenseeID int
								,@FromDate smalldatetime
								,@ToDate smalldatetime
								,@SportType tinyint=0
								,@BetType tinyint=0
								,@MovingBetDay smalldatetime								
								,@IsLive bit
								,@PageIndex int
								,@PageSize int'
								,@LicenseeID
								,@FromDate
								,@ToDate
								,@SportType
								,@BetType
								,@MovingBetDay							
								,@IsLive
								,@PageIndex
								,@PageSize
		
	SET NOCOUNT OFF
END
/*
--non paging
EXEC dbo.Lbs_Rpt_GetTotalTicket
		@LicenseeID=1
		,@FromDate='2011-01-01'
		,@ToDate='2011-07-10'
		,@SportType=1
		,@BetType=1		
		,@IsLive=NULL
		,@ReportBy=1
		,@MovingBetDay='2011-07-01'		
		,@Debug=1

EXEC dbo.Lbs_Rpt_GetTotalTicket
		@LicenseeID=1
		,@FromDate='2011-01-01'
		,@ToDate='2011-07-10'
		,@SportType=1
		,@BetType=1		
		,@IsLive=0
		,@ReportBy=2
		,@MovingBetDay='2011-07-01'
		,@Debug=1

EXEC dbo.Lbs_Rpt_GetTotalTicket
		@LicenseeID=1
		,@FromDate='2011-07-02'
		,@ToDate='2011-07-10'
		,@SportType=1
		,@BetType=1		
		,@IsLive=1
		,@ReportBy=3
		,@MovingBetDay='2011-07-01'
		,@Debug=1
--paging
EXEC dbo.Lbs_Rpt_GetTotalTicket
		@LicenseeID=1
		,@FromDate='2011-01-01'
		,@ToDate='2011-07-10'
		,@SportType=1
		,@BetType=1		
		,@IsLive=NULL
		,@ReportBy=1
		,@MovingBetDay='2011-07-01'
		,@PageSize=12
		,@PageIndex=1
		,@Debug=1

EXEC dbo.Lbs_Rpt_GetTotalTicket
		@LicenseeID=1
		,@FromDate='2011-01-01'
		,@ToDate='2011-07-10'
		,@SportType=1
		,@BetType=1		
		,@IsLive=0
		,@ReportBy=2
		,@MovingBetDay='2011-07-01'
		,@PageSize=10
		,@Debug=1

EXEC dbo.Lbs_Rpt_GetTotalTicket
		@LicenseeID=1
		,@FromDate='2011-01-01'
		,@ToDate='2011-07-10'
		,@SportType=1
		,@BetType=1		
		,@IsLive=1
		,@ReportBy=3
		,@MovingBetDay='2011-07-01'
		,@PageSize=10
		,@Debug=1

--Total Row of paging
EXEC dbo.Lbs_Rpt_GetTotalTicket
		@LicenseeID=1
		,@FromDate='2011-01-01'
		,@ToDate='2011-07-10'
		,@SportType=1
		,@BetType=1		
		,@IsLive=NULL
		,@ReportBy=1
		,@MovingBetDay='2011-07-01'
		,@IsTotalRow=1
		,@Debug=1

EXEC dbo.Lbs_Rpt_GetTotalTicket
		@LicenseeID=1
		,@FromDate='2011-01-01'
		,@ToDate='2011-07-10'
		,@SportType=1
		,@BetType=1		
		,@IsLive=0
		,@ReportBy=2
		,@MovingBetDay='2011-07-01'
		,@IsTotalRow=1
		,@Debug=1

EXEC dbo.Lbs_Rpt_GetTotalTicket
		@LicenseeID=1
		,@FromDate='2011-01-01'
		,@ToDate='2011-07-10'
		,@SportType=1
		,@BetType=1		
		,@IsLive=1
		,@ReportBy=3
		,@MovingBetDay='2011-07-01'
		,@IsTotalRow=1
		,@Debug=1
*/
GO