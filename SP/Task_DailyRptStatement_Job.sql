USE [bodb_Report]
GO

/****** Object:  StoredProcedure [dbo].[Task_DailyRptStatement_Job]    Script Date: 01/21/2015 22:45:17 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.Task_DailyRptStatement_Job    Script Date: 1/6/2015 9:35:00 AM ******/
CREATE PROCEDURE [dbo].[Task_DailyRptStatement_Job]


/*	Created by:  Cody
	Date: 20141229
	Task: Jobs daily for sum up data for rptStatement
	DB: DBRPT.bodb_report

	Revision:

*/

AS
	CHECKPOINT

	Declare @WeekDay tinyint
	SET @WeekDay = DATEPART(weekday, CURRENT_TIMESTAMP)

	Declare @Todaym1 datetime, @Todaym2 datetime, @Todaym3 datetime, @Todaym4 datetime
	SET @Todaym1 = DATEADD(day, -1, CONVERT(varchar(10), CURRENT_TIMESTAMP, 120))
	SET @Todaym2 = DATEADD(day, -1, @Todaym1)
	SET @Todaym3 = DATEADD(day, -1, @Todaym2)
	SET @Todaym4 = DATEADD(day, -1, @Todaym3)

	-- Server Time : Monday (2)
	-- Local Time  : Tuesday's morning
	IF @WeekDay = 2
	BEGIN
				EXEC dbo.Task_DailyRptStatement @Todaym4 -- Thursday
	END
	-- Server Time : Tuesday (3)
	-- Local Time  : Wednesday's morning
	ELSE IF @WeekDay = 3
	BEGIN
				EXEC dbo.Task_DailyRptStatement @Todaym4 -- Friday
				EXEC dbo.Task_DailyRptStatement @Todaym3 -- Saturday
	END
	-- Server Time : Wednesday (4)
	-- Local Time  : Thursday's morning
	ELSE IF @WeekDay = 4
	BEGIN
				EXEC dbo.Task_DailyRptStatement @Todaym3 -- Sunday
				EXEC dbo.Task_DailyRptStatement @Todaym2 -- Monday
	END
	-- Server Time : Friday (6)
	-- Local Time  : Saturday's morning
	ELSE IF @WeekDay = 6
	BEGIN
				EXEC dbo.Task_DailyRptStatement @Todaym3 -- Tuesday
				EXEC dbo.Task_DailyRptStatement @Todaym2 -- Wednesday
		--EXEC dbo.Task_DailySummary @Todaym1 -- Thursday
	END

	ELSE
	BEGIN
		RETURN -1
	END
GO

GRANT VIEW DEFINITION ON [dbo].[Task_DailyRptStatement_Job] TO [vnteam] AS [dbo]
GO


