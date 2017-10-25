/*<info serverAlias="DBTXN-bodb02" executers="" viewers="vnteam" isFunction="0" isNested="1"></info>*/
CREATE PROCEDURE [dbo].[Dot_BalanceDebit_BonusWalletUpd]
(
	@custID			INT,
	@bonusId		INT,
	@balance		MONEY,
	@Amount			MONEY = 0 OUTPUT,
	@errCode		INT = 0 OUTPUT	
)
AS
/*
	Created: 20170505@Bobby
	Task: 72789 - Implement bonus wallet into balance
	DB: DBTXN/bodb02
		
	Revisions:
		- 20170505@Bobby: Initialize
		- 20171009@Kathy: Change column name of BonusWalletDebit [Redmine:#72789]
		
	Params explanation
*/

BEGIN
	SET NOCOUNT ON 
	
	DECLARE @Retry 		INT = 0 
		,@Success 		BIT = 0
	
	SELECT @errCode 	= 0
		,@Amount 		= 0
	
	WHILE (@Success = 0 AND @Retry < 3)
	BEGIN
		BEGIN TRY
			SET @Retry = @Retry + 1
			SET @Success = 1
			
			--UPDATE into bonus debit table
			UPDATE bd WITH(ROWLOCK, UPDLOCK)
			SET @Amount 			= bc.initBonus + bc.Amount + bc.LockedAmt - (bd.Amount + @balance)
				,Amount	 		+= @balance
			FROM dbo.BonusWalletDebit bd 
				INNER JOIN dbo.BonusWalletCredit bc WITH(NOLOCK)
				ON bd.custID 	= bc.custID
				AND bd.bonusId 	= bc.bonusId
					
			WHERE bd.custID 	= @custID
				AND bd.bonusId 	= @bonusId
						
			IF(@@ROWCOUNT = 0)
			BEGIN
				SET @errCode = 104
				
				INSERT INTO BalanceErr ( Custid, BalanceGroup, BalanceAmt, ExecutedSP, ErrMsg, bonusId )
				VALUES ( @custid, 1, @balance,'Dot_BalanceDebit_BonusWalletUpd', 'This member custid=' + CAST(@custid AS VARCHAR(20)) + ' does not exist for the balance''s bonus wallet.', @bonusId)
			END
				
		END TRY
		BEGIN CATCH
			SET @errCode = 103
			SET @Success = 0
			
			INSERT INTO BalanceErr ( Custid, BalanceGroup, BalanceAmt, ExecutedSP, ErrMsg, bonusId )
			VALUES ( @custid, 1, @balance,'Dot_BalanceDebit_BonusWalletUpd',LEFT(ERROR_MESSAGE(),500), @bonusId)
			
		END CATCH 
	END
	
	RETURN
END
GO