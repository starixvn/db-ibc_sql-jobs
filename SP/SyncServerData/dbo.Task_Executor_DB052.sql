/*<info serverAlias="DBAGE-bodb02" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].Task_Executor_DB052
AS
/*
	Created: 20220603@Sol
	Task: Database - Sync-up Standby Server data - [Redmine:167261]
	Database: DBAGE-bodb02
	
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
			@serverName VARCHAR(200),
			@aliasName VARCHAR(200),	
			@sqlCommand VARCHAR(MAX),
			@params VARCHAR(MAX),
			@xml XML,
			@errMsg VARCHAR(1000)

	DECLARE @GenerateData TINYINT = 0

	---variables for specific sp
	DECLARE @tblParams TABLE (Winlostdate DATETIME)
	DECLARE 
		@winlostdate DATETIME
		

	---instant running
	WHILE NOT EXISTS (SELECT TOP 1 1 FROM JobExecutionQueue WITH(NOLOCK) WHERE ExecStatus IN ('Running','Failed'))
	BEGIN

		--- pick step which type = 1 to execute
		SELECT TOP(1) @queueId = t.QueueId, @serverName = t.ServerName, @aliasName = t.AliasName, @sqlCommand = t.SqlCommand, @params = t.Params
		FROM JobExecutionQueue t WITH(NOLOCK)
		WHERE ExecStatus = 'Waiting'
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
				IF (@sqlCommand LIKE '%bodb_LicenseeReport.dbo.Task_rptBetting_CheckData%')
				BEGIN
					SET @GenerateData = 0
					SET @sqlCommand = @sqlCommand + ',@HasDataMismatch = @GenerateData OUTPUT'

					EXEC sys.sp_executesql @sqlCommand, N'@GenerateData TINYINT OUTPUT', @GenerateData = @GenerateData OUTPUT

					IF (@generateData <> 0)
					BEGIN
						--- clean up table variable
						DELETE FROM @tblParams

						---get/set params
						SET @xml = @params
				
						INSERT INTO @tblParams(Winlostdate)
						SELECT	
							t.c.value('@wld', 'DATETIME') AS WinlostDate
						FROM @xml.nodes('/root') AS t(c)

						SELECT @winlostdate = Winlostdate FROM @tblParams

						SET @errmsg = 'step 6.03'
						EXEC bodb_LicenseeReport.dbo.GEN_rptBetting @date = @WinlostDate, @date2 = @WinlostDate
						
						SET @errmsg = 'step 6.04'
						EXEC bodb_LicenseeReport.dbo.GEN_rptBettingByProduct
								@date = @winlostdate,
								@date2 = @winlostdate,
								@DataSource = 'rpt_Betting'
						
					END
				END
				ELSE IF (@sqlCommand LIKE '%bodb_LicenseeReport.dbo.Task_rptBettingBySport_CheckData%')
				BEGIN
					SET @GenerateData = 0
					SET @sqlCommand = @sqlCommand + ',@HasDataMismatch = @GenerateData OUTPUT'

					EXEC sys.sp_executesql @sqlCommand, N'@GenerateData TINYINT OUTPUT', @GenerateData = @GenerateData OUTPUT

					IF (@generateData <> 0)
					BEGIN
						--- clean up table variable
						DELETE FROM @tblParams

						---get/set params
						SET @xml = @params
				
						INSERT INTO @tblParams(Winlostdate)
						SELECT	
							t.c.value('@wld', 'DATETIME') AS WinlostDate
						FROM @xml.nodes('/root') AS t(c)

						SELECT @winlostdate = Winlostdate FROM @tblParams

						SET @errmsg = 'step 6.07'
						EXEC bodb_LicenseeReport.dbo.GEN_rptBettingBySport14 @date = @WinlostDate
						
					END
				END
				ELSE
				BEGIN
					EXEC sys.sp_executesql @sqlCommand
				END
			END TRY
			BEGIN CATCH
            	UPDATE JobExecutionQueue
				SET ExecStatus = 'Failed',
					ModifiedDate = GETDATE(),
					CompletedDate = GETDATE(),
					Remark = Remark + ' - ' + @errmsg + ' - ' + ERROR_MESSAGE()
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