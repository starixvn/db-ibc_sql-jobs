/*<info serverAlias="DBLIC-bodb_LicenseeReport," executers="bodbLicenseeNet" viewers="vnteam" isFunction="0" isNested=”0”></info>*/
USE [bodb_LicenseeReport]
GO

ALTER PROCEDURE [dbo].[Task_rptBetting_CheckData_Job]
	@FromDate SMALLDATETIME = NULL
	, @ToDate SMALLDATETIME = NULL
	, @Step TINYINT = 0
	, @AllowCorrect BIT = 0

 /* 
	Created by: 20170525@Sophia
	Task: Check & correct data after move bet for rptBetting group [Redmine: #72914]
	DB: DBLIC.bodb_LicenseeReport  
	Param's Explanation: 
		@FromDate , @ToDaate :  NULL then check MovebetDays by Schedule 
		@Step = 1 : Check and correct rptKenoWinloss and rpt_ThirdPartyWL_ExtraGMT
			  = 2 : Check and correct rpt_betting, rpt_betting_BA, rptLicCashoutSummary, rpt_BettingBySport tables (using Staging bettrans)
			  = 3 : 3rd table
			  = 0 : ALL
		@AllowCorrect = 1: Check and correct
					  = 0: Check only, do no Correct data  
	Revisions:  		 


	EXEC Task_rptBetting_CheckData_Job @FromDate = '2017-05-01', @ToDate = '2017-05-07', @Step = 0,  @AllowCorrect = 1
    
*/  
AS 
BEGIN 	
SET NOCOUNT ON   

	DECLARE @MoveBetSchedule TABLE(RowId TINYINT IDENTITY(1,1), ScheduleId TINYINT, MoveBetDay DATE)

	DECLARE @RowId TINYINT, @WinlostDate SMALLDATETIME, 
			@TotalDayMoveBet TINYINT, @TotalDayMoveBetCompleted TINYINT, 
			@Tomorrow DATETIME, @Today DATETIME
	
	SELECT @RowId = 1, @Tomorrow = DATEADD(dd, 1, CAST(GETDATE() AS DATE)), @Today = CAST(GETDATE() AS DATE)

	IF @FromDate IS NULL AND @ToDate IS NULL
	BEGIN 
		INSERT INTO @MoveBetSchedule(ScheduleId, MoveBetDay)
		EXEC DBTXN.bodb02.dbo.Task_MoveBetsDayByScheduleSel
	END 
	ELSE
	BEGIN 
		WHILE @FromDate <= @ToDate
		BEGIN 
			INSERT INTO @MoveBetSchedule(ScheduleId, MoveBetDay)
			VALUES (0, @FromDate)
			
			SELECT @FromDate = @FromDate + 1
		END
	END 

	IF NOT EXISTS (SELECT TOP 1 1 FROM @MoveBetSchedule)
	BEGIN
		RETURN
	END
	
	SELECT @TotalDayMoveBet = COUNT(1) FROM @MoveBetSchedule
	
	--SELECT @TotalDayMoveBetCompleted = COUNT(1)
	--FROM DBACC.bodb02.dbo.userlog WITH(NOLOCK)
	--WHERE userid = 25520 AND doing = 'Task_DailySummary : End (with Finish)'
	--	AND logdate > @Today AND logdate < @Tomorrow
	
	--IF @TotalDayMoveBet <> @TotalDayMoveBetCompleted
	--	RETURN --move is processing or move bet does not run

	DECLARE @ErrMsgTab AS TABLE (NoID SMALLINT IDENTITY (1,1), Date VARCHAR(20), ErrMsg VARCHAR(MAX))

	DECLARE @Subject VARCHAR(1000) = '', @ErrorMessage VARCHAR(MAX) = '', 
			@ErrorMsgStaging VARCHAR(500) = '',
			@GenRptKenoWinloss BIT = 0, @GenExtraGMT BIT = 0,
			@GenRptBetting BIT = 0, @GenRptBettingBA BIT = 0, 
			@GenRptLicCashout BIT = 0, @GenRptBettingBySport BIT = 0

	WHILE EXISTS (SELECT 1 FROM @MoveBetSchedule WHERE RowId = @RowId)
	BEGIN
		SELECT @WinlostDate = MoveBetDay FROM @MoveBetSchedule WHERE RowId = @RowId
		SELECT @RowId = @RowId + 1

		IF NOT EXISTS (SELECT TOP 1 1 FROM bodb02.dbo.bettrans14 WITH(NOLOCK) WHERE WinlostDate = @WinlostDate)
			CONTINUE --does not exist data in bettrans 14
					
		--- Check and correct rptKenoWinloss and rpt_ThirdPartyWL_ExtraGMT tables
		IF @Step IN (0,1)
		BEGIN 			
			------1.1 Check data mismatch
			EXEC dbo.Task_rptKenoWinloss_CheckData @WinlostDate = @WinlostDate, @HasDataMismatch = @GenRptKenoWinloss OUTPUT

			EXEC dbo.Task_rptThirdPartyWL_ExtraGMT_CheckData @WinlostDate = @WinlostDate, @HasDataMismatch = @GenExtraGMT OUTPUT

			-----1.2 Correct data
			IF @AllowCorrect = 1
			BEGIN 
				IF @GenRptKenoWinloss = 1 
				BEGIN 
					EXEC dbo.Task_KenoWinloss_GenDataFromBettrans14 @Fromdate = @WinlostDate, @ToDate = @WinlostDate
				END

				IF @GenExtraGMT = 1 
				BEGIN 
					EXEC dbo.Task_Microgaming_Bettrans14 @Fromdate = @WinlostDate, @ToDate = @WinlostDate
				END 
			END

			----- 1.3. Get Msg 
			IF @GenRptKenoWinloss = 1 
				INSERT INTO @ErrMsgTab (Date, ErrMsg)
				VALUES (@WinlostDate, 'Has data mismatch between rptKenoWinloss table and source')			 
		
			IF @GenExtraGMT = 1 
				INSERT INTO @ErrMsgTab (Date, ErrMsg)
				VALUES (@WinlostDate, 'Has data mismatch between rpt_ThirdPartyWL_ExtraGMT table and source')		 
				

		END 
		
		----Check and correct rpt_betting, rpt_betting_BA, rptLicCashoutSummary, rpt_BettingBySport table (using Staging bettrans)
		IF @Step IN (0,2)
		BEGIN 		 
			-----2.1. Staging bettrans table
			EXEC dbo.Task_PrepareStaging @datefrom = @WinlostDate, @dateto = @WinlostDate , @ErrorMsg = @ErrorMsgStaging OUTPUT				
				IF @ErrorMsgStaging <> '' 
				BEGIN 
					INSERT INTO @ErrMsgTab (Date, ErrMsg)
					VALUES (@WinlostDate, @ErrorMsgStaging)
					BREAK
				END 
		 
			-----2.2 Check data mismatch  
			EXEC dbo.Task_rptBetting_CheckData @winlostdate = @WinlostDate, @HasDataMismatch = @GenRptBetting OUTPUT

			EXEC dbo.Task_rptBetting_BA_CheckData @winlostdate = @WinlostDate, @HasDataMismatch = @GenRptBettingBA OUTPUT

			EXEC dbo.Task_rptLicCashoutSummary_CheckData @winlostdate = @WinlostDate, @HasDataMismatch = @GenRptLicCashout OUTPUT

			EXEC dbo.Task_rptBettingBySport_CheckData @winlostdate = @WinlostDate, @HasDataMismatch = @GenRptBettingBySport OUTPUT

			-----2.3. Correct data
			IF @AllowCorrect = 1
			BEGIN 
				IF @GenRptBetting = 1   
				BEGIN 
					EXEC dbo.GEN_rptBetting @date = @WinlostDate, @date2 = @WinlostDate
				END

				IF @GenRptBettingBA = 1   
				BEGIN 
					EXEC dbo.GEN_rptBetting_BA @date = @WinlostDate, @date2 = @WinlostDate
				END 

				IF @GenRptLicCashout = 1 
				BEGIN   
					EXEC dbo.GEN_rptLicCashoutSummary @FromDate = @WinlostDate, @ToDate = @WinlostDate, @ProductCodes = 'CO'
				END 

				IF @GenRptBettingBySport = 1 
				BEGIN   
					EXEC dbo.GEN_rptBettingBySport @FromDate = @WinlostDate, @ToDate = @WinlostDate 
				END 

				-----2.3.b. Correct data of Rpt_BettingByProduct table because of rpt_betting , rpt_betting_BA has been corrected 
				IF @GenRptBetting = 1 OR @GenRptBetting = 1
				BEGIN 
					EXEC dbo.GEN_rptBettingByProduct @date = @WinlostDate, @date2 = @WinlostDate, @DataSource = 'rpt_betting'  
				END
			END
			
			-----2.4. Clean up staging bettrans
			EXEC dbo.Task_PostStaging 	

			---- 2.5. Get Msg
			IF @GenRptBetting = 1
				INSERT INTO @ErrMsgTab (Date, ErrMsg)
				VALUES (@WinlostDate, 'Has data mismatch between rpt_betting, rpt_BettingbyProduct tables and source') 

			IF @GenRptBettingBA = 1 
				INSERT INTO @ErrMsgTab (Date, ErrMsg)
				VALUES (@WinlostDate, 'Has data mismatch between rpt_betting_BA, rpt_BettingbyProduct tables and source') 

			IF @GenRptLicCashout = 1 
				INSERT INTO @ErrMsgTab (Date, ErrMsg)
				VALUES (@WinlostDate, 'Has data mismatch between rptLicCashoutSummary table and source') 

			IF @GenRptBettingBySport = 1 
				INSERT INTO @ErrMsgTab (Date, ErrMsg)
				VALUES (@WinlostDate, 'Has data mismatch between rpt_BettingBySport table and source') 
		END 
	END 		
	 
	IF EXISTS (SELECT TOP 1 1 FROM @ErrMsgTab)
		BEGIN
			SELECT @Subject = 'SQL Server Job System:'' bodb_LicenseeReport: DW - Generate Daily - Check and correct'' completed on \\' + @@SERVERNAME
			
			SELECT @ErrorMessage = '<H3>Rpt_betting group tables has data mismatch</H3>'
								 + '<table border="1"> '
								 + '<tr><th>No.</th><th>Date</th><th>Error Message</th></tr>'
								  + CAST(( SELECT    td = NoID, '',
													 td = Date, '',
													 td = ErrMsg, ''
											FROM @ErrMsgTab
											FOR XML PATH('tr'), TYPE 
										) AS NVARCHAR(MAX) ) + N'</table>'
			
			EXEC msdb.dbo.sp_send_dbmail @recipients = 'Sophia.nguyen@starixsoft.com, Paul.tran@Starixsoft.com'
						, @subject = @subject
						, @body = @ErrorMessage
						, @body_format = 'HTML'
		END

	--IF ISNULL(@ErrorMsgStaging, '') <> ''
	--BEGIN
	--	RAISERROR (@ErrorMsgStaging, 16, 1)
	--END

 END
   