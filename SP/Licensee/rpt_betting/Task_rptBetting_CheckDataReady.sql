/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb_LicenseeReport]
GO

ALTER PROCEDURE [dbo].[Task_rptBetting_CheckDataReady] 
AS
/*

	Created: @Sophia
	Task:  check data of sum rpt_betting done yet 
	Revision: 
		- 20171124@Sophia: Initial, call SP check before send mail House Net Income report [redmine: #87247]
		- 20190328@Sophia: Check data Licensee and DW before send mail [redmind: #110981]

*/

BEGIN 
	SET NOCOUNT ON 
	
	DECLARE @MaxDate DATETIME, @IsDataYesterdayReady BIT = 0 

	SELECT @MaxDate = MAX(RptDate)
	FROM   bodb_LicenseeReport.dbo.rpt_Betting WITH (NOLOCK)	 
 
	---Has data at sum table and all steps of the Job are done
	IF @MaxDate >= DATEADD (DAY, -1, CONVERT(DATE, GETDATE()))
		AND (SELECT VValue
			FROM  bodb02.dbo.SystemSettings  WITH (NOLOCK)
			WHERE VName = 'IsStagingBettrans') = '0'
	BEGIN
		SELECT @IsDataYesterdayReady = 1
	END 
	ELSE
	BEGIN 
		SELECT @IsDataYesterdayReady = 0 
	END  
	
	----- Compare Amount diff more than 100k RM, then not email
	IF @IsDataYesterdayReady = 1
	BEGIN 
		
		CREATE TABLE #Lic (rptDate SMALLDATETIME, betcount INT, Stake MONEY, Winloss MONEY)	
		CREATE TABLE #DW (rptDate SMALLDATETIME, betcount INT, Stake MONEY, Winloss MONEY)
		DECLARE @Winlosdate SMALLDATETIME = DATEADD(DAY, -3, CURRENT_TIMESTAMP)	 
		
		
		INSERT INTO #Lic (rptDate, betcount, Stake, Winloss)
		SELECT rptDate, sum(BetCount) BetCount, sum(stake) stake, sum(winloss) winloss
		FROM (
				SELECT rptDate, sum(BetCount) BetCount, sum(Turnover * e.actualrate) stake, sum(winloss * e.actualrate) winloss
				FROM dbo.rpt_Betting r WITH(NOLOCK)
					INNER JOIN bodb02.dbo.Exchange e WITH (NOLOCK) ON e.ExchangeID = r.CurrencyId
				WHERE rptDate >= @Winlosdate
				GROUP BY rptDate

				UNION ALL
				SELECT rptDate, sum(BetCount) BetCount, sum(Turnover * e.actualrate) stake, sum(winloss * e.actualrate) winloss
				FROM dbo.rpt_Betting_BA r WITH(NOLOCK)
					INNER JOIN bodb02.dbo.Exchange e WITH (NOLOCK) ON e.ExchangeID = r.CurrencyId
				WHERE rptDate >= @Winlosdate
				GROUP BY rptDate
			) t
		GROUP BY rptDate 

		INSERT INTO #DW (rptDate, betcount, Stake, Winloss)
		SELECT rptDate, SUM(BetCount) cnt, SUM(stake * e.actualrate) stake, SUM(winlossP * e.actualrate) winloss
		FROM  DBWH.bodb_Account.dbo.FactCustWinloss f WITH(NOLOCK)
			INNER JOIN bodb02.dbo.Exchange e WITH (NOLOCK) ON e.ExchangeID = f.CurrencyId
		WHERE rptDate >= @Winlosdate
		GROUP BY rptDate 
		
		IF NOT EXISTS (
					SELECT l.RptDate, ABS(ISNULL(l.Winloss,0)) - ABS(ISNULL(d.Winloss,0)) AS Winloss
					FROM #Lic l 
						FULL JOIN #DW d ON d.rptDate = l.RptDate
					WHERE ABS(ISNULL(l.Winloss,0)) - ABS(ISNULL(d.Winloss,0)) > 100000
				   ) 
		
		BEGIN
			SELECT @IsDataYesterdayReady = 1
		END 
		ELSE
		BEGIN 
			SELECT @IsDataYesterdayReady = 0 
		END  
		
		DROP TABLE #DW
		DROP TABLE #Lic
	END
	----- Get info	

	SELECT @IsDataYesterdayReady AS IsDataYesterdayReady


END 
GO 
 
 