/*<info serverAlias="DBTXN-bodb02" executers="Dot_Member" viewers="vnteam" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Dot_Dep_BettransInsBonusWallet_Initial] 
	@custid int,
	@bal_custid int,
	@bettype SMALLINT = 22026,
	@bonusId int,
	@amount money,	
	@lockedAmount money,	
	@transdesc nvarchar(300),
	@ip	nvarchar(15)='',
	@transid bigint = 0 OUTPUT,	
	@bal_transid bigint = 0 OUTPUT,
	@RefNo bigint = 0 OUTPUT,
	@transdate DateTime = NULL OUTPUT,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
Creator:20170518@Bobby
Task : Record transactions bonus and initial bonus wallet for Deposit sites
DB: DBTXN/bodb02

Revisions:

Param's Explanation:
	- @custid: player account who joined bonus program
	- @bal_custid: Custid of "Balance" (dummy) account to record opposite value for transaction
				For ex: 12BetBonus02US$, 12BetNetellerGBP
	
	Full structure of balance accounts:
	--ACC Super		12BETSuperUS$		12BETSuperEURO
	--ACC Master	12BetACCUS$			12BetACCEURO
	--ACC Agent		12BetACCUS$01		12BetACCEURO01

		--ACC Member	12BETBonus02US$		12BETBonus02EURO
	- @bonusId: Id of bonus program being joined by customer
	- @amount: Given bonus amount
	- @lockedAmount:  Initial locked bonus amount
	- @bettype:
		22026: Transfer Bonus and initial bonus wallet
	
	
	- @ErrCode:
		= 0: Transaction recorded successfully.
		> 0: Specific Error.
	
	- @ErrMsg: Error description.
*/
BEGIN
	SET NOCOUNT ON
	--------------------------------

	declare @username varchar(50),
		@currency tinyint,
		@currencyName varchar(5),
		-- @transdate datetime,	
		@actualrate float,
		@cust_winlost money,	
		@cust_actual_stake money,
		@mrecommend int,
		@recommend int,
		@srecommend int,
		@roleid tinyint,
		
		--Balance Account info
		@bal_winlost money,	
		@bal_actual_stake money,
		@bal_mrecommend int,
		@bal_recommend int,
		@bal_srecommend int,
		@bal_Username varchar(50),
		@bal_currency tinyint,
		@bal_actualrate float,
		@bal_currencyName nvarchar(5)

	Select @ErrCode = 0,
			@ErrMsg = ''
			

	if (@amount <= 0 OR @lockedAmount <= 0 OR @bonusId <= 0)
	BEGIN
		Select @ErrMsg = 'Sorry, amount or bonus ID is invalid.', @ErrCode = 101	
		return		
	END

	Select @username = username, @currency = ci.currency, @currencyName = e.currency, @actualrate = e.actualrate,
		@mrecommend = mrecommend, @recommend = recommend, @srecommend = srecommend, @roleid = roleid
	from CustDB.dbo.custinfo as ci with (NOLOCK) 
	INNER JOIN CustDB.dbo.exchange as e with (NOLOCK) on ci.currency = e.exchangeid
	where ci.custid = @custid
	
	IF @@rowcount = 0
	BEGIN
		Select @username = username, @currency = ci.currency, @currencyName = e.currency, @actualrate = e.actualrate,
			@mrecommend = mrecommend, @recommend = recommend, @srecommend = srecommend, @roleid = roleid
		from DBCUST.CustDB.dbo.custinfo as ci with (NOLOCK) 
		INNER JOIN DBCUST.CustDB.dbo.exchange as e with (NOLOCK) on ci.currency = e.exchangeid
		where ci.custid = @custid
	END

	SELECT 
		@cust_winlost = @amount,
		@cust_actual_stake = 0,
		@bal_winlost = 0,
		@bal_actual_stake = @amount,
		@transdesc = @username + ' - Bonus '
					+ case when @transdesc <> '' then ' - ' + @transdesc end
					
	if @roleid <> 1
	BEGIN
		Select @ErrMsg = 'Invalid Role ID.', @ErrCode = 102		
		return
	END

	----------------------------------
	--Check balance Account

	select @bal_custid = c.custid, @bal_Username = c.username,
		@bal_mrecommend = c.mrecommend, @bal_recommend = c.recommend, @bal_srecommend = c.srecommend,
		@bal_currency = c.currency, @bal_actualrate = e.actualrate, @bal_currencyName = e.currency
	from CustDB.dbo.customer c with (nolock)
	inner join CustDB.dbo.exchange as e with (nolock) on c.currency = e.exchangeid
	where c.custid = @bal_custid
	
	IF @@rowcount = 0
	BEGIN
		select @bal_custid = c.custid, @bal_Username = c.username,
			@bal_mrecommend = c.mrecommend, @bal_recommend = c.recommend, @bal_srecommend = c.srecommend,
			@bal_currency = c.currency, @bal_actualrate = e.actualrate, @bal_currencyName = e.currency
		from DBCUST.CustDB.dbo.customer c with (nolock)
		inner join DBCUST.CustDB.dbo.exchange as e with (nolock) on c.currency = e.exchangeid
		where c.custid = @bal_custid
	END

	if @bal_mrecommend is NULL 
	BEGIN
		Select @ErrMSg = 'Invalid balance account.', @ErrCode = 103			
			return
	END
	----------------------------------

	--- Block cross currency transfers. ----
	IF @currencyName <> @bal_currencyName
	BEGIN
		SELECT @ErrMSg = 'Sorry, cross currency transfers are not allowed!', @ErrCode = 104
		RETURN
	END
	
	if @RefNo = 0
	BEGIN	
		EXEC dbo.Acc_SelRefNo @RefNo = @RefNo OUTPUT
		select @RefNo = @RefNo + 100000000000	
	END

	---Insert bonus transfer for cust
	SELECT @transdate = current_timestamp

	INSERT INTO bettrans 
		(custid, username, refno, transdate, matchid, bettype, transdesc,winlost, actual_stake, winlostdate, 
		 creator,recommend,mrecommend,srecommend,currency,actualrate, currencyName, ruben, status, statusID, ip)
	VALUES 
		(@CustID, @username, @RefNo, @transdate, 0, @bettype, @transdesc,@cust_winlost, @cust_actual_stake, convert(nvarchar(10), @transdate, 120), 
		 @CustID, @Recommend, @MRecommend, @SRecommend, @Currency,@actualrate, @currencyName, 1, 'Completed', 131, @ip)

	if @@ERROR <> 0
	BEGIN						
		Select @ErrMsg = 'Insert transaction for account failed.', @ErrCode = 105	
		--Manually rollback 
		DELETE FROM bettrans where refno = @RefNo and matchid = 0 and bettype = @bettype and custid in (@custid, @bal_custID)
		
		return
	END
	
	Select @TransID = @@IDENTITY

	---Insert bonus transfer for bal acc
	INSERT INTO bettrans 
		(custid, username, refno, transdate, matchid, bettype, transdesc,winlost, actual_stake, winlostdate, 
		 creator,recommend,mrecommend,srecommend,currency,actualrate, currencyName, ruben, status, statusID, ip)
	VALUES 
		(@bal_custID, @bal_Username, @RefNo, @transdate, 0, @bettype, @transdesc, @bal_actual_stake, @bal_winlost, convert(nvarchar(10), @transdate, 120), 
		 @CustID, @bal_recommend, @bal_mrecommend, @bal_srecommend, @bal_currency, @bal_actualrate, @bal_currencyName, 1, 'Completed', 131, @ip)

	if @@ERROR <> 0
	BEGIN
		Select @ErrMsg = 'Insert transaction for dummy failed.', @ErrCode = 106
		--Manually rollback
		DELETE FROM bettrans where refno = @RefNo and matchid = 0 and bettype = @bettype and custid in (@custid, @bal_custID)
		return
	END
	
	Select @bal_transid = @@IDENTITY
	SET @transdate = CONVERT(CHAR(30),@transdate, 121)
	
	DECLARE @Bal_Success BIT = 0

	BEGIN TRY
		-----------------INITIAL Bonus Wallet----------------------
		--insert bonus credit
		INSERT INTO [dbo].[BonusWalletCredit]
			   ([CustID]
			   ,[BonusID]
			   ,[StatusID]
			   ,[initBonus]
			   ,[initLockedAmt]
			   ,[Bonus]
			   ,[LockedAmt])
		SELECT 
			   @CustID
			   ,@BonusID
			   ,4 AS StatusID --running
			   ,@amount AS initBonus
			   ,@lockedAmount AS initLockedAmt
			   ,0 AS Bonus
			   ,0 AS LockedAmt
		
		--insert bonus debit
		INSERT INTO [dbo].[BonusWalletDebit]
			   ([CustID]
			   ,[BonusID]
			   ,[Bonus]
			   ,[LockedAmt])
		 SELECT
			   @CustID AS CustID
			   ,@BonusID AS BonusID
			   ,0 AS Bonus
			   ,0 AS LockedAmt
		
		---Update Credit Balance	
		EXEC dbo.Dot_BalanceCreditUpd @CustID = @CustID, @balance = @amount, @type = 2, @ErrCode = @ErrCode OUTPUT
		
		IF(@ErrCode <> 0)
		BEGIN
			Select @ErrMsg = 'Insert balance credit failed.', @ErrCode = 107
			
			--Manually rollback
			DELETE FROM bettrans where refno = @RefNo and matchid = 0 and bettype = @bettype and custid in (@custid, @bal_custID)

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
	END TRY
	BEGIN CATCH
		Select @ErrMsg = 'Initial bonus wallet failed.', @ErrCode = 108
		
		--Manually rollback
		DELETE FROM bettrans where refno = @RefNo and matchid = 0 and bettype = @bettype and custid in (@custid, @bal_custID)
		
		--delete [BonusWalletCredit]
		DELETE [dbo].[BonusWalletCredit]
		WHERE custid = @custid
			AND bonusid = @bonusid

		--delete [BonusWalletDebit]
		DELETE [dbo].[BonusWalletDebit]
		WHERE custid = @custid
			AND bonusid = @bonusid
				
		--rollback acc balance for sure
		/*IF(@Bal_Success = 1)
		BEGIN
			EXEC dbo.Dot_BalanceDebitUpd @CustID = @CustID, @balance = @amount, @type = 2, @isForced = 1
		END*/

		RETURN
	END CATCH
	
	-----------------Write Log Bonus Wallet----------------------
	BEGIN TRY
		declare @LogData varchar(300)

		Select @LogData = 
				'Insert bonus transfer custid = ' + convert(varchar(20), @custid) 
				+ ', bettype = ' + convert(varchar(20), @bettype) 
				+ ', bonusid = ' + convert(varchar(20), @bonusId) 
				+ ', amount = ' + convert(varchar(20), @amount)
				+ ', lockedAmount = ' + convert(varchar(20), @lockedAmount)
	
		EXEC dbo.WriteLog_UserLog @UserID = @custid, @Doing = @LogData
	END TRY
	BEGIN CATCH
		-- if write log error: not return error code
	END CATCH
END
GO
