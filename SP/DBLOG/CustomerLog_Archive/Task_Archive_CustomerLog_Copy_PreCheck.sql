/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Archive_CustomerLog_Copy_PreCheck]
AS
/*
	Created: 20190227@Patrick
	Task : Implement archiving data for customer log
	DB: DBLog.bodb_CustomerLog

	Revisions: 
		- 20190618@Patrick: Initalize [RedmineId: #115227] 	
*/
BEGIN
	SET NOCOUNT ON

	IF EXISTS (SELECT TOP 1 1 
		FROM dbo.Task_ArchiveData_List_Processing WITH(NOLOCK)
	)
	BEGIN
		PRINT 'Job delete data or previous round not done yet. Please check!!!'
		RAISERROR('Job delete data or previous round not done yet. Please check!!!', 16, 1)
		RETURN
	END
	
END
GO