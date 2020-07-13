ALTER PROCEDURE [dbo].[DBA_BalanceRecord_ReInit]
	@custid int = NULL,
	@display bit = 0
AS

IF @custid IS NULL
BEGIN

	CREATE TABLE #c (custid int PRIMARY KEY, Balance money)

	;WITH B AS (
			SELECT custid, SUM(winlost-actual_stake+playercomm) bBalance
			FROM dbo.bettrans WITH (PAGLOCK)
			WHERE custid <> recommend AND custid <> mrecommend AND custid <> srecommend
			GROUP BY custid
		)
	, T AS (
		SELECT custid, -SUM(actual_stake) tBalance	FROM dbo.translog WITH (NOLOCK)
		WHERE statusID = 0
		GROUP BY custid
		)
	, RNG AS (
		SELECT custid, SUM(CASE WHEN statusid = 0 then -actual_stake ELSE winlost-actual_stake+playercomm END) rngBalance
		FROM dbo.bettransRNG WITH (PAGLOCK)
		WHERE IsSum = 0
		GROUP BY custid
		)
	, LC AS (
		SELECT custid, SUM(CASE WHEN statusid = 0 then -actual_stake ELSE winlost-actual_stake+playercomm END) lcBalance
		FROM dbo.bettransLC WITH (PAGLOCK)
		WHERE IsSum = 0
		GROUP BY custid
		)
	, S AS (
	SELECT
		b.custid, Balance = bBalance + ISNULL(tBalance, 0) + ISNULL(rngBalance, 0) + ISNULL(lcBalance, 0)
	FROM
		B
		LEFT JOIN T ON B.custid = T.custid
		LEFT JOIN RNG ON B.custid = RNG.custid
		LEFT JOIN LC ON B.custid = LC.custid
	)
	INSERT INTO #c (custid, Balance)
	SELECT custid, Balance FROM S

	;WITH
	-- prepare data to get lastest balance
		ListBAL AS (
			SELECT B.custid, NewBalance, RN = ROW_NUMBER() OVER (PARTITION BY B.custid ORDER BY RowID DESC) 
			FROM dbo.BalanceRecord B WITH (NOLOCK)
				INNER JOIN #c C ON B.custid = C.custid
		)
	-- prepare data to get lastest balance
		,CurrentBAL AS (SELECT * FROM ListBAL WHERE RN = 1)

	-- remove Row which already have Correct Running balance (Balnace same as calculated)
	DELETE C
	FROM #c C 
		INNER JOIN CurrentBAL CB ON C.custid = CB.custid AND C.Balance = CB.NewBalance


	-- sert Balance Re-Init
	INSERT INTO BalanceRecord (custid, transid, bettype, actual_stake, winlost, playercomm, balancechanged, newbalance, actionDate, actionID, [action])
	SELECT
		BAL.custid, 0, 0, 0, 0, 0, 0, BAL.Balance,
		CURRENT_TIMESTAMP, 255, 'Balance : Re-Init'
	FROM
		#c BAL
		INNER JOIN dbo.custinfo c WITH (ROWLOCK) ON BAL.custid = c.custid AND c.roleid = 1

	DROP TABLE #c
END

/*
ELSE
INSERT INTO BalanceRecord (custid, transid, bettype, actual_stake, winlost, playercomm, balancechanged, newbalance, actionDate, actionID, [action], BTBalance)
SELECT B.*, v.Balance BTBalance
FROM
	(SELECT
		custid, 0 transid, 20000 bettype, 
		SUM(actual_stake) actual_stake, SUM(winlost) winlost, SUM(playercomm) playercomm, 
		0 BalanceChanged, SUM(winlost-actual_stake+playercomm) NewBalance,
		CURRENT_TIMESTAMP ActionDate, 255 ActionID, 'Balance Re-Init' [Action]
	FROM
		dbo.bettrans with (rowlock)
	WHERE
		custid = @custid
	GROUP BY
		custid
	) B
	INNER JOIN DBTRANS.bodb02.dbo.v_BalanceTable v ON B.custid = v.custid
WHERE B.NewBalance = v.Balance

IF @display = 1 SELECT * FROM dbo.BalanceRecord with (nolock) WHERE RowID = SCOPE_IDENTITY()
*/