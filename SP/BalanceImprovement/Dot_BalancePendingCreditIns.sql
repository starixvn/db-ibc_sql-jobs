/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Dot_BalancePendingCreditIns]
(
	@BalancePending TVP_BalanceList READONLY,
	@Type		TINYINT,
	@errCode	INT = 0 OUTPUT
)
AS
/*
	Created: 20150731@Lukas
	Task: insert balance into credit pending tables
	DB: DBTXN/bodb02
		
	Revisions:
		- 20190312@Kathy: Exclude updating balance for CN88 user [Redmine:#109882]
		- 20230523@Kathy: remove old balance table [Redmine:#188452]

	Params explanation
		type = 1 - Sports
		type = 2 - Transfer
		type = 3 - Casino
		type = 4 - Others
*/
BEGIN
	SET NOCOUNT ON 
	
	DECLARE @BalanceMode TINYINT --0: Old, 1: New, 2: Both	
	
	DECLARE @tmpCreditPending TVP_BalanceList
	
	SELECT @BalanceMode = dbo.f_GetBalanceMode()
	
	INSERT INTO @tmpCreditPending(custID, balance)
	SELECT	b.custID, b.balance
	FROM	@BalancePending b
		LEFT JOIN (
			SELECT c.custid
			FROM	CustDB.dbo.custInfo c WITH(NOLOCK)
				INNER JOIN dbo.CS_CustSuper cs WITH(NOLOCK)
					ON	c.srecommend = cs.CustId		
						AND c.roleid = 1
		) c
			ON b.custID = c.custid
	WHERE	c.custid IS NULL

	BEGIN TRY
		IF @BalanceMode IN (1, 2)
		BEGIN
			IF @Type = 1 -- Sports
			BEGIN
				INSERT INTO dbo.BalCreditSportsPending(custid, Balance)
				SELECT custID, balance
				FROM @tmpCreditPending
			END
			ELSE IF @Type = 3 -- Casino
			BEGIN
				INSERT INTO dbo.BalCreditCasinoPending(custid, Balance)
				SELECT custID, balance
				FROM @tmpCreditPending
			END 
			ELSE IF @Type = 4 -- Others
			BEGIN
				INSERT INTO dbo.BalCreditOthersPending(custid, Balance)
				SELECT custID, balance
				FROM @tmpCreditPending
			END 
		END	
	END TRY
	BEGIN CATCH
		SET @errCode = 100
		INSERT INTO BalanceErr ( Custid, BalanceGroup, BalanceAmt, ExecutedSP, ErrMsg )
		VALUES ( 0, @Type, 0,'Dot_BalancePendingCreditIns',LEFT(ERROR_MESSAGE(),500)  )
	END CATCH 
END
GO