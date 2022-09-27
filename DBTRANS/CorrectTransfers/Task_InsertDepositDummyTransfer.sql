/*<info serverAlias="DBTXN-bodb02" executers="Dot_Member,Dot_Bonus" viewers="vnteam" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_InsertDepositDummyTransfer]
	(
		@CustID		INT,
		@Bal_CustID INT,
		@Refno		BIGINT
	)
/*
	DB: DBTXN.BODB02
	Revision:
		- 20220927@Evan: Create new [Redmine: #178188]
	Param explaination:
		- @CustID		: CustID of transaction to correct
		- @Bal_CustID	: CustID of pairing dummy account
		- @Refno		: Transaction refno to be corrected
*/	
AS
BEGIN	
	SET NOCOUNT ON
	
   /*
		Checking valid account / transaction
   */ 

   	IF (SELECT COUNT(*) FROM dbo.Transfer WITH(NOLOCK) WHERE Refno = @Refno AND CustID = @CustID) = 0
		BEGIN
			PRINT 'There is no transaction.'
			RETURN
		END
	 
	IF (SELECT COUNT(*) FROM dbo.Transfer WITH(NOLOCK) WHERE Refno = @Refno AND CustID = @Bal_CustID) > 0
		BEGIN
			PRINT 'Transaction for dummy account existed.'
			RETURN
		END  

	IF NOT EXISTS(SELECT 1 FROM CustDB.dbo.Customer WITH(NOLOCK) WHERE CustID = @CustID)
		BEGIN
			PRINT 'Invalid customer account.'
			RETURN
		END
	 
	IF NOT EXISTS(SELECT 1 FROM CustDB.dbo.Customer WITH(NOLOCK) WHERE CustID = @Bal_CustID)
		BEGIN
			PRINT 'Invalid balance account.'
			RETURN
		END
	 
	IF NOT EXISTS(SELECT 1 FROM dbo.Transfer WITH(NOLOCK) WHERE Refno = @Refno)
		BEGIN
			PRINT 'Invalid Refno number.'
			RETURN
		END
	 
   /*** INSERT TRANSACTION ***/
    DECLARE @Transdate          DATETIME
            ,@Transdesc         NVARCHAR(300)
            ,@Bettype           SMALLINT
            ,@Actual_Stake      MONEY
            ,@Winlost           MONEY
            ,@IP                VARCHAR(45)
     
    DECLARE
            @Bal_mrecommend         INT
            ,@Bal_recommend         INT
            ,@Bal_srecommend        INT
            ,@Bal_username          VARCHAR(50)
            ,@Bal_currency          TINYINT
            ,@Bal_actualrate        FLOAT
            ,@Bal_currencyname      NVARCHAR(50)
			,@Bal_TransID				BIGINT
			,@TransID				BIGINT
     
    SELECT
        @Transdate          = transdate
        ,@Transdesc         = transdesc
        ,@Bettype           = bettype
        ,@Actual_Stake      = actual_stake
        ,@Winlost           = winlost
        ,@IP                = ip
        ,@Bal_actualrate    = actualrate
        ,@Bal_TransID		= TransId
    FROM dbo.Transfer WITH(NOLOCK)
    WHERE custid = @CustID AND refno = @Refno  
     
    SELECT     
        @Bal_username = c.username
        ,@Bal_mrecommend = c.mrecommend, @Bal_recommend = c.recommend, @Bal_srecommend = c.srecommend
        ,@Bal_currency = c.currency, @Bal_currencyname = e.currency
    FROM CustDB.dbo.Customer c WITH(NOLOCK)
            INNER JOIN CustDB.dbo.Exchange e WITH(NOLOCK) ON c.currency = e.exchangeid
    WHERE c.custid = @Bal_CustID
    
	-----------------------
    --Get new transid 

	EXEC Get_Bettrans_TransID @TransID = @TransID OUTPUT

    INSERT INTO dbo.Transfer (
        TransId, CustId, Username, RefNo, TransDate, Bettype, TransDesc, Winlost, Actual_Stake, WinlostDate, 
        Creator, Recommend, MRecommend, SRecommend, Currency, ActualRate, CurrencyName, StatusId, IP, RepUpdateTime
        )
        VALUES (
            @TransID, @Bal_CustID, @Bal_username, @Refno, @Transdate, @Bettype, @Transdesc, @Actual_Stake, @Winlost, CONVERT(NVARCHAR(10), @Transdate, 120), 
            @CustID, @Bal_recommend, @Bal_mrecommend, @Bal_srecommend, @Bal_currency, @Bal_actualrate, @Bal_currencyname, 131, @IP, SYSDATETIME()
            )
	
	IF EXISTS(SELECT 1 FROM TransferInfo WITH (NOLOCK) WHERE TransId = @Bal_TransID)
	BEGIN
		INSERT INTO TransferInfo (TransId,APositiontaking,MPositiontaking,SPositiontaking,EPositiontaking,PlayerDiscount,Discount,ADiscount,SDiscount,WalletType,BonusID,Amount,CheckerId,CheckerName,IsCollection,IsDel,RepUpdateTime)
		SELECT @TransID,APositiontaking,MPositiontaking,SPositiontaking,EPositiontaking,PlayerDiscount,Discount,ADiscount,SDiscount,WalletType,BonusID,Amount,CheckerId,CheckerName,IsCollection,IsDel,SYSDATETIME()
		FROM TransferInfo WITH (NOLOCK) 
		WHERE TransId = @Bal_TransID
	END

	-----------------------
	
	DECLARE @Cust_balance MONEY,
			@Cust_balance_ABS MONEY;

	SELECT @Cust_balance = @winlost - @actual_stake
	SELECT @Cust_balance_ABS = ABS(@Cust_balance)

	IF @Cust_balance < 0
	BEGIN
		EXEC Dot_BalanceDebitUpd @CustID = @CustID, @balance = @Cust_balance_ABS, @type = 2
	END
	ELSE
	BEGIN
		EXEC Dot_BalanceCreditUpd @CustID = @CustID, @balance = @Cust_balance, @type = 2
	END

END
