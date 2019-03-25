/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Archive_CustomerLog_GenerateNextArchiveDate]
AS
/*
	Created: 20190227@Patrick
	Task : Implement archiving data for customer log
	DB: DBLog.bodb_CustomerLog

	Revisions: 
		- 20190227@Patrick: Initalize [RedmineId: #110208] 	
*/
BEGIN
	SET NOCOUNT ON

	DELETE FROM dbo.Task_ArchiveData_List

	INSERT INTO dbo.Task_ArchiveData_List(TableName, ArchiveDate)
	SELECT TableName, DATEADD(DAY, ArchiveDayCount, ArchiveDate) AS NextArchiveDate
	FROM dbo.Task_ArchiveData_TableList WITH(NOLOCK), dbo.Task_ArchiveData_Setting WITH(NOLOCK)

END
GO

