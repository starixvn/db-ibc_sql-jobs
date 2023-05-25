/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet,bodbDownlineNet,bodbExtAccNet,Dot_Member,Dot_Evolution" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Dot_BalanceCreditInitialize]
(
	@custid		INT,
	@errCode	INT = 0 OUTPUT
)
AS
/*
	Created: 20150803@Lukas	
	Task: 
	DB: DBTXN/BODB02

	Revisions:
		- 20230523@Kathy: remove un-used table [Redmine:#188452]

	Parameters Explanation:		
	
*/
BEGIN
	SET NOCOUNT ON 
	SET @errCode = 0
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
			INSERT INTO dbo.BalCreditSports (custid, balance) VALUES (@custid, 0)		
			INSERT INTO dbo.BalCreditTransfer (custid, balance) VALUES (@custid, 0)	
			INSERT INTO dbo.BalCreditCasino (custid, balance) VALUES (@custid, 0)	
			INSERT INTO dbo.BalCreditOthers (custid, balance) VALUES (@custid, 0)	
		END TRY
		BEGIN CATCH
			INSERT INTO BalanceErr ( Custid, BalanceGroup, BalanceAmt, ExecutedSP, ErrMsg )
			VALUES ( @custid, 0, 0,'Dot_BalanceCreditInitialize' ,LEFT(ERROR_MESSAGE(),500))

						EXEC [dbo].[Dot_BalanceCreditRemove] @custid = @custid -- roll back 
			SET @Success = 0	
		END CATCH

		IF @Success = 0 AND @Retry < 3 GOTO TryAgain

		IF @Success = 0 SET @errCode = 100	

	END
END