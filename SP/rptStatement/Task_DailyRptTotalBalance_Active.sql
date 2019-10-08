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
		CustId 			INT, 
		OpeningBalance  MONEY, 
		OpeningTotalBalance DECIMAL(37,4)
	)
	
	CREATE TABLE  #FinalRptTotalBalance_Active 
	(
		CustID INT PRIMARY KEY, 
		--WinlostDate DATE, 
		OpeningBalance MONEY, 
		OpeningTotalBalance DECIMAL(37,4)
	
	)
	
	
	CREATE TABLE #OpenningBalanceBettrans
	(	
		Winlostdate 	DATE,
		roleid			TINYINT,
		CustId 			INT, 
		recommend		INT, 
		mrecommend		INT,
		srecommend		INT,	
		Winlost1  		MONEY,
		Winlost2 		MONEY,
		Winlost3 		MONEY,
		Winlost4  		MONEY		
	)
	
	IF @Winlostdate = DATEADD(DD, 1, @MovebetDay)    --- first day on bettrans.OpeningBalance = last day on rptStatement.ClosingBalance
	BEGIN 		  
		
		INSERT INTO #FinalRptTotalBalance_Active (CustID, OpeningBalance)
		SELECT CustID, ClosingBalance 
		FROM (	
			SELECT CustID, ClosingBalance, ROW_NUMBER() OVER (PARTITION BY CustID ORDER BY  Winlostdate DESC) as Num
			FROM   dbo.rptStatement WITH (READPAST) 
			WHERE  Winlostdate >= @Saturday
			GROUP BY CustID, Winlostdate, ClosingBalance		
		) A
		WHERE  Num = 1
		
		-------------------------------------
		
		IF EXISTS (
			SELECT TOP 1 1
			FROM #FinalRptTotalBalance_Active SOURCE
				FULL OUTER JOIN dbo.RptTotalBalance_Active TARGET WITH (NOLOCK) 
					ON TARGET.Winlostdate = @WinlostDate
					AND TARGET.CustId = SOURCE.CustId 
			WHERE
					SOURCE.CustId IS NULL
					OR TARGET.CustId IS NULL				
					OR TARGET.OpeningBalance <> SOURCE.OpeningBalance						
		)
		BEGIN
			IF @IsCheckDataOnly = 1 --just check data
			BEGIN
				SELECT 'Wrong OpeningTotalBalance on ' + CONVERT(VARCHAR(10), @WinlostDate, 112)
			END
			ELSE IF @IsCheckDataOnly = 0 			 
			BEGIN
		
				------------Calc OpeningBalance & OpeningTotalBalance----------
				--- Member & Headline
				INSERT INTO #tmpRptTotalBalance_Active (CustID, OpeningBalance, OpeningTotalBalance)
				SELECT	s.CustID, ISNULL(tmp.OpeningBalance, s.OpeningBalance), ISNULL(tmp.OpeningBalance, s.OpeningBalance)
				FROM 	dbo.rptTotalBalance_Active s WITH (NOLOCK)
					INNER JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) 
						ON c.CustID = s.CustID
					LEFT JOIN #FinalRptTotalBalance_Active tmp ON s.CustID = tmp.CustID
				WHERE   s.WinlostDate = @WinlostDate
						AND c.RoleID IN (1,0)
					
				--- Agent	
				SELECT	c.recommend, SUM (ISNULL(s.OpeningTotalBalance,0)) as DownlineCash
				INTO #__Agent
				FROM 	#tmpRptTotalBalance_Active s WITH (NOLOCK)
				INNER JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) 
						ON c.CustID = s.CustID
				WHERE c.RoleID = 1
				GROUP BY c.recommend
			
				INSERT INTO #tmpRptTotalBalance_Active (CustID, OpeningBalance, OpeningTotalBalance)	
				SELECT  s.CustID, ISNULL(tmp.OpeningBalance, s.OpeningBalance), ISNULL(tmp.OpeningBalance, s.OpeningBalance) + ISNULL(d.DownlineCash ,0)
				FROM 	dbo.rptTotalBalance_Active s WITH (NOLOCK)
					--INNER JOIN bodb02.dbo.CustInfo c WITH (NOLOCK)
					--	ON c.CustID = s.CustID AND c.roleID = 2
					INNER JOIN #__Agent d
						ON s.CustID = d.recommend
					LEFT JOIN #FinalRptTotalBalance_Active tmp ON s.CustID = tmp.CustID
				WHERE   s.WinlostDate = @WinlostDate

				DROP TABLE #__Agent
			
				-- Master	
				SELECT	c.mrecommend, SUM (ISNULL(s.OpeningTotalBalance,0)) as DownlineCash
				INTO #__Master
				FROM 	#tmpRptTotalBalance_Active s WITH (NOLOCK)
				INNER JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) 
						ON c.CustID = s.CustID
				WHERE c.RoleID = 2
				GROUP BY c.mrecommend	 
			
				INSERT INTO #tmpRptTotalBalance_Active (CustID, OpeningBalance, OpeningTotalBalance)	
				SELECT  s.CustID, ISNULL(tmp.OpeningBalance, s.OpeningBalance), ISNULL(tmp.OpeningBalance, s.OpeningBalance) + ISNULL(d.DownlineCash ,0)
				FROM 	dbo.rptTotalBalance_Active s WITH (NOLOCK)
					--INNER JOIN bodb02.dbo.CustInfo c WITH (NOLOCK)
					--	ON c.CustID = s.CustID AND c.roleID = 3
					INNER JOIN #__Master d
						ON s.CustID = d.mrecommend
					LEFT JOIN #FinalRptTotalBalance_Active tmp ON s.CustID = tmp.CustID
				WHERE   s.WinlostDate = @WinlostDate

				DROP TABLE #__Master
					
				-- Super		 
				SELECT	c.srecommend, SUM (ISNULL(s.OpeningTotalBalance,0)) as DownlineCash
				INTO #__Super
				FROM 	#tmpRptTotalBalance_Active s WITH (NOLOCK)
				INNER JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) 
						ON c.CustID = s.CustID
				WHERE c.RoleID = 3
				GROUP BY c.srecommend
			
				INSERT INTO #tmpRptTotalBalance_Active (CustID, OpeningBalance, OpeningTotalBalance)	
				SELECT  s.CustID, ISNULL(tmp.OpeningBalance, s.OpeningBalance), ISNULL(tmp.OpeningBalance, s.OpeningBalance) + ISNULL(d.DownlineCash ,0)
				FROM 	dbo.rptTotalBalance_Active s WITH (NOLOCK)
					--INNER JOIN bodb02.dbo.CustInfo c WITH (NOLOCK)
					--	ON c.CustID = s.CustID AND c.roleID = 4
					INNER JOIN #__Super d
						ON s.CustID = d.srecommend
					LEFT JOIN #FinalRptTotalBalance_Active tmp ON s.CustID = tmp.CustID
				WHERE   s.WinlostDate = @WinlostDate
			
				DROP TABLE #__Super

				-- UPDATE Headline with super(s) downline
				SELECT	cs.UplineID, SUM (ISNULL(s.OpeningTotalBalance,0)) as DownlineCash
				INTO #__Headline
				FROM 	#tmpRptTotalBalance_Active s WITH (NOLOCK)
				INNER JOIN bodb02.dbo.CustSuper cs WITH (NOLOCK) 
					ON s.custid = cs.custid 
				WHERE cs.uplineID > 0
				GROUP BY cs.UplineID

				UPDATE s
				SET s.OpeningTotalBalance += d.DownlineCash
				FROM #tmpRptTotalBalance_Active s
				INNER JOIN #__Headline d ON s.custid =d.UplineID

				DROP TABLE #__Headline

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
				INSERT (custid, winlostdate, openingbalance, OpeningTotalBalance)
				VALUES (SOURCE.custid, @Winlostdate, SOURCE.openingbalance, SOURCE.OpeningTotalBalance) 
				
				--WHEN NOT MATCHED BY SOURCE AND winlostdate = @Winlostdate THEN
				--DELETE
				;
			END
		END
		-----------------------------------------------------
		
	END 
	ELSE IF @Winlostdate > DATEADD(DD, 1, @MovebetDay) --- Get data winlost on bettrans and calculate
	BEGIN 
		INSERT INTO #OpenningBalanceBettrans
		SELECT	@winlostdate AS winlostdate,
				CASE custid
					WHEN recommend THEN 2
					WHEN mrecommend THEN 3
					WHEN srecommend THEN 4
					ELSE 1 END roleid, -- Member & Headline
				custid, recommend, mrecommend, srecommend,
				SUM(CASE WHEN custid NOT IN (recommend, mrecommend, srecommend) THEN winlost-actual_stake + playercomm ELSE 0 END) Winlost1,
				SUM(CASE WHEN custid = recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END) Winlost2,
				SUM(CASE WHEN custid = mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END) Winlost3,
				SUM(CASE WHEN custid = srecommend THEN winlost-actual_stake ELSE swinlost+scomm-acomm END) Winlost4 
		FROM	bodb02.dbo.bettrans with (nolock)
		WHERE	winlostdate = @TheDayBefore
				AND statusID NOT IN (0, 1)
		GROUP BY custid, recommend, mrecommend, srecommend	
		

		INSERT INTO #tmpRptTotalBalance_Active (CustID, OpeningBalance, OpeningTotalBalance)
		SELECT CustID, SUM(Winlost) AS OpeningBalance, SUM(TotalBL) AS OpeningTotalBalance
		FROM 
		( 	
			SELECT  CustID, SUM(OpeningBalance) AS Winlost, SUM(OpeningTotalBalance) as TotalBL
			FROM 	dbo.rptTotalBalance_Active WITH (NOLOCK)
			WHERE 	WinlostDate = @TheDayBefore
			GROUP BY CustID 
			
			UNION ALL
			SELECT  CustID, SUM(CASE RoleID 
									WHEN 1 THEN Winlost1   ---- Transfer and Bet tickets of Member
									WHEN 2 THEN Winlost2   ---- Transfer of Agent
									WHEN 3 THEN Winlost3   ---- Transfer of Master
									WHEN 4 THEN Winlost4   ---- Transfer of Super
									END
							) AS Winlost
					, SUM(CASE RoleID 
									WHEN 1 THEN Winlost1   ---- Transfer and Bet tickets of Member
									WHEN 2 THEN Winlost2   ---- Transfer of Agent
									WHEN 3 THEN Winlost3   ---- Transfer of Master
									WHEN 4 THEN Winlost4   ---- Transfer of Super
									END) as TotalBL					
			FROM 	#OpenningBalanceBettrans
			GROUP BY CustID	   --- All levels
			
			UNION ALL
			SELECT	recommend as CustID, SUM(Winlost2) as Winlost, SUM(Winlost1 + Winlost2) as TotalBL
			FROM	#OpenningBalanceBettrans
			WHERE 	RoleID = 1   -- agent gets on bet tickets
			GROUP BY recommend
			
			UNION ALL 
			SELECT	mrecommend as CustId, SUM(Winlost3) as Winlost, SUM(Winlost1 + Winlost2 + Winlost3) as TotalBL
			FROM	#OpenningBalanceBettrans
			WHERE 	RoleID IN (1,2)  -- master gets on bet tickets & transfer of agent, member
			GROUP BY mrecommend		
			
			UNION ALL			
			SELECT	srecommend as CustId, SUM(Winlost4) as Winlost, SUM(Winlost1 + Winlost2 + Winlost3 + Winlost4) as TotalBL
			FROM	#OpenningBalanceBettrans
			WHERE 	RoleID IN (1,2,3)
			GROUP BY srecommend  -- super gets on bet tickets & transfer of master, agent, member
		)	A			
		GROUP BY CustID 	

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
				VALUES (SOURCE.custid, SOURCE.winlostdate, SOURCE.openingbalance, SOURCE.openingtotalbalance) 
				
				WHEN NOT MATCHED BY SOURCE AND TARGET.winlostdate = @Winlostdate THEN
				DELETE
				;
			END
		END
				
	END
	 
	DROP TABLE #FinalRptTotalBalance_Active
	DROP TABLE #OpenningBalanceBettrans
	DROP TABLE #tmpRptTotalBalance_Active
	
END 
GO