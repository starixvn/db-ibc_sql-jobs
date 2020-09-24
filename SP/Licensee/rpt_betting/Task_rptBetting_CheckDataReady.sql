/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_rptBetting_CheckDataReady] 
AS
/*

	Created: @Sophia
	Task:  check data of sum rpt_betting done yet 
	
	Revisions: 
		- 20171124@Sophia: Initial, call SP check before send mail House Net Income report [redmine: #87247]
		- 20190328@Sophia: Check data Licensee and DW before send mail [redmind: #110981]
		- 20190416@Patrick: Add notification to skype and lestalk [Redmind: #111921]
		- 20190524@Billy:	Change Letstalk linked server - [Redmine: #113125]
		- 20190910@Percy:	Replace FactCustWinloss to FactSitewinloss (get smaller data) + Split code to enhance performance [RedmineID: #119761]
		- 20200924@Percy:	Increase max different winloss from 100k to 200k [RedmineID: #142269]
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

		SELECT rptDate, CurrencyId, SUM(BetCount) cnt, SUM(stake) stake, SUM(winlossP) winloss
		INTO #__DW
		FROM  DBWH.bodb_Account.dbo.FactSitewinloss WITH (NOLOCK)
		WHERE rptDate >= @Winlosdate
		GROUP BY rptDate, CurrencyId

		INSERT INTO #DW (rptDate, betcount, Stake, Winloss)
		SELECT rptDate, SUM(cnt) cnt, SUM(stake * e.actualrate) stake, SUM(winloss * e.actualrate) winloss
		FROM  #__DW f
			INNER JOIN bodb02.dbo.Exchange e WITH (NOLOCK) ON e.ExchangeID = f.CurrencyId
		GROUP BY rptDate
		
		IF NOT EXISTS (
					SELECT l.RptDate, ABS(ISNULL(l.Winloss,0)) - ABS(ISNULL(d.Winloss,0)) AS Winloss
					FROM #Lic l 
						FULL JOIN #DW d ON d.rptDate = l.RptDate
					WHERE ABS(ISNULL(l.Winloss,0)) - ABS(ISNULL(d.Winloss,0)) > 200000
				   ) 
		
		BEGIN
			SELECT @IsDataYesterdayReady = 1
		END 
		ELSE
		BEGIN 
			SELECT @IsDataYesterdayReady = 0 

			--set alert to pontus
			DECLARE @message NVARCHAR(512)
			SET @message = '[WARNING] - DATA IS INCONSISTENT BETWEEN RPT_BETTING AND FACTSITEWINLOSS - Automail Report - House Net Income ' + CONVERT(VARCHAR(50), GETDATE(), 121) + '. Please help to check!'
			print @message
			EXECUTE	DBNOTI.NotificationDB.dbo.DBA_Letstalk_NewJobMessage @ServerName = N'PONTUS', 
				@JobId = NULL, @JobName = N'Custom Message', 
				@Message = @message, @CaseId = 1;
		END  
		
		DROP TABLE #__DW
		DROP TABLE #DW
		DROP TABLE #Lic
	END

	----- Get info	
	SELECT @IsDataYesterdayReady AS IsDataYesterdayReady
END
GO