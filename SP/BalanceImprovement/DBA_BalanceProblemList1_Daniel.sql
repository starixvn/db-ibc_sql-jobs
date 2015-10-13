ALTER PROCEDURE [dbo].[DBA_BalanceProblemList1_Daniel]
AS
/*
	Task: Compute/Compare balance vs BalanceTable(new) for all members and output the list directly
	Original: 
	Location: DBTXN.bodb02

	Revision:
	   20151007@Daniel: Created

	Param use:

*/
;WITH
cb AS (
	SELECT b.custid, SUM(winlost-actual_stake+playercomm) Balance, MAX(tstamp) as RowVersion
	FROM dbo.bettrans b with (nolock)
		--INNER JOIN CustDB.dbo.custinfo c with (nolock) ON b.custid = c.custid AND c.roleid = 1
	GROUP BY b.custid
),
q2 AS (
	-- translog
	SELECT tl.custid, SUM(actual_stake) AS Outstanding
	FROM dbo.translog tl with (nolock)
		--INNER JOIN CustDB.dbo.custinfo c with (nolock) ON tl.custid = c.custid AND c.roleid = 1 and
	WHERE tl.statusID=0 --summary running tickets only
	GROUP BY tl.custid
)
SELECT cb.*, ISNULL(q2.Outstanding,0) Outstanding, 
   cd1.Balance + cd2.Balance + cd3.Balance + cd4.Balance 
   - db1.Balance - db2.Balance - db3.Balance - db4.Balance AS FromBalanceTable
INTO #QuestionLists
FROM cb	
	INNER JOIN dbo.BalCreditTransfer cd1 with (nolock) ON cb.custid = cd1.custid
	INNER JOIN dbo.BalCreditSports cd2 with (nolock) ON cb.custid = cd2.custid
	INNER JOIN dbo.BalCreditCasino cd3 with (nolock) ON cb.custid = cd3.custid
	INNER JOIN dbo.BalCreditOthers cd4 with (nolock) ON cb.custid = cd4.custid
	INNER JOIN dbo.BalDebitTransfer db1 with (nolock) ON cb.custid = db1.custid
	INNER JOIN dbo.BalDebitSports db2 with (nolock) ON cb.custid = db2.custid
	INNER JOIN dbo.BalDebitCasino db3 with (nolock) ON cb.custid = db3.custid
	INNER JOIN dbo.BalDebitOthers db4 with (nolock) ON cb.custid = db4.custid
	LEFT OUTER JOIN q2 ON cb.custid = q2.custid
WHERE
	cb.Balance - ISNULL(q2.Outstanding,0) <> cd1.Balance + cd2.Balance + cd3.Balance + cd4.Balance - db1.Balance - db2.Balance - db3.Balance - db4.Balance
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
   (cd1.Balance + cd2.Balance + cd3.Balance + cd4.Balance - db1.Balance - db2.Balance - db3.Balance - db4.Balance) Bal_BalTable_New,
   cb.Balance - ISNULL(q2.Outstanding,0)
	- (cd1.Balance + cd2.Balance + cd3.Balance + cd4.Balance - db1.Balance - db2.Balance - db3.Balance - db4.Balance) DiffBal
FROM cb
	INNER JOIN dbo.BalCreditTransfer cd1 with (nolock) ON cb.custid = cd1.custid
	INNER JOIN dbo.BalCreditSports cd2 with (nolock) ON cb.custid = cd2.custid
	INNER JOIN dbo.BalCreditCasino cd3 with (nolock) ON cb.custid = cd3.custid
	INNER JOIN dbo.BalCreditOthers cd4 with (nolock) ON cb.custid = cd4.custid
	INNER JOIN dbo.BalDebitTransfer db1 with (nolock) ON cb.custid = db1.custid
	INNER JOIN dbo.BalDebitSports db2 with (nolock) ON cb.custid = db2.custid
	INNER JOIN dbo.BalDebitCasino db3 with (nolock) ON cb.custid = db3.custid
	INNER JOIN dbo.BalDebitOthers db4 with (nolock) ON cb.custid = db4.custid
	LEFT OUTER JOIN q2 ON cb.custid = q2.custid
	INNER JOIN custDB.dbo.custinfo c WITH (nolock) ON cb.custid = c.custid
WHERE
	cb.Balance - ISNULL(q2.Outstanding,0) <> cd1.Balance + cd2.Balance + cd3.Balance + cd4.Balance - db1.Balance - db2.Balance - db3.Balance - db4.Balance
	AND NOT EXISTS (SELECT 1 FROM dbo.Task_Cust_CheckBalance_Exception ex with (nolock) WHERE cb.custid = ex.custid)
	AND NOT EXISTS (SELECT 1 FROM dbo.BalCreditSportsPending cdp2 with (nolock) WHERE cb.custid = cdp2.custid)
	AND NOT EXISTS (SELECT 1 FROM dbo.BalCreditCasinoPending cdp3 with (nolock) WHERE cb.custid = cdp3.custid)
	AND NOT EXISTS (SELECT 1 FROM dbo.BalCreditOthersPending cdp4 with (nolock) WHERE cb.custid = cdp4.custid)
	AND NOT EXISTS (SELECT 1 FROM dbo.BalDebitSportsPending dbp2 with (nolock) WHERE cb.custid = dbp2.custid)
	AND NOT EXISTS (SELECT 1 FROM dbo.BalDebitCasinoPending dbp3 with (nolock) WHERE cb.custid = dbp3.custid)
	AND NOT EXISTS (SELECT 1 FROM dbo.BalDebitOthersPending dbp4 with (nolock) WHERE cb.custid = dbp4.custid)
	
DROP TABLE #QuestionLists