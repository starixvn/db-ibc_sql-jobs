/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_CS_HeadlineBalance_Add]
(
	@winlostdate SMALLDATETIME,
	@custid      INT,
	@amount      MONEY,
	@transdesc   NVARCHAR(1000),
	@creator     INT,
	@ip          VARCHAR(20),
	@ErrCode     INT = 0 OUTPUT,  
    @ErrMsg      VARCHAR(100) = '' OUTPUT
)
AS
/*
	Creator: 20191018@Sophia 
	Remark: Insert transaction to bettrans for CN88 Headline balance
	DB: DBTXN-bodb02

	Revisions:
		- 20191018@Sophia: initial SP [Redmine: #117863]
	 

	Param's explain:
 

	 
*/
BEGIN
	SET NOCOUNT ON
 
	DECLARE		@RefNum bigint = 0, @bettype int, @Curr int, @CurrName nvarchar(10),
				@actualrate float, @Recommend int, @MRecommend int, @SRecommend int,
				@username nvarchar(50), @creditamt money, @debitamt money, @roleID tinyint	 
			
	IF NOT EXISTS (SELECT 1 FROM dbo.Bettrans WITH (NOLOCK) WHERE CustID = @CustID AND WinlostDate = @WinlostDate AND Bettype = 21007)
	BEGIN 

		IF @amount > 0  
		BEGIN
			SELECT @creditamt = ABS(@amount)
				,@debitamt = 0
				,@bettype = 21007
		END
		ELSE  
		BEGIN
			SELECT @creditamt = 0
				,@debitamt = ABS(@amount)
				,@bettype = 21007
		END


		SELECT @Curr = c.Currency
			,@actualrate = eo.actualrate
			,@currName = e.currency
			,@username = c.username
			,@Recommend = c.Recommend
			,@MRecommend = c.MRecommend
			,@SRecommend = c.SRecommend
			,@roleID = roleid
		FROM CustDB.dbo.custInfo c WITH (NOLOCK)
			INNER JOIN CustDB.dbo.ExchangeDailyOanda eo WITH (NOLOCK)
				ON c.currency = eo.exchangeid and eo.exchangeDate = @winlostdate
			INNER JOIN CustDB.dbo.Exchange e WITH (NOLOCK)
				ON c.currency = e.exchangeid
		WHERE c.CustID = @custid


		----Insert transaction
		EXEC Acc_SelRefNo
			@refNo = @RefNum OUTPUT

		SELECT @RefNum = @RefNum + 100000000000

		BEGIN TRY
			INSERT INTO bettrans
			(
				custid, username, refno, transdate, matchid,
				bettype, transdesc, winlost, actual_stake, winlostdate,
				creator, recommend, mrecommend, srecommend, currency,
				currencyName, actualrate, ruben, status, ip, statusID
			)
			VALUES
			(
				@CustID, @username, @RefNum, current_timestamp, 0,
				@bettype, @transDesc, @creditamt, @debitamt, @winlostdate,
				@creator, @Recommend, @MRecommend, @SRecommend, @curr,
				@currName, @actualrate, 1, 'Completed', @ip, 131
			)
		END TRY
				
		BEGIN CATCH 
			IF @@ERROR <> 0
			BEGIN
				SELECT @ErrCode = 1,
						@ErrMsg = 'Can not insert transaction of '+ CONVERT (VARCHAR(20),@CustID)+ ' ! Please try again later.'			

				RETURN
			END						
		END CATCH								
			 
	END
	ELSE 			
	BEGIN 
		UPDATE dbo.Bettrans WITH (ROWLOCK) 
		SET Winlost = CASE WHEN @amount >= 0 THEN @amount ELSE 0 END,
			Actual_Stake = CASE WHEN @amount <= 0 THEN ABS(@amount) ELSE 0 END
		WHERE CustID = @CustID
			AND WinlostDate = @WinlostDate
			AND Bettype = 21007	
	END			
END
GO