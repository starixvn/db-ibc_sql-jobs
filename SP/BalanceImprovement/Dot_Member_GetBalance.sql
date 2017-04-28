ALTER PROCEDURE [dbo].[Dot_BalanceMemberSel]
(
	@custID		INT,
	@balance	MONEY = 0 OUTPUT
)
AS
/*
	Created: 20150731@Lukas
	Task: select a specific member's balance
	DB: DBTXN/bodb02
		
	Revisions:
	20151015@Cooper(DBTrans): add IF @balance is null SET @balance = 0
	20160204@Sylvia(DBTrans): add NetPosition balance
*/
BEGIN
	SET NOCOUNT ON 
	DECLARE @BalanceMode TINYINT --0: Old, 1: New, 2: Both	
	SELECT @BalanceMode = dbo.f_GetBalanceMode()

	IF @BalanceMode = 1
		SELECT @balance = (cs.Balance + cc.Balance + co.Balance + ct.Balance) - (ds.Balance + dc.Balance + do.Balance + dt.Balance)
		FROM dbo.BalCreditSports				cs WITH(NOLOCK)	
			INNER JOIN dbo.BalCreditCasino 		cc WITH(NOLOCK)	ON cs.custid = cc.custid 
			INNER JOIN dbo.BalCreditOthers 		co WITH(NOLOCK) ON cs.custid = co.custid 
			INNER JOIN dbo.BalCreditTransfer	ct WITH(NOLOCK) ON cs.custid = ct.custid
			INNER JOIN dbo.BalDebitSports		ds ON cs.custid = ds.custid 
			INNER JOIN dbo.BalDebitCasino		dc ON cs.custid = dc.custid 
			INNER JOIN dbo.BalDebitOthers		do ON cs.custid = do.custid 
			INNER JOIN dbo.BalDebitTransfer		dt ON cs.custid = dt.custid 
		WHERE cs.custid = @custID 
	ELSE
		SELECT @balance = c.Balance - d.Balance
		FROM dbo.BalanceCredit			c  WITH(NOLOCK)
			INNER JOIN dbo.BalanceDebit d ON c.custid = d.custid 
		WHERE c.custid = @custID 

	SELECT @balance=Isnull(@balance,0)+isnull(sum(Credit-Debit),0) FROM BalNetPosition WHERE CustID=@custID
	
	IF @balance is null SET @balance = 0
END
