/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Task_DailyRptCasinoTurnover_CheckData]
	@WinLostDate SMALLDATETIME
AS

/*
	Created: 20181129@Joseph
	Task: Check & correct data for rptCustomerTurnover
	DB: DBLIC.bodb_LicenseeReport

	Revisions:
		- 20181129@Joseph: Create [Redmine: #95178]
		- 20200423@Hogan: Add new product Sexy Gaming [RedmineID: #132829]
		- 20200707@Kos: Fix NetStake [RedmineID: #137111]
		- 20200728@Hogan: Integrate SA Gaming [RedmineID: #128493]
		- 20201201@Mark: Casino Turnover Report - Support Saba.club, PP and PG Soft products [RedmineID: #146135]
		- 20201223@Kos: Fix duplicate Saba.club data [RedmineID: #146135]
		- 20201224@Hogan: Integrate GDG [RedmineID: #147267]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @SportBetTypeMatrix TABLE (
		ProductId	TINYINT,
		BetType		SMALLINT )

	INSERT INTO @SportBetTypeMatrix
	SELECT DISTINCT
		ProductId,
		BetType
	FROM bodb02.dbo.SportBettypeMatrix WITH (NOLOCK)
	WHERE ProductID IN (6, 22, 55, 32, 42, 21, 45, 39, 59)

	DECLARE
		@S_Winlost			MONEY,
		@T_Winlost			MONEY,
		@S_Turnover			MONEY,
		@T_Turnover			MONEY,
		@S_BetCount			INT,
		@T_BetCount			INT,
		@S_ValidBetAmount	MONEY,
		@T_ValidBetAmount	MONEY

	SELECT @S_Winlost = SUM(ISNULL(Winlost, 0))
		, @S_Turnover = SUM(ISNULL(Turnover, 0))
		, @S_BetCount = SUM(ISNULL(BetCount, 0))
		, @S_ValidBetAmount = SUM(ISNULL(ValidBetAmount, 0))
	FROM (
		-- RNG Casino, Macau Games, PG Soft, PP, Saba.club
		SELECT SUM(b.winlost - b.actual_stake) AS Winlost
			, SUM(b.stake) AS Turnover
			, COUNT(b.transid) AS BetCount
			, SUM(b.stake) AS ValidBetAmount
		FROM bodb02.dbo.bettransRnG14 AS b WITH (NOLOCK)
			INNER JOIN @SportBetTypeMatrix AS s ON b.gameID = s.BetType
		WHERE b.winlostdate = @WinLostDate
			AND b.statusID IN (111, 112, 113)
			AND s.ProductID IN (6, 22, 55, 32, 42) -- RNG Casino, Macau Games, PG Soft, PP, Saba.club

		UNION ALL

		-- AllBet, Sexy Gaming, SA Gaming, GDG
		SELECT SUM(b.winlost - b.actual_stake) AS Winlost
			, SUM(b.stake) AS Turnover
			, COUNT(b.transid) AS BetCount
			, SUM(b.netstake) AS ValidBetAmount
		FROM bodb02.dbo.bettransLC14 AS b WITH (NOLOCK)
			INNER JOIN @SportBetTypeMatrix AS s ON b.gameID = s.BetType
		WHERE b.winlostdate = @WinLostDate
			AND b.statusID IN (111, 112, 113)
			AND s.ProductID IN (21, 45, 39, 59) -- All bet, Sexy Gaming, SA Gaming, GDG
	) t
	OPTION (RECOMPILE)

	SELECT @T_Winlost = SUM(Winlost)
		, @T_Turnover = SUM(Turnover)
		, @T_BetCount = SUM(BetCount)
		, @T_ValidBetAmount = SUM(ValidBetAmount)
	FROM dbo.rptCasinoTurnover WITH (NOLOCK)
	WHERE WinlostDate = @WinLostDate
		AND StatusId IN (111, 112, 113)
		AND ProductID IN (6, 22, 21, 45, 39, 55, 32, 42, 59) -- RNG Casino, Macau Games, All Bet, SA Gaming, PG Soft, PP, Saba.club

	-- compare 
	IF ISNULL(@S_Winlost, 0) <> ISNULL(@T_Winlost, 0)
		OR ISNULL(@S_Turnover, 0) <> ISNULL(@T_Turnover, 0)
		OR ISNULL(@S_BetCount, 0) <> ISNULL(@T_BetCount, 0)
		OR ISNULL(@S_ValidBetAmount, 0) <> ISNULL(@T_ValidBetAmount, 0)
	BEGIN
		PRINT 'Re-generate data for rptCasinoTurnover on ' + CONVERT(VARCHAR(10), @WinLostDate, 112) + ' date.'

		EXEC dbo.Task_DailyRptCasinoTurnover_Bettrans14 @WinLostDate = @WinLostDate

		RETURN
	END
END
GO
