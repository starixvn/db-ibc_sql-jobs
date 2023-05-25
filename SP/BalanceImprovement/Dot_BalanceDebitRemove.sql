/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet,bodbDownlineNet,bodbExtAccNet,Dot_Member,Dot_Evolution" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Dot_BalanceDebitRemove]
(
	@custid		INT,
	@errCode	INT = 0 OUTPUT
)
AS
/*
	Created: 20150803@Lukas	
	Task: Delete from BalanceCredit
	DB: DBTXN/BODB02

	Revisions:
		- 20230523@Kathy: remove old balance table [Redmine:#188452]

	Parameters Explanation:		
	
*/
BEGIN
	DECLARE @BalanceMode TINYINT --0: Old, 1: New, 2: Both	
	SELECT @BalanceMode = dbo.f_GetBalanceMode()
	
	IF @BalanceMode IN (1, 2)
	BEGIN
		DECLARE @Retry		INT, 
				@Success	BIT
		SET @Retry = 0

		TryAgain:

		BEGIN TRY
			SET @Retry = @Retry + 1
			SET @Success = 1
			DELETE dbo.BalDebitSports  WITH(ROWLOCK) WHERE custid = @custid
			DELETE dbo.BalDebitTransfer WITH(ROWLOCK) WHERE custid = @custid
			DELETE dbo.BalDebitCasino  WITH(ROWLOCK) WHERE custid = @custid
			DELETE dbo.BalDebitOthers  WITH(ROWLOCK) WHERE custid = @custid
		END TRY
		BEGIN CATCH
			SET @Success = 0	
			INSERT INTO BalanceErr ( Custid, BalanceGroup, BalanceAmt, ExecutedSP, ErrMsg )
			VALUES ( @custid, 0, 0,'Dot_BalanceDebitRemove',LEFT(ERROR_MESSAGE(),500)  )
		END CATCH

		IF @Success = 0 AND @Retry < 3 GOTO TryAgain

		IF @Success = 0 SET @errCode = 100
	END
END