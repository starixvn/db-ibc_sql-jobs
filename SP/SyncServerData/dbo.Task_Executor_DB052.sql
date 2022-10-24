/*<info serverAlias="DBSUM-bodb02,DBLIC-bodb02,DBFS-bodb02" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].Task_Executor_DB052
AS
/*
	Created: 20220603@Sol
	Task: Database - Sync-up Standby Server data - [Redmine:167261]
	Database: DBSUM-bodb02,DBLIC-bodb02,DBFS-bodb02
	
	Revision:
		- 20220603@Sol: Database - Sync-up Standby Server data - [Redmine:167261]
		
	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON;

	-- check if have failed steps
	IF EXISTS (SELECT TOP 1 1 FROM JobExecutionQueue WITH(NOLOCK) WHERE ExecStatus IN ('Failed') )
	BEGIN
		RAISERROR ('Uncompleted steps found, please help check!',16,1)
		RETURN
	END

	--running sp, return 
	IF EXISTS (SELECT TOP 1 1 FROM JobExecutionQueue WITH(NOLOCK) WHERE ExecStatus IN ('Running') )
	BEGIN
		RETURN
	END

	---most of time will have nothing to do - return
	IF NOT EXISTS (SELECT TOP 1 1 FROM JobExecutionQueue WITH(NOLOCK) WHERE ExecStatus = 'Waiting' )
	BEGIN
		RETURN
	END

	---general variables
	DECLARE @queueId INT,
			@spName VARCHAR(200),	
			@params VARCHAR(MAX),
			@xml XML,
			@errMsg VARCHAR(1000)

	---variables for specific sp
	DECLARE @tblRecover7Days TABLE (Winlostdate DATETIME, CustIds VARCHAR(MAX), FromDate DATETIME, ToDate DATETIME, Mode INT, IsCheckDataOnly BIT)
	DECLARE 
		@winlostdate DATETIME,
		@custids VARCHAR(MAX),
		@fromDate DATETIME,
		@toDate DATETIME,
		@mode INT,
		@generateData TINYINT,
		@betTypes VARCHAR(MAX),
		@IsParlay VARCHAR(20),
		@IsCheckDataOnly BIT

	---instant running
	WHILE NOT EXISTS (SELECT TOP 1 1 FROM JobExecutionQueue WITH(NOLOCK) WHERE ExecStatus IN ('Running','Failed') AND PriorityOrder = 1 )
	BEGIN
		--- clean up table variable
		DELETE FROM @tblRecover7Days

		--- pick step which type = 1 to execute
		SELECT TOP(1) @queueId = t.QueueId, @spName = t.SpName, @params = t.Params
		FROM JobExecutionQueue t WITH(NOLOCK)
		WHERE PriorityOrder = 1 
			AND ExecStatus = 'Waiting'
		ORDER BY t.QueueId

		IF @@ROWCOUNT = 0
			BREAK; 

		--- update status to running
		UPDATE JobExecutionQueue
		SET ExecStatus = 'Running',
			ModifiedDate = GETDATE()
		WHERE QueueId = @queueId
			AND ExecStatus = 'Waiting'

		IF @@ROWCOUNT > 0
		BEGIN
			BEGIN TRY
				--step 2.1
				IF (@spName = 'bodb_summary.dbo.Task_CS_SumWinloss_14')
				BEGIN
            		---get/set params
					SET @xml = @params
				
					INSERT INTO @tblRecover7Days(Winlostdate, CustIds)
					SELECT	
						t.c.value('@w', 'DATETIME')	AS WinlostDate,
						t.c.value('@c', 'VARCHAR(MAX)') AS CustIds
					FROM @xml.nodes('/root') AS t(c)

					SELECT @winlostdate = Winlostdate , @custids = CustIds FROM @tblRecover7Days

					---run sp
					--EXEC bodb_summary.dbo.Task_CS_SumWinloss_14
					--	   @WinlostDate = @WinlostDate,
					--	   @CustIds = @CustIds

					SELECT 'bodb_summary.dbo.Task_CS_SumWinloss_14' , @WinlostDate, @CustIds


				END
				--step 2.2
				ELSE IF (@spName = 'bodb_summary.dbo.Task_CS_SumCancelled_14')
				BEGIN  
            		---get/set params
					SET @xml = @params
				
					INSERT INTO @tblRecover7Days(Winlostdate, CustIds)
					SELECT	
						t.c.value('@w', 'DATETIME')	AS WinlostDate,
						t.c.value('@c', 'VARCHAR(MAX)') AS CustIds
					FROM @xml.nodes('/root') AS t(c)

					SELECT @winlostdate = Winlostdate , @custids = CustIds FROM @tblRecover7Days

					---run sp
					--EXEC bodb_summary.dbo.Task_CS_SumCancelled_14
					--	@WinlostDate = @WinlostDate,
					--	@CustIds = @CustIds

					SELECT 'bodb_summary.dbo.Task_CS_SumCancelled_14', @WinlostDate, @custids
				END
			END TRY
			BEGIN CATCH
            	UPDATE JobExecutionQueue
				SET ExecStatus = 'Failed',
					ModifiedDate = GETDATE(),
					CompletedDate = GETDATE(),
					Remark = Remark + ' - ' + ERROR_MESSAGE()
				WHERE QueueId = @queueId
            END CATCH
		END

		--- set this stepno is done with success 
		UPDATE JobExecutionQueue
		SET ExecStatus = 'Completed',
			ModifiedDate = GETDATE(),
			CompletedDate = GETDATE(),
			Remark = Remark + ' - ' + 'DONE'
		WHERE QueueId = @queueId
			
	END

	---return if there is no row with created time < current time
	IF NOT EXISTS (SELECT TOP 1 1 FROM JobExecutionQueue WITH(NOLOCK) WHERE ExecStatus = 'Running' AND PriorityOrder = 2 AND CreatedDate < CONVERT(VARCHAR, GETDATE(), 23) )
		RETURN

	---daily running
	WHILE NOT EXISTS (SELECT TOP 1 1 FROM JobExecutionQueue WITH(NOLOCK) WHERE ExecStatus = 'Waiting' AND PriorityOrder = 1 ) --- type = 1 get higher priority
			AND NOT EXISTS (SELECT TOP 1 1 FROM JobExecutionQueue WITH(NOLOCK) WHERE ExecStatus IN ('Running', 'Failed') AND PriorityOrder = 2 )
	BEGIN
		--- clean up table variable
		DELETE FROM @tblRecover7Days

		--- pick step which type = 1 to execute
		SELECT TOP(1) @queueId = t.QueueId, @spName = t.SpName, @params = t.Params
		FROM JobExecutionQueue t WITH(NOLOCK)
		WHERE PriorityOrder = 2
			AND ExecStatus = 'Waiting'
			AND CreatedDate < CONVERT(VARCHAR, GETDATE(), 23)
		ORDER BY t.QueueId

		IF @@ROWCOUNT = 0
			BREAK; 

		--- update status to running
		UPDATE JobExecutionQueue
		SET ExecStatus = 'Running',
			ModifiedDate = GETDATE()
		WHERE QueueId = @queueId
			AND ExecStatus = 'Waiting'
			AND CreatedDate < CONVERT(VARCHAR, GETDATE(), 23)

		IF @@ROWCOUNT > 0
		BEGIN
			BEGIN TRY
				--step 6.01
				IF (@spName = 'bodb_LicenseeReport.dbo.Task_PrepareStaging')
				BEGIN  
            		---get/set params
					SET @xml = @params
				
					INSERT INTO @tblRecover7Days(FromDate, ToDate)
					SELECT	
						t.c.value('@fd', 'DATETIME') AS fromDate,
						t.c.value('@td', 'DATETIME') AS toDate
					FROM @xml.nodes('/root') AS t(c)

					SELECT @fromDate = FromDate, @toDate = ToDate FROM @tblRecover7Days

					---run sp
					EXEC bodb_LicenseeReport.dbo.Task_PrepareStaging
						@datefrom = @fromDate,
						@dateto = @toDate, 
						@ErrorMsg = @errMsg OUTPUT  

					IF @errMsg <> ''
					BEGIN
						RAISERROR(@errMsg, 16, 1)
					END
				END
				--step 6.02
				ELSE IF (@spName = 'bodb_LicenseeReport.dbo.Task_rptBetting_CheckData')
				BEGIN 
            		---get/set params
					SET @xml = @params
					SET @generateData = 0
				
					INSERT INTO @tblRecover7Days(Winlostdate)
					SELECT	
						t.c.value('@w', 'DATETIME')	AS WinlostDate
					FROM @xml.nodes('/root') AS t(c)

					SELECT @WinlostDate = Winlostdate FROM @tblRecover7Days

					---run sp
					EXEC bodb_LicenseeReport.dbo.Task_rptBetting_CheckData 
						@WinlostDate	 = @WinlostDate,
						@HasDataMismatch = @generateData OUTPUT,
						@BetTypes = @BetTypes OUTPUT

					IF (@generateData <> 0)
					BEGIN 
						BEGIN TRY
							EXEC bodb_LicenseeReport.dbo.GEN_rptBetting @date = @WinlostDate, @date2 = @WinlostDate
						END TRY
						BEGIN CATCH
							SET @errmsg = 'step 6.03' + ' - ' + ERROR_MESSAGE()			
							RAISERROR(@errmsg, 16, 1)
						END CATCH
						
						BEGIN TRY
							EXEC bodb_LicenseeReport.dbo.GEN_rptBettingByProduct
								@date = @winlostdate,
								@date2 = @winlostdate,
								@DataSource = 'rpt_Betting'
						END TRY
						BEGIN CATCH
							SET @errmsg = 'step 6.04' + ' - ' + ERROR_MESSAGE()			
							RAISERROR(@errmsg, 16, 1)
						END CATCH
					END
				END
				--step 6.05
				ELSE IF (@spName = 'bodb_LicenseeReport.dbo.Task_PostStaging')
				BEGIN  
					---run sp
					EXEC bodb_LicenseeReport.dbo.Task_PostStaging
				END
				--step 6.06
				ELSE IF (@spName = 'bodb_LicenseeReport.dbo.Task_rptBettingBySport_CheckData')
				BEGIN  
            		---get/set params
					SET @xml = @params
					SET @generateData = 0
				
					INSERT INTO @tblRecover7Days(Winlostdate)
					SELECT	
						t.c.value('@w', 'DATETIME')	AS WinlostDate
					FROM @xml.nodes('/root') AS t(c)

					SELECT @WinlostDate = Winlostdate FROM @tblRecover7Days

					---run sp
					EXEC bodb_LicenseeReport.dbo.Task_rptBettingBySport_CheckData 
						@WinlostDate = @WinlostDate,
						@HasDataMismatch = @generateData OUTPUT,
						@IsParlay = @IsParlay OUTPUT  

					IF @generateData <> 0
					BEGIN
						BEGIN TRY
							EXEC bodb_LicenseeReport.dbo.GEN_rptBettingBySport14 @Date = @WinlostDate
						END TRY
						BEGIN CATCH
							SET @errmsg = 'step 6.07' + ' - ' + ERROR_MESSAGE()			
							RAISERROR(@errmsg, 16, 1)
						END CATCH
					END
				END
				--step 6.08
				ELSE IF (@spName = 'bodb_LicenseeReport.dbo.Task_DailyRptLicWinloss2')
				BEGIN  
            		---get/set params
					SET @xml = @params
				
					INSERT INTO @tblRecover7Days(Winlostdate)
					SELECT	
						t.c.value('@w', 'DATETIME')	AS WinlostDate
					FROM @xml.nodes('/root') AS t(c)

					SELECT @WinlostDate = Winlostdate FROM @tblRecover7Days

					---run sp
					EXEC bodb_LicenseeReport.dbo.Task_DailyRptLicWinloss2 @winlostdate = @WinlostDate
				END
				--step 6.09
				ELSE IF (@spName = 'bodb_LicenseeReport.dbo.Task_rptCustomerTurnOver_Bettrans14')
				BEGIN  
            		---get/set params
					SET @xml = @params
				
					INSERT INTO @tblRecover7Days(Winlostdate)
					SELECT	
						t.c.value('@d', 'DATETIME')	AS WinlostDate
					FROM @xml.nodes('/root') AS t(c)

					SELECT @WinlostDate = Winlostdate FROM @tblRecover7Days

					---run sp
					EXEC bodb_LicenseeReport.dbo.Task_rptCustomerTurnOver_Bettrans14 @Date = @WinlostDate
				END
				--step 6.10
				ELSE IF (@spName = 'bodb_LicenseeReport.dbo.Task_rptWinlostbyleague_Bettrans14')
				BEGIN  
            		---get/set params
					SET @xml = @params
				
					INSERT INTO @tblRecover7Days(Winlostdate)
					SELECT	
						t.c.value('@d', 'DATETIME')	AS WinlostDate
					FROM @xml.nodes('/root') AS t(c)

					SELECT @WinlostDate = Winlostdate FROM @tblRecover7Days

					---run sp
					EXEC bodb_LicenseeReport.dbo.Task_rptWinlostbyleague_Bettrans14 @Date = @WinlostDate
				END
				--step 6.11
				ELSE IF (@spName = 'bodb_LicenseeReport.dbo.Task_rptCustomerMatch_Bettrans14')
				BEGIN  
            		---get/set params
					SET @xml = @params
				
					INSERT INTO @tblRecover7Days(Winlostdate)
					SELECT	
						t.c.value('@d', 'DATETIME')	AS WinlostDate
					FROM @xml.nodes('/root') AS t(c)

					SELECT @WinlostDate = Winlostdate FROM @tblRecover7Days

					---run sp
					EXEC bodb_LicenseeReport.dbo.Task_rptCustomerMatch_Bettrans14 @Date = @WinlostDate
				END
				--step 6.12
				ELSE IF (@spName = 'bodb_LicenseeReport.dbo.GEN_rptBetting_Parlay14')
				BEGIN  
            		---get/set params
					SET @xml = @params
				
					INSERT INTO @tblRecover7Days(FromDate, ToDate)
					SELECT	
						t.c.value('@fd', 'DATETIME')	AS fromDate,
						t.c.value('@td', 'DATETIME')	AS toDate
					FROM @xml.nodes('/root') AS t(c)

					SELECT @fromDate = FromDate, @toDate = ToDate FROM @tblRecover7Days

					---run sp
					EXEC bodb_LicenseeReport.dbo.GEN_rptBetting_Parlay14
						@datefrom = @fromDate,
						@dateto = @toDate
				END
				--step 6.13
				ELSE IF (@spName = 'bodb_LicenseeReport.dbo.Task_DailyRptLicWinlossGMT_Bettrans14')
				BEGIN  
            		---get/set params
					SET @xml = @params
				
					INSERT INTO @tblRecover7Days(FromDate)
					SELECT	
						t.c.value('@fd', 'DATETIME')	AS fromDate
					FROM @xml.nodes('/root') AS t(c)

					SELECT @fromDate = FromDate FROM @tblRecover7Days

					---run sp
					EXEC bodb_LicenseeReport.dbo.Task_DailyRptLicWinlossGMT_Bettrans14 @FromDate = @fromDate
				END
				--step 6.14
				ELSE IF (@spName = 'bodb_LicenseeReport.dbo.Task_DailySummaryLicPromotion_Bettrans14')
				BEGIN  
            		---get/set params
					SET @xml = @params
				
					INSERT INTO @tblRecover7Days(Winlostdate, IsCheckDataOnly)
					SELECT	
						t.c.value('@pd', 'DATETIME') AS promoDate,
						t.c.value('@i', 'BIT') AS IsCheckDataOnly
					FROM @xml.nodes('/root') AS t(c)

					SELECT @WinLostDate = Winlostdate, @IsCheckDataOnly = IsCheckDataOnly FROM @tblRecover7Days

					---run sp
					EXEC bodb_LicenseeReport.dbo.Task_DailySummaryLicPromotion_Bettrans14 @PromoDate = @winlostdate, @IsCheckDataOnly = @IsCheckDataOnly
				END
				--step 6.15
				ELSE IF (@spName = 'bodb_LicenseeReport.dbo.Task_Microgaming_Bettrans14')
				BEGIN  
            		---get/set params
					SET @xml = @params
				
					INSERT INTO @tblRecover7Days(FromDate, ToDate)
					SELECT	
						t.c.value('@fd', 'DATETIME') AS FromDate,
						t.c.value('@td', 'DATETIME') AS ToDate
					FROM @xml.nodes('/root') AS t(c)

					SELECT @fromDate = FromDate, @toDate = ToDate FROM @tblRecover7Days

					---run sp
					EXEC bodb_LicenseeReport.dbo.Task_Microgaming_Bettrans14 @FromDate = @fromDate, @Todate = @Todate
				END
				--step 7
				ELSE IF (@spName = 'bodb_FraudSensor.dbo.FS_Task_MatchDailyDataCapture')
				BEGIN  
            		---get/set params
					SET @xml = @params
				
					INSERT INTO @tblRecover7Days(FromDate, ToDate)
					SELECT	
						t.c.value('@gfd', 'DATETIME') AS genFromDate,
						t.c.value('@gtd', 'DATETIME') AS genToDate
					FROM @xml.nodes('/root') AS t(c)

					SELECT @FromDate = FromDate, @ToDate = ToDate FROM @tblRecover7Days

					---run sp
					EXECUTE bodb_FraudSensor.dbo.FS_Task_MatchDailyDataCapture @GenerateFromDate = @FromDate, @GenerateToDate = @toDate
				END

			END TRY
			BEGIN CATCH
            	UPDATE JobExecutionQueue
				SET ExecStatus = 'Failed',
					ModifiedDate = GETDATE(),
					CompletedDate = GETDATE(),
					Remark = Remark + ' - ' + ERROR_MESSAGE()
				WHERE QueueId = @queueId
            END CATCH
		END

		--- set this stepno is done with success 
		UPDATE JobExecutionQueue
		SET ExecStatus = 'Completed',
			ModifiedDate = GETDATE(),
			CompletedDate = GETDATE(),
			Remark = Remark + ' - ' + 'DONE'
		WHERE QueueId = @queueId
			
	END
END