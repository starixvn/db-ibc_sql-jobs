/*<info serverAlias="DBRPT-bodb_Report" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_DailyRptStatement_CheckData]
	@WinlostDate		DATE
	,@isCheckDataOnly	BIT = 1
AS

/*  
	Created: 20141202@Tom.Vo
	Task: Check data on rptStatement table
	DB: DBRPT.bodb_Report

	Revisions:
		- @20150311@Tom: Change option ReadPast to NOLOCK when select data on bettrans table
		- @20150402@Tom: Change option NOLOCK to ROWLOCK table hint when select on bettrans to prevent dirty read by NOLOCK
		- 20150727@Sophia: Apply Bettrade, exclude ticket Bettrade Comm (903) for Void/reject [#36905]
		- 20150901@Sophia: Apply Colossus Bets [#42428]
		- 20151019@Sophia: Apply AG Casino - Add table BettransLC [#43810]
							Apply MGC - RNG Casino - Add table BettransRNG [#43549]						 
		- 20151109@Sophia: Change Sporttype of Microgaming RNG Casino [RedmineId: #46450] 
		- 20160328@Sophia: Check status Of PayOutTrans, get status Completed and Expired [Redmine: #54643]
		- 20170323@Percy: Apply Cash Out [RedmineID: #72164]
		- 20190128@Sophia: Fix correct data at Void Block code [RedmineID: #107365]
		- 20190801@Percy: Check OpeningTotalBalance for Credit Collection [RedmineID: #109293]
		- 20190912@Bobby: Implement headline - Statement [Redmine: #119289]
		- 20191111@Bobby: Correct BU rule - Statement [Redmine: #119289]
		- 20191212@Percy: Get UplineId (HeadlineId) from ExtraPT Setting table [RedmineID: #118962]
		- 20200619@Percy: Correct OpeningBalance on winlostdate = saturday [RedmineID: #134251]
		- 20201008@Percy: Get SMA from bettrans instead of custinfo table [RedmineID: #142953]
*/
BEGIN

	SET NOCOUNT ON

	DECLARE @CurrentBU_Date SMALLDATETIME
		,@CurrentMB_Date	SMALLDATETIME
		,@_Winlostdate		SMALLDATETIME
		,@_Saturday			SMALLDATETIME

	CREATE TABLE #rptStatementTable (
		Custid				INT PRIMARY KEY
		,OpeningBalance		MONEY	NULL
		,VoidAmt			MONEY	NULL
		,Turnover			MONEY	NULL
		,netTurnover		MONEY	NULL
		,TransferAmt		MONEY	NULL
		,Winlost			MONEY	NULL
		,Comm				MONEY	NULL
		,ClosingBalance		MONEY	NULL
		,BetCount			INT		DEFAULT 0
		,TransCount			INT		DEFAULT 0
		,VoidCount			INT		DEFAULT 0
		,GrandPrize			MONEY	NULL
		,OpeningTotalBalance DECIMAL(37,4)	NULL
	)
	
	DECLARE @BalanceUpDays AS TABLE (BalanceUpDay DATE, MoveBetDay DATE)
	
	-- GET BU & MB Dates
	INSERT INTO @BalanceUpDays (BalanceUpDay, MoveBetDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay

	SELECT @CurrentBU_Date	= BalanceUpDay
		,@CurrentMB_Date	= MoveBetDay
	FROM @BalanceUpDays

	-- GET the previous Saturday
	SELECT @_Winlostdate = @Winlostdate

	-- CHECK validation DATE
	IF @_Winlostdate < @CurrentBU_Date
		RETURN

	-- 1. SUM BET/VOID/TRANSFER
	-- TRANSFER: Headline, Member & SMA
	-- BET/VOID: Member
	;
	WITH bettrans_temp AS (
		SELECT b.custid,b.recommend,b.mrecommend,b.srecommend
			,bet.transIndicator
			,SUM(bet.stake) AS stake
			,SUM(b.winlost-b.actual_stake) as winlost
			,SUM(b.playercomm) AS playercomm
			,SUM(b.comm) AS comm
			,SUM(b.acomm) AS acomm
			,SUM(b.scomm) AS scomm
			,SUM(b.awinlost) AS awinlost
			,SUM(b.mwinlost) AS mwinlost
			,SUM(b.swinlost) AS swinlost
			,SUM(bet.stake*b.apositiontaking) AS anet_stake
			,SUM(bet.stake*b.mpositiontaking) AS mnet_stake
			,SUM(bet.stake*b.spositiontaking) AS snet_stake
		FROM
			bodb02.dbo.bettrans14 b WITH(NOLOCK)
		OUTER APPLY (
			SELECT 
				CASE 
					WHEN b.statusID IN(103) THEN 0 -- Refund
					ELSE ABS(b.stake)
				END AS stake
				,CASE 
					WHEN b.statusID IN (101,102) AND b.bettype NOT IN (903, 500, 913, 914) THEN POWER(2*1,2) --> void bet
					WHEN b.statusID NOT IN (101,102) THEN POWER(2*1,3) --> normal bet
					ELSE 0
					END AS transIndicator
				
		) AS bet
		WHERE
			b.winlostdate = @_Winlostdate
			AND bet.transIndicator > 0
		GROUP BY b.winlostdate,b.custid,b.recommend,b.mrecommend,b.srecommend
			,bet.transIndicator
	)
	INSERT INTO #rptStatementTable(
		Custid
		,BetCount
		,Turnover
		,netTurnover
		,Winlost
		,Comm
		,VoidCount
		,VoidAmt
	)
	SELECT
		c.custid
		,SUM(bet.betIndicator) AS BetCount
		,SUM(b.stake * bet.betIndicator) AS Turnover
		,SUM(c.net_stake * bet.betIndicator) AS netTurnover
		,SUM(c.winlost * bet.betIndicator) AS winlost
		,SUM(c.comm * bet.betIndicator) AS comm
		,SUM(c.voidIndicator) AS VoidCount
		,SUM(b.stake * c.voidIndicator) AS VoidAmt
	FROM
		bettrans_temp b
	OUTER APPLY (
		SELECT (4 & transIndicator)/4 AS voidIndicator
			,(8 & transIndicator)/8 AS betIndicator
	) AS bet
	OUTER APPLY (
		SELECT b.custid						AS custid
			, 0								AS net_stake
			, b.winlost						AS winlost
			, b.playercomm					AS comm
			, bet.voidIndicator				AS voidIndicator
		UNION ALL
		SELECT b.recommend, anet_stake, awinlost, comm - playercomm, 0
		UNION ALL
		SELECT b.mrecommend, mnet_stake, mwinlost, acomm - comm, 0
		UNION ALL
		SELECT b.srecommend, snet_stake, swinlost, scomm -acomm, 0
	) AS c
	GROUP BY
		c.custid
	
	-- 2. TRANSFER
	;
	WITH CTE_Transfer AS
	(
		SELECT custid
			,COUNT(1) AS TransCount
			,SUM(winlost - actual_stake) AS TransferAmt
		FROM bodb02.dbo.bettrans WITH (NOLOCK)
		WHERE matchid = 0
			AND bettype > 20000
			AND winlostdate = @_Winlostdate
		GROUP BY custid
	)
	MERGE #rptStatementTable AS TGR
	USING CTE_Transfer AS SRC
	ON TGR.custid = SRC.custid
	WHEN MATCHED THEN
		UPDATE 
		SET TransCount = SRC.TransCount
			,TransferAmt = SRC.TransferAmt
	WHEN NOT MATCHED BY TARGET THEN
		INSERT (custid, TransCount, TransferAmt)
		VALUES (
			SRC.custid
			, SRC.TransCount
			, SRC.TransferAmt
		)
	;

	-- 3. SUM Grand Prize
	;
	WITH CTE_GrandPrize	AS (
		SELECT custid
			,SUM(WinAmount) AS GrandPrize
		FROM
			DBACC.bodb02.dbo.PayoutTrans WITH(NOLOCK) 
		WHERE
			winlostdate = @_Winlostdate			
			AND PayoutStatusId IN (4, 5)  ----- 'Completed', 'Expired'

		GROUP BY custid
	)
	MERGE #rptStatementTable AS TGR
	USING CTE_GrandPrize AS SRC
	ON TGR.custid = SRC.custid
	WHEN MATCHED THEN
		UPDATE 
		SET GrandPrize = SRC.GrandPrize
	WHEN NOT MATCHED BY TARGET THEN
		INSERT (custid, GrandPrize)
		VALUES (
			SRC.custid
			, SRC.GrandPrize
		)
	;

	-- 4. SUM OPENNING [balance & total balance]
	CREATE TABLE #rptOpenningBalanceTable (custid INT, roleid TINYINT, recommend INT, mrecommend INT, srecommend INT, balance MONEY)
	BEGIN
		-- The BU date & next Saturday in rptStatement
		SELECT @_Saturday = DATEADD (DD, 7-DATEPART(DW, @CurrentBU_Date), @CurrentBU_Date)
		
		IF @_Winlostdate BETWEEN @CurrentBU_Date AND @_Saturday -- Friday & Saturday
		BEGIN			
			INSERT #rptOpenningBalanceTable (custid, balance)
			SELECT custid, balance
			FROM (
				SELECT rpt.custid
					, CASE WHEN rpt.winlostdate < @_Winlostdate THEN rpt.ClosingBalance ELSE rpt.OpeningBalance END AS balance
					, ROW_NUMBER() OVER (PARTITION BY rpt.CustID ORDER BY rpt.Winlostdate ASC) AS Num
				FROM dbo.rptStatement rpt WITH(NOLOCK)
				WHERE rpt.winlostdate >= @CurrentBU_Date AND rpt.winlostdate <= @_Saturday
			) AS tmp 
			WHERE tmp.Num = 1
		END
		-- The last Saturday in rptStatement
		ELSE
		BEGIN
			INSERT #rptOpenningBalanceTable (custid, balance)
			SELECT custid, balance
			FROM (
				SELECT rpt.custid, rpt.ClosingBalance AS balance
					, ROW_NUMBER() OVER (PARTITION BY rpt.CustID ORDER BY rpt.Winlostdate DESC) AS Num
				FROM dbo.rptStatement rpt WITH(NOLOCK)
				WHERE rpt.winlostdate >= @_Saturday AND  rpt.winlostdate < @_Winlostdate
			) AS tmp 
			WHERE tmp.Num = 1
		END

		UPDATE t
		SET t.recommend = b.recommend, t.mrecommend = b.mrecommend, t.srecommend = b.srecommend
			,t.roleid = CASE b.custid
							WHEN b.srecommend THEN 4
							WHEN b.mrecommend THEN 3
							WHEN b.recommend THEN 2
							ELSE 1 END -- include member & headline
		FROM #rptOpenningBalanceTable t
			CROSS APPLY (
				SELECT TOP 1 b.custid, b.recommend, b.mrecommend, b.srecommend
				FROM bodb02.dbo.bettrans b WITH (NOLOCK)
				WHERE t.custid = b.custid
			) b;

		;WITH CTE_Balance (custid, OpeningBalance, OpeningTotalBalance) AS
		(
			SELECT bal.custid
				, SUM(bal.balance)
				, SUM(bal.totalbalance)
			FROM #rptOpenningBalanceTable b
				CROSS APPLY (
					SELECT POWER(2*1, b.roleid) AS ownerIndicator
				) AS bet
				CROSS APPLY (
					SELECT b.custid, 1 AS levelID, b.balance, b.balance AS totalbalance
					UNION ALL
					SELECT b.recommend, 2, b.balance * CAST(bet.ownerIndicator & 4 AS BIT)/1, b.balance
					UNION ALL
					SELECT b.mrecommend, 3, b.balance * CAST(bet.ownerIndicator & 8 AS BIT)/1, b.balance
					UNION ALL
					SELECT b.srecommend, 4, b.balance * CAST(bet.ownerIndicator & 16 AS BIT)/1, b.balance
				) AS bal
			WHERE bal.levelID >= b.roleid
				AND bal.custid > 0
			GROUP BY bal.custid
		)
		MERGE #rptStatementTable AS TGR
		USING CTE_Balance AS SRC
		ON TGR.custid = SRC.custid
		WHEN MATCHED THEN
			UPDATE 
			SET OpeningBalance = SRC.OpeningBalance
			,OpeningTotalBalance = SRC.OpeningTotalBalance
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (custid, OpeningBalance, OpeningTotalBalance)
			VALUES (SRC.custid, SRC.OpeningBalance, SRC.OpeningTotalBalance)
		;
	END

	--5. Headline - Openning total balance
	;WITH CTE_HeadlineTotalBalance AS 
	(
		SELECT e.UplineId, SUM(ISNULL(tmp.OpeningTotalBalance, 0)) AS OpeningTotalBalance
		FROM #rptStatementTable tmp
			CROSS APPLY (
				SELECT TOP (1) ag.UplineId
				FROM bodb02.dbo.Acc_GroupExtraPTSetting ag WITH (NOLOCK)
				WHERE tmp.Custid = ag.SuperId
					AND @Winlostdate BETWEEN ag.FromDate AND ag.ToDate
			) e
		GROUP BY e.UplineId
	)
	UPDATE tmp
	SET tmp.OpeningTotalBalance = ISNULL(tmp.OpeningTotalBalance, 0) + ISNULL(bal.OpeningTotalBalance, 0)
	FROM #rptStatementTable tmp
	INNER JOIN CTE_HeadlineTotalBalance bal ON tmp.Custid = bal.UplineId
	
	-- 6. INSERT into #rptStatementCompare
	CREATE TABLE #rptStatementCompare (
		Custid				INT PRIMARY KEY
		,Winlostdate		SMALLDATETIME
		,OpeningBalance		MONEY	NULL
		,VoidAmt			MONEY	NULL
		,Turnover			MONEY	NULL
		,netTurnover		MONEY	NULL
		,TransferAmt		MONEY	NULL
		,Winlost			MONEY	NULL
		,Comm				MONEY	NULL
		,ClosingBalance		MONEY	NULL
		,GrandPrize			MONEY	NULL
		,OpeningTotalBalance DECIMAL(37,4)	NULL
	)

	INSERT INTO #rptStatementCompare(
		Winlostdate
		, Custid
		, Openingbalance
		, Turnover
		, NetTurnover
		, Winlost
		, Comm
		, Voidamt
		, TransferAmt
		, GrandPrize
		, ClosingBalance
		, OpeningTotalBalance
	)
	SELECT 
		@_Winlostdate AS Winlostdate
		,tmp.Custid
		,(ISNULL(tmp.Openingbalance, 0)) AS [OpeningBalance]
		,(CASE WHEN tmp.BetCount > 0 THEN tmp.Turnover ELSE NULL END) AS [Turnover]
		,(CASE WHEN tmp.BetCount > 0 THEN tmp.NetTurnover ELSE NULL END) AS [NetTurnover]
		,(CASE WHEN tmp.BetCount > 0 THEN tmp.Winlost ELSE NULL END) AS [Winlost]
		,(CASE WHEN tmp.BetCount > 0 THEN tmp.Comm ELSE NULL END) AS [Comm]
		,(CASE WHEN tmp.VoidCount > 0 THEN tmp.Voidamt ELSE NULL END) AS [VoidAmt]
		,(CASE WHEN tmp.TransCount > 0 THEN tmp.TransferAmt ELSE NULL END) AS [TransferAmt]
		,(tmp.GrandPrize) AS GrandPrize
		,(ISNULL(tmp.Openingbalance, 0) + ISNULL(tmp.[Winlost], 0) + ISNULL(tmp.[Comm], 0) + ISNULL(tmp.[TransferAmt], 0)) AS ClosingBalance
		,(ISNULL(OpeningTotalBalance,0)) AS OpeningTotalBalance
	
	FROM 
		#rptStatementTable tmp
	WHERE 
		DATEPART(DW,@_Winlostdate) = 7
		OR
		(ISNULL(tmp.VoidCount, 0)) <> 0
		OR (ISNULL(tmp.BetCount, 0)) <> 0
		OR (ISNULL(tmp.TransCount, 0)) <> 0
		OR (ISNULL(tmp.GrandPrize, 0)) <> 0
	
	
	--7. COMPARE & COLLECT ERROR--------------------------------------
	CREATE TABLE #custComparision (
		custid			INT
		, ErrorCode		INT
		, SubError		INT DEFAULT(0)
		, beforeAmt		DECIMAL(20,4) DEFAULT(0)
		, afterAmt		DECIMAL(20,4) DEFAULT(0)
	)

	CREATE CLUSTERED INDEX CIC_CustID ON #custComparision(custid)

	INSERT INTO #custComparision(custid, ErrorCode, SubError, beforeAmt, afterAmt)
	SELECT custid, ErrorCode, SubError, beforeAmt, afterAmt
	FROM (
		--1. CHECK missed CUST
		SELECT tmp.custid
			,10 AS ErrorCode
			,11 AS SubError
			,0 AS beforeAmt
			,tmp.Custid AS afterAmt
		FROM #rptStatementCompare tmp
		LEFT JOIN dbo.rptStatement rpt WITH(NOLOCK) 
			ON tmp.custid = rpt.custid AND rpt.winlostdate = @_Winlostdate
		WHERE rpt.custid IS NULL

		--1.2 CHECK removed CUST
		UNION ALL
		SELECT rpt.custid
			,10 AS ErrorCode
			,12 AS SubError
			,rpt.custid AS beforeAmt
			,0 AS afterAmt
		FROM dbo.rptStatement rpt WITH(NOLOCK)
		LEFT JOIN #rptStatementCompare tmp 
			ON tmp.custid = rpt.custid
		WHERE rpt.winlostdate = @_Winlostdate
			AND tmp.custid IS NULL

		
		--2. CHECK wrong BET
		UNION ALL
		SELECT tmp.custid
			, 20 AS ErrorCode
			, diff.SubError
			, diff.beforeAmt
			, diff.afterAmt
		FROM #rptStatementCompare tmp
		INNER JOIN dbo.rptStatement rpt WITH(NOLOCK) ON tmp.custid = rpt.custid
		CROSS APPLY (
			--Turnover
			SELECT rpt.turnover AS beforeAmt
				, tmp.turnover AS afterAmt
				, 21 AS SubError
			WHERE tmp.turnover <> rpt.turnover

			--NetTurnover
			UNION ALL
			SELECT rpt.NetTurnover AS beforeAmt
				, tmp.NetTurnover AS afterAmt
				, 22 AS SubError
			WHERE tmp.NetTurnover <> rpt.NetTurnover

			--winlost
			UNION ALL
			SELECT rpt.winlost AS beforeAmt
				, tmp.winlost AS afterAmt
				, 23 AS SubError
			WHERE tmp.winlost <> rpt.winlost

			--Comm
			UNION ALL
			SELECT rpt.Comm AS beforeAmt
				, tmp.Comm AS afterAmt
				, 24 AS SubError
			WHERE tmp.Comm <> rpt.Comm
		) AS diff
		WHERE rpt.winlostdate = @_Winlostdate
			AND (
				tmp.turnover <> rpt.turnover
				OR tmp.NetTurnover <> rpt.NetTurnover
				OR tmp.winlost <> rpt.winlost
				OR tmp.Comm <> rpt.Comm
			)

		--3. CHECK wrong VOID
		UNION ALL
		SELECT tmp.custid
			,30 AS ErrorCode
			,0 AS SubError
			,rpt.Voidamt AS beforeAmt
			,tmp.Voidamt AS afterAmt
		FROM #rptStatementCompare tmp
		INNER JOIN dbo.rptStatement rpt WITH(NOLOCK) ON tmp.custid = rpt.custid
		WHERE rpt.winlostdate = @_Winlostdate
			AND tmp.Voidamt <> rpt.Voidamt
		
		--4. CHECK wrong TRANSFER
		UNION ALL
		SELECT tmp.custid
			,40 AS ErrorCode
			,0 AS SubError
			,rpt.TransferAmt AS beforeAmt
			,tmp.TransferAmt AS afterAmt
		FROM #rptStatementCompare tmp
		INNER JOIN dbo.rptStatement rpt WITH(NOLOCK) ON tmp.custid = rpt.custid
		WHERE rpt.winlostdate = @_Winlostdate
			AND tmp.TransferAmt <> rpt.TransferAmt

		--5. CHECK wrong GRAND_PRIZE
		UNION ALL
		SELECT tmp.custid
			,50 AS ErrorCode
			,0 AS SubError
			,rpt.GrandPrize AS beforeAmt
			,tmp.GrandPrize AS afterAmt
		FROM #rptStatementCompare tmp
		INNER JOIN dbo.rptStatement rpt WITH(NOLOCK) ON tmp.custid = rpt.custid
		WHERE rpt.winlostdate = @_Winlostdate
			AND tmp.GrandPrize <> rpt.GrandPrize

		--6. CHECK wrong OPENING_BALANCE
		UNION ALL
		SELECT tmp.custid
			,60 AS ErrorCode
			,diff.SubError
			,diff.beforeAmt
			,diff.afterAmt
		FROM #rptStatementCompare tmp
		INNER JOIN dbo.rptStatement rpt WITH(NOLOCK) ON tmp.custid = rpt.custid
		CROSS APPLY (
			--Openingbalance
			SELECT rpt.Openingbalance AS beforeAmt
				, tmp.Openingbalance AS afterAmt
				, 61 AS SubError
			WHERE tmp.Openingbalance <> rpt.Openingbalance

			--OpeningTotalBalance
			UNION ALL
			SELECT rpt.OpeningTotalBalance AS beforeAmt
				, tmp.OpeningTotalBalance AS afterAmt
				, 62 AS SubError
			WHERE tmp.OpeningTotalBalance <> rpt.OpeningTotalBalance
			
		) AS diff
		WHERE rpt.winlostdate = @_Winlostdate
			AND (
				tmp.Openingbalance <> rpt.Openingbalance
				OR tmp.OpeningTotalBalance <> rpt.OpeningTotalBalance
			)
	) AS tmp
	--------------------END COMPARE & COLLECT ERROR--------------------------------------

	--8. CHECK OR CORRECT rptStatement
	IF @isCheckDataOnly = 1
	BEGIN
		----------ERROR SUMMARY--------------
		SELECT err.ErrorCode
			, COUNT(1) NumOfItem
		FROM #custComparision err
		GROUP BY err.ErrorCode

		----------ERROR DETAIL--------------
		SELECT 
			CASE 
				WHEN err.ErrorCode = 10 THEN 'Wrong Cust' 
				WHEN err.ErrorCode = 20 THEN 'Wrong BET' 
				WHEN err.ErrorCode = 30 THEN 'Wrong Void/Reject/Refund' 
				WHEN err.ErrorCode = 40 THEN 'Wrong Transfer' 
				WHEN err.ErrorCode = 50 THEN 'Wrong Grand Prize' 
				WHEN err.ErrorCode = 60 THEN 'Wrong Balance' 
				ELSE 'Unknown' 
			END 
			+ CASE 
				WHEN err.SubError = 11 THEN ' - Missed' 
				WHEN err.SubError = 12 THEN ' - Removed' 
				WHEN err.SubError = 21 THEN ' - Turnover' 
				WHEN err.SubError = 22 THEN ' - NetTurnover' 
				WHEN err.SubError = 23 THEN ' - Winlost' 
				WHEN err.SubError = 24 THEN ' - Comm' 
				WHEN err.SubError = 61 THEN ' - OpeningBalance' 
				WHEN err.SubError = 62 THEN ' - OpeningTotalBalance' 
				WHEN err.SubError = 0 THEN '' 
				ELSE ' - Unknown'
				END
			AS Reason
			, err.custid
			, err.beforeAmt
			, err.afterAmt
			, ci.roleid
		FROM #custComparision err
		LEFT JOIN bodb02.dbo.custInfo ci (nolock) on err.Custid = ci.custid
		ORDER BY err.ErrorCode
			, err.SubError
	END
	ELSE 
	BEGIN
		-- Correct Data
		MERGE INTO dbo.rptStatement AS TGR
		USING #rptStatementCompare SRC
		ON TGR.Winlostdate = SRC.Winlostdate AND TGR.Custid = SRC.Custid
		WHEN MATCHED AND TGR.Winlostdate = @_Winlostdate THEN
		UPDATE 
			SET OpeningBalance = SRC.OpeningBalance
				,VoidAmt = SRC.VoidAmt
				,Turnover = SRC.Turnover
				,NetTurnover = SRC.NetTurnover
				,TransferAmt = SRC.TransferAmt
				,Winlost = SRC.Winlost
				,Comm = SRC.Comm
				,ClosingBalance = SRC.ClosingBalance
				,GrandPrize = SRC.GrandPrize
				,OpeningTotalBalance = SRC.OpeningTotalBalance

		WHEN NOT MATCHED BY TARGET THEN
		INSERT (
				Winlostdate
				,Custid
				,OpeningBalance
				,VoidAmt
				,Turnover
				,NetTurnover
				,TransferAmt
				,Winlost
				,Comm
				,ClosingBalance
				,GrandPrize
				,OpeningTotalBalance
			)
		VALUES (
				SRC.Winlostdate
				,SRC.Custid
				,SRC.OpeningBalance
				,SRC.VoidAmt
				,SRC.Turnover
				,SRC.NetTurnover
				,SRC.TransferAmt
				,SRC.Winlost
				,SRC.Comm
				,SRC.ClosingBalance
				,SRC.GrandPrize
				,SRC.OpeningTotalBalance
			) 
				
		WHEN NOT MATCHED BY SOURCE 
				AND TGR.Winlostdate = @_Winlostdate AND DATEPART(DW,@_Winlostdate) <> 7 THEN
			DELETE
		;
	END

	DROP TABLE #rptOpenningBalanceTable
	DROP TABLE #rptStatementTable
	DROP TABLE #custComparision
	DROP TABLE #rptStatementCompare
END
GO