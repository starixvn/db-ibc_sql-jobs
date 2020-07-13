/*<info serverAlias="DBBAH-bodb02" executers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_BalanceRecord_ReInit]
	@custid int = NULL,
	@display bit = 0
AS
/*
	Created: 20200713@Booby
	Task: Re-init member balanceRecord
	DB: DBBAH/bodb02
		
	Revisions:
		- 20200713@Booby: Implement by custid mode
*/
BEGIN

	SET NOCOUNT ON;
	CREATE TABLE #c (custid int PRIMARY KEY, Balance money)

	IF @custid IS NULL
	BEGIN

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
				
	END
	ELSE
	BEGIN
		DECLARE @recommend INT;

		SELECT @recommend = recommend
		FROM dbo.vw_Customer WITH (NOLOCK)
		WHERE custid = @custid;

		;WITH B AS (
				SELECT custid, SUM(winlost-actual_stake+playercomm) bBalance
				FROM dbo.bettrans WITH (PAGLOCK)
				WHERE custid = @custid
				GROUP BY custid
			)
		, T AS (
			SELECT custid, -SUM(actual_stake) tBalance	FROM dbo.translog WITH (NOLOCK)
			WHERE  recommend = @recommend  
				AND custid = @custid
				AND statusID = 0
			GROUP BY custid
			)
		, RNG AS (
			SELECT custid, SUM(CASE WHEN statusid = 0 then -actual_stake ELSE winlost-actual_stake+playercomm END) rngBalance
			FROM dbo.bettransRNG WITH (PAGLOCK)
			WHERE recommend = @recommend  
				AND custid = @custid
				AND IsSum = 0
			GROUP BY custid
			)
		, LC AS (
			SELECT custid, SUM(CASE WHEN statusid = 0 then -actual_stake ELSE winlost-actual_stake+playercomm END) lcBalance
			FROM dbo.bettransLC WITH (PAGLOCK)
		WHERE custid = @custid
				AND IsSum = 0
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
		SELECT custid, S.Balance FROM S
		CROSS APPLY (
			SELECT TOP 1 Balance 
			FROM DBTRANS.bodb02.dbo.v_BalanceTable b with(nolock)
			WHERE custid = S.custid
		) AS bal
		WHERE S.Balance = bal.Balance
	END

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
GO
