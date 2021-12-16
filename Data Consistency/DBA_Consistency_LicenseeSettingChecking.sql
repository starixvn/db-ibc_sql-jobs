/*<info serverAlias="DBCONSISTENCY-bodb_Consistency"></info>*/
USE [bodb_Consistency]
GO

ALTER PROCEDURE [dbo].[DBA_Consistency_LicenseeSettingChecking]
	@RuleId			TINYINT
	,@ErrCode		INT				= 0		OUTPUT
	,@ErrMsg		VARCHAR(MAX)	= ''	OUTPUT
	,@SampleData	VARCHAR(MAX)	= ''	OUTPUT
AS

/*
	Created: 20210419@Percy
	DB: DBCONSISTENCY-bodb_Consistency
	Task: LA Setting - Check data consistency

	Revisions:
		- 20210419@Percy: Initialize SP [RedmineID: #153195]
		- 20210531@Percy: Add rule 3: Check differrent PT Setting between NAP and LA [RedmineID: #153195]
		- 20210629@Percy: Enhance code get data from bettrans [RedmineID: #153195]
		- 20210812@Percy: Exclude Oddsspread Adjustment Dummy Account [RedmineID: #153195]
		- 20211215@Percy: Exclude Sports Lottery [RedmineID: #153195]
	
	Param's Explanation:
		@RuleId
			.1 = Licensee has bet tickets but Launch date is null or > winlostdate
			.2 = Licensee has bet tickets but Product's charge rate date is null or > winlostdate
			.3 = Licensee has bet tickets but PT <> charge rate
*/

BEGIN
	SET NOCOUNT ON

	-- Date range to check: MoveBetsDay + 1 to Yesterday
	DECLARE @MBBU TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)
	INSERT INTO @MBBU (BalanceUpDay, MoveBetsDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay

	DECLARE @MoveBetsDay SMALLDATETIME
	SELECT  @MoveBetsDay = MoveBetsDay FROM @MBBU

	DECLARE @CurrentDate SMALLDATETIME = CONVERT(DATE, GETDATE())

	-- Get Product - Bettype
	CREATE TABLE #SportBettypeMatrix (ProductId INT, Product3rdId INT, Bettype SMALLINT)
	INSERT INTO #SportBettypeMatrix (ProductId, Bettype)
	SELECT DISTINCT ProductId, Bettype FROM bodb02.dbo.SportBettypeMatrix WITH (NOLOCK) WHERE ProductId NOT IN (37, 63)
		AND BetType NOT IN (911, 912, 913, 914, 999, 1700, 1800, 8000, 1906, 1698, 1699, 4297, 4298, 4299, 4300, 18000)

	UPDATE s
	SET s.Product3rdId = CASE WHEN s.ProductId = 1 THEN 0 ELSE p3rd.ProductId END
	FROM #SportBettypeMatrix s
		INNER JOIN bodb02.dbo.Products p WITH (NOLOCK) ON s.ProductId = p.ProductId
		LEFT JOIN bodb_Licensee.dbo.Product3rd p3rd WITH (NOLOCK) ON p.ProductPrefix = p3rd.ProductPrefix

	-- Get data on bettrans
	CREATE TABLE #bettrans (LicenseeName VARCHAR(50), Currency INT, Product3rdId INT, TransId BIGINT, WinlostDate SMALLDATETIME, HousePT FLOAT)
	CREATE CLUSTERED INDEX CIX_bettrans ON #bettrans (Product3rdId, LicenseeName, Currency)

	CREATE TABLE #tmp_bettrans (recommend INT, bettype INT, winlostdate SMALLDATETIME, transid BIGINT, apositiontaking FLOAT)
	INSERT INTO #tmp_bettrans (recommend, bettype, winlostdate, transid, apositiontaking)
	SELECT recommend, bettype, winlostdate, transid, apositiontaking
	FROM (
		SELECT b.recommend, b.bettype, b.winlostdate, b.transid, b.apositiontaking
			,ROW_NUMBER() OVER(PARTITION BY b.winlostdate, b.recommend, b.bettype ORDER BY b.transid) AS RN
		FROM bodb02.dbo.bettrans b WITH (NOLOCK)
		WHERE b.winlostdate > @MoveBetsDay AND b.winlostdate < @CurrentDate
			AND b.statusId IN (111, 112, 113)
			AND b.currency <> 20
	) a
	WHERE RN = 1

	CREATE CLUSTERED INDEX CIX_tmp_bettrans ON #tmp_bettrans (recommend, bettype, winlostdate)

	INSERT INTO #bettrans (LicenseeName, Currency, Product3rdId, TransId, WinlostDate, HousePT)
	SELECT DISTINCT c.site, c.currency, b.Product3rdId, b.transid, b.winlostdate, CASE WHEN b.Product3rdId = 6 THEN 1.0 - b.apositiontaking ELSE 0 END
	FROM (
		SELECT b.recommend, sb.Product3rdId, b.transid, b.winlostdate, b.apositiontaking
			,ROW_NUMBER() OVER(PARTITION BY b.recommend, sb.Product3rdId, b.winlostdate ORDER BY b.transid) AS RN
		FROM #tmp_bettrans b
			INNER JOIN #SportBettypeMatrix sb ON b.bettype = sb.Bettype
	) b
		INNER JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON b.recommend = c.custid
	WHERE b.RN = 1

	-- Keep latest date for RNG Casino
	DELETE t
	FROM (
		SELECT ROW_NUMBER() OVER(PARTITION BY LicenseeName, currency ORDER BY winlostdate DESC) AS RN
		FROM #bettrans
		WHERE Product3rdId = 6
	) t
	WHERE RN > 1

	-- Get house pt setting
	CREATE TABLE #Member (LicenseeName VARCHAR(50), Currency INT, CustId INT, recommend INT, IsGroupPT BIT DEFAULT (0)) 
	INSERT INTO #Member (LicenseeName, Currency, CustId, recommend)
	SELECT Site, Currency, CustId, recommend
	FROM (
		SELECT cs.Site, cs.Currency, c.CustId, a.CustId AS recommend, ROW_NUMBER() OVER(PARTITION BY cs.Site, cs.Currency ORDER BY cs.Site) AS RN
		FROM bodb02.dbo.Dep_CustSuper cs WITH (NOLOCK)
			INNER JOIN bodb02.dbo.CustInfo a WITH (NOLOCK) ON cs.custid = a.srecommend AND a.roleid = 2 AND a.Enabled = 1
			OUTER APPLY (
				SELECT TOP 1 c.CustId
				FROM bodb02.dbo.CustInfo c WITH (NOLOCK)
				WHERE c.recommend = a.custid
					AND c.username NOT LIKE '%ClearBal' -- balance customer
					AND c.username NOT LIKE '%CashOut' -- CO customer
					AND c.username NOT LIKE '%01OddsAdj' -- Oddsspread Adjustment customer
					AND c.roleid = 1
					AND c.Enabled = 1
		) c
		WHERE cs.currency <> 20
			AND a.username NOT LIKE '%ACC%' -- dummy agent
	) t
	WHERE RN = 1

	UPDATE m
	SET m.IsGroupPT = 1
	FROM #Member m
		INNER JOIN bodb02.dbo.Dep_CustSettingMode dcs WITH (NOLOCK) ON m.CustId = dcs.CustId
	WHERE dcs.IsGroupedPT = 1

	CREATE TABLE #PT (LicenseeName VARCHAR(50), Currency INT, Product3rdId INT, HousePT SMALLMONEY, Rate SMALLMONEY)
	
	-- SB
	BEGIN
		-- member
		INSERT INTO #PT (LicenseeName, Currency, Product3rdId, HousePT)
		SELECT m.LicenseeName, m.Currency, 0, MAX(CONVERT(FLOAT, 1.0 - dcs.apositiontaking))
		FROM bodb02.dbo.Dep_CustSetting dcs WITH (NOLOCK)
			INNER JOIN #Member m ON m.CustId = dcs.CustId
		WHERE dcs.bettype = 1 AND dcs.sporttype = 1 AND dcs.islive = 0 AND dcs.apositiontaking <> 0 -- BA
		GROUP BY m.LicenseeName, m.Currency

		-- agent
		INSERT INTO #PT (LicenseeName, Currency, Product3rdId, HousePT)
		SELECT m.LicenseeName, m.Currency, 0, MAX(CONVERT(FLOAT, 1.0 - dcs.apositiontaking))
		FROM bodb02.dbo.Dep_CustSetting dcs WITH (NOLOCK)
			INNER JOIN #Member m ON m.recommend = dcs.CustId AND m.CustId IS NULL
		WHERE dcs.bettype = 1 AND dcs.sporttype = 1 AND dcs.islive = 0 AND dcs.apositiontaking <> 0 -- BA
		GROUP BY m.LicenseeName, m.Currency
	END

	-- Number Games
	BEGIN
		-- member
		INSERT INTO #PT (LicenseeName, Currency, Product3rdId, HousePT)
		SELECT m.LicenseeName, m.Currency, 2, MAX(CONVERT(FLOAT, 1.0 - dcs.apositiontaking)) AS HousePT
		FROM bodb02.dbo.Dep_CustSetting3rd dcs WITH (NOLOCK)
			INNER JOIN #Member m ON m.CustId = dcs.CustId
			INNER JOIN bodb02.dbo.CustInfo ci WITH (NOLOCK) ON m.CustId = ci.CustId AND ci.DisableNumber = 0
		WHERE dcs.bettype = 81 AND dcs.sporttype = 161 AND dcs.islive = 0
		GROUP BY m.LicenseeName, m.Currency

		-- agent
		INSERT INTO #PT (LicenseeName, Currency, Product3rdId, HousePT)
		SELECT m.LicenseeName, m.Currency, 2, MAX(CONVERT(FLOAT, 1.0 - dcs.apositiontaking)) AS HousePT
		FROM bodb02.dbo.Dep_CustSetting3rd dcs WITH (NOLOCK)
			INNER JOIN #Member m ON m.recommend = dcs.CustId AND m.CustId IS NULL
			INNER JOIN bodb02.dbo.CustInfo ci WITH (NOLOCK) ON m.recommend = ci.CustId AND ci.DisableNumber = 0
		WHERE dcs.bettype = 81 AND dcs.sporttype = 161 AND dcs.islive = 0
		GROUP BY m.LicenseeName, m.Currency
	END
	
	-- Keno
	BEGIN
		-- member
		INSERT INTO #PT (LicenseeName, Currency, Product3rdId, HousePT)
		SELECT m.LicenseeName, m.Currency, 8, MAX(CONVERT(FLOAT, 1.0 - dcs.apositiontaking)) AS HousePT
		FROM bodb02.dbo.CustSettingGame dcs WITH (NOLOCK)
			INNER JOIN #Member m ON m.CustId = dcs.CustId
			INNER JOIN bodb02.dbo.CustGameType cgt WITH (NOLOCK) ON m.CustId = cgt.CustId AND cgt.GameTypeId = 1 -- Keno Deposit
		WHERE dcs.bettype = 1501 AND dcs.sporttype = 202 AND cgt.IsDisabled = 0
		GROUP BY m.LicenseeName, m.Currency

		-- agent
		INSERT INTO #PT (LicenseeName, Currency, Product3rdId, HousePT)
		SELECT m.LicenseeName, m.Currency, 8, MAX(CONVERT(FLOAT, 1.0 - dcs.apositiontaking)) AS HousePT
		FROM bodb02.dbo.CustSettingGame dcs WITH (NOLOCK)
			INNER JOIN #Member m ON m.recommend = dcs.CustId AND m.CustId IS NULL
			INNER JOIN bodb02.dbo.CustGameType cgt WITH (NOLOCK) ON m.recommend = cgt.CustId AND cgt.GameTypeId = 1 -- Keno Deposit
		WHERE dcs.bettype = 1501 AND dcs.sporttype = 202 AND cgt.IsDisabled = 0
		GROUP BY m.LicenseeName, m.Currency
	END

	-- RnG Casino
	INSERT INTO #PT (LicenseeName, Currency, Product3rdId, HousePT)
	SELECT LicenseeName, Currency, 6, MAX(HousePT) AS HousePT
	FROM #bettrans
	WHERE Product3rdId = 6
	GROUP BY LicenseeName, Currency

	-- Others
	BEGIN
		CREATE TABLE #ProductSetting (ProductId INT, Product3rdId INT, SportType SMALLINT, BetType SMALLINT, IsLive BIT)
		INSERT INTO #ProductSetting (ProductId, SportType, BetType, IsLive)
		SELECT ProductId, SportType, BetType, IsLive
		FROM (
			SELECT ds.ProductId, dsd.SportType, dsd.BetType, dsd.IsLive
				,ROW_NUMBER() OVER(PARTITION BY ds.ProductId ORDER BY (SELECT NULL)) AS RN
			FROM bodb02.dbo.Dep_ProductSetting ds WITH (NOLOCK)
				INNER JOIN bodb02.dbo.Dep_ProductSettingDetail dsd WITH (NOLOCK) ON ds.ProductSettingId = dsd.ProductSettingId
			WHERE ds.SettingType = 1 -- PT
				AND dsd.SettingStatus = 0 -- PRO
				AND ds.ProductId <> 16
		) p
		WHERE RN = 1

		UPDATE ps
		SET ps.Product3rdId = p3.ProductId
		FROM #ProductSetting ps
			INNER JOIN bodb02.dbo.Products p WITH (NOLOCK) ON ps.ProductId = p.ProductId
			INNER JOIN bodb_Licensee.dbo.Product3rd p3 WITH (NOLOCK) ON p.ProductPrefix = p3.ProductPrefix

		DELETE #ProductSetting WHERE Product3rdId IN (0, 2, 6, 8)

		-- member
		INSERT INTO #PT (LicenseeName, Currency, Product3rdId, HousePT)
		SELECT LicenseeName, Currency, Product3rdId, MAX(HousePT) AS HousePT
		FROM (
			SELECT ps.Product3rdId, m.LicenseeName, m.Currency, MAX(CONVERT(FLOAT, 1.0 - dcs.AgentPT / 100.00)) AS HousePT
			FROM bodb02.dbo.Dep_CustPTGroupSetting_Member dcs WITH (NOLOCK)
				INNER JOIN #Member m ON m.recommend = dcs.AgentId AND m.IsGroupPT = 1
				INNER JOIN #ProductSetting ps ON dcs.SportType = ps.SportType AND dcs.BetType = ps.BetType AND dcs.IsLive = ps.IsLive
				INNER JOIN bodb02.dbo.Dep_ProductStatusProfile psp WITH (NOLOCK) ON psp.Sporttype = ps.SportType AND psp.BetType = ps.BetType
				INNER JOIN bodb02.dbo.Dep_CustProductStatus cps WITH (NOLOCK) ON m.recommend = cps.CustId
				CROSS APPLY bodb02.dbo.f_CustSetting_ProductStatusSel (cps.bitmapIsDisabled, psp.bitmapOrder) ds
			WHERE ds.value = 0
			GROUP BY ps.Product3rdId, m.LicenseeName, m.Currency
			UNION ALL
			SELECT ps.Product3rdId, m.LicenseeName, m.Currency, MAX(CONVERT(FLOAT, 1.0 - dcs.AgentPT / 100.00)) AS HousePT
			FROM bodb02.dbo.Dep_CustPTSetting_Member dcs WITH (NOLOCK)
				INNER JOIN #Member m ON m.CustId = dcs.CustId AND m.IsGroupPT = 0
				INNER JOIN #ProductSetting ps ON dcs.SportType = ps.SportType AND dcs.BetType = ps.BetType AND dcs.IsLive = ps.IsLive
				INNER JOIN bodb02.dbo.Dep_ProductStatusProfile psp WITH (NOLOCK) ON psp.Sporttype = ps.SportType AND psp.BetType = ps.BetType
				INNER JOIN bodb02.dbo.Dep_CustProductStatus cps WITH (NOLOCK) ON m.CustId = cps.CustId
				CROSS APPLY bodb02.dbo.f_CustSetting_ProductStatusSel (cps.bitmapIsDisabled, psp.bitmapOrder) ds
			WHERE ds.value = 0
			GROUP BY ps.Product3rdId, m.LicenseeName, m.Currency
		) t
		GROUP BY LicenseeName, Currency, Product3rdId

		-- agent
		INSERT INTO #PT (LicenseeName, Currency, Product3rdId, HousePT)
		SELECT m.LicenseeName, m.Currency, ps.Product3rdId, MAX(CONVERT(FLOAT, 1.0 - dcs.AgentPT / 100.00)) AS HousePT
		FROM bodb02.dbo.Dep_CustPTSetting_Agent dcs WITH (NOLOCK)
			INNER JOIN #Member m ON m.recommend = dcs.CustId AND m.IsGroupPT = 0 AND m.CustId IS NULL
			INNER JOIN #ProductSetting ps ON dcs.SportType = ps.SportType AND dcs.BetType = ps.BetType AND dcs.IsLive = ps.IsLive
			INNER JOIN bodb02.dbo.Dep_ProductStatusProfile psp WITH (NOLOCK) ON psp.Sporttype = ps.SportType AND psp.BetType = ps.BetType
			INNER JOIN bodb02.dbo.Dep_CustProductStatus cps WITH (NOLOCK) ON m.recommend = cps.CustId
			CROSS APPLY bodb02.dbo.f_CustSetting_ProductStatusSel (cps.bitmapIsDisabled, psp.bitmapOrder) ds
		WHERE ds.value = 0
		GROUP BY m.LicenseeName, m.Currency, ps.Product3rdId

		DROP TABLE #ProductSetting
	END

	-- Get charge rate setting
	CREATE TABLE #Licensees (PartyId INT, LicenseeId INT, IsDeposit BIT, LicenseeName VARCHAR(50), LaunchDate SMALLDATETIME)
	INSERT INTO #Licensees (PartyId, LicenseeId, IsDeposit, LicenseeName)
	SELECT p.PartyId, CASE WHEN pd.IsDeposit = 0 THEN lb.LabelId ELSE l.LicenseeId END, pd.IsDeposit, p.PartyName
	FROM bodb_Licensee.dbo.OAS_Party p WITH (NOLOCK)
		INNER JOIN bodb_Licensee.dbo.OAS_PartyDetail pd WITH (NOLOCK) ON p.PartyId = pd.PartyId
		LEFT JOIN bodb_Licensee.dbo.Licensees l WITH (NOLOCK) ON p.OldRefId = l.LicenseeId AND pd.IsDeposit = 1
		LEFT JOIN bodb_Licensee.dbo.Labels lb WITH (NOLOCK) ON p.OldRefId = lb.LicenseeId AND pd.IsDeposit = 0
	WHERE p.PartyType IN (1, 5) -- licensees (official, non-official)

	-- Deposit
	UPDATE l
	SET l.LaunchDate = ci.LaunchDate
	FROM #Licensees l
		INNER JOIN (
			SELECT FromParty AS PartyId, MIN(FromDate) AS LaunchDate
			FROM bodb_Licensee.dbo.OAS_ChargeInfo WITH (NOLOCK)
			WHERE ToParty IN (1, 9, 11, 98)
			GROUP BY FromParty
		) ci ON l.PartyId = ci.PartyId
	WHERE l.IsDeposit = 1

	-- Credit
	UPDATE #Licensees
	SET LaunchDate = (SELECT MIN(FromDate) AS LaunchDate
			FROM bodb_Licensee.dbo.OAS_ChargeInfo WITH (NOLOCK)
			WHERE FromParty IN (25, 30) OR ToParty IN (25, 30))
	WHERE IsDeposit = 0

	UPDATE l
	SET l.LicenseeName = s.SiteName
	FROM #Licensees l
		INNER JOIN bodb_Licensee.dbo.view_site_list s WITH (NOLOCK) ON l.LicenseeId = s.SiteId

	CREATE TABLE #ChargeRate (PartyId INT, Product3rdId INT, FromDate SMALLDATETIME, ToDate SMALLDATETIME, Currency INT, Rate SMALLMONEY)
	INSERT INTO #ChargeRate (PartyId, Product3rdId, FromDate, ToDate, Currency, Rate)
	SELECT DISTINCT l.PartyId, ci.ProductId, ci.FromDate, ci.ToDate, c.Currency, c.Rate
	FROM #Licensees l
		INNER JOIN bodb_Licensee.dbo.OAS_ChargeInfo ci WITH (NOLOCK) ON l.PartyId = ci.FromParty
		INNER JOIN bodb_Licensee.dbo.LA_ChargeInfo_SystemMapping map ON map.ChargeID = ci.ChargeID AND map.SystemID = 2
		LEFT JOIN bodb_Licensee.dbo.LA_ChargeRateByCurrency lc WITH (NOLOCK) ON ci.ChargeId = lc.ChargeId
		CROSS APPLY (
			SELECT CONVERT(INT, 0) AS Currency, CONVERT(FLOAT, ci.Rate) AS Rate
			UNION ALL SELECT lc.CurrencyId, lc.Rate
		) c
	WHERE
		(
			(ci.ProductId = 21 AND ci.ChargeType = 10)
			OR ci.ChargeType = 1
		)
		AND (
			ci.ToParty IN (1, 9, 11, 98)
			OR ci.FromParty IN (25, 30)
		)
		AND (
			(ci.FromDate < @CurrentDate AND ci.ToDate > @MoveBetsDay) -- current setting
			OR ci.FromDate >= @CurrentDate -- feature setting
		)
		AND c.Currency IS NOT NULL

	DELETE #bettrans WHERE LicenseeName IN ('Spondemo', 'Athena000')
	DELETE #Licensees WHERE LicenseeName IN ('Spondemo', 'Athena000')
	DELETE #PT WHERE LicenseeName IN ('Spondemo', 'Athena000')

	-- Check data Consistency between setting and ticket
	DECLARE @Result TABLE (RuleId TINYINT, LicenseeName VARCHAR(50), TransId VARCHAR(20), Product3rdId INT, ProductName VARCHAR(100), Currency INT, CurrencyCode VARCHAR(10))
	
	IF @RuleId IN (1, 2)
	BEGIN
		INSERT INTO @Result (RuleId, LicenseeName, TransId, Product3rdId, Currency)
		SELECT
			CASE
				WHEN l.LicenseeName IS NULL OR l.LaunchDate IS NULL OR l.LaunchDate > b.WinlostDate THEN 1
				WHEN c.PartyId IS NULL OR b.WinlostDate NOT BETWEEN c.FromDate AND c.ToDate THEN 2
				ELSE 0 END AS RuleId
			,ISNULL(ls.LicenseeName, b.LicenseeName)
			,CONVERT(VARCHAR(20), b.TransId)
			,b.Product3rdId
			,b.Currency
		FROM #bettrans b
			LEFT JOIN #Licensees l ON b.LicenseeName = l.LicenseeName
			LEFT JOIN bodb_Licensee.dbo.OAS_Party p WITH (NOLOCK) ON l.PartyId = p.PartyId AND l.IsDeposit = 0
			LEFT JOIN bodb_Licensee.dbo.Licensees ls WITH (NOLOCK) ON p.OldRefId = ls.LicenseeId
			LEFT JOIN (
				SELECT PartyId, Product3rdId, MIN(FromDate) AS FromDate, MAX(ToDate) AS ToDate
				FROM #ChargeRate
				WHERE Currency = 0
				GROUP BY PartyId, Product3rdId
			) c ON l.PartyId = c.PartyId AND b.Product3rdId = c.Product3rdId
		WHERE (l.LicenseeName IS NULL OR l.LaunchDate IS NULL OR l.LaunchDate > b.WinlostDate) -- Rule 1
			OR (c.PartyId IS NULL OR b.WinlostDate NOT BETWEEN c.FromDate AND c.ToDate) -- Rule 2

		DELETE r
		FROM (
			SELECT LicenseeName, ROW_NUMBER() OVER(PARTITION BY LicenseeName, CASE WHEN RuleId = 2 THEN Product3rdId END ORDER BY RuleId) AS RN
			FROM @Result
		) r
		WHERE RN > 1
	END
	ELSE IF @RuleId = 3
	BEGIN
		UPDATE pt
		SET pt.Rate = c.Rate
		FROM #PT pt
			INNER JOIN #Licensees l ON pt.LicenseeName = l.LicenseeName AND l.IsDeposit = 1
			INNER JOIN #ChargeRate c ON l.PartyId = c.PartyId AND pt.Product3rdId = c.Product3rdId AND pt.Currency = c.Currency
		WHERE @CurrentDate BETWEEN c.FromDate AND c.ToDate

		UPDATE pt
		SET pt.Rate = c.Rate
		FROM #PT pt
			INNER JOIN #Licensees l ON pt.LicenseeName = l.LicenseeName AND l.IsDeposit = 1
			INNER JOIN #ChargeRate c ON l.PartyId = c.PartyId AND pt.Product3rdId = c.Product3rdId AND c.Currency = 0
		WHERE @CurrentDate BETWEEN c.FromDate AND c.ToDate
			AND pt.Rate IS NULL

		INSERT INTO @Result (RuleId, LicenseeName, Product3rdId, Currency)
		SELECT 3, pt.LicenseeName, pt.Product3rdId, pt.Currency
		FROM #PT pt
			INNER JOIN #Licensees l ON pt.LicenseeName = l.LicenseeName AND l.IsDeposit = 1
		WHERE pt.Rate <> pt.HousePT
	END

	UPDATE r
	SET r.ProductName = CASE WHEN r.Product3rdId = 0 THEN 'Sportsbook' ELSE p.ProductName END
		,r.CurrencyCode = e.Code
		,r.LicenseeName = CASE r.LicenseeName WHEN 'IBC' THEN 'FDL' WHEN '18bb'THEN 'PIH' ELSE r.LicenseeName END
	FROM @Result r
		LEFT JOIN bodb_Licensee.dbo.Product3rd p WITH (NOLOCK) ON r.Product3rdId = p.ProductId
		INNER JOIN bodb02.dbo.Exchange e WITH (NOLOCK) ON r.Currency = e.ExchangeId

	-- Return data
	SELECT @ErrCode = 0, @ErrMsg = NULL, @SampleData = NULL

	;WITH CTE_LicenseeName AS (SELECT DISTINCT LicenseeName FROM @Result WHERE RuleId = @RuleId)
	SELECT @ErrCode = 100, @ErrMsg = COALESCE(@ErrMsg + ', ', '') + LicenseeName FROM CTE_LicenseeName ORDER BY LicenseeName

	SELECT @SampleData = COALESCE(@SampleData + ', ', '')
							+ CASE
								WHEN @RuleId = 1 THEN TransId + '(' + LicenseeName + ')'
								WHEN @RuleId = 2 THEN TransId + '(' + LicenseeName + '>' + ProductName + ')'
								WHEN @RuleId = 3 THEN LicenseeName + '(' + ProductName + '>' + CurrencyCode + ')'
								ELSE '' END
	FROM @Result
	WHERE RuleId = @RuleId
	ORDER BY LicenseeName

	IF @ErrMsg IS NULL
		SELECT @ErrMsg = '', @SampleData = ''
	ELSE
		SELECT @ErrMsg = 'Licensee ' + @ErrMsg
						+ CASE @RuleId
							WHEN 1 THEN ': 1st date of bet ticket is different from LA launch date info'
							WHEN 2 THEN ': 1st date of bet ticket is different from LA product charge rate'
							WHEN 3 THEN ': NAP PT is different from LA product charge rate'
							ELSE '' END
	
	DROP TABLE #bettrans
	DROP TABLE #ChargeRate
	DROP TABLE #Licensees
	DROP TABLE #Member
	DROP TABLE #PT
	DROP TABLE #SportBettypeMatrix
	DROP TABLE #tmp_bettrans
END
GO