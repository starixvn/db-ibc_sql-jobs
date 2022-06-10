/*<info serverAlias="DBTXN-bodb02" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].Task_Executor_DB061
AS
/*
	Created: 20220603@Sol
	Task: Database - Sync-up Standby Server data - [Redmine:167261]
	Database: DBTXN-bodb02
	
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
				--step 3
				IF (@spName = 'bodb02.dbo.Task_CS_HeadlineBalance14')
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
					EXEC bodb02.dbo.Task_CS_HeadlineBalance14
						@Winlostdate = @Winlostdate,
						@CustIds        = @CustIds
				END
				--step 4
				ELSE IF (@spName = 'bodb_report.dbo.Task_rptStatement_14')
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
					EXEC bodb_report.dbo.Task_rptStatement_14
						@WinlostDate = @WinlostDate,
						@CustIds = @CustIds
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
				--step 5.1
				IF (@spName = 'bodb02.dbo.Acc_ResetWinning_SelByDate14')
				BEGIN  
            		---get/set params
					SET @xml = @params
				
					INSERT INTO @tblRecover7Days(Winlostdate, Mode)
					SELECT	
						t.c.value('@w', 'DATETIME')	AS WinlostDate,
						t.c.value('@m', 'INT') AS CustIds
					FROM @xml.nodes('/root') AS t(c)

					SELECT @winlostdate = Winlostdate , @mode = Mode FROM @tblRecover7Days

					---run sp
					EXEC bodb02.dbo.Acc_ResetWinning_SelByDate14
						@Winlostdate = @Winlostdate,
						@Mode = @mode
				END
				--step 5.2
				ELSE IF (@spName = 'bodb02.dbo.Task_ResetWinning_ExtraPT14')
				BEGIN  
            		---get/set params
					SET @xml = @params
				
					INSERT INTO @tblRecover7Days(FromDate, ToDate, Mode)
					SELECT	
						t.c.value('@fd', 'DATETIME')	AS fromDate,
						t.c.value('@td', 'DATETIME')	AS toDate,
						t.c.value('@m', 'INT') AS Mode
					FROM @xml.nodes('/root') AS t(c)

					SELECT @fromdate = FromDate, @todate = ToDate, @mode = Mode FROM @tblRecover7Days

					---run sp
					EXEC bodb02.dbo.Task_ResetWinning_ExtraPT14
						@FromDate= @fromdate,
						@ToDate = @todate,
						@Mode = @mode
				END
				--step 8
				ELSE IF (@spName = 'bodb_TGRS.dbo.Task_RegenerateTGRSData')
				BEGIN  
            		---get/set params
					SET @xml = @params
				
					INSERT INTO @tblRecover7Days(FromDate, ToDate, Mode)
					SELECT	
						t.c.value('@fd', 'DATETIME') AS fromDate,
						t.c.value('@td', 'DATETIME') AS toDate,
						t.c.value('@m', 'INT') AS Mode
					FROM @xml.nodes('/root') AS t(c)

					SELECT @fromdate = FromDate, @todate = ToDate, @mode = Mode FROM @tblRecover7Days

					---run sp
					EXECUTE bodb_TGRS.dbo.Task_RegenerateTGRSData @FromDate = @fromdate, @ToDate = @todate, @Flagged = @mode
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