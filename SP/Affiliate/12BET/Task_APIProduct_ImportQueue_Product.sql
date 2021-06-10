/*<info serverAlias="DBAFF12BET-Affiliate_12BET" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_APIProduct_ImportQueue_Product]
	@ProductId		INT,
	@WinlostDate	SMALLDATETIME
AS

/*
	Created: 20181001@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Import Data Job - API Products

	Revisions:
		- 20181001@Percy: Initialize SP [RedmineID: #102322]
		- 20181201@Percy: Integrate new products: 12Crystal - GPI, 12Quartz - iSoftbet, 12Diamond - OPUS [RedmineID: #104892]
		- 20190117@Percy: Divide amount by 100 for Betsoft [RedmineID: #107979]
		- 20190131@Percy: Divide amount by 100 for iSoftbet [RedmineID: #107979]
		- 20190322@Percy: Include more type of iSoftbet [RedmineID: #110638]
		- 20191206@Percy: Integrate new products: 12Topaz, LB Keno, GPI lottery, VR Lottery [RedmineID: #117197]
		- 20200228@Percy: Return if input wrong @ProductId [RedmineID: #129442]
		- 20200707@Percy: Integrate new product: KY Gaming [RedmineID: #131437]
		- 20200827@Percy: Re-Integrate 12Topaz due to API's change [RedmineID: #139043]
		- 20201216@Percy: Integrate new product: BTi [RedmineID: #144456]
		- 20210602@Percy: Change formula of 12Topaz & BTi [RedmineID: #156324]
*/

