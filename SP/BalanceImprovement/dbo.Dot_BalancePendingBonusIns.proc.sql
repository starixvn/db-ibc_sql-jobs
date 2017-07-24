/*<info serverAlias="DBTXN-bodb02" executers="" viewers="vnteam" isFunction="0" isNested="1"></info>*/
CREATE PROCEDURE [dbo].[Dot_BalancePendingBonusIns]
	@BonusWalletChange	TVP_BalanceWalletChange	READONLY
AS
/* 
	Created: 20170419@Bobby.nguyen  
	Task:  72789 - Implement bonus system into NAP Settlement
	DB: DBTXN/bodb02  
	Original:   

	Revisions:  
		- 20170419@Bobby: Initialize
		
	Param's Explanation:   
	 
*/
BEGIN
	SET NOCOUNT ON
	
	BEGIN TRY
	
		INSERT INTO dbo.BonusWalletPending	(
			CustID
			, BonusID
			, Bonus
			, LockedAmt
		)
		SELECT bn.CustID
			, bn.BonusID
			, bn.balance AS Bonus
			, 0 AS LockedAmt
		FROM @BonusWalletChange bn
			
	END TRY	
	BEGIN CATCH
	
		INSERT INTO dbo.BalanceErr ( Custid, BalanceGroup, BalanceAmt, ExecutedSP, ErrMsg )
		VALUES ( 0, 1, 0,'Dot_BalancePendingBonusIns',LEFT(ERROR_MESSAGE(),500)  )
		
	END CATCH
	
	RETURN
END
GO
