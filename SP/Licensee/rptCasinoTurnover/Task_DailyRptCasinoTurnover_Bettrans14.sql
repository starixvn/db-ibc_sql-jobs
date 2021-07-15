/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Task_DailyRptCasinoTurnover_Bettrans14]
	@winlostdate DATETIME
AS

/*
	Created:20181129@Joseph
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
*/

BEGIN
	SET NOCOUNT ON

	DELETE FROM dbo.rptCasinoTurnover WITH (ROWLOCK) WHERE winlostdate = @winlostdate

	DECLARE @SportBetTypeMatrix TABLE (
		ProductId	TINYINT,
		BetType		SMALLINT )

	INSERT INTO @SportBetTypeMatrix
	SELECT DISTINCT
		ProductId,
		BetType
	FROM bodb02.dbo.SportBettypeMatrix WITH (NOLOCK)
	WHERE ProductID IN (6, 22, 55, 32, 42, 21, 45, 39, 59, 61, 51, 57, 66, 62)

	INSERT INTO dbo.rptCasinoTurnover(
		[WinlostDate]
		,[CustId]
		,[Recommend]
		,[ProductId]
		,[StatusId]
		,[Currency]
		,[BetCount]
		,[Turnover]
		,[Winlost]
		,[ValidBetAmount]
		,[TicketType] )
	(
		-- RNG Casino and Macau Games
		SELECT @winlostdate
			,bettrans.custid
			,bettrans.recommend
			,p3rd.ProductID
			,bettrans.statusID
			,bettrans.currency
			,COUNT(bettrans.transid) AS BetCount
			,SUM(bettrans.stake) AS Turnover
			,SUM(bettrans.winlost-bettrans.actual_stake) AS winlost
			,SUM(bettrans.stake) AS ValidBetAmount
			,CASE
				WHEN (bettrans.productId = 150 AND matrix.ProductID = 42) -- Saba.club Free Bets
					THEN 1
				WHEN (bettrans.productId = 173 AND matrix.ProductID = 66) -- Vgaming Free Bets
					THEN 1
				WHEN matrix.bettype IN (4300, 4299, 4298, 4297, 1698, 1699, 3150, 3898, 3899)
					THEN 1
				ELSE 0 END AS TicketType
 		FROM
			bodb02.dbo.bettransRnG14 bettrans WITH (NOLOCK)
			INNER JOIN @SportBetTypeMatrix matrix ON bettrans.gameid = matrix.bettype
			INNER JOIN bodb02.dbo.Products p WITH(NOLOCK) ON p.ProductID = matrix.productId
			INNER JOIN bodb_licensee.dbo.product3rd p3rd WITH (NOLOCK) ON p.ProductPrefix = p3rd.ProductPrefix
		WHERE
			bettrans.winlostdate = @winlostdate AND
			bettrans.statusID IN (111, 112, 113) AND -- DRAW, WON, LOSE
			matrix.ProductID IN (6, 22, 55, 32, 42, 61, 66, 62) -- RNG Casino, Macau Games, PG Soft, PP, Saba.club, Vgaming, Creative Gaming
		GROUP BY
			bettrans.custid
			,bettrans.recommend
			,p3rd.ProductID
			,bettrans.statusID
			,bettrans.currency
			,CASE
				WHEN (bettrans.productId = 150 AND matrix.ProductID = 42) -- Saba.club Free Bets
					THEN 1
				WHEN (bettrans.productId = 173 AND matrix.ProductID = 66) -- Vgaming Free Bets
					THEN 1
				WHEN matrix.bettype IN (4300, 4299, 4298, 4297, 1698, 1699, 3150, 3898, 3899)
					THEN 1
				ELSE 0 END

		UNION ALL

		-- AllBet, Sexy Gaming, SA Gaming, GDG, WM Live Casino, Big Gaming
		SELECT @winlostdate
			,bettrans.custid
			,bettrans.recommend
			,p3rd.ProductID
			,bettrans.statusID
			,bettrans.currency
			,COUNT(bettrans.transid) AS BetCount
			,SUM(bettrans.stake) AS Turnover
			,SUM(bettrans.winlost-bettrans.actual_stake) AS winlost
			,SUM(ISNULL(bettrans.netstake, 0)) AS ValidBetAmount
			,CASE
				WHEN matrix.bettype IN (3007)
					THEN 1
				ELSE 0 END AS TicketType
		FROM
			bodb02.dbo.bettransLC14 bettrans WITH (NOLOCK)
			INNER JOIN @SportBetTypeMatrix matrix ON bettrans.gameid = matrix.bettype
			INNER JOIN bodb02.dbo.Products p WITH(NOLOCK) ON p.ProductID = matrix.productId
			INNER JOIN bodb_licensee.dbo.product3rd p3rd WITH (NOLOCK) ON p.ProductPrefix = p3rd.ProductPrefix
		WHERE
			bettrans.winlostdate = @winlostdate AND
			bettrans.statusID IN (111, 112, 113) AND -- DRAW, WON, LOSE
			matrix.ProductID IN (21, 45, 39, 59, 51, 57) -- AllBet, Sexy Gaming, SA Gaming, GDG, WM Live Casino, Big Gaming
		GROUP BY
			bettrans.custid
			,bettrans.recommend
			,p3rd.ProductID
			,bettrans.statusID
			,bettrans.currency
			,CASE
				WHEN matrix.bettype IN (3007)
					THEN 1
				ELSE 0 END
	)
END
GO
