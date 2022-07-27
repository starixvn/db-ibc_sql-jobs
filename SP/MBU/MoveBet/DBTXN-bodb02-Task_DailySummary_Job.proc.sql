/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE	[dbo].[Task_DailySummary_Job]
AS
/*
	** NOTE:
		- if modify anything here.
		- go check and modify SP Task_DailySummary_Job_IP2Country as well

	Created by: Unknown
	Date: Unknown
	Task: Job Move Bets
	DB: DBTXN.bodb02

	Revision:
		- 20140622@Thien: revise the job schedule for WC 2014, to perform Move Bet every day except Friday's morning (Balance Up day)
		- 20150806@Sophia: Control schedule by a new store procedure
		- 20160615@Viet: delete old data @ bettranssum before movebet
		- 20160909@Patrick: Record EndTime value to systemsettings table on dbtrans.bodb02
		- 20170915@Patrick: Update code for:
			+ Delete data bettrans/translog/bettransRnG/bettransLC/bettransG batch by batch
			+ Add more signal to replicated servers when MB/BU starting or done
			+ Set current datetime value to checktime field when insert ticket 19999
			+ When processing a line then insert itself and upline's to [List]
		- 20180329@Percy: Add Bet_ExecRep_09 [RedmineID: #92391]
		- 202010316@Patrick: Revise Movebet flow to support transfer 247 - Redmine: [#149927]
		- 20211214@Kathy: Separate Transfer Tickets[Redmine:#164197]
		- 20220720@Patrick: Support new transid [Redmine: #175666]
 */
