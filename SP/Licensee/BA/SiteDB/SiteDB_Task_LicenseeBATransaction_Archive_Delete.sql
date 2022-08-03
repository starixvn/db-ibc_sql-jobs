/*<info serverAlias="DBSID-bodb02" executers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [SiteDB_Task_LicenseeBATransaction_Archive_Delete]
AS

/*
	Created by: Evan 
	Original: Task_LicenseeBATransaction_Archive_Delete
	Task: Add job [bodb02: Archive BA Transaction - Delete data] on SiteDB
	DB: DBSID-bodb02
	
	Revisions:
		- 20220724@Evan: Add SP for SiteDB  [Redmine: #175297]
*/

BEGIN
	SET NOCOUNT ON

	CREATE TABLE #ArchiveData (TransID BIGINT)

	INSERT INTO #ArchiveData
	SELECT t.TransId
	FROM dbo.LicenseeBATransaction_active t WITH(NOLOCK)
		LEFT JOIN dbo.bettrans b WITH(NOLOCK) ON t.TransID = b.transid
	WHERE b.transid IS NULL

	DECLARE @__TransIds TABLE (transId BIGINT)
	WHILE 1 = 1
	BEGIN
		
		DELETE FROM @__TransIds
		
		DELETE TOP(2000) 
		FROM #ArchiveData
		OUTPUT DELETED.TransID INTO @__TransIds
		
		IF @@ROWCOUNT = 0
			BREAK

		DELETE
		FROM dbo.LicenseeBATransaction_active WITH(ROWLOCK)
		WHERE TransID IN (SELECT t.transId FROM @__TransIds t)

	END

	DROP TABLE #ArchiveData;
	
	SET NOCOUNT OFF
END
GO