/*<info serverAlias="DBRPT-bodb_Report" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_DailyRptStatement_Job]
/* 
	Created by:  Cody  
	Date: 20141229  
	Task: Jobs daily for sum up data for rptStatement  
	DB: DBRPT.bodb_report 

	Revision:  
		-20150806@Sophia: Control schedule by a new store procedure

*/
AS
BEGIN 

	SET NOCOUNT ON

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

				EXEC dbo.Task_DailyRptStatement @RunningDay 
		
				UPDATE  @Days
				SET		IsFinish = 1
				WHERE	ScheduleId = @ScheduleId
						
			END
			ELSE 
				BREAK
		END	
	END



END	
GO



 