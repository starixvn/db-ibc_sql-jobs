/*<info serverAlias="DBSID-bodb02" executers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [SiteDB_Task_LicenseeBATransaction_Archive_Delete]
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

	DECLARE @MoveBetSchedule TABLE(RowId TINYINT IDENTITY(1,1), ScheduleId TINYINT, MoveBetsDay SMALLDATETIME)
	
	INSERT INTO @MoveBetSchedule(ScheduleId, MoveBetsDay)
	EXEC DBTXN.bodb02.dbo.Task_MoveBetsDayByScheduleSel

	IF @@ROWCOUNT = 0
		RETURN

	CREATE TABLE #TempData
	(
		TransID	BIGINT,
		transdate	DATETIME,
		custid	INT,
		recommend	INT,
		srecommend	INT,
		winlostdate	SMALLDATETIME
	)

	INSERT INTO #TempData (TransID, transdate, custid, recommend, srecommend, winlostdate)
	SELECT ba.TransID, ba.transdate, ba.custid, ba.recommend, ba.srecommend, b.winlostdate
	FROM dbo.LicenseeBATransaction_active ba WITH (ROWLOCK)
		INNER JOIN dbo.bettrans14 b WITH (NOLOCK) ON b.transid = ba.transid
	WHERE b.winlostdate IN (SELECT m.MoveBetsDay FROM @MoveBetSchedule m)

	-- delete LicenseeBATransaction_active
	DELETE l
	FROM dbo.LicenseeBATransaction_active l
		INNER JOIN #TempData t ON l.TransID = t.TransID
	

	DROP TABLE #TempData
	
	SET NOCOUNT OFF
END
GO