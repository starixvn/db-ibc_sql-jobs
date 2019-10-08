/*<info serverAlias="DBRPT-bodb_Report" executers="" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_DailyRptStatement_OpeningTotalBalance_CheckData]
	@WinlostDate		DATE
	,@isCheckDataOnly	BIT = 0
	,@HasMismatch		BIT = 1 OUTPUT
AS

/*
	Created: 20190801@Percy
	DB: DBRPT.bodb_Report
	Task: rptStatement - Check and Correct OpeningTotalBalance

	Revisions:
		- 20190801@Percy: Initialize SP [RedmineID: #109293]
		- 20191002@Bobby: Implement headline - Statement [Redmine: #119289]
*/

BEGIN
	SET NOCOUNT ON

	-- data type winlostdate on rptStatement/rptStatement_Old: DATE
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

	INSERT INTO #SourceOpeningTotalBalance	(WinlostDate, CustId, OpeningTotalBalance)
	SELECT WinlostDate, CustId, OpeningBalance AS OpeningTotalBalance
	FROM dbo.rptStatement WITH (NOLOCK)
	WHERE WinlostDate = @WinlostDate

	-- Every saturday, all customers data will be recored
	IF DATEPART(WEEKDAY, @WinlostDate) <> 7
	BEGIN
		IF @WinlostDate = @BalanceUpDay -- WEEKDAY = 6
		BEGIN
			SELECT @tmpWinlostDate = DATEADD(DAY, 1, @WinlostDate)

			INSERT INTO #SourceOpeningTotalBalance (WinlostDate, CustId, OpeningTotalBalance)
			SELECT r.WinlostDate, r.CustId, r.OpeningBalance AS OpeningTotalBalance
			FROM dbo.rptStatement r WITH (NOLOCK)
			WHERE r.WinlostDate = @tmpWinlostDate
				AND NOT EXISTS (SELECT 1 FROM #SourceOpeningTotalBalance s WHERE s.CustId = r.CustId)
		END
		ELSE -- loop back to last saturday
		BEGIN
			SELECT @Last_Saturday	= DATEADD(DAY, -DATEPART(WEEKDAY, @WinlostDate), @WinlostDate)
			SELECT @tmpWinlostDate	= DATEADD(DAY, -1, @WinlostDate)

			WHILE @tmpWinlostDate >= @Last_Saturday
			BEGIN
				INSERT INTO #SourceOpeningTotalBalance (WinlostDate, CustId, OpeningTotalBalance)
				SELECT r.WinlostDate, r.CustId, r.ClosingBalance AS OpeningTotalBalance
				FROM dbo.rptStatement r WITH (NOLOCK)
				WHERE r.WinlostDate = @tmpWinlostDate
					AND NOT EXISTS (SELECT 1 FROM #SourceOpeningTotalBalance s WHERE s.CustId = r.CustId)

				SELECT @tmpWinlostDate = DATEADD(DAY, -1, @tmpWinlostDate)
			END
		END
	END

	-- update customer info
	UPDATE s
	SET s.roleid = c.roleid, s.recommend = c.recommend, s.mrecommend = c.mrecommend, s.srecommend = c.srecommend
	FROM #SourceOpeningTotalBalance s
		INNER JOIN bodb02.dbo.custInfo c WITH (NOLOCK) ON s.CustId = c.CustId

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

	-- UPDATE for Headline
	;
	WITH CTE_HealineBalance AS (
		SELECT cs.UplineId, SUM(bal.OpeningTotalBalance) AS OpeningTotalBalance
		FROM bodb02.dbo.CustSuper cs WITH(NOLOCK)
		INNER JOIN #SourceOpeningTotalBalance bal ON cs.custid = bal.custid AND bal.RoleId = 4  --> is super downline
		WHERE cs.UplineId > 0
		GROUP BY cs.UplineId
	)
	UPDATE s
	SET s.OpeningTotalBalance += d.OpeningTotalBalance
	FROM #SourceOpeningTotalBalance s
	INNER JOIN CTE_HealineBalance d 
	ON s.custid = d.UplineId
	-- END Headline

	-- Check data with target
	CREATE TABLE #__CheckData (CustId INT, OpeningTotalBalance DECIMAL(37,4))
	INSERT INTO #__CheckData (CustId, OpeningTotalBalance)
	SELECT s.CustId, s.OpeningTotalBalance
	FROM #SourceOpeningTotalBalance s
		INNER JOIN dbo.rptStatement r WITH (NOLOCK) ON s.CustId = r.CustId
	WHERE r.WinlostDate = @WinlostDate AND r.OpeningTotalBalance <> s.OpeningTotalBalance

	IF @@ROWCOUNT <> 0
		SELECT @HasMismatch = 1
	ELSE
		SELECT @HasMismatch = 0

	DROP TABLE #SourceOpeningTotalBalance

	IF @HasMismatch = 1
	BEGIN
		IF @isCheckDataOnly = 1
		BEGIN
			PRINT CONVERT(VARCHAR(10), @WinlostDate, 120) + ': Data on rptStatement has mismatch with source'

			SELECT r.CustId, r.OpeningTotalBalance AS targetOpeningTotalBalance, c.OpeningTotalBalance AS sourceOpeningTotalBalance
			FROM dbo.rptStatement r
				INNER JOIN #__CheckData c ON r.CustId = c.CustId
			WHERE r.WinlostDate = @WinlostDate
		END
		ELSE
		BEGIN
			UPDATE r WITH (ROWLOCK)
			SET r.OpeningTotalBalance = c.OpeningTotalBalance
			FROM dbo.rptStatement r
				INNER JOIN #__CheckData c ON r.CustId = c.CustId
			WHERE r.WinlostDate = @WinlostDate
		END
	END

	DROP TABLE #__CheckData
END
GO