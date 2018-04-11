/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="" viewers="" isFunction="0" isNested="0"></info>*/

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
		@Step = 1 : Check and correct rptKenoWinloss, rpt_ThirdPartyWL_ExtraGMT and rpt_BettingBySport
			  = 2 : Check and correct rpt_betting, rpt_betting_BA, rptLicCashoutSummary tables (using Staging bettrans)
			  = 3 : 3rd table
			  = 0 : ALL
		@AllowCorrect = 1: Check and correct
					  = 0: Check only, do no Correct data  
	Revisions:  		 
		- 20171018@Harper: Include Parlay MuayThai to check data [RedmineID #82827]
		- 20170405@Harper: Include Exchange (separate wallet) to check data [RedmineID: #92485]

	EXEC Task_rptBetting_CheckData_Job @FromDate = '2018-04-01', @ToDate = '2018-04-10', @Step = 0,  @AllowCorrect = 1
    
*/  
AS 
BEGIN 	
	SET NOCOUNT ON   

	DECLARE @MoveBetSchedule TABLE(RowId TINYINT IDENTITY(1,1), ScheduleId TINYINT, MoveBetDay DATE)

	DECLARE @RowId TINYINT, @WinlostDate SMALLDATETIME, 
			@VValue TINYINT, 
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
		RETURN  ---  move bet does not run
	END
	 
	SELECT @VValue = VValue FROM DBACC.bodb02.dbo.SystemSettings WITH (NOLOCK) WHERE VName = 'isMovingBet'		
	IF @VValue = 1
	BEGIN 	
		RAISERROR('Move bets is processing. Automatically retry after 15mins.', 16, 1)
		
		RETURN --move bets is processing 
	END
	ELSE 
	BEGIN 
		WAITFOR DELAY '00:15:00'
		UPDATE STATISTICS bodb02.dbo.bettrans14
	END

	DECLARE @Dates AS TABLE(BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)

	DECLARE @ErrMsgTab AS TABLE (NoID SMALLINT IDENTITY (1,1), Date VARCHAR(50), ErrMsg VARCHAR(MAX))

	DECLARE @Subject VARCHAR(1000) = '', @ErrorMessage VARCHAR(MAX) = '', 
			@ErrorMsgStaging VARCHAR(500) = '',
			@GenRptKenoWinloss TINYINT = 0, @GenExtraGMT TINYINT = 0,
			@GenRptBetting TINYINT = 0, @GenRptBettingBA TINYINT = 0, 
			@GenRptLicCashout TINYINT = 0, @GenRptBettingBySport TINYINT = 0,
			@GenAGC TINYINT = 0, @Gen3rdParty TINYINT = 0, @SeparatedProductID TINYINT, @GenBX TINYINT = 0,
			@BalanceUpDay SMALLDATETIME,
			@KenoWinlossBetTypes VARCHAR(MAX), @ExtraGMTBetTypes VARCHAR(MAX),
			@BettingBetTypes VARCHAR(MAX), @BettingBABetTypes VARCHAR(MAX),
			@3rdProducts VARCHAR(MAX), @IsParLay VARCHAR(20)

	INSERT INTO @Dates(BalanceUpDay, MoveBetsDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay

	SELECT @BalanceUpDay = BalanceUpDay 
	FROM @Dates

	DELETE dbo.DataCheckingLog
	WHERE WinlostDate < @BalanceUpDay

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
			EXEC dbo.Task_rptKenoWinloss_CheckData @WinlostDate = @WinlostDate, @HasDataMismatch = @GenRptKenoWinloss OUTPUT, @BetTypes = @KenoWinlossBetTypes OUTPUT

			EXEC dbo.Task_rptThirdPartyWL_ExtraGMT_CheckData @WinlostDate = @WinlostDate, @HasDataMismatch = @GenExtraGMT OUTPUT, @BetTypes = @ExtraGMTBetTypes OUTPUT

			EXEC dbo.Task_rptBettingBySport_CheckData @winlostdate = @WinlostDate, @HasDataMismatch = @GenRptBettingBySport OUTPUT, @IsParLay = @IsParLay OUTPUT

			-----1.2 Correct data
			IF @AllowCorrect = 1
			BEGIN 
				IF @GenRptKenoWinloss <> 0 
				BEGIN 
					EXEC dbo.Task_KenoWinloss_GenDataFromBettrans14 @Fromdate = @WinlostDate, @ToDate = @WinlostDate
				END

				IF @GenExtraGMT <> 0 
				BEGIN 
					EXEC dbo.Task_Microgaming_Bettrans14 @Fromdate = @WinlostDate, @ToDate = @WinlostDate
				END 

				IF @GenRptBettingBySport <> 0
				BEGIN
					EXEC dbo.GEN_rptBettingBySport14 @Date = @WinlostDate
				END
			END

			----- 1.3. Get Msg 
			IF @GenRptKenoWinloss <> 0 
			BEGIN
				INSERT INTO @ErrMsgTab (Date, ErrMsg)
				SELECT	@WinlostDate,
						CASE @GenRptKenoWinloss
							WHEN 1 THEN ''
							WHEN 2 THEN '(UUS only) '
						END + 'Has data mismatch between rptKenoWinloss table and source with bet types (' + @KenoWinlossBetTypes + ')'
			END		 
		
			IF @GenExtraGMT <> 0
			BEGIN
				INSERT INTO @ErrMsgTab (Date, ErrMsg)
				SELECT	@WinlostDate,
						CASE @GenExtraGMT
							WHEN 1 THEN ''
							WHEN 2 THEN '(UUS only) '
						END + 'Has data mismatch between rpt_ThirdPartyWL_ExtraGMT table and source with bettypes (' + @ExtraGMTBetTypes + ')'
			END

			IF @GenRptBettingBySport <> 0
			BEGIN
				INSERT INTO @ErrMsgTab (Date, ErrMsg)
				SELECT	@WinlostDate,
						CASE @GenRptBettingBySport
							WHEN 1 THEN ''
							WHEN 2 THEN '(UUS only) '
						END + 'Has data mismatch between rpt_BettingBySport table and source with kind of ticket is: (' + @IsParLay + ' ticket)'
			END
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
			EXEC dbo.Task_rptBetting_CheckData @winlostdate = @WinlostDate, @HasDataMismatch = @GenRptBetting OUTPUT, @BetTypes = @BettingBetTypes OUTPUT

			EXEC dbo.Task_rptBetting_BA_CheckData @winlostdate = @WinlostDate, @HasDataMismatch = @GenRptBettingBA OUTPUT, @BetTypes = @BettingBABetTypes OUTPUT

			EXEC dbo.Task_rptLicCashoutSummary_CheckData @winlostdate = @WinlostDate, @HasDataMismatch = @GenRptLicCashout OUTPUT

			
			-----2.3. Correct data
			IF @AllowCorrect = 1
			BEGIN 
				IF @GenRptBetting <> 0
				BEGIN 
					EXEC dbo.GEN_rptBetting @date = @WinlostDate, @date2 = @WinlostDate
				END

				IF @GenRptBettingBA <> 0
				BEGIN 
					EXEC dbo.GEN_rptBetting_BA @date = @WinlostDate, @date2 = @WinlostDate
				END 

				IF @GenRptLicCashout <> 0
				BEGIN   
					EXEC dbo.GEN_rptLicCashoutSummary @FromDate = @WinlostDate, @ToDate = @WinlostDate, @ProductCodes = 'CO'
				END 			

				-----2.3.b. Correct data of Rpt_BettingByProduct table because of rpt_betting , rpt_betting_BA has been corrected 
				IF @GenRptBetting <> 0 OR @GenRptBettingBA <> 0
				BEGIN 
					EXEC dbo.GEN_rptBettingByProduct @date = @WinlostDate, @date2 = @WinlostDate, @DataSource = 'rpt_betting' , @SeparatedProductID = 0   
				END
			END
			
			-----2.4. Clean up staging bettrans
			EXEC dbo.Task_PostStaging 	

			---- 2.5. Get Msg
			IF @GenRptBetting <> 0
			BEGIN
				INSERT INTO @ErrMsgTab (Date, ErrMsg)
				SELECT	@WinlostDate,
						CASE @GenRptBetting
							WHEN 1 THEN ''
							WHEN 2 THEN '(UUS only) '
						END + 'Has data mismatch between rpt_betting, rpt_BettingbyProduct tables and source with bet types (' + @BettingBetTypes + ')'
			END

			IF @GenRptBettingBA <> 0
			BEGIN
				INSERT INTO @ErrMsgTab (Date, ErrMsg)
				SELECT	@WinlostDate,
						CASE @GenRptBettingBA
							WHEN 1 THEN ''
							WHEN 2 THEN '(UUS only) '
						END + 'Has data mismatch between rpt_betting_BA, rpt_BettingbyProduct tables and source with bet types (' + @BettingBABetTypes + ')'
			END

			IF @GenRptLicCashout <> 0
			BEGIN
				INSERT INTO @ErrMsgTab (Date, ErrMsg)
				SELECT	@WinlostDate,
						CASE @GenRptLicCashout
							WHEN 1 THEN ''
							WHEN 2 THEN '(UUS only) '
						END + 'Has data mismatch between rptLicCashoutSummary table and source'
			END			
		END 
		
		----3. Check and correct 3rdProduct table - AGC and GD Separate Wallet (not use staging bettrans) and Exchange (separate wallet)
		IF @Step IN (0,3)
		BEGIN 		  
			-----3.1 Check data mismatch  
			EXEC dbo.Task_rptDepWinlost_AGCasino_CheckData @winlostdate = @WinlostDate, @HasDataMismatch = @GenAGC OUTPUT   ---- AGC
			
			EXEC dbo.Task_rptDepWinlost_ThirdParty_CheckData @winlostdate = @WinlostDate, @HasDataMismatch = @Gen3rdParty OUTPUT, @ProductIDs = @3rdProducts OUTPUT
			
			EXEC dbo.Task_rptDepWinlost_Exchange_CheckData @WinlostDate = @WinlostDate, @HasDataMismatch = @GenBX OUTPUT -- Exchange Product
			        
			-----3.2. Correct data
			IF @AllowCorrect = 1
			BEGIN 
				IF @GenAGC <> 0 --- AGC 
				BEGIN 
					EXEC DBACC.bodb02.dbo.Task_DOT_AGCasino_DailySummary @winlostdate = @winlostdate
				END 
				
				IF @Gen3rdParty <> 0 AND ', ' + @3rdProducts + ',' LIKE '%, 11,%' --- GD   
				BEGIN 
					EXEC bodb_PlaytechCS.dbo.Task_DOT_GoldDeluxe_DailySummary @winlostdate = @winlostdate
				END

				IF @GenBX <> 0 -- Exchange Product
				BEGIN
					EXEC bodb_3rdProduct.dbo.Task_DOT_Exchange_DailySummary @winlostdate = @WinlostDate					
				END
				
			-----3.3.b. Correct data of Rpt_BettingByProduct table because of AGC and GD have been corrected 
				IF @GenAGC <> 0 OR @Gen3rdParty <> 0 OR @GenBX <> 0
				BEGIN
					
					IF (@Gen3rdParty <> 0 AND @GenAGC <> 0) OR (@Gen3rdParty <> 0 AND @GenBX <> 0) OR (@GenAGC <> 0 AND @GenBX <> 0)
					BEGIN
						EXEC dbo.GEN_rptBettingByProduct @date = @WinlostDate, @date2 = @WinlostDate, @DataSource = 'SeparatedProduct' , @SeparatedProductID = 0 -- run for all separate product  
					END
					
					ELSE IF @Gen3rdParty <> 0 AND ', ' + @3rdProducts + ',' LIKE '%, 11,%'
					BEGIN
						EXEC dbo.GEN_rptBettingByProduct @date = @WinlostDate, @date2 = @WinlostDate, @DataSource = 'SeparatedProduct' , @SeparatedProductID = 11 
					END
					
					ELSE IF @GenAGC <> 0 
					BEGIN
						EXEC dbo.GEN_rptBettingByProduct @date = @WinlostDate, @date2 = @WinlostDate, @DataSource = 'SeparatedProduct' , @SeparatedProductID = 10 
					END
					
					ELSE IF @GenBX <> 0 
					BEGIN
						EXEC dbo.GEN_rptBettingByProduct @date = @WinlostDate, @date2 = @WinlostDate, @DataSource = 'SeparatedProduct' , @SeparatedProductID = 31 
					END								
					
				END
				
			END 		   
	
	
			---- 3.2. Get Msg
			IF @GenAGC <> 0
			BEGIN
				INSERT INTO @ErrMsgTab (Date, ErrMsg)
				SELECT	@WinlostDate,
						CASE @GenAGC
							WHEN 1 THEN ''
							WHEN 2 THEN '(UUS only) '
						END + 'Has data mismatch between rptDepWinlost_AGCasino table and source'
			END
			 
			IF @Gen3rdParty <> 0
			BEGIN
				INSERT INTO @ErrMsgTab (Date, ErrMsg)
				SELECT	@WinlostDate,
						CASE @Gen3rdParty
							WHEN 1 THEN ''
							WHEN 2 THEN '(UUS only) '
						END + 'Has data mismatch between rptDepWinlost_ThirdParty table and source with products (' + @3rdProducts + ')'
			END

			IF @GenBX <> 0
			BEGIN
				INSERT INTO @ErrMsgTab (Date, ErrMsg)
				SELECT	@WinlostDate,
						CASE @GenBX
							WHEN 1 THEN ''
							WHEN 2 THEN '(UUS only) '
						END + 'Has data mismatch between rptDepWinlost_ThirdParty table and source with Exchange product'
			END
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
			
		EXEC msdb.dbo.sp_send_dbmail @recipients = 'Sophia.nguyen@starixsoft.com;Paul.tran@starixsoft.com;Patrick.pham@starixsoft.com'
					, @subject = @subject
					, @body = @ErrorMessage
					, @body_format = 'HTML'
	END

END
GO