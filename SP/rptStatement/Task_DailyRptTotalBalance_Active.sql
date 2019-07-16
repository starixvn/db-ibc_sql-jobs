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
		OpeningTotalBalance MONEY
	)
	
	CREATE TABLE  #FinalRptTotalBalance_Active 
	(
		CustID INT, WinlostDate DATE, OpeningBalance MONEY, OpeningTotalBalance MONEY
	
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
		INSERT INTO dbo.rptTotalBalance_Active (CustID, WinlostDate, OpeningBalance)
		SELECT CustID, @Winlostdate, ClosingBalance 
		FROM (	
					SELECT CustID, Winlostdate, ClosingBalance, ROW_NUMBER() OVER (PARTITION BY CustID ORDER BY  Winlostdate DESC) as Num
					FROM   dbo.rptStatement WITH (NOLOCK) 
					WHERE  Winlostdate >= @Saturday
					GROUP BY CustID, Winlostdate, ClosingBalance		
			) A
		WHERE  Num = 1
		
		/*
		;WITH rptStm_OLD AS (					
					SELECT DISTINCT	rptO.custid, MAX(rptO.Winlostdate) as Winlostdate, rptO.OpeningBalance, rptO.ClosingBalance 
					FROM  dbo.rptStatement_Old rptO  WITH(NOLOCK)
						LEFT JOIN dbo.rptStatement rpt WITH(NOLOCK)
							ON rptO.custid = rpt.custid
					WHERE
						rptO.winlostdate >= DATEADD(DD, -7, @Saturday)
							AND rpt.custid IS NULL
					GROUP BY rptO.CustID, rptO.OpeningBalance, rptO.ClosingBalance	
		INSERT INTO dbo.rptTotalBalance_Active (CustID, WinlostDate, OpeningBalance)
		SELECT 	CustID, @WinlostDate, ClosingBalance AS OpeningBalance
		FROM 	rptStm_OLD 	

		*/		
		
		------------Calc OpeningTotalBalance----------
		--- Member
		INSERT INTO #tmpRptTotalBalance_Active (CustID, OpeningBalance, OpeningTotalBalance)
		SELECT	s.CustID, s.OpeningBalance,	s.OpeningBalance
		FROM 	dbo.rptTotalBalance_Active s WITH (NOLOCK)
		INNER JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) 
				ON c.CustID = s.CustID
		WHERE   s.WinlostDate = @WinlostDate
				AND c.RoleID = 1
				
		--- Agent	
		INSERT INTO #tmpRptTotalBalance_Active (CustID, OpeningBalance, OpeningTotalBalance)	
		SELECT  s.CustID, s.OpeningBalance, s.OpeningBalance + ISNULL(d.DownlineCash ,0)
		FROM 	dbo.rptTotalBalance_Active s WITH (NOLOCK)
			INNER JOIN bodb02.dbo.CustInfo c WITH (NOLOCK)
				ON c.CustID = s.CustID AND c.roleID = 2
			LEFT JOIN ( 
						SELECT	c.recommend, SUM (ISNULL(s.OpeningTotalBalance,0)) as DownlineCash
						FROM 	#tmpRptTotalBalance_Active s WITH (NOLOCK)
						INNER JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) 
								ON c.CustID = s.CustID
						WHERE c.RoleID = 1
						GROUP BY c.recommend
						) d
			ON s.CustID = d.recommend
		WHERE   s.WinlostDate = @WinlostDate
		
		-- Master		 
		INSERT INTO #tmpRptTotalBalance_Active (CustID, OpeningBalance, OpeningTotalBalance)	
		SELECT  s.CustID, s.OpeningBalance, s.OpeningBalance + ISNULL(d.DownlineCash ,0)
		FROM 	dbo.rptTotalBalance_Active s WITH (NOLOCK)
			INNER JOIN bodb02.dbo.CustInfo c WITH (NOLOCK)
				ON c.CustID = s.CustID AND c.roleID = 3
			LEFT JOIN ( 
						SELECT	c.mrecommend, SUM (ISNULL(s.OpeningTotalBalance,0)) as DownlineCash
						FROM 	#tmpRptTotalBalance_Active s WITH (NOLOCK)
						INNER JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) 
								ON c.CustID = s.CustID
						WHERE c.RoleID = 2
						GROUP BY c.mrecommend
						) d
			ON s.CustID = d.mrecommend
		WHERE   s.WinlostDate = @WinlostDate
				
		-- Super		 
		INSERT INTO #tmpRptTotalBalance_Active (CustID, OpeningBalance, OpeningTotalBalance)	
		SELECT  s.CustID, s.OpeningBalance, s.OpeningBalance + ISNULL(d.DownlineCash ,0)
		FROM 	dbo.rptTotalBalance_Active s WITH (NOLOCK)
			INNER JOIN bodb02.dbo.CustInfo c WITH (NOLOCK)
				ON c.CustID = s.CustID AND c.roleID = 4
			LEFT JOIN ( 
						SELECT	c.srecommend, SUM (ISNULL(s.OpeningTotalBalance,0)) as DownlineCash
						FROM 	#tmpRptTotalBalance_Active s WITH (NOLOCK)
						INNER JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) 
								ON c.CustID = s.CustID
						WHERE c.RoleID = 3
						GROUP BY c.srecommend
						) d
			ON s.CustID = d.srecommend
		WHERE   s.WinlostDate = @WinlostDate
		
		----- Update rptTotalBalance_Active.OpeningTotalBalance
		UPDATE	s
		SET		s.OpeningTotalBalance = b.OpeningTotalBalance
		FROM	dbo.rptTotalBalance_Active s
		INNER JOIN #tmpRptTotalBalance_Active b 
			ON s.CustID = b.CustID
		WHERE  s.WinlostDate = @WinlostDate		
		
	END 
	ELSE IF @Winlostdate > DATEADD(DD, 1, @MovebetDay) --- Get data winlost on bettrans and calculate
	BEGIN 
		INSERT INTO #OpenningBalanceBettrans
		SELECT	@winlostdate AS winlostdate,
				CASE custid
					WHEN recommend THEN 2
					WHEN mrecommend THEN 3
					WHEN srecommend THEN 4
					ELSE 1 END roleid, 
				custid, recommend, mrecommend, srecommend,
				SUM(CASE WHEN custid NOT IN (recommend, mrecommend, srecommend) THEN winlost-actual_stake + playercomm ELSE 0 END) Winlost1,
				SUM(CASE WHEN custid = recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END) Winlost2,
				SUM(CASE WHEN custid = mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END) Winlost3,
				SUM(CASE WHEN custid = srecommend THEN winlost-actual_stake ELSE swinlost+scomm-acomm END) Winlost4 
		FROM	bodb02.dbo.bettrans with (nolock)
		WHERE	winlostdate = @TheDayBefore
				AND ruben = 1
		GROUP BY custid, recommend, mrecommend, srecommend	
		

		INSERT INTO #FinalRptTotalBalance_Active (CustID, WinlostDate, OpeningBalance, OpeningTotalBalance)
		SELECT CustID, @WinlostDate as WinlostDate, SUM(Winlost) AS OpeningBalance, SUM(TotalBL) AS OpeningTotalBalance
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
					, SUM(Winlost1 + Winlost2 + Winlost3 + Winlost4) as TotalBL					
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

		---------------- Correct Opening Total Balance --------------------
		IF EXISTS (
			SELECT 1
			FROM #FinalRptTotalBalance_Active SOURCE
				FULL OUTER JOIN dbo.RptTotalBalance_Active TARGET WITH (NOLOCK) 
					ON SOURCE.CustId = TARGET.CustId 
					AND SOURCE.WinlostDate = TARGET.WinlostDate
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
				MERGE dbo.RptTotalBalance_Active AS TARGET
				USING #FinalRptTotalBalance_Active AS SOURCE
						ON	TARGET.WinlostDate	= SOURCE.WinlostDate
						AND TARGET.CustId		= SOURCE.CustId 
				WHEN MATCHED THEN
				UPDATE SET
					TARGET.OpeningBalance = SOURCE.OpeningBalance,		
					TARGET.OpeningTotalBalance = SOURCE.OpeningTotalBalance	
					
				WHEN NOT MATCHED BY Target THEN
				INSERT (custid, winlostdate, openingbalance, Openingtotalbalance)
				VALUES (source.custid, source.winlostdate, source.openingbalance, source.openingtotalbalance) 
				;
			END
		END
				
	END
	 
	
	DROP TABLE #OpenningBalanceBettrans
	DROP TABLE #tmpRptTotalBalance_Active
	
END 
GO 