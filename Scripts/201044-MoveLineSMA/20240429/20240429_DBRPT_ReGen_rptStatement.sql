/*<info serverAlias="DBRPT-bodb_Report" isNested="1"></info>*/
/*
	Created by: 20240429@Bobby
	Task: 201044 - Move SMA lines
	DB: DBTXN.bodb02
		
*/

--TODO: Run script after moving SMA done on bettrans14, transfer COMPLETED
USE bodb_Report;
GO
BEGIN

	SET NOCOUNT ON;

	DECLARE @CurrentBU_Date SMALLDATETIME
		,@CurrentMB_Date	SMALLDATETIME
		,@_Winlostdate		SMALLDATETIME
		,@_Saturday			SMALLDATETIME
		,@_AffectedCust		INT = 0

	DROP TABLE IF EXISTS #rptOpenningBalanceTable
	DROP TABLE IF EXISTS #rptStatementTable

	CREATE TABLE #rptOpenningBalanceTable (custid INT, roleid TINYINT, recommend INT, mrecommend INT, srecommend INT, balance MONEY)
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
		
	-- GET BU & MB Dates
	DECLARE @BalanceUpDays AS TABLE (BalanceUpDay DATE, MoveBetDay DATE)
	INSERT INTO @BalanceUpDays (BalanceUpDay, MoveBetDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay

	SELECT @CurrentBU_Date	= BalanceUpDay
		,@CurrentMB_Date	= MoveBetDay
	FROM @BalanceUpDays

	DROP TABLE IF EXISTS #affectedCustTmp;
	CREATE TABLE #affectedCustTmp(CustId INT, RoleId TINYINT, recommend INT, mrecommend INT, srecommend INT);

	INSERT #affectedCustTmp(custid, roleid, recommend, mrecommend, srecommend)
	SELECT DISTINCT custid, roleid, recommend, mrecommend, srecommend
	FROM bodb02.dbo.Customer c WITH(NOLOCK)
	WHERE username IN ('USTM','MUSDT','XYZUSDT','231')

	SET @_AffectedCust = @@ROWCOUNT;

	DECLARE @SuperProcess TABLE(SuperId INT);
	INSERT INTO @SuperProcess(SuperId)
	SELECT DISTINCT custid FROM #affectedCustTmp WHERE roleid = 4;

	--select * from #rptOpenningBalanceTable
	DROP TABLE IF EXISTS #temp
	DROP TABLE IF EXISTS #temp2

	CREATE TABLE #temp (CustId INT, Balance MONEY, TotalBalance MONEY)
	CREATE CLUSTERED INDEX CIX_temp ON #temp (CustId)

	CREATE TABLE #temp2 (CustId INT, OpeningBalance MONEY, OpeningTotalBalance MONEY)
	CREATE CLUSTERED INDEX CIX_temp2 ON #temp2 (CustId)

	DROP TABLE IF EXISTS #rptStatementCompare;
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
	);

	DROP TABLE IF EXISTS #tmpUpdateCust;
	CREATE TABLE #tmpUpdateCust(CustId INT, Winlostdate	SMALLDATETIME);

	SELECT @CurrentBU_Date, @CurrentMB_Date
	-- GET start day
	DECLARE @startTime DATETIME;
	SELECT @_Winlostdate = @CurrentBU_Date

	WHILE (@_Winlostdate <= @CurrentMB_Date)
	BEGIN
		SET @startTime = CURRENT_TIMESTAMP;

		TRUNCATE TABLE #rptOpenningBalanceTable;
		TRUNCATE TABLE #rptStatementCompare;
		TRUNCATE TABLE #rptStatementTable;
		TRUNCATE TABLE #tmpUpdateCust;

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
				INNER JOIN @SuperProcess s ON s.SuperId = b.srecommend
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
			SELECT t.custid
				,COUNT(1) AS TransCount
				,SUM(t.winlost - t.actual_stake) AS TransferAmt
			FROM bodb02.dbo.transfer t WITH (NOLOCK)
			INNER JOIN #affectedCustTmp tmp ON tmp.custid = t.custid
			WHERE t.bettype > 20000
				AND t.winlostdate = @_Winlostdate
				AND t.winlostdate >= @CurrentBU_Date
			GROUP BY t.custid
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
		
		BEGIN
			-- The BU date & next Saturday in rptStatement
			SELECT @_Saturday = DATEADD (DD, 7-DATEPART(DW, @CurrentBU_Date), @CurrentBU_Date)
		
			IF @_Winlostdate BETWEEN @CurrentBU_Date AND @_Saturday -- Friday & Saturday
			BEGIN			
				INSERT INTO #rptOpenningBalanceTable (custid, roleid, recommend, mrecommend, srecommend, balance)
				SELECT tmp.custid, CASE WHEN c.roleid = 0 THEN 1 ELSE c.roleid END AS roleid, c.recommend, c.mrecommend, c.srecommend, tmp.balance
				FROM (
					SELECT rpt.custid
						, CASE WHEN rpt.winlostdate < @_Winlostdate THEN rpt.ClosingBalance ELSE rpt.OpeningBalance END AS balance
						, ROW_NUMBER() OVER (PARTITION BY rpt.CustID ORDER BY rpt.Winlostdate ASC) AS Num
					FROM dbo.rptStatement rpt WITH(NOLOCK)
					INNER JOIN #affectedCustTmp tmp ON tmp.custid = rpt.custid
					WHERE rpt.winlostdate >= @CurrentBU_Date AND rpt.winlostdate <= @_Saturday
				) AS tmp 
					LEFT JOIN bodb02.dbo.custInfo c WITH (NOLOCK) ON tmp.custid = c.custid
				WHERE tmp.Num = 1
			END
			-- The last Saturday in rptStatement
			ELSE
			BEGIN
				INSERT INTO #rptOpenningBalanceTable (custid, roleid, recommend, mrecommend, srecommend, balance)
				SELECT tmp.custid, CASE WHEN c.roleid = 0 THEN 1 ELSE c.roleid END AS roleid, c.recommend, c.mrecommend, c.srecommend, tmp.balance
				FROM (
					SELECT rpt.custid, rpt.ClosingBalance AS balance
						, ROW_NUMBER() OVER (PARTITION BY rpt.CustID ORDER BY rpt.Winlostdate DESC) AS Num
					FROM dbo.rptStatement rpt WITH(NOLOCK)
					INNER JOIN #affectedCustTmp tmp ON tmp.custid = rpt.custid
					WHERE rpt.winlostdate >= @_Saturday AND  rpt.winlostdate < @_Winlostdate
				) AS tmp
					LEFT JOIN bodb02.dbo.custInfo c WITH (NOLOCK) ON tmp.custid = c.custid
				WHERE tmp.Num = 1
			END

			INSERT INTO #rptOpenningBalanceTable (custid, roleid, recommend, mrecommend, srecommend, balance)
			SELECT tmp.custid, tmp.roleid, tmp.recommend, tmp.mrecommend, tmp.srecommend, 0 AS balance
			FROM  #affectedCustTmp tmp
			LEFT JOIN #rptOpenningBalanceTable rpt ON rpt.custid = tmp.CustId
			WHERE rpt.custid IS NULL


			TRUNCATE TABLE #temp;
			TRUNCATE TABLE #temp2;

			INSERT INTO #temp (CustId, Balance, TotalBalance)
			SELECT bal.custid, bal.balance, bal.totalbalance
			FROM #rptOpenningBalanceTable b
				CROSS APPLY (
				SELECT b.custid, b.balance, convert(MONEY, 0) AS totalbalance
				UNION ALL
				SELECT b.custid, 0, b.balance WHERE roleid = 1
				UNION ALL
				SELECT b.recommend, 0, b.balance WHERE roleid <= 2
				UNION ALL
				SELECT b.mrecommend, 0, b.balance WHERE roleid <= 3
				UNION ALL
				SELECT b.srecommend, 0, b.balance WHERE roleid <= 4
			) AS bal
		
			INSERT INTO #temp2 (CustId, OpeningBalance, OpeningTotalBalance)
			SELECT CustId, SUM(Balance), SUM(TotalBalance)
			FROM #temp
			GROUP BY CustId
		
			;MERGE #rptStatementTable AS TGR
			USING #temp2 AS SRC
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
						AND @_Winlostdate BETWEEN ag.FromDate AND ag.ToDate
				) e
			GROUP BY e.UplineId
		)
		UPDATE tmp
		SET tmp.OpeningTotalBalance = ISNULL(tmp.OpeningTotalBalance, 0) + ISNULL(bal.OpeningTotalBalance, 0)
		FROM #rptStatementTable tmp
		INNER JOIN CTE_HeadlineTotalBalance bal ON tmp.Custid = bal.UplineId
	
		-- 6. INSERT into #rptStatementCompare
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
			INNER JOIN #affectedCustTmp c ON c.custid = tmp.custid
		WHERE 
			DATEPART(DW,@_Winlostdate) = 7 	OR @_Winlostdate = @CurrentBU_Date OR
			(ISNULL(tmp.VoidCount, 0)) <> 0
			OR (ISNULL(tmp.BetCount, 0)) <> 0
			OR (ISNULL(tmp.TransCount, 0)) <> 0
			OR (ISNULL(tmp.GrandPrize, 0)) <> 0
		;
		
		--TODO: DELETE/INSERT rptStatement
		BEGIN
			DELETE TGR WITH(ROWLOCK)
			FROM dbo.rptStatement TGR
			INNER JOIN #affectedCustTmp c ON c.custid = TGR.custid
			WHERE TGR.Winlostdate = @_Winlostdate

			--TODO INSERT IF Any
			INSERT INTO dbo.rptStatement(
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
			SELECT
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
			FROM #rptStatementCompare SRC
		END

		PRINT CONCAT('running rptStatement------> @_Winlostdate=', FORMAT(@_Winlostdate, 'yyyy-MM-dd'), ', @Duration=', DATEDIFF(SECOND, @startTime, GETDATE()));

		SET @_Winlostdate = DATEADD(DAY, 1, @_Winlostdate);
	END

	--TODO: update OpeningTotalBalance
	DECLARE @tmpWinlostDate SMALLDATETIME
		,@CustIds			VARCHAR(MAX);

	SELECT @tmpWinlostDate = @CurrentBU_Date
		, @CustIds			= STRING_AGG(CAST(custid AS VARCHAR(MAX)), ',')
	FROM #affectedCustTmp
	;

	--select @CustIds AS [@CustIds]
	WHILE @tmpWinlostDate <= @CurrentMB_Date
	BEGIN
		SET @startTime = GETDATE();
		EXEC dbo.Task_rptStatement_OpeningTotalBalance_14
			@WinlostDate	= @tmpWinlostDate
			,@CustIds		= @CustIds

		PRINT CONCAT('running rptStatement_OpeningTotalBalance_14------> @tmpWinlostDate=', FORMAT(@tmpWinlostDate, 'yyyy-MM-dd'), ', @Duration=', DATEDIFF(SECOND, @startTime, GETDATE()));

		SELECT @tmpWinlostDate = DATEADD(DAY, 1, @tmpWinlostDate)
	END
END
GO