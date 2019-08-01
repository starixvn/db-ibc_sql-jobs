/*<info serverAlias="DBRPT-bodb_Report" executers="" isFunction="0" isNested="1"></info>*/
USE bodb_Report
GO

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
*/

BEGIN
	SET NOCOUNT ON

	-- data type winlostdate on rptStatement/rptStatement_Old: DATE
	DECLARE @Last_Saturday		DATE
			,@BalanceUpDay		DATE
			,@tmpWinlostDate	DATE

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
		SELECT @Last_Saturday = ''

		CREATE TABLE #__bets (CustId INT) -- bet tickets
		CREATE TABLE #__transfers (CustId INT PRIMARY KEY) -- transfer tickets

		DECLARE @CustIds TABLE (CustId INT) -- using for nested loop

		SELECT @tmpWinlostDate =  DATEADD(DAY, -1, @WinlostDate) -- loop back to last saturday

		WHILE @tmpWinlostDate >= @Last_Saturday
		BEGIN
			-- Reset data
			TRUNCATE TABLE #__bets
			TRUNCATE TABLE #__transfers
			DELETE FROM @CustIds

			IF @tmpWinlostDate < @BalanceUpDay -- rptStatement_Old
			BEGIN
				IF @tmpWinlostDate = @Last_Saturday
				BEGIN
					INSERT INTO @CustIds (CustId)
					SELECT b.CustId FROM bodb02.dbo.bettrans b WITH (NOLOCK)
					WHERE b.bettype = 20000 AND b.matchid = 0 AND NOT EXISTS (SELECT 1 FROM #SourceOpeningTotalBalance s WHERE s.CustId = b.CustId)
				END
				ELSE
				BEGIN
					-- bet tickets
						-- member
					INSERT INTO #__bets (CustId)
					SELECT CustId FROM bodb_Archive.dbo.bettrans_bk WITH (NOLOCK) WHERE WinlostDate = @tmpWinlostDate
					GROUP BY CustId
						-- SMA
					INSERT INTO #__bets (CustId)
					SELECT c.recommend FROM bodb02.dbo.custInfo c WITH (NOLOCK)
					WHERE EXISTS (SELECT 1 FROM #__bets b WHERE c.CustId = b.CustId)
						AND c.RoleId = 1
					GROUP BY c.recommend
					UNION ALL
					SELECT c.mrecommend FROM bodb02.dbo.custInfo c WITH (NOLOCK)
					WHERE EXISTS (SELECT 1 FROM #__bets b WHERE c.CustId = b.CustId)
						AND c.RoleId = 1
					GROUP BY c.mrecommend
					UNION ALL
					SELECT c.srecommend FROM bodb02.dbo.custInfo c WITH (NOLOCK)
					WHERE EXISTS (SELECT 1 FROM #__bets b WHERE c.CustId = b.CustId)
						AND c.RoleId = 1
					GROUP BY c.srecommend

					-- transfer tickets
					INSERT INTO #__transfers (CustId)
					SELECT CustId FROM bodb_Archive.dbo.transfer_bk WITH (NOLOCK) WHERE WinlostDate = @tmpWinlostDate
					GROUP BY CustId

					-- mix cust bet + transfer
					INSERT INTO #__bets (CustId)
					SELECT t.CustId FROM #__transfers t
					WHERE NOT EXISTS (SELECT 1 FROM #__bets b WHERE b.CustId = t.CustId)

					-- final cust
					INSERT INTO @CustIds (CustId)
					SELECT b.CustId FROM #__bets b WITH (NOLOCK)
					WHERE NOT EXISTS (SELECT 1 FROM #SourceOpeningTotalBalance s WHERE s.CustId = b.CustId)
				END

				INSERT INTO #SourceOpeningTotalBalance (WinlostDate, CustId, OpeningTotalBalance)
				SELECT r.WinlostDate, r.CustId, r.ClosingBalance AS OpeningTotalBalance
				FROM @CustIds c
					CROSS APPLY (
						SELECT TOP (1) r.WinlostDate, r.CustId, r.ClosingBalance FROM dbo.rptStatement_Old r WITH (NOLOCK)
						WHERE r.CustId = c.CustId AND r.WinlostDate = @tmpWinlostDate
					) AS r
			END
			ELSE -- rptStatement
			BEGIN
				INSERT INTO #SourceOpeningTotalBalance (WinlostDate, CustId, OpeningTotalBalance)
				SELECT r.WinlostDate, r.CustId, r.ClosingBalance AS OpeningTotalBalance
				FROM dbo.rptStatement r WITH (NOLOCK)
				WHERE r.WinlostDate = @tmpWinlostDate
					AND NOT EXISTS (SELECT 1 FROM #SourceOpeningTotalBalance s WHERE s.CustId = r.CustId)
			END

			SELECT @tmpWinlostDate = DATEADD(DAY, -1, @tmpWinlostDate)
		END

		DROP TABLE #__bets
		DROP TABLE #__transfers
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
			SELECT SUM(ma.OpeningTotalBalance) AS OpeningTotalBalance FROM #SourceOpeningTotalBalance ma WHERE s.CustId = ma.srecommend AND s.RoleId = 3
			UNION ALL
			SELECT SUM(ag.OpeningTotalBalance) AS OpeningTotalBalance FROM #SourceOpeningTotalBalance ag WHERE s.CustId = ag.srecommend AND s.RoleId = 2
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