/*<info serverAlias="DBRPT-bodb_Report" executers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_rptStatement_14]
	@WinlostDate	SMALLDATETIME
	,@CustIds		VARCHAR(MAX)
AS

/*
	Created: 20190909@Percy
	DB: DBRPT.bodb_Report
	Task: rptStatement - Correct data on bettrans range

	Revisions:
		- 20190909@Percy: Initialize SP [RedmineID: #115377]
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
		CREATE TABLE #CustInfo (custid INT, roleid TINYINT)
		INSERT INTO #CustInfo (custid, roleid)
		SELECT c.custid, c.roleid
		FROM bodb02.dbo.Customer c WITH (NOLOCK)
			INNER JOIN #tmpSuper s ON c.srecommend = s.srecommend

		CREATE CLUSTERED INDEX IX_roleId ON #CustInfo (roleid, custid)
		
		DROP TABLE #tmpSuper
	END
	/* ===== End Get Customer Info ===== */

	/* ===== Get Temp Data ===== */
	BEGIN
		CREATE TABLE #tmpData
		(
			custid			INT
			,VoidAmt		MONEY
			,TransferAmt	MONEY
			,GrandPrize		MONEY
			,Turnover		MONEY
			,NetTurnover	MONEY
			,Winlost		MONEY
			,Comm			MONEY
			,BetCount		INT
			,VoidCount		INT
			,OpeningBalance	MONEY
		)

		-- bet tickets
		SELECT
			b.custid
			,b.recommend
			,b.mrecommend
			,b.srecommend
			,SUM(CASE WHEN b.statusID IN (101,102) AND b.bettype NOT IN (500,903,913,914) THEN ABS(b.stake) ELSE 0 END) AS VoidAmt
			,SUM(CASE WHEN b.statusID IN (111,112,113) THEN ABS(b.stake) ELSE 0 END) AS Turnover
			,0 AS MemberNetTurnover
			,SUM(CASE WHEN b.statusID IN (111,112,113) THEN ABS(b.stake * b.apositiontaking) ELSE 0 END) AS AgentNetTurnover
			,SUM(CASE WHEN b.statusID IN (111,112,113) THEN ABS(b.stake * b.mpositiontaking) ELSE 0 END) AS MasterNetTurnover
			,SUM(CASE WHEN b.statusID IN (111,112,113) THEN ABS(b.stake * b.spositiontaking) ELSE 0 END) AS SuperNetTurnover
			,SUM(b.winlost - b.actual_stake) AS MemberWinloss
			,SUM(b.awinlost) AS AgentWinloss
			,SUM(b.mwinlost) AS MasterWinloss
			,SUM(b.swinlost) AS SuperWinloss
			,SUM(b.playercomm) AS MemberComm
			,SUM(b.comm - b.playercomm) AS AgentComm
			,SUM(b.acomm - b.comm) AS MasterComm
			,SUM(b.scomm - b.acomm) AS SuperComm
			,SUM(CASE WHEN b.statusID IN (111,112,113,103) AND b.bettype <> 500 THEN 1 ELSE 0 END) AS BetCount
			,SUM(CASE WHEN b.statusID IN (101,102) AND b.bettype NOT IN (500,903,913,914) THEN 1 ELSE 0 END) AS VoidCount
		INTO #__bets
		FROM bodb02.dbo.bettrans14 b WITH (NOLOCK)
			CROSS APPLY (
					SELECT c.CustId FROM #CustInfo c WHERE b.custid = c.CustId AND c.roleid = 1
				) AS tmp
		WHERE b.winlostdate = @WinlostDate
		GROUP BY
			b.winlostdate -- group by on index winlostdate, custid
			,b.custid
			,b.recommend
			,b.mrecommend
			,b.srecommend

		INSERT INTO #tmpData
		(
			custid
			,VoidAmt
			,Turnover
			,NetTurnover
			,Winlost
			,Comm
			,BetCount
			,VoidCount
		)
		-- member
		SELECT
			custid
			,SUM(ISNULL(VoidAmt, 0)) AS VoidAmt
			,SUM(ISNULL(Turnover, 0)) AS Turnover
			,SUM(ISNULL(MemberNetTurnover, 0)) AS NetTurnover
			,SUM(ISNULL(MemberWinloss, 0)) AS Winlost
			,SUM(ISNULL(MemberComm, 0)) AS Comm
			,SUM(ISNULL(BetCount, 0)) AS BetCount
			,SUM(ISNULL(VoidCount, 0)) AS VoidCount
		FROM #__bets
		GROUP BY
			custid

		-- agent
		UNION ALL
		SELECT
			recommend
			,0 --SUM(ISNULL(VoidAmt, 0)) AS VoidAmt
			,SUM(ISNULL(Turnover, 0)) AS Turnover
			,SUM(ISNULL(AgentNetTurnover, 0)) AS NetTurnover
			,SUM(ISNULL(AgentWinloss, 0)) AS Winlost
			,SUM(ISNULL(AgentComm, 0)) AS Comm
			,SUM(ISNULL(BetCount, 0)) AS BetCount
			,0 --SUM(ISNULL(VoidCount, 0)) AS VoidCount
		FROM #__bets
		GROUP BY
			recommend

		-- master
		UNION ALL
		SELECT
			mrecommend
			,0 --SUM(ISNULL(VoidAmt, 0)) AS VoidAmt
			,SUM(ISNULL(Turnover, 0)) AS Turnover
			,SUM(ISNULL(MasterNetTurnover, 0)) AS NetTurnover
			,SUM(ISNULL(MasterWinloss, 0)) AS Winlost
			,SUM(ISNULL(MasterComm, 0)) AS Comm
			,SUM(ISNULL(BetCount, 0)) AS BetCount
			,0 --SUM(ISNULL(VoidCount, 0)) AS VoidCount
		FROM #__bets
		GROUP BY
			mrecommend

		-- super
		UNION ALL
		SELECT
			srecommend
			,0 --SUM(ISNULL(VoidAmt, 0)) AS VoidAmt
			,SUM(ISNULL(Turnover, 0)) AS Turnover
			,SUM(ISNULL(SuperNetTurnover, 0)) AS NetTurnover
			,SUM(ISNULL(SuperWinloss, 0)) AS Winlost
			,SUM(ISNULL(SuperComm, 0)) AS Comm
			,SUM(ISNULL(BetCount, 0)) AS BetCount
			,0 --SUM(ISNULL(VoidCount, 0)) AS VoidCount
		FROM #__bets
		GROUP BY
			srecommend

		DROP TABLE #__bets

		-- transfer ticket
		INSERT INTO #tmpData
		(
			custid
			,TransferAmt
			,BetCount
		)
		SELECT
			b.custid
			,SUM(b.winlost - b.actual_stake) AS TransferAmt
			,SUM(1) AS BetCount
		FROM bodb02.dbo.bettrans b WITH (NOLOCK)
			CROSS APPLY (
					SELECT c.CustId FROM #CustInfo c WHERE b.custid = c.CustId
				) AS tmp
		WHERE b.winlostdate = @WinlostDate
			AND b.matchid = 0
			AND b.bettype > 20000
			AND b.bettype NOT IN (23001,23002,23101,23102,23201,23202)
		GROUP BY
			b.custid

		-- Opening Balance
		IF EXISTS (SELECT 1 FROM bodb02.dbo.bettrans WITH (NOLOCK) WHERE matchid = 0 AND custid = 3 AND winlostdate = @WinlostDate)
		BEGIN
			INSERT INTO #tmpData
			(
				custid
				,OpeningBalance
			)
			SELECT
				b.custid
				,SUM(b.winlost - b.actual_stake) AS OpeningBalance
			FROM bodb02.dbo.bettrans b WITH (NOLOCK)
				CROSS APPLY (
					SELECT c.CustId FROM #CustInfo c WHERE b.custid = c.CustId
				) AS tmp
			WHERE b.matchid = 0
				AND b.bettype = 20000
				--AND b.winlostdate = @WinlostDate
			GROUP BY
				b.matchid -- group by on index matchid, custid
				,b.custid
		END
		ELSE
		BEGIN
			SELECT
				b.custid
				,b.recommend
				,b.mrecommend
				,b.srecommend
				,SUM(b.winlost) AS winlost
				,SUM(b.actual_stake) AS actual_stake
				,SUM(b.awinlost) AS awinlost
				,SUM(b.mwinlost) AS mwinlost
				,SUM(b.swinlost) AS swinlost
				,SUM(b.playercomm) AS playercomm
				,SUM(b.comm) AS comm
				,SUM(b.acomm) AS acomm
				,SUM(b.scomm) AS scomm
			INTO #__tmpOpeningBalance
			FROM bodb02.dbo.bettrans b WITH (NOLOCK)
				CROSS APPLY (
					SELECT c.CustId FROM #CustInfo c WHERE b.custid = c.CustId AND c.roleid = 1
				) AS tmp
			WHERE b.matchid = 0
				AND b.winlostdate < @WinlostDate
			GROUP BY
				b.matchid -- group by on index matchid, custid
				,b.custid
				,b.recommend
				,b.mrecommend
				,b.srecommend

			INSERT INTO #tmpData
			(
				custid
				,OpeningBalance
			)
			-- member + transfer of SMA
			SELECT
				custid
				,SUM(winlost - actual_stake + playercomm)
			FROM #__tmpOpeningBalance
			GROUP BY
				custid

			-- agent (bet tickets)
			UNION ALL
			SELECT
				recommend
				,SUM(awinlost + comm - playercomm)
			FROM #__tmpOpeningBalance
			WHERE custid <> recommend
			GROUP BY
				recommend

			-- master (bet tickets)
			UNION ALL
			SELECT
				mrecommend
				,SUM(mwinlost + acomm - comm)
			FROM #__tmpOpeningBalance
			WHERE custid <> mrecommend
			GROUP BY
				mrecommend

			-- super (bet tickets)
			UNION ALL
			SELECT
				srecommend
				,SUM(swinlost + scomm - acomm)
			FROM #__tmpOpeningBalance
			WHERE custid <> srecommend
			GROUP BY
				srecommend

			DROP TABLE #__tmpOpeningBalance
		END

		-- Grand Prize
		INSERT INTO #tmpData
		(
			custid
			,GrandPrize
		)
		SELECT
			p.custid
			,SUM(p.WinAmount) AS GrandPrize
		FROM bodb02.dbo.PayoutTrans p WITH (NOLOCK)
			CROSS APPLY (
					SELECT c.CustId FROM #CustInfo c WHERE p.custid = c.CustId AND c.roleid = 1
				) AS tmp
		WHERE p.winlostdate = @Winlostdate
			AND p.PayoutStatusId IN (4,5) -- 'Completed', 'Expired'
		GROUP BY
			p.custid
	END
	/* ===== End Get Temp Data ===== */

	/* ===== Final Data ===== */
	BEGIN
		CREATE TABLE #rptStatement
		(
			CustId			INT
			,VoidAmt		MONEY
			,TransferAmt	MONEY
			,Turnover		MONEY
			,NetTurnover	MONEY
			,Winlost		MONEY
			,Comm			MONEY
			,OpeningBalance	MONEY
			,ClosingBalance	MONEY
			,GrandPrize		MONEY
		)
		
		INSERT INTO #rptStatement
		(
			CustId
			,VoidAmt
			,TransferAmt
			,Turnover
			,NetTurnover
			,Winlost
			,Comm
			,OpeningBalance
			,ClosingBalance
			,GrandPrize
		)
		SELECT
			custid
			,SUM(ISNULL(VoidAmt, 0)) AS VoidAmt
			,SUM(ISNULL(TransferAmt, 0)) AS TransferAmt
			,SUM(ISNULL(Turnover, 0)) AS Turnover
			,SUM(ISNULL(NetTurnover, 0)) AS NetTurnover
			,SUM(ISNULL(Winlost, 0)) AS Winlost
			,SUM(ISNULL(Comm, 0)) AS Comm
			,SUM(ISNULL(OpeningBalance, 0)) AS OpeningBalance
			,SUM(ISNULL(Openingbalance, 0) + ISNULL(Winlost, 0) + ISNULL(Comm, 0) + ISNULL(TransferAmt, 0)) AS ClosingBalance
			,SUM(ISNULL(GrandPrize, 0)) AS GrandPrize
		FROM #tmpData
		GROUP BY
			custid
		HAVING
			DATEPART(WEEKDAY, @WinlostDate) = 7
			OR SUM(ISNULL(BetCount, 0) + ISNULL(BetCount, 0)) > 0

		DROP TABLE #tmpData
	END
	/* ===== End Final Data ===== */

	/* ===== Compare and Correct Data ===== */
	BEGIN
		DECLARE @RowCount INT

		;WITH CTE_rptStatement AS
		(
			SELECT
				r.CustId
				,ISNULL(r.OpeningBalance, 0) AS OpeningBalance
				,ISNULL(r.VoidAmt, 0) AS VoidAmt
				,ISNULL(r.Turnover, 0) AS Turnover
				,ISNULL(r.NetTurnover, 0) AS NetTurnover
				,ISNULL(r.TransferAmt, 0) AS TransferAmt
				,ISNULL(r.Winlost, 0) AS Winlost
				,ISNULL(r.Comm, 0) AS Comm
				,ISNULL(r.ClosingBalance, 0) AS ClosingBalance
				,ISNULL(r.GrandPrize, 0) AS GrandPrize
			FROM dbo.rptStatement r WITH (NOLOCK)
				CROSS APPLY (
					SELECT c.CustId FROM #CustInfo c WHERE r.custid = c.CustId
				) AS tmp
			WHERE r.winlostdate = @WinlostDate
		)
		SELECT @RowCount = COUNT(1)
		FROM CTE_rptStatement s
			FULL OUTER JOIN #rptStatement t ON s.CustId = t.CustId
		WHERE s.CustId IS NULL
			OR t.CustId IS NULL
			OR t.OpeningBalance	<> s.OpeningBalance
			OR t.VoidAmt		<> s.VoidAmt
			OR t.Turnover		<> s.Turnover
			OR t.NetTurnover	<> s.NetTurnover
			OR t.TransferAmt	<> s.TransferAmt
			OR t.Winlost		<> s.Winlost
			OR t.Comm			<> s.Comm
			OR t.ClosingBalance	<> s.ClosingBalance
			OR t.GrandPrize		<> s.GrandPrize

		IF @RowCount <> 0
		BEGIN
			MERGE dbo.rptStatement AS SOURCE
			USING #rptStatement AS TARGET
				ON		SOURCE.winlostdate = @WinlostDate
					AND SOURCE.CustId = TARGET.CustId
					AND EXISTS (SELECT 1 FROM #CustInfo c WHERE SOURCE.CustId = c.CustId)
			WHEN MATCHED AND
				(
						ISNULL(SOURCE.OpeningBalance, 0)	<> ISNULL(TARGET.OpeningBalance, 0)
					OR	ISNULL(SOURCE.VoidAmt, 0)			<> ISNULL(TARGET.VoidAmt, 0)
					OR	ISNULL(SOURCE.Turnover, 0)			<> ISNULL(TARGET.Turnover, 0)
					OR	ISNULL(SOURCE.NetTurnover, 0)		<> ISNULL(TARGET.NetTurnover, 0)
					OR	ISNULL(SOURCE.TransferAmt, 0)		<> ISNULL(TARGET.TransferAmt, 0)
					OR	ISNULL(SOURCE.Winlost, 0)			<> ISNULL(TARGET.Winlost, 0)
					OR	ISNULL(SOURCE.Comm, 0)				<> ISNULL(TARGET.Comm, 0)
					OR	ISNULL(SOURCE.ClosingBalance, 0)	<> ISNULL(TARGET.ClosingBalance, 0)
					OR	ISNULL(SOURCE.GrandPrize, 0)		<> ISNULL(TARGET.GrandPrize, 0)
				)
				THEN UPDATE
				SET SOURCE.OpeningBalance	= TARGET.OpeningBalance
					,SOURCE.VoidAmt			= TARGET.VoidAmt
					,SOURCE.Turnover		= TARGET.Turnover
					,SOURCE.NetTurnover		= TARGET.NetTurnover
					,SOURCE.TransferAmt		= TARGET.TransferAmt
					,SOURCE.Winlost			= TARGET.Winlost
					,SOURCE.Comm			= TARGET.Comm
					,SOURCE.ClosingBalance	= TARGET.ClosingBalance
					,SOURCE.GrandPrize		= TARGET.GrandPrize
			WHEN NOT MATCHED BY TARGET THEN INSERT
				(
					winlostdate,CustId,OpeningBalance,VoidAmt,Turnover,NetTurnover,TransferAmt,Winlost,Comm,ClosingBalance,GrandPrize
				)
				VALUES
				(
					@WinLostDate,CustId,OpeningBalance,VoidAmt,Turnover,NetTurnover,TransferAmt,Winlost,Comm,ClosingBalance,GrandPrize
				)
			WHEN NOT MATCHED BY SOURCE
				AND SOURCE.winlostdate = @WinlostDate
				AND EXISTS (SELECT 1 FROM #CustInfo c WHERE SOURCE.CustId = c.CustId)
				THEN DELETE;
		END
	END
	/* ===== End Compare and Correct Data ===== */

	DROP TABLE #CustInfo
	DROP TABLE #rptStatement
END
GO