BEGIN 
	CHECKPOINT
	
	DECLARE @Days AS TABLE (ScheduleId TINYINT, RunningDay DATETIME, IsFinish BIT DEFAULT (0))
	INSERT INTO @Days (ScheduleId, RunningDay)
		EXEC dbo.Task_MoveBetsDayByScheduleSel 

	DECLARE @RunningDay DATETIME , @ScheduleId TINYINT
	
	IF NOT EXISTS (SELECT TOP 1 1 FROM @Days)
	BEGIN 
		RETURN -1
	END 
	ELSE
	BEGIN 
		--Record endtime to systemsettings table
		DECLARE @TotalMoveBetDays TINYINT, @CurrentDateTime DATETIME
		SELECT @TotalMoveBetDays = COUNT(1), @CurrentDateTime = GETDATE()
		FROM @Days
		
		EXEC dbo.Task_EstimatedTimeForJobDone @IsMoveBet = 1
			, @CurrentDateTime = @CurrentDateTime
			, @TotalMoveBetDays = @TotalMoveBetDays
		
		--//turn on isMovingBet_Local flag
		--EXEC dbo.Bet_ExecRep_09 @mode = 3
		EXEC dbo.Transfer_ExecRep_02 @Mode = 1
		EXEC dbo.ExecRep_09 @recommend = 0, @winlostdate = NULL, @parlay = 3, @tableName = 'SystemSettings'

		-- delete old data from bettranssum before movebet
		TRUNCATE TABLE dbo.bettranssum

		DECLARE @__errorMessage VARCHAR(300), @__doing VARCHAR(300)
		
		WHILE 1 = 1 
		BEGIN 
			IF EXISTS (SELECT TOP 1 1 FROM @Days WHERE IsFinish = 0)
			BEGIN 
				SELECT  TOP 1 @RunningDay = RunningDay, @ScheduleId = ScheduleId
				FROM	@Days
				WHERE	IsFinish = 0
				ORDER BY ScheduleId 

				--//1: update ticket (if any) which winlostdate is not synced with eventdate 
				BEGIN TRY
					SET @__errorMessage = ''
					EXEC dbo.Task_DailySummary @winlostdate = @RunningDay, @step = 1
	
				END TRY
				BEGIN CATCH
					SET @__errorMessage = ERROR_MESSAGE()
					SET @__doing = 'DailySummary JOB Failed at step: ' + CAST(1 AS VARCHAR(10)) + ', errMsg: ' + @__errorMessage
					EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @__doing
		
					--throw exception and terminated process
					RAISERROR (@__errorMessage, 16, 1)
					RETURN
				END CATCH

				--//2: check qualify data && void UUS tickets
				BEGIN TRY
					SET @__errorMessage = ''
					EXEC dbo.Task_DailySummary @winlostdate = @RunningDay, @step = 2
	
				END TRY
				BEGIN CATCH
					SET @__errorMessage = ERROR_MESSAGE()
					SET @__doing = 'DailySummary JOB Failed at step: ' + CAST(2 AS VARCHAR(10)) + ', errMsg: ' + @__errorMessage
					EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @__doing
		
					--throw exception and terminated process
					RAISERROR (@__errorMessage, 16, 1)
					RETURN
				END CATCH

				--//3: generate sum tickets
				BEGIN TRY
					SET @__errorMessage = ''
					EXEC dbo.Task_DailySummary @winlostdate = @RunningDay, @step = 3
	
				END TRY
				BEGIN CATCH
					SET @__errorMessage = ERROR_MESSAGE()
					SET @__doing = 'DailySummary JOB Failed at step: ' + CAST(3 AS VARCHAR(10)) + ', errMsg: ' + @__errorMessage
					EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @__doing
		
					--throw exception and terminated process
					RAISERROR (@__errorMessage, 16, 1)
					RETURN
				END CATCH

				--//4: copy event | bet data to [14]
				BEGIN TRY
					SET @__errorMessage = ''
					EXEC dbo.Task_DailySummary @winlostdate = @RunningDay, @step = 4
	
				END TRY
				BEGIN CATCH
					SET @__errorMessage = ERROR_MESSAGE()
					SET @__doing = 'DailySummary JOB Failed at step: ' + CAST(4 AS VARCHAR(10)) + ', errMsg: ' + @__errorMessage
					EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @__doing
		
					--throw exception and terminated process
					RAISERROR (@__errorMessage, 16, 1)
					RETURN
				END CATCH

				--//5: insert data for sum_winloss
				BEGIN TRY
					SET @__errorMessage = ''
					EXEC dbo.Task_DailySummary @winlostdate = @RunningDay, @step = 5
	
				END TRY
				BEGIN CATCH
					SET @__errorMessage = ERROR_MESSAGE()
					SET @__doing = 'DailySummary JOB Failed at step: ' + CAST(5 AS VARCHAR(10)) + ', errMsg: ' + @__errorMessage
					EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @__doing
		
					--throw exception and terminated process
					RAISERROR (@__errorMessage, 16, 1)
					RETURN
				END CATCH

				--//6: insert sum ticket 19999
				BEGIN TRY
					SET @__errorMessage = ''
					EXEC dbo.Task_DailySummary @winlostdate = @RunningDay, @step = 6
	
				END TRY
				BEGIN CATCH
					SET @__errorMessage = ERROR_MESSAGE()
					SET @__doing = 'DailySummary JOB Failed at step: ' + CAST(6 AS VARCHAR(10)) + ', errMsg: ' + @__errorMessage
					EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @__doing
		
					--throw exception and terminated process
					RAISERROR (@__errorMessage, 16, 1)
					RETURN
				END CATCH

				--//7: wait for replicated servers perform done and then go to update movebetdate flag
				BEGIN TRY
					SET @__errorMessage = ''
					EXEC dbo.Task_DailySummary @winlostdate = @RunningDay, @step = 7
	
				END TRY
				BEGIN CATCH
					SET @__errorMessage = ERROR_MESSAGE()
					SET @__doing = 'DailySummary JOB Failed at step: ' + CAST(7 AS VARCHAR(10)) + ', errMsg: ' + @__errorMessage
					EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @__doing
		
					--throw exception and terminated process
					RAISERROR (@__errorMessage, 16, 1)
					RETURN
				END CATCH

				--//8: remove bet tickets
				BEGIN TRY
					SET @__errorMessage = ''
					EXEC dbo.Task_DailySummary @winlostdate = @RunningDay, @step = 8
	
				END TRY
				BEGIN CATCH
					SET @__errorMessage = ERROR_MESSAGE()
					SET @__doing = 'DailySummary JOB Failed at step: ' + CAST(8 AS VARCHAR(10)) + ', errMsg: ' + @__errorMessage
					EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @__doing
		
					--throw exception and terminated process
					RAISERROR (@__errorMessage, 16, 1)
					RETURN
				END CATCH

				--//9: movebet done
				BEGIN TRY
					SET @__errorMessage = ''
					EXEC dbo.Task_DailySummary @winlostdate = @RunningDay, @step = 9
	
				END TRY
				BEGIN CATCH
					SET @__errorMessage = ERROR_MESSAGE()
					SET @__doing = 'DailySummary JOB Failed at step: ' + CAST(9 AS VARCHAR(10)) + ', errMsg: ' + @__errorMessage
					EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @__doing
		
					--throw exception and terminated process
					RAISERROR (@__errorMessage, 16, 1)
					RETURN
				END CATCH

				--
				UPDATE @Days
				SET IsFinish = 1
				WHERE ScheduleId = @ScheduleId

			END
			ELSE
			BEGIN
				BREAK
			END
		END
		
		--//turn off isMovingBet_Local flag
		--EXEC dbo.Bet_ExecRep_09 @mode = 4
		EXEC dbo.Transfer_ExecRep_02 @Mode = 2
		EXEC dbo.ExecRep_09 @recommend = 0, @winlostdate = NULL, @parlay = 4, @tableName = 'SystemSettings'
	END
END
GO