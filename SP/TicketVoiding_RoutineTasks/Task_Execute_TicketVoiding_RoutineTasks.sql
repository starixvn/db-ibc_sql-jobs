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
		- 20200106@Sol: Recover/Void - add missing sub-steps to step 6 - [RedmineID: #148325]
		- 20220422@Sol: LAP - Enhance database jobs - [RedmineID: #171747]
		- 20220805@Sol: LAP - Scale out DBTrans phase 1 - Check siteDB or central to run specific code - [RedmineID: #175297]
		- 20230522@Lewis: Database - Abnormal Account - call sum Sps on other servers - [RedmineID: #188463]
		- 20230612@Evan: remove code related to Saba Promotion report - [RedmineID: #189234]
		- 20220603@Sol: Database - Sync-up Standby Server data - [RedmineID: #167261]
*/
BEGIN
	DECLARE @GenerateData TINYINT,
			--@localErrmsg VARCHAR(100),
			@result VARCHAR(20),
			@BetTypes VARCHAR(8000)

	DECLARE 
		@alias VARCHAR(100), 
		@sqlCommand VARCHAR(MAX),
		@params VARCHAR(MAX),
		@doNotRunInServer VARCHAR(1000)
	
	DECLARE @SiteDBGroupID SMALLINT = 0 
	SELECT @SiteDBGroupID = dbo.f_Get_SiteDBGroupID()

	IF (@SiteDBGroupID <> 0) ---run at SiteDB -> only need exec step 1 at sitedb because it update bettrans14
	BEGIN
		IF @stepNo = 1
		BEGIN
			SET @errmsg = 'step 1.1'
			EXEC bodb02.dbo.Task_Dep_DailySum_OddsAdjustment_14 
				@WinlostDate = @winlostdate,
				@CustIds = @custIDs
		END
	END
	ELSE --- run at central DB
	BEGIN
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
			EXEC dbo.Get_ServerName_By_Alias @Alias  = 'DBTXN', @ServerName = @doNotRunInServer OUTPUT
	
			SELECT 
				@alias = 'DBSUM', 
				@SqlCommand = CONCAT('EXEC bodb_summary.dbo.Task_CS_SumWinloss_14 ', ' @WinlostDate = ''',CONVERT(VARCHAR(50), @winlostdate, 121),''' ,@CustIds = ''',@CustIds,'''')

			EXEC ExecRep_NAP_Admin_05 @ServerName = '', @AliasName = @alias, @SqlCommand = @SqlCommand, @doNotRunInServer = @doNotRunInServer, @Remark = @errmsg

			SET @errmsg = 'step 2.2'

			SELECT 
				@alias = 'DBSUM', 
				@SqlCommand = CONCAT('EXEC bodb_summary.dbo.Task_CS_SumCancelled_14 ', ' @WinlostDate = ''',CONVERT(VARCHAR(50), @winlostdate, 121),''' ,@CustIds = ''',@CustIds,'''')
			EXEC ExecRep_NAP_Admin_05 @ServerName = '', @AliasName = @alias, @SqlCommand = @SqlCommand, @doNotRunInServer = @doNotRunInServer, @Remark = @errmsg
		END
		IF @stepNo = 3
		BEGIN
			
			SET @errmsg = 'step 3'
			EXEC dbo.Get_ServerName_By_Alias @Alias  = 'DBTXN', @ServerName = @doNotRunInServer OUTPUT 
	
			SELECT 
				@alias = 'DBACC', 
				@SqlCommand = CONCAT('EXEC bodb02.dbo.Task_CS_HeadlineBalance14 ', ' @WinlostDate = ''',CONVERT(VARCHAR(50), @winlostdate, 121),''' ,@CustIds = ''',@CustIds,'''')
			EXEC ExecRep_NAP_Admin_05 @ServerName = '', @AliasName = @alias, @SqlCommand = @SqlCommand, @doNotRunInServer = @doNotRunInServer, @Remark = @errmsg
		END
		IF @stepNo = 4
		BEGIN
			
			SET @errmsg = 'step 4'
			EXEC dbo.Get_ServerName_By_Alias @Alias  = 'DBTXN', @ServerName = @doNotRunInServer OUTPUT
	
			SELECT 
				@alias = 'DBRPT', 
				@SqlCommand = CONCAT('EXEC bodb_report.dbo.Task_rptStatement_14 ', ' @WinlostDate = ''',CONVERT(VARCHAR(50), @winlostdate, 121),''' ,@CustIds = ''',@CustIds,'''')
			EXEC ExecRep_NAP_Admin_05 @ServerName = '', @AliasName = @alias, @SqlCommand = @SqlCommand, @doNotRunInServer = @doNotRunInServer, @Remark = @errmsg
		END
		IF @stepNo = 5
		BEGIN
		
			SET @errmsg = 'step 5.1'
			---keep call sp by linked server to DBACC
			EXEC DBACC.bodb02.dbo.Acc_ResetWinning_SelByDate14
				   @Winlostdate = @Winlostdate,
				   @Mode = 1

			-------------------------
			SET @errmsg = 'step 5.2'
			---keep call sp by linked server to DBACC
			EXEC DBACC.bodb02.dbo.Task_ResetWinning_ExtraPT14
				  @FromDate= @WinlostDate,
				  @ToDate = @WinlostDate,
				  @Mode = 1
		END
		IF @stepNo = 6
		BEGIN

			BEGIN TRY
				SET @errmsg = 'step 6.01'
				
				EXEC dbo.Get_ServerName_By_Alias @Alias  = 'DBTXN', @ServerName = @doNotRunInServer OUTPUT 
				SELECT 
					@alias = 'DBLIC', 
					@SqlCommand = CONCAT('EXEC bodb_LicenseeReport.dbo.Task_PrepareStaging ', ' @datefrom = ''',CONVERT(VARCHAR(50), @winlostdate, 121),''' ,@dateto = ''',CONVERT(VARCHAR(50), @winlostdate, 121),'''')
				EXEC ExecRep_NAP_Admin_05 @ServerName = '', @AliasName = @alias, @SqlCommand = @SqlCommand, @doNotRunInServer = @doNotRunInServer, @Remark = @errmsg

			END TRY
			BEGIN CATCH
				SET @errmsg = 'step 6.01' + '--' + ERROR_MESSAGE()			
				RAISERROR(@errmsg,16,1)
			END CATCH

			BEGIN TRY			 
				
				SET @ErrMsg = 'step 6.02'
				;WITH rs AS 
				(
					SELECT (SELECT * FROM (VALUES (@WinlostDate)) t(wld) for XML RAW('root') ) AS cxml
				)
				SELECT @params = cxml FROM rs

				EXEC dbo.Get_ServerName_By_Alias @Alias  = 'DBTXN', @ServerName = @doNotRunInServer OUTPUT
				SELECT 
					@alias = 'DBLIC', 
					@SqlCommand = CONCAT('EXEC bodb_LicenseeReport.dbo.Task_rptBetting_CheckData ', ' @WinlostDate = ''',CONVERT(VARCHAR(50), @winlostdate, 121),'''',',@HasDataMismatch = @GenerateData OUTPUT, @BetTypes = @BetTypes OUTPUT')
				EXEC ExecRep_NAP_Admin_05 @ServerName = '', @AliasName = @alias, @SqlCommand = @SqlCommand, @doNotRunInServer = @doNotRunInServer, @Remark = @errmsg, @Params = @params

			END TRY
			BEGIN CATCH
				SET @errmsg = 'step 6.02' + '--' + ERROR_MESSAGE()			
				RAISERROR(@errmsg,16,1)
			END CATCH

			BEGIN TRY
				
				SELECT @params = '', @ErrMsg = 'step 6.05'
				
				EXEC dbo.Get_ServerName_By_Alias @Alias  = 'DBTXN', @ServerName = @doNotRunInServer OUTPUT
				SELECT 
					@alias = 'DBLIC', 
					@SqlCommand = 'EXEC bodb_LicenseeReport.dbo.Task_PostStaging '
				EXEC ExecRep_NAP_Admin_05 @ServerName = '', @AliasName = @alias, @SqlCommand = @SqlCommand, @doNotRunInServer = @doNotRunInServer, @Remark = @errmsg

			END TRY
			BEGIN CATCH
				SET @errmsg = 'step 6.05' + '--' + ERROR_MESSAGE()			
				RAISERROR(@errmsg,16,1)
			END CATCH

			BEGIN TRY
				
				SET @ErrMsg  = 'step 6.06'

				;WITH rs AS 
				(
					SELECT (SELECT * FROM (VALUES (@WinlostDate)) t(wld) for XML RAW('root') ) AS cxml
				)
				SELECT @params = cxml FROM rs
			
				EXEC dbo.Get_ServerName_By_Alias @Alias  = 'DBTXN', @ServerName = @doNotRunInServer OUTPUT
				SELECT 
					@alias = 'DBLIC', 
					@SqlCommand = CONCAT('EXEC bodb_LicenseeReport.dbo.Task_rptBettingBySport_CheckData ', ' @WinlostDate = ''',CONVERT(VARCHAR(50), @winlostdate, 121),'''',',@HasDataMismatch = @GenerateData OUTPUT, @IsParlay = @IsParlay OUTPUT')
				EXEC ExecRep_NAP_Admin_05 @ServerName = '', @AliasName = @alias, @SqlCommand = @SqlCommand, @doNotRunInServer = @doNotRunInServer, @Remark = @errmsg, @Params = @params

			END TRY
			BEGIN CATCH
				SET @errmsg = 'step 6.06' + '--' + ERROR_MESSAGE()			
				RAISERROR(@errmsg,16,1)
			END CATCH

			BEGIN TRY
				
				SET @ErrMsg  = 'step 6.08'
				
				EXEC dbo.Get_ServerName_By_Alias @Alias  = 'DBTXN', @ServerName = @doNotRunInServer OUTPUT
				SELECT 
					@alias = 'DBLIC', 
					@SqlCommand = CONCAT('EXEC bodb_LicenseeReport.dbo.Task_DailyRptLicWinloss2 ', ' @WinlostDate = ''',CONVERT(VARCHAR(50), @winlostdate, 121),'''')
				EXEC ExecRep_NAP_Admin_05 @ServerName = '', @AliasName = @alias, @SqlCommand = @SqlCommand, @doNotRunInServer = @doNotRunInServer, @Remark = @errmsg

			END TRY
			BEGIN CATCH
				SET @errmsg = 'step 6.08' + '--' + ERROR_MESSAGE()			
				RAISERROR(@errmsg,16,1)
			END CATCH

			BEGIN TRY
				
				SET @ErrMsg  = 'step 6.09'

				EXEC dbo.Get_ServerName_By_Alias @Alias  = 'DBTXN', @ServerName = @doNotRunInServer OUTPUT
				SELECT 
					@alias = 'DBLIC', 
					@SqlCommand = CONCAT('EXEC bodb_LicenseeReport.dbo.Task_rptCustomerTurnOver_Bettrans14 ', ' @Date = ''',CONVERT(VARCHAR(50), @winlostdate, 121),'''')
				EXEC ExecRep_NAP_Admin_05 @ServerName = '', @AliasName = @alias, @SqlCommand = @SqlCommand, @doNotRunInServer = @doNotRunInServer, @Remark = @errmsg

			END TRY
			BEGIN CATCH
				SET @errmsg = 'step 6.09' + '--' + ERROR_MESSAGE()			
				RAISERROR(@errmsg,16,1)
			END CATCH

			BEGIN TRY 
				
				SET @ErrMsg  = 'step 6.10'
			
				EXEC dbo.Get_ServerName_By_Alias @Alias  = 'DBTXN', @ServerName = @doNotRunInServer OUTPUT
				SELECT 
					@alias = 'DBLIC', 
					@SqlCommand = CONCAT('EXEC bodb_LicenseeReport.dbo.Task_rptWinlostbyleague_Bettrans14 ', ' @Date = ''',CONVERT(VARCHAR(50), @winlostdate, 121),'''')
				EXEC ExecRep_NAP_Admin_05 @ServerName = '', @AliasName = @alias, @SqlCommand = @SqlCommand, @doNotRunInServer = @doNotRunInServer, @Remark = @errmsg

			END TRY
			BEGIN CATCH
				SET @errmsg = 'step 6.10' + '--' + ERROR_MESSAGE()			
				RAISERROR(@errmsg,16,1)
			END CATCH

			BEGIN TRY
				
				SET @ErrMsg  = 'step 6.11'
				
				EXEC dbo.Get_ServerName_By_Alias @Alias  = 'DBTXN', @ServerName = @doNotRunInServer OUTPUT
				SELECT 
					@alias = 'DBLIC', 
					@SqlCommand = CONCAT('EXEC bodb_LicenseeReport.dbo.Task_rptCustomerMatch_Bettrans14 ', ' @Date = ''',CONVERT(VARCHAR(50), @winlostdate, 121),'''')
				EXEC ExecRep_NAP_Admin_05 @ServerName = '', @AliasName = @alias, @SqlCommand = @SqlCommand, @doNotRunInServer = @doNotRunInServer, @Remark = @errmsg

			END TRY
			BEGIN CATCH
				SET @errmsg = 'step 6.11' + '--' + ERROR_MESSAGE()			
				RAISERROR(@errmsg,16,1)
			END CATCH

			BEGIN TRY
				
				SET @ErrMsg  = 'step 6.12'
				
				EXEC dbo.Get_ServerName_By_Alias @Alias  = 'DBTXN', @ServerName = @doNotRunInServer OUTPUT
				SELECT 
					@alias = 'DBLIC', 
					@SqlCommand = CONCAT('EXEC bodb_LicenseeReport.dbo.GEN_rptBetting_Parlay14 ', ' @datefrom = ''',CONVERT(VARCHAR(50), @winlostdate, 121),''' ,@dateto = ''',CONVERT(VARCHAR(50), @winlostdate, 121),'''')
				EXEC ExecRep_NAP_Admin_05 @ServerName = '', @AliasName = @alias, @SqlCommand = @SqlCommand, @doNotRunInServer = @doNotRunInServer, @Remark = @errmsg

			END TRY
			BEGIN CATCH
				SET @errmsg = 'step 6.12' + '--' + ERROR_MESSAGE()			
				RAISERROR(@errmsg,16,1)
			END CATCH

			BEGIN TRY
				
				SET @ErrMsg  = 'step 6.13'
								
				EXEC dbo.Get_ServerName_By_Alias @Alias  = 'DBTXN', @ServerName = @doNotRunInServer OUTPUT
				SELECT 
					@alias = 'DBLIC', 
					@SqlCommand = CONCAT('EXEC bodb_LicenseeReport.dbo.Task_DailyRptLicWinlossGMT_Bettrans14 ', ' @FromDate = ''',CONVERT(VARCHAR(50), @winlostdate, 121),'''')
				EXEC ExecRep_NAP_Admin_05 @ServerName = '', @AliasName = @alias, @SqlCommand = @SqlCommand, @doNotRunInServer = @doNotRunInServer, @Remark = @errmsg

			END TRY
			BEGIN CATCH
				SET @errmsg = 'step 6.13' + '--' + ERROR_MESSAGE()			
				RAISERROR(@errmsg,16,1)
			END CATCH

			BEGIN TRY
			
				SET @ErrMsg  = 'step 6.14'
				
				EXEC dbo.Get_ServerName_By_Alias @Alias  = 'DBTXN', @ServerName = @doNotRunInServer OUTPUT
				SELECT 
					@alias = 'DBLIC', 
					@SqlCommand = CONCAT('EXEC bodb_LicenseeReport.dbo.Task_Microgaming_Bettrans14 ', ' @Fromdate = ''',CONVERT(VARCHAR(50), @winlostdate, 121),''', @Todate = ''', CONVERT(VARCHAR(50), @winlostdate, 121), '''')
				EXEC ExecRep_NAP_Admin_05 @ServerName = '', @AliasName = @alias, @SqlCommand = @SqlCommand, @doNotRunInServer = @doNotRunInServer, @Remark = @errmsg

			END TRY
			BEGIN CATCH
				SET @errmsg = 'step 6.14' + '--' + ERROR_MESSAGE()			
				RAISERROR(@errmsg,16,1)
			END CATCH

		END
		IF @stepNo = 7
		BEGIN
			
			SET @ErrMsg  = 'step 7'
			
			EXEC dbo.Get_ServerName_By_Alias @Alias  = 'DBTXN', @ServerName = @doNotRunInServer OUTPUT
			SELECT 
				@alias = 'DBFS', 
				@SqlCommand = CONCAT('EXEC bodb_FraudSensor.dbo.FS_Task_MatchDailyDataCapture ', ' @GenerateFromDate = ''',CONVERT(VARCHAR(50), @winlostdate, 121),''', @GenerateToDate = ''', CONVERT(VARCHAR(50), @winlostdate, 121), '''')
			EXEC ExecRep_NAP_Admin_05 @ServerName = '', @AliasName = @alias, @SqlCommand = @SqlCommand, @doNotRunInServer = @doNotRunInServer, @Remark = @errmsg

		END
		IF @stepNo = 8
		BEGIN
			
			SET @ErrMsg  = 'step 8'
			
			EXEC dbo.Get_ServerName_By_Alias @Alias  = 'DBTXN', @ServerName = @doNotRunInServer OUTPUT
			SELECT 
				@alias = 'DBTGRS', 
				@SqlCommand = CONCAT('EXEC bodb_TGRS.dbo.Task_RegenerateTGRSData ', ' @FromDate = ''',CONVERT(VARCHAR(50), @winlostdate, 121),''', @ToDate = ''', CONVERT(VARCHAR(50), @winlostdate, 121), ''', @Flagged = 0')
			EXEC ExecRep_NAP_Admin_05 @ServerName = '', @AliasName = @alias, @SqlCommand = @SqlCommand, @doNotRunInServer = @doNotRunInServer, @Remark = @errmsg

		END 
	END
END
GO