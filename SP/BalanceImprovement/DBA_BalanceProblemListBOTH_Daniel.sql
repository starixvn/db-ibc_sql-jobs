USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[DBA_BalanceProblemListBOTH_Daniel]    Script Date: 12/08/2015 02:36:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[DBA_BalanceProblemListBOTH_Daniel]
AS
/*
	Task: Compute/Compare balance from bettrans vs BalanceTable(new) vs Balance(old) for all members and output the list
	Original: 
	Location: DBTXN.bodb02

	Revision:
	   20151007@Daniel: Created
		20151210@Daniel: calc balance from table bettransRNG & bettransLC 

	Param use:

*/
;WITH
cb AS (
	SELECT b.custid, SUM(winlost-actual_stake+playercomm) Balance
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
),
q3 AS (
	SELECT custid, SUM(CASE WHEN statusid = 0 then -actual_stake ELSE winlost-actual_stake+playercomm END) BalRNG
	FROM dbo.bettransRNG WITH(NOLOCK)
	WHERE IsSum = 0
	GROUP BY custid
),
q4 AS (
	SELECT custid, SUM(CASE WHEN statusid = 0 then -actual_stake ELSE winlost-actual_stake+playercomm END) BalLC
	FROM dbo.bettransLC WITH(NOLOCK)
	WHERE IsSum = 0
	GROUP BY custid
)
SELECT cb.*, ISNULL(q2.Outstanding,0) Outstanding, ISNULL(q3.BalRNG, 0) BalRNG, ISNULL(q4.BalLC, 0) BalLC, 
   cd.Balance - db.Balance AS FromBalanceTable,
   cd1.Balance + cd2.Balance + cd3.Balance + cd4.Balance 
   - db1.Balance - db2.Balance - db3.Balance - db4.Balance AS FromBalanceTable_New   
INTO #QuestionLists
FROM cb	
	INNER JOIN dbo.BalanceCredit cd with (nolock) ON cb.custid = cd.custid
	INNER JOIN dbo.BalanceDebit db with (nolock) ON cb.custid = db.custid
	INNER JOIN dbo.BalCreditTransfer cd1 with (nolock) ON cb.custid = cd1.custid
	INNER JOIN dbo.BalCreditSports cd2 with (nolock) ON cb.custid = cd2.custid
	INNER JOIN dbo.BalCreditCasino cd3 with (nolock) ON cb.custid = cd3.custid
	INNER JOIN dbo.BalCreditOthers cd4 with (nolock) ON cb.custid = cd4.custid
	INNER JOIN dbo.BalDebitTransfer db1 with (nolock) ON cb.custid = db1.custid
	INNER JOIN dbo.BalDebitSports db2 with (nolock) ON cb.custid = db2.custid
	INNER JOIN dbo.BalDebitCasino db3 with (nolock) ON cb.custid = db3.custid
	INNER JOIN dbo.BalDebitOthers db4 with (nolock) ON cb.custid = db4.custid
	LEFT OUTER JOIN q2 ON cb.custid = q2.custid
	LEFT OUTER JOIN q3 ON cb.custid = q3.custid
	LEFT OUTER JOIN q4 ON cb.custid = q4.custid		
WHERE
	(
		cb.Balance - ISNULL(q2.Outstanding,0) + ISNULL(BalRNG, 0) + ISNULL(BalLC, 0) <> cd1.Balance + cd2.Balance + cd3.Balance + cd4.Balance - db1.Balance - db2.Balance - db3.Balance - db4.Balance
		OR cb.Balance - ISNULL(q2.Outstanding,0) + ISNULL(BalRNG, 0) + ISNULL(BalLC, 0) <> cd.Balance - db.Balance
		OR cd.Balance - db.Balance <> cd1.Balance + cd2.Balance + cd3.Balance + cd4.Balance - db1.Balance - db2.Balance - db3.Balance - db4.Balance		
	)
	AND NOT EXISTS (SELECT 1 FROM dbo.Task_Cust_CheckBalance_Exception ex with (nolock) WHERE cb.custid = ex.custid AND remark not like '%_nbt')

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
),
q3 AS (
	SELECT custid, SUM(CASE WHEN statusid = 0 then -actual_stake ELSE winlost-actual_stake+playercomm END) BalRNG
	FROM dbo.bettransRNG WITH(NOLOCK)
	WHERE IsSum = 0
	GROUP BY custid
),
q4 AS (
	SELECT custid, SUM(CASE WHEN statusid = 0 then -actual_stake ELSE winlost-actual_stake+playercomm END) BalLC
	FROM dbo.bettransLC WITH(NOLOCK)
	WHERE IsSum = 0
	GROUP BY custid
)
SELECT cb.custid, Username, cb.Balance - ISNULL(q2.Outstanding,0) + ISNULL(BalRNG, 0) + ISNULL(BalLC, 0) Bal_bettrans,
	cd.Balance - db.Balance AS Bal_BalanceTable,
   (cd1.Balance + cd2.Balance + cd3.Balance + cd4.Balance - db1.Balance - db2.Balance - db3.Balance - db4.Balance) Bal_BalTable_New,
   cb.Balance - ISNULL(q2.Outstanding,0) + ISNULL(BalRNG, 0) + ISNULL(BalLC, 0)
	- (cd1.Balance + cd2.Balance + cd3.Balance + cd4.Balance - db1.Balance - db2.Balance - db3.Balance - db4.Balance) DiffBal_New,
   cb.Balance - ISNULL(q2.Outstanding,0) + ISNULL(BalRNG, 0) + ISNULL(BalLC, 0) - (cd.Balance - db.Balance) DiffBal
