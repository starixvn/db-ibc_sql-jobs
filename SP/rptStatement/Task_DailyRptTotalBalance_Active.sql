/*<info serverAlias="DBRPT-bodb_Report" executers="" viewers="" isFunction="0" isNested="0"></info>*/
 
ALTER PROCEDURE [dbo].[Task_DailyRptTotalBalance_Active]
	@Winlostdate DATE
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

	-- Get bettype --
	DECLARE @isTest BIT = 0
	SELECT  @isTest = dbo.f_CheckSPVersion(@@PROCID)
	
	CREATE TABLE #SportBettype (bettype INT)
	INSERT INTO #SportBettype (bettype)
	SELECT bettype FROM bodb02.dbo.f_SportBettypeMatrix_Sel (0, 0, 0, 2, '', '', @isTest)
	WHERE RefTable NOT IN (0, 3) -- exclude bettrans, translog

	-- Get OpeningBalance Information --
	
	CREATE TABLE #tmpRptTotalBalance_Active
	(			
		CustId 			INT, 
		OpeningBalance  MONEY, 
		OpeningTotalBalance MONEY
	)
	
	
	CREATE TABLE #OpenningBalanceBettrans
	(	
		Winlostdate 	DATE,
		roleid			TINYINT,
		CustId 			INT, 
		recommend		INT, 
		mrecommend		INT,
		srecommend		INT,	
		Amount1  		MONEY,
		Amount2 		MONEY,
		Amount3 		MONEY,
		Amount4  		MONEY		
	)
	
	IF @Winlostdate = DATEADD(DD, 1, @MovebetDay)    --- first day on bettrans.OpeningBalance = last day on rptStatement.ClosingBalance
	BEGIN 		 
		;WITH rptStm AS ( 
					SELECT CustID, MAX(Winlostdate) as Winlostdate, OpeningBalance, ClosingBalance
					FROM   dbo.rptStatement WITH (NOLOCK) 
					WHERE  Winlostdate >= @Saturday
					GROUP BY CustID, OpeningBalance, ClosingBalance				
					)
		INSERT INTO dbo.rptTotalBalance_Active (CustID, WinlostDate, OpeningBalance)
		SELECT 	CustID, @WinlostDate, ClosingBalance AS OpeningBalance
		FROM 	rptStm 	
		
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
		SELECT  s.CustID, s.OpeningBalance, s.OpeningBalance + d.DownlineCash 
		FROM 	dbo.rptTotalBalance_Active s WITH (NOLOCK)
			INNER JOIN ( 
						SELECT	c.recommend, SUM (s.OpeningBalance) as DownlineCash
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
		SELECT  s.CustID, s.OpeningBalance, s.OpeningBalance + d.DownlineCash
		FROM 	dbo.rptTotalBalance_Active s WITH (NOLOCK)
			INNER JOIN ( 
						SELECT	c.mrecommend, SUM (s.OpeningBalance) as DownlineCash
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
		SELECT  s.CustID, s.OpeningBalance, s.OpeningBalance + d.DownlineCash
		FROM 	dbo.rptTotalBalance_Active s WITH (NOLOCK)
			INNER JOIN ( 
						SELECT	c.srecommend, SUM (s.OpeningBalance) as DownlineCash
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
		FROM	dbo.bettrans with (nolock)
		WHERE	winlostdate = @TheDayBefore
				AND ruben = 1
		GROUP BY custid, recommend, mrecommend, srecommend	
		

		INSERT INTO dbo.rptTotalBalance_Active (CustID, WinlostDate, OpeningBalance, OpeningTotalBalance)
		SELECT CustID, @WinlostDate as WinlostDate, SUM(Winlost) AS OpeningBalance, SUM(TotalBL) AS OpeningTotalBalance
		FROM 
		( 	
			SELECT  CustID, SUM(OpeningBalance) AS Winlost, SUM(OpeningTotalBalance) as TotalBL
			FROM 	dbo.rptTotalBalance_Active WITH (NOLOCK)
			WHERE 	WinlostDate = @TheDayBefore
			GROUP BY CustID 
			
			UNION ALL
			SELECT  CustID, SUM(Winlost1) AS Winlost, SUM(Winlost1 + Winlost2 + Winlost3 + Winlost4) as TotalBL
			FROM 	#OpenningBalanceBettrans
			GROUP BY CustID	
			
			UNION ALL
			SELECT	recommend as CustID, SUM(Winlost2) as Winlost, SUM(Winlost1 + Winlost2 + Winlost3 + Winlost4) as TotalBL
			FROM	#OpenningBalanceBettrans
			WHERE 	RoleID = 1
			GROUP BY recommend
			
			UNION ALL 
			SELECT	mrecommend as CustId, SUM(Winlost3) as Winlost, SUM(Winlost1 + Winlost2 + Winlost3 + Winlost4) as TotalBL
			FROM	#OpenningBalanceBettrans
			WHERE 	RoleID = 1
			GROUP BY mrecommend		
			
			UNION ALL			
			SELECT	srecommend as CustId, SUM(Winlost4) as Winlost, SUM(Winlost1 + Winlost2 + Winlost3 + Winlost4) as TotalBL
			FROM	#OpenningBalanceBettrans
			WHERE 	RoleID = 1
			GROUP BY srecommend
		)	A			
		GROUP BY CustID 		
	END
	 
	
	DROP TABLE #OpenningBalanceBettrans
	DROP TABLE #tmpRptTotalBalance_Active
	
END 
GO 