/*<info serverAlias="DBYASHBET-bodb_YashBet" executers="wsv_lap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_API_TimeTracker_Sel]
	@DataSource	VARCHAR(200)
AS

/*
	Created: 20240115@Sally
	DB: DBYASHBET-bodb_YashBet
	Task: Get latest info from API_TimeTracker

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

*/

BEGIN
	SET NOCOUNT ON

	SELECT TOP 1 CalledTime, KeyValue
	FROM dbo.API_TimeTracker WITH (NOLOCK)
	WHERE DataSource = @DataSource
	ORDER BY CalledTime DESC

END
GO