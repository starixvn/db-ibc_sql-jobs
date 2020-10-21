/*<info serverAlias="DBRPT-bodb_Report" isFunction="0" isNested="0"></info>*/ 
ALTER PROCEDURE [dbo].[Task_DailyRptTotalBalance_Active]
	@Winlostdate		DATE
	,@isCheckDataOnly	BIT = 0
AS
/*
	Created by:20190507@Sophia
	Task: insert/ update data on RptTotalBalance_Active, data from MoveBetDay+1 to today
	DB: DBRPT.bodb_Report
	Revisions:
		- 20190507@Sophia: Initial SP [redmine: #109293] 
		- 20190912@Bobby: Implement headline - Statement [Redmine: #119289]
		- 20191212@Percy: Get UplineId (HeadlineId) from ExtraPT Setting table [RedmineID: #118962]
		- 20200310@Bobby: Remove readpast hint and improve index seek [RedmineID: #130122]
		- 20201008@Percy: Get SMA from bettrans instead of custinfo table [RedmineID: #142953]
 */

BEGIN
	SET NOCOUNT ON

	DECLARE @yesterday SMALLDATETIME, @TheDayBefore DATE
	SELECT  @yesterday = CONVERT(DATE, DATEADD(DAY, -1, GETDATE())), 
			@TheDayBefore = DATEADD (DD, -1 , @Winlostdate)
	
	DECLARE @BalanceUpDay SMALLDATETIME, @MoveBetDay SMALLDATETIME, @Saturday DATE, @i TINYINT
	DECLARE @BalanceUpDays AS TABLE (BalanceUpDay DATE, MoveBetDay DATE)
	
	INSERT INTO @BalanceUpDays (BalanceUpDay, MoveBetDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay
	
	SELECT @BalanceUpDay = BalanceUpDay, @MoveBetDay = MoveBetDay
	FROM @BalanceUpDays 
	
	SELECT @i = DATEPART (DW,@MoveBetDay) 
	SELECT @Saturday = DATEADD ( DD, -@i, @MoveBetDay)

	-- Get OpeningBalance Information --
	
	CREATE TABLE #tmpRptTotalBalance_Active
	(			
		CustId 				INT PRIMARY KEY, 
		OpeningBalance		MONEY, 
		OpeningTotalBalance DECIMAL(20,4)
	)
	
	CREATE TABLE #rptOpenningBalanceTable (
		custid INT PRIMARY KEY
		, roleid TINYINT
		, recommend INT
		, mrecommend INT
		, srecommend INT
		, winlost MONEY
		, awinlost MONEY
		, mwinlost MONEY
		, swinlost MONEY
	)

	IF @Winlostdate = DATEADD(DD, 1, @MovebetDay)    ---> first day on bettrans.OpeningBalance = last day on rptStatement.ClosingBalance
	BEGIN 
		--> GET full cust back to the previous saturday
		INSERT INTO #rptOpenningBalanceTable (custid, roleid, recommend, mrecommend, srecommend, winlost)
		SELECT rpt.custid, CASE WHEN c.roleid = 0 THEN 1 ELSE c.roleid END AS roleid, c.recommend, c.mrecommend, c.srecommend, rpt.winlost
		FROM (	
			SELECT rpt.CustID, rpt.ClosingBalance AS winlost
				, ROW_NUMBER() OVER (PARTITION BY rpt.CustID ORDER BY rpt.Winlostdate DESC) as Num
			FROM dbo.rptStatement rpt WITH (NOLOCK) 
			WHERE  Winlostdate >= @Saturday
		) AS rpt
			LEFT JOIN bodb02.dbo.custInfo c WITH (NOLOCK) ON rpt.custid = c.custid
		WHERE rpt.Num = 1;

		IF EXISTS (SELECT 1 FROM #rptOpenningBalanceTable WHERE recommend IS NULL)
			UPDATE t
			SET t.recommend = b.recommend, t.mrecommend = b.mrecommend, t.srecommend = b.srecommend
			,t.roleid = CASE b.custid
							WHEN b.srecommend THEN 4
							WHEN b.mrecommend THEN 3
							WHEN b.recommend THEN 2
							ELSE 1 END -- include member & headline
			FROM #rptOpenningBalanceTable t
				INNER JOIN bodb02.dbo.bettrans b WITH (NOLOCK) ON t.custid = b.custid
			WHERE t.recommend IS NULL
				AND b.bettype = 20000
				AND b.winlostdate = @BalanceUpDay;

		INSERT INTO #tmpRptTotalBalance_Active (CustID, OpeningBalance, OpeningTotalBalance)
		SELECT bal.custid
			, SUM(bal.winlost)
			, SUM(bal.totalWinlost)
		FROM #rptOpenningBalanceTable b
			CROSS APPLY (
				SELECT POWER(2*1, b.roleid) AS ownerIndicator
			) AS bet
			CROSS APPLY (
				SELECT b.custid, 1 AS levelID, b.winlost, b.winlost AS totalWinlost
				UNION ALL
				SELECT b.recommend, 2, b.winlost * CAST(bet.ownerIndicator & 4 AS BIT)/1, b.winlost
				UNION ALL
				SELECT b.mrecommend, 3, b.winlost * CAST(bet.ownerIndicator & 8 AS BIT)/1, b.winlost
				UNION ALL
				SELECT b.srecommend, 4, b.winlost * CAST(bet.ownerIndicator & 16 AS BIT)/1, b.winlost
			) AS bal
		WHERE bal.levelID >= b.roleid
			AND bal.custid > 0
		GROUP BY bal.custid

		-- Headline
		;WITH CTE_HeadlineTotalBalance AS 
		(
			SELECT e.UplineId, SUM(ISNULL(tmp.OpeningTotalBalance, 0)) AS OpeningTotalBalance
			FROM #tmpRptTotalBalance_Active tmp
				CROSS APPLY (
					SELECT TOP (1) ag.UplineId
					FROM bodb02.dbo.Acc_GroupExtraPTSetting ag WITH (NOLOCK)
					WHERE tmp.Custid = ag.SuperId
						AND @Winlostdate BETWEEN ag.FromDate AND ag.ToDate
				) e
			GROUP BY e.UplineId
		)
		UPDATE tmp
		SET tmp.OpeningTotalBalance = ISNULL(tmp.OpeningBalance, 0) + ISNULL(bal.OpeningTotalBalance, 0)
		FROM #tmpRptTotalBalance_Active tmp
		INNER JOIN CTE_HeadlineTotalBalance bal ON tmp.Custid = bal.UplineId

		---------------- Correct Opening Total Balance --------------------
		IF EXISTS (
			SELECT TOP 1 1
			FROM #tmpRptTotalBalance_Active SOURCE
			FULL OUTER JOIN (
				SELECT CustID, OpeningBalance, OpeningTotalBalance 
				FROM dbo.RptTotalBalance_Active WITH (NOLOCK) 
				WHERE Winlostdate = @WinlostDate
			) AS TARGET	ON TARGET.CustId = SOURCE.CustId 
			WHERE 
				SOURCE.CustId IS NULL
				OR TARGET.CustId IS NULL
				OR TARGET.OpeningBalance 	  <> SOURCE.OpeningBalance				
				OR TARGET.OpeningTotalBalance <> SOURCE.OpeningTotalBalance
		)
		BEGIN
			IF @IsCheckDataOnly = 1 --just check data
			BEGIN
				SELECT 'Wrong OpeningTotalBalance on ' + CONVERT(VARCHAR(10), @WinlostDate, 112)
			END
			ELSE 
			BEGIN
				-- correct data
				MERGE dbo.RptTotalBalance_Active AS TARGET
				USING #tmpRptTotalBalance_Active AS SOURCE
						ON	TARGET.Winlostdate  = @WinlostDate
						AND TARGET.CustId		= SOURCE.CustId
						 
				WHEN MATCHED AND (
					TARGET.OpeningBalance <> SOURCE.OpeningBalance
					OR TARGET.OpeningTotalBalance <> SOURCE.OpeningTotalBalance) 
					AND TARGET.Winlostdate  = @WinlostDate THEN
				UPDATE SET
					TARGET.OpeningBalance = SOURCE.OpeningBalance,		
					TARGET.OpeningTotalBalance = SOURCE.OpeningTotalBalance	
					
				WHEN NOT MATCHED BY TARGET THEN
					INSERT (custid, winlostdate, openingbalance, Openingtotalbalance)
					VALUES (SOURCE.custid, @WinlostDate, SOURCE.openingbalance, SOURCE.openingtotalbalance) 
				
				WHEN NOT MATCHED BY SOURCE AND TARGET.winlostdate = @Winlostdate THEN
					DELETE
				;
			END
		END
		ELSE
		BEGIN
			SELECT 'There is nothing changes on ' + CONVERT(VARCHAR(10), @WinlostDate, 112)
		END
	END 
	ELSE IF @Winlostdate > DATEADD(DD, 1, @MovebetDay) --- Get data winlost on bettrans and calculate
	BEGIN 
		--RE_CAL WL of @TheDayBefore
		INSERT INTO #rptOpenningBalanceTable (custid, roleid, recommend, mrecommend, srecommend, winlost, awinlost, mwinlost, swinlost)
		SELECT custid
			, CASE custid
				WHEN srecommend THEN 4
				WHEN mrecommend THEN 3
				WHEN recommend THEN 2
				ELSE 1 END -- include member & headline
			, recommend
			, mrecommend
			, srecommend
			, SUM(winlost) AS winlost
			, SUM(awinlost) AS awinlost
			, SUM(mwinlost) AS mwinlost
			, SUM(swinlost) AS swinlost
		FROM (
			SELECT custid, recommend, mrecommend, srecommend
				, SUM(winlost - actual_stake + playercomm) AS winlost
				, SUM(awinlost + comm - playercomm) AS awinlost
				, SUM(mwinlost + acomm - comm) AS mwinlost
				, SUM(swinlost + scomm - acomm) AS swinlost
			FROM bodb02.dbo.bettrans WITH (NOLOCK)
			WHERE winlostdate = @TheDayBefore
				AND bettype < 19999 --> bet tickets
				AND ruben = 1
				AND statusID NOT IN (0, 1)
			GROUP BY custid, recommend, mrecommend, srecommend
	
			UNION ALL
			SELECT custid, recommend, mrecommend, srecommend
				, SUM(winlost - actual_stake) AS winlost
				, 0 AS awinlost
				, 0 AS mwinlost
				, 0 AS swinlost
			FROM bodb02.dbo.bettrans WITH (NOLOCK)
			WHERE winlostdate = @TheDayBefore
				AND bettype > 19999 --> transfer tickets
				AND ruben = 1
				AND statusID NOT IN (0, 1)
			GROUP BY custid, recommend, mrecommend, srecommend
		) AS rpt
		GROUP BY custid
			, CASE custid
				WHEN srecommend THEN 4
				WHEN mrecommend THEN 3
				WHEN recommend THEN 2
				ELSE 1 END
			, recommend
			, mrecommend
			, srecommend
		
		--INIT with the OpeningBalance of @TheDayBefore
		INSERT INTO #tmpRptTotalBalance_Active (CustID, OpeningBalance, OpeningTotalBalance)
		SELECT  CustID, OpeningBalance, OpeningTotalBalance
		FROM 	dbo.rptTotalBalance_Active WITH (NOLOCK)
		WHERE 	WinlostDate = @TheDayBefore

		;--MERGE with the winlost of @TheDayBefore
		MERGE #tmpRptTotalBalance_Active AS TGR
		USING (
			SELECT
				bal.custid
				,SUM(ISNULL(bal.winlost, 0)) AS OpeningBalance
				,SUM(ISNULL(bal.totalWinlost, 0)) AS OpeningTotalBalance
			FROM #rptOpenningBalanceTable b
			CROSS APPLY (
				SELECT POWER(2*1, b.roleid) AS ownerIndicator
			)AS bet
			OUTER APPLY (
				SELECT b.custid, (ownerIndicator & 2)/2 * winlost AS winlost, 1 AS levelID, winlost AS totalWinlost
				UNION
				SELECT b.recommend, (ownerIndicator & 4)/4 * winlost + awinlost, 2, winlost + awinlost
				UNION
				SELECT b.mrecommend, (ownerIndicator & 8)/8 * winlost + mwinlost, 3, winlost + awinlost + mwinlost
				UNION
				SELECT b.srecommend, (ownerIndicator & 16)/16 * winlost + swinlost, 4, winlost + awinlost + mwinlost + swinlost
			) AS bal
			WHERE bal.levelID >= b.roleid
				AND bal.custid > 0
			GROUP BY bal.custid
		) AS SRC ON TGR.custid = SRC.custid
		WHEN MATCHED THEN 
		UPDATE
			SET TGR.OpeningBalance = ISNULL(TGR.OpeningBalance, 0) + ISNULL(SRC.OpeningBalance, 0)
				,TGR.OpeningTotalBalance = ISNULL(TGR.OpeningTotalBalance, 0) + ISNULL(SRC.OpeningTotalBalance, 0)
		WHEN NOT MATCHED BY TARGET THEN
		INSERT (custid, OpeningBalance, OpeningTotalBalance)
		VALUES(SRC.custid, SRC.OpeningBalance, SRC.OpeningTotalBalance)
		;	

		-- Headline
		;WITH CTE_HeadlineTotalBalance AS 
		(
			SELECT e.UplineId, SUM(ISNULL(tmp.OpeningTotalBalance, 0)) AS OpeningTotalBalance
			FROM #tmpRptTotalBalance_Active tmp
				CROSS APPLY (
					SELECT TOP (1) ag.UplineId
					FROM bodb02.dbo.Acc_GroupExtraPTSetting ag WITH (NOLOCK)
					WHERE tmp.Custid = ag.SuperId
						AND @Winlostdate BETWEEN ag.FromDate AND ag.ToDate
				) e
			GROUP BY e.UplineId
		)
		UPDATE tmp
		SET tmp.OpeningTotalBalance = ISNULL(tmp.OpeningBalance, 0) + ISNULL(bal.OpeningTotalBalance, 0)
		FROM #tmpRptTotalBalance_Active tmp
		INNER JOIN CTE_HeadlineTotalBalance bal ON tmp.Custid = bal.UplineId

		---------------- Correct Opening Total Balance --------------------
		IF EXISTS (
			SELECT TOP 1 1
			FROM #tmpRptTotalBalance_Active SOURCE
			FULL OUTER JOIN (
				SELECT CustID, OpeningBalance, OpeningTotalBalance 
				FROM dbo.RptTotalBalance_Active WITH (NOLOCK) 
				WHERE Winlostdate = @WinlostDate
			) AS TARGET	ON TARGET.CustId = SOURCE.CustId 
			WHERE 
				SOURCE.CustId IS NULL
				OR TARGET.CustId IS NULL
				OR TARGET.OpeningBalance 	  <> SOURCE.OpeningBalance				
				OR TARGET.OpeningTotalBalance <> SOURCE.OpeningTotalBalance
		)
		BEGIN
			IF @IsCheckDataOnly = 1 --just check data
			BEGIN
				SELECT 'Wrong OpeningTotalBalance on ' + CONVERT(VARCHAR(10), @WinlostDate, 112)
			END
			ELSE 
			BEGIN
				-- correct data
				MERGE dbo.RptTotalBalance_Active AS TARGET
				USING #tmpRptTotalBalance_Active AS SOURCE
						ON	TARGET.Winlostdate  = @WinlostDate
						AND TARGET.CustId		= SOURCE.CustId
						 
				WHEN MATCHED AND (
					TARGET.OpeningBalance <> SOURCE.OpeningBalance
					OR TARGET.OpeningTotalBalance <> SOURCE.OpeningTotalBalance) 
					AND TARGET.Winlostdate  = @WinlostDate THEN
				UPDATE SET
					TARGET.OpeningBalance = SOURCE.OpeningBalance,		
					TARGET.OpeningTotalBalance = SOURCE.OpeningTotalBalance	
					
				WHEN NOT MATCHED BY TARGET THEN
				INSERT (custid, winlostdate, openingbalance, Openingtotalbalance)
				VALUES (SOURCE.custid, @WinlostDate, SOURCE.openingbalance, SOURCE.openingtotalbalance) 
				
				WHEN NOT MATCHED BY SOURCE AND TARGET.winlostdate = @Winlostdate THEN
				DELETE
				;
			END
		END
		ELSE
		BEGIN
			SELECT 'There is nothing changes on ' + CONVERT(VARCHAR(10), @WinlostDate, 112)
		END	
	END
	
	DROP TABLE #rptOpenningBalanceTable
	DROP TABLE #tmpRptTotalBalance_Active
END
GO