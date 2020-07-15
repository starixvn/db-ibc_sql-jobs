/*<info serverAlias="DBN88-bodb_N88" executers="bodbLicenseeNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_API_TimeTracker_Sel]
	@DataSource	VARCHAR(200)
AS

/*
	Created: 20200520@Percy
	DB: DBN88-bodb_N88
	Task: Get latest info from API_TimeTracker

	Revisions:
		- 20200520@Percy: Initialize SP [RedmineID: #133254]
		- 20200716@Percy: Add KeyValue [RedmineID: #137395]
*/

BEGIN
	SET NOCOUNT ON

	SELECT TOP 1 CalledTime, KeyValue
	FROM dbo.API_TimeTracker WITH (NOLOCK)
	WHERE DataSource = @DataSource
	ORDER BY CalledTime DESC
END
GO