FROM cb
	INNER JOIN dbo.BalanceCredit cd with (nolock) ON cb.custid = cd.custid
	INNER JOIN dbo.BalanceDebit db with (nolock) ON cb.custid = db.custid
	INNER JOIN dbo.BalCreditTransfer cd1 with (nolock) ON cb.custid = cd1.custid
	INNER JOIN dbo.BalCreditSports cd2 with (nolock) ON cb.custid = cd2.custid
	INNER JOIN dbo.BalCreditCasino cd3 with (nolock) ON cb.custid = cd3.custid
	INNER JOIN dbo.BalCreditOthers cd4 with (nolock) ON cb.custid = cd4.custid
	INNER JOIN dbo.BalDebitTransfer db1 with (nolock) ON cb.custid = db1.custid
	INNER JOIN dbo.BalDebitSports db2 with (nolock) ON cb.custid = db2.custid
	INNER JOIN dbo.BalDebitCasino db3 with (nolock) ON cb.custid = db3.custid
	INNER JOIN dbo.BalDebitOthers db4 with (nolock) ON cb.custid = db4.custid
	LEFT OUTER JOIN q2 ON cb.custid = q2.custid
	LEFT OUTER JOIN q3 ON cb.custid = q3.custid
	LEFT OUTER JOIN q4 ON cb.custid = q4.custid		
	INNER JOIN custDB.dbo.custinfo c WITH (nolock) ON cb.custid = c.custid
WHERE
	(
		cb.Balance - ISNULL(q2.Outstanding,0) + ISNULL(BalRNG, 0) + ISNULL(BalLC, 0) <> cd1.Balance + cd2.Balance + cd3.Balance + cd4.Balance - db1.Balance - db2.Balance - db3.Balance - db4.Balance
		OR cb.Balance - ISNULL(q2.Outstanding,0) + ISNULL(BalRNG, 0) + ISNULL(BalLC, 0) <> cd.Balance - db.Balance
		OR cd.Balance - db.Balance <> cd1.Balance + cd2.Balance + cd3.Balance + cd4.Balance - db1.Balance - db2.Balance - db3.Balance - db4.Balance		
	)
	AND NOT EXISTS (SELECT 1 FROM dbo.Task_Cust_CheckBalance_Exception ex with (nolock) WHERE cb.custid = ex.custid AND remark not like '%_nbt')
	AND NOT EXISTS (SELECT 1 FROM dbo.BalancePendingCredit cdp with (nolock) WHERE cb.custid = cdp.custid)
	AND NOT EXISTS (SELECT 1 FROM dbo.BalancePendingDebit cdp with (nolock) WHERE cb.custid = cdp.custid)	
	AND NOT EXISTS (SELECT 1 FROM dbo.BalCreditSportsPending cdp2 with (nolock) WHERE cb.custid = cdp2.custid)
	AND NOT EXISTS (SELECT 1 FROM dbo.BalCreditCasinoPending cdp3 with (nolock) WHERE cb.custid = cdp3.custid)
	AND NOT EXISTS (SELECT 1 FROM dbo.BalCreditOthersPending cdp4 with (nolock) WHERE cb.custid = cdp4.custid)
	AND NOT EXISTS (SELECT 1 FROM dbo.BalDebitSportsPending dbp2 with (nolock) WHERE cb.custid = dbp2.custid)
	AND NOT EXISTS (SELECT 1 FROM dbo.BalDebitCasinoPending dbp3 with (nolock) WHERE cb.custid = dbp3.custid)
	AND NOT EXISTS (SELECT 1 FROM dbo.BalDebitOthersPending dbp4 with (nolock) WHERE cb.custid = dbp4.custid)
ORDER BY username

DROP TABLE #QuestionLists

