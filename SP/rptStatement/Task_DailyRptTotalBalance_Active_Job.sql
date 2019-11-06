 /*<info serverAlias="DBRPT-bodb_Report" executers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_DailyRptTotalBalance_Active_Job]
/* 
	Created by:20190507@Sophia 
	Task: insert/ update data on RptTotalBalance_Active, data from MoveBetDay to today
	DB: DBRPT.bodb_report 

	Revisions:
		- 20190507@Sophia: Initial data [redmine: #109293]
		- 20191017@Bobby: Ensure the schedule start from day by day in ascending [Redmine: #119289]
*/
AS
BEGIN 

	SET NOCOUNT ON 		
	DECLARE @RunningDay SMALLDATETIME , @ScheduleId INT, @ToDay DATE, @MoveBetsDay DATE
		
	DECLARE @Days AS TABLE (ScheduleId INT IDENTITY (1,1), RunningDay DATE PRIMARY KEY, IsFinish BIT DEFAULT (0))

	DECLARE @Selbalanceupday AS TABLE (BalanceUpDay DATE, MoveBetsDay DATE)

	INSERT INTO @Selbalanceupday (BalanceUpDay, MoveBetsDay)
	EXEC bodb02.dbo.Age_Selbalanceupday	
			
	SELECT @MoveBetsDay = MoveBetsDay,  @ToDay = GETDATE()	
	FROM @Selbalanceupday
	
	-- SET start date from MB + 1 = 1st day in bettrans
	SELECT @RunningDay = DATEADD(DD, 1, @MoveBetsDay)
	WHILE @RunningDay <= @ToDay
	BEGIN 
		INSERT INTO @Days (RunningDay)
		VALUES (@RunningDay)
		
		SELECT @RunningDay = DATEADD(DD, 1, @RunningDay )
	END 
	
	-- START processing
	WHILE EXISTS (SELECT TOP 1 1 FROM @Days WHERE IsFinish = 0)
	BEGIN 
		SELECT  TOP 1 @RunningDay = RunningDay, @ScheduleId = ScheduleId
		FROM	@Days
		WHERE	IsFinish = 0
		ORDER BY ScheduleId

		EXEC dbo.Task_DailyRptTotalBalance_Active @Winlostdate = @RunningDay, @isCheckDataOnly = 0
		
		UPDATE  @Days
		SET		IsFinish = 1
		WHERE	RunningDay = @RunningDay
						
	END

	-- CLEAN DATA processing
	DELETE dbo.rptTotalBalance_Active WITH (ROWLOCK)
	WHERE WinlostDate <= @MoveBetsDay
END	
GO 