/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Task_DailyRptCasinoTurnover_Bettrans]
	@WinLostDate DATETIME
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
	WHERE ProductID IN (6, 22, 55, 32, 42, 21, 45, 39, 59)

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
				WHEN matrix.bettype IN (4300, 4299, 4298, 4297)
					THEN 1
				ELSE 0 END AS TicketType
		FROM
			bodb02.dbo.bettransRnG bettrans WITH (NOLOCK)
			INNER JOIN @SportBetTypeMatrix matrix ON bettrans.gameid = matrix.bettype
			INNER JOIN bodb02.dbo.Products p WITH(NOLOCK) ON p.ProductID = matrix.productId
			INNER JOIN bodb_licensee.dbo.product3rd p3rd WITH (NOLOCK) ON p.ProductPrefix = p3rd.ProductPrefix
		WHERE
			bettrans.winlostdate = @winlostdate AND
			bettrans.statusID IN (111, 112, 113) AND -- DRAW, WON, LOSE
			matrix.ProductID IN (6, 22, 55, 32, 42) -- RNG Casino, Macau Games, PG Soft, PP, Saba.club
		GROUP BY
			bettrans.custid
			,bettrans.recommend
			,p3rd.ProductID
			,bettrans.statusID
			,bettrans.currency
			,CASE
				WHEN (bettrans.productId = 150 AND matrix.ProductID = 42) -- Saba.club Free Bets
					THEN 1
				WHEN matrix.bettype IN (4300, 4299, 4298, 4297)
					THEN 1
				ELSE 0 END

		UNION ALL

		-- All Bet, Sexy Gaming, SA Gaming
		SELECT
			@winlostdate
			,bettrans.custid
			,bettrans.recommend
			,p3rd.ProductID
			,bettrans.statusID
			,bettrans.currency
			,COUNT(bettrans.transid) AS BetCount
			,SUM(bettrans.stake) AS Turnover
			,SUM(bettrans.winlost-bettrans.actual_stake) AS winlost
			,SUM(bettrans.netstake) AS ValidBetAmount 
			,CASE
				WHEN matrix.bettype IN (3007)
					THEN 1
				ELSE 0 END AS TicketType
		FROM
			bodb02.dbo.bettransLC bettrans WITH (NOLOCK)
			INNER JOIN @SportBetTypeMatrix matrix ON bettrans.gameid = matrix.bettype
			INNER JOIN bodb02.dbo.Products p WITH(NOLOCK) ON p.ProductID = matrix.productId
			INNER JOIN bodb_licensee.dbo.product3rd p3rd WITH (NOLOCK) ON p.ProductPrefix = p3rd.ProductPrefix
		WHERE
			bettrans.winlostdate = @winlostdate AND
			bettrans.statusID IN (111, 112, 113) AND -- DRAW, WON, LOSE
			matrix.ProductID IN (21, 45, 39, 59) -- AllBet, Sexy Gaming, SA Gaming, GDG
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
