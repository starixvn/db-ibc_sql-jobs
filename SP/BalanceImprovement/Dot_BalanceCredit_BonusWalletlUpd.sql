/*<info serverAlias="DBTXN-bodb02" executers="" viewers="vnteam" isFunction="0" isNested="1"></info>*/
CREATE PROCEDURE [dbo].[Dot_BalanceCredit_BonusWalletlUpd]
(
	@custID			INT,
	@bonusId		INT,
	@balance		MONEY,
	@errCode		INT = 0 OUTPUT
)
AS
/*
	Created: 20170505@Bobby
	Task: 72789 - Implement bonus wallet into balance
	DB: DBTXN/bodb02
		
	Revisions:
		
	Params explanation
*/

BEGIN
	SET NOCOUNT ON 
	
	SELECT @errCode 	= 0
	
	BEGIN TRY
		--UPDATE into bonus credit table
		UPDATE bc WITH(ROWLOCK, UPDLOCK)
		SET bonus	 		+= @balance
		FROM dbo.BonusWalletCredit bc 				
		WHERE bc.custID 	= @custID
			AND bc.bonusId 	= @bonusId
		
		IF(@@ROWCOUNT = 0)
			SET @errCode = 104
	END TRY
	BEGIN CATCH
		SET @errCode = 103
		
		INSERT INTO BalanceErr ( Custid, BalanceGroup, BalanceAmt, ExecutedSP, ErrMsg )
		VALUES ( @custid, 1, @balance,'Dot_BalanceCredit_BonusWalletlUpd',LEFT(ERROR_MESSAGE(),500))
		
	END CATCH 
	RETURN
END
GO