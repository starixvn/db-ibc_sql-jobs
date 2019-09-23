/*<info serverAlias="DBRPT-bodb_Report" executers="" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_rptStatement_OpeningTotalBalance_14]
	@WinlostDate	DATE
	,@CustIds		VARCHAR(MAX)
AS

/*
	Created: 20190909@Percy
	DB: DBRPT.bodb_Report
	Task: rptStatement - Check and Correct OpeningTotalBalance on bettrans14 range

	Revisions:
		- 20190909@Percy: Initialize SP [RedmineID: #109293]
*/

BEGIN
	SET NOCOUNT ON

	/* ===== Get Customer Info ===== */
	BEGIN
		-- Super
		CREATE TABLE #tmpSuper (srecommend INT)
		INSERT INTO #tmpSuper (srecommend)
		SELECT DISTINCT c.srecommend
		FROM bodb02.dbo.Customer c WITH (NOLOCK)
			CROSS APPLY (
				SELECT val FROM bodb02.dbo.strSplit(@CustIds, ',') f WHERE c.custid = f.val
			) AS tmp

		-- Member + SMA
		CREATE TABLE #CustInfo (custid INT, roleid TINYINT, recommend INT, mrecommend INT, srecommend INT)
		INSERT INTO #CustInfo (custid, roleid, recommend, mrecommend, srecommend)
		SELECT c.custid, c.roleid, c.recommend, c.mrecommend, c.srecommend
		FROM bodb02.dbo.Customer c WITH (NOLOCK)
			INNER JOIN #tmpSuper s ON c.srecommend = s.srecommend

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
		,OpeningTotalBalance DECIMAL(37,4) -- over money type
	)

	INSERT INTO #SourceOpeningTotalBalance (WinlostDate, CustId, RoleId, recommend, mrecommend, srecommend, OpeningTotalBalance)
	SELECT r.WinlostDate, r.CustId, c.RoleId, c.recommend, c.mrecommend, c.srecommend, r.OpeningBalance AS OpeningTotalBalance
	FROM dbo.rptStatement r WITH (NOLOCK)
		CROSS APPLY (SELECT c.RoleId, c.recommend, c.mrecommend, c.srecommend FROM #CustInfo c WHERE r.CustId = c.CustId) AS c
	WHERE r.WinlostDate = @WinlostDate

	-- Every saturday, all customers data will be recored
	IF DATEPART(WEEKDAY, @WinlostDate) <> 7
	BEGIN
		IF @WinlostDate = @BalanceUpDay -- WEEKDAY = 6
		BEGIN
			SELECT @tmpWinlostDate = DATEADD(DAY, 1, @WinlostDate)

			INSERT INTO #SourceOpeningTotalBalance (WinlostDate, CustId, RoleId, recommend, mrecommend, srecommend, OpeningTotalBalance)
			SELECT r.WinlostDate, r.CustId, c.RoleId, c.recommend, c.mrecommend, c.srecommend, r.OpeningBalance AS OpeningTotalBalance
			FROM dbo.rptStatement r WITH (NOLOCK)
				CROSS APPLY (SELECT c.RoleId, c.recommend, c.mrecommend, c.srecommend FROM #CustInfo c WHERE r.CustId = c.CustId) AS c
			WHERE r.WinlostDate = @tmpWinlostDate
				AND NOT EXISTS (SELECT 1 FROM #SourceOpeningTotalBalance s WHERE s.CustId = r.CustId)
		END
		ELSE -- loop back to last saturday
		BEGIN
			SELECT @Last_Saturday	= DATEADD(DAY, -DATEPART(WEEKDAY, @WinlostDate), @WinlostDate)
			SELECT @tmpWinlostDate	= DATEADD(DAY, -1, @WinlostDate)

			WHILE @tmpWinlostDate >= @Last_Saturday
			BEGIN
				INSERT INTO #SourceOpeningTotalBalance (WinlostDate, CustId, RoleId, recommend, mrecommend, srecommend, OpeningTotalBalance)
				SELECT r.WinlostDate, r.CustId, c.RoleId, c.recommend, c.mrecommend, c.srecommend, r.ClosingBalance AS OpeningTotalBalance
				FROM dbo.rptStatement r WITH (NOLOCK)
					CROSS APPLY (SELECT c.RoleId, c.recommend, c.mrecommend, c.srecommend FROM #CustInfo c WHERE r.CustId = c.CustId) AS c
				WHERE r.WinlostDate = @tmpWinlostDate
					AND NOT EXISTS (SELECT 1 FROM #SourceOpeningTotalBalance s WHERE s.CustId = r.CustId)

				SELECT @tmpWinlostDate = DATEADD(DAY, -1, @tmpWinlostDate)
			END
		END
	END

	-- update OpeningTotalBalance
	CREATE INDEX ix_srecommend	ON #SourceOpeningTotalBalance (srecommend)
	CREATE INDEX ix_mrecommend	ON #SourceOpeningTotalBalance (mrecommend)
	CREATE INDEX ix_recommend	ON #SourceOpeningTotalBalance (recommend)
	CREATE INDEX ix_roleid		ON #SourceOpeningTotalBalance (RoleId, CustId)

	UPDATE s
	SET s.OpeningTotalBalance = t.OpeningTotalBalance
	FROM #SourceOpeningTotalBalance s
		CROSS APPLY (
			SELECT SUM(su.OpeningTotalBalance) AS OpeningTotalBalance FROM #SourceOpeningTotalBalance su WHERE s.CustId = su.srecommend AND s.RoleId = 4
			UNION ALL
			SELECT SUM(ma.OpeningTotalBalance) AS OpeningTotalBalance FROM #SourceOpeningTotalBalance ma WHERE s.CustId = ma.mrecommend AND s.RoleId = 3
			UNION ALL
			SELECT SUM(ag.OpeningTotalBalance) AS OpeningTotalBalance FROM #SourceOpeningTotalBalance ag WHERE s.CustId = ag.recommend AND s.RoleId = 2
		) AS t
	WHERE s.RoleId IN (2,3,4)

	-- Check data with target
	CREATE TABLE #__CheckData (CustId INT, OpeningTotalBalance DECIMAL(37,4))
	INSERT INTO #__CheckData (CustId, OpeningTotalBalance)
	SELECT s.CustId, s.OpeningTotalBalance
	FROM #SourceOpeningTotalBalance s
		INNER JOIN dbo.rptStatement r WITH (NOLOCK) ON s.CustId = r.CustId
	WHERE r.WinlostDate = @WinlostDate AND r.OpeningTotalBalance <> s.OpeningTotalBalance

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