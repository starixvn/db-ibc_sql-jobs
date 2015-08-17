USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Task_DailySummary_Job_IP2Country]    Script Date: 08/06/2015 02:02:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_DailySummary_Job_IP2Country]
AS
/*  
	Created by: unknow  
	Task: 
	DB: DBTXN.bodb02  

	Revision:  
		- 20140622@Thien: revise the job schedule for WC 2014, to perform Move Bet every day except Friday's morning (Balance Up day)  
		- 20150806@Sophia: Control schedule by a new store procedure

*/
BEGIN 

	CHECKPOINT
	/*
	--DBCC DROPCLEANBUFFERS  
	--EXEC sp_updatestats  
	--DBCC FREEPROCCACHE  
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
		EXEC dbo.Task_DailySummary_IP2Country @Todaym4 -- Thursday  
	END  
	-- Server Time : Tuesday (3)  
	-- Local Time  : Wednesday's morning  
	ELSE IF @WeekDay = 3  
	BEGIN  
		EXEC dbo.Task_DailySummary_IP2Country @Todaym4 -- Friday  
		EXEC dbo.Task_DailySummary_IP2Country @Todaym3 -- Saturday  
	END  
	-- Server Time : Wednesday (4)  
	-- Local Time  : Thursday's morning  
	ELSE IF @WeekDay = 4  
	BEGIN  
		EXEC dbo.Task_DailySummary_IP2Country @Todaym3 -- Sunday  
		EXEC dbo.Task_DailySummary_IP2Country @Todaym2 -- Monday  
	END  
	-- Server Time : Friday (6)  
	-- Local Time  : Saturday's morning  
	ELSE IF @WeekDay = 6  
	BEGIN  
		EXEC dbo.Task_DailySummary_IP2Country @Todaym3 -- Tuesday  
		EXEC dbo.Task_DailySummary_IP2Country @Todaym2 -- Wednesday  
		--EXEC dbo.Task_DailySummary_IP2Country @Todaym1 -- Thursday  
	END		
	ELSE
	BEGIN
		RETURN - 1
	END
	*/
	
	
	DECLARE @Days AS TABLE (ScheduleId TINYINT, RunningDay DATETIME, IsFinish BIT DEFAULT (0))
	INSERT INTO @Days (ScheduleId, RunningDay)
	EXEC DBTXN.bodb02.dbo.Task_MoveBetsDayByScheduleSel 

	DECLARE @RunningDay DATETIME , @ScheduleId TINYINT
	
	IF NOT EXISTS (SELECT TOP 1 1 FROM @Days)
	BEGIN 
		RETURN -1
	END 
	ELSE
	BEGIN 
		WHILE 1 = 1 
		BEGIN 
			IF EXISTS (SELECT TOP 1 1 FROM @Days WHERE IsFinish = 0)
			BEGIN 
				SELECT  TOP 1 @RunningDay = RunningDay, @ScheduleId = ScheduleId
				FROM	@Days
				WHERE	IsFinish = 0
				ORDER BY ScheduleId 

				EXEC dbo.Task_DailySummary_IP2Country @RunningDay 
		
				UPDATE  @Days
				SET		IsFinish = 1
				WHERE	ScheduleId = @ScheduleId
						
			END
			ELSE 
				BREAK
		END	
	END

	   
END    


