/*<info serverAlias="DBLIC-bodb_LicenseeReport,DBBAL-bodb_LicenseeReport" executers="" viewers="" isFunction="0" isNested="0"></info>*/

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
		- 20210416@Hogan: Integrate Habanero RNG Games [RedmineID: #150843]
		- 20210428@Hogan: Integrate WM Live Casino [RedmineID: #140944]
		- 20210519@Louis: Integrate Big Gaming product [RedmineID: #146773]
		- 20210525@Hogan: Integrate Vgaming [RedmineID: #151583]
		- 20210630@Hogan: Integrate Creative Gaming [RedmineID: #152619]
		- 20210816@Sophia: add DBBAL [Redmine: #154300]
		- 20211105@Hogan: Integrate AdvantPlay RNG & Mini [RedmineID: #158186]
		- 20220315@Kos: Revise net turnover [RedmineID: #169843]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @SportBetTypeMatrix TABLE (ProductId TINYINT, BetType SMALLINT, RefTable TINYINT)

	INSERT INTO @SportBetTypeMatrix
	SELECT DISTINCT
		ProductId,
		BetType,
		RefTable
	FROM bodb02.dbo.SportBettypeMatrix WITH (NOLOCK)
	WHERE RefTable IN (1, 2) AND ProductID NOT IN (11, 17)

	DECLARE
		@S_WinLost			MONEY,
		@T_WinLost			MONEY,
		@S_Turnover			MONEY,
		@T_Turnover			MONEY,
		@S_BetCount			INT,
		@T_BetCount			INT,
		@S_ValidBetAmount	MONEY,
		@T_ValidBetAmount	MONEY

	SELECT
		@S_WinLost = SUM(ISNULL(t.WinLost, 0)),
		@S_Turnover = SUM(ISNULL(t.Turnover, 0)),
		@S_BetCount = SUM(ISNULL(t.BetCount, 0)),
		@S_ValidBetAmount = SUM(ISNULL(t.ValidBetAmount, 0))
	FROM (
		-- bettransRnG
		SELECT
			SUM(b.winlost - b.actual_stake) AS WinLost,
			SUM(b.stake) AS Turnover,
			COUNT(b.transid) AS BetCount,
			SUM(b.BetStake) AS ValidBetAmount
		FROM bodb02.dbo.bettransRnG14 AS b WITH (NOLOCK)
			INNER JOIN @SportBetTypeMatrix AS s ON b.gameID = s.BetType
		WHERE b.winlostdate = @WinLostDate
			AND b.statusID IN (111, 112, 113)
			AND s.RefTable = 1

		UNION ALL

		-- bettransLC
		SELECT
			SUM(b.winlost - b.actual_stake) AS WinLost,
			SUM(b.stake) AS Turnover,
			COUNT(b.transid) AS BetCount,
			SUM(b.NetStake) AS ValidBetAmount
		FROM bodb02.dbo.bettransLC14 AS b WITH (NOLOCK)
			INNER JOIN @SportBetTypeMatrix AS s ON b.gameID = s.BetType
		WHERE b.winlostdate = @WinLostDate
			AND b.statusID IN (111, 112, 113)
			AND s.RefTable = 2
	) t
	OPTION (RECOMPILE)

	SELECT
		@T_Winlost = SUM(b.Winlost),
		@T_Turnover = SUM(b.Turnover),
		@T_BetCount = SUM(b.BetCount),
		@T_ValidBetAmount = SUM(b.ValidBetAmount)
	FROM dbo.rptCasinoTurnover AS b WITH (NOLOCK)
		INNER JOIN bodb_licensee.dbo.Product3rd AS p3rd WITH (NOLOCK) ON p3rd.Productid = b.ProductId
		INNER JOIN bodb02.dbo.Products AS p WITH (NOLOCK) ON p.ProductPrefix = p3rd.ProductPrefix
		INNER JOIN @SportBetTypeMatrix AS sbt ON sbt.ProductId = p.ProductID
	WHERE WinlostDate = @WinLostDate AND StatusId IN (111, 112, 113)

	-- compare
	IF ISNULL(@S_WinLost, 0) <> ISNULL(@T_WinLost, 0)
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
