ALTER PROCEDURE [dbo].[DBA_CustBalanceFix1_Daniel]
	@custid INT
AS
/*
	Task: Compare balance vs BalanceTable(new) for spec member and FIX at once
	Original: 
	Location: DBTXN.bodb02

	Revision:
	   20151007@Daniel: Created

	Param use:

*/
DECLARE @DiffBalance money, @result int

SET @DiffBalance = 0
SET @result = 0

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
WHERE
	cb.Balance - ISNULL(q2.Outstanding,0) <> cd1.Balance + cd2.Balance + cd3.Balance + cd4.Balance - db1.Balance - db2.Balance - db3.Balance - db4.Balance
	AND NOT EXISTS (SELECT 1 FROM dbo.Task_Cust_CheckBalance_Exception ex with (nolock) WHERE @custid = ex.custid)

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
WHERE
	cb.Balance - ISNULL(q2.Outstanding,0) <> cd1.Balance + cd2.Balance + cd3.Balance + cd4.Balance - db1.Balance - db2.Balance - db3.Balance - db4.Balance
	AND NOT EXISTS (SELECT 1 FROM dbo.Task_Cust_CheckBalance_Exception ex with (nolock) WHERE @custid = ex.custid)
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