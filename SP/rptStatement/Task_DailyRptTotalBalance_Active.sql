/*<info serverAlias="DBRPT-bodb_Report" executers="" viewers="" isFunction="0" isNested="0"></info>*/
 
ALTER PROCEDURE [dbo].[Task_DailyRptTotalBalance_Active]
	@Winlostdate DATE
AS

/*
	Created by:20190507@Sophia
	Task: insert/ update data on RptTotalBalance_Active, data from MoveBetDay to today
	DB: DBRPT.bodb_Report
	Revisions:
		- 20190507@Sophia: Initial data [redmine: #109293]
 */

BEGIN
	SET NOCOUNT ON

	DECLARE @yesterday SMALLDATETIME
	SELECT  @yesterday = CONVERT(DATE, DATEADD(DAY, -1, GETDATE()))

	-- Get bettype --
	DECLARE @isTest BIT = 0
	SELECT  @isTest = dbo.f_CheckSPVersion(@@PROCID)
	
	CREATE TABLE #SportBettype (bettype INT)
	INSERT INTO #SportBettype (bettype)
	SELECT bettype FROM dbo.f_SportBettypeMatrix_Sel (0, 0, 0, 2, '', '', @isTest)
	WHERE RefTable NOT IN (0, 3) -- exclude bettrans, translog
	
	DECLARE @roleID TINYINT, @ID INT = 1, @__custId INT
	SET @__custId = @custID

	SELECT @roleID = roleid FROM dbo.custInfo WITH (NOLOCK) WHERE custid = @__custId
	
	-- Get Balance Information --
	CREATE TABLE #BalanceInfo
	(	
		CustId INT, 
		RoleId TINYINT,
		superCash	MONEY DEFAULT (0),
		masterCash	MONEY DEFAULT (0),
		agentCash	MONEY DEFAULT (0),
		memberCash	MONEY DEFAULT (0)
	)

    IF @roleid = 1
	BEGIN
		-- bettransRNG
		INSERT INTO #BalanceInfo (custid, RoleId, memberCash)
		SELECT b.CustId, 1 as RoleId,  
			SUM(winlost-actual_stake+playercomm)
	    FROM dbo.bettransRNG b WITH (NOLOCK)
		INNER JOIN CustInfo c WITH (NOLOCK) 
				ON c.CustId = b.CustId		
		WHERE  winlostdate >= @yesterday
			AND ruben = 1
			AND statusID NOT IN (0, 1)
			AND c.RoleID = 1	 
		GROUP BY b.CustID

		-- bettransLC
		INSERT INTO #BalanceInfo (custid, RoleId, memberCash)
		SELECT b.CustID, 1 as RoleID,
			SUM(winlost-actual_stake+playercomm)
	    FROM dbo.bettransLC b WITH (NOLOCK)
		INNER JOIN CustInfo c WITH (NOLOCK) 
				ON c.CustId = b.CustId		
		WHERE winlostdate >= @yesterday
			AND statusID NOT IN (0, 1)
			AND c.RoleID = 1
		GROUP BY b.CustID

		-- bettrans
		INSERT INTO #BalanceInfo (custid, RoleId, memberCash)
		SELECT b.CustID, 1 as RoleID,
			SUM(winlost-actual_stake+playercomm)
		FROM dbo.bettrans b WITH (NOLOCK)
		INNER JOIN CustInfo c WITH (NOLOCK) 
				ON c.CustId = b.CustId	
		WHERE b.ruben = 1
			AND statusID NOT IN (0, 1)
			AND (
				b.winlostdate < @yesterday
				OR NOT EXISTS (SELECT 1 FROM #SportBettype s WHERE s.Bettype = b.bettype)
			)
			AND c.RoleID = 1
		GROUP BY b.CustID
							
    END
    ELSE IF @roleid = 2
    BEGIN
		-- bettransRNG
		INSERT INTO #BalanceInfo (agentCash, yesterdayAgentCash, memberCash, yesterdayMemberCash)
		SELECT 
			SUM(awinlost+comm-playercomm),
			SUM(CASE WHEN winlostdate = @yesterday THEN awinlost+comm-playercomm ELSE 0 END),
			SUM(winlost-actual_stake+playercomm),
			SUM(CASE WHEN winlostdate = @yesterday THEN winlost-actual_stake+playercomm ELSE 0 END)
	    FROM dbo.bettransRNG WITH (NOLOCK)
		WHERE recommend = @__custId
			AND winlostdate >= @yesterday
			AND statusID NOT IN (0, 1)

		-- bettransLC
		INSERT INTO #BalanceInfo (agentCash, yesterdayAgentCash, memberCash, yesterdayMemberCash)
		SELECT 
			SUM(awinlost+comm-playercomm),
			SUM(CASE WHEN winlostdate = @yesterday THEN awinlost+comm-playercomm ELSE 0 END),
			SUM(winlost-actual_stake+playercomm),
			SUM(CASE WHEN winlostdate = @yesterday THEN winlost-actual_stake+playercomm ELSE 0 END)
	    FROM dbo.bettransLC WITH (NOLOCK)
		WHERE recommend = @__custId
			AND winlostdate >= @yesterday
			AND statusID NOT IN (0, 1)

		
		-- bettrans 
		INSERT INTO #BalanceInfo (agentCash, yesterdayAgentCash, memberCash, yesterdayMemberCash)
		SELECT
			SUM(CASE WHEN custid = @__custId THEN winlost-actual_stake ELSE awinlost+comm-playercomm END),
			SUM(CASE WHEN custid = @__custId THEN winlost-actual_stake ELSE awinlost+comm-playercomm END),
			SUM(CASE WHEN custid <> @__custId THEN winlost-actual_stake+playercomm ELSE 0 END),
			SUM(CASE WHEN custid <> @__custId THEN winlost-actual_stake+playercomm ELSE 0 END)
		FROM dbo.bettrans b WITH (NOLOCK)    
		WHERE b.recommend = @__custId
			AND b.ruben = 1
			AND b.winlostdate < @yesterday
						
		;WITH Bettrans_CTE AS (
				SELECT
					Winlostdate, Bettype,
					SUM(CASE WHEN custid = @__custId THEN winlost-actual_stake ELSE awinlost+comm-playercomm END) AS agentCash,
					SUM(CASE WHEN (winlostdate = @yesterday OR b.bettype > 20000) THEN CASE WHEN custid = @__custId THEN winlost-actual_stake ELSE awinlost+comm-playercomm END ELSE 0 END) AS yesterdayAgentCash,
					SUM(CASE WHEN custid <> @__custId THEN winlost-actual_stake+playercomm ELSE 0 END) AS memberCash,
					SUM(CASE WHEN custid <> @__custId AND (winlostdate = @yesterday OR b.bettype > 20000) THEN winlost-actual_stake+playercomm ELSE 0 END) AS yesterdayMemberCash
				FROM dbo.bettrans b WITH (NOLOCK)    
				WHERE b.recommend = @__custId
					AND b.ruben = 1
					AND b.winlostdate >= @yesterday
				GROUP BY Winlostdate, Bettype
		)
		INSERT INTO #BalanceInfo (agentCash, yesterdayAgentCash, memberCash, yesterdayMemberCash)
		SELECT  SUM (agentCash) AS agentCash,
				SUM (yesterdayAgentCash) AS yesterdayAgentCash,
				SUM (memberCash) AS memberCash,
				SUM (yesterdayMemberCash) AS yesterdayMemberCash			   
		FROM Bettrans_CTE b
		WHERE NOT EXISTS (SELECT 1 FROM #SportBettype s WHERE s.Bettype = b.bettype)
    END
    ELSE IF @roleid = 3
    BEGIN
		-- bettransRNG
		INSERT INTO #BalanceInfo (masterCash, yesterdayMasterCash, agentCash, yesterdayAgentCash, memberCash, yesterdayMemberCash)
		SELECT 
			SUM(mwinlost+acomm-comm),
			SUM(CASE WHEN winlostdate = @yesterday THEN mwinlost+acomm-comm ELSE 0 END),
			SUM(awinlost+comm-playercomm),
			SUM(CASE WHEN winlostdate = @yesterday THEN awinlost+comm-playercomm ELSE 0 END),
			SUM(winlost-actual_stake+playercomm),
			SUM(CASE WHEN winlostdate = @yesterday THEN winlost-actual_stake+playercomm ELSE 0 END)
	    FROM dbo.bettransRNG WITH (NOLOCK)
		WHERE mrecommend = @__custId
			AND winlostdate >= @yesterday
			AND statusID NOT IN (0, 1)

		-- bettransLC
		INSERT INTO #BalanceInfo (masterCash, yesterdayMasterCash, agentCash, yesterdayAgentCash, memberCash, yesterdayMemberCash)
		SELECT 
			SUM(mwinlost+acomm-comm),
			SUM(CASE WHEN winlostdate = @yesterday THEN mwinlost+acomm-comm ELSE 0 END),
			SUM(awinlost+comm-playercomm),
			SUM(CASE WHEN winlostdate = @yesterday THEN awinlost+comm-playercomm ELSE 0 END),
			SUM(winlost-actual_stake+playercomm),
			SUM(CASE WHEN winlostdate = @yesterday THEN winlost-actual_stake+playercomm ELSE 0 END)
	    FROM dbo.bettransLC WITH (NOLOCK)
		WHERE mrecommend = @__custId
			AND winlostdate >= @yesterday
			AND statusID NOT IN (0, 1)

		-- bettrans  
		INSERT INTO #BalanceInfo (masterCash, yesterdayMasterCash, agentCash, yesterdayAgentCash, memberCash, yesterdayMemberCash)
		SELECT
			SUM(mwinlost+acomm-comm),
			SUM(mwinlost+acomm-comm),
			SUM(CASE WHEN custid = recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END),
			SUM(CASE WHEN custid = recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END),
			SUM(CASE WHEN custid <> recommend THEN winlost-actual_stake+playercomm ELSE 0 END),
			SUM(CASE WHEN custid <> recommend THEN winlost-actual_stake+playercomm ELSE 0 END)
		FROM dbo.bettrans b WITH (NOLOCK)
		WHERE b.mrecommend = @__custId
			AND (b.recommend * @Id) <> 0 		----  agent, customer level
			AND b.ruben = 1
			AND b.winlostdate < @yesterday
			

		;WITH Bettrans_CTE AS (		
				SELECT
					Winlostdate, Bettype,
					SUM(mwinlost+acomm-comm) AS masterCash,
					SUM(CASE WHEN (winlostdate = @yesterday OR bettype > 20000) THEN mwinlost+acomm-comm ELSE 0 END) AS yesterdayMasterCash ,
					SUM(CASE WHEN custid = recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END) AS agentCash,
					SUM(CASE WHEN (winlostdate = @yesterday OR bettype > 20000) THEN CASE WHEN custid = recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END ELSE 0 END) AS yesterdayAgentCash,
					SUM(CASE WHEN custid <> recommend THEN winlost-actual_stake+playercomm ELSE 0 END) AS memberCash,
					SUM(CASE WHEN (winlostdate = @yesterday OR bettype > 20000) AND custid <> recommend THEN winlost-actual_stake+playercomm ELSE 0 END) AS yesterdayMemberCash
				FROM dbo.bettrans b WITH (NOLOCK)
				WHERE b.mrecommend = @__custId  
					AND (b.recommend * @Id) <> 0 		----  agent, customer level
					AND b.ruben = 1
					AND b.winlostdate >= @yesterday
				GROUP BY Winlostdate, Bettype
			)			
		INSERT INTO #BalanceInfo (masterCash, yesterdayMasterCash, agentCash, yesterdayAgentCash, memberCash, yesterdayMemberCash)
		SELECT
			SUM(masterCash),
			SUM(yesterdayMasterCash),
			SUM(agentCash),
			SUM(yesterdayAgentCash),
			SUM(memberCash),
			SUM(yesterdayMemberCash)
		FROM Bettrans_CTE b
		WHERE NOT EXISTS (SELECT 1 FROM #SportBettype s WHERE s.Bettype = b.bettype)

		-- sum, balance, transfer tickets of this master
		INSERT INTO #BalanceInfo (masterCash, yesterdayMasterCash, agentCash, yesterdayAgentCash, memberCash, yesterdayMemberCash)
		SELECT
			SUM(winlost-actual_stake),
			SUM(CASE WHEN (winlostdate <= @yesterday OR b.bettype > 20000) THEN winlost-actual_stake ELSE 0 END),
			SUM(awinlost+comm-playercomm), ---- = 0 
			SUM(CASE WHEN (winlostdate <= @yesterday OR b.bettype > 20000) THEN awinlost+comm-playercomm ELSE 0 END),  ---- = 0
			0,
			0
		FROM dbo.bettrans b WITH (NOLOCK)
		WHERE custid = @__custId   --- master level
			AND b.matchid = 0
			AND b.bettype >= 19999
			AND b.ruben = 1
    END
    ELSE IF @roleid = 4
    BEGIN
		-- bettransRNG
		INSERT INTO #BalanceInfo (superCash, yesterdaySuperCash, masterCash, yesterdayMasterCash, agentCash, yesterdayAgentCash, memberCash, yesterdayMemberCash)
		SELECT 
			SUM(swinlost+scomm-acomm),
			SUM(CASE WHEN winlostdate = @yesterday THEN swinlost+scomm-acomm ELSE 0 END),
			SUM(mwinlost+acomm-comm),
			SUM(CASE WHEN winlostdate = @yesterday THEN mwinlost+acomm-comm ELSE 0 END),
			SUM(awinlost+comm-playercomm),
			SUM(CASE WHEN winlostdate = @yesterday THEN awinlost+comm-playercomm ELSE 0 END),
			SUM(winlost-actual_stake+playercomm),
			SUM(CASE WHEN winlostdate = @yesterday THEN winlost-actual_stake+playercomm ELSE 0 END)
	    FROM dbo.bettransRNG WITH (NOLOCK)
		WHERE srecommend = @__custId
			AND winlostdate >= @yesterday
			AND statusID NOT IN (0, 1)

		-- bettransLC
		INSERT INTO #BalanceInfo (superCash, yesterdaySuperCash, masterCash, yesterdayMasterCash, agentCash, yesterdayAgentCash, memberCash, yesterdayMemberCash)
		SELECT 
			SUM(swinlost+scomm-acomm),
			SUM(CASE WHEN winlostdate = @yesterday THEN swinlost+scomm-acomm ELSE 0 END),
			SUM(mwinlost+acomm-comm),
			SUM(CASE WHEN winlostdate = @yesterday THEN mwinlost+acomm-comm ELSE 0 END),
			SUM(awinlost+comm-playercomm),
			SUM(CASE WHEN winlostdate = @yesterday THEN awinlost+comm-playercomm ELSE 0 END),
			SUM(winlost-actual_stake+playercomm),
			SUM(CASE WHEN winlostdate = @yesterday THEN winlost-actual_stake+playercomm ELSE 0 END)
	    FROM dbo.bettransLC WITH (NOLOCK)
		WHERE srecommend = @__custId
			AND winlostdate >= @yesterday
			AND statusID NOT IN (0, 1)

		-- bettrans  
		INSERT INTO #BalanceInfo (superCash, yesterdaySuperCash, masterCash, yesterdayMasterCash, agentCash, yesterdayAgentCash, memberCash, yesterdayMemberCash)
		SELECT
			SUM(swinlost+scomm-acomm),
			SUM(swinlost+scomm-acomm),
			SUM(mwinlost+acomm-comm),
			SUM(mwinlost+acomm-comm),
			SUM(CASE WHEN custid = recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END),
			SUM(CASE WHEN custid = recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END),
			SUM(CASE WHEN custid <> recommend THEN winlost-actual_stake+playercomm ELSE 0 END),
			SUM(CASE WHEN custid <> recommend THEN winlost-actual_stake+playercomm ELSE 0 END)
		FROM dbo.bettrans b WITH (NOLOCK)
		WHERE b.srecommend = @__custId
			AND (b.recommend * @Id) <> 0   ---- level agent and customer
			AND b.ruben = 1
			AND b.winlostdate < @yesterday

			
		;WITH Bettrans_CTE AS (
			SELECT winlostdate, Bettype,
				SUM(swinlost+scomm-acomm) superCash,
				SUM(CASE WHEN (winlostdate = @yesterday OR bettype > 20000) THEN swinlost+scomm-acomm ELSE 0 END) yesterdaySuperCash,
				SUM(mwinlost+acomm-comm) masterCash,
				SUM(CASE WHEN (winlostdate = @yesterday OR bettype > 20000) THEN mwinlost+acomm-comm ELSE 0 END) yesterdayMasterCash,
				SUM(CASE WHEN custid = recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END) agentCash,
				SUM(CASE WHEN (winlostdate = @yesterday OR bettype > 20000) THEN CASE WHEN custid = recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END ELSE 0 END) yesterdayAgentCash,
				SUM(CASE WHEN custid <> recommend THEN winlost-actual_stake+playercomm ELSE 0 END) memberCash,
				SUM(CASE WHEN (winlostdate = @yesterday OR bettype > 20000) AND custid <> recommend THEN winlost-actual_stake+playercomm ELSE 0 END) yesterdayMemberCash
			FROM dbo.bettrans b WITH (NOLOCK)
			WHERE b.srecommend = @__custId 
				AND (b.recommend * @Id) <> 0   ---- level agent and customer
				AND b.ruben = 1
				AND b.winlostdate >= @yesterday				
			GROUP BY winlostdate, Bettype 
			)		
		INSERT INTO #BalanceInfo (superCash, yesterdaySuperCash, masterCash, yesterdayMasterCash, agentCash, yesterdayAgentCash, memberCash, yesterdayMemberCash)
		SELECT
			SUM(superCash),
			SUM(yesterdaySuperCash),
			SUM(masterCash),
			SUM(yesterdayMasterCash),
			SUM(agentCash),
			SUM(yesterdayAgentCash),
			SUM(memberCash),
			SUM(yesterdayMemberCash)
		FROM Bettrans_CTE b
		WHERE NOT EXISTS (SELECT 1 FROM #SportBettype s WHERE s.Bettype = b.bettype)
		
		-- sum, balance, transfer tickets of this super and all masters
		INSERT INTO #BalanceInfo (superCash, yesterdaySuperCash, masterCash, yesterdayMasterCash, agentCash, yesterdayAgentCash, memberCash, yesterdayMemberCash)
		SELECT
			SUM(CASE WHEN custid = srecommend THEN winlost-actual_stake ELSE swinlost+scomm-acomm END),
			SUM(CASE WHEN (winlostdate <= @yesterday OR b.bettype > 20000) THEN CASE WHEN custid = srecommend THEN winlost-actual_stake ELSE swinlost+scomm-acomm END ELSE 0 END),
			SUM(CASE WHEN custid = mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END),
			SUM(CASE WHEN (winlostdate <= @yesterday OR b.bettype > 20000) THEN CASE WHEN custid = mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END ELSE 0 END),
			SUM(awinlost+comm-playercomm),
			SUM(CASE WHEN (winlostdate <= @yesterday OR b.bettype > 20000) THEN awinlost+comm-playercomm ELSE 0 END),
			0,
			0
		FROM dbo.bettrans b WITH (NOLOCK)
		WHERE b.srecommend = @__custId
			AND (b.recommend * @Id) = 0   --- level master and super
			AND b.matchid = 0
			AND b.bettype >= 19999
			AND b.ruben = 1
			
    END

	SELECT
		SUM(superCash)				AS superCash,
		SUM(yesterdaySuperCash)		AS yesterdaySuperCash,
		SUM(masterCash)				AS masterCash,
		SUM(yesterdayMasterCash)	AS yesterdayMasterCash,
		SUM(agentCash)				AS agentCash,
		SUM(yesterdayAgentCash)		AS yesterdayAgentCash,
		SUM(memberCash)				AS memberCash,
		SUM(yesterdayMemberCash)	AS yesterdayMemberCash
	FROM #BalanceInfo
	
	DROP TABLE #SportBettype
	DROP TABLE #BalanceInfo
	
END 
GO 