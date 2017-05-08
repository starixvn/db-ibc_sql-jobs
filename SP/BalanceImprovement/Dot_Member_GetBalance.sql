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

	DECLARE @Balance money 
	DECLARE @Bonus MONEY, @LockedAmt MONEY
	select @Balance=0

	EXEC dbo.Dot_BalanceMemberSel @custid, @Balance out,@WalletFlag = @WalletFlag, @Bonus = @Bonus OUT, @LockedAmt = @LockedAmt OUT

	SELECT 
		@Balance AS finalbalance--,@Credit as credit
		,@Bonus AS Bonus
		,@LockedAmt AS LockedAmt
END
GO

