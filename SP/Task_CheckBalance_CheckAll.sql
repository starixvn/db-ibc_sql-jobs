USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Task_CheckBalance_CheckAll]    Script Date: 12/07/2015 05:17:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_CheckBalance_CheckAll]
AS

/*
	Task: Compute/Compare balance vs BalanceTable for all members
	Original: Task_CheckBalance_CheckAll
	Location: DBTXN.bodb02

	Revision:
		20151210@Daniel: calc balance from table bettransRNG & bettransLC 

	Param use:


	Logic & Process:
		update DWL into Exception table
		1st compute and compare (all members)
		remove UUS & members having ticket being settle
		2nd compute and compare (filtered members)
*/
SET NOCOUNT ON
Declare @RC int, @RD int, @msg varchar(200)
SET @msg = ''
SET @RD = 0

-- automatic update list from DWL
INSERT INTO Task_Cust_CheckBalance_Exception
SELECT custid, 'DWLList'
FROM DBACC.bodb_ACC.dbo.Acc_DWLList dw with (nolock)
WHERE custid NOT IN (SELECT custid FROM dbo.Task_Cust_CheckBalance_Exception ce with (nolock))


IF NOT EXISTS (SELECT 1 FROM dbo.Task_Cust_CheckBalanceVerify)
BEGIN
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
		cd.Balance - db.Balance AS FromBalanceTable
	INTO #QuestionLists
	FROM cb
		INNER JOIN dbo.BalanceCredit cd with (nolock) ON cb.custid = cd.custid
		INNER JOIN dbo.BalanceDebit  db with (nolock) ON cb.custid = db.custid
		LEFT OUTER JOIN q2 ON cb.custid = q2.custid
		LEFT OUTER JOIN q3 ON cb.custid = q3.custid
		LEFT OUTER JOIN q4 ON cb.custid = q4.custid		
	WHERE
		cb.Balance - ISNULL(q2.Outstanding,0) + ISNULL(BalRNG, 0) + ISNULL(BalLC, 0) <> (cd.Balance - db.Balance)
		AND NOT EXISTS (SELECT 1 FROM dbo.Task_Cust_CheckBalance_Exception ex with (nolock) WHERE cb.custid = ex.custid)

	SET @RC = @@ROWCOUNT
	SET @msg = CAST(@RC as varchar(50))
	-- remove test currency
	/*
	IF @RC > 0
	BEGIN
		DELETE #QuestionLists
			FROM CustDB.dbo.custInfo ci with (nolock)
			INNER JOIN #QuestionLists ON #QuestionLists.custid = ci.custid
			WHERE ci.currency = 20
			
		SET @RD = @@ROWCOUNT
		
	END*/
	
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
			
		SET @RD = @RD + @@ROWCOUNT
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
	INSERT INTO dbo.Task_Cust_CheckBalanceVerify (custid, roundVerified, MaxRowVersion, DiffBalance)
	SELECT cb.custid, 0, RowVersion, cb.Balance - ISNULL(q2.Outstanding,0) + ISNULL(BalRNG, 0) + ISNULL(BalLC, 0) - (cd.Balance - db.Balance)
	FROM cb
		INNER JOIN dbo.BalanceCredit cd with (nolock) ON cb.custid = cd.custid
		INNER JOIN dbo.BalanceDebit  db with (nolock) ON cb.custid = db.custid
		LEFT OUTER JOIN q2 ON cb.custid = q2.custid
		LEFT OUTER JOIN q3 ON cb.custid = q3.custid
		LEFT OUTER JOIN q4 ON cb.custid = q4.custid		
	WHERE
		cb.Balance - ISNULL(q2.Outstanding,0) + ISNULL(BalRNG, 0) + ISNULL(BalLC, 0) <> (cd.Balance - db.Balance)
		AND NOT EXISTS (SELECT 1 FROM dbo.Task_Cust_CheckBalance_Exception ex with (nolock) WHERE cb.custid = ex.custid)
		AND NOT EXISTS (SELECT 1 FROM dbo.BalancePendingCredit pc with (nolock) WHERE cb.custid = pc.custid)
		AND NOT EXISTS (SELECT 1 FROM dbo.BalancePendingDebit pd with (nolock) WHERE cb.custid = pd.custid)
		
	PRINT @msg + ' -' + CAST(@RD as varchar(50)) + ' -> ' + CAST(@@ROWCOUNT as varchar(50)) + ' accounts add to verify balance'
	
	DROP TABLE #QuestionLists
END


