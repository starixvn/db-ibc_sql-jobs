/*<info serverAlias="DBLIC-bodb_LicenseeReport,DBBAL-bodb_LicenseeReport" executers="" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Task_DailyRptCasinoTurnover_Bettrans14]
	@WinLostDate SMALLDATETIME
AS

/*
	Created: 20181129@Joseph
	Task: daily summary for casino turnover
	DB: DBLIC.bodb_LicenseeReport

	Revisions:
		- 20181129@Joseph: Create [Redmine: #95178]
		- 20200423@Hogan: Add new product Sexy Gaming [RedmineID: #132829]
		- 20200615@Hogan: Integrate SA Gaming [RedmineID: #128493]
		- 20201201@Mark: Casino Turnover Report - Support Saba.club, PP and PG Soft products [RedmineID: #146135]
		- 20201223@Kos: Fix duplicate Saba.club data [RedmineID: #146135]
		- 20201224@Hogan: Integrate GDG [RedmineID: #147267]
		- 20210119@Hogan: Integrate Four Guardians [RedmineID: #148100]
		- 20210322@Hogan: Integrate AE Casino Lucky Draw [RedmineID: #151984]
		- 20210416@Hogan: Integrate Habanero RNG Games [RedmineID: #150843]
		- 20210428@Hogan: Integrate WM Live Casino [RedmineID: #140944]
		- 20210519@Louis: Integrate Big Gaming product [RedmineID: #146773]
		- 20210525@Hogan: Integrate Vgaming [RedmineID: #151583]
		- 20210630@Hogan: Integrate Creative Gaming [RedmineID: #152619]
		- 20210816@Sophia: add DBBAL [Redmine: #154300]
		- 20211105@Hogan: Integrate AdvantPlay RNG & Mini [RedmineID: #158186]
		- 20220315@Kos: Revise net turnover [RedmineID: #169843]
		- 20230606@Evan: Inteagrate SG promotion prize [RedmineID: #189369]
*/

BEGIN
	SET NOCOUNT ON

	DELETE FROM dbo.rptCasinoTurnover WITH (ROWLOCK) WHERE WinlostDate = @WinLostDate

	DECLARE @SportBetTypeMatrix TABLE (ProductId TINYINT, BetType SMALLINT, RefTable TINYINT)

	INSERT INTO @SportBetTypeMatrix
	SELECT DISTINCT
		ProductId,
		BetType,
		RefTable
	FROM bodb02.dbo.SportBettypeMatrix WITH (NOLOCK)
	WHERE RefTable IN (1, 2) AND ProductID NOT IN (11, 17)

	INSERT INTO dbo.rptCasinoTurnover(
		WinlostDate,
		CustId,
		Recommend,
		ProductId,
		StatusId,
		Currency,
		BetCount,
		Turnover,
		Winlost,
		ValidBetAmount,
		TicketType )
	(
		-- bettransRnG14
		SELECT
			@WinLostDate,
			b.custid,
			b.recommend,
			p3rd.Productid,
			b.statusID,
			b.currency,
			COUNT(b.transid) AS BetCount,
			SUM(b.stake) AS Turnover,
			SUM(b.winlost - b.actual_stake) AS WinLost,
			SUM(b.BetStake) AS ValidBetAmount,
			CASE
				WHEN b.productId = 150 AND sbt.ProductID = 42 THEN 1	-- Saba.club Free Bets
				WHEN b.productId = 173 AND sbt.ProductID = 66 THEN 1	-- Vgaming Free Bets
				WHEN sbt.bettype IN (4300, 4299, 4298, 4297, 1698, 1699, 3150, 3898, 3899, 1906, 4598, 4599, 4600) THEN 1
				ELSE 0
			END AS TicketType
 		FROM
			bodb02.dbo.bettransRnG14 AS b WITH (NOLOCK)
			INNER JOIN @SportBetTypeMatrix AS sbt ON sbt.BetType = b.gameID
			INNER JOIN bodb02.dbo.Products AS p WITH (NOLOCK) ON p.ProductID = sbt.ProductId
			INNER JOIN bodb_licensee.dbo.Product3rd AS p3rd WITH (NOLOCK) ON p3rd.ProductPrefix = p.ProductPrefix
		WHERE
			b.winlostdate = @WinLostDate
			AND b.statusID IN (111, 112, 113)
			AND sbt.RefTable = 1
		GROUP BY
			b.custid,
			b.recommend,
			p3rd.ProductID,
			b.statusID,
			b.currency,
			CASE
				WHEN b.productId = 150 AND sbt.ProductID = 42 THEN 1	-- Saba.club Free Bets
				WHEN b.productId = 173 AND sbt.ProductID = 66 THEN 1	-- Vgaming Free Bets
				WHEN sbt.bettype IN (4300, 4299, 4298, 4297, 1698, 1699, 3150, 3898, 3899, 1906, 4598, 4599, 4600) THEN 1
				ELSE 0
			END

		UNION ALL

		-- bettransLC
		SELECT
			@WinLostDate,
			b.custid,
			b.recommend,
			p3rd.Productid,
			b.statusID,
			b.currency,
			COUNT(b.transid) AS BetCount,
			SUM(b.stake) AS Turnover,
			SUM(b.winlost - b.actual_stake) AS WinLost,
			SUM(ISNULL(b.NetStake, 0)) AS ValidBetAmount,
			CASE
				WHEN sbt.bettype IN (3007, 2499) THEN 1
				ELSE 0
			END AS TicketType
		FROM
			bodb02.dbo.bettransLC14 AS b WITH (NOLOCK)
			INNER JOIN @SportBetTypeMatrix AS sbt ON sbt.BetType = b.gameID
			INNER JOIN bodb02.dbo.Products AS p WITH(NOLOCK) ON p.ProductID = sbt.ProductId
			INNER JOIN bodb_licensee.dbo.Product3rd AS p3rd WITH (NOLOCK) ON p3rd.ProductPrefix = p.ProductPrefix
		WHERE
			b.winlostdate = @WinLostDate
			AND b.statusID IN (111, 112, 113)
			AND sbt.RefTable = 2
		GROUP BY
			b.custid,
			b.recommend,
			p3rd.Productid,
			b.statusID,
			b.currency,
			CASE
				WHEN sbt.bettype IN (3007, 2499) THEN 1
				ELSE 0
			END
	)
END
GO
