/*<info serverAlias="DBN88-bodb_N88" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_N88_CustBonusSummary]
	@WinlostDate	DATE
	,@DataSources	VARCHAR(4000) = 'all'
AS

/*
	Created: 20220412@Percy
	DB: DBN88-bodb_N88
	Task: Job - Import data for CustBonusSummary

	Revisions:
		- 20220412@Percy: Initialize SP [RedmineID: #171245]
*/

BEGIN
	SET NOCOUNT ON
	
	-- Get data
	BEGIN
		CREATE TABLE #__CustBonusSummary
		(
			CustId			INT
			,CurrencyId		INT
			,SiteId			INT
			,DataSource		VARCHAR(128)
			,BonusType		SMALLINT
			,BonusStatus	TINYINT DEFAULT(0)
			,BonusCode		VARCHAR(50)
			,BonusTime		DATETIME
			,BonusAmount	MONEY
		)

		-- BonusInfo
		IF @DataSources = 'all' OR ',' + @DataSources + ',' LIKE '%,BonusInfo,%'
			INSERT INTO #__CustBonusSummary (CustId, CurrencyId, SiteId, DataSource, BonusType, BonusStatus, BonusCode, BonusTime, BonusAmount)
			SELECT CustId, CurrencyId, SiteId, 'BonusInfo' AS DataSource, PromotionType AS BonusType, Status AS BonusStatus, BonusCode
				,DATEADD(HOUR, DATEPART(HOUR, CreateTime), CONVERT(VARCHAR(10), CreateTime, 120)) AS BonusTime -- date & hour
				,SUM(BonusAmount / CASE WHEN CurrencyId IN (15, 51) THEN 1000.0 ELSE 1.0 END) AS BonusAmount
			FROM dbo.BonusInfo WITH (NOLOCK)
			WHERE WinlostDate = @WinlostDate
			GROUP BY CustId, CurrencyId, SiteId, PromotionType, Status, BonusCode
				,DATEADD(HOUR, DATEPART(HOUR, CreateTime), CONVERT(VARCHAR(10), CreateTime, 120)) -- date & hour

		-- RebateMLog
		IF @DataSources = 'all' OR ',' + @DataSources + ',' LIKE '%,RebateMLog,%'
			INSERT INTO #__CustBonusSummary (CustId, CurrencyId, SiteId, DataSource, BonusType, BonusCode, BonusTime, BonusAmount)
			SELECT CustId, CurrencyId, SiteId, 'RebateMLog' AS DataSource, RebateType AS BonusType, BonusCode
				,DATEADD(HOUR, DATEPART(HOUR, CreateTime), CONVERT(VARCHAR(10), CreateTime, 120)) AS BonusTime -- date & hour
				,SUM(RedeemAmount / CASE WHEN CurrencyId IN (15, 51) THEN 1000.0 ELSE 1.0 END) AS BonusAmount
			FROM dbo.RebateMLog WITH (NOLOCK)
			WHERE WinlostDate = @WinlostDate
			GROUP BY CustId, CurrencyId, SiteId, RebateType, BonusCode
				,DATEADD(HOUR, DATEPART(HOUR, CreateTime), CONVERT(VARCHAR(10), CreateTime, 120)) -- date & hour

		-- DrawLog
		IF @DataSources = 'all' OR ',' + @DataSources + ',' LIKE '%,DrawLog,%'
			INSERT INTO #__CustBonusSummary (CustId, CurrencyId, SiteId, DataSource, BonusCode, BonusTime, BonusAmount)
			SELECT CustId, CurrencyId, SiteId, 'DrawLog' AS DataSource, EventId AS BonusCode
				,DATEADD(HOUR, DATEPART(HOUR, DrawTime), CONVERT(VARCHAR(10), DrawTime, 120)) AS BonusTime -- date & hour
				,SUM(Amount / CASE WHEN CurrencyId IN (15, 51) THEN 1000.0 ELSE 1.0 END) AS BonusAmount
			FROM dbo.DrawLog WITH (NOLOCK)
			WHERE WinlostDate = @WinlostDate
			GROUP BY CustId, CurrencyId, SiteId, EventId
				,DATEADD(HOUR, DATEPART(HOUR, DrawTime), CONVERT(VARCHAR(10), DrawTime, 120)) -- date & hour

		-- AdjustmentInfo
		IF @DataSources = 'all' OR ',' + @DataSources + ',' LIKE '%,AdjustmentInfo,%'
			INSERT INTO #__CustBonusSummary (CustId, CurrencyId, SiteId, DataSource, BonusType, BonusStatus, BonusTime, BonusAmount)
			SELECT CustId, CurrencyId, SiteId, 'AdjustmentInfo' AS DataSource, AdjustType AS BonusType, Status AS BonusStatus
				,DATEADD(HOUR, DATEPART(HOUR, CreateTime), CONVERT(VARCHAR(10), CreateTime, 120)) AS BonusTime -- date & hour
				,SUM(Amount / CASE WHEN CurrencyId IN (15, 51) THEN 1000.0 ELSE 1.0 END) AS BonusAmount
			FROM dbo.AdjustmentInfo WITH (NOLOCK)
			WHERE WinlostDate = @WinlostDate
			GROUP BY CustId, CurrencyId, SiteId, AdjustType, Status
				,DATEADD(HOUR, DATEPART(HOUR, CreateTime), CONVERT(VARCHAR(10), CreateTime, 120)) -- date & hour

		-- LogAdminAdjustWallet
		IF @DataSources = 'all' OR ',' + @DataSources + ',' LIKE '%,LogAdminAdjustWallet,%'
			INSERT INTO #__CustBonusSummary (CustId, CurrencyId, SiteId, DataSource, BonusType, BonusStatus, BonusTime, BonusAmount)
			SELECT CustId, CurrencyId, SiteId, 'LogAdminAdjustWallet' AS DataSource, Direction AS BonusType, Status AS BonusStatus
				,DATEADD(HOUR, DATEPART(HOUR, CreateTime), CONVERT(VARCHAR(10), CreateTime, 120)) AS BonusTime -- date & hour
				,SUM(Amount / CASE WHEN CurrencyId IN (15, 51) THEN 1000.0 ELSE 1.0 END) AS BonusAmount
			FROM dbo.LogAdminAdjustWallet WITH (NOLOCK)
			WHERE WinlostDate = @WinlostDate
			GROUP BY CustId, CurrencyId, SiteId, Direction, Status
				,DATEADD(HOUR, DATEPART(HOUR, CreateTime), CONVERT(VARCHAR(10), CreateTime, 120)) -- date & hour

		-- VipUpgradeReview
		IF @DataSources = 'all' OR ',' + @DataSources + ',' LIKE '%,VipUpgradeReview,%'
			INSERT INTO #__CustBonusSummary (CustId, CurrencyId, SiteId, DataSource, BonusStatus, BonusTime, BonusAmount)
			SELECT CustId, CurrencyId, SiteId, 'VipUpgradeReview' AS DataSource, Status AS BonusStatus
				,DATEADD(HOUR, DATEPART(HOUR, SettleTime), CONVERT(VARCHAR(10), SettleTime, 120)) AS BonusTime -- date & hour
				,SUM(UpgradeAmount / CASE WHEN CurrencyId IN (15, 51) THEN 1000.0 ELSE 1.0 END) AS BonusAmount
			FROM dbo.VipUpgradeReview WITH (NOLOCK)
			WHERE WinlostDate = @WinlostDate
			GROUP BY CustId, CurrencyId, SiteId, Status
				,DATEADD(HOUR, DATEPART(HOUR, SettleTime), CONVERT(VARCHAR(10), SettleTime, 120)) -- date & hour

		-- CustVerificationReward
		IF @DataSources = 'all' OR ',' + @DataSources + ',' LIKE '%,CustVerificationReward,%'
			INSERT INTO #__CustBonusSummary (CustId, CurrencyId, SiteId, DataSource, BonusType, BonusTime, BonusAmount)
			SELECT CustId, CurrencyId, SiteId, 'CustVerificationReward' AS DataSource, RewardType AS BonusType
				,DATEADD(HOUR, DATEPART(HOUR, RewardTime), CONVERT(VARCHAR(10), RewardTime, 120)) AS BonusTime -- date & hour
				,SUM(RewardAmount / CASE WHEN CurrencyId IN (15, 51) THEN 1000.0 ELSE 1.0 END) AS BonusAmount
			FROM dbo.CustVerificationRewardDetail WITH (NOLOCK)
			WHERE WinlostDate = @WinlostDate
			GROUP BY CustId, CurrencyId, SiteId, RewardType
				,DATEADD(HOUR, DATEPART(HOUR, RewardTime), CONVERT(VARCHAR(10), RewardTime, 120)) -- date & hour

		-- ReferralMLog
		IF @DataSources = 'all' OR ',' + @DataSources + ',' LIKE '%,ReferralMLog,%'
			INSERT INTO #__CustBonusSummary (CustId, CurrencyId, SiteId, DataSource, BonusTime, BonusAmount)
			SELECT CustId, CurrencyId, SiteId, 'ReferralMLog' AS DataSource
				,DATEADD(HOUR, DATEPART(HOUR, CreateTime), CONVERT(VARCHAR(10), CreateTime, 120)) AS BonusTime -- date & hour
				,SUM(ReferralAmount / CASE WHEN CurrencyId IN (15, 51) THEN 1000.0 ELSE 1.0 END) AS BonusAmount
			FROM dbo.ReferralMLog WITH (NOLOCK)
			WHERE WinlostDate = @WinlostDate
			GROUP BY CustId, CurrencyId, SiteId
				,DATEADD(HOUR, DATEPART(HOUR, CreateTime), CONVERT(VARCHAR(10), CreateTime, 120)) -- date & hour
	END

	-- Gen data
	BEGIN
		DECLARE @FDate DATETIME = @WinlostDate
		DECLARE @TDate DATETIME = DATEADD(DAY, 1, @FDate)
		
		;WITH CTE_CustBonusSummary AS
		(
			SELECT CustId, CurrencyId, SiteId, DataSource, BonusType, BonusStatus, BonusCode, BonusTime, BonusAmount
			FROM dbo.CustBonusSummary WITH (NOLOCK)
			WHERE BonusTime >= @FDate AND BonusTime < @TDate
				AND (@DataSources = 'all' OR ',' + @DataSources + ',' LIKE '%,' + DataSource + ',%')
		)
		MERGE CTE_CustBonusSummary AS t
		USING #__CustBonusSummary AS s
			ON t.DataSource = s.DataSource
				AND ISNULL(t.BonusType, 0) = ISNULL(s.BonusType, 0)
				AND ISNULL(t.BonusStatus, 0) = ISNULL(s.BonusStatus, 0)
				AND ISNULL(t.BonusCode, '') = ISNULL(s.BonusCode, '')
				AND ISNULL(t.BonusTime, '') = ISNULL(s.BonusTime, '')
				AND t.CustId = s.CustId
		WHEN MATCHED THEN UPDATE
			SET t.CurrencyId = s.CurrencyId
				,t.SiteId = s.SiteId
				,t.BonusAmount = s.BonusAmount
		WHEN NOT MATCHED BY TARGET THEN INSERT
			(CustId, CurrencyId, SiteId, DataSource, BonusType, BonusStatus, BonusCode, BonusTime, BonusAmount)
			VALUES (s.CustId, s.CurrencyId, s.SiteId, s.DataSource, s.BonusType, s.BonusStatus, s.BonusCode, s.BonusTime, s.BonusAmount)
		WHEN NOT MATCHED BY SOURCE THEN DELETE;
	END

	DROP TABLE #__CustBonusSummary
END
GO