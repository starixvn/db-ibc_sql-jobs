USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[DBA_CustBalanceFix1_Daniel]    Script Date: 12/08/2015 22:27:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[DBA_CustBalanceFix1_Daniel]
	@custid INT,
	@reset BIT = 0
AS
/*
	Task: Compare balance vs BalanceTable(new) for spec member and FIX at once
	Original: 
	Location: DBTXN.bodb02

	Revision:
	   20151007@Daniel: Created
		20151210@Daniel: calc balance from table bettransRNG & bettransLC 

	Param use:
	 - @reset = FALSE: Add bal diff in SB group only
	 - @reset = TRUE: Clear balance (bal = 0) on other bal groups, keep the whole bal in SB group

*/
DECLARE @DiffBalance money, @result int

SET @DiffBalance = 0
SET @result = 0

IF (@reset = 1)
BEGIN
	UPDATE BalCreditTransfer WITH (ROWLOCK, UPDLOCK) SET Balance = 0 WHERE custid = @custid
	UPDATE BalCreditCasino WITH (ROWLOCK, UPDLOCK) SET Balance = 0 WHERE custid = @custid
	UPDATE BalCreditOthers WITH (ROWLOCK, UPDLOCK) SET Balance = 0 WHERE custid = @custid
	
	UPDATE BalDebitTransfer WITH (ROWLOCK, UPDLOCK) SET Balance = 0 WHERE custid = @custid
	UPDATE BalDebitCasino WITH (ROWLOCK, UPDLOCK) SET Balance = 0 WHERE custid = @custid
	UPDATE BalDebitOthers WITH (ROWLOCK, UPDLOCK) SET Balance = 0 WHERE custid = @custid
END

;WITH
cb AS (
	SELECT @custid custid, SUM(winlost-actual_stake+playercomm) Balance
	FROM dbo.bettrans b with (nolock)
	WHERE custid = @custid
),
q2 AS (
	-- translog
	SELECT @custid custid, SUM(actual_stake) AS Outstanding
	FROM dbo.translog tl with (nolock)
	WHERE tl.statusID=0 --summary running tickets only
		AND custid = @custid
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
SELECT @Diffbalance = cb.Balance - ISNULL(q2.Outstanding,0) 
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
	LEFT OUTER JOIN q3 ON cb.custid = q3.custid
	LEFT OUTER JOIN q4 ON cb.custid = q4.custid		
WHERE
	cb.Balance - ISNULL(q2.Outstanding,0) <> cd1.Balance + cd2.Balance + cd3.Balance + cd4.Balance - db1.Balance - db2.Balance - db3.Balance - db4.Balance
	--AND NOT EXISTS (SELECT 1 FROM dbo.Task_Cust_CheckBalance_Exception ex with (nolock) WHERE @custid = ex.custid)

IF @DiffBalance = 0 RETURN

-- Check settlement involvement
IF EXISTS (SELECT 1 FROM TempVariableNumber WHERE KeyID = 1)
	IF EXISTS(
		SELECT 1 FROM dbo.bettrans b with (nolock) 
		WHERE b.custid = @custid 
			AND EXISTS(SELECT 1 FROM TempVariableNumber WHERE KeyID = 1 AND CAST(KeyValue as int) = b.matchid)
	)
	RETURN

-- check one more time with pending
SET @DiffBalance = 0

;WITH
cb AS (
	SELECT @custid custid, SUM(winlost-actual_stake+playercomm) Balance
	FROM dbo.bettrans b with (nolock)
	WHERE custid = @custid
),
q2 AS (
	-- translog
	SELECT @custid custid, SUM(actual_stake) AS Outstanding
	FROM dbo.translog tl with (nolock)
	WHERE tl.statusID=0 --summary running tickets only
		AND custid = @custid
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
SELECT @Diffbalance = cb.Balance - ISNULL(q2.Outstanding,0) 
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
	LEFT OUTER JOIN q3 ON cb.custid = q3.custid
	LEFT OUTER JOIN q4 ON cb.custid = q4.custid		
WHERE
	cb.Balance - ISNULL(q2.Outstanding,0) <> cd1.Balance + cd2.Balance + cd3.Balance + cd4.Balance - db1.Balance - db2.Balance - db3.Balance - db4.Balance
	--AND NOT EXISTS (SELECT 1 FROM dbo.Task_Cust_CheckBalance_Exception ex with (nolock) WHERE @custid = ex.custid)
	AND NOT EXISTS (SELECT 1 FROM dbo.BalCreditSportsPending cdp2 with (nolock) WHERE @custid = cdp2.custid)
	AND NOT EXISTS (SELECT 1 FROM dbo.BalCreditCasinoPending cdp3 with (nolock) WHERE @custid = cdp3.custid)
	AND NOT EXISTS (SELECT 1 FROM dbo.BalCreditOthersPending cdp4 with (nolock) WHERE @custid = cdp4.custid)
	AND NOT EXISTS (SELECT 1 FROM dbo.BalDebitSportsPending dbp2 with (nolock) WHERE @custid = dbp2.custid)
	AND NOT EXISTS (SELECT 1 FROM dbo.BalDebitCasinoPending dbp3 with (nolock) WHERE @custid = dbp3.custid)
	AND NOT EXISTS (SELECT 1 FROM dbo.BalDebitOthersPending dbp4 with (nolock) WHERE @custid = dbp4.custid)
	
IF @DiffBalance = 0 RETURN

EXEC [dbo].[Task_CheckBalance1_FixOne]
	@custid = @custid,
	@DiffBalance = @DiffBalance OUTPUT,
	@result = @result OUTPUT
	
SELECT @DiffBalance DiffBalance, @result Result