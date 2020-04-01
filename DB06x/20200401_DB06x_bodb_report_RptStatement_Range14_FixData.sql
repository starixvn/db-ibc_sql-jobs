/*
	Creator:bobby@20200331
	Task: Hotfix for reversal transaction in MB range - [Redmine: #131490]
	DB:DB06-DB061/bodb_report
*/
USE bodb_report
GO

DECLARE @cutoff_date DATE
	,@winlostdate DATE;
DECLARE @runningDays TABLE (
	winlostdate DATE
	,dayIdx INT identity(1, 1)
	);

CREATE TABLE #custTemp (
	custid INT PRIMARY KEY
	,closingdate DATE
	);

CREATE TABLE #custChanged (
	custid INT
	,closingdate DATE
	,openingdate DATE
	,closingbalance MONEY
	,openingbalance MONEY
	,is_updated BIT
	,CONSTRAINT PK_#custchanged_custid PRIMARY KEY (
		custid
		,closingdate
		,openingdate
		)
	);

CREATE TABLE #custOutput (
	custid INT
	,winlostdate DATE
	)

SET NOCOUNT ON;

DECLARE @min_date_r14 DATE
	,@max_date_OLD DATE

-- INIT cust to correct data
INSERT INTO #custTemp (custid)
SELECT Custid
FROM (
	VALUES (39372113)
		,(7213887)
	) AS c(custid);

WITH cte_closing
AS (
	SELECT rpt.custid
		,MAX(winlostdate) AS closingdate
	FROM dbo.rptStatement_Old rpt WITH (NOLOCK)
	INNER JOIN #custTemp ci ON ci.custid = rpt.custid
	GROUP BY rpt.custid
	)
UPDATE ci
SET ci.closingdate = cte.closingdate
FROM #custTemp ci
INNER JOIN cte_closing cte ON cte.custid = ci.custid

--- INIT closing balance
DECLARE @init_balance TABLE (
	custid INT
	,closingdate DATE
	,closingbalance MONEY
	)

INSERT INTO @init_balance (
	custid
	,closingdate
	,closingbalance
	)
SELECT rpt.custid
	,ci.closingdate
	,rpt.closingbalance
FROM dbo.rptStatement_Old rpt WITH (NOLOCK)
INNER JOIN #custTemp ci ON ci.custid = rpt.custid
	AND ci.closingdate = rpt.winlostdate

SELECT @cutoff_date = MAX(closingdate)
FROM #custTemp

INSERT INTO @runningDays (winlostdate)
SELECT winlostdate
FROM (
	SELECT DISTINCT rpt.winlostdate
	FROM dbo.rptStatement rpt WITH (NOLOCK)
	INNER JOIN #custTemp ci ON ci.custid = rpt.custid
	WHERE rpt.WinlostDate > @cutoff_date
	
	UNION ALL
	
	SELECT closingdate
	FROM #custTemp
	) AS rpt
ORDER BY rpt.WinlostDate ASC

SELECT *
FROM @init_balance

SELECT @cutoff_date AS [@cutoff_date]

--return
DECLARE @dayIdx INT = 1
	,@diff_total_balance MONEY = 0

WHILE EXISTS (
		SELECT 1
		FROM @runningDays
		WHERE dayIdx = @dayIdx
		)
BEGIN
	SELECT @winlostdate = winlostdate
	FROM @runningDays
	WHERE dayIdx = @dayIdx

	PRINT 'running -> (' + convert(VARCHAR(20), @winlostdate, 120) + ')';

	BEGIN TRY
			;

		WITH cte_mixStatement
		AS (
			SELECT cl.custid
				,isnull(closingbalance, 0) AS closingbalance
				,WinlostDate
			FROM dbo.rptStatement cl WITH (NOLOCK)
			INNER JOIN #custTemp ci ON ci.custid = cl.Custid
			WHERE cl.WinlostDate = @winlostdate
			
			UNION
			
			SELECT custid
				,isnull(closingbalance, 0)
				,closingdate AS winlostdate
			FROM @init_balance
			)
		INSERT INTO #custChanged (
			custid
			,closingdate
			,closingbalance
			,openingdate
			,openingbalance
			,is_updated
			)
		SELECT cl.Custid
			,cl.WinlostDate AS closingdate
			,cl.closingbalance
			,op.WinlostDate AS openingdate
			,op.OpeningBalance
			,0 AS is_updated
		FROM (
			SELECT cl.custid
				,isnull(cl.closingbalance, 0) AS closingbalance
				,cl.WinlostDate
			FROM cte_mixStatement cl
			WHERE cl.WinlostDate = @winlostdate
			) AS cl
		INNER JOIN (
			SELECT Custid
				,OpeningBalance
				,WinlostDate
			FROM (
				SELECT op.Custid
					,isnull(OpeningBalance, 0) AS OpeningBalance
					,WinlostDate
					,ROW_NUMBER() OVER (
						PARTITION BY op.custid ORDER BY op.winlostdate ASC
						) AS custIdx
				FROM dbo.rptStatement op WITH (NOLOCK)
				INNER JOIN #custTemp ci ON ci.custid = op.Custid
				WHERE op.WinlostDate > @winlostdate
				) AS op
			WHERE custIdx = 1
			) AS op ON op.Custid = cl.Custid
		WHERE op.OpeningBalance <> cl.ClosingBalance

		PRINT 'diff cust -> (' + convert(VARCHAR(10), @@rowcount) + ')';

		-- UPDATE OPENING
		SET @diff_total_balance = 0

		UPDATE tgr
		SET @diff_total_balance = ISNULL(src.closingbalance, 0) - ISNULL(tgr.OpeningBalance, 0)
			,tgr.OpeningBalance = src.closingbalance
			,tgr.ClosingBalance = (ISNULL(src.closingbalance, 0) + ISNULL(tgr.[Winlost], 0) + ISNULL(tgr.[Comm], 0) + ISNULL(tgr.[TransferAmt], 0))
			,tgr.OpeningTotalBalance = ISNULL(tgr.OpeningTotalBalance, 0) + ISNULL(@diff_total_balance, 0)
		OUTPUT inserted.Custid
			,inserted.WinlostDate
		INTO #custOutput
		FROM dbo.rptStatement tgr WITH (ROWLOCK)
		INNER JOIN #custChanged src ON src.custid = tgr.Custid
			AND src.openingdate = tgr.WinlostDate
		WHERE src.is_updated = 0

		-- UPDATE trace FLAG
		UPDATE rs
		SET rs.is_updated = 1
		FROM #custChanged rs
		INNER JOIN #custOutput co ON co.winlostdate = rs.openingdate
			AND co.custid = rs.custid
	END TRY

	BEGIN CATCH
		SELECT ERROR_MESSAGE() AS [ERROR]

		BREAK;
	END CATCH

	SET @dayIdx += 1;
END

-- CHECK rows updated
SELECT *
FROM #custChanged rs
INNER JOIN dbo.rptStatement rpt WITH (NOLOCK) ON rpt.Custid = rs.custid
	AND rpt.WinlostDate = rs.openingdate

DROP TABLE #custOutput

DROP TABLE #custTemp

DROP TABLE #custChanged
