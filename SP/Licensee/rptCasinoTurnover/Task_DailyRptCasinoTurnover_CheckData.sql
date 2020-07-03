/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_DailyRptCasinoTurnover_CheckData] @WinlostDate SMALLDATETIME
AS
/*
	Created: 20181129@Joseph
	Task : Check & correct data for rptCustomerTurnover
	DB: DBLIC.bodb_LicenseeReport
	Revisions:
	- 20181129@Joseph: Create [Redmine: #95178]
	- 20200423@Hogan: Add new product Sexy Gaming [RedmineID: #132829]
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @S_Winlost MONEY, @T_Winlost MONEY, @S_Turnover MONEY, @T_Turnover MONEY, @S_BetCount INT, @T_BetCount INT,
			@S_ValidBetAmount MONEY, @T_ValidBetAmount MONEY
	
SELECT @S_Winlost = SUM(ISNULL(winlost,0))
		, @S_Turnover = SUM(ISNULL(turnover,0))
		, @S_BetCount = COUNT(ISNULL(betcount,0))
		, @S_ValidBetAmount = SUM(ISNULL(validbetamount,0))
	FROM (
		-- RNG and Macau Games
		SELECT SUM(b.winlost - b.actual_stake) as winlost
		, SUM(b.stake) as turnover
		, COUNT(b.TransId) as betcount
		, SUM(b.stake) as validbetamount
		FROM bodb02.dbo.bettransRng14 b WITH(NOLOCK)
			INNER JOIN bodb02.dbo.SportBettypeMatrix matrix WITH(NOLOCK) ON b.gameid = matrix.bettype
		WHERE b.winlostdate = @WinlostDate
			AND b.statusID IN (111,112,113) -- DRAW, WON, LOSE
			AND matrix.ProductID IN (6, 22) -- RNG Casino, Macau Games

		UNION ALL

		-- AllBet
		SELECT SUM(b.winlost - b.actual_stake) as winlost
			, SUM(b.stake) as turnover
			, COUNT(b.TransId) as betcount
			, SUM(b.stake) as validbetamount
		FROM bodb02.dbo.bettransLC14 b WITH(NOLOCK)
			INNER JOIN bodb02.dbo.SportBettypeMatrix matrix WITH(NOLOCK) ON b.gameid = matrix.bettype
		WHERE b.winlostdate = @WinlostDate
			AND b.statusID IN (111,112,113) -- DRAW, WON, LOSE
			AND matrix.ProductID IN (21,45) -- All bet, Sexy Gaming
	) t
	OPTION (RECOMPILE)

	SELECT @T_Winlost = SUM(winlost)
		, @T_Turnover = SUM(turnover)
		, @T_BetCount = SUM(BetCount)
		, @T_ValidBetAmount = SUM(ValidBetAmount)
	FROM dbo.rptCasinoTurnover b WITH(NOLOCK)
	WHERE b.winlostdate = @WinlostDate
		AND b.statusID IN (111,112,113) -- DRAW, WON, LOSE
		AND b.ProductID IN (6, 22, 21) -- RNG Casino, Macau Games, All Bet

	-- compare 
	IF ISNULL(@S_Winlost, 0) <> ISNULL(@T_Winlost, 0)
		OR ISNULL(@S_Turnover, 0) <> ISNULL(@T_Turnover, 0)
		OR ISNULL(@S_BetCount, 0) <> ISNULL(@T_BetCount, 0)
		OR ISNULL(@S_ValidBetAmount, 0) <> ISNULL(@T_ValidBetAmount, 0)
		
	BEGIN
		PRINT 'Re-generate data for rptCasinoTurnover on ' + CONVERT(VARCHAR(10), @WinlostDate, 112) + ' date.'
				EXEC dbo.Task_DailyRptCasinoTurnover_Bettrans14 @winlostdate = @WinlostDate
		RETURN
	END

END
GO