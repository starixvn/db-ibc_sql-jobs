/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Archive_CustomerLog_UpdateArchiveDate]
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

	UPDATE a
	SET ArchiveDate = t.ArchiveDate
	FROM dbo.Task_Setting_ArchiveData a WITH(UPDLOCK, ROWLOCK)
		INNER JOIN (
			SELECT TableName, MAX(ArchiveDate) ArchiveDate
			FROM dbo.Task_ArchiveData_List WITH(NOLOCK)
			GROUP BY TableName
		) t ON a.TableName = t.TableName

END
GO