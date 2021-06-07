/*<info serverAlias="DBARC-bodb_Archive" isFunction="0" isNested="1"></info>*/
CREATE PROCEDURE Task_RMS_ARC_rmBettrans_Old_byLeagueOrBettype_Sel 
	@winlostdate SMALLDATETIME,
	@isByBettype BIT = 0
AS
/*
	Created:
	DB: DBRMS-bodb_Archive
	Task: RMS - Get Data parlay archived  by league or bettype

	Revisions:   
		- 20210111@Danny: Initialize SP for Enhancing performance (get data from bettrans_bk) [RedmineID: #123157]
*/

SET NOCOUNT ON

DECLARE @__winlostdate SMALLDATETIME
SET @__winlostdate = @winlostdate

DECLARE @MBBU TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)
INSERT INTO @MBBU (BalanceUpDay, MoveBetsDay)
EXEC DBAGE.bodb02.dbo.Age_SelBalanceUpDay

DECLARE @BalanceUpDay SMALLDATETIME, @MoveBetsDay SMALLDATETIME
SELECT  @BalanceUpDay = BalanceUpDay, @MoveBetsDay = MoveBetsDay FROM @MBBU

CREATE TABLE #__refnoList (refNo BIGINT)

IF @__winlostdate > @MoveBetsDay 
BEGIN
	INSERT INTO #__refnoList(refNo)
	SELECT refNo
	FROM bodb02.dbo.bettrans b WITH (NOLOCK)
	WHERE b.winlostdate = @__winlostdate
		AND b.bettype = 29
		AND b.currency <> 20
		AND b.liveawayscore IN (1, 3) -- soccer
		AND b.statusID IN (111, 112, 113, 101, 102)
		AND b.currency <> 20
END
ELSE
BEGIN
	INSERT INTO #__refnoList(refNo)
	SELECT refNo
	FROM bodb02.dbo.bettrans14 b WITH (NOLOCK)
	WHERE b.winlostdate = @__winlostdate
		AND b.bettype = 29
		AND b.currency <> 20
		AND b.liveawayscore IN (1, 3) -- soccer
		AND b.statusID IN (111, 112, 113, 101, 102)
		AND b.currency <> 20
END

IF @isByBettype = 0 
BEGIN
	SELECT b.refno, bm.statusID, m.leagueid
	FROM #__refnoList b WITH (NOLOCK)
		INNER JOIN dbo.bettransm bm WITH (NOLOCK, INDEX = IX_bettransm, FORCESEEK) ON b.refno = bm.refno
		INNER JOIN dbo.match_bk m WITH (NOLOCK) ON bm.matchid = m.matchid
	WHERE bm.winlostdate >= DATEADD(DAY, -21, @__winlostdate)
	AND m.sporttype = 1
END
ELSE
BEGIN
	SELECT b.refno, bm.bettype, bm.statusID, m.leagueid
	FROM #__refnoList b WITH (NOLOCK)
		INNER JOIN dbo.bettransm bm WITH (NOLOCK, INDEX = IX_bettransm, FORCESEEK) ON b.refno = bm.refno
		INNER JOIN dbo.match_bk m WITH (NOLOCK) ON bm.matchid = m.matchid
	WHERE bm.winlostdate >= DATEADD(DAY, -21, @__winlostdate)
	AND m.sporttype = 1
END
drop table #__refnoList
