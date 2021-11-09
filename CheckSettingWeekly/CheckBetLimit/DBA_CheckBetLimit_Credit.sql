/*<info serverAlias="DBCHECK-CheckResultDB" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_CheckBetLimit_Credit]
	@srecommend INT
	,@RuleId	SMALLINT = 0
	,@Sporttype SMALLINT = 0
	,@Bettype SMALLINT = 0
	
AS
/*
Created: 20170328@Helen
Task: weekly check bet limit setting for credit/deposit customers - [Redmine:73556]
DB: DBCHECK.CheckResultDB
Revisions:
	-20180802@Johnson: update ruleid [redmine: #73556]
	-20210928@Eden: migrate SB and NG betsetting to new tables [redmine: #158073]
	-20211109@Eden: Break setting for Saba Soccer/Basketball [redmine: #159626]
Param's Explanation: 
	
*/
BEGIN 

	SET NOCOUNT ON 
	-------------------PREPARATION: GET LIST SUPER/Master/Agent disabled FIRST----------------------------
	CREATE TABLE #SportTypeCheck (SportType SMALLINT, BetType SMALLINT, PRIMARY KEY (BetType,SportType) )	
	INSERT INTO #SportTypeCheck 
	SELECT 1,1 UNION ALL
	SELECT 1,9 UNION ALL
	SELECT 2,1 UNION ALL
	SELECT 3,1 UNION ALL
	SELECT 5,1 UNION ALL
	SELECT 8,1 UNION ALL
	SELECT 10,1 UNION ALL
	SELECT 11,1 UNION ALL
	SELECT 99,1 UNION ALL
	SELECT 99,9 UNION ALL
	SELECT 161,81 UNION ALL
	SELECT 164,8101 UNION ALL
	SELECT 9901,1 UNION ALL --saba soccer
	SELECT 9902,1 --saba basketball

	CREATE TABLE #DCS_Super (custID INT,SportType SMALLINT, BetType SMALLINT, minbet MONEY, maxbet MONEY, maxpermatch MONEY
							, MaxPerNumber money, MaxPayoutPerMatch money, PRIMARY KEY (custID,Bettype,SportType))
	
	CREATE TABLE #DCS_Master (custID INT, UplineID INT,SportType SMALLINT, BetType SMALLINT, minbet MONEY, maxbet MONEY, maxpermatch MONEY
							, MaxPerNumber money, MaxPayoutPerMatch money, PRIMARY KEY (custID,Bettype,SportType))
	
	CREATE TABLE #DCS_Agent (custID INT,UplineID INT,SportType SMALLINT, BetType SMALLINT, minbet MONEY, maxbet MONEY, maxpermatch MONEY
							, MaxPerNumber money, MaxPayoutPerMatch money, PRIMARY KEY (custID,Bettype,SportType))
	
	INSERT INTO #DCS_Super (custID,SportType,BetType,minbet,maxbet,maxpermatch,MaxPerNumber,MaxPayoutPerMatch)
	SELECT CPS.CustID,CPS.SportType,CPS.BetType,cps.MinBet,CPS.MaxBet,CPS.maxpermatch,cps.MaxPerNumber,cps.MaxPayoutPerMatch
	FROM CheckCustDB.dbo.CustBetSetting_Agent CPS (NOLOCK)
		INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON CPS.CustID = CI.custid
		INNER JOIN CheckCustDB.dbo.CustSuper CS WITH (NOLOCK)  ON CI.custid = CS.custid AND CS.IsInternal = 0
		INNER JOIN #SportTypeCheck S ON CPS.SportType = s.SportType AND CPS.BetType = s.BetType
	WHERE CI.roleid = 4 
		AND ci.custid = @srecommend
		AND CI.Enabled = 1
		AND CI.Currency NOT IN (20,72,27,28)
		AND (cps.MinBet <> 0 OR CPS.MaxBet <> 0 OR CPS.maxpermatch <> 0 OR CPS.MaxPerNumber <> 0 OR CPS.MaxPayoutPerMatch <> 0)
	
	INSERT INTO #DCS_Master (custID,UplineID,SportType,BetType,minbet,maxbet,maxpermatch,MaxPerNumber,MaxPayoutPerMatch)
	SELECT CPS.CustID,ci.srecommend,CPS.SportType,CPS.BetType,cps.MinBet,CPS.MaxBet,CPS.maxpermatch,cps.MaxPerNumber,cps.MaxPayoutPerMatch
	FROM CheckCustDB.dbo.CustBetSetting_Agent CPS (NOLOCK)
		INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON CPS.CustID = CI.custid
		INNER JOIN CheckCustDB.dbo.CustSuper CS WITH (NOLOCK)  ON CI.srecommend = CS.custid AND CS.IsInternal = 0 
		INNER JOIN #SportTypeCheck S ON CPS.SportType = s.SportType AND CPS.BetType = s.BetType
	WHERE CI.roleid = 3 
		AND ci.srecommend = @srecommend
		AND CI.Enabled = 1
		AND CI.Currency NOT IN (20,72,27,28)
		AND (cps.MinBet <> 0 OR CPS.MaxBet <> 0 OR CPS.maxpermatch <> 0 OR CPS.MaxPerNumber <> 0 OR CPS.MaxPayoutPerMatch <> 0)
		
	INSERT INTO #DCS_Agent (custID,UplineID,SportType,BetType,minbet,maxbet,maxpermatch,MaxPerNumber,MaxPayoutPerMatch)
	SELECT CPS.CustID,ci.mrecommend,CPS.SportType,CPS.BetType,cps.MinBet,CPS.MaxBet,CPS.maxpermatch,cps.MaxPerNumber,cps.MaxPayoutPerMatch
	FROM CheckCustDB.dbo.CustBetSetting_Agent CPS (NOLOCK)
		INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON CPS.CustID = CI.custid
		INNER JOIN CheckCustDB.dbo.CustSuper CS WITH (NOLOCK)  ON CI.srecommend = CS.custid AND CS.IsInternal = 0 
		INNER JOIN #SportTypeCheck S ON CPS.SportType = s.SportType AND CPS.BetType = s.BetType
	WHERE CI.roleid = 2 
		AND ci.srecommend = @srecommend
		AND CI.Enabled = 1
		AND CI.Currency NOT IN (20,72,27,28)
		AND (cps.MinBet <> 0 OR CPS.MaxBet <> 0 OR CPS.maxpermatch <> 0 OR CPS.MaxPerNumber <> 0 OR CPS.MaxPayoutPerMatch <> 0)
	
	-------------------END OF PREPARATION: GET LIST SUPER/Master/Agent disabled FIRST----------------------------
	----------------------------FINAL RESULT ------------------------------------
	DECLARE @CreatedDate DATETIME = GETDATE()
		
	-- Rule 313: Missing bet limit setting
	IF @RuleId IN (0,313)
	BEGIN
		INSERT INTO CheckBetLimitResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		SELECT 313,T3.SportType,T3.BetType,CI.custID,CI.custID,NULL,NULL,@CreatedDate,0
		FROM CheckCustDB.dbo.custInfo CI WITH (NOLOCK)
			CROSS JOIN #SportTypeCheck AS T3
		WHERE CI.custid NOT IN (SELECT custID FROM #DCS_Super T5 WHERE T5.SportType = T3.SportType AND T5.BetType = T3.BetType)
			AND NOT EXISTS (SELECT 1 FROM CheckCustDB.dbo.CustBetSetting_Agent T4 WITH (NOLOCK) WHERE T4.custid = CI.CustID AND T4.SportType = T3.SportType AND T4.BetType = T3.BetType)
			AND CI.roleid = 4
			AND ci.srecommend = @srecommend
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
				
		UNION ALL	
		
		SELECT 313,T3.SportType,T3.BetType,CI.custID,CI.custID,NULL,NULL,@CreatedDate,0
		FROM CheckCustDB.dbo.custInfo CI WITH (NOLOCK)
			CROSS JOIN #SportTypeCheck AS T3
		WHERE CI.custid NOT IN (SELECT custID FROM #DCS_Master T5 WHERE T5.SportType = T3.SportType AND T5.BetType = T3.BetType)
			AND NOT EXISTS (SELECT 1 FROM CheckCustDB.dbo.CustBetSetting_Agent T4 WITH (NOLOCK) WHERE T4.custid = CI.CustID AND T4.SportType = T3.SportType AND T4.BetType = T3.BetType)		
			AND CI.roleid = 3
			AND ci.srecommend = @srecommend
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
		
		UNION ALL	
		
		SELECT 313,T3.SportType,T3.BetType,CI.custID,CI.custID,NULL,NULL,@CreatedDate,0
		FROM CheckCustDB.dbo.custInfo CI WITH (NOLOCK)
			CROSS JOIN #SportTypeCheck AS T3
		WHERE CI.custid NOT IN (SELECT custID FROM #DCS_Agent T5 WHERE T5.SportType = T3.SportType AND T5.BetType = T3.BetType)
			AND NOT EXISTS (SELECT 1 FROM CheckCustDB.dbo.CustBetSetting_Agent T4 WITH (NOLOCK) WHERE T4.custid = CI.CustID AND T4.SportType = T3.SportType AND T4.BetType = T3.BetType)		
			AND CI.roleid = 2
			AND ci.srecommend = @srecommend
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
		
		UNION ALL	
		
		SELECT 313,T3.SportType,T3.BetType,CI.custID,CI.custID,NULL,NULL,@CreatedDate,0
		FROM CheckCustDB.dbo.custInfo CI WITH (NOLOCK)
			CROSS JOIN #SportTypeCheck AS T3
		WHERE NOT EXISTS (SELECT 1 FROM CheckCustDB.dbo.CustBetSetting_Member T4 WITH (NOLOCK) WHERE T4.custid = CI.CustID AND T4.SportType = T3.SportType AND T4.BetType = T3.BetType)		
			AND CI.roleid = 1
			AND ci.srecommend = @srecommend
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)						
	END

	-- Rule 314: minbet < 0								
	IF @RuleId IN (0,314)
	BEGIN
		INSERT INTO CheckBetLimitResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		SELECT 314,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.minbet,T1.minbet,@CreatedDate,0
		FROM #DCS_Super T1
		WHERE T1.minbet < 0
		
		UNION ALL
		
		SELECT 314,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.minbet,T1.minbet,@CreatedDate,0
		FROM #DCS_Master T1
		WHERE T1.minbet < 0
		
		UNION ALL
		
		SELECT 314,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.minbet,T1.minbet,@CreatedDate,0
		FROM #DCS_Agent T1
		WHERE T1.minbet < 0
		
		
		UNION ALL
		
		SELECT 314,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.minbet,T1.minbet,@CreatedDate,0
		FROM CheckCustDB.dbo.CustBetSetting_Member T1 WITH (NOLOCK)
			INNER JOIN  CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON T1.CustID = CI.custid
			INNER JOIN #SportTypeCheck S ON T1.SportType = S.SportType AND T1.Bettype = S.Bettype
		WHERE T1.minbet < 0
			AND ci.srecommend = @srecommend
			AND roleid = 1
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
		
	END
	
	-- Rule 315: maxbet < 0										
	IF @RuleId IN (0,315)
	BEGIN
		INSERT INTO CheckBetLimitResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		SELECT 315,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.maxbet,T1.maxbet,@CreatedDate,0
		FROM #DCS_Super T1
		WHERE T1.maxbet < 0
		
		UNION ALL
		
		SELECT 315,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.maxbet,T1.maxbet,@CreatedDate,0
		FROM #DCS_Master T1
		WHERE T1.maxbet < 0
		
		UNION ALL
		
		SELECT 315,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.maxbet,T1.maxbet,@CreatedDate,0
		FROM #DCS_Agent T1
		WHERE T1.maxbet < 0
		
		
		UNION ALL
		
		SELECT 315,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.maxbet,T1.maxbet,@CreatedDate,0
		FROM CheckCustDB.dbo.CustBetSetting_Member T1 WITH (NOLOCK)
			INNER JOIN  CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON T1.CustID = CI.custid
			INNER JOIN #SportTypeCheck S ON T1.SportType = S.SportType AND T1.Bettype = S.Bettype
		WHERE T1.maxbet < 0
			AND ci.srecommend = @srecommend
			AND roleid = 1
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
		
	END
	
	-- Rule 316: max per match < 0								
	IF @RuleId IN (0,316)
	BEGIN
		INSERT INTO CheckBetLimitResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		SELECT 316,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.maxpermatch,T1.maxpermatch,@CreatedDate,0
		FROM #DCS_Super T1
		WHERE T1.maxpermatch < 0
		
		UNION ALL
		
		SELECT 316,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.maxpermatch,T1.maxpermatch,@CreatedDate,0
		FROM #DCS_Master T1
		WHERE T1.maxpermatch < 0
		
		UNION ALL
		
		SELECT 316,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.maxpermatch,T1.maxpermatch,@CreatedDate,0
		FROM #DCS_Agent T1
		WHERE T1.maxpermatch < 0
		
		UNION ALL
		
		SELECT 316,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.maxpermatch,T1.maxpermatch,@CreatedDate,0
		FROM CheckCustDB.dbo.CustBetSetting_Member T1 WITH (NOLOCK)
			INNER JOIN  CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON T1.CustID = CI.custid
			INNER JOIN #SportTypeCheck S ON T1.SportType = S.SportType AND T1.Bettype = S.Bettype
		WHERE T1.maxpermatch < 0
			AND ci.srecommend = @srecommend
			AND roleid = 1
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
		
	END

	-- Rule 340: max per ball < 0								
	IF @RuleId IN (0,340)
	BEGIN
		INSERT INTO CheckBetLimitResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		SELECT 340,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.MaxPerNumber,T1.MaxPerNumber,@CreatedDate,0
		FROM #DCS_Super T1
		WHERE T1.MaxPerNumber < 0
		
		UNION ALL
		
		SELECT 340,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.MaxPerNumber,T1.MaxPerNumber,@CreatedDate,0
		FROM #DCS_Master T1
		WHERE T1.MaxPerNumber < 0
		
		UNION ALL
		
		SELECT 340,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.MaxPerNumber,T1.MaxPerNumber,@CreatedDate,0
		FROM #DCS_Agent T1
		WHERE T1.MaxPerNumber < 0
		
		UNION ALL
		
		SELECT 340,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.MaxPerNumber,T1.MaxPerNumber,@CreatedDate,0
		FROM CheckCustDB.dbo.CustBetSetting_Member T1 WITH (NOLOCK)
			INNER JOIN  CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON T1.CustID = CI.custid
			INNER JOIN #SportTypeCheck S ON T1.SportType = S.SportType AND T1.Bettype = S.Bettype
		WHERE T1.MaxPerNumber < 0
			AND ci.srecommend = @srecommend
			AND roleid = 1
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
		
	END

	-- Rule 341: max payout per match < 0							
	IF @RuleId IN (0,341)
	BEGIN
		INSERT INTO CheckBetLimitResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		SELECT 341,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.MaxPayoutPerMatch,T1.MaxPayoutPerMatch,@CreatedDate,0
		FROM #DCS_Super T1
		WHERE T1.MaxPayoutPerMatch < 0
		
		UNION ALL
		
		SELECT 341,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.MaxPayoutPerMatch,T1.MaxPayoutPerMatch,@CreatedDate,0
		FROM #DCS_Master T1
		WHERE T1.MaxPayoutPerMatch < 0
		
		UNION ALL
		
		SELECT 341,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.MaxPayoutPerMatch,T1.MaxPayoutPerMatch,@CreatedDate,0
		FROM #DCS_Agent T1
		WHERE T1.MaxPayoutPerMatch < 0
		
		UNION ALL
		
		SELECT 341,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.MaxPayoutPerMatch,T1.MaxPayoutPerMatch,@CreatedDate,0
		FROM CheckCustDB.dbo.CustBetSetting_Member T1 WITH (NOLOCK)
			INNER JOIN  CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON T1.CustID = CI.custid
			INNER JOIN #SportTypeCheck S ON T1.SportType = S.SportType AND T1.Bettype = S.Bettype
		WHERE T1.MaxPayoutPerMatch < 0
			AND ci.srecommend = @srecommend
			AND roleid = 1
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
		
	END
	SET NOCOUNT OFF	
END
GO
