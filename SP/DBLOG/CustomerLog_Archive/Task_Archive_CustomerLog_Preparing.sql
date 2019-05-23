/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Archive_CustomerLog_Preparing]
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

	IF EXISTS (SELECT TOP 1 1 FROM Task_ArchiveData_List_Processing WITH(NOLOCK))
	BEGIN
		RAISERROR('Having data in [Task_ArchiveData_List_Processing]. Please take a look.', 16, 1)
		RETURN
	END

	INSERT INTO Task_ArchiveData_List_Processing(TableName, ArchiveDate)
	SELECT TableName, ArchiveDate
	FROM dbo.Task_ArchiveData_List WITH(NOLOCK)

END
GO

