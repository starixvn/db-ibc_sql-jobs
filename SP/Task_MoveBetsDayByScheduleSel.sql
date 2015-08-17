ALTER PROCEDURE [dbo].[Task_MoveBetsDayByScheduleSel]
AS  
/*		
	Creator:20150807@Sophia
	Task: Get Move bets day by Schedule 
	DB: DBTXN/bodb02
		
	Revisions:			
		
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
	

	/* 
	----- Update schedule manually
	UPDATE	@Schedule
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

GO
GRANT EXECUTE ON [dbo].[Task_MoveBetsDayByScheduleSel] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Task_MoveBetsDayByScheduleSel] TO [vnteam] AS [dbo]
GO