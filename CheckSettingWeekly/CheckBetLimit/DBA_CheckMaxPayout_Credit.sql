/*<info serverAlias="DBCHECK-CheckResultDB" executers="" viewers="" isFunction="0"></info>*/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[DBA_CheckMaxPayout_Credit]
	@srecommend INT
	,@RuleId	SMALLINT = 0
	,@Sporttype SMALLINT = 0
	,@Bettype SMALLINT = 0
	
AS
/*
Created: 20210525@winfred
Task: weekly check max payout limit setting for credit customers
DB: DB054.CheckResultDB
Revisions:
	-20210525@winfred: initial SP [redmine: #154104]
Param's Explanation: 
	
	
CustSetting
*/
BEGIN 

	SET NOCOUNT ON 
	-------------------PREPARATION: GET LIST SUPER/Master/Agent disabled FIRST----------------------------

	CREATE TABLE #DCS_Super (custID INT,SportType SMALLINT, BetType SMALLINT, SingleMatchParlay	MONEY,Combo2	MONEY,Combo35	MONEY,ComboOver6	MONEY)
	CREATE TABLE #DCS_Master (custID INT, UplineID INT,SportType SMALLINT, BetType SMALLINT, SingleMatchParlay	MONEY,Combo2	MONEY,Combo35	MONEY,ComboOver6	MONEY)
	CREATE TABLE #DCS_Agent (custID INT,UplineID INT,SportType SMALLINT, BetType SMALLINT, SingleMatchParlay	MONEY,Combo2	MONEY,Combo35	MONEY,ComboOver6	MONEY)
	CREATE TABLE #GlobalSetting([SportType] SMALLINT,BetType SMALLINT,SingleMatchParlay	MONEY,Combo2	MONEY,Combo35	MONEY,ComboOver6	MONEY)
	
	DECLARE @currency INT
	SELECT @currency = currency 
	FROM CheckCustDB.dbo.customer WITH(NOLOCK)
	WHERE custid = @srecommend
	
	INSERT INTO #GlobalSetting (SportType,Bettype,SingleMatchParlay,Combo2,Combo35, ComboOver6)
	SELECT Sporttype,Bettype,SingleMatchParlay,Combo2,Combo35, ComboOver6
	FROM CheckCustDB.dbo.MaxPayoutGlobalSetting ps2 WITH(NOLOCK)
	WHERE ps2.currency  = @currency	AND ps2.SettingStatus = 0 
	AND sportType = CASE WHEN @sportType = 0 THEN sportType ELSE @sportType END
	AND Bettype = CASE WHEN @Bettype = 0 THEN Bettype ELSE @Bettype END
	
	INSERT INTO #DCS_Super (custID,SportType,BetType,SingleMatchParlay,Combo2,Combo35, ComboOver6)
	SELECT CPS.CustID,CPS.SportType,CPS.BetType,cps.SingleMatchParlay,CPS.Combo2,cps.Combo35,cps.ComboOver6
	FROM CheckCustDB.dbo.CustMaxPayoutSetting_Agent CPS (NOLOCK)
		INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON CPS.CustID = CI.custid
		INNER JOIN CheckCustDB.dbo.CustSuper CS WITH (NOLOCK)  ON CI.srecommend = CS.custid AND CS.IsInternal = 0
		INNER JOIN #GlobalSetting T ON T.SportType = CPS.SportType AND T.BetType = CPS.Bettype
	WHERE CI.roleid = 4 
		AND ci.srecommend = @srecommend
		AND CI.Enabled = 1
		AND CI.Currency NOT IN (20,72,27,28)
		AND (cps.SingleMatchParlay <> 0 OR CPS.Combo2 <> 0 OR CPS.Combo35 <> 0 OR CPS.ComboOver6 <> 0)
		
	INSERT INTO #DCS_Master (custID,UplineID,SportType,BetType,SingleMatchParlay,Combo2,Combo35, ComboOver6)
	SELECT CPS.CustID,ci.srecommend,cps.SportType,cps.BetType,cps.SingleMatchParlay,CPS.Combo2,cps.Combo35,cps.ComboOver6
	FROM CheckCustDB.dbo.CustMaxPayoutSetting_Agent CPS (NOLOCK)
		INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON CPS.CustID = CI.custid
		INNER JOIN CheckCustDB.dbo.CustSuper CS WITH (NOLOCK)  ON CI.srecommend = CS.custid AND CS.IsInternal = 0 
		INNER JOIN #GlobalSetting T ON T.SportType = CPS.SportType AND T.BetType = CPS.Bettype
	WHERE CI.roleid = 3 
		AND ci.srecommend = @srecommend
		AND CI.Enabled = 1
		AND CI.Currency NOT IN (20,72,27,28)
		AND (cps.SingleMatchParlay <> 0 OR CPS.Combo2 <> 0 OR CPS.Combo35 <> 0 OR CPS.ComboOver6 <> 0)
			
	INSERT INTO #DCS_Agent (custID,UplineID,SportType,BetType,SingleMatchParlay,Combo2,Combo35, ComboOver6)
	SELECT CPS.CustID,ci.mrecommend,cps.SportType,cps.BetType,cps.SingleMatchParlay,CPS.Combo2,cps.Combo35,cps.ComboOver6
	FROM CheckCustDB.dbo.CustMaxPayoutSetting_Agent CPS (NOLOCK)
		INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON CPS.CustID = CI.custid
		INNER JOIN CheckCustDB.dbo.CustSuper CS WITH (NOLOCK)  ON CI.srecommend = CS.custid AND CS.IsInternal = 0 
		INNER JOIN #GlobalSetting T ON T.SportType = CPS.SportType AND T.BetType = CPS.Bettype
	WHERE CI.roleid = 2 
		AND ci.srecommend = @srecommend
		AND CI.Enabled = 1
		AND CI.Currency NOT IN (20,72,27,28)
		AND (cps.SingleMatchParlay <> 0 OR CPS.Combo2 <> 0 OR CPS.Combo35 <> 0 OR CPS.ComboOver6 <> 0)
	
	-------------------END OF PREPARATION: GET LIST SUPER/Master/Agent disabled FIRST----------------------------
	----------------------------FINAL RESULT ------------------------------------
	DECLARE @CreatedDate DATETIME = GETDATE()
		
	-- Rule 331: Missing Parlay Max Payout setting
	IF @RuleId IN (0,331)
	BEGIN
		INSERT INTO CheckBetLimitResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		SELECT 331,T3.SportType,T3.BetType,CI.custID,CI.custID,NULL,NULL,@CreatedDate,0
		FROM CheckCustDB.dbo.custInfo CI WITH (NOLOCK)
			CROSS JOIN #GlobalSetting AS T3
		WHERE CI.custid NOT IN (SELECT custID FROM #DCS_Super T5 WHERE T5.SportType = T3.SportType AND T5.BetType = T3.BetType)
			AND NOT EXISTS (SELECT 1 FROM CheckCustDB.dbo.CustMaxPayoutSetting_Agent T4 WITH (NOLOCK) WHERE T4.custid = CI.CustID AND T4.SportType = T3.SportType AND T4.BetType = T3.BetType)
			AND CI.roleid = 4
			AND ci.srecommend = @srecommend
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
				
		UNION ALL	
		
		SELECT 331,T3.SportType,T3.BetType,CI.custID,CI.custID,NULL,NULL,@CreatedDate,0
		FROM CheckCustDB.dbo.custInfo CI WITH (NOLOCK)
			CROSS JOIN #GlobalSetting AS T3
		WHERE CI.custid NOT IN (SELECT custID FROM #DCS_Master T5 WHERE T5.SportType = T3.SportType AND T5.BetType = T3.BetType)
			AND NOT EXISTS (SELECT 1 FROM CheckCustDB.dbo.CustMaxPayoutSetting_Agent T4 WITH (NOLOCK) WHERE T4.custid = CI.CustID AND T4.SportType = T3.SportType AND T4.BetType = T3.BetType)		
			AND CI.roleid = 3
			AND ci.srecommend = @srecommend
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
		
		UNION ALL	
		
		SELECT 331,T3.SportType,T3.BetType,CI.custID,CI.custID,NULL,NULL,@CreatedDate,0
		FROM CheckCustDB.dbo.custInfo CI WITH (NOLOCK)
			CROSS JOIN #GlobalSetting AS T3
		WHERE CI.custid NOT IN (SELECT custID FROM #DCS_Agent T5 WHERE T5.SportType = T3.SportType AND T5.BetType = T3.BetType)
			AND NOT EXISTS (SELECT 1 FROM CheckCustDB.dbo.CustMaxPayoutSetting_Agent T4 WITH (NOLOCK) WHERE T4.custid = CI.CustID AND T4.SportType = T3.SportType AND T4.BetType = T3.BetType)		
			AND CI.roleid = 2
			AND ci.srecommend = @srecommend
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
		
		UNION ALL	
		
		SELECT 331,T3.SportType,T3.BetType,CI.custID,CI.custID,NULL,NULL,@CreatedDate,0
		FROM CheckCustDB.dbo.custInfo CI WITH (NOLOCK)
			CROSS JOIN #GlobalSetting AS T3
		WHERE NOT EXISTS (SELECT 1 FROM CheckCustDB.dbo.CustMaxPayoutSetting_Member T4 WITH (NOLOCK) WHERE T4.custid = CI.CustID AND T4.SportType = T3.SportType AND T4.BetType = T3.BetType)		
			AND CI.roleid = 1
			AND ci.srecommend = @srecommend
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
		
							
	END
	
	-- Rule 332: Single Match Parlay < 0								
	IF @RuleId IN (0,332)
	BEGIN
		INSERT INTO CheckBetLimitResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		SELECT 332,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.SingleMatchParlay,T1.SingleMatchParlay,@CreatedDate,0
		FROM #DCS_Super T1
		WHERE T1.SingleMatchParlay < 0
		
		UNION ALL
		
		SELECT 332,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.SingleMatchParlay,T1.SingleMatchParlay,@CreatedDate,0
		FROM #DCS_Master T1
		WHERE T1.SingleMatchParlay < 0
		
		UNION ALL
		
		SELECT 332,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.SingleMatchParlay,T1.SingleMatchParlay,@CreatedDate,0
		FROM #DCS_Agent T1
		WHERE T1.SingleMatchParlay < 0
		
		
		UNION ALL
		
		SELECT 332,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.SingleMatchParlay,T1.SingleMatchParlay,@CreatedDate,0
		FROM CheckCustDB.dbo.CustMaxPayoutSetting_Member T1 WITH (NOLOCK)
			INNER JOIN  CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON T1.CustID = CI.custid
			INNER JOIN #GlobalSetting S ON T1.SportType = S.SportType AND T1.Bettype = S.Bettype
		WHERE T1.SingleMatchParlay < 0
			AND ci.srecommend = @srecommend
			AND roleid = 1
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
		
	END
	
	-- Rule 333: Combo 2 < 0
	IF @RuleId IN (0,333)
	BEGIN
		INSERT INTO CheckBetLimitResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		SELECT 333,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.Combo2,T1.Combo2,@CreatedDate,0
		FROM #DCS_Super T1
		WHERE T1.Combo2 < 0
		
		UNION ALL
		
		SELECT 333,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.Combo2,T1.Combo2,@CreatedDate,0
		FROM #DCS_Master T1
		WHERE T1.Combo2 < 0
		
		UNION ALL
		
		SELECT 333,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.Combo2,T1.Combo2,@CreatedDate,0
		FROM #DCS_Agent T1
		WHERE T1.Combo2 < 0
		
		
		UNION ALL
		
		SELECT 333,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.Combo2,T1.Combo2,@CreatedDate,0
		FROM CheckCustDB.dbo.CustMaxPayoutSetting_Member T1 WITH (NOLOCK)
			INNER JOIN  CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON T1.CustID = CI.custid
			INNER JOIN #GlobalSetting S ON T1.SportType = S.SportType AND T1.Bettype = S.Bettype
		WHERE T1.Combo2 < 0
			AND ci.srecommend = @srecommend
			AND roleid = 1
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
		
	END
	
	-- Rule 334: Combo 3 - 5 < 0
	IF @RuleId IN (0,334)
	BEGIN
		INSERT INTO CheckBetLimitResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		SELECT 334,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.Combo35,T1.Combo35,@CreatedDate,0
		FROM #DCS_Super T1
		WHERE T1.Combo35 < 0
		
		UNION ALL
		
		SELECT 334,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.Combo35,T1.Combo35,@CreatedDate,0
		FROM #DCS_Master T1
		WHERE T1.Combo35 < 0
		
		UNION ALL
		
		SELECT 334,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.Combo35,T1.Combo35,@CreatedDate,0
		FROM #DCS_Agent T1
		WHERE T1.Combo35 < 0
		
		
		UNION ALL
		
		SELECT 334,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.Combo35,T1.Combo35,@CreatedDate,0
		FROM CheckCustDB.dbo.CustMaxPayoutSetting_Member T1 WITH (NOLOCK)
			INNER JOIN  CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON T1.CustID = CI.custid
			INNER JOIN #GlobalSetting S ON T1.SportType = S.SportType AND T1.Bettype = S.Bettype
		WHERE T1.Combo35 < 0
			AND ci.srecommend = @srecommend
			AND roleid = 1
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
		
	END
	-- Rule 335: Combo 6+ < 0
	IF @RuleId IN (0,335)
	BEGIN
		INSERT INTO CheckBetLimitResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		SELECT 335,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.ComboOver6,T1.ComboOver6,@CreatedDate,0
		FROM #DCS_Super T1
		WHERE T1.ComboOver6 < 0
		
		UNION ALL
		
		SELECT 335,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.ComboOver6,T1.ComboOver6,@CreatedDate,0
		FROM #DCS_Master T1
		WHERE T1.ComboOver6 < 0
		
		UNION ALL
		
		SELECT 335,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.ComboOver6,T1.ComboOver6,@CreatedDate,0
		FROM #DCS_Agent T1
		WHERE T1.ComboOver6 < 0
		
		
		UNION ALL
		
		SELECT 335,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.ComboOver6,T1.ComboOver6,@CreatedDate,0
		FROM CheckCustDB.dbo.CustMaxPayoutSetting_Member T1 WITH (NOLOCK)
			INNER JOIN  CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON T1.CustID = CI.custid
			INNER JOIN #GlobalSetting S ON T1.SportType = S.SportType AND T1.Bettype = S.Bettype
		WHERE T1.ComboOver6 < 0
			AND ci.srecommend = @srecommend
			AND roleid = 1
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
		
	END
	
	-- Rule 336: 'Single Match Parlay > Upline Single Match Parlay '
	IF @RuleId IN (0,336)
	BEGIN
		INSERT INTO CheckBetLimitResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )	
		SELECT 336,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.SingleMatchParlay,T2.SingleMatchParlay,@CreatedDate,0
		FROM #DCS_Super T1
		INNER JOIN #GlobalSetting T2 on T1.SportType = T2.SportType AND T1.BetType = T2.Bettype
		WHERE (T1.SingleMatchParlay  > 0  AND T1.SingleMatchParlay > T2.SingleMatchParlay) 
		
		UNION ALL
			
		SELECT 336,T1.SportType,T1.BetType,T1.custID,T2.custID,T1.SingleMatchParlay,T2.SingleMatchParlay,@CreatedDate,0
		FROM #DCS_Master T1
		INNER JOIN #DCS_Super T2 on T1.UplineID = T2.custID  AND T1.SportType = T2.SportType AND T1.BetType = T2.Bettype
		WHERE (T2.SingleMatchParlay  > 0  AND T1.SingleMatchParlay > T2.SingleMatchParlay) 
			 OR (T2.SingleMatchParlay > 0 AND T1.SingleMatchParlay = 0)
		
		UNION ALL
		
		SELECT 336,T1.SportType,T1.BetType,T1.custID,T2.custID,T1.SingleMatchParlay,T2.SingleMatchParlay,@CreatedDate,0
		FROM #DCS_Agent T1
		INNER JOIN #DCS_Master T2 on T1.UplineID = T2.custID  AND T1.SportType = T2.SportType AND T1.BetType = T2.Bettype
		WHERE (T2.SingleMatchParlay  > 0  AND T1.SingleMatchParlay > T2.SingleMatchParlay) 
			 OR (T2.SingleMatchParlay > 0 AND T1.SingleMatchParlay =0)
		
		UNION ALL
		
		SELECT 336,T1.SportType,T1.BetType,T1.custID,T2.custID,T1.SingleMatchParlay,T2.SingleMatchParlay,@CreatedDate,0
		FROM CheckCustDB.dbo.CustMaxPayoutSetting_Member T1 WITH (NOLOCK)
			INNER JOIN  CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON T1.CustID = CI.custid
			INNER JOIN #DCS_Agent T2 ON T1.SportType = T2.SportType AND T1.Bettype = T2.Bettype AND ci.recommend = T2.CustID
		WHERE ((T2.SingleMatchParlay  > 0  AND T1.SingleMatchParlay > T2.SingleMatchParlay)  OR T1.SingleMatchParlay = 0)
			AND ci.srecommend = @srecommend
			AND roleid = 1
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
	END
	-- Rule 337: 'Combo 2 > Upline Combo 2'
	IF @RuleId IN (0,337)
	BEGIN
		INSERT INTO CheckBetLimitResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		SELECT 337,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.SingleMatchParlay,T2.SingleMatchParlay,@CreatedDate,0
		FROM #DCS_Super T1
		INNER JOIN #GlobalSetting T2 on T1.SportType = T2.SportType AND T1.BetType = T2.Bettype
		WHERE (T1.Combo2  > 0  AND T1.Combo2 > T2.Combo2) 
		
		UNION ALL
					
		SELECT 337,T1.SportType,T1.BetType,T1.custID,T2.custID,T1.Combo2,T2.Combo2,@CreatedDate,0
		FROM #DCS_Master T1
		INNER JOIN #DCS_Super T2 on T1.UplineID = T2.custID AND T1.SportType = T2.SportType AND T1.BetType = T2.Bettype
		WHERE (T2.Combo2  > 0  AND T1.Combo2 > T2.Combo2) 
			 OR (T2.Combo2 > 0 AND T1.Combo2 = 0)
		
		UNION ALL
		
		SELECT 337,T1.SportType,T1.BetType,T1.custID,T2.custID,T1.Combo2,T2.Combo2,@CreatedDate,0
		FROM #DCS_Agent T1
		INNER JOIN #DCS_Master T2 on T1.UplineID = T2.custID AND T1.SportType = T2.SportType AND T1.BetType = T2.Bettype
		WHERE (T2.Combo2  > 0  AND T1.Combo2 > T2.Combo2) 
			 OR (T2.Combo2 > 0 AND T1.Combo2 = 0)
				
		UNION ALL
		
		SELECT 337,T1.SportType,T1.BetType,T1.custID,T2.custID,T1.Combo2,T2.Combo2,@CreatedDate,0
		FROM CheckCustDB.dbo.CustMaxPayoutSetting_Member T1 WITH (NOLOCK)
			INNER JOIN  CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON T1.CustID = CI.custid
			INNER JOIN #DCS_Agent T2 ON T1.SportType = T2.SportType AND T1.Bettype = T2.Bettype  AND ci.recommend = T2.CustID
		WHERE ((T2.Combo2  > 0  AND T1.Combo2 > T2.Combo2)  OR T1.Combo2 = 0)
			AND ci.srecommend = @srecommend
			AND roleid = 1
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
	END
	-- Rule 338: 'Combo 3 - 5 > Upline Combo 3 - 5'
	IF @RuleId IN (0,338)
	BEGIN
		INSERT INTO CheckBetLimitResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		SELECT 338,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.SingleMatchParlay,T2.SingleMatchParlay,@CreatedDate,0
		FROM #DCS_Super T1
		INNER JOIN #GlobalSetting T2 on T1.SportType = T2.SportType AND T1.BetType = T2.Bettype
		WHERE (T1.Combo35  > 0  AND T1.Combo35 > T2.Combo35) 
		
		UNION ALL
						
		SELECT 338,T1.SportType,T1.BetType,T1.custID,T2.custID,T1.Combo35,T2.Combo35,@CreatedDate,0
		FROM #DCS_Master T1
		INNER JOIN #DCS_Super T2 on T1.UplineID = T2.custID AND T1.SportType = T2.SportType AND T1.BetType = T2.Bettype
		WHERE (T2.Combo35  > 0  AND T1.Combo35 > T2.Combo35) 
			 OR (T2.Combo35 > 0 AND T1.Combo35 = 0)
		
		UNION ALL
		
		SELECT 338,T1.SportType,T1.BetType,T1.custID,T2.custID,T1.Combo35,T2.Combo35,@CreatedDate,0
		FROM #DCS_Agent T1
		INNER JOIN #DCS_Master T2 on T1.UplineID = T2.custID AND T1.SportType = T2.SportType AND T1.BetType = T2.Bettype
		WHERE (T2.Combo35  > 0  AND T1.Combo35 > T2.Combo35)  
			 OR (T2.Combo35 > 0 AND T1.Combo35 = 0)
				
		UNION ALL
		
		SELECT 338,T1.SportType,T1.BetType,T1.custID,T2.custID,T1.Combo35,T2.Combo35,@CreatedDate,0
		FROM CheckCustDB.dbo.CustMaxPayoutSetting_Member T1 WITH (NOLOCK)
			INNER JOIN  CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON T1.CustID = CI.custid
			INNER JOIN #DCS_Agent T2 ON T1.SportType = T2.SportType AND T1.Bettype = T2.Bettype  AND ci.recommend = T2.CustID
		WHERE((T2.Combo35  > 0  AND T1.Combo35 > T2.Combo35)  OR T1.Combo35 = 0)
			AND ci.srecommend = @srecommend
			AND roleid = 1
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
	END
	-- Rule 339: 'Combo 6+ > Upline Combo 6+'
	IF @RuleId IN (0,339)
	BEGIN	
		INSERT INTO CheckBetLimitResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )	
		SELECT 339,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.SingleMatchParlay,T2.SingleMatchParlay,@CreatedDate,0
		FROM #DCS_Super T1
		INNER JOIN #GlobalSetting T2 on T1.SportType = T2.SportType AND T1.BetType = T2.Bettype
		WHERE (T1.ComboOver6  > 0  AND T1.ComboOver6 > T2.ComboOver6) 
		
		UNION ALL
						
		SELECT 339,T1.SportType,T1.BetType,T1.custID,T2.custID,T1.ComboOver6,T2.ComboOver6,@CreatedDate,0
		FROM #DCS_Master T1
		INNER JOIN #DCS_Super T2 on T1.UplineID = T2.custID AND T1.SportType = T2.SportType AND T1.BetType = T2.Bettype
		WHERE (T2.ComboOver6  > 0  AND T1.ComboOver6 > T2.ComboOver6) 
			 OR (T2.ComboOver6 > 0 AND T1.ComboOver6 = 0)
		
		UNION ALL
		
		SELECT 339,T1.SportType,T1.BetType,T1.custID,T2.custID,T1.ComboOver6,T2.ComboOver6,@CreatedDate,0
		FROM #DCS_Agent T1
		INNER JOIN #DCS_Master T2 on T1.UplineID = T2.custID AND T1.SportType = T2.SportType AND T1.BetType = T2.Bettype
		WHERE (T2.ComboOver6  > 0  AND T1.ComboOver6 > T2.ComboOver6) 
			 OR (T2.ComboOver6 > 0 AND T1.ComboOver6 = 0)
				
		UNION ALL
		
		SELECT 339,T1.SportType,T1.BetType,T1.custID,T2.custID,T1.ComboOver6,T2.ComboOver6,@CreatedDate,0
		FROM CheckCustDB.dbo.CustMaxPayoutSetting_Member T1 WITH (NOLOCK)
			INNER JOIN  CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON T1.CustID = CI.custid
			INNER JOIN #DCS_Agent T2 ON T1.SportType = T2.SportType AND T1.Bettype = T2.Bettype  AND ci.recommend = T2.CustID
		WHERE((T2.ComboOver6  > 0  AND T1.ComboOver6 > T2.ComboOver6)  OR T1.ComboOver6 = 0)
			AND ci.srecommend = @srecommend
			AND roleid = 1
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
	END
	SET NOCOUNT OFF	
		
END

