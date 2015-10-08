ALTER PROCEDURE [dbo].[DBA_BalanceProblemList_Daniel]
AS
/*
	Task: Compute/Compare balance vs BalanceTable for all members and output the list directly
	Original: 
	Location: DBTXN.bodb02

	Revision:
	   20150907@Daniel: Created

	Param use:

*/
;WITH
cb AS (
	SELECT b.custid, SUM(winlost-actual_stake+playercomm) Balance, MAX(tstamp) as RowVersion
	FROM dbo.bettrans b with (nolock)
	GROUP BY b.custid
),
q2 AS (
	-- translog
	SELECT tl.custid, SUM(actual_stake) AS Outstanding
	FROM dbo.translog tl with (nolock)
	WHERE tl.statusID=0 --summary running tickets only
	GROUP BY tl.custid
)
SELECT cb.*, ISNULL(q2.Outstanding,0) Outstanding, cd.Balance - db.Balance AS FromBalanceTable
INTO #QuestionLists
FROM cb
	INNER JOIN dbo.BalanceCredit cd with (nolock) ON cb.custid = cd.custid
	INNER JOIN dbo.BalanceDebit  db with (nolock) ON cb.custid = db.custid
	LEFT OUTER JOIN q2 ON cb.custid = q2.custid
WHERE
	cb.Balance - ISNULL(q2.Outstanding,0) <> (cd.Balance - db.Balance)
	AND NOT EXISTS (SELECT 1 FROM dbo.Task_Cust_CheckBalance_Exception ex with (nolock) WHERE cb.custid = ex.custid)

-- remove settlement involvement
IF  EXISTS (SELECT 1 FROM #QuestionLists)
	AND
	EXISTS (SELECT 1 FROM TempVariableNumber WHERE KeyID = 1)
BEGIN
	;WITH m AS (SELECT CAST(KeyValue as int) matchid FROM TempVariableNumber WHERE KeyID = 1)
	DELETE q
	FROM #QuestionLists q
	WHERE EXISTS (
		SELECT 1 
		FROM dbo.bettrans b with (nolock) 
		INNER JOIN m ON b.matchid = m.matchid AND b.custid = q.custid
		)
		
END

-- check one more time (with less accounts)
;WITH
cb AS (
	SELECT b.custid, SUM(winlost-actual_stake+playercomm) Balance, MAX(tstamp) as RowVersion
	FROM dbo.bettrans b with (nolock)
		INNER JOIN #QuestionLists q ON b.custid = q.custid
	GROUP BY b.custid
),
q2 AS (
	-- translog
	SELECT tl.custid, SUM(actual_stake) AS Outstanding
	FROM dbo.translog tl with (nolock)
	WHERE tl.statusID=0 --summary running tickets only
	GROUP BY tl.custid
)
SELECT cb.custid, Username, cb.Balance - ISNULL(q2.Outstanding,0) Bal_bettrans,
	(cd.Balance - db.Balance) Bal_BalTable,
	cb.Balance - ISNULL(q2.Outstanding,0) - (cd.Balance - db.Balance) DiffBal
FROM cb
	INNER JOIN dbo.BalanceCredit cd with (nolock) ON cb.custid = cd.custid
	INNER JOIN dbo.BalanceDebit  db with (nolock) ON cb.custid = db.custid
	LEFT OUTER JOIN q2 ON cb.custid = q2.custid
	INNER JOIN custDB.dbo.custinfo c WITH (nolock) ON cb.custid = c.custid
WHERE
	cb.Balance - ISNULL(q2.Outstanding,0) <> (cd.Balance - db.Balance)
	AND NOT EXISTS (SELECT 1 FROM dbo.Task_Cust_CheckBalance_Exception ex with (nolock) WHERE cb.custid = ex.custid)
	AND NOT EXISTS (SELECT 1 FROM dbo.BalancePendingCredit pc with (nolock) WHERE cb.custid = pc.custid)
	AND NOT EXISTS (SELECT 1 FROM dbo.BalancePendingDebit pd with (nolock) WHERE cb.custid = pd.custid)
	
DROP TABLE #QuestionLists	