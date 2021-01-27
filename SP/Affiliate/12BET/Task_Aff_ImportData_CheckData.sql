/*<info serverAlias="DBAFF12BET-Affiliate_12BET" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_Aff_ImportData_CheckData]
	@WinlostDate	SMALLDATETIME,
	@IsCheckOnly	BIT = 0,
	@IsMatched		BIT = 0 OUTPUT,
	@ProductList	VARCHAR(50) = '' OUTPUT
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Job - Check and regen data of IBC's Products

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
		- 20190108@Percy: Get Product List from bettrans (IsIBC = 1) [RedmineID: #107623]
		- 20190109@Percy: Send mail if data has mismatch [RedmineID: #107623]
		- 20190116@Percy: Move send mail part out main SP: Task_Aff_ImportData_CheckData_Job [RedmineID: #107623]
		- 20180117@Percy: Check product by releasedDate [RedmineID: #106503]
		- 20191127@Percy: Enhance performance [RedmineID: #118992]
		- 20210127@Percy: Fix conflict ProductId = -3 with Playtech CS [RedmineID: #149476]
*/

BEGIN 
	SET NOCOUNT ON

	DECLARE @BalanceUpDay SMALLDATETIME, @MoveBetsDay SMALLDATETIME
	SELECT  @BalanceUpDay = winlostdate FROM bodb02.dbo.bettrans WITH (NOLOCK) WHERE custid = 3 AND matchid = 0 AND bettype = 20000
	SELECT  @MoveBetsDay = MAX(eventdate) FROM bodb02.dbo.match14 WITH (NOLOCK)

	IF @WinlostDate IS NULL OR @WinlostDate NOT BETWEEN @BalanceUpDay AND @MoveBetsDay
		RETURN

	-- Get data
	BEGIN
		CREATE TABLE #tmpBettrans
		(
			winlostdate	SMALLDATETIME
			,custid		INT
			,ProductId	INT
			,Deposit	MONEY
			,Withdrawal	MONEY
			,Bonus		MONEY
			,Adjustment	MONEY
			,Turnover	MONEY
			,Winloss	MONEY
		)
			
		SELECT DISTINCT p.ProductId, s.bettype -- bet types of bet tickets
		INTO #_bettype
		FROM dbo.Products p WITH (NOLOCK)
			INNER JOIN bodb02.dbo.Products ps WITH (NOLOCK) ON p.ProductPrefix = ps.ProductPrefix
			INNER JOIN bodb02.dbo.SportBettypeMatrix s WITH (NOLOCK) ON ps.ProductID = s.ProductID
		WHERE p.IsIBC = 1
			AND p.Enabled = 1

		UNION ALL -- bet types of transfer tickets
		SELECT bt.ProductId, bt.Bettype
		FROM (
			VALUES
				-- -1: Deposit
				(-1, 22001),
				-- -2: Withdrawal
				(-2, 22002), (-2, 22003),
				-- -3: Bonus
				(-3, 22004), (-3, 22200),
				-- -4: Adjustment
				(-4, 21001), (-4, 21002), (-4, 21003), (-4, 21004), (-4, 21005),
				(-4, 22005), (-4, 22201)
		) AS bt (ProductId, Bettype)
			
		SELECT DISTINCT recommend
		INTO #_recommend
		FROM dbo.MemberInfo WITH (NOLOCK)
			
		INSERT INTO #tmpBettrans (custid, winlostdate, ProductId, Deposit, Withdrawal, Bonus, Adjustment, Turnover, Winloss)
		SELECT b.custid, b.winlostdate, CASE WHEN bt.ProductId < 0 THEN -1 ELSE bt.ProductId END AS ProductId
			,SUM(CASE WHEN bt.ProductId = -1 THEN b.winlost-b.actual_stake		ELSE 0 END) AS Deposit
			,SUM(CASE WHEN bt.ProductId = -2 THEN -(b.winlost-b.actual_stake)	ELSE 0 END) AS Withdrawal
			,SUM(CASE WHEN bt.ProductId = -3 THEN b.winlost-b.actual_stake		ELSE 0 END) AS Bonus
			,SUM(CASE WHEN bt.ProductId = -4 THEN b.winlost-b.actual_stake		ELSE 0 END) AS Adjustment
			,SUM(CASE WHEN bt.ProductId > 0 AND b.bettype <> 911 THEN b.stake	ELSE 0 END) AS Turnover
			,SUM(CASE WHEN bt.ProductId > 0 THEN b.winlost-b.actual_stake+b.playercomm ELSE 0 END) AS Winloss
		FROM bodb02.dbo.bettrans14 b WITH (NOLOCK)
			INNER JOIN #_recommend r ON b.recommend = r.recommend
			INNER JOIN #_bettype bt ON b.bettype = bt.bettype
		WHERE b.winlostdate = @WinlostDate
			AND b.statusID NOT IN (0, 1, 101, 102, 103)
		GROUP BY b.custid, b.winlostdate, CASE WHEN bt.ProductId < 0 THEN -1 ELSE bt.ProductId END

		CREATE TABLE #rptMemberDaily
		(
			IBCCustId		INT
			,Currency		INT
			,AffId			INT
			,ProductId		INT
			,Deposit		MONEY
			,Withdrawal		MONEY
			,Bonus			MONEY
			,Adjustment		MONEY
			,Turnover		MONEY
			,Winloss		MONEY
			,AffExRate		FLOAT
			,ExRate			FLOAT
		)
		INSERT INTO #rptMemberDaily
		(
			IBCCustId
			,Currency
			,AffId
			,ProductId
			,Deposit
			,Withdrawal
			,Bonus
			,Adjustment
			,Turnover
			,Winloss
			,AffExRate
			,ExRate
		)
		SELECT
			mi.IBCCustId
			,mi.Currency
			,mi.AffId
			,b.ProductId
			,SUM(ISNULL(b.Deposit, 0)) AS Deposit
			,SUM(ISNULL(b.Withdrawal, 0)) AS Withdrawal
			,SUM(ISNULL(b.Bonus, 0)) AS Bonus
			,SUM(ISNULL(b.Adjustment, 0)) AS Adjustment
			,SUM(ISNULL(b.Turnover, 0)) AS Turnover
			,SUM(ISNULL(b.Winloss, 0)) AS Winloss
			,e.ActualRate2
			,e.ActualRate
		FROM #tmpBettrans b
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON b.custid = mi.IBCCustID
			CROSS APPLY dbo.Aff_f_ExchangeRateById_Sel(mi.currency, b.winlostdate) e
		WHERE NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mr.RemovedDate < DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, b.WinlostDate) + 1, 0))
					AND mr.IBCCustId = mi.IBCCustId
				)
		GROUP BY
			mi.IBCCustId
			,mi.Currency
			,mi.AffId
			,b.ProductId
			,e.ActualRate2
			,e.ActualRate

		DROP TABLE #_recommend
		DROP TABLE #tmpBettrans
	END

	-- Compare data
	BEGIN
		;WITH CTE_rptMemberDaily AS
		(
			SELECT AffId,IBCCustId,ProductId,Deposit,Withdrawal,Bonus,Adjustment,Turnover,Winloss,Currency,ExRate,AffExRate
			FROM dbo.rptMemberDaily r WITH (NOLOCK)
			WHERE r.winlostdate = @WinlostDate
				AND (
					r.ProductId = -1
					OR r.ProductId IN (SELECT bt.ProductId FROM #_bettype bt WHERE bt.ProductId > 0)
				)
		)
		SELECT
			CASE	WHEN t.IBCCustId IS NULL THEN -1 -- delete
					WHEN r.IBCCustId IS NULL THEN 1 -- insert
					ELSE 0 END AS ModifiedType-- update
			,ISNULL(t.IBCCustId, r.IBCCustId) AS IBCCustId
			,ISNULL(t.ProductId, r.ProductId) AS ProductId
			,t.AffId, t.Currency, t.AffExRate, t.ExRate, t.Bonus, t.Turnover, t.Winloss
			,t.Deposit, t.Withdrawal, t.Adjustment
		INTO #__Data
		FROM #rptMemberDaily t
			FULL OUTER JOIN CTE_rptMemberDaily r ON t.IBCCustId = r.IBCCustId AND t.ProductId = r.ProductId

		IF @@ROWCOUNT = 0
			SELECT @IsMatched = 1
		ELSE
			SELECT @IsMatched = 0
	END

	-- Correct data
	IF @IsMatched = 0
	BEGIN
		IF @IsCheckOnly = 1
		BEGIN
			PRINT 'Data on rptMemberDaily is not matched with source. ' + 'WinlostDate = ' + CONVERT(VARCHAR(10), @WinlostDate, 120)
			RETURN
		END
		
		-- Delete
		IF EXISTS (SELECT 1 FROM #__Data WHERE ModifiedType = -1)
		BEGIN
			DELETE r WITH (ROWLOCK, UPDLOCK)
			FROM dbo.rptMemberDaily r
				INNER JOIN #__Data d ON r.winlostdate = @WinlostDate AND d.IBCCustId = r.IBCCustId AND d.ProductId = r.ProductId
			WHERE d.ModifiedType = -1

			DELETE #__Data WHERE ModifiedType = -1
		END
				
		-- Insert
		IF EXISTS (SELECT 1 FROM #__Data WHERE ModifiedType = 1)
		BEGIN
			DELETE #__Data
			OUTPUT @WinlostDate,DELETED.AffId,DELETED.IBCCustId,DELETED.ProductId
					,DELETED.Deposit,DELETED.Withdrawal,DELETED.Bonus,DELETED.Adjustment,DELETED.Turnover,DELETED.Winloss
					,DELETED.Currency,DELETED.ExRate,DELETED.AffExRate,0 AWinloss,0 AComm
			INTO dbo.rptMemberDaily(WinlostDate,AffId,IBCCustId,ProductId,Deposit,Withdrawal,Bonus,Adjustment,Turnover,Winloss,Currency,ExRate,AffExRate,AWinloss,AComm)
			WHERE ModifiedType = 1
		END

		-- Update
		IF EXISTS (SELECT 1 FROM #__Data WHERE ModifiedType = 0)
		BEGIN
			UPDATE r WITH (ROWLOCK)
			SET r.AffId = d.AffId
				,r.Deposit = d.Deposit
				,r.Withdrawal = d.Withdrawal
				,r.Bonus = d.Bonus
				,r.Adjustment = d.Adjustment
				,r.Turnover = d.Turnover
				,r.Winloss = d.Winloss
				,r.Currency = d.Currency
				,r.ExRate = d.ExRate
				,r.AffExRate = d.AffExRate
				,r.AWinloss = 0
				,r.AComm = 0
			FROM dbo.rptMemberDaily r
				INNER JOIN #__Data d ON r.winlostdate = @WinlostDate AND d.IBCCustId = r.IBCCustId AND d.ProductId = r.ProductId
			WHERE d.ModifiedType = 0
				AND (
					r.AffId <> d.AffId
					OR r.Bonus <> d.Bonus
					OR r.Turnover <> d.Turnover
					OR r.Winloss <> d.Winloss
					OR r.Deposit <> d.Deposit
					OR r.Withdrawal <> d.Withdrawal
					OR r.Adjustment <> d.Adjustment
					OR r.Currency <> d.Currency
					OR r.ExRate <> d.ExRate
					OR r.AffExRate <> d.AffExRate
				)
		END
	END

	DROP TABLE #_bettype
	DROP TABLE #rptMemberDaily

	-- Output data
	SELECT @ProductList = NULL
	SELECT @ProductList = COALESCE(@ProductList + ',', '') + CONVERT(VARCHAR(5), ProductId) FROM #__Data

	DROP TABLE #__Data
END
GO