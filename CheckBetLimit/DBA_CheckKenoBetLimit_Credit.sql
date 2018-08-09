
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[DBA_CheckKenoBetLimit_Credit]
	@srecommend INT
	,@RuleId	SMALLINT = 0	
AS
/*
Created: 20180808@Johnson
Task: weekly check Keno bet limit setting for credit/deposit customers - [Redmine:73556]
DB: DB054.CheckResultDB
Revisions:
	
Param's Explanation: 

CustGameType
*/

BEGIN 

	SET NOCOUNT ON 	
	-------------------PREPARATION: GET LIST SUPER/Master/Agent disabled FIRST----------------------------
		
	CREATE TABLE #CGT_Super (custID INT,GameTypeID SMALLINT, minbet MONEY, maxbet MONEY, MaxPerGameType MONEY)
	CREATE TABLE #CGT_Master (custID INT,GameTypeID SMALLINT, minbet MONEY, maxbet MONEY, MaxPerGameType MONEY)
	CREATE TABLE #CGT_Agent (custID INT,GameTypeID SMALLINT, minbet MONEY, maxbet MONEY, MaxPerGameType MONEY)
		
	DECLARE @GameType TABLE(GameTypeID SMALLINT)
	
	BEGIN TRY
		INSERT INTO @GameType (GameTypeID)
		SELECT 
	END TRY
	BEGIN CATCH
	END CATCH
	INSERT INTO #DCS_Super (custID,SportType,BetType,minbet,maxbet,maxpermatch)
	SELECT CPS.CustID,CPS.SportType,CPS.BetType,cps.MinBet,CPS.MaxBet,cps.MaxPerMatch
	FROM CheckCustDB.dbo.CustBetSetting3rd_Agent CPS (NOLOCK)
		INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON CPS.CustID = CI.custid
		INNER JOIN CheckCustDB.dbo.CustSuper CS WITH (NOLOCK)  ON CI.srecommend = CS.custid AND CS.IsInternal = 0
		INNER JOIN @SportBettypeFilter T ON T.SportType = CPS.SportType AND T.BetType = CPS.Bettype
	WHERE CI.roleid = 4 
		AND ci.srecommend = @srecommend
		AND CI.Enabled = 1
		AND CI.Currency NOT IN (20,72,27,28)
		AND CI.username NOT LIKE '%Acc%'
		AND CI.username NOT LIKE '%3rdSuper%'
		AND CI.username NOT LIKE 'STEST%'
		AND CI.username NOT LIKE '%cashout%'
		AND CI.username NOT LIKE '%dummy%'
		AND CI.username NOT LIKE '%BetTrade%'
		AND (cps.MinBet <> 0 OR CPS.MaxBet <> 0 OR CPS.maxpermatch <> 0)
		
	INSERT INTO #DCS_Master (custID,UplineID,SportType,BetType,minbet,maxbet,maxpermatch)
	SELECT CPS.CustID,ci.srecommend,cps.SportType,cps.BetType,cps.MinBet,CPS.MaxBet,cps.MaxPerMatch
	FROM CheckCustDB.dbo.CustBetSetting3rd_Agent CPS (NOLOCK)
		INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON CPS.CustID = CI.custid
		INNER JOIN CheckCustDB.dbo.CustSuper CS WITH (NOLOCK)  ON CI.srecommend = CS.custid AND CS.IsInternal = 0 
		INNER JOIN @SportBettypeFilter T ON T.SportType = CPS.SportType AND T.BetType = CPS.Bettype
	WHERE CI.roleid = 3 
		AND ci.srecommend = @srecommend
		AND CI.Enabled = 1
		AND CI.Currency NOT IN (20,72,27,28)
		AND CI.username NOT LIKE '%Acc%'
		AND CI.username NOT LIKE '%3rdSuper%'
		AND CI.username NOT LIKE 'STEST%'
		AND CI.username NOT LIKE '%cashout%'
		AND CI.username NOT LIKE '%dummy%'
		AND CI.username NOT LIKE '%BetTrade%'
		AND (cps.MinBet <> 0 OR CPS.MaxBet <> 0 OR CPS.maxpermatch <> 0)
			
	INSERT INTO #DCS_Agent (custID,UplineID,SportType,BetType,minbet,maxbet,maxpermatch)
	SELECT CPS.CustID,ci.mrecommend,cps.SportType,cps.BetType,cps.MinBet,CPS.MaxBet,cps.MaxPerMatch
	FROM CheckCustDB.dbo.CustBetSetting3rd_Agent CPS (NOLOCK)
		INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON CPS.CustID = CI.custid
		INNER JOIN CheckCustDB.dbo.CustSuper CS WITH (NOLOCK)  ON CI.srecommend = CS.custid AND CS.IsInternal = 0 
		INNER JOIN @SportBettypeFilter T ON T.SportType = CPS.SportType AND T.BetType = CPS.Bettype
	WHERE CI.roleid = 2 
		AND ci.srecommend = @srecommend
		AND CI.Enabled = 1
		AND CI.Currency NOT IN (20,72,27,28)
		AND CI.username NOT LIKE '%Acc%'
		AND CI.username NOT LIKE '%3rdSuper%'
		AND CI.username NOT LIKE 'STEST%'
		AND CI.username NOT LIKE '%cashout%'
		AND CI.username NOT LIKE '%dummy%'
		AND CI.username NOT LIKE '%BetTrade%'
		AND (cps.MinBet <> 0 OR CPS.MaxBet <> 0 OR CPS.maxpermatch <> 0)
	
	-------------------END OF PREPARATION: GET LIST SUPER/Master/Agent disabled FIRST----------------------------
	----------------------------FINAL RESULT ------------------------------------
	DECLARE @CreatedDate DATETIME = GETDATE()
		
	-- Rule 311: min bet > max bet						
	IF @RuleId IN (0,311)
	BEGIN
		INSERT INTO CheckBetLimitResult_DCS (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		SELECT 311,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.minbet,T1.maxbet,@CreatedDate,0
		FROM #DCS_Super T1
		WHERE T1.minbet > T1.maxbet
		
		UNION ALL
		
		SELECT 311,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.minbet,T1.maxbet,@CreatedDate,0
		FROM #DCS_Master T1
		WHERE T1.minbet > T1.maxbet
		
		UNION ALL
		
		SELECT 311,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.minbet,T1.maxbet,@CreatedDate,0
		FROM #DCS_Agent T1
		WHERE T1.minbet > T1.maxbet
		
		
		UNION ALL
		
		SELECT 311,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.minbet,T1.maxbet,@CreatedDate,0
		FROM CheckCustDB.dbo.CustBetSetting3rd_Member T1 WITH (NOLOCK)
			INNER JOIN  CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON T1.CustID = CI.custid
			INNER JOIN @SportBettypeFilter P ON T1.SportType = p.SportType AND T1.BetType = p.Bettype
		WHERE T1.minbet > T1.maxbet
			AND ci.srecommend = @srecommend
			AND ci.roleid = 1
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
			AND CI.username NOT LIKE '%Acc%'
			AND CI.username NOT LIKE '%3rdSuper%'
			AND CI.username NOT LIKE 'STEST%'
			AND CI.username NOT LIKE '%cashout%'
			AND CI.username NOT LIKE '%dummy%'
			AND CI.username NOT LIKE '%BetTrade%'
		
	END
	
	-- Rule 312: max per match < max bet						
	IF @RuleId IN (0,312)
	BEGIN
		INSERT INTO CheckBetLimitResult_DCS (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		SELECT 312,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.maxpermatch,T1.maxbet,@CreatedDate,0
		FROM #DCS_Super T1
		WHERE T1.maxpermatch < T1.maxbet
		
		UNION ALL
		
		SELECT 312,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.maxpermatch,T1.maxbet,@CreatedDate,0
		FROM #DCS_Master T1
		WHERE T1.maxpermatch < T1.maxbet
		
		UNION ALL
		
		SELECT 312,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.maxpermatch,T1.maxbet,@CreatedDate,0
		FROM #DCS_Agent T1
		WHERE T1.maxpermatch < T1.maxbet
		
		UNION ALL
		
		SELECT 312,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.maxpermatch,T1.maxbet,@CreatedDate,0
		FROM CheckCustDB.dbo.CustBetSetting3rd_Member T1 WITH (NOLOCK) 
			INNER JOIN  CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON T1.CustID = CI.custid
			INNER JOIN @SportBettypeFilter P ON T1.SportType = p.SportType AND T1.BetType = p.Bettype
		WHERE T1.maxpermatch < T1.maxbet
			AND ci.srecommend = @srecommend
			AND ci.roleid = 1
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
			AND CI.username NOT LIKE '%Acc%'
			AND CI.username NOT LIKE '%3rdSuper%'
			AND CI.username NOT LIKE 'STEST%'
			AND CI.username NOT LIKE '%cashout%'
			AND CI.username NOT LIKE '%dummy%'
			AND CI.username NOT LIKE '%BetTrade%'
		
	END
	
	-- Rule 313: Missing bet limit setting, for DCS Products								
	IF @RuleId IN (0,313)
	BEGIN
		INSERT INTO CheckBetLimitResult_DCS (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		SELECT 313,T3.SportType,T3.BetType,CI.custID,CI.custID,NULL,NULL,@CreatedDate,0
		FROM CheckCustDB.dbo.custInfo CI WITH (NOLOCK)
			CROSS JOIN @SportBettypeFilter AS T3
		WHERE CI.custid NOT IN (SELECT custID FROM #DCS_Super T5 WHERE T5.SportType = T3.SportType AND T5.BetType = T3.BetType)
			AND NOT EXISTS (SELECT 1 FROM CheckCustDB.dbo.CustBetSetting3rd_Agent T4 WITH (NOLOCK) WHERE T4.custid = CI.CustID AND T4.SportType = T3.SportType AND T4.BetType = T3.BetType)
			AND CI.roleid = 4
			AND ci.srecommend = @srecommend
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
			AND CI.username NOT LIKE '%Acc%'
			AND CI.username NOT LIKE '%3rdSuper%'
			AND CI.username NOT LIKE 'STEST%'
			AND CI.username NOT LIKE '%cashout%'
			AND CI.username NOT LIKE '%dummy%'
			AND CI.username NOT LIKE '%BetTrade%'
				
		UNION ALL	
		
		SELECT 313,T3.SportType,T3.BetType,CI.custID,CI.custID,NULL,NULL,@CreatedDate,0
		FROM CheckCustDB.dbo.custInfo CI WITH (NOLOCK)
			CROSS JOIN @SportBettypeFilter AS T3
		WHERE CI.custid NOT IN (SELECT custID FROM #DCS_Master T5 WHERE T5.SportType = T3.SportType AND T5.BetType = T3.BetType)
			AND NOT EXISTS (SELECT 1 FROM CheckCustDB.dbo.CustBetSetting3rd_Agent T4 WITH (NOLOCK) WHERE T4.custid = CI.CustID AND T4.SportType = T3.SportType AND T4.BetType = T3.BetType)		
			AND CI.roleid = 3
			AND ci.srecommend = @srecommend
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
			AND CI.username NOT LIKE '%Acc%'
			AND CI.username NOT LIKE '%3rdSuper%'
			AND CI.username NOT LIKE 'STEST%'
			AND CI.username NOT LIKE '%cashout%'
			AND CI.username NOT LIKE '%dummy%'
			AND CI.username NOT LIKE '%BetTrade%'
		
		UNION ALL	
		
		SELECT 313,T3.SportType,T3.BetType,CI.custID,CI.custID,NULL,NULL,@CreatedDate,0
		FROM CheckCustDB.dbo.custInfo CI WITH (NOLOCK)
			CROSS JOIN @SportBettypeFilter AS T3
		WHERE CI.custid NOT IN (SELECT custID FROM #DCS_Agent T5 WHERE T5.SportType = T3.SportType AND T5.BetType = T3.BetType)
			AND NOT EXISTS (SELECT 1 FROM CheckCustDB.dbo.CustBetSetting3rd_Agent T4 WITH (NOLOCK) WHERE T4.custid = CI.CustID AND T4.SportType = T3.SportType AND T4.BetType = T3.BetType)		
			AND CI.roleid = 2
			AND ci.srecommend = @srecommend
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
			AND CI.username NOT LIKE '%Acc%'
			AND CI.username NOT LIKE '%3rdSuper%'
			AND CI.username NOT LIKE 'STEST%'
			AND CI.username NOT LIKE '%cashout%'
			AND CI.username NOT LIKE '%dummy%'
			AND CI.username NOT LIKE '%BetTrade%'
		
		UNION ALL	
		
		SELECT 313,T3.SportType,T3.BetType,CI.custID,CI.custID,NULL,NULL,@CreatedDate,0
		FROM CheckCustDB.dbo.custInfo CI WITH (NOLOCK)
			CROSS JOIN @SportBettypeFilter AS T3
		WHERE NOT EXISTS (SELECT 1 FROM CheckCustDB.dbo.CustBetSetting3rd_Member T4 WITH (NOLOCK) WHERE T4.custid = CI.CustID AND T4.SportType = T3.SportType AND T4.BetType = T3.BetType)		
			AND CI.roleid = 1
			AND ci.srecommend = @srecommend
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
			AND CI.username NOT LIKE '%Acc%'
			AND CI.username NOT LIKE '%3rdSuper%'
			AND CI.username NOT LIKE 'STEST%'
			AND CI.username NOT LIKE '%cashout%'
			AND CI.username NOT LIKE '%dummy%'
			AND CI.username NOT LIKE '%BetTrade%'
		
							
	END
	
	-- Rule 314: minbet < 0								
	IF @RuleId IN (0,314)
	BEGIN
		INSERT INTO CheckBetLimitResult_DCS (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
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
		FROM CheckCustDB.dbo.CustBetSetting3rd_Member T1 WITH (NOLOCK)
			INNER JOIN  CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON T1.CustID = CI.custid
			INNER JOIN @SportBettypeFilter P ON T1.SportType = p.SportType AND T1.BetType = p.Bettype
		WHERE T1.minbet < 0
			AND ci.srecommend = @srecommend
			AND ci.roleid = 1
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
			AND CI.username NOT LIKE '%Acc%'
			AND CI.username NOT LIKE '%3rdSuper%'
			AND CI.username NOT LIKE 'STEST%'
			AND CI.username NOT LIKE '%cashout%'
			AND CI.username NOT LIKE '%dummy%'
			AND CI.username NOT LIKE '%BetTrade%'
		
	END
	
	-- Rule 315: maxbet < 0										
	IF @RuleId IN (0,315)
	BEGIN
		INSERT INTO CheckBetLimitResult_DCS (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
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
		FROM CheckCustDB.dbo.CustBetSetting3rd_Member T1 WITH (NOLOCK)
			INNER JOIN  CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON T1.CustID = CI.custid
			INNER JOIN @SportBettypeFilter P ON T1.SportType = p.SportType AND T1.BetType = p.Bettype
		WHERE T1.maxbet < 0
			AND ci.srecommend = @srecommend
			AND ci.roleid = 1
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
			AND CI.username NOT LIKE '%Acc%'
			AND CI.username NOT LIKE '%3rdSuper%'
			AND CI.username NOT LIKE 'STEST%'
			AND CI.username NOT LIKE '%cashout%'
			AND CI.username NOT LIKE '%dummy%'
			AND CI.username NOT LIKE '%BetTrade%'
		
	END
	
	-- Rule 316: max per match < 0								
	IF @RuleId IN (0,316)
	BEGIN
		INSERT INTO CheckBetLimitResult_DCS (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
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
		FROM CheckCustDB.dbo.CustBetSetting3rd_Member T1 WITH (NOLOCK)
			INNER JOIN  CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON T1.CustID = CI.custid
			INNER JOIN @SportBettypeFilter P ON T1.SportType = p.SportType AND T1.BetType = p.Bettype
		WHERE T1.maxpermatch < 0
			AND ci.srecommend = @srecommend
			AND ci.roleid = 1
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
			AND CI.username NOT LIKE '%Acc%'
			AND CI.username NOT LIKE '%3rdSuper%'
			AND CI.username NOT LIKE 'STEST%'
			AND CI.username NOT LIKE '%cashout%'
			AND CI.username NOT LIKE '%dummy%'
			AND CI.username NOT LIKE '%BetTrade%'
		
	END
	SET NOCOUNT OFF	
		
END