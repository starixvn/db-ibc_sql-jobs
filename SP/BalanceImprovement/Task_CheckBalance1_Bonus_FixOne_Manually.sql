/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_CheckBalance1_Bonus_FixOne_Manually]
	@custid int,
	@bonusId int,
	@DiffBalance money OUTPUT,
	@result int OUTPUT,
	@IsUUS bit = 0 OUTPUT
AS
/*
	Task: Correct member balance (balance tables of Bonus) for one given account
	Original: Task_CheckBalance_FixOne
	Location: DBTXN.bodb02
	Revision:
		- 20180326@Patrick: Changes bettype from 22026, 22027 to 22200, 22201
		- 20210514@Patrick: Revise Movebet flow to support transfer 247 - Redmine: [#149927]
		
	Param use:

	Logic & Process:
		check if member got bet in match being settle (exit if true)
		is there any pending?
			No? compute balance and compare
				if diff : adjust in sports set.
*/
SET NOCOUNT ON
SET @result = -1


--Check member has tickets bet on matches that are being calculated
IF EXISTS(SELECT 1 FROM bettrans WITH (NOLOCK) WHERE custid = @custid AND matchid IN(SELECT KeyValue FROM TempVariableNumber WHERE KeyID = 1))
BEGIN
	SET @result = 100
	RETURN
END
ELSE
BEGIN
	Declare @FromBettrans money, @FromSumWinloss money

	--
	-- Skip if Pending Found
	--
	
	IF	EXISTS (SELECT 1 FROM dbo.BonusWalletPending WITH (ROWLOCK) WHERE custid = @custid AND BonusID = @bonusId)		
	BEGIN
		SET @result = 200
		RETURN
	END
	ELSE
	BEGIN
		--
		-- Get/Compare Balance
		--
		DECLARE @__movebetdate SMALLDATETIME
		EXEC dbo.NAP_Admin_GetMovebetDate @MovebetDate = @__movebetdate OUTPUT

		__tryagain:
		SELECT @FromBettrans = SUM(CASE WHEN WalletType = 1 AND bettype NOT IN (22200, 22201) THEN winlost - actual_stake + playercomm ELSE 0 END)
		FROM dbo.bettrans WITH (ROWLOCK) 
		WHERE custid = @custid 
			AND BonusID = @bonusId
			AND 1 = CASE WHEN bettype = 19999 AND winlostdate > @__movebetdate THEN 0 --> new sum
				 WHEN bettype < 19999 AND winlostdate <= @__movebetdate THEN 0 --> old bet
				 ELSE 1 END

		DECLARE @__movebetdateF SMALLDATETIME
		EXEC dbo.NAP_Admin_GetMovebetDate @MovebetDate = @__movebetdateF OUTPUT

		IF @__movebetdate <> @__movebetdateF
		BEGIN
			SET @__movebetdate = @__movebetdateF
			GOTO __tryagain
		END

		SELECT @FromSumWinloss = SUM(Amount)
		FROM dbo.Bonus_sum_winloss WITH(NOLOCK)
		WHERE CustId = @custid AND BonusId = @bonusId
				
		SELECT @DiffBalance = (ISNULL(@FromBettrans, 0) + ISNULL(@FromSumWinloss, 0)) - (c1.Amount - d1.Amount)
		FROM dbo.BonusWalletCredit c1 WITH (ROWLOCK)
			INNER JOIN dbo.BonusWalletDebit d1 WITH (NOLOCK) ON c1.custid = d1.custid AND c1.BonusID = d1.BonusID
		WHERE c1.custid = @custid AND c1.BonusID = @bonusId
		
		--
		-- Take Action accordingly
		--
		--INSERT INTO dbo.BonusWalletPending(custid, bonusId, Amount) VALUES (@custid, @bonusId, @DiffBalance)
		
		SET @result = 0
		SELECT @IsUUS = CASE WHEN Currency = 20 THEN 1 ELSE 0 END
		FROM custdb.dbo.custInfo WITH (NOLOCK)
		WHERE custid = @custid
	END
END

GO