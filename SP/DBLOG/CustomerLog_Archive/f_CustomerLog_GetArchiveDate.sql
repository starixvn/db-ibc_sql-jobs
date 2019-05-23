/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="" viewers="" isFunction="1" isNested="0"></info>*/
ALTER FUNCTION dbo.f_CustomerLog_GetArchiveDate()
RETURNS DATETIME
AS
/*
	Created: 20190227@Patrick
	Task : Implement archiving data for customer log
	DB: DBLog.bodb_CustomerLog

	Revisions: 
		- 20190227@Patrick: Initalize [RedmineId: #110208] 	
*/
BEGIN
	RETURN (
		SELECT TOP(1) CAST(ArchiveDate AS DATE) AS ArchiveDate
		FROM dbo.Task_ArchiveData_Setting WITH(NOLOCK)
	)
END