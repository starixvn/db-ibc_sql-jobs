/*<info serverAlias="DBEXT-bodb02" executers="" isFunction="0" isNested="1"></info>*/
USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Task_Aff_ImportData_Bettrans14]
	@WinlostDate SMALLDATETIME
AS

/*
	Created: 20180601@Percy
	DB: DBEXT.bodb02
	Task: Get data on bettrans and bettrans14

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
		- 20190716@Percy: Add bet types of rebate bonus (22202: bonus, 22203: adjustment) [RedmineID: #116778]
*/

BEGIN 
	SET NOCOUNT ON 
	
	-- Agent Info
	BEGIN
		DECLARE @recommend TABLE (recommend INT)

		INSERT INTO @recommend (recommend)
		SELECT DISTINCT recommend FROM Affiliate_12BET.dbo.MemberInfo WITH (NOLOCK)
	END

	-- Get SportBettypeMatrix Info
	BEGIN
		CREATE TABLE #SportBettypeMatrix (ProductId INT, ProductPrefix VARCHAR(10), Bettype INT)
	
		INSERT INTO #SportBettypeMatrix (ProductPrefix, Bettype)
		SELECT DISTINCT p.ProductPrefix, s.BetType
		FROM dbo.Products p WITH (NOLOCK)
			INNER JOIN dbo.SportBettypeMatrix s WITH (NOLOCK) ON p.ProductID = s.ProductID
		WHERE s.BetType NOT IN (912, 913, 914) -- Exclude CashOut (keep 911)

		-- Transfer tickets
		INSERT INTO #SportBettypeMatrix (ProductId, Bettype)
		SELECT bt.ProductId, bt.Bettype
		FROM (
			VALUES
				-- -1: Deposit
				(-1, 22001),
				-- -2: Withdrawal
				(-2, 22002), (-2, 22003),
				-- -3: Bonus
				(-3, 22004), (-3, 22200), (-3, 22202),
				-- -4: Adjustment
				(-4, 21001), (-4, 21002), (-4, 21003), (-4, 21004), (-4, 21005),
				(-4, 22005), (-4, 22201), (-4, 22203)
		) AS bt (ProductId, Bettype)

		UPDATE s
		SET s.ProductId = p.ProductId
		FROM #SportBettypeMatrix s
			INNER JOIN Affiliate_12BET.dbo.Products p WITH (NOLOCK)ON s.ProductPrefix = p.ProductPrefix
		WHERE s.ProductPrefix IS NOT NULL
			AND p.IsIBC = 1

		-- For CashOut
		UPDATE #SportBettypeMatrix
		SET ProductId = 1
		WHERE Bettype = 911

		DELETE #SportBettypeMatrix
		WHERE ProductId IS NULL
	END

	-- Get Data from bettrans
	BEGIN
		-- bet tickets
		SELECT
			a.custid,
			a.currency,
			a.ProductId,
			a.Deposit,
			a.Withdrawal,
			a.Bonus,
			a.Adjustment,
			a.Turnover,
			a.Winloss
		FROM
		(
			SELECT
				b.custid,
				b.currency,
				bt.ProductId,
				0 AS Deposit,
				0 AS Withdrawal,
				0 AS Bonus,
				0 AS Adjustment,
				SUM(CASE WHEN b.bettype <> 911 THEN b.stake ELSE 0 END) AS Turnover,
				SUM(b.winlost-b.actual_stake+b.playercomm) AS Winloss
			FROM dbo.bettrans14 b WITH (NOLOCK)
				INNER JOIN #SportBettypeMatrix bt WITH (NOLOCK) ON b.bettype = bt.Bettype AND bt.ProductId > 0
				CROSS APPLY @recommend r
			WHERE
				b.recommend = r.recommend
				AND b.winlostdate = @WinlostDate
				AND b.statusID NOT IN (0, 1, 101, 102, 103)
			GROUP BY
				b.custid,
				b.currency,
				bt.ProductId

			UNION ALL -- transfer tickets
			SELECT
				b.custid,
				b.currency,
				-1 AS ProductId,
				SUM(CASE WHEN bt.ProductId = -1 THEN b.winlost-b.actual_stake ELSE 0 END) AS Deposit,
				SUM(CASE WHEN bt.ProductId = -2 THEN -(b.winlost-b.actual_stake) ELSE 0 END) AS Withdrawal,
				SUM(CASE WHEN bt.ProductId = -3 THEN b.winlost-b.actual_stake ELSE 0 END) AS Bonus,
				SUM(CASE WHEN bt.ProductId = -4 THEN b.winlost-b.actual_stake ELSE 0 END) AS Adjustment,
				0 AS Turnover,
				0 AS Winloss
			FROM dbo.bettrans b WITH (NOLOCK)
				INNER JOIN #SportBettypeMatrix bt WITH (NOLOCK) ON b.bettype = bt.Bettype AND bt.ProductId < 0
				CROSS APPLY @recommend r
			WHERE
				b.recommend = r.recommend
				AND b.winlostdate = @WinlostDate
				AND b.statusID NOT IN (0, 1, 101, 102, 103)
			GROUP BY
				b.custid,
				b.currency
		) AS a
			INNER JOIN Affiliate_12BET.dbo.MemberInfo mi WITH (NOLOCK) ON mi.IBCCustId = A.custid
	END

	DROP TABLE #SportBettypeMatrix
END
GO