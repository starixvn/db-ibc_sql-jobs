/*<info serverAlias="DBTXN-bodb02" executers="" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Dot_GetCustBalance_Cust]
	@custid 	INT,
	-------- bonus wallet --------
	@WalletFlag	TINYINT = 0
AS
/*
	Created: 20120506@vivi
	Task: get balance from new table
	DB: DBTXN/bodb02
		
	Revisions:
		-- 20120506@vivi: get balance from new table
		-- 20140218@Tony: add Sum value from Translog
		-- 20150203@Victor: remove bettrans index hint (INDEX=IX_custid)
		-- 20150908@Tony Yu: add chekc use new balance table
		-- 20151007@Tony Yu: use balance table value for custinfo mini and custinfo full
		-- 20160112@TWJoe(DBtrans): New Balance
		-- 2010112@TWJoe(DBtrans): New Balance
		-- 20170505@Bobby: Implement bonus wallet. Add output Bonus & LockedAmt info
		-- 20171009@Kathy: Change output name Bonus --> Amount
*/
BEGIN
	SET NOCOUNT ON;
		
	DECLARE @OutStanding money
	DECLARE @OutStandingTranslog money
	DECLARE @TotalTranslog money
	DECLARE @Balance money
	DECLARE @BalanceCredit money, @BalanceDebit money
	Declare @OuSTxn money, @Total money, @MaxTrans datetime
	DECLARE @Amount MONEY
	
	select @TotalTranslog = 0;

	EXEC Dot_GetOutStanding @custid,@OutStanding out,@MaxTrans out
	EXEC Dot_BalanceMemberSel @custid, @Balance out, @WalletFlag = @WalletFlag, @Amount = @Amount OUT

	-- compare balance from bettrans -vs- balanceTable
	--IF ISNULL(@Balance, 0) <> ISNULL(@Total, 0)
	--EXEC dbo.Task_Balance_CompareWithBettrans @custid, @Balance, @Total

	SELECT 	IsNull(@OutStanding, 0) OutStanding, 
			IsNull(@Balance, 0) Balance,
			ISNULL(@Balance, 0) Total,
			@MaxTrans MaxTrans,
			@Amount AS Amount
			
END
GO