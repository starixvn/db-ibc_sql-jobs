/*<info serverAlias="DB042-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_Archive_GetMovebetDays]
AS
/*
	Create By: 20180625@Patrick
	Task: Get movebet days
	DB: DB042/bodb02
	Revision: 
		-20191127@Patrick: Setup sync status ticket on DB052 -> DB054 - [Redmine: #124482]
		
	Para's explaination
*/
BEGIN
	SET NOCOUNT ON

	DELETE FROM [dbo].[Task_ArchiveBet] WITH(ROWLOCK)

	DECLARE @MoveBetSchedule TABLE (ScheduleId TINYINT, MoveBetsDay DATE)
	INSERT INTO @MoveBetSchedule (ScheduleId, MoveBetsDay)
	EXEC DBTXN.bodb02.dbo.Task_MoveBetsDayByScheduleSel

	INSERT dbo.[Task_ArchiveBet](winlostdate)
	SELECT MoveBetsDay
	FROM @MoveBetSchedule

END