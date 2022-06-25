/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isNested="0"></info>*/
USE [bodb02]
GO
ALTER PROCEDURE [dbo].[Task_CheckBalance1_FixOne_Manually]
	@custid int,
	@DiffBalanceInput money = NULL,
	@DiffBalance money OUTPUT,
	@result int OUTPUT,
	@IsUUS bit = 0 OUTPUT
AS
/*
	Task: Correct member balance (balance tables) for one given account
	Original: Task_CheckBalance_FixOne
	Location: DBTXN.bodb02

	Revision:
		20150907@Daniel: Clone from Task_CheckBalance_FixOne & apply new set of bal tables
		20151210@Daniel: calc balance from table bettransRNG & bettransLC 
		20171002@Patrick: Update code for Bonus project
		20171201@Patrick: Bullfighting - calc waiting ticket into outstanding amt on translog
		20190319@Patrick: Exclude CN88 account - push code to git [RedmineID: #110530]
		20210514@Patrick: Revise Movebet flow to support transfer 247 - Redmine: [#149927]
		20211231@Patrick: Split bettype >= 19999 out bettrans Redmine: [#164197]
		20220615@Patrick: Update code for DBBR Redmine: [#174024]

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
	Declare @FromBettrans money, 
			@FromTransLog money, @FromBettransRNG money, @FromBettransLC money,
			@FromAdjustmentTransfer money,
			@FromTransfer money,
			@FromBetRunning money

	--
	-- Skip if Pending Found
	--
	
	IF	EXISTS (SELECT 1 FROM dbo.BalCreditSportsPending with (nolock) WHERE custid = @custid) OR
		EXISTS (SELECT 1 FROM dbo.BalCreditCasinoPending  with (nolock) WHERE custid = @custid) OR
		EXISTS (SELECT 1 FROM dbo.BalCreditOthersPending  with (nolock) WHERE custid = @custid) OR
		EXISTS (SELECT 1 FROM dbo.BalDebitSportsPending  with (nolock) WHERE custid = @custid) OR
		EXISTS (SELECT 1 FROM dbo.BalDebitCasinoPending  with (nolock) WHERE custid = @custid) OR
		EXISTS (SELECT 1 FROM dbo.BalDebitOthersPending  with (nolock) WHERE custid = @custid)		
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
			, @__fromRepUpdateTime DATETIME2

		SET @__fromRepUpdateTime = DATEADD(HOUR, -2, SYSDATETIME()) --get data within 2 hours ==> need to review to select best value
		EXEC dbo.NAP_Admin_GetMovebetDate @MovebetDate = @__movebetdate OUTPUT

		__tryagain:

		--getting data from BR
		IF OBJECT_ID('tempdb.dbo.#__betsRunningByCustId') IS NOT NULL
			DROP TABLE #__betsRunningByCustId

		CREATE TABLE #__betsRunningByCustId (BRID BIGINT, actual_stake MONEY)
		DECLARE @__query NVARCHAR(MAX) = ''
		SELECT	@__query = @__query + N'\
INSERT INTO	#__betsRunningByCustId(BRID, actual_stake)
SELECT BRID, actual_stake
FROM	OPENQUERY(DBBR, ''\
DECLARE	@__custid INT = ''''' + CONVERT(NVARCHAR(50), @custid, 121) + '''''
DECLARE	@__repUpdateTime DATETIME2 = ''''' + CONVERT(NVARCHAR(50), @__fromRepUpdateTime, 121) + '''''

SELECT BRID, actual_stake
FROM bodb02.dbo.bettrans_running br WITH(NOLOCK, INDEX=IX_custid)
WHERE custid = @__custid AND RepUpdateTime >= @__repUpdateTime'');';

		EXECUTE	sys.sp_executesql @__query

		SELECT @FromBetRunning = SUM(-ISNULL(actual_stake, 0))
		FROM #__betsRunningByCustId br
			LEFT JOIN (
				SELECT BRID
				FROM dbo.bettrans WITH(NOLOCK, INDEX=IX_customerinfo)
				WHERE custid = @custid
					AND 1 = CASE WHEN bettype >= 19999 THEN 0 --> get from transfer table
						 WHEN bettype < 19999 AND winlostdate <= @__movebetdate THEN 0 --> old bet
						 ELSE 1 END
			) b ON br.BRID = b.BRID
		WHERE b.BRID IS NULL

		IF ISNULL(@FromBetRunning, 0) <> 0
		BEGIN
			SET @result = 333 -->>having data in BR
			RETURN
		END

		SELECT @FromBettrans = SUM(winlost-actual_stake+playercomm)	
		FROM dbo.bettrans with (rowlock) 
		WHERE custid = @custid
			AND 1 = CASE WHEN bettype >= 19999 THEN 0 --> get from transfer table
				 WHEN bettype < 19999 AND winlostdate <= @__movebetdate THEN 0 --> old bet
				 ELSE 1 END

		SELECT @FromTransfer = SUM(winlost-actual_stake+playercomm)	
		FROM dbo.Transfer with (rowlock) 
		WHERE custid = @custid
			AND 1 = CASE WHEN bettype = 19999 AND winlostdate > @__movebetdate THEN 0 --> new sum
				 ELSE 1 END

		DECLARE @__movebetdateF SMALLDATETIME
		EXEC dbo.NAP_Admin_GetMovebetDate @MovebetDate = @__movebetdateF OUTPUT

		IF @__movebetdate <> @__movebetdateF
		BEGIN
			SET @__movebetdate = @__movebetdateF
			GOTO __tryagain
		END
		
		SELECT @FromAdjustmentTransfer = SUM(Amount)
		FROM dbo.BonusAdjustmentTransfer WITH(NOLOCK)
		WHERE isTransferred = 0 AND custid = @custid

		SELECT @FromTransLog = SUM(actual_stake) FROM dbo.translog with (rowlock) WHERE custid = @custid and statusID IN (0,1)

		SELECT @FromBettransRNG = SUM(CASE WHEN statusid = 0 then -actual_stake ELSE winlost-actual_stake+playercomm END) 
		FROM dbo.bettransRNG WITH(NOLOCK)
		WHERE IsSum = 0 AND custid = @custid
		
		SELECT @FromBettransLC = SUM(CASE WHEN statusid = 0 then -actual_stake ELSE winlost-actual_stake+playercomm END) 
		FROM dbo.bettransLC WITH(NOLOCK)
		WHERE IsSum = 0 AND custid = @custid
				
		SELECT 
			@DiffBalance = IsNull(@FromBettrans, 0) + ISNULL(@FromBetRunning, 0) + IsNull(@FromTransfer, 0) - IsNull(@FromTransLog, 0) + IsNull(@FromBettransRNG, 0) + IsNull(@FromBettransLC, 0) - IsNull(@FromAdjustmentTransfer, 0)
			- (cd1.Balance + cd2.Balance + cd3.Balance + cd4.Balance - db1.Balance - db2.Balance - db3.Balance - db4.Balance)
		FROM 
			dbo.BalCreditTransfer cd1 WITH (ROWLOCK)
			INNER JOIN dbo.BalCreditSports cd2 WITH (ROWLOCK) ON cd1.custid = cd2.custid
			INNER JOIN dbo.BalCreditCasino cd3 WITH (ROWLOCK) ON cd1.custid = cd3.custid
			INNER JOIN dbo.BalCreditOthers cd4 WITH (ROWLOCK) ON cd1.custid = cd4.custid
			INNER JOIN dbo.BalDebitTransfer db1 WITH (ROWLOCK) ON cd1.custid = db1.custid
			INNER JOIN dbo.BalDebitSports db2 WITH (ROWLOCK) ON cd1.custid = db2.custid
			INNER JOIN dbo.BalDebitCasino db3 WITH (ROWLOCK) ON cd1.custid = db3.custid
			INNER JOIN dbo.BalDebitOthers db4 WITH (ROWLOCK) ON cd1.custid = db4.custid	
		WHERE cd1.custid = @custid
		
		IF @DiffBalanceInput IS NOT NULL AND ISNULL(@DiffBalance, 0) <> ISNULL(@DiffBalanceInput, 0)
		BEGIN
			SET @result = 300 -->>balance amnt has changed
			RETURN
		END

		--
		-- Take Action accordingly --> dont auto correct data
		--
		--IF @DiffBalance > 0
		--	INSERT INTO dbo.BalCreditSportsPending (custid, Balance) VALUES (@custid, @DiffBalance)
		--ELSE IF @DiffBalance < 0
		--	INSERT INTO dbo.BalDebitSportsPending  (custid, Balance) VALUES (@custid,-@DiffBalance)
			
		SET @result = 0
		SELECT @IsUUS = CASE WHEN Currency = 20 THEN 1 ELSE 0 END
			FROM custdb.dbo.custInfo WITH (NOLOCK)
			WHERE custid = @custid
	END
END
GO


