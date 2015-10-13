ALTER PROCEDURE [dbo].[DBA_CustBalanceCheck_Daniel]
	@custid INT
AS
/*
	Task: Compute balance from bettrans, Balance Tables(old & new) for spec members and output result
	Original: 
	Location: DBTXN.bodb02

	Revision:
	   20151007@Daniel: Created

	Param use:

*/
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
SELECT cb.Balance - ISNULL(q2.Outstanding,0) Bal_bettrans,
   cd.Balance - db.Balance Bal_BalTable,
   cb.Balance - ISNULL(q2.Outstanding,0) - (cd.Balance - db.Balance) DiffBal,
   cd2.Balance - db2.Balance BalSports,
   cd3.Balance - db3.Balance BalCasino,
   cd1.Balance - db1.Balance BalTransfer,
   cd4.Balance - db4.Balance BalOthers,
   (cd1.Balance + cd2.Balance + cd3.Balance + cd4.Balance - db1.Balance - db2.Balance - db3.Balance - db4.Balance) Bal_NewBalTableALL,
   cb.Balance - ISNULL(q2.Outstanding,0)
	- (cd1.Balance + cd2.Balance + cd3.Balance + cd4.Balance - db1.Balance - db2.Balance - db3.Balance - db4.Balance) DiffBal_New
FROM cb
	LEFT JOIN q2 ON cb.custid = q2.custid
	LEFT JOIN BalanceCredit cd with (nolock) on cb.custid = cd.custid 
	LEFT JOIN BalanceDebit db with (nolock) on cb.custid = db.custid
	LEFT JOIN dbo.BalCreditTransfer cd1 with (nolock) ON cb.custid = cd1.custid
	LEFT JOIN dbo.BalCreditSports cd2 with (nolock) ON cb.custid = cd2.custid
	LEFT JOIN dbo.BalCreditCasino cd3 with (nolock) ON cb.custid = cd3.custid
	LEFT JOIN dbo.BalCreditOthers cd4 with (nolock) ON cb.custid = cd4.custid
	LEFT JOIN dbo.BalDebitTransfer db1 with (nolock) ON cb.custid = db1.custid
	LEFT JOIN dbo.BalDebitSports db2 with (nolock) ON cb.custid = db2.custid
	LEFT JOIN dbo.BalDebitCasino db3 with (nolock) ON cb.custid = db3.custid
	LEFT JOIN dbo.BalDebitOthers db4 with (nolock) ON cb.custid = db4.custid