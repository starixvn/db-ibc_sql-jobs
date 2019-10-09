/*<info serverAlias="DBTXN-bodb02" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Execute_TicketVoiding_RoutineTasks]
(
	 @stepNo		TINYINT,
	 @custIDs		VARCHAR(MAX) = '', 
	 @winlostdate	DATETIME
)
AS
/*
	Created: 20190906@Lukas
	Task: routine task after void/recover tickets in bet14 - execute the task case by case 
	DB: DBTXN.bodb02

	Revisions:
		- 20190906@Lukas: Initialize SP [RedmineID: #115377]
*/
BEGIN
	DECLARE @errorCode INT,
			@errmsg VARCHAR(100),
			@result INT

	--select @winlostdate, @custIDs
	IF @stepNo = 1
	BEGIN
		EXEC bodb02.dbo.Task_sum_winloss_14
				@WinlostDate = @WinlostDate,
				@CustIds = @CustIds 
	END
	IF @stepNo = 2
	BEGIN
		EXEC DBSUM.bodb_summary.dbo.Task_CS_SumWinloss_14
			   @WinlostDate = @WinlostDate,
			   @CustIds = @CustIds
		EXEC DBSUM.bodb_summary.dbo.Task_CS_SumCancelled_14
				@WinlostDate = @WinlostDate,
				@CustIds = @CustIds
	END
	IF @stepNo = 3
	BEGIN
		EXEC bodb02.dbo.Task_CS_HeadlineBalance14
			   @Winlostdate = @Winlostdate,
			   @Mode = 1 ,
			   @ErrCode = @errorCode OUTPUT,
			   @ErrMsg = @errmsg OUTPUT 
		IF @errorCode NOT IN (0,2)
		BEGIN
			RAISERROR(@errmsg,16,1)
		END
	END
	IF @stepNo = 4
	BEGIN
		EXEC DBRPT.bodb_report.dbo.Task_rptStatement_14
				@WinlostDate = @WinlostDate,
				@CustIds = @CustIds
		
	END
	IF @stepNo = 5
	BEGIN
		EXEC DBACC.bodb02.dbo.Acc_ResetWinning_SelByDate14
			   @Winlostdate = @Winlostdate,
			   @Mode = 1,  
			   @ErrCode = @errorCode OUTPUT,
			   @ErrMsg = @errmsg OUTPUT 

		IF @errorCode NOT IN (0,2)
		BEGIN
			RAISERROR(@errmsg,16,1)
		END

	END
	IF @stepNo = 6
	BEGIN
		EXEC DBACC.bodb02.dbo.Task_rptWinLost_UpdateTable @winlostdate = @WinlostDate

		EXEC DBLIC.bodb_LicenseeReport.dbo.Task_PrepareStaging
			   @datefrom = @WinlostDate,
			   @dateto = @WinlostDate, 
			   @ErrorMsg = @errmsg OUTPUT
		IF @errmsg <> ''
		BEGIN
			RAISERROR(@errmsg,16,1)
		END

		EXEC DBLIC.bodb_LicenseeReport.dbo.Task_rptBetting_CheckData 
			@WinlostDate	 = @WinlostDate,
			@HasDataMismatch = @errorCode OUTPUT,
			@BetTypes		 = @result OUTPUT

		EXEC DBLIC.bodb_LicenseeReport.dbo.Task_PostStaging

		EXEC DBLIC.bodb_LicenseeReport.dbo.GEN_rptBettingByProduct
			   @date = @winlostdate,
			   @date2 = @winlostdate,
			   @DataSource = 'rpt_Betting'

		EXEC DBLIC.bodb_LicenseeReport.dbo.Task_rptBettingBySport_CheckData 
			@WinlostDate = @WinlostDate,
			@HasDataMismatch = @errorCode OUTPUT,
			@IsParlay = @result OUTPUT

		EXEC DBLIC.bodb_LicenseeReport.dbo.Task_DailyRptLicWinloss2 @winlostdate = @WinlostDate

		EXEC DBLIC.bodb_LicenseeReport.dbo.Task_rptCustomerTurnOver_Bettrans14 @Date = @WinlostDate

		EXEC DBLIC.bodb_LicenseeReport.dbo.Task_rptWinlostbyleague_Bettrans14 @Date = @WinlostDate

		EXEC DBLIC.bodb_LicenseeReport.dbo.Task_rptCustomerMatch_Bettrans14 @Date = @WinlostDate

		EXEC DBLIC.bodb_LicenseeReport.dbo.GEN_rptBetting_Parlay14
			   @datefrom = @WinlostDate,
			   @dateto = @WinlostDate
		
		EXEC DBLIC.bodb_LicenseeReport.dbo.Task_DailyRptLicWinlossGMT_Bettrans14 @FromDate = @winlostdate


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