BEGIN
	SET NOCOUNT ON

	CREATE TABLE #tempData
	(
		AffId		INT,
		IBCCustId	INT,
		Currency	INT,
		Turnover	MONEY,
		Winloss		MONEY
	)

	-- Ebet
	IF @ProductId = 10
	BEGIN
		INSERT INTO #tempData
		(
			AffId,
			IBCCustId,
			Currency,
			Turnover,
			Winloss
		)
		SELECT
			mi.AffId,
			mi.IBCCustId,
			mi.currency,
			SUM(ISNULL(b.Bet, 0)) AS Turnover,
			SUM(ISNULL(b.Payout, 0) - ISNULL(b.Bet, 0)) AS Winloss
		FROM dbo.bettrans_Ebet b WITH (NOLOCK)
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON b.IBCCustId = mi.IBCCustId
		WHERE b.WinlostDate = @WinlostDate
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mr.RemovedDate <= DATEADD(DAY, 1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @WinlostDate) + 1, 0))
					AND mi.IBCCustId = mr.IBCCustId
			)
		GROUP BY
			mi.AffId,
			mi.IBCCustId,
			mi.currency
	END
	-- Betsoft
	ELSE IF @ProductId = 11
	BEGIN
		INSERT INTO #tempData
		(
			AffId,
			IBCCustId,
			Currency,
			Turnover,
			Winloss
		)
		SELECT
			mi.AffId,
			mi.IBCCustId,
			mi.currency,
			SUM(ISNULL(b.Amount, 0) / 100) AS Turnover,
			SUM(ISNULL(b.Win, 0) / 100 - ISNULL(b.Amount, 0) / 100) AS Winloss
		FROM dbo.bettrans_Betsoft b WITH (NOLOCK)
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON b.IBCCustId = mi.IBCCustId
		WHERE b.WinlostDate = @WinlostDate
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mr.RemovedDate <= DATEADD(DAY, 1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @WinlostDate) + 1, 0))
					AND mi.IBCCustId = mr.IBCCustId
			)
		GROUP BY
			mi.AffId,
			mi.IBCCustId,
			mi.currency
	END
	-- Crystal
	ELSE IF @ProductId = 12
	BEGIN
		INSERT INTO #tempData
		(
			AffId,
			IBCCustId,
			Currency,
			Turnover,
			Winloss
		)
		SELECT
			mi.AffId,
			mi.IBCCustId,
			mi.currency,
			SUM(ISNULL(c.bet, 0)) AS Turnover,
			SUM(ISNULL(c.changes, 0)) AS Winloss
		FROM dbo.bettrans_Crystal c WITH (NOLOCK)
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON c.IBCCustId = mi.IBCCustId
		WHERE c.WinlostDate = @WinlostDate
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mr.RemovedDate <= DATEADD(DAY, 1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @WinlostDate) + 1, 0))
					AND mi.IBCCustId = mr.IBCCustId
			)
		GROUP BY
			mi.AffId,
			mi.IBCCustId,
			mi.currency
	END
	-- iSoftbet
	ELSE IF @ProductId = 13
	BEGIN
		INSERT INTO #tempData
		(
			AffId,
			IBCCustId,
			Currency,
			Turnover,
			Winloss
		)
		SELECT
			mi.AffId,
			mi.IBCCustId,
			mi.currency,
			SUM(CASE WHEN i.TYPE LIKE '%BET%' THEN ISNULL(i.Amount, 0)/100 ELSE 0 END) AS Turnover,
			SUM(CASE WHEN i.TYPE LIKE '%BET%' THEN -ISNULL(i.Amount, 0)/100 WHEN i.TYPE LIKE '%WIN%' THEN ISNULL(i.Amount, 0)/100 ELSE 0 END) AS Winloss
		FROM dbo.bettrans_iSoftbet i WITH (NOLOCK)
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON i.IBCCustId = mi.IBCCustId
		WHERE i.WinlostDate = @WinlostDate
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mr.RemovedDate <= DATEADD(DAY, 1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @WinlostDate) + 1, 0))
					AND mi.IBCCustId = mr.IBCCustId
			)
			AND (i.TYPE LIKE '%BET%' OR i.TYPE LIKE '%WIN%')
		GROUP BY
			mi.AffId,
			mi.IBCCustId,
			mi.currency
	END
	-- OPUS
	ELSE IF @ProductId = 14
	BEGIN
		INSERT INTO #tempData
		(
			AffId,
			IBCCustId,
			Currency,
			Turnover,
			Winloss
		)
		SELECT
			mi.AffId,
			mi.IBCCustId,
			mi.currency,
			SUM(ISNULL(o.bet, 0)) AS Turnover,
			SUM(ISNULL(o.win, 0) - ISNULL(o.bet, 0)) AS Winloss
		FROM dbo.bettrans_OPUS o WITH (NOLOCK)
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON o.IBCCustId = mi.IBCCustId
		WHERE o.WinlostDate = @WinlostDate
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mr.RemovedDate <= DATEADD(DAY, 1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @WinlostDate) + 1, 0))
					AND mi.IBCCustId = mr.IBCCustId
			)
		GROUP BY
			mi.AffId,
			mi.IBCCustId,
			mi.currency
	END
	-- GPI Lottery
	ELSE IF @ProductId = 20
	BEGIN
		INSERT INTO #tempData
		(
			AffId,
			IBCCustId,
			Currency,
			Turnover,
			Winloss
		)
		SELECT
			mi.AffId,
			mi.IBCCustId,
			mi.currency,
			SUM(ISNULL(g.betAmount, 0)) AS Turnover,
			SUM(ISNULL(g.winAmount, 0) - ISNULL(g.betAmount, 0)) AS Winloss
		FROM dbo.bettrans_GPILottery g WITH (NOLOCK)
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON g.IBCCustId = mi.IBCCustId
		WHERE g.WinlostDate = @WinlostDate
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mr.RemovedDate <= DATEADD(DAY, 1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @WinlostDate) + 1, 0))
					AND mi.IBCCustId = mr.IBCCustId
			)
			AND g.status = 'Settled'
		GROUP BY
			mi.AffId,
			mi.IBCCustId,
			mi.currency
	END
	-- VR Lottery
	ELSE IF @ProductId = 21
	BEGIN
		INSERT INTO #tempData
		(
			AffId,
			IBCCustId,
			Currency,
			Turnover,
			Winloss
		)
		SELECT
			mi.AffId,
			mi.IBCCustId,
			mi.currency,
			SUM(ISNULL(v.BetAmount, 0)) AS Turnover,
			SUM(ISNULL(v.PlayerWinLoss, 0)) AS Winloss
		FROM dbo.bettrans_VRLottery v WITH (NOLOCK)
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON v.IBCCustId = mi.IBCCustId
		WHERE v.WinlostDate = @WinlostDate
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mr.RemovedDate <= DATEADD(DAY, 1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @WinlostDate) + 1, 0))
					AND mi.IBCCustId = mr.IBCCustId
			)
			AND v.status = 'Settled'
		GROUP BY
			mi.AffId,
			mi.IBCCustId,
			mi.currency
	END
	-- LB Keno
	ELSE IF @ProductId = 22
	BEGIN
		INSERT INTO #tempData
		(
			AffId,
			IBCCustId,
			Currency,
			Turnover,
			Winloss
		)
		SELECT
			mi.AffId,
			mi.IBCCustId,
			mi.currency,
			SUM(ISNULL(l.bet_money, 0)) AS Turnover,
			SUM(ISNULL(l.bet_winning, 0) - ISNULL(l.bet_money, 0)) AS Winloss
		FROM dbo.bettrans_LBKeno l WITH (NOLOCK)
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON l.IBCCustId = mi.IBCCustId
		WHERE l.WinlostDate = @WinlostDate
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mr.RemovedDate <= DATEADD(DAY, 1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @WinlostDate) + 1, 0))
					AND mi.IBCCustId = mr.IBCCustId
			)
			AND l.bet_status = 'Settled'
		GROUP BY
			mi.AffId,
			mi.IBCCustId,
			mi.currency
	END
	-- 12 Topaz
	ELSE IF @ProductId = 23
	BEGIN
		INSERT INTO #tempData
		(
			AffId,
			IBCCustId,
			Currency,
			Turnover,
			Winloss
		)
		SELECT
			mi.AffId,
			mi.IBCCustId,
			mi.currency,
			SUM(t.wager/CASE WHEN mi.Currency IN (15,22,33,34,51) THEN 1000.0 ELSE 1.0 END) AS Turnover, -- IDR, VND amount divide by 1000
			SUM((t.payout - t.wager) /CASE WHEN mi.Currency IN (15,22,33,34,51) THEN 1000.0 ELSE 1.0 END) AS Winloss -- IDR, VND amount divide by 1000
		FROM dbo.bettrans_Topaz2 t WITH (NOLOCK)
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON t.IBCCustId = mi.IBCCustId
		WHERE t.WinlostDate = @WinlostDate
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mr.RemovedDate <= DATEADD(DAY, 1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @WinlostDate) + 1, 0))
					AND mi.IBCCustId = mr.IBCCustId
			)
			AND t.category = 'ENDROUND'
		GROUP BY
			mi.AffId,
			mi.IBCCustId,
			mi.currency
	END
	-- KY Gaming
	ELSE IF @ProductId = 24
	BEGIN
		INSERT INTO #tempData
		(
			AffId,
			IBCCustId,
			Currency,
			Turnover,
			Winloss
		)
		SELECT
			mi.AffId,
			mi.IBCCustId,
			mi.currency,
			SUM(k.CellScore) AS Turnover,
			SUM(CASE WHEN k.Profit < 0 THEN k.Profit ELSE k.Profit - k.CellScore END) AS Winloss
		FROM dbo.bettrans_KYGaming k WITH (NOLOCK)
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON k.IBCCustId = mi.IBCCustId
		WHERE k.WinlostDate = @WinlostDate
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mr.RemovedDate <= DATEADD(DAY, 1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @WinlostDate) + 1, 0))
					AND mi.IBCCustId = mr.IBCCustId
			)
		GROUP BY
			mi.AffId,
			mi.IBCCustId,
			mi.currency
	END
	-- BTi
	ELSE IF @ProductId = 25
	BEGIN
		INSERT INTO #tempData
		(
			AffId,
			IBCCustId,
			Currency,
			Turnover,
			Winloss
		)
		SELECT
			mi.AffId,
			mi.IBCCustId,
			mi.currency,
			SUM(b.ValidStake) AS Turnover,
			SUM(b.PL) AS Winloss
		FROM dbo.bettrans_BTi b WITH (NOLOCK)
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON b.IBCCustId = mi.IBCCustId
		WHERE b.WinlostDate = @WinlostDate
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mr.RemovedDate <= DATEADD(DAY, 1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @WinlostDate) + 1, 0))
					AND mi.IBCCustId = mr.IBCCustId
			)
			AND b.BetStatus IN ('Won', 'Lost', 'Half won', 'Half lost', 'Draw', 'Cashout')
		GROUP BY
			mi.AffId,
			mi.IBCCustId,
			mi.currency
	END
	ELSE
	BEGIN
		-- Prevent input wrong ProductId
		RETURN
	END

	-- Import data
	BEGIN
		;WITH CTE_rptMemberDaily AS
		(
			SELECT IBCCustID, AffId, Currency, AffExRate, ExRate, Bonus, Turnover, Winloss
			FROM dbo.rptMemberDaily WITH (NOLOCK)
			WHERE winlostdate = @WinlostDate AND ProductId = @ProductId
		)
		SELECT
			CASE	WHEN t.IBCCustId IS NULL THEN -1 -- delete
					WHEN r.IBCCustId IS NULL THEN 1 -- insert
					ELSE 0 END AS ModifiedType-- update
			,ISNULL(t.IBCCustId, r.IBCCustId) AS IBCCustId
			,t.AffId, t.Currency, t.AffExRate, t.ExRate, t.Turnover, t.Winloss
		INTO #__Data
		FROM (
			SELECT AffId,IBCCustId,Turnover,Winloss,Currency,e.ActualRate AS ExRate,e.ActualRate2 AS AffExRate
			FROM #tempData d
				CROSS APPLY dbo.Aff_f_ExchangeRateById_Sel(d.Currency, @WinlostDate) e
		) t
			FULL OUTER JOIN CTE_rptMemberDaily r ON t.IBCCustId = r.IBCCustId

		DROP TABLE #tempData

		-- Delete
		IF EXISTS (SELECT 1 FROM #__Data WHERE ModifiedType = -1)
		BEGIN
			DELETE r WITH (ROWLOCK, UPDLOCK)
			FROM dbo.rptMemberDaily r
				INNER JOIN #__Data d ON d.IBCCustId = r.IBCCustId
			WHERE r.WinlostDate = @WinlostDate
				AND r.ProductId = @ProductId
				AND d.ModifiedType = -1

			DELETE #__Data WHERE ModifiedType = -1
		END
				
		-- Insert
		IF EXISTS (SELECT 1 FROM #__Data WHERE ModifiedType = 1)
		BEGIN
			DELETE #__Data
			OUTPUT @WinlostDate WinlostDate,DELETED.AffId,DELETED.IBCCustId,@ProductId ProductId
					,0 Deposit,0 Withdrawal,0 Bonus,0 Adjustment,DELETED.Turnover,DELETED.Winloss
					,DELETED.Currency,DELETED.ExRate,DELETED.AffExRate,0 AWinloss,0 AComm
			INTO dbo.rptMemberDaily(WinlostDate,AffId,IBCCustId,ProductId,Deposit,Withdrawal,Bonus,Adjustment,Turnover,Winloss,Currency,ExRate,AffExRate,AWinloss,AComm)
			WHERE ModifiedType = 1
		END

		-- Update
		IF EXISTS (SELECT 1 FROM #__Data WHERE ModifiedType = 0)
		BEGIN
			UPDATE r WITH (ROWLOCK)
			SET r.AffId = d.AffId
				,r.Deposit = 0
				,r.Withdrawal = 0
				,r.Bonus = 0
				,r.Adjustment = 0
				,r.Turnover = d.Turnover
				,r.Winloss = d.Winloss
				,r.Currency = d.Currency
				,r.ExRate = d.ExRate
				,r.AffExRate = d.AffExRate
				,r.AWinloss = 0
				,r.AComm = 0
			FROM dbo.rptMemberDaily r
				INNER JOIN #__Data d ON d.IBCCustId = r.IBCCustId
			WHERE r.WinlostDate = @WinlostDate
				AND r.ProductId = @ProductId
				AND d.ModifiedType = 0
				AND (
					r.AffId <> d.AffId
					OR r.Turnover <> d.Turnover
					OR r.Winloss <> d.Winloss
					OR r.Currency <> d.Currency
					OR r.ExRate <> d.ExRate
					OR r.AffExRate <> d.AffExRate
				)
		END

		DROP TABLE #__Data
	END
END
GO