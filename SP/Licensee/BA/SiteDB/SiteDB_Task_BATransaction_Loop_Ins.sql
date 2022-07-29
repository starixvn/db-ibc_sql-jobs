/*<info serverAlias="DBSID-bodb02" executers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].SiteDB_Task_BATransaction_Loop_Ins
AS
/*
	Created by: Evan 
	Original: Task_BATransaction_Loop_Ins
	Task: Loop to call Insert BA Transaction (exec) on SiteDB
	DB: DBSID-bodb02
	
	Revisions:
		- 20220724@Evan: Add SP for SiteDB  [Redmine: #175297]
*/

BEGIN
	
	SET NOCOUNT ON

	DECLARE @start DATETIME
	SELECT @start = CURRENT_TIMESTAMP

	WHILE (DATEDIFF(SECOND,@start, CURRENT_TIMESTAMP) <= 600) --loop 10 mins and then break
	BEGIN
		EXEC dbo.SiteDB_Task_BATransaction_Ins
		WAITFOR DELAY '00:00:01' -- waifor delay for [Retrieve BA Transaction] job
	END

END
GO