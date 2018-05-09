/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isNested="0"></info>*/
USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Task_DailySummary_Job]
AS
/*  
   	** NOTE: 
		- if modify anything here.  
		- go check and modify SP Task_DailySummary_Job_IP2Country as well  
   
    Created by: Unknow  
	Date: Unknow  
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
 */

BEGIN 
	CHECKPOINT

	--DBCC DROPCLEANBUFFERS  
	--EXEC sp_updatestats  
	--DBCC FREEPROCCACHE  

	/* ---- Old Code 
	DECLARE @WeekDay TINYINT

	SET @WeekDay = DATEPART(weekday, CURRENT_TIMESTAMP)

	DECLARE @Todaym1 DATETIME
		,@Todaym2 DATETIME
		,@Todaym3 DATETIME
		,@Todaym4 DATETIME

	SET @Todaym1 = DATEADD(day, - 1, CONVERT(VARCHAR(10), CURRENT_TIMESTAMP, 120))
	SET @Todaym2 = DATEADD(day, - 1, @Todaym1)
	SET @Todaym3 = DATEADD(day, - 1, @Todaym2)
	SET @Todaym4 = DATEADD(day, - 1, @Todaym3)

	-- Server Time : Monday (2)  
	-- Local Time  : Tuesday's morning  
	IF @WeekDay = 2  
	BEGIN  
		EXEC dbo.Task_DailySummary @Todaym4 -- Thursday  
	END  
	-- Server Time : Tuesday (3)  
	-- Local Time  : Wednesday's morning  
	ELSE IF @WeekDay = 3  
	BEGIN  
		EXEC dbo.Task_DailySummary @Todaym4 -- Friday  
		EXEC dbo.Task_DailySummary @Todaym3 -- Saturday  
	END  
	-- Server Time : Wednesday (4)  
	-- Local Time  : Thursday's morning  
	ELSE IF @WeekDay = 4  
	BEGIN  
		EXEC dbo.Task_DailySummary @Todaym3 -- Sunday  
		EXEC dbo.Task_DailySummary @Todaym2 -- Monday  
	END  
	-- Server Time : Friday (6)  
	-- Local Time  : Saturday's morning  
	ELSE IF @WeekDay = 6  
	BEGIN  
		EXEC dbo.Task_DailySummary @Todaym3 -- Tuesday  
		EXEC dbo.Task_DailySummary @Todaym2 -- Wednesday  
		--EXEC dbo.Task_DailySummary @Todaym1 -- Thursday  
	END
	ELSE
	BEGIN
		RETURN - 1
	END
	*/
	
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

				EXEC dbo.Task_DailySummary @RunningDay 
		
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