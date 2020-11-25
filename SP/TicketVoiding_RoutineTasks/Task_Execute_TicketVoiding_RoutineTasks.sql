/*<info serverAlias="DBTXN-bodb02" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Execute_TicketVoiding_RoutineTasks]
(
	 @stepNo		TINYINT,
	 @custIDs		VARCHAR(MAX) = '', 
	 @winlostdate	DATETIME,
	 @errmsg		VARCHAR(1000) = '' OUTPUT
)
AS
/*
	Created: 20190906@Lukas
	Task: routine task after void/recover tickets in bet14 - execute the task case by case 
	DB: DBTXN.bodb02

	Revisions:
		- 20190906@Lukas: Initialize SP [RedmineID: #115377]
		- 20191210@Bobby: Integrate Saba Promotion  [RedmineID: #115377]
			+ Added step 6.94: DBLIC.bodb_LicenseeReport.dbo.Task_DailySummaryLicPromotion_Bettrans14
		- 20201019@Sol: LAP - Licensee Spread Setting - Added new step 1.2 - Calculate original licensee winlost - [RedmineID: #142532]
*/
BEGIN
	DECLARE @errorCode INT,
			--@localErrmsg VARCHAR(100),
			@result INT,
			@BetTypes VARCHAR(8000)

	--select @winlostdate, @custIDs
	IF @stepNo = 1
	BEGIN
		SET @errmsg = 'step 1.1'
		EXEC bodb02.dbo.Task_Dep_DailySum_OddsAdjustment_14
				@WinlostDate = @winlostdate,
				@CustIds = @custIDs

		SET @errmsg = 'step 1.2'
		EXEC bodb02.dbo.Task_sum_winloss_14
				@WinlostDate = @WinlostDate,
				@CustIds = @CustIds 
		
	END
	IF @stepNo = 2
	BEGIN
		SET @errmsg = 'step 2.1'
		EXEC DBSUM.bodb_summary.dbo.Task_CS_SumWinloss_14
			   @WinlostDate = @WinlostDate,
			   @CustIds = @CustIds
		SET @errmsg = 'step 2.2'
		EXEC DBSUM.bodb_summary.dbo.Task_CS_SumCancelled_14
				@WinlostDate = @WinlostDate,
				@CustIds = @CustIds
	END
	IF @stepNo = 3
	BEGIN
		EXEC DBACC.bodb02.dbo.Task_CS_HeadlineBalance14
			   @Winlostdate = @Winlostdate,
			   @CustIds        = @CustIds
	END
	IF @stepNo = 4
	BEGIN
		EXEC DBRPT.bodb_report.dbo.Task_rptStatement_14
				@WinlostDate = @WinlostDate,
				@CustIds = @CustIds
		
	END
	IF @stepNo = 5
	BEGIN
		SET @errmsg = 'step 5.1'
		EXEC DBACC.bodb02.dbo.Acc_ResetWinning_SelByDate14
			   @Winlostdate = @Winlostdate,
			   @Mode = 1 
		SET @errmsg = 'step 5.2'
		EXEC DBACC.bodb02.dbo.Task_ResetWinning_ExtraPT14
			  @FromDate= @WinlostDate,
			  @ToDate = @WinlostDate,
			  @Mode = 1
	END
	IF @stepNo = 6
	BEGIN
		BEGIN TRY			
			EXEC DBACC.bodb02.dbo.Task_rptWinLost_UpdateTable @winlostdate = @WinlostDate
		END TRY
		BEGIN CATCH
			SET @errmsg = 'step 6.1' + '--' + ERROR_MESSAGE()			
			RAISERROR(@errmsg,16,1)
		END CATCH 

		BEGIN TRY
			SET @errmsg = ''
			EXEC DBLIC.bodb_LicenseeReport.dbo.Task_PrepareStaging
				   @datefrom = @WinlostDate,
				   @dateto = @WinlostDate, 
				   @ErrorMsg = @errmsg OUTPUT  
			IF @errmsg <> ''
			BEGIN
				SET @errmsg = 'step 6.2--' +  @errmsg  
				RAISERROR(@errmsg,16,1)
			END
		END TRY
		BEGIN CATCH
			SET @errmsg = 'step 6.2' + '--' + ERROR_MESSAGE()			
			RAISERROR(@errmsg,16,1)
		END CATCH

		BEGIN TRY			 
			EXEC DBLIC.bodb_LicenseeReport.dbo.Task_rptBetting_CheckData 
				@WinlostDate	 = @WinlostDate,
				@HasDataMismatch = @errorCode OUTPUT,
				@BetTypes		 = @BetTypes OUTPUT
		END TRY
		BEGIN CATCH
			SET @errmsg = 'step 6.3' + '--' + ERROR_MESSAGE()			
			RAISERROR(@errmsg,16,1)
		END CATCH

		BEGIN TRY
			EXEC DBLIC.bodb_LicenseeReport.dbo.Task_PostStaging
		END TRY
		BEGIN CATCH
			SET @errmsg = 'step 6.4' + '--' + ERROR_MESSAGE()			
			RAISERROR(@errmsg,16,1)
		END CATCH

		BEGIN TRY
			EXEC DBLIC.bodb_LicenseeReport.dbo.GEN_rptBettingByProduct
				   @date = @winlostdate,
				   @date2 = @winlostdate,
				   @DataSource = 'rpt_Betting'
		END TRY
		BEGIN CATCH
			SET @errmsg = 'step 6.5' + '--' + ERROR_MESSAGE()			
			RAISERROR(@errmsg,16,1)
		END CATCH 


		BEGIN TRY
			EXEC DBLIC.bodb_LicenseeReport.dbo.Task_rptBettingBySport_CheckData 
				@WinlostDate = @WinlostDate,
				@HasDataMismatch = @errorCode OUTPUT,
				@IsParlay = @result OUTPUT
		END TRY
		BEGIN CATCH
			SET @errmsg = 'step 6.6' + '--' + ERROR_MESSAGE()			
			RAISERROR(@errmsg,16,1)
		END CATCH

		BEGIN TRY
			EXEC DBLIC.bodb_LicenseeReport.dbo.Task_DailyRptLicWinloss2 @winlostdate = @WinlostDate
		END TRY
		BEGIN CATCH
			SET @errmsg = 'step 6.7' + '--' + ERROR_MESSAGE()			
			RAISERROR(@errmsg,16,1)
		END CATCH

		BEGIN TRY
			EXEC DBLIC.bodb_LicenseeReport.dbo.Task_rptCustomerTurnOver_Bettrans14 @Date = @WinlostDate
		END TRY
		BEGIN CATCH
			SET @errmsg = 'step 6.8' + '--' + ERROR_MESSAGE()			
			RAISERROR(@errmsg,16,1)
		END CATCH

		BEGIN TRY 
			EXEC DBLIC.bodb_LicenseeReport.dbo.Task_rptWinlostbyleague_Bettrans14 @Date = @WinlostDate
		END TRY
		BEGIN CATCH
			SET @errmsg = 'step 6.9' + '--' + ERROR_MESSAGE()			
			RAISERROR(@errmsg,16,1)
		END CATCH

		BEGIN TRY
			EXEC DBLIC.bodb_LicenseeReport.dbo.Task_rptCustomerMatch_Bettrans14 @Date = @WinlostDate
		END TRY
		BEGIN CATCH
			SET @errmsg = 'step 6.91' + '--' + ERROR_MESSAGE()			
			RAISERROR(@errmsg,16,1)
		END CATCH

		BEGIN TRY
			EXEC DBLIC.bodb_LicenseeReport.dbo.GEN_rptBetting_Parlay14
				   @datefrom = @WinlostDate,
				   @dateto = @WinlostDate
		END TRY
		BEGIN CATCH
			SET @errmsg = 'step 6.92' + '--' + ERROR_MESSAGE()			
			RAISERROR(@errmsg,16,1)
		END CATCH

		BEGIN TRY
			EXEC DBLIC.bodb_LicenseeReport.dbo.Task_DailyRptLicWinlossGMT_Bettrans14 @FromDate = @winlostdate
		END TRY
		BEGIN CATCH
			SET @errmsg = 'step 6.93' + '--' + ERROR_MESSAGE()			
			RAISERROR(@errmsg,16,1)
		END CATCH

		BEGIN TRY
			EXEC DBLIC.bodb_LicenseeReport.dbo.Task_DailySummaryLicPromotion_Bettrans14 @PromoDate = @winlostdate, @IsCheckDataOnly = 0
		END TRY
		BEGIN CATCH
			SET @errmsg = 'step 6.94' + '--' + ERROR_MESSAGE()			
			RAISERROR(@errmsg,16,1)
		END CATCH

	END
	IF @stepNo = 7
	BEGIN
		EXECUTE DBFS.bodb_FraudSensor.dbo.FS_Task_MatchDailyDataCapture @GenerateFromDate = @winlostdate, @GenerateToDate = @winlostdate
	END
	IF @stepNo = 8
	BEGIN
		EXECUTE DBTGRS.bodb_TGRS.dbo.Task_RegenerateTGRSData @FromDate = @winlostdate, @ToDate = @winlostdate, @Flagged = 0
	END 
END
GO