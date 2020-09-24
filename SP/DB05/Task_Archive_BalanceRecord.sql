/*<info serverAlias="DBBAH-bodb02" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Archive_BalanceRecord] 
	@DelSize varchar(10) = 'Small'
AS
/*
	Created: 
	DB: DBBAH.bodb02
	Task: 
	Revision:
		- 20200922@Kathy: Add column matchid, statusid, SettlementType, smawinlost, smacomm [Redmine:#138552]
*/
BEGIN
SET NOCOUNT ON

CREATE TABLE #AList (custid int PRIMARY KEY, nRowID bigint, xRowID bigint, cnt int)
CREATE TABLE #CList (rn int PRIMARY KEY IDENTITY(1,1), custid int, nRowID bigint, xRowID bigint)

Declare @DelRN int
SET @DelRN = CASE @DelSize
	WHEN 'Small' THEN 100
	WHEN 'Medium' THEN 50
	WHEN 'Big' THEN 10
	END

IF @DelSize = 'Big'
	INSERT INTO #AList (custid, nRowID, xRowID, cnt)
	SELECT custid, min(RowID), max(RowID), COUNT(*)
	FROM dbo.BalanceRecord with (nolock)
	GROUP BY custid
	HAVING COUNT(*) > 100
ELSE IF @DelSize = 'Medium'
	INSERT INTO #AList (custid, nRowID, xRowID, cnt)
	SELECT custid, min(RowID), max(RowID), COUNT(*)
	FROM dbo.BalanceRecord with (nolock)
	GROUP BY custid
	HAVING COUNT(*) BETWEEN 40 AND 95
ELSE
	INSERT INTO #AList (custid, nRowID, xRowID, cnt)
	SELECT custid, min(RowID), max(RowID), COUNT(*)
	FROM dbo.BalanceRecord with (nolock)
	GROUP BY custid
	HAVING COUNT(*) BETWEEN 3 AND 35


CREATE TABLE #RList (rn int PRIMARY KEY IDENTITY (1,1), rowID bigint)
INSERT INTO #RList (rowID)
SELECT rowID
FROM dbo.BalanceRecord br with (nolock)
	INNER JOIN #AList a
	ON a.custid = br.custid AND br.rowID < a.xRowID
ORDER BY
	br.RowID

CREATE TABLE #R (rowID bigint PRIMARY KEY)

SET NOCOUNT ON
Declare @rn int, @rn2 int, @xrn int
SET @rn = 1
SET @rn2 = @DelRN

WHILE (1=1)
BEGIN

	TRUNCATE TABLE #R

	INSERT INTO #R
	SELECT DISTINCT RowID FROM #RList with (nolock)
	WHERE rn BETWEEN @rn AND @rn2

	DELETE FROM	dbo.BalanceRecord
	OUTPUT
		DELETED.RowID, DELETED.custid, DELETED.transid, DELETED.bettype,
		DELETED.actual_stake, DELETED.winlost, DELETED.playercomm,
		DELETED.BalanceChanged, DELETED.NewBalance,
		DELETED.ActionDate, DELETED.ActionID, DELETED.[Action],
		DELETED.BTBalance,
		DELETED.MatchId, DELETED.StatusId, DELETED.SettlementType, DELETED.swinlost, DELETED.mwinlost, DELETED.awinlost, DELETED.scomm, DELETED.acomm, DELETED.comm
	INTO BalanceRecord.dbo.BalanceRecord_bk (
		RowID, custid, transid, bettype, 
		actual_stake, winlost, playercomm,
		BalanceChanged, NewBalance, 
		ActionDate, ActionID, [Action],
		BTBalance, MatchId, StatusId, SettlementType, swinlost, mwinlost, awinlost, scomm, acomm, comm
		)
	WHERE rowID IN (SELECT rowID FROM #R)

	IF @@ROWCOUNT = 0 GOTO EndMe


	SET @rn = @rn + @DelRN
	SET @rn2 = @rn2 + @DelRN
END

EndMe:

SET NOCOUNT OFF
END
