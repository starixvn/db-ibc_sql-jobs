SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE	[dbo].[Task_MoveBetsDayByScheduleSel]
AS
/*
	Creator:20150807@Sophia
	Task: Get Move bets day by Schedule
	DB: DBTXN/bodb02

	Revisions
		- 20150925@Harris: skip move bet for Balance Issue
		- 20160129@Harris: Skip move bet for One RNG settle issue
		- 20160201@Harris: Skip move bet for 27Jan again
		- 20160517@Harris: #57686 change move bet for 13May to 20160518 morning(gmt+7)
		- 20160614@Harris: #59313 change move bet in period 15-19Jun
		- 20160615@Harris: #59317 Modify for EC schedule
		- 20160815@Harris: #62474 Modify for Aug 10 / Hold move bet as CSD requested
		- 20160831@Harris: #63383 Modify for Aug 28 / Hold move bet as CSD requested for matchid = 19603626
		- 20180617@Harris: #97040  Modify for WC2018
		- 20180626@Harris: #97040  Modify for WC2018 v3
		- 20180709@Harris: #97040  Modify for WC2018 v4
*/
BEGIN
	SET NOCOUNT ON

	 DECLARE @Today DATETIME
		,@Todaym1 DATETIME
		,@Todaym2 DATETIME
		,@Todaym3 DATETIME
		,@Todaym4 DATETIME
		,@WeekDay TINYINT
	--IF ISNULL(@today,'') = ''
	SET @Today = CURRENT_TIMESTAMP

	--select  cast (@today as DATE)
	SET @WeekDay = DATEPART(WEEKDAY, @Today)

	SET @Todaym1 = DATEADD(day, - 1, CONVERT(VARCHAR(10), @Today, 120))
	SET @Todaym2 = DATEADD(day, - 1, @Todaym1)
	SET @Todaym3 = DATEADD(day, - 1, @Todaym2)
	SET @Todaym4 = DATEADD(day, - 1, @Todaym3)


	DECLARE @Schedule AS TABLE (ScheduleId TINYINT, WeekDay TINYINT, RunningDay DATETIME, ManualDay DATETIME, IsManual BIT)
	INSERT INTO @Schedule (ScheduleId, WeekDay, RunningDay, ManualDay, IsManual)
	VALUES  (1, 2, @Todaym4, NULL , 0 ) --- Thursday
		, (2, 2, @Todaym3, NULL , 0 ) --- Friday
		, (3, 3, @Todaym3, NULL , 0 ) --- Saturday
		, (4, 4, @Todaym3, NULL , 0 ) --- Sunday
		, (5, 6, @Todaym4, NULL , 0 ) --- Monday
		, (6, 6, @Todaym3, NULL , 0 ) --- Tuesday
		, (7, 7, @Todaym3, NULL , 0 ) --- Wednesday

--- Update schedule manually
-- 20160614@Harris: #59313 change move bet in period 15-19Jun
-- 20160815@Harris: #62474 Modify for Aug 10 / Hold move bet as CSD requested
-- 20180617@Harris: #97040  Modify for WC2018
-- 20180626@Harris: #97040  Modify for WC2018 v3

/*
	IF CAST (@today as DATE) = '20180626' -- Wednesday morning // weekday = 3
	BEGIN
		UPDATE @Schedule
		SET WeekDay = 3, ManualDay = '20180624', IsManual = 1
		WHERE ScheduleId = 2
	END
*/


-- 20160615@Harris: #59317 Modify for EC schedule
-- 20160815@Harris: Comment below code for later big events
-- 20180617@Harris: #97040  Modify for WC2018
-- 20180626@Harris: #97040  Modify for WC2018 v3
-- 20180709@Harris: #97040  Modify for WC2018 v4

	IF CAST(@today as date) between '20180709' and '20180718'-- one week after EC  
	BEGIN
		DELETE @Schedule

		INSERT INTO @Schedule (ScheduleId, WeekDay, RunningDay, ManualDay, IsManual)
		VALUES   (1, 1, @Todaym2, NULL , 0 ) --- Friday
			, (2, 2, @Todaym2, NULL , 0 ) --- Saturday
			, (3, 3, @Todaym2, NULL , 0 ) --- Sunday
			, (4, 4, @Todaym2, NULL , 0 ) --- Monday
			, (5, 6, @Todaym3, NULL , 0 ) --- Tuesday
			, (6, 6, @Todaym2, NULL , 0 ) --- Wednesday
			, (7, 7, @Todaym2, NULL , 0 ) --- Thursday
	END
	IF CAST (@today as DATE) = '20180709' -- Wednesday morning // weekday = 3  
	BEGIN
		UPDATE @Schedule
		SET WeekDay = 0
		WHERE ScheduleId = 2
	END

	IF CAST (@today as DATE) = '20180718' -- Wednesday morning // weekday = 3  
	BEGIN
		UPDATE @Schedule
		SET WeekDay = 0
		WHERE ScheduleId = 4
	END

	SELECT ScheduleId, CASE WHEN IsManual = 0 THEN RunningDay ELSE ManualDay END AS MoveBetsDay
	FROM @Schedule
	WHERE WeekDay = @WeekDay
	ORDER BY ScheduleId
END
GO
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/