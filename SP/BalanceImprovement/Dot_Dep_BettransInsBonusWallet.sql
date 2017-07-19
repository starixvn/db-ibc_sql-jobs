/*<info serverAlias="DBTXN-bodb02" executers="Dot_Member" viewers="vnteam" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Dot_Dep_BettransInsBonusWallet] 
	@custid 		INT,
	@bal_custid 	INT,
	@bettype 		SMALLINT = 22026,
	@bonusId 		INT,
	@amount 		MONEY,	
	@lockedAmount	MONEY = 0,	
	@transdesc 		NVARCHAR(300) = '',
	@ip				NVARCHAR(15)='',
	@transid 		BIGINT = 0 OUTPUT,	
	@bal_transid 	BIGINT = 0 OUTPUT,
	@RefNo 			BIGINT = 0 OUTPUT,
	@transdate 		DATETIME = NULL OUTPUT,
	@ErrCode 		INT = 0 OUTPUT,
	@ErrMsg 		NVARCHAR(200) = '' OUTPUT
AS
/*
Creator:20170518@Bobby
Task : Record transactions for initializing & cancelling bonus wallet for Deposit sites
DB: DBTXN/bodb02

Revisions:
	- 20170518@Bobby: Initialize
	
Param's Explanation:
	- @custid: player account who joined bonus program
	- @bal_custid: Custid of "Balance" (dummy) account to record opposite value for transaction
	
	Full structure of balance accounts:
	--ACC Super		12BETSuperUS$		12BETSuperEURO
	--ACC Master	12BetACCUS$			12BetACCEURO
	--ACC Agent		12BetACCUS$01		12BetACCEURO01
	--ACC Member	12BETBonus02US$		12BETBonus02EURO
	
	- @bonusId: Id of bonus program being joined by customer
	- @amount: 
		+ @bettype=22026: Given amount when  initializing bonus wallet. 
		+ @bettype=22027: Take out the bonus amount when  cancelling bonus wallet
		
	- @lockedAmount:  Initial locked bonus amount when @bettype = 22026
	- @bettype:
		+ 22026: Transfer Bonus for initial bonus wallet
		+ 22027: Transfer Bonus for cancelling / zerolize bonus wallet
	
	
	- @ErrCode:
		= 0: Transaction recorded successfully.
		> 0: Specific Error.
	
	- @ErrMsg: Error description.
*/
BEGIN
	SET NOCOUNT ON
	--------------------------------

	DECLARE @username 		VARCHAR(50),
		@currency 			TINYINT,
		@currencyName 		VARCHAR(5),
		@actualrate 		FLOAT,
		@cust_winlost 		MONEY,	
		@cust_actual_stake 	MONEY,
		@mrecommend 		INT,
		@recommend 			INT,
		@srecommend 		INT,
		@roleid 			TINYINT,
		
		--Balance Account info
		@bal_winlost 		MONEY,	
		@bal_actual_stake 	MONEY,
		@bal_mrecommend 	INT,
		@bal_recommend 		INT,
		@bal_srecommend 	INT,
		@bal_Username 		VARCHAR(50),
		@bal_currency 		TINYINT,
		@bal_actualrate 	FLOAT,
		@bal_currencyName 	NVARCHAR(5),
		
		--bettype transfer
		@bonus_initial 		SMALLINT,
		@bonus_zerolize 	SMALLINT,
		@bonus_amount		MONEY,
		@walletType			TINYINT

	SELECT @ErrCode				= 0,
			@ErrMsg				= '',
			@bonus_initial		= 22026,
			@bonus_zerolize		= 22027,
			@walletType			= 1
			

	IF (@bettype NOT IN (@bonus_initial, @bonus_zerolize) OR @bonusId <= 0)
	BEGIN
		SELECT @ErrMsg = 'Sorry, transaction type or bonus ID is invalid.', @ErrCode = 101	
		RETURN		
	END

	SELECT @username = username, @currency = ci.currency, @currencyName = e.currency, @actualrate = e.actualrate,
		@mrecommend = mrecommend, @recommend = recommend, @srecommend = srecommend, @roleid = roleid
	FROM CustDB.dbo.custinfo AS ci WITH (NOLOCK) 
		INNER JOIN CustDB.dbo.exchange AS e WITH (NOLOCK) 
		ON ci.currency = e.exchangeid
	WHERE ci.custid = @custid
	
	IF (@@rowcount = 0)
	BEGIN
		SELECT @username = username, @currency = ci.currency, @currencyName = e.currency, @actualrate = e.actualrate,
			@mrecommend = mrecommend, @recommend = recommend, @srecommend = srecommend, @roleid = roleid
		FROM DBCUST.CustDB.dbo.custinfo AS ci with (NOLOCK) 
			INNER JOIN DBCUST.CustDB.dbo.exchange AS e with (NOLOCK) 
			on ci.currency = e.exchangeid
		WHERE ci.custid = @custid
	END

	SELECT 
		--bonus amount
		@bonus_amount		= ABS(@amount),
		--member winlost
		@cust_winlost 		= CASE WHEN @bettype = @bonus_initial THEN @bonus_amount WHEN @amount > 0 THEN @bonus_amount ELSE 0 END,
		@cust_actual_stake 	= CASE WHEN @bettype = @bonus_initial THEN 0 WHEN @amount > 0 THEN 0 ELSE @bonus_amount END,
		--bal winlost
		@bal_winlost 		= CASE WHEN @bettype = @bonus_initial THEN 0 WHEN @amount > 0 THEN 0 ELSE @bonus_amount END,
		@bal_actual_stake 	= CASE WHEN @bettype = @bonus_initial THEN @bonus_amount WHEN @amount > 0 THEN @bonus_amount ELSE 0 END,
		--trans description
		@transdesc 			= @username + ' - Bonus ' + CASE WHEN @transdesc <> '' THEN ' - ' + @transdesc END
		
	
					
	IF @roleid <> 1
	BEGIN
		SELECT @ErrMsg = 'Invalid Role ID.', @ErrCode = 102		
		RETURN
	END

	----------------------------------
	--Check balance Account
	SELECT @bal_custid = c.custid, @bal_Username = c.username,
		@bal_mrecommend = c.mrecommend, @bal_recommend = c.recommend, @bal_srecommend = c.srecommend,
		@bal_currency = c.currency, @bal_actualrate = e.actualrate, @bal_currencyName = e.currency
	FROM CustDB.dbo.customer c WITH (NOLOCK)
		INNER JOIN CustDB.dbo.exchange AS e WITH (NOLOCK) 
		ON c.currency = e.exchangeid
	WHERE c.custid = @bal_custid
	
	IF @@rowcount = 0
	BEGIN
		SELECT @bal_custid = c.custid, @bal_Username = c.username,
			@bal_mrecommend = c.mrecommend, @bal_recommend = c.recommend, @bal_srecommend = c.srecommend,
			@bal_currency = c.currency, @bal_actualrate = e.actualrate, @bal_currencyName = e.currency
		FROM DBCUST.CustDB.dbo.customer c WITH (NOLOCK)
			INNER JOIN DBCUST.CustDB.dbo.exchange AS e WITH (NOLOCK) 
			ON c.currency = e.exchangeid
		WHERE c.custid = @bal_custid
	END

	IF (@bal_mrecommend IS NULL )
	BEGIN
		SELECT @ErrMSg = 'Invalid balance account.', @ErrCode = 103			
			RETURN
	END
	----------------------------------

	--- Block cross currency transfers. ----
	IF @currencyName <> @bal_currencyName
	BEGIN
		SELECT @ErrMSg = 'Sorry, cross currency transfers are not allowed!', @ErrCode = 104
		RETURN
	END
	
	IF @RefNo = 0
	BEGIN	
		EXEC dbo.Acc_SelRefNo @RefNo = @RefNo OUTPUT
		SELECT @RefNo = @RefNo + 100000000000	
	END
	
	---Update Debit Balance	first with high priority if any
	IF(@amount < 0 AND @bettype = @bonus_zerolize)
	BEGIN
		EXEC dbo.Dot_BalanceDebitUpd @CustID = @CustID, @balance = @bonus_amount, @type = 2, @isForced = 1, @ErrCode = @ErrCode OUTPUT
		IF @ErrCode <> 0
		BEGIN
			SELECT @ErrMsg = 'Insert balance debit failed.', @ErrCode = 110	
			RETURN
		END
	END
	
	---Insert bonus transfer for cust
	SELECT @transdate = CURRENT_TIMESTAMP

	INSERT INTO bettrans 
		(custid, username, refno, transdate, matchid, bettype, transdesc,winlost, actual_stake, winlostdate, 
		 creator,recommend,mrecommend,srecommend,currency,actualrate, currencyName, ruben, status, statusID, ip, WalletType, bonusid)
	VALUES 
		(@CustID, @username, @RefNo, @transdate, 0, @bettype, @transdesc,@cust_winlost, @cust_actual_stake, convert(nvarchar(10), @transdate, 120), 
		 @CustID, @Recommend, @MRecommend, @SRecommend, @Currency,@actualrate, @currencyName, 1, 'Completed', 131, @ip, @walletType, @bonusId)

	IF @@ERROR <> 0
	BEGIN						
		SELECT @ErrMsg = 'Insert transaction for account failed.', @ErrCode = 105	
		--Manually rollback 
		DELETE FROM dbo.bettrans WHERE refno = @RefNo AND matchid = 0 AND bettype = @bettype AND custid IN (@custid, @bal_custID)
		
		--Manually rollback balance debit if any
		IF(@amount < 0 AND @bettype = @bonus_zerolize)
		BEGIN
			EXEC dbo.Dot_BalanceCreditUpd @CustID = @CustID, @balance = @bonus_amount, @type = 2
		END
		RETURN
	END
	
	SELECT @TransID = SCOPE_IDENTITY()

	---Insert bonus transfer for bal acc
	INSERT INTO bettrans 
		(custid, username, refno, transdate, matchid, bettype, transdesc,winlost, actual_stake, winlostdate, 
		 creator,recommend,mrecommend,srecommend,currency,actualrate, currencyName, ruben, status, statusID, ip, WalletType, bonusid)
	VALUES 
		(@bal_custID, @bal_Username, @RefNo, @transdate, 0, @bettype, @transdesc, @bal_winlost, @bal_actual_stake, convert(nvarchar(10), @transdate, 120), 
		 @CustID, @bal_recommend, @bal_mrecommend, @bal_srecommend, @bal_currency, @bal_actualrate, @bal_currencyName, 1, 'Completed', 131, @ip, @walletType, @bonusId)

	IF @@ERROR <> 0
	BEGIN
		SELECT @ErrMsg = 'Insert transaction for dummy failed.', @ErrCode = 106
		--Manually rollback
		DELETE FROM dbo.bettrans WHERE refno = @RefNo AND matchid = 0 AND bettype = @bettype AND custid IN (@custid, @bal_custID)
		--Manually rollback balance debit if any
		IF(@amount < 0 AND @bettype = @bonus_zerolize)
		BEGIN
			EXEC dbo.Dot_BalanceCreditUpd @CustID = @CustID, @balance = @bonus_amount, @type = 2
		END
		RETURN
	END
	
	SELECT @bal_transid = SCOPE_IDENTITY()
	SET @transdate = CONVERT(CHAR(30),@transdate, 121)
	
	DECLARE @Bal_Success 	BIT = 0
	BEGIN TRY
					
		-----------------INITIAL Bonus Wallet----------------------
		IF(@bettype = @bonus_initial)
		BEGIN
			--insert bonus credit
			WITH CTE_BonusCredit AS
			(
				SELECT 
				   @CustID AS CustId
				   ,@BonusID AS BonusID
				   ,4 AS StatusID --running
				   ,@bonus_amount AS initBonus
				   ,@lockedAmount AS initLockedAmt
				   ,0 AS Bonus
				   ,0 AS LockedAmt
			)
			MERGE [dbo].[BonusWalletCredit] AS bc
			USING CTE_BonusCredit AS temp 
				ON (bc.CustId = temp.custid AND bc.BonusId = temp.BonusId)
			WHEN NOT MATCHED THEN
				INSERT 
				   ([CustID]
				   ,[BonusID]
				   ,[StatusID]
				   ,[initBonus]
				   ,[initLockedAmt]
				   ,[Bonus]
				   ,[LockedAmt])
				VALUES (
					temp.[CustID]
				   ,temp.[BonusID]
				   ,temp.[StatusID]
				   ,temp.[initBonus]
				   ,temp.[initLockedAmt]
				   ,temp.[Bonus]
				   ,temp.[LockedAmt]
				)
			WHEN MATCHED THEN
				UPDATE
				SET [StatusID]		= temp.[StatusID]
				   ,[initBonus]		= temp.[initBonus]
				   ,[initLockedAmt] = temp.[initLockedAmt]
				   ,[Bonus]			= temp.[Bonus]
				   ,[LockedAmt]		= temp.[LockedAmt]
			;			
			
			--insert bonus debit
			;WITH CTE_BonusDebit AS (
				SELECT 
					@CustID AS CustID
				   ,@BonusID AS BonusID
				   ,0 AS Bonus
				   ,0 AS LockedAmt
			)
			MERGE [dbo].[BonusWalletDebit] AS bd
			USING CTE_BonusDebit AS temp
				ON (bd.CustId = temp.custid AND bd.BonusId = temp.BonusId)
			WHEN NOT MATCHED THEN
				INSERT ([CustID]
				   ,[BonusID]
				   ,[Bonus]
				   ,[LockedAmt])
				VALUES(
					[CustID]
				   ,[BonusID]
				   ,[Bonus]
				   ,[LockedAmt]
				)
			WHEN MATCHED THEN
				UPDATE
				SET [Bonus] = temp.[Bonus]
				   ,[LockedAmt] = temp.[LockedAmt]
			;
			
			---Update Credit Balance	
			EXEC dbo.Dot_BalanceCreditUpd @CustID = @CustID, @balance = @bonus_amount, @type = 2, @ErrCode = @ErrCode OUTPUT
			
			IF(@ErrCode <> 0)
			BEGIN
				SELECT @ErrMsg = 'Insert balance credit failed.', @ErrCode = 107
				
				--Manually rollback
				DELETE FROM dbo.bettrans WHERE refno = @RefNo AND matchid = 0 AND bettype = @bettype AND custid IN (@custid, @bal_custID)

				--delete [BonusWalletCredit]
				DELETE [dbo].[BonusWalletCredit]
				WHERE custid = @custid
					AND bonusid = @bonusid

				--delete [BonusWalletDebit]
				DELETE [dbo].[BonusWalletDebit]
				WHERE custid = @custid
					AND bonusid = @bonusid

				RETURN
			END
			ELSE
			BEGIN
				SET @Bal_Success = 1
			END
		END
		ELSE IF(@bettype = @bonus_zerolize)
		BEGIN
			---Update Credit Balance	
			IF(@amount > 0)
			BEGIN
				EXEC dbo.Dot_BalanceCreditUpd @CustID = @CustID, @balance = @bonus_amount, @type = 2, @ErrCode = @ErrCode OUTPUT
			END
			
			IF(@ErrCode <> 0)
			BEGIN
				SELECT @ErrMsg = 'Insert balance credit failed.', @ErrCode = 109
				
				--Manually rollback
				DELETE FROM dbo.bettrans WHERE refno = @RefNo AND matchid = 0 AND bettype = @bettype AND custid IN (@custid, @bal_custID)
				
				RETURN
			END
			ELSE
			BEGIN
				SET @Bal_Success = 1
			END
		END
	END TRY
	BEGIN CATCH
		SELECT @ErrMsg = 'Insert/Update bonus wallet failed.', @ErrCode = 108
		
		--Manually rollback
		DELETE FROM dbo.bettrans WHERE refno = @RefNo AND matchid = 0 AND bettype = @bettype AND custid IN (@custid, @bal_custID)
		
		IF (@bettype = @bonus_initial)
		BEGIN
			--rollback [BonusWalletCredit]
			DELETE [dbo].[BonusWalletCredit]
			WHERE custid = @custid
				AND bonusid = @bonusid

			--rollback [BonusWalletDebit]
			DELETE [dbo].[BonusWalletDebit]
			WHERE custid = @custid
				AND bonusid = @bonusid
		END
		--Manually rollback balance debit if any
		IF(@amount < 0 AND @bettype = @bonus_zerolize)
		BEGIN
			EXEC dbo.Dot_BalanceCreditUpd @CustID = @CustID, @balance = @bonus_amount, @type = 2
		END
		
		RETURN
	END CATCH
	
	-----------------Write Log Bonus Wallet----------------------
	BEGIN TRY
		DECLARE @LogData VARCHAR(300)

		SELECT @LogData = 
				'Insert bonus transfer custid = ' + CONVERT(VARCHAR(20), @custid) 
				+ ', bettype = ' + CONVERT(VARCHAR(20), @bettype) 
				+ ', bonusid = ' + CONVERT(VARCHAR(20), @bonusId) 
				+ ', amount = ' + CONVERT(VARCHAR(20), @amount)
				+ ', lockedAmount = ' + CONVERT(VARCHAR(20), @lockedAmount)
	
		EXEC dbo.WriteLog_UserLog @UserID = @custid, @Doing = @LogData
	END TRY
	BEGIN CATCH
		-- IF write log error: not RETURN error code
	END CATCH
END
GO
