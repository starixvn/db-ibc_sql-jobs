ALTER PROCEDURE [dbo].[DBA_CustBalanceFix_Daniel]
	@custid INT
AS
/*
	Task: Compare balance vs BalanceTable for spec member and FIX at once
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
SELECT @Diffbalance = cb.Balance - ISNULL(q2.Outstanding,0) - (cd.Balance - db.Balance)
FROM cb	
	INNER JOIN dbo.BalanceCredit cd with (nolock) ON cb.custid = cd.custid
	INNER JOIN dbo.BalanceDebit db with (nolock) ON cb.custid = db.custid
	LEFT OUTER JOIN q2 ON cb.custid = q2.custid
WHERE
	cb.Balance - ISNULL(q2.Outstanding,0) <> cd.Balance - db.Balance
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
SELECT @Diffbalance = cb.Balance - ISNULL(q2.Outstanding,0) - (cd.Balance - db.Balance)
FROM cb	
	INNER JOIN dbo.BalanceCredit cd with (nolock) ON cb.custid = cd.custid
	INNER JOIN dbo.BalanceDebit db with (nolock) ON cb.custid = db.custid
	LEFT OUTER JOIN q2 ON cb.custid = q2.custid
WHERE
	cb.Balance - ISNULL(q2.Outstanding,0) <> cd.Balance - db.Balance
	AND NOT EXISTS (SELECT 1 FROM dbo.Task_Cust_CheckBalance_Exception ex with (nolock) WHERE @custid = ex.custid)
	AND NOT EXISTS (SELECT 1 FROM dbo.BalancePendingCredit cdp with (nolock) WHERE @custid = cdp.custid)
	AND NOT EXISTS (SELECT 1 FROM dbo.BalancePendingDebit dbp with (nolock) WHERE @custid = dbp.custid)
	
IF @DiffBalance = 0 RETURN

EXEC [dbo].[Task_CheckBalance_FixOne]
	@custid = @custid,
	@DiffBalance = @DiffBalance OUTPUT,
	@result = @result OUTPUT
	
SELECT @DiffBalance DiffBalance, @result Result