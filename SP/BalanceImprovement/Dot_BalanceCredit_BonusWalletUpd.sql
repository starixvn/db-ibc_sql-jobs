/*<info serverAlias="DBTXN-bodb02" executers="" viewers="vnteam" isFunction="0" isNested="1"></info>*/
CREATE PROCEDURE [dbo].[Dot_BalanceCredit_BonusWalletUpd]
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
		- 20170419@Bobby: Initialize
		- 20171009@Kathy: Change column name of BonusWalletCredit [Redmine:#72789]
		
	Params explanation
*/

BEGIN
	SET NOCOUNT ON 
	
	DECLARE @Retry 		INT = 0 
		,@Success 		BIT = 0
	
	SELECT @errCode 	= 0
	WHILE (@Success = 0 AND @Retry < 3)
	BEGIN
		BEGIN TRY
			SET @Retry = @Retry + 1
			SET @Success = 1
			
			--UPDATE into bonus credit table
			UPDATE bc WITH(ROWLOCK, UPDLOCK)
			SET Amount	 		+= @balance
			FROM dbo.BonusWalletCredit bc 				
			WHERE bc.custID 	= @custID
				AND bc.bonusId 	= @bonusId
			
			IF(@@ROWCOUNT = 0)
			BEGIN
				SET @errCode = 104
				INSERT INTO BalanceErr ( Custid, BalanceGroup, BalanceAmt, ExecutedSP, ErrMsg, bonusId )
				VALUES ( @custid, 1, @balance,'Dot_BalanceCredit_BonusWalletUpd', 'This member custid=' + CAST(@custid AS VARCHAR(20)) + ' does not exist for the balance''s bonus wallet.', @bonusId)
			END
		END TRY
		BEGIN CATCH
			SET @errCode = 103
			SET @Success = 0
			
			INSERT INTO BalanceErr ( Custid, BalanceGroup, BalanceAmt, ExecutedSP, ErrMsg, bonusId )
			VALUES ( @custid, 1, @balance,'Dot_BalanceCredit_BonusWalletUpd',LEFT(ERROR_MESSAGE(),500), @bonusId)
			
		END CATCH 
	END
	
	RETURN
END
GO