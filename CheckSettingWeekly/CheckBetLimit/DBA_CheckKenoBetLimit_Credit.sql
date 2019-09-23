
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
		
	CREATE TABLE #CGT_Super (custID INT,SportType INT,GameTypeID SMALLINT, minbet MONEY, maxbet MONEY, MaxPerGameType MONEY)
	CREATE TABLE #CGT_Master (custID INT,SportType INT,GameTypeID SMALLINT, minbet MONEY, maxbet MONEY, MaxPerGameType MONEY)
	CREATE TABLE #CGT_Agent (custID INT,SportType INT,GameTypeID SMALLINT, minbet MONEY, maxbet MONEY, MaxPerGameType MONEY)
		
	DECLARE @GameType TABLE(SportType INT, GameTypeID SMALLINT)
	
	BEGIN TRY
		INSERT INTO @GameType (SportType,GameTypeID)
		SELECT SportType, GameTypeID
		FROM CheckCustDB.dbo.GameType WITH(NOLOCK)
		WHERE GameTypeID NOT IN (2,7,9)-- exclude not offered games
			AND sportType = 202
	END TRY
	BEGIN CATCH
		DECLARE @tmpID TABLE(ID INT IDENTITY(1,1),custID INT)
		DECLARE	@GameTypeID_max INT
				
		INSERT INTO @tmpID(custID)
		SELECT TOP(100) custid--keno only has 100 games from 1 to 100
		FROM CheckCustDB.dbo.custInfo WITH(NOLOCK)
		
		SELECT @GameTypeID_max = max(GameTypeID)
		FROM CheckCustDB.dbo.CustGameType CPS (NOLOCK)
		WHERE GameTypeID < 100--keno
		
		INSERT INTO @GameType (SportType,GameTypeID)
		SELECT 202 as sportType, ID as GameTypeID
		FROM @tmpID
		WHERE ID <= @GameTypeID_max
			AND ID NOT IN (2,7,9)-- exclude not offered games
	END CATCH
	
	INSERT INTO #CGT_Super (custID,SportType,GameTypeID,minbet,maxbet,MaxPerGameType)
	SELECT CPS.CustID,T.SportType,T.GameTypeID,cps.MinBet,CPS.MaxBet,cps.MaxPerGameType
	FROM CheckCustDB.dbo.CustGameType CPS (NOLOCK)
		INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON CPS.CustID = CI.custid
		INNER JOIN CheckCustDB.dbo.CustSuper CS WITH (NOLOCK)  ON CI.srecommend = CS.custid AND CS.IsInternal = 0
		INNER JOIN @GameType T ON T.GameTypeID = cps.GameTypeID
	WHERE CI.roleid = 4 
		AND ci.custid = @srecommend
		AND CI.Enabled = 1
		AND CI.Currency NOT IN (20,72,27,28)		
		AND (cps.MinBet <> 0 OR CPS.MaxBet <> 0 OR CPS.MaxPerGameType <> 0)
		
	INSERT INTO #CGT_Master (custID,SportType,GameTypeID,minbet,maxbet,MaxPerGameType)
	SELECT CPS.CustID,T.SportType,T.GameTypeID,cps.MinBet,CPS.MaxBet,cps.MaxPerGameType
	FROM CheckCustDB.dbo.CustGameType CPS (NOLOCK)
		INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON CPS.CustID = CI.custid
		INNER JOIN CheckCustDB.dbo.CustSuper CS WITH (NOLOCK)  ON CI.srecommend = CS.custid AND CS.IsInternal = 0 
		INNER JOIN @GameType T ON T.GameTypeID = cps.GameTypeID
	WHERE CI.roleid = 3 
		AND ci.srecommend = @srecommend
		AND CI.Enabled = 1
		AND CI.Currency NOT IN (20,72,27,28)		
		AND (cps.MinBet <> 0 OR CPS.MaxBet <> 0 OR CPS.MaxPerGameType <> 0)
			
	INSERT INTO #CGT_Agent (custID,SportType,GameTypeID,minbet,maxbet,MaxPerGameType)
	SELECT CPS.CustID,T.SportType,T.GameTypeID,cps.MinBet,CPS.MaxBet,cps.MaxPerGameType
	FROM CheckCustDB.dbo.CustGameType CPS (NOLOCK)
		INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON CPS.CustID = CI.custid
		INNER JOIN CheckCustDB.dbo.CustSuper CS WITH (NOLOCK)  ON CI.srecommend = CS.custid AND CS.IsInternal = 0 
		INNER JOIN @GameType T ON T.GameTypeID = cps.GameTypeID
	WHERE CI.roleid = 2 
		AND ci.srecommend = @srecommend
		AND CI.Enabled = 1
		AND CI.Currency NOT IN (20,72,27,28)		
		AND (cps.MinBet <> 0 OR CPS.MaxBet <> 0 OR CPS.MaxPerGameType <> 0)
	
	-------------------END OF PREPARATION: GET LIST SUPER/Master/Agent disabled FIRST----------------------------
	----------------------------FINAL RESULT ------------------------------------
	DECLARE @CreatedDate DATETIME = GETDATE()
			
	-- Rule 313: Missing bet limit setting, for keno								
	IF @RuleId IN (0,313)
	BEGIN
		INSERT INTO CheckBetLimitResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		SELECT 313,T.SportType,T.GameTypeID,CI.custID,CI.custID,NULL,NULL,@CreatedDate,0
		FROM CheckCustDB.dbo.custInfo CI WITH (NOLOCK)
			CROSS JOIN @GameType AS T
		WHERE CI.custid NOT IN (SELECT custID FROM #CGT_Super T1 WHERE T1.GameTypeID = T.GameTypeID)
			AND NOT EXISTS (SELECT 1 FROM CheckCustDB.dbo.CustGameType T2 WITH (NOLOCK) WHERE T2.custid = CI.CustID AND T2.GameTypeID = T.GameTypeID)
			AND CI.roleid = 4
			AND ci.custID = @srecommend
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
			
		UNION ALL	
		
		SELECT 313,T.SportType,T.GameTypeID,CI.custID,CI.custID,NULL,NULL,@CreatedDate,0
		FROM CheckCustDB.dbo.custInfo CI WITH (NOLOCK)
			CROSS JOIN @GameType AS T
		WHERE CI.custid NOT IN (SELECT custID FROM #CGT_Master T1 WHERE T1.GameTypeID = T.GameTypeID)
			AND NOT EXISTS (SELECT 1 FROM CheckCustDB.dbo.CustGameType T2 WITH (NOLOCK) WHERE T2.custid = CI.CustID AND T2.GameTypeID = T.GameTypeID)
			AND CI.roleid = 3
			AND ci.srecommend = @srecommend
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
		
		UNION ALL	
		
		SELECT 313,T.SportType,T.GameTypeID,CI.custID,CI.custID,NULL,NULL,@CreatedDate,0
		FROM CheckCustDB.dbo.custInfo CI WITH (NOLOCK)
			CROSS JOIN @GameType AS T
		WHERE CI.custid NOT IN (SELECT custID FROM #CGT_Agent T1 WHERE T1.GameTypeID = T.GameTypeID)
			AND NOT EXISTS (SELECT 1 FROM CheckCustDB.dbo.CustGameType T2 WITH (NOLOCK) WHERE T2.custid = CI.CustID AND T2.GameTypeID = T.GameTypeID)
			AND CI.roleid = 2
			AND ci.srecommend = @srecommend
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
		
		UNION ALL	
		
		SELECT 313,T.SportType,T.GameTypeID,CI.custID,CI.custID,NULL,NULL,@CreatedDate,0
		FROM CheckCustDB.dbo.custInfo CI WITH (NOLOCK)
			CROSS JOIN @GameType AS T
		WHERE CI.custid NOT IN (SELECT custID FROM #CGT_Agent T1 WHERE T1.GameTypeID = T.GameTypeID)
			AND NOT EXISTS (SELECT 1 FROM CheckCustDB.dbo.CustGameType T2 WITH (NOLOCK) WHERE T2.custid = CI.CustID AND T2.GameTypeID = T.GameTypeID)
			AND CI.roleid = 1
			AND ci.srecommend = @srecommend
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)		
							
	END
	
	-- Rule 314: minbet < 0								
	IF @RuleId IN (0,314)
	BEGIN
		INSERT INTO CheckBetLimitResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		SELECT 314,T1.SportType,T1.GameTypeID,T1.custID,T1.custID,T1.minbet,T1.minbet,@CreatedDate,0
		FROM #CGT_Super T1
		WHERE T1.minbet < 0
		
		UNION ALL
		
		SELECT 314,T1.SportType,T1.GameTypeID,T1.custID,T1.custID,T1.minbet,T1.minbet,@CreatedDate,0
		FROM #CGT_Master T1
		WHERE T1.minbet < 0
		
		UNION ALL
		
		SELECT 314,T1.SportType,T1.GameTypeID,T1.custID,T1.custID,T1.minbet,T1.minbet,@CreatedDate,0
		FROM #CGT_Agent T1
		WHERE T1.minbet < 0
		
		
		UNION ALL
		
		SELECT 314,T.SportType,T.GameTypeID,T1.custID,T1.custID,T1.minbet,T1.minbet,@CreatedDate,0
		FROM CheckCustDB.dbo.CustGameType T1 WITH (NOLOCK)
			INNER JOIN  CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON T1.CustID = CI.custid
			INNER JOIN @GameType T ON T.GameTypeID = T1.GameTypeID
		WHERE T1.minbet < 0
			AND ci.srecommend = @srecommend
			AND ci.roleid = 1
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
		
	END
	
	-- Rule 315: maxbet < 0										
	IF @RuleId IN (0,315)
	BEGIN
		INSERT INTO CheckBetLimitResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		SELECT 315,T1.SportType,T1.GameTypeID,T1.custID,T1.custID,T1.maxbet,T1.maxbet,@CreatedDate,0
		FROM #CGT_Super T1
		WHERE T1.maxbet < 0
		
		UNION ALL
		
		SELECT 315,T1.SportType,T1.GameTypeID,T1.custID,T1.custID,T1.maxbet,T1.maxbet,@CreatedDate,0
		FROM #CGT_Master T1
		WHERE T1.maxbet < 0
		
		UNION ALL
		
		SELECT 315,T1.SportType,T1.GameTypeID,T1.custID,T1.custID,T1.maxbet,T1.maxbet,@CreatedDate,0
		FROM #CGT_Agent T1
		WHERE T1.maxbet < 0
		
		
		UNION ALL
		
		SELECT 315,T.SportType,T.GameTypeID,T1.custID,T1.custID,T1.maxbet,T1.maxbet,@CreatedDate,0
		FROM CheckCustDB.dbo.CustGameType T1 WITH (NOLOCK)
			INNER JOIN  CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON T1.CustID = CI.custid
			INNER JOIN @GameType T ON T.GameTypeID = T1.GameTypeID
		WHERE T1.maxbet < 0
			AND ci.srecommend = @srecommend
			AND ci.roleid = 1
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)		
	END
	
	-- Rule 316: max per match < 0								
	IF @RuleId IN (0,316)
	BEGIN
		INSERT INTO CheckBetLimitResult (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		SELECT 316,T1.SportType,T1.GameTypeID,T1.custID,T1.custID,T1.maxpergametype,T1.maxpergametype,@CreatedDate,0
		FROM #CGT_Super T1
		WHERE T1.maxpergametype < 0
		
		UNION ALL
		
		SELECT 316,T1.SportType,T1.GameTypeID,T1.custID,T1.custID,T1.maxpergametype,T1.maxpergametype,@CreatedDate,0
		FROM #CGT_Master T1
		WHERE T1.maxpergametype < 0
		
		UNION ALL
		
		SELECT 316,T1.SportType,T1.GameTypeID,T1.custID,T1.custID,T1.maxpergametype,T1.maxpergametype,@CreatedDate,0
		FROM #CGT_Agent T1
		WHERE T1.maxpergametype < 0
		
		
		UNION ALL
		
		SELECT 316,T.SportType,T.GameTypeID,T1.custID,T1.custID,T1.maxpergametype,T1.maxpergametype,@CreatedDate,0
		FROM CheckCustDB.dbo.CustGameType T1 WITH (NOLOCK)
			INNER JOIN  CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON T1.CustID = CI.custid
			INNER JOIN @GameType T ON T1.GameTypeID = T.GameTypeID
		WHERE T1.maxpergametype < 0
			AND ci.srecommend = @srecommend
			AND ci.roleid = 1
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
		
	END
	SET NOCOUNT OFF	
		
END