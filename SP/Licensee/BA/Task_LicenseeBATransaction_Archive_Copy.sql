/*<info serverAlias="DBAGE-bodb02,DBACC-bodb02"></info>*/
ALTER PROCEDURE [Task_LicenseeBATransaction_Archive_Copy]
AS

/*
	Created: 20191022@Percy
	DB: DBAGE.bodb02, DBACC.bodb02
	Task: Archive data for LicenseeBATransaction_active - Copy data
	
	Revisions:
		- 20191022@Percy: Initialize SP [RedmineID: #103656]
		- 20200401@Percy: Check exists TransID on LicenseeBATransaction_bk [RedmineID: #131643]
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
		INNER JOIN dbo.bettrans b WITH (NOLOCK) ON b.transid = ba.transid
	WHERE b.winlostdate IN (SELECT MoveBetsDay FROM @MoveBetSchedule)

	IF @@ROWCOUNT = 0
		RETURN

	IF EXISTS (
		SELECT 1
		FROM bodb_licensee.dbo.LicenseeBATransaction_bk b WITH (NOLOCK)
			INNER JOIN #TempData t ON b.TransID = t.TransID
	)
	BEGIN
		DELETE b WITH (ROWLOCK, UPDLOCK)
		FROM bodb_licensee.dbo.LicenseeBATransaction_bk b
			INNER JOIN #TempData t ON b.TransID = t.TransID
	END

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