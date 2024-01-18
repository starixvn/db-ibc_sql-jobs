/*<info serverAlias="DBYASHBET-bodb_YashBet" executers="bodbLicenseeNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_API_TimeTracker_LatestCalledTime]
	@DataSource	VARCHAR(200)
AS

/*
	Created: 20240115@Sally
	DB: DBYASHBET-bodb_YashBet
	Task: Get latest called API time

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

*/

BEGIN
	SET NOCOUNT ON

	SELECT TOP 1 CalledTime 
	FROM dbo.API_TimeTracker WITH (NOLOCK) 
	WHERE DataSource = @DataSource
	ORDER BY CalledTime DESC

END
GO