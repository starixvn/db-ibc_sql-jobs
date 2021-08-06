/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_Aff_ImportData]
	@WinlostDate SMALLDATETIME
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Job - Import data

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
		- 20201216@Percy: Auto add Platform Fee's setting [RedmineID: #146661]
		- 20210628@Percy: Get Rebate amount [RedmineID: #157591]
		- 20210714@Percy: Get Revenue amount [RedmineID: #157958]
		- 20210805@Percy: Include free spin into P2P Products [RedmineID: #157958]
*/

BEGIN 
	SET NOCOUNT ON

	DECLARE @MonthDate DATETIME
	SELECT  @MonthDate = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @WinlostDate) + 1, 0))

	DECLARE @TimeZone SMALLINT
	SELECT  @TimeZone = CONVERT(SMALLINT, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'TimeZone'

	-- Update product list
	BEGIN
		DECLARE @Products TABLE (ProductId INT, RefProductId INT, IsP2P BIT)
		
		BEGIN TRY
			INSERT INTO dbo.Products (ProductId,ProductName,ProductPrefix,IsIBC,Enabled,IsTest,ReleasedDate,RefProductId,DataSource)
			SELECT g.Type, g.TypeName, '', 0, 1, 0, CONVERT(DATE, GETDATE()), g.Type, 'TpBetRecord'
			FROM bodb_N88.dbo.TpGameType g WITH (NOLOCK)
				LEFT JOIN dbo.Products p WITH (NOLOCK) ON g.Type = p.RefProductId
			WHERE p.RefProductId IS NULL

			INSERT INTO @Products (ProductId, IsP2P)
			SELECT p.ProductId, p.IsP2P
			FROM dbo.Products p WITH (NOLOCK)
				CROSS JOIN (SELECT GroupId FROM dbo.CommGroup WITH (NOLOCK) WHERE IsDeleted = 0) g
				LEFT JOIN (
					SELECT DISTINCT GroupId, ProductId FROM dbo.DeductionSetting WITH (NOLOCK) WHERE ProductId > 0
					UNION ALL SELECT DISTINCT GroupId, ProductId FROM dbo.StraightSetting WITH (NOLOCK) WHERE ProductId > 0
			) s ON g.GroupId = s.GroupId AND p.ProductId = s.ProductId
			WHERE s.GroupId IS NULL

			IF EXISTS (SELECT 1 FROM @Products WHERE IsP2P = 0)
			BEGIN
				INSERT INTO dbo.DeductionSetting (GroupId, DeductionId, ProductId, GroupProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent)
				SELECT s.GroupId, s.DeductionId, p.ProductId, s.GroupProductId, s.DeductedPercentage, s.DeductedAmount, s.IsDeductedPercent
				FROM (
					SELECT GroupId, DeductionId, GroupProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent
						,ROW_NUMBER() OVER(PARTITION BY GroupId ORDER BY GroupProductId) AS RN
					FROM dbo.DeductionSetting WITH (NOLOCK)
					WHERE DeductionId = 10
				) s
					CROSS JOIN (SELECT ProductId FROM @Products WHERE IsP2P = 0) p
					LEFT JOIN dbo.DeductionSetting ds WITH (NOLOCK) ON s.GroupId = ds.GroupId AND s.DeductionId = ds.DeductionId AND p.ProductId = ds.ProductId
				WHERE s.RN = 1 AND ds.GroupId IS NULL

				INSERT INTO dbo.DeductionSettingHistory (GroupId, MonthDate, DeductionId, ProductId, GroupProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent)
				SELECT ds.GroupId, @MonthDate, ds.DeductionId, ds.ProductId, ds.GroupProductId, ds.DeductedPercentage, ds.DeductedAmount, ds.IsDeductedPercent
				FROM dbo.DeductionSetting ds WITH (NOLOCK)
					LEFT JOIN dbo.DeductionSettingHistory dsh WITH (NOLOCK) ON ds.GroupId = dsh.GroupId AND ds.DeductionId = dsh.DeductionId AND ds.ProductId = dsh.ProductId AND dsh.MonthDate = @MonthDate
				WHERE dsh.GroupId IS NULL
			END
			
			IF EXISTS (SELECT 1 FROM @Products WHERE IsP2P = 1)
			BEGIN
				INSERT INTO dbo.StraightSetting (GroupId, ProductId, GroupProductId, DeductedPercentage, Commission)
				SELECT s.GroupId, p.ProductId, s.GroupProductId, s.DeductedPercentage, s.Commission
				FROM (
					SELECT GroupId, GroupProductId, DeductedPercentage, Commission
						,ROW_NUMBER() OVER(PARTITION BY GroupId ORDER BY GroupProductId) AS RN
					FROM dbo.StraightSetting WITH (NOLOCK)
				) s
					CROSS JOIN (SELECT ProductId FROM @Products WHERE IsP2P = 1) p
					LEFT JOIN dbo.StraightSetting ss WITH (NOLOCK) ON s.GroupId = ss.GroupId AND p.ProductId = ss.ProductId
				WHERE s.RN = 1 AND ss.GroupId IS NULL

				INSERT INTO dbo.StraightSettingHistory (GroupId, MonthDate, ProductId, GroupProductId, DeductedPercentage, Commission)
				SELECT ss.GroupId, @MonthDate, ss.ProductId, ss.GroupProductId, ss.DeductedPercentage, ss.Commission
				FROM dbo.StraightSetting ss WITH (NOLOCK)
					LEFT JOIN dbo.StraightSettingHistory ssh WITH (NOLOCK) ON ss.GroupId = ssh.GroupId AND ss.ProductId = ssh.ProductId AND ssh.MonthDate = @MonthDate
				WHERE ssh.GroupId IS NULL
			END
		END TRY
		BEGIN CATCH
			PRINT 'Invalid import new product!'
		END CATCH
	END

	-- Get data
	BEGIN
		DELETE @Products

		-- WinLoss data
		INSERT INTO @Products (ProductId, RefProductId, IsP2P)
		SELECT ProductId, RefProductId, IsP2P
		FROM dbo.Products p WITH (NOLOCK)
		WHERE IsIBC = 0
			AND DataSource = 'TpBetRecord'

		-- Others (Deposit, Withdrawal, Bonus, Rebate, ...)
		INSERT INTO @Products (ProductId, RefProductId, IsP2P)
		VALUES (-1, -1, 0)

		CREATE TABLE #rptMemberDaily
		(
			CustId			INT
			,Currency		INT
			,AffId			INT
			,ProductId		INT
			,Deposit		MONEY DEFAULT (0)
			,Withdrawal		MONEY DEFAULT (0)
			,Bonus			MONEY DEFAULT (0)
			,Rebate			MONEY DEFAULT (0)
			,Adjustment		MONEY DEFAULT (0)
			,Turnover		MONEY DEFAULT (0)
			,Winloss		MONEY DEFAULT (0)
			,Revenue		MONEY DEFAULT (0)
			,AffExRate		FLOAT
		)

		-- Bet tickets
		INSERT INTO #rptMemberDaily
		(
			CustId
			,Currency
			,AffId
			,ProductId
			,Turnover
			,Winloss
			,Revenue
			,AffExRate
		)
		SELECT
			mi.CustId
			,mi.Currency
			,mi.AffId
			,p.ProductId
			,SUM(b.Stake * 1.0 / CASE WHEN e.Code IN ('VND', 'IDR') THEN 1000.0 ELSE 1.0 END)			AS Turnover
			,SUM(b.WinlostAmount * 1.0 / CASE WHEN e.Code IN ('VND', 'IDR') THEN 1000.0 ELSE 1.0 END)	AS Winloss
			,SUM(b.Revenue * 1.0 / CASE WHEN e.Code IN ('VND', 'IDR') THEN 1000.0 ELSE 1.0 END)			AS Revenue
			,e.Rate
		FROM bodb_N88.dbo.TpBetRecord b WITH (NOLOCK)
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON b.CustId = mi.CustId
			INNER JOIN @Products p ON b.GameType = p.RefProductId
			CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(@WinlostDate, mi.currency, 0) e
		WHERE b.WinlostDate BETWEEN DATEADD(DAY, -1, @WinlostDate) AND DATEADD(DAY, 1, @WinlostDate)
			AND b.TicketStatus IN (1, 2, 4, 6) -- Won/Lose/Draw/Free Spin
			AND (
				p.IsP2P = 1
				OR (p.IsP2P = 0 AND b.TicketStatus <> 6)
			)
			AND CONVERT(DATE, DATEADD(HOUR, @TimeZone, b.SettledTime)) = @WinlostDate
		GROUP BY
			mi.CustId
			,mi.Currency
			,mi.AffId
			,p.ProductId
			,e.Rate

		-- Deposit, Withdrawal, Bonus, Rebate
		INSERT INTO #rptMemberDaily
		(
			CustId
			,Currency
			,AffId
			,ProductId
			,Deposit
			,Withdrawal
			,Bonus
			,Rebate
			,AffExRate
		)
		SELECT
			CustId
			,Currency
			,AffId
			,-1 AS ProductId
			,SUM(Deposit)
			,SUM(Withdrawal)
			,SUM(Bonus)
			,SUM(Rebate)
			,Rate
		FROM
		(
			SELECT
				mi.CustId
				,mi.Currency
				,mi.AffId
				,SUM(d.Amount * 1.0 / CASE WHEN e.Code IN ('VND', 'IDR') THEN 1000.0 ELSE 1.0 END) AS Deposit
				,0 AS Withdrawal
				,0 AS Bonus
				,0 AS Rebate
				,e.Rate
			FROM bodb_N88.dbo.DepositInfo d WITH (NOLOCK)
				INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON d.CustId = mi.CustId
				CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(@WinlostDate, mi.currency, 0) e
			WHERE d.WinlostDate BETWEEN DATEADD(DAY, -1, @WinlostDate) AND DATEADD(DAY, 1, @WinlostDate)
				AND d.Status = 3 -- Approved
				AND CONVERT(DATE, DATEADD(HOUR, @TimeZone, d.CreateTime)) = @WinlostDate
			GROUP BY
				mi.CustId
				,mi.Currency
				,mi.AffId
				,e.Rate

			UNION ALL
			SELECT
				mi.CustId
				,mi.Currency
				,mi.AffId
				,0 AS Deposit
				,SUM(d.Amount * 1.0 / CASE WHEN e.Code IN ('VND', 'IDR') THEN 1000.0 ELSE 1.0 END) AS Withdrawal
				,0 AS Bonus
				,0 AS Rebate
				,e.Rate
			FROM bodb_N88.dbo.WithdrawalInfo d WITH (NOLOCK)
				INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON d.CustId = mi.CustId
				CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(@WinlostDate, mi.currency, 0) e
			WHERE d.WinlostDate BETWEEN DATEADD(DAY, -1, @WinlostDate) AND DATEADD(DAY, 1, @WinlostDate)
				AND d.Status = 6 -- Approved
				AND CONVERT(DATE, DATEADD(HOUR, @TimeZone, d.CreateTime)) = @WinlostDate
			GROUP BY
				mi.CustId
				,mi.Currency
				,mi.AffId
				,e.Rate

			UNION ALL
			SELECT
				mi.CustId
				,mi.Currency
				,mi.AffId
				,0 AS Deposit
				,0 AS Withdrawal
				,SUM(d.BonusAmount * 1.0 / CASE WHEN e.Code IN ('VND', 'IDR') THEN 1000.0 ELSE 1.0 END) AS Bonus
				,0 AS Rebate
				,e.Rate
			FROM bodb_N88.dbo.BonusInfo d WITH (NOLOCK)
				INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON d.CustId = mi.CustId
				CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(@WinlostDate, mi.currency, 0) e
			WHERE d.WinlostDate BETWEEN DATEADD(DAY, -1, @WinlostDate) AND DATEADD(DAY, 1, @WinlostDate)
				AND CONVERT(DATE, DATEADD(HOUR, @TimeZone, d.CreateTime)) = @WinlostDate
			GROUP BY
				mi.CustId
				,mi.Currency
				,mi.AffId
				,e.Rate

			UNION ALL
			SELECT
				mi.CustId
				,mi.Currency
				,mi.AffId
				,0 AS Deposit
				,0 AS Withdrawal
				,0 AS Bonus
				,SUM(d.RedeemAmount * 1.0 / CASE WHEN e.Code IN ('VND', 'IDR') THEN 1000.0 ELSE 1.0 END) AS Rebate
				,e.Rate
			FROM bodb_N88.dbo.RebateMLog d WITH (NOLOCK)
				INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON d.CustId = mi.CustId
				CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(@WinlostDate, mi.currency, 0) e
			WHERE d.WinlostDate BETWEEN DATEADD(DAY, -1, @WinlostDate) AND DATEADD(DAY, 1, @WinlostDate)
				AND CONVERT(DATE, DATEADD(HOUR, @TimeZone, d.CreateTime)) = @WinlostDate
			GROUP BY
				mi.CustId
				,mi.Currency
				,mi.AffId
				,e.Rate
		) t
		GROUP BY
			CustId
			,Currency
			,AffId
			,Rate
	END

	-- Gen data into rptMemberDaily
	BEGIN
		CREATE TABLE #_CheckData
		(
			ModifiedType	INT
			,CustId			INT
			,ProductId		INT
			,AffId			INT
			,Currency		INT
			,AffExRate		FLOAT
			,Bonus			MONEY
			,Rebate			MONEY
			,Turnover		MONEY
			,Winloss		MONEY
			,Revenue		MONEY
			,Deposit		MONEY
			,Withdrawal		MONEY
			,Adjustment		MONEY
		)
		;WITH CTE_rptMemberDaily AS
		(
			SELECT AffId,CustId,ProductId,Deposit,Withdrawal,Bonus,Rebate,Adjustment,Turnover,Winloss,Revenue,Currency,AffExRate
			FROM dbo.rptMemberDaily WITH (NOLOCK)
			WHERE winlostdate = @WinlostDate
				AND ProductId IN (SELECT ProductId FROM @Products)
		)
		INSERT INTO #_CheckData (ModifiedType, CustId, ProductId, AffId, Currency, AffExRate, Bonus, Rebate, Turnover, Winloss, Revenue, Deposit, Withdrawal, Adjustment)
		SELECT
			CASE	WHEN t.CustId IS NULL THEN -1 -- delete
					WHEN r.CustId IS NULL THEN 1 -- insert
					ELSE 0 END AS ModifiedType -- update
			,ISNULL(t.CustId, r.CustId) AS CustId
			,ISNULL(t.ProductId, r.ProductId) AS ProductId
			,t.AffId, t.Currency, t.AffExRate, t.Bonus, t.Rebate, t.Turnover, t.Winloss, t.Revenue
			,t.Deposit, t.Withdrawal, t.Adjustment
		FROM #rptMemberDaily t
			FULL OUTER JOIN CTE_rptMemberDaily r ON t.CustId = r.CustId AND t.ProductId = r.ProductId
		
		-- Delete
		IF EXISTS (SELECT 1 FROM #_CheckData WHERE ModifiedType = -1)
		BEGIN
			DELETE r WITH (ROWLOCK, UPDLOCK)
			FROM dbo.rptMemberDaily r
				INNER JOIN #_CheckData d ON r.winlostdate = @WinlostDate AND d.CustId = r.CustId AND d.ProductId = r.ProductId
			WHERE d.ModifiedType = -1

			DELETE #_CheckData WHERE ModifiedType = -1
		END
				
		-- Insert
		IF EXISTS (SELECT 1 FROM #_CheckData WHERE ModifiedType = 1)
		BEGIN
			DELETE #_CheckData
			OUTPUT @WinlostDate,DELETED.AffId,DELETED.CustId,DELETED.ProductId
					,DELETED.Deposit,DELETED.Withdrawal,DELETED.Bonus,DELETED.Rebate,DELETED.Adjustment,DELETED.Turnover,DELETED.Winloss,DELETED.Revenue
					,DELETED.Currency,DELETED.AffExRate
			INTO dbo.rptMemberDaily(WinlostDate,AffId,CustId,ProductId,Deposit,Withdrawal,Bonus,Rebate,Adjustment,Turnover,Winloss,Revenue,Currency,AffExRate)
			WHERE ModifiedType = 1
		END

		-- Update
		IF EXISTS (SELECT 1 FROM #_CheckData WHERE ModifiedType = 0)
		BEGIN
			UPDATE r WITH (ROWLOCK)
			SET r.AffId = d.AffId
				,r.Deposit = d.Deposit
				,r.Withdrawal = d.Withdrawal
				,r.Bonus = d.Bonus
				,r.Rebate = d.Rebate
				,r.Adjustment = d.Adjustment
				,r.Turnover = d.Turnover
				,r.Winloss = d.Winloss
				,r.Revenue = d.Revenue
				,r.Currency = d.Currency
				,r.AffExRate = d.AffExRate
			FROM dbo.rptMemberDaily r
				INNER JOIN #_CheckData d ON r.winlostdate = @WinlostDate AND d.CustId = r.CustId AND d.ProductId = r.ProductId
			WHERE d.ModifiedType = 0
				AND (
					r.AffId						<> d.AffId
					OR ISNULL(r.Bonus, 0)		<> ISNULL(d.Bonus, 0)
					OR ISNULL(r.Rebate, 0)		<> ISNULL(d.Rebate, 0)
					OR ISNULL(r.Turnover, 0)	<> ISNULL(d.Turnover, 0)
					OR ISNULL(r.Winloss, 0)		<> ISNULL(d.Winloss, 0)
					OR ISNULL(r.Revenue, 0)		<> ISNULL(d.Revenue, 0)
					OR ISNULL(r.Deposit, 0)		<> ISNULL(d.Deposit, 0)
					OR ISNULL(r.Withdrawal, 0)	<> ISNULL(d.Withdrawal, 0)
					OR ISNULL(r.Adjustment, 0)	<> ISNULL(d.Adjustment, 0)
					OR ISNULL(r.Currency, 0)	<> ISNULL(d.Currency, 0)
					OR ISNULL(r.AffExRate, 0)	<> ISNULL(d.AffExRate, 0)
				)
		END
	END

	DROP TABLE #_CheckData
	DROP TABLE #rptMemberDaily
END
GO