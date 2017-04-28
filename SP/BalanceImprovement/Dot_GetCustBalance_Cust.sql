ALTER PROCEDURE [dbo].[Dot_GetCustBalance_Cust]
	@custid int
AS
BEGIN
	SET NOCOUNT ON;
	
	-- 20120506@vivi: get balance from new table
	-- 20140218@Tony: add Sum value from Translog
	-- 20150203@Victor: remove bettrans index hint (INDEX=IX_custid)
        -- 20150908@Tony Yu: add chekc use new balance table
	-- 20151007@Tony Yu: use balance table value for custinfo mini and custinfo full
	-- 20160112@TWJoe(DBtrans): New Balance
	DECLARE @OutStanding money
	DECLARE @OutStandingTranslog money
	DECLARE @TotalTranslog money
	DECLARE @Balance money
	DECLARE @BalanceCredit money, @BalanceDebit money
	Declare @OuSTxn money, @Total money, @MaxTrans datetime
	
	select @TotalTranslog = 0;

	EXEC Dot_GetOutStanding @custid,@OutStanding out,@MaxTrans out
	EXEC Dot_BalanceMemberSel @custid, @Balance out	

	-- compare balance from bettrans -vs- balanceTable
	--IF ISNULL(@Balance, 0) <> ISNULL(@Total, 0)
	--EXEC dbo.Task_Balance_CompareWithBettrans @custid, @Balance, @Total

	SELECT IsNull(@OutStanding, 0) OutStanding, 
		   IsNull(@Balance, 0) Balance,
		   ISNULL(@Balance, 0) Total,
		   @MaxTrans MaxTrans   
END