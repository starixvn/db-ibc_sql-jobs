/*<info serverAlias="DBAGE-bodb02,DBACC-bodb02"></info>*/
ALTER PROCEDURE [Task_LicenseeBATransaction_Archive_Delete]
AS

/*
	Created: 20191022@Percy
	DB: DBAGE.bodb02, DBACC.bodb02
	Task: Archive data for LicenseeBATransaction_active - Check and Correct data + Delete data
	
	Revisions:
		- 20191022@Percy: Initialize SP [RedmineID: #103656]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @MoveBetSchedule TABLE(RowId TINYINT IDENTITY(1,1), ScheduleId TINYINT, MoveBetsDay SMALLDATETIME)
	
	INSERT INTO @MoveBetSchedule(ScheduleId, MoveBetsDay)
	EXEC DBTXN.bodb02.dbo.Task_MoveBetsDayByScheduleSel

	IF @@ROWCOUNT = 0
		RETURN

	SELECT ba.TransID, ba.transdate, ba.custid, ba.recommend, ba.srecommend, b.winlostdate
	INTO #TempData
	FROM bodb_licensee.dbo.LicenseeBATransaction_active ba WITH (ROWLOCK)
		INNER JOIN dbo.bettrans14 b WITH (NOLOCK) ON b.transid = ba.transid

	DELETE t
	FROM #TempData t
		LEFT JOIN @MoveBetSchedule m ON t.winlostdate = m.MoveBetsDay
	WHERE m.MoveBetsDay IS NULL

	-- delete LicenseeBATransaction_active
	DELETE l
	FROM bodb_licensee.dbo.LicenseeBATransaction_active l
		INNER JOIN #TempData t ON l.TransID = t.TransID
	
	-- insert missing ticket to LicenseeBATransaction_bk if have
	DELETE t
	FROM #TempData t
		INNER JOIN bodb_licensee.dbo.LicenseeBATransaction_bk b WITH (NOLOCK) ON t.TransID = b.TransID

	IF NOT EXISTS (SELECT 1 FROM #TempData)
		RETURN

	INSERT INTO	bodb_licensee.dbo.LicenseeBATransaction_bk
	(
		TransID, transdate, custid, recommend, srecommend, winlostdate
	)
	SELECT
		TransID, transdate, custid, recommend, srecommend, winlostdate
	FROM #TempData t

	DROP TABLE #TempData
	
	SET NOCOUNT OFF
END
GO