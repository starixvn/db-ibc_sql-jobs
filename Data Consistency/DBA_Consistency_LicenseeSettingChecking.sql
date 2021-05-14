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
	
	Param's Explanation:
		@RuleId
			.1 = Licensee has bet tickets but Launch date is null or > winlostdate
			.2 = Licensee has bet tickets but Product's charge rate date is null or > winlostdate
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
	SELECT DISTINCT ProductId, Bettype FROM bodb02.dbo.SportBettypeMatrix WITH (NOLOCK) WHERE ProductId <> 37

	UPDATE s
	SET s.Product3rdId = CASE WHEN s.ProductId = 1 THEN 0 ELSE p3rd.ProductId END
	FROM #SportBettypeMatrix s
		INNER JOIN bodb02.dbo.Products p WITH (NOLOCK) ON s.ProductId = p.ProductId
		LEFT JOIN bodb_Licensee.dbo.Product3rd p3rd WITH (NOLOCK) ON p.ProductPrefix = p3rd.ProductPrefix

	-- Get data on bettrans
	DECLARE @tblWinlostDate TABLE (winlostdate SMALLDATETIME)
	;WITH CTE_winlostdate AS (
		SELECT @MoveBetsDay AS winlostdate
		UNION ALL
		SELECT DATEADD(DAY, 1, winlostdate)
		FROM CTE_winlostdate
		WHERE winlostdate < @CurrentDate
	)
	INSERT INTO @tblWinlostDate (winlostdate)
	SELECT winlostdate FROM CTE_winlostdate
	OPTION (MAXRECURSION 0)

	DELETE @tblWinlostDate WHERE winlostdate <= @MoveBetsDay OR winlostdate >= @CurrentDate

	CREATE TABLE #bettrans (LicenseeName VARCHAR(50), Product3rdId INT, TransId BIGINT, WinlostDate SMALLDATETIME)
	INSERT INTO #bettrans (LicenseeName, Product3rdId, TransId, WinlostDate)
	SELECT DISTINCT site, Product3rdId, transid, winlostdate
	FROM (
		SELECT recommend, Product3rdId, transid, t.winlostdate
		FROM @tblWinlostDate t
			CROSS APPLY (
				SELECT b.recommend, sb.Product3rdId, b.transid
					,ROW_NUMBER() OVER(PARTITION BY b.recommend, sb.Product3rdId, b.winlostdate ORDER BY b.winlostdate) AS RN
				FROM bodb02.dbo.bettrans b WITH (NOLOCK)
					INNER JOIN #SportBettypeMatrix sb ON b.bettype = sb.Bettype
				WHERE b.winlostdate = t.winlostdate
					AND b.statusID IN (111, 112, 113)
					AND b.currency <> 20
			) b
		WHERE RN = 1
	) b
		INNER JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON b.recommend = c.custid

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

	CREATE TABLE #ChargeRate (PartyId INT, Product3rdId INT, FromDate SMALLDATETIME, ToDate SMALLDATETIME)
	INSERT INTO #ChargeRate (PartyId, Product3rdId, FromDate, ToDate)
	SELECT DISTINCT l.PartyId, ci.ProductId, ci.FromDate, ci.ToDate
	FROM #Licensees l
		INNER JOIN bodb_Licensee.dbo.OAS_ChargeInfo ci WITH (NOLOCK) ON l.PartyId = ci.FromParty
		INNER JOIN bodb_Licensee.dbo.LA_ChargeInfo_SystemMapping map ON map.ChargeID = ci.ChargeID AND map.SystemID = 2
	WHERE
		(ci.FromDate < @CurrentDate AND ci.ToDate > @MoveBetsDay) -- current setting
		OR ci.FromDate >= @CurrentDate -- feature setting

	-- Check data Consistency between setting and ticket
	DECLARE @Result TABLE (RuleId TINYINT, LicenseeName VARCHAR(50), TransId VARCHAR(20))
	INSERT INTO @Result (RuleId, LicenseeName, TransId)
	SELECT CASE WHEN l.LaunchDate IS NULL OR l.LaunchDate > b.WinlostDate THEN 1 ELSE 2 END AS RuleId, b.LicenseeName, CONVERT(VARCHAR(20), b.TransId)
	FROM #bettrans b
		INNER JOIN #Licensees l ON b.LicenseeName = l.LicenseeName
		LEFT JOIN #ChargeRate c ON l.PartyId = c.PartyId AND b.Product3rdId = c.Product3rdId
	WHERE c.PartyId IS NULL OR b.WinlostDate NOT BETWEEN c.FromDate AND c.ToDate

	DELETE r
	FROM (
		SELECT LicenseeName, ROW_NUMBER() OVER(PARTITION BY LicenseeName ORDER BY RuleId) AS RN
		FROM @Result
	) r
	WHERE RN > 1

	-- Return data
	SELECT @ErrCode = 0, @ErrMsg = NULL, @SampleData = NULL

	SELECT @ErrCode = 100
		,@ErrMsg = COALESCE(@ErrMsg + ', ', '') + LicenseeName
		,@SampleData = COALESCE(@SampleData + ', ', '') + TransId + '(' + LicenseeName + ')'
	FROM @Result
	WHERE RuleId = @RuleId

	IF @ErrMsg IS NULL
		SELECT @ErrMsg = '', @SampleData = ''
	ELSE
		SELECT @ErrMsg = 'Licensee ' + @ErrMsg + ': 1st date of bet ticket is different from LA'
						+ CASE @RuleId
							WHEN 1 THEN ' launch date info'
							WHEN 2 THEN ' product charge rate'
							ELSE '' END
	
	DROP TABLE #bettrans
	DROP TABLE #ChargeRate
	DROP TABLE #Licensees
	DROP TABLE #SportBettypeMatrix
END
GO