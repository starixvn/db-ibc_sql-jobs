/*<info serverAlias="DBRPT-bodb_Report" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_rptStatement_OpeningTotalBalance_14]
	@WinlostDate	DATE
	,@CustIds		VARCHAR(MAX)
AS

/*
	Created: 20190909@Percy
	DB: DBRPT.bodb_Report
	Task: rptStatement - Check and Correct OpeningTotalBalance on bettrans14 range

	Revisions:
		- 20190909@Percy: Initialize SP [RedmineID: #115377]
		- 20191212@Percy: Get UplineId (HeadlineId) from ExtraPT Setting table [RedmineID: #118962]
		- 20211104@Percy: Fix case UplineId is null [RedmineID: #164203]
*/

BEGIN
	SET NOCOUNT ON

	/* ===== Get Customer Info ===== */
	BEGIN
		-- Super
		CREATE TABLE #tmpSuper (UplineId INT, srecommend INT)
		INSERT INTO #tmpSuper (UplineId, srecommend)
		SELECT DISTINCT u.UplineId, c.srecommend
		FROM bodb02.dbo.Customer c WITH (NOLOCK)
			CROSS APPLY (
				SELECT val FROM bodb02.dbo.strSplit(@CustIds, ',') f WHERE c.custid = f.val
			) AS tmp
			OUTER APPLY (
				SELECT TOP (1) ag.UplineId
				FROM bodb02.dbo.Acc_GroupExtraPTSetting ag WITH (NOLOCK)
				WHERE c.srecommend = ag.SuperId
					AND @WinlostDate BETWEEN ag.FromDate AND ag.ToDate
			) AS u

		-- Member + SMA + Headline
		CREATE TABLE #CustInfo (custid INT, roleid TINYINT, recommend INT, mrecommend INT, srecommend INT, UplineId INT)
		INSERT INTO #CustInfo (custid, roleid, recommend, mrecommend, srecommend, UplineId)
		SELECT c.custid, c.roleid, c.recommend, c.mrecommend, c.srecommend, s.UplineId
		FROM bodb02.dbo.Customer c WITH (NOLOCK)
			INNER JOIN #tmpSuper s ON c.srecommend = s.srecommend
		UNION ALL
		SELECT DISTINCT UplineId, 0, 0, 0, 0, UplineId FROM #tmpSuper WHERE UplineId IS NOT NULL

		DROP TABLE #tmpSuper
	END
	/* ===== End Get Customer Info ===== */

	-- data type winlostdate on rptStatement: DATE
	DECLARE @Last_Saturday		DATE
			,@BalanceUpDay		DATE
			,@tmpWinlostDate	DATE

	DECLARE @MBBU TABLE (BalanceUpDay DATE, MoveBetsDay DATE)
	INSERT INTO @MBBU (BalanceUpDay, MoveBetsDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay

	SELECT @BalanceUpDay = BalanceUpDay FROM @MBBU

	CREATE TABLE #SourceOpeningTotalBalance
	(
		WinlostDate DATE
		,CustId		INT
		,RoleId		TINYINT
		,recommend	INT
		,mrecommend	INT
		,srecommend	INT
		,UplineId	INT
		,OpeningTotalBalance DECIMAL(37,4) -- over money type
	)

	INSERT INTO #SourceOpeningTotalBalance (WinlostDate, CustId, RoleId, recommend, mrecommend, srecommend, UplineId, OpeningTotalBalance)
	SELECT r.WinlostDate, r.CustId, c.RoleId, c.recommend, c.mrecommend, c.srecommend, c.UplineId, r.OpeningBalance AS OpeningTotalBalance
	FROM dbo.rptStatement r WITH (NOLOCK)
		CROSS APPLY (SELECT c.RoleId, c.recommend, c.mrecommend, c.srecommend, c.UplineId FROM #CustInfo c WHERE r.CustId = c.CustId) AS c
	WHERE r.WinlostDate = @WinlostDate

	-- Every saturday, all customers data will be recored
	IF DATEPART(WEEKDAY, @WinlostDate) <> 7
	BEGIN
		IF @WinlostDate = @BalanceUpDay -- WEEKDAY = 6
		BEGIN
			SELECT @tmpWinlostDate = DATEADD(DAY, 1, @WinlostDate)

			INSERT INTO #SourceOpeningTotalBalance (WinlostDate, CustId, RoleId, recommend, mrecommend, srecommend, UplineId, OpeningTotalBalance)
			SELECT r.WinlostDate, r.CustId, c.RoleId, c.recommend, c.mrecommend, c.srecommend, c.UplineId, r.OpeningBalance AS OpeningTotalBalance
			FROM dbo.rptStatement r WITH (NOLOCK)
				CROSS APPLY (SELECT c.RoleId, c.recommend, c.mrecommend, c.srecommend, c.UplineId FROM #CustInfo c WHERE r.CustId = c.CustId) AS c
			WHERE r.WinlostDate = @tmpWinlostDate
				AND NOT EXISTS (SELECT 1 FROM #SourceOpeningTotalBalance s WHERE s.CustId = r.CustId)
		END
		ELSE -- loop back to last saturday
		BEGIN
			SELECT @Last_Saturday	= DATEADD(DAY, -DATEPART(WEEKDAY, @WinlostDate), @WinlostDate)
			SELECT @tmpWinlostDate	= DATEADD(DAY, -1, @WinlostDate)

			WHILE @tmpWinlostDate >= @Last_Saturday
			BEGIN
				INSERT INTO #SourceOpeningTotalBalance (WinlostDate, CustId, RoleId, recommend, mrecommend, srecommend, UplineId, OpeningTotalBalance)
				SELECT r.WinlostDate, r.CustId, c.RoleId, c.recommend, c.mrecommend, c.srecommend, c.UplineId, r.ClosingBalance AS OpeningTotalBalance
				FROM dbo.rptStatement r WITH (NOLOCK)
					CROSS APPLY (SELECT c.RoleId, c.recommend, c.mrecommend, c.srecommend, c.UplineId FROM #CustInfo c WHERE r.CustId = c.CustId) AS c
				WHERE r.WinlostDate = @tmpWinlostDate
					AND NOT EXISTS (SELECT 1 FROM #SourceOpeningTotalBalance s WHERE s.CustId = r.CustId)

				SELECT @tmpWinlostDate = DATEADD(DAY, -1, @tmpWinlostDate)
			END
		END
	END

	-- update OpeningTotalBalance
	CREATE INDEX ix_UplineId	ON #SourceOpeningTotalBalance (UplineId)
	CREATE INDEX ix_srecommend	ON #SourceOpeningTotalBalance (srecommend)
	CREATE INDEX ix_mrecommend	ON #SourceOpeningTotalBalance (mrecommend)
	CREATE INDEX ix_recommend	ON #SourceOpeningTotalBalance (recommend)
	CREATE INDEX ix_roleid		ON #SourceOpeningTotalBalance (RoleId, CustId)

	UPDATE s
	SET s.OpeningTotalBalance = t.OpeningTotalBalance
	FROM #SourceOpeningTotalBalance s
		CROSS APPLY (
			SELECT SUM(up.OpeningTotalBalance) AS OpeningTotalBalance FROM #SourceOpeningTotalBalance up
			WHERE s.CustId = up.UplineId AND s.RoleId = 0 HAVING COUNT (1) > 0
			UNION ALL
			SELECT SUM(su.OpeningTotalBalance) AS OpeningTotalBalance FROM #SourceOpeningTotalBalance su
			WHERE s.CustId = su.srecommend AND s.RoleId = 4 HAVING COUNT (1) > 0
			UNION ALL
			SELECT SUM(ma.OpeningTotalBalance) AS OpeningTotalBalance FROM #SourceOpeningTotalBalance ma
			WHERE s.CustId = ma.mrecommend AND s.RoleId = 3 HAVING COUNT (1) > 0
			UNION ALL
			SELECT SUM(ag.OpeningTotalBalance) AS OpeningTotalBalance FROM #SourceOpeningTotalBalance ag
			WHERE s.CustId = ag.recommend AND s.RoleId = 2 HAVING COUNT (1) > 0
		) AS t
	WHERE s.RoleId IN (2,3,4,0)

	-- Check data with target
	CREATE TABLE #__CheckData (CustId INT, OpeningTotalBalance DECIMAL(37,4))
	INSERT INTO #__CheckData (CustId, OpeningTotalBalance)
	SELECT s.CustId, s.OpeningTotalBalance
	FROM #SourceOpeningTotalBalance s
		INNER JOIN dbo.rptStatement r WITH (NOLOCK) ON s.CustId = r.CustId
	WHERE r.WinlostDate = @WinlostDate AND ISNULL(r.OpeningTotalBalance, 0) <> ISNULL(s.OpeningTotalBalance, 0)

	IF @@ROWCOUNT <> 0
	BEGIN
		UPDATE r WITH (ROWLOCK)
		SET r.OpeningTotalBalance = c.OpeningTotalBalance
		FROM dbo.rptStatement r
			INNER JOIN #__CheckData c ON r.CustId = c.CustId
		WHERE r.WinlostDate = @WinlostDate
	END

	DROP TABLE #CustInfo
	DROP TABLE #SourceOpeningTotalBalance
	DROP TABLE #__CheckData
END
GO