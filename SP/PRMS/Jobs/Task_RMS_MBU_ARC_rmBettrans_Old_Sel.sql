/*<info serverAlias="DBARC-bodb_Archive" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE Task_RMS_MBU_ARC_rmBettrans_Old_Sel @winlostdate SMALLDATETIME
AS
/*
	Created:
	DB: DBRMS-bodb_Archive
	Task: RMS - Check Sum data Rm bettrans_Old

	Revisions:   
		- 20201221@danny: create SP  [RedmineID: #145926]
		- 20210604@Danny: Add New League Group for Saba Sports [RedmineID: #156453]
		
*/

DECLARE @__winlostdate SMALLDATETIME
SET @__winlostdate = @winlostdate

CREATE TABLE #__refnoList (refNo BIGINT)
INSERT INTO #__refnoList(refNo)
SELECT refNo
FROM bodb02.dbo.bettrans14 b WITH (NOLOCK)
WHERE b.winlostdate = @__winlostdate
	AND b.bettype = 29
	AND b.statusID IN (111, 112, 113)

SELECT bm.refno, m.sporttype
	, CASE WHEN l.LeagueGroupID IN (42, 74, 108) THEN 1 ELSE -1 END Saba
	, bm.odds, bm.stake, CASE WHEN m.ChildMatchType = 200 THEN m.ParentID ELSE bm.matchid END matchid
FROM #__refnoList b WITH (NOLOCK)
	INNER JOIN dbo.bettransm bm WITH (NOLOCK) ON b.refno = bm.refno
	INNER JOIN dbo.match_bk m WITH (NOLOCK) ON bm.matchid = m.matchid
	INNER JOIN bodb02.dbo.League l WITH(NOLOCK) ON m.leagueid = l.leagueid
WHERE bm.winlostdate >= DATEADD(DAY, -21, @__winlostdate)

drop table #__refnoList

