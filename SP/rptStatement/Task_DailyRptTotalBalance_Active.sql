/*<info serverAlias="DBRPT-bodb_Report" executers="" viewers="" isFunction="0" isNested="0"></info>*/ 
ALTER PROCEDURE [dbo].[Task_DailyRptTotalBalance_Active]
	@Winlostdate DATE
	,@isCheckDataOnly BIT = 0
AS
/*
	Created by:20190507@Sophia
	Task: insert/ update data on RptTotalBalance_Active, data from MoveBetDay+1 to today
	DB: DBRPT.bodb_Report
	Revisions:
		- 20190507@Sophia: Initial SP [redmine: #109293] 
		- 20190912@Bobby: Implement headline - Statement [Redmine: #119289]
 */

BEGIN
	SET NOCOUNT ON

	DECLARE @yesterday SMALLDATETIME, @TheDayBefore DATE
	SELECT  @yesterday = CONVERT(DATE, DATEADD(DAY, -1, GETDATE())), 
			@TheDayBefore = DATEADD (DD, -1 , @Winlostdate)
	
	DECLARE @BalanceUpDay DATE, @MoveBetDay DATE, @Saturday DATE, @i TINYINT
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
	
	IF @Winlostdate = DATEADD(DD, 1, @MovebetDay)    ---> first day on bettrans.OpeningBalance = last day on rptStatement.ClosingBalance
	BEGIN 
		--> GET full cust back to the last saturday
		; 
		WITH CTE_rptStatement AS
		(
			SELECT CustID, winlost
			FROM (	
				SELECT rpt.CustID, rpt.ClosingBalance AS winlost
					, ROW_NUMBER() OVER (PARTITION BY rpt.CustID ORDER BY rpt.Winlostdate DESC) as Num
				FROM dbo.rptStatement rpt WITH (NOLOCK) 
				WHERE  Winlostdate >= @Saturday
			) AS rpt
			WHERE rpt.Num = 1
		)

		INSERT INTO #tmpRptTotalBalance_Active (CustID, OpeningBalance, OpeningTotalBalance)
		SELECT
			c.custid
			,SUM(c.winlost) AS OpeningBalance
			,SUM(c.totalWinlost) AS OpeningTotalBalance
		FROM
			CTE_rptStatement AS b
			INNER JOIN bodb02.dbo.custinfo ci WITH(NOLOCK) ON b.custid = ci.custid
		CROSS APPLY (
			SELECT POWER(2*1, ci.roleid) AS ownerIndicator
		) AS bet
		OUTER APPLY (
			SELECT b.custid, b.winlost AS winlost, 1 AS levelID, b.winlost AS totalWinlost
			UNION
			SELECT ci.recommend, b.winlost*((4 & bet.ownerIndicator)/4), 2, b.winlost
			UNION
			SELECT ci.mrecommend, b.winlost*((8 & bet.ownerIndicator)/8), 3, b.winlost
			UNION
			SELECT ci.srecommend, b.winlost*((16 & bet.ownerIndicator)/16), 4, b.winlost
		) AS c
		WHERE c.levelID >= ci.roleID
			AND c.custid > 0
		GROUP BY c.custid

		-- Headline
		UPDATE s
		SET s.OpeningTotalBalance += bal.DownlineCash
		FROM #tmpRptTotalBalance_Active s
		INNER JOIN (
			SELECT	cs.UplineID, SUM(s.OpeningTotalBalance) AS DownlineCash
			FROM #tmpRptTotalBalance_Active s
			INNER JOIN bodb02.dbo.CustSuper cs WITH (NOLOCK) 
				ON s.custid = cs.custid 
			WHERE cs.uplineID > 0
			GROUP BY cs.UplineID
		) AS bal ON s.custid = bal.UplineID


		---------------- Correct Opening Total Balance --------------------
		IF EXISTS (
			SELECT TOP 1 1
			FROM #tmpRptTotalBalance_Active SOURCE
				LEFT JOIN dbo.RptTotalBalance_Active TARGET WITH (NOLOCK) 
					ON TARGET.Winlostdate = @WinlostDate 
					AND TARGET.CustId = SOURCE.CustId 
			WHERE
				TARGET.CustId IS NULL				
				OR TARGET.OpeningBalance 	  <> SOURCE.OpeningBalance				
				OR TARGET.OpeningTotalBalance <> SOURCE.OpeningTotalBalance		
		)
		BEGIN
			IF @IsCheckDataOnly = 1 --just check data
			BEGIN
				SELECT 'Wrong OpeningTotalBalance on ' + CONVERT(VARCHAR(10), @WinlostDate, 112)
			END
			ELSE -- correct data
			BEGIN
				--MERGE INTO RptTotalBalance_Active
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
				
				--WHEN NOT MATCHED BY SOURCE AND TARGET.winlostdate = @Winlostdate THEN
				--DELETE
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
		WITH CTE_OpenningBalanceBettrans AS
		(
			SELECT	 
				custid, recommend, mrecommend, srecommend,c.roleID,
				SUM(CASE WHEN c.roleID = 1 THEN winlost-actual_stake + playercomm ELSE 0 END) Winlost1,
				SUM(CASE WHEN c.roleID = 2 THEN winlost-actual_stake ELSE awinlost+comm-playercomm END) Winlost2,
				SUM(CASE WHEN c.roleID = 3 THEN winlost-actual_stake ELSE mwinlost+acomm-comm END) Winlost3,
				SUM(CASE WHEN c.roleID = 4 THEN winlost-actual_stake ELSE swinlost+scomm-acomm END) Winlost4 
			FROM	bodb02.dbo.bettrans WITH (READPAST)
			CROSS APPLY (
				SELECT 
					CASE custid
						WHEN recommend THEN 2
						WHEN mrecommend THEN 3
						WHEN srecommend THEN 4
						ELSE 1 -- Member & Headline
					END AS roleid
			) AS c
			WHERE	winlostdate = @TheDayBefore
					AND statusID NOT IN (0, 1)
			GROUP BY custid, recommend, mrecommend, srecommend, c.roleID
		)
		INSERT INTO #tmpRptTotalBalance_Active (CustID, OpeningBalance, OpeningTotalBalance)
		SELECT CustID, SUM(OpeningBalance) AS OpeningBalance, SUM(OpeningTotalBalance) AS OpeningTotalBalance
		FROM 
		( 	
			--MERGE with the OpeningBalance of @TheDayBefore
			SELECT  CustID, SUM(OpeningBalance) AS OpeningBalance, SUM(OpeningTotalBalance) as OpeningTotalBalance
			FROM 	dbo.rptTotalBalance_Active WITH (NOLOCK)
			WHERE 	WinlostDate = @TheDayBefore
			GROUP BY CustID 
			
			--MERGE with totalWinlost of the @TheDayBefore
			UNION ALL
			SELECT
				c.custid
				,SUM(c.winlost) AS OpeningBalance
				,SUM(c.totalWinlost) AS OpeningTotalBalance
			FROM
				CTE_OpenningBalanceBettrans b
			OUTER APPLY (
				SELECT b.custid, winlost1 AS winlost, 1 AS levelID, winlost1 AS totalWinlost
				UNION
				SELECT b.recommend, winlost2, 2, winlost1 + winlost2
				UNION
				SELECT b.mrecommend, winlost3, 3, winlost1 + winlost2 + winlost3
				UNION
				SELECT b.srecommend, winlost4, 4, winlost1 + winlost2 + winlost3 + winlost4
			) AS c
			WHERE c.levelID >= b.roleID
				AND c.custid > 0
			GROUP BY c.custid
			
		) AS A			
		GROUP BY A.CustID 	

		-- Headline
		UPDATE s
		SET s.OpeningTotalBalance += bal.DownlineCash
		FROM #tmpRptTotalBalance_Active s
		INNER JOIN (
			SELECT	cs.UplineID, SUM(s.OpeningTotalBalance) AS DownlineCash
			FROM #tmpRptTotalBalance_Active s
			INNER JOIN bodb02.dbo.CustSuper cs WITH (NOLOCK) 
				ON s.custid = cs.custid 
			WHERE cs.uplineID > 0
			GROUP BY cs.UplineID
		) AS bal ON s.custid = bal.UplineID

		---------------- Correct Opening Total Balance --------------------
		IF EXISTS (
			SELECT TOP 1 1
			FROM #tmpRptTotalBalance_Active SOURCE
				FULL OUTER JOIN dbo.RptTotalBalance_Active TARGET WITH (NOLOCK) 
					ON TARGET.Winlostdate = @WinlostDate 
					AND TARGET.CustId = SOURCE.CustId 
					
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
			ELSE -- correct data
			BEGIN
				-- MERGE INTO RptTotalBalance_Active
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
	 
	DROP TABLE #tmpRptTotalBalance_Active
	
END 
GO