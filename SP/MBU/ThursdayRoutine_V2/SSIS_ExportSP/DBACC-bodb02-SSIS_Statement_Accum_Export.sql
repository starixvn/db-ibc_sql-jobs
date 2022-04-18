/*<info serverAlias="DBACC-bodb02" executers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.SSIS_Statement_Accum_Export
AS
/*
	Created:	20220404@Percy
	Task:		SSIS Archiving Data - Statement_Accum
	Database:	DBACC-bodb02

	Revisions:
		- 20220404@Percy: Initialize SP [RedmineID: #169560]
 */
BEGIN
	SET NOCOUNT ON

	DECLARE @min_winlostdate SMALLDATETIME,
			@max_winlostdate SMALLDATETIME,
			@fromdate	DATETIME,
			@todate		DATETIME,
			@accdate	DATETIME
	
	SELECT
		@min_winlostdate = MIN(winlostdate),
		@max_winlostdate = MAX(winlostdate)
	FROM DBTXN.bodb02.dbo.Task_ArchiveDate WITH (NOLOCK)

	SELECT @fromdate = @min_winlostdate, @todate = @max_winlostdate, @accdate = DATEADD(DAY, 1, @max_winlostdate)

	-- Get data from bettrans
	CREATE TABLE #bettrans 
	(
		custid INT, recommend INT, mrecommend INT, srecommend INT,
		actual_stake MONEY, winlost MONEY, awinlost MONEY, mwinlost MONEY, swinlost MONEY,
		playercomm MONEY, comm MONEY, acomm MONEY, scomm MONEY
	)

	INSERT INTO #bettrans (custid, recommend, mrecommend, srecommend, actual_stake, winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm)
	SELECT custid, recommend, mrecommend, srecommend, SUM(actual_stake), SUM(winlost), SUM(awinlost), SUM(mwinlost), SUM(swinlost), SUM(playercomm), SUM(comm), SUM(acomm), SUM(scomm)
	FROM dbo.bettrans14 WITH (NOLOCK)
	WHERE winlostdate BETWEEN @min_winlostdate AND @max_winlostdate
	GROUP BY custid, recommend, mrecommend, srecommend

	SELECT CustId, @accdate AS AccDate, SUM(totalamt) AS TotalAmt
	FROM (
		-- Opening Accumulated Amount
		SELECT custid, totalamt
		FROM bodb_Report.dbo.Statement_Accum WITH (NOLOCK)
		WHERE accdate = @fromdate

		-- Transfer tickets
		UNION ALL
		SELECT CustId, SUM(Winlost - Actual_Stake) AS totalamt
		FROM dbo.Transfer WITH (NOLOCK)
		WHERE TransDate BETWEEN @fromdate AND @todate AND bettype > 20000
		GROUP BY CustId
		UNION ALL
		SELECT CustId, SUM(Credit - Debit) AS totalamt
		FROM bodb_Archive.dbo.Transfer_bk WITH (NOLOCK)
		WHERE TransDate BETWEEN @fromdate AND @todate AND bettype > 20000
			AND winlostdate >= DATEADD(DAY, -14, @min_winlostdate)
		GROUP BY CustId

		-- Prize tickets
		UNION ALL
		SELECT custid, SUM(WinAmount) AS totalamt
		FROM dbo.PayoutTrans WITH (NOLOCK)
		WHERE winlostdate BETWEEN @min_winlostdate AND @max_winlostdate
			AND PayoutStatusId IN (4, 5) -- 'Completed', 'Expired'		
		GROUP BY custid

		-- Bet tickets
		UNION ALL
		SELECT t.custid, SUM(t.totalamt) AS totalamt
		FROM #bettrans b
			CROSS APPLY (
				SELECT b.custid, b.winlost - b.actual_stake + b.playercomm AS totalamt
				UNION ALL SELECT b.recommend, b.awinlost + b.comm - b.playercomm
				UNION ALL SELECT b.mrecommend, b.mwinlost + b.acomm - b.comm
				UNION ALL SELECT b.srecommend, b.swinlost + b.scomm - b.acomm
			) t
		GROUP BY t.custid
	) b
	GROUP BY custid
	HAVING SUM(totalamt) <> 0

	DROP TABLE #bettrans
END
GO