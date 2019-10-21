/*<info serverAlias="DBRPT-bodb_Report" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_DailyRptStatement_Job]
/* 
	Created by:  Cody  
	Date: 20141229  
	Task: Jobs daily for sum up data for rptStatement  
	DB: DBRPT.bodb_report 

	Revision:  
		- 20150806@Sophia: Control schedule by a new store procedure
		- 20191017@Bobby: Ensure the schedule start from day by day in ascending [Redmine: #119289]

*/
AS
BEGIN 

	SET NOCOUNT ON

	DECLARE @Days AS TABLE (ScheduleId TINYINT, RunningDay DATE PRIMARY KEY, IsFinish BIT DEFAULT (0))

	-- GET MB shedule in days
	INSERT INTO @Days (ScheduleId, RunningDay)
	EXEC DBTXN.bodb02.dbo.Task_MoveBetsDayByScheduleSel 

	IF @@ROWCOUNT = 0
	BEGIN 
		RETURN -1
	END 

	DECLARE @RunningDay DATETIME , @ScheduleId TINYINT

	WHILE EXISTS (SELECT TOP 1 1 FROM @Days WHERE IsFinish = 0)
	BEGIN 
		SELECT  TOP 1 @RunningDay = RunningDay, @ScheduleId = ScheduleId
		FROM	@Days
		WHERE	IsFinish = 0

		EXEC dbo.Task_DailyRptStatement @RunningDay 
		
		UPDATE  @Days
		SET		IsFinish = 1
		WHERE	RunningDay = @RunningDay
						
	END
END	
GO
 