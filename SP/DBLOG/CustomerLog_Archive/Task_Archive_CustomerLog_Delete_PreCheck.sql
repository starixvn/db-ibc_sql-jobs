/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Archive_CustomerLog_Delete_PreCheck]
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

	IF EXISTS (SELECT TOP 1 1 
		FROM dbo.Task_ArchiveData_List_Processing WITH(NOLOCK)
	)
	BEGIN
		PRINT 'Job copy data not done yet. Please check!!!'
		RAISERROR('Job copy data not done yet. Please check!!!', 16, 1)
	END
END
GO