/*<info serverAlias="DBTXN-bodb02" executers="" viewers="vnteam" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Dot_Member_GetBalance]
	@custid 	INT,
	-------- bonus wallet --------
	@WalletFlag	TINYINT = 0
AS
BEGIN
SET NOCOUNT ON; 
 
	-- 20160111@TWJoe: new create, copy from Dot_Member_VendorGame_GetFinalBalance_cust
	-- 20170505@Bobby: Implement bonus wallet
	-- 20171009@Kathy: Change parameter of SP Dot_BalanceMemberSel

	DECLARE @Balance money 
	DECLARE @Amount MONEY
	select @Balance=0

	EXEC dbo.Dot_BalanceMemberSel @custid, @Balance out,@WalletFlag = @WalletFlag, @Amount = @Amount OUT

	SELECT 
		@Balance AS finalbalance--,@Credit as credit
		,@Amount AS Amount
END
GO

