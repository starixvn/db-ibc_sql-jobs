USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Task_MoveBetsDayByScheduleSel]    Script Date: 06/14/2016 02:30:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Task_MoveBetsDayByScheduleSel    Script Date: 8/17/2015 10:18:00 AM ******/
ALTER PROCEDURE [dbo].[Task_MoveBetsDayByScheduleSel]
AS  

/*		
	Creator:20150807@Sophia
	Task: Get Move bets day by Schedule 
	DB: DBTXN/bodb02
		
	Revisions:			
		20150925@Harris: skip move bet for Balance Issue
		20160129@Harris: Skip move bet for One RNG settle issue
		20160201@Harris: Skip move bet for 27Jan again
		20160517@Harris: #57686 change move bet for 13May to 20160518 morning(gmt+7)  
		20160614@Harris: #59313 change move bet in period 15-19Jun  

*/
BEGIN 
	SET NOCOUNT ON 	
	
	DECLARE @Today DATETIME
			,@Todaym1 DATETIME
			,@Todaym2 DATETIME
			,@Todaym3 DATETIME
			,@Todaym4 DATETIME
			,@WeekDay TINYINT
	
	SET @Today = CURRENT_TIMESTAMP
	--select  cast (@today as DATE)
	SET @WeekDay = DATEPART(WEEKDAY, @Today)

	SET @Todaym1 = DATEADD(day, - 1, CONVERT(VARCHAR(10), @Today, 120))
	SET @Todaym2 = DATEADD(day, - 1, @Todaym1)
	SET @Todaym3 = DATEADD(day, - 1, @Todaym2)
	SET @Todaym4 = DATEADD(day, - 1, @Todaym3)
	

	DECLARE @Schedule AS TABLE (ScheduleId TINYINT, WeekDay TINYINT, RunningDay DATETIME, ManualDay DATETIME, IsManual BIT)
	INSERT INTO @Schedule (ScheduleId, WeekDay, RunningDay, ManualDay, IsManual)  
	VALUES	  (1, 2, @Todaym4, NULL , 0 ) --- Thursday
			, (2, 2, @Todaym3, NULL , 0 ) --- Friday 
			, (3, 3, @Todaym3, NULL , 0 ) --- Saturday
			, (4, 4, @Todaym3, NULL , 0 ) --- Sunday
			, (5, 6, @Todaym4, NULL , 0 ) --- Monday
			, (6, 6, @Todaym3, NULL , 0 ) --- Tuesday
			, (7, 7, @Todaym3, NULL , 0 ) --- Wednesday
	

	--- Update schedule manually
	--	20160614@Harris: #59313 change move bet in period 15-19Jun  

	IF CAST (@today as DATE) = '20160614' -- Wednesday morning 
		BEGIN
			update @Schedule
			set IsManual = 1, WeekDay = 3,ManualDay = '20160612'
			where scheduleID = 4 -- move bet for Sunday 12Jun // Saturday is moved by current schedule
		END
	
	IF CAST (@today as DATE) = '20160615' -- Thursday morning 
		BEGIN
			update @Schedule
			set IsManual = 1,ManualDay = '20160613'
			where scheduleID = 4 -- move bet for Monday 13Jun 
		END
	
	-- Friday morning is skipped as default
	
	IF CAST (@today as DATE) = '20160617' -- Saturday morning 
		BEGIN
			update @Schedule
			set IsManual = 1,ManualDay = '20160614'
			where scheduleID = 5 -- move bet for Tuesday 14Jun 
			
			update @Schedule
			set IsManual = 1,ManualDay = '20160615'
			where scheduleID = 6 -- move bet for Wednesday 15Jun 
		END
	
	IF CAST (@today as DATE) = '20160618' -- Sunday morning
		BEGIN
			update @Schedule
			set IsManual = 1,ManualDay = '20160616'
			where scheduleID = 7 -- move bet for Thursday 16Jun 
		END
	
	/*UPDATE	@Schedule
	SET		ManualDay = @Todaym2 
			, IsManual = 1
	WHERE	ScheduleId = 1

	UPDATE	@Schedule
	SET		ManualDay = @Todaym1 
			, IsManual = 1
	WHERE	ScheduleId = 2
 */
	
 
 
	SELECT	ScheduleId, CASE WHEN IsManual = 0 THEN RunningDay ELSE ManualDay END AS MoveBetsDay
	FROM	@Schedule 
	WHERE	WeekDay = @WeekDay
	ORDER BY ScheduleId
	   
END




