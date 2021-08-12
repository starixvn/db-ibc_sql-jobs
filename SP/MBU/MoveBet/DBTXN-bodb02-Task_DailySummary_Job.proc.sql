SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
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
		EXEC dbo.Bet_ExecRep_09 @mode = 3
		EXEC dbo.ExecRep_09 @recommend = 0, @winlostdate = NULL, @parlay = 3, @tableName = 'SystemSettings'

		-- delete old data from bettranssum before movebet
		TRUNCATE TABLE dbo.bettranssum
		
		WHILE 1 = 1 
		BEGIN 
			IF EXISTS (SELECT TOP 1 1 FROM @Days WHERE IsFinish = 0)
			BEGIN 
				SELECT  TOP 1 @RunningDay = RunningDay, @ScheduleId = ScheduleId
				FROM	@Days
				WHERE	IsFinish = 0
				ORDER BY ScheduleId 

				EXEC dbo.Task_DailySummary @winlostdate = @RunningDay, @step = 1
				IF @@ERROR <> 0
				BEGIN
					RAISERROR('** DailySummary JOB Failed @ step = 1 **', 16, 1)
					RETURN
				END

				EXEC dbo.Task_DailySummary @winlostdate = @RunningDay, @step = 2
				IF @@ERROR <> 0
				BEGIN
					RAISERROR('** DailySummary JOB Failed @ step = 2 **', 16, 1)
					RETURN
				END

				EXEC dbo.Task_DailySummary @winlostdate = @RunningDay, @step = 3
				IF @@ERROR <> 0
				BEGIN
					RAISERROR('** DailySummary JOB Failed @ step = 3 **', 16, 1)
					RETURN
				END

				EXEC dbo.Task_DailySummary @winlostdate = @RunningDay, @step = 4
				IF @@ERROR <> 0
				BEGIN
					RAISERROR('** DailySummary JOB Failed @ step = 4 **', 16, 1)
					RETURN
				END

				EXEC dbo.Task_DailySummary @winlostdate = @RunningDay, @step = 5
				IF @@ERROR <> 0
				BEGIN
					RAISERROR('** DailySummary JOB Failed @ step = 5 **', 16, 1)
					RETURN
				END

				EXEC dbo.Task_DailySummary @winlostdate = @RunningDay, @step = 6
				IF @@ERROR <> 0
				BEGIN
					RAISERROR('** DailySummary JOB Failed @ step = 6 **', 16, 1)
					RETURN
				END

				EXEC dbo.Task_DailySummary @winlostdate = @RunningDay, @step = 7
				IF @@ERROR <> 0
				BEGIN
					RAISERROR('** DailySummary JOB Failed @ step = 7 **', 16, 1)
					RETURN
				END

				EXEC dbo.Task_DailySummary @winlostdate = @RunningDay, @step = 8
				IF @@ERROR <> 0
				BEGIN
					RAISERROR('** DailySummary JOB Failed @ step = 8 **', 16, 1)
					RETURN
				END

				EXEC dbo.Task_DailySummary @winlostdate = @RunningDay, @step = 9
				IF @@ERROR <> 0
				BEGIN
					RAISERROR('** DailySummary JOB Failed @ step = 9 **', 16, 1)
					RETURN
				END
		
				UPDATE  @Days
				SET		IsFinish = 1
				WHERE	ScheduleId = @ScheduleId
						
			END
			ELSE 
				BREAK
		END
		
		--//turn off isMovingBet_Local flag
		EXEC dbo.Bet_ExecRep_09 @mode = 4
		EXEC dbo.ExecRep_09 @recommend = 0, @winlostdate = NULL, @parlay = 4, @tableName = 'SystemSettings'
	END
END
GO
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/