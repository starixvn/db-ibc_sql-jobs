/*<info serverAlias="DBN88-bodb_N88" executers="bodbLicenseeNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_API_TimeTracker_LatestCalledTime]
	@DataSource	VARCHAR(200)
AS

/*
	Created: 20200520@Percy
	DB: DBN88-bodb_N88
	Task: Get latest called API time

	Revisions:
		- 20200520@Percy: Initalize SP [RedmineID: #133254]
*/

BEGIN
	SET NOCOUNT ON

	SELECT TOP 1 CalledTime FROM dbo.API_TimeTracker WITH (NOLOCK) WHERE DataSource = @DataSource
	ORDER BY CalledTime DESC
END
GO