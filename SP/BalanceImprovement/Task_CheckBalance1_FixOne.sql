USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Task_CheckBalance1_FixOne]    Script Date: 10/07/2015 03:19:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_CheckBalance1_FixOne]
	@custid int,
	@DiffBalance money OUTPUT,
	@result int OUTPUT
AS
/*
	Task: Correct member balance (balance tables) for one given account
	Original: Task_CheckBalance_FixOne
	Location: DBTXN.bodb02

	Revision:
	   20150907@Daniel: Clone from Task_CheckBalance_FixOne & apply new set of bal tables

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
			@FromTransLog money

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
		SELECT @FromBettrans = SUM(winlost-actual_stake+playercomm)	FROM dbo.bettrans with (rowlock) WHERE custid = @custid
		SELECT @FromTransLog = SUM(actual_stake)	FROM dbo.translog with (rowlock) WHERE custid = @custid and statusID = 0
		
		SELECT 
			@DiffBalance = IsNull(@FromBettrans, 0) - IsNull(@FromTransLog, 0) 
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
		
		--
		-- Take Action accordingly
		--
		IF @DiffBalance > 0
			INSERT INTO dbo.BalCreditSportsPending (custid, Balance) VALUES (@custid, @DiffBalance)
		ELSE IF @DiffBalance < 0
			INSERT INTO dbo.BalDebitSportsPending  (custid, Balance) VALUES (@custid,-@DiffBalance)
			
		SET @result = 0
	END
END
