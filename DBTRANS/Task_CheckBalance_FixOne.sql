USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Task_CheckBalance_FixOne]    Script Date: 12/07/2015 23:15:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_CheckBalance_FixOne]
	@custid int,
	@DiffBalance money OUTPUT,
	@result int OUTPUT,
	@IsUUS bit = 0 OUTPUT
AS
/*
	Task: Correct member balance (balance tables) for one given account
	Original: Task_CheckBalance_FixOne
	Location: DBTXN.bodb02

	Revision:
		20151210@Daniel: calc balance from table bettransRNG & bettransLC 

	Param use:


	Logic & Process:
		check if member got bet in match being settle (exit if true)
		is there any pending?
			No? compute balance and compare
				if diff : adjust.
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
			@FromTransLog money, @FromBettransRNG money, @FromBettransLC money
			
	--
	-- Skip if Pending Found
	--
	IF	EXISTS (SELECT 1 FROM dbo.BalancePendingCredit with (nolock) WHERE custid = @custid) OR
		EXISTS (SELECT 1 FROM dbo.BalancePendingDebit  with (nolock) WHERE custid = @custid)
	BEGIN
		SET @result = 200
		RETURN
	END
	ELSE
	BEGIN
		--
		-- Get/Compare Balance
		--
		SELECT @FromBettrans = SUM(winlost-actual_stake+playercomm)	FROM dbo.bettrans with (rowlock) WHERE custid = @custid
		SELECT @FromTransLog = SUM(actual_stake)	FROM dbo.translog with (rowlock) WHERE custid = @custid and statusID = 0
		
		SELECT @FromBettransRNG = SUM(CASE WHEN statusid = 0 then -actual_stake ELSE winlost-actual_stake+playercomm END) 
		FROM dbo.bettransRNG WITH(NOLOCK)
		WHERE IsSum = 0 AND custid = @custid
		
		SELECT @FromBettransLC = SUM(CASE WHEN statusid = 0 then -actual_stake ELSE winlost-actual_stake+playercomm END) 
		FROM dbo.bettransLC WITH(NOLOCK)
		WHERE IsSum = 0 AND custid = @custid
		
		SELECT 
			@DiffBalance = IsNull(@FromBettrans, 0) - IsNull(@FromTransLog, 0) + IsNull(@FromBettransRNG, 0) + IsNull(@FromBettransLC, 0) - (cd.Balance - db.Balance)
		FROM dbo.BalanceCredit cd with (rowlock)
			INNER JOIN dbo.BalanceDebit db with (rowlock) ON cd.custid = db.custid
		WHERE
			cd.custid = @custid
			AND db.custid = @custid
	
		--
		-- Take Action accordingly
		--
		IF @DiffBalance > 0
			INSERT INTO dbo.BalancePendingCredit (custid, Balance) VALUES (@custid, @DiffBalance)
		ELSE IF @DiffBalance < 0
			INSERT INTO dbo.BalancePendingDebit  (custid, Balance) VALUES (@custid,-@DiffBalance)

		SET @result = 0
		SELECT @IsUUS = CASE WHEN Currency = 20 THEN 1 ELSE 0 END
			FROM custdb.dbo.custInfo WITH (NOLOCK)
			WHERE custid = @custid
	END
END
