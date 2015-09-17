USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Task_CheckBalance1_CheckAll]    Script Date: 09/11/2015 11:27:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_CheckBalance1_CheckAll]
AS

/*
	Task: Compute/Compare balance vs BalanceTable for all members
	Original: Task_CheckBalance_CheckAll
	Location: DBTXN.bodb02

	Revision:
	   20150907@Daniel: Clone from Task_CheckBalance_CheckAll & apply new set of bal tables

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


IF NOT EXISTS (SELECT 1 FROM dbo.Task_Cust_CheckBalanceVerify1)
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

	-- remove test currency
	SET @RC = @@ROWCOUNT
	IF @RC > 0
	BEGIN
		DELETE #QuestionLists
			FROM CustDB.dbo.custInfo ci with (nolock)
			INNER JOIN #QuestionLists ON #QuestionLists.custid = ci.custid
			WHERE ci.currency = 20
			
		SET @RD = @@ROWCOUNT
		SET @msg = CAST(@RC as varchar(50))
	END
	
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
			--INNER JOIN CustDB.dbo.custinfo c with (nolock) ON b.custid = c.custid AND c.roleid = 1
			INNER JOIN #QuestionLists q ON b.custid = q.custid
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
	INSERT INTO dbo.Task_Cust_CheckBalanceVerify1(custid, roundVerified, MaxRowVersion, DiffBalance)
	SELECT cb.custid, 0, RowVersion, 
	   cb.Balance - ISNULL(q2.Outstanding,0) 
	   - (cd1.Balance + cd2.Balance + cd3.Balance + cd4.Balance - db1.Balance - db2.Balance - db3.Balance - db4.Balance)
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
		AND NOT EXISTS (SELECT 1 FROM dbo.BalCreditSportsPending cdp2 with (nolock) WHERE cb.custid = cdp2.custid)
		AND NOT EXISTS (SELECT 1 FROM dbo.BalCreditCasinoPending cdp3 with (nolock) WHERE cb.custid = cdp3.custid)
		AND NOT EXISTS (SELECT 1 FROM dbo.BalCreditOthersPending cdp4 with (nolock) WHERE cb.custid = cdp4.custid)
		AND NOT EXISTS (SELECT 1 FROM dbo.BalDebitSportsPending dbp2 with (nolock) WHERE cb.custid = dbp2.custid)
		AND NOT EXISTS (SELECT 1 FROM dbo.BalDebitCasinoPending dbp3 with (nolock) WHERE cb.custid = dbp3.custid)
		AND NOT EXISTS (SELECT 1 FROM dbo.BalDebitOthersPending dbp4 with (nolock) WHERE cb.custid = dbp4.custid)
		
	PRINT @msg + ' -' + CAST(@RD as varchar(50)) + ' -> ' + CAST(@@ROWCOUNT as varchar(50)) + ' accounts add to verify balance'
	
	DROP TABLE #QuestionLists
END


