
ALTER PROCEDURE [dbo].[DBA_CheckStakeLevel_Credit]
	 @srecommend INT 
	,@SportType SMALLINT = 0
	,@RuleId	SMALLINT = 0
AS
/*
	Created: 20180718@Johnson
	Task: Check StakeLevel setting on CustGameType for credit customers
	DB: DBCHECK.CheckResultDB
	Revisions:

	Parameter's Explanations:
*/
BEGIN 
	SET NOCOUNT ON
	
	DECLARE @GameType TABLE(SportType INT, GameTypeID INT)
	DECLARE @currency INT, @Rowcount INT
	
	CREATE TABLE #SuperStakeLevel (CustID INT, SportType INT, GameTypeID INT, StakeLevelList VARCHAR(100), PRIMARY KEY(CustID,GameTypeID))
	CREATE TABLE #MasterStakeLevel (CustID INT, SportType INT, GameTypeID INT, StakeLevelList VARCHAR(100), PRIMARY KEY(CustID,GameTypeID))
	CREATE TABLE #AgentStakeLevel (CustID INT, SportType INT, GameTypeID INT, mrecommend INT, StakeLevelList VARCHAR(100), PRIMARY KEY(CustID,GameTypeID))
	CREATE TABLE #MemberStakeLevel (CustID INT, SportType INT, GameTypeID INT, recommend INT, StakeLevelList VARCHAR(100), PRIMARY KEY(CustID,GameTypeID))
	CREATE TABLE #GlobalStakeLevel (GameTypeID INT, StakeLevelList VARCHAR(100))
	
	IF @SportType = 0
	BEGIN
		INSERT INTO @GameType (SportType,GameTypeID)
		SELECT 255,1701--GD
		UNION SELECT 255,1702
	END
	ELSE 
	BEGIN
		IF @sportType = 255
		BEGIN
			INSERT INTO @GameType (SportType, GameTypeID)
			SELECT 255,1701--GD
			UNION SELECT 255,1702
		END	
	END
	
	SELECT @currency = currency 
	FROM CheckCustDB.dbo.custinfo WITH(NOLOCK)
	WHERE custid = @srecommend
	
	SELECT @Rowcount = COUNT(1)
	FROM @GameType
	
	INSERT INTO #GlobalStakeLevel(GameTypeID,StakeLevelList)		
	SELECT GameTypeID,  STUFF((SELECT ',' + cast(StakeLevelID as VARCHAR(10)) 
						from CheckCustDB.dbo.StakeLevel s2 (NOLOCK) 
						where s2.GameTypeID = s1.gametypeid and s2.ExchangeId = @currency
						FOR XML PATH('')
						),1,1,'')
	FROM CheckCustDB.dbo.StakeLevel s1 
	WHERE GameTypeID in (SELECT GameTypeID FROM @GameType)
		AND ExchangeId = @currency
	GROUP BY s1.GameTypeID
	
	INSERT INTO #SuperStakeLevel(custid,GameTypeID,StakeLevelList)
	SELECT cs.custid, GameTypeID, StakeLevelList
	FROM CheckCustDB.dbo.CustGameType cs WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.CustInfo ci WITH(NOLOCK) ON cs.custid = ci.custid
	WHERE ci.custid = @srecommend
		AND GameTypeID IN (SELECT GameTypeID FROM @GameType)
		AND ci.Enabled = 1
		AND ci.Currency NOT IN (20,27,28)
		AND CI.username NOT LIKE '%Acc%'
		AND CI.username NOT LIKE '%3rdSuper%'
		AND CI.username NOT LIKE 'STEST%'
		AND CI.username NOT LIKE '%cashout%'
		AND CI.username NOT LIKE '%dummy%'
		AND CI.username NOT LIKE '%BetTrade%'		 
	
	INSERT INTO #MasterStakeLevel(custid,GameTypeID,StakeLevelList)
	SELECT cs.custid, GameTypeID, StakeLevelList
	FROM CheckCustDB.dbo.CustGameType cs WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.CustInfo ci WITH(NOLOCK) ON cs.custid = ci.custid
	WHERE ci.srecommend = @srecommend
		AND roleid = 3
		AND Enabled = 1
		AND ci.Currency NOT IN (20,27,28)
		AND CI.username NOT LIKE '%Acc%'
		AND CI.username NOT LIKE '%3rdSuper%'
		AND CI.username NOT LIKE 'STEST%'
		AND CI.username NOT LIKE '%cashout%'
		AND CI.username NOT LIKE '%dummy%'
		AND CI.username NOT LIKE '%BetTrade%'		 
		AND GameTypeID IN (SELECT GameTypeID FROM @GameType)
	
	INSERT INTO #AgentStakeLevel(custid,mrecommend,GameTypeID,StakeLevelList)
	SELECT cs.custid, mrecommend, GameTypeID, StakeLevelList
	FROM CheckCustDB.dbo.CustGameType cs WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.CustInfo ci WITH(NOLOCK) ON cs.custid = ci.custid
	WHERE ci.srecommend = @srecommend
		AND roleid = 2
		AND Enabled = 1
		AND ci.Currency NOT IN (20,27,28) 
		AND CI.username NOT LIKE '%Acc%'
		AND CI.username NOT LIKE '%3rdSuper%'
		AND CI.username NOT LIKE 'STEST%'
		AND CI.username NOT LIKE '%cashout%'
		AND CI.username NOT LIKE '%dummy%'
		AND CI.username NOT LIKE '%BetTrade%'	
		AND GameTypeID IN (SELECT GameTypeID FROM @GameType)
	
	INSERT INTO #MemberStakeLevel(custid,recommend,GameTypeID,StakeLevelList)
	SELECT cs.custid, recommend, GameTypeID, StakeLevelList
	FROM CheckCustDB.dbo.CustGameType cs WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.CustInfo ci WITH(NOLOCK) ON cs.custid = ci.custid
	WHERE ci.srecommend = @srecommend
		AND roleid = 1
		AND Enabled = 1
		AND CI.username NOT LIKE '%Acc%'
		AND CI.username NOT LIKE '%3rdSuper%'
		AND CI.username NOT LIKE 'STEST%'
		AND CI.username NOT LIKE '%cashout%'
		AND CI.username NOT LIKE '%dummy%'
		AND CI.username NOT LIKE '%BetTrade%'	
		AND ci.Currency NOT IN (20,27,28) 
		AND GameTypeID IN (SELECT GameTypeID FROM @GameType)
	
	--check missing stake level
	SELECT custid
	INTO #SuperMissingStakeLevel
	FROM #SuperStakeLevel
	GROUP BY custid
	HAVING COUNT(1) < @Rowcount
	
	SELECT custid
	INTO #MasterMissingStakeLevel
	FROM #MasterStakeLevel
	GROUP BY custid
	HAVING COUNT(1) < @Rowcount
	
	SELECT custid
	INTO #AgentMissingStakeLevel
	FROM #AgentStakeLevel
	GROUP BY custid
	HAVING COUNT(1) < @Rowcount
	
	SELECT custid
	INTO #MemberMissingStakeLevel
	FROM #MemberStakeLevel
	GROUP BY custid
	HAVING COUNT(1) < @Rowcount
	
	--miss all stakelevel
	INSERT INTO #SuperMissingStakeLevel(custid)
	SELECT custid	
	FROM CheckCustDB.dbo.CustInfo ci WITH(NOLOCK) 
	WHERE ci.custid = @srecommend
		AND roleid = 4
		AND Enabled = 1
		AND CI.username NOT LIKE '%Acc%'
		AND CI.username NOT LIKE '%3rdSuper%'
		AND CI.username NOT LIKE 'STEST%'
		AND CI.username NOT LIKE '%cashout%'
		AND CI.username NOT LIKE '%dummy%'
		AND CI.username NOT LIKE '%BetTrade%'	
		AND ci.Currency NOT IN (20,27,28) 
		AND NOT EXISTS (SELECT 1 FROM #SuperStakeLevel cs WHERE cs.custid = ci.custid)
	
	INSERT INTO #MasterMissingStakeLevel(custid)
	SELECT custid	
	FROM CheckCustDB.dbo.CustInfo ci WITH(NOLOCK) 
	WHERE srecommend = @srecommend
		AND roleid = 3
		AND Enabled = 1
		AND CI.username NOT LIKE '%Acc%'
		AND CI.username NOT LIKE '%3rdSuper%'
		AND CI.username NOT LIKE 'STEST%'
		AND CI.username NOT LIKE '%cashout%'
		AND CI.username NOT LIKE '%dummy%'
		AND CI.username NOT LIKE '%BetTrade%'	
		AND Currency NOT IN (20,27,28) 
		AND NOT EXISTS (SELECT 1 FROM #MasterStakeLevel cs WHERE cs.custid = ci.custid)
	
	INSERT INTO #AgentMissingStakeLevel(custid)
	SELECT custid	
	FROM CheckCustDB.dbo.CustInfo ci WITH(NOLOCK) 
	WHERE srecommend = @srecommend
		AND roleid = 2
		AND Enabled = 1
		AND Currency NOT IN (20,27,28) 
		AND CI.username NOT LIKE '%Acc%'
		AND CI.username NOT LIKE '%3rdSuper%'
		AND CI.username NOT LIKE 'STEST%'
		AND CI.username NOT LIKE '%cashout%'
		AND CI.username NOT LIKE '%dummy%'
		AND CI.username NOT LIKE '%BetTrade%'	
		AND NOT EXISTS (SELECT 1 FROM #AgentStakeLevel cs WHERE cs.custid = ci.custid)
	
	INSERT INTO #MemberMissingStakeLevel(custid)
	SELECT custid	
	FROM CheckCustDB.dbo.CustInfo ci WITH(NOLOCK) 
	WHERE srecommend = @srecommend
		AND roleid = 1
		AND Enabled = 1
		AND CI.username NOT LIKE '%Acc%'
		AND CI.username NOT LIKE '%3rdSuper%'
		AND CI.username NOT LIKE 'STEST%'
		AND CI.username NOT LIKE '%cashout%'
		AND CI.username NOT LIKE '%dummy%'
		AND CI.username NOT LIKE '%BetTrade%'	
		AND Currency NOT IN (20,27,28) 
		AND NOT EXISTS (SELECT 1 FROM #MemberStakeLevel cs WHERE cs.custid = ci.custid)
	
	IF @ruleid IN (0,301)
	BEGIN
		INSERT INTO CheckResultStakeLevel_Credit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
		SELECT DISTINCT 301 as RuleId,t.sportType,t.GameTypeID,cs1.CustID custidA,0 as custidB, '' as ValueA, '' ValueB
		FROM #SuperMissingStakeLevel cs1
			CROSS APPLY (SELECT SportType, GameTypeID FROM @GameType) t
		WHERE NOT EXISTS (SELECT 1 FROM #SuperStakeLevel cs2 
						WHERE cs1.custid = cs2.custid
							AND t.GameTypeID = cs2.GameTypeID
						)
		
		INSERT INTO CheckResultStakeLevel_Credit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
		SELECT DISTINCT 301 as RuleId,t.sportType,t.GameTypeID,cs1.CustID custidA,0 as custidB, '' as ValueA, '' ValueB
		FROM #MasterMissingStakeLevel cs1
			CROSS APPLY (SELECT SportType, GameTypeID FROM @GameType) t
		WHERE NOT EXISTS (SELECT 1 FROM #MasterStakeLevel cs2 
						WHERE cs1.custid = cs2.custid
							AND t.GameTypeID = cs2.GameTypeID
						)
						
		INSERT INTO CheckResultStakeLevel_Credit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
		SELECT DISTINCT 301 as RuleId,t.sportType,t.GameTypeID,cs1.CustID custidA,0 as custidB, '' as ValueA, '' ValueB
		FROM #AgentMissingStakeLevel cs1
			CROSS APPLY (SELECT SportType, GameTypeID FROM @GameType) t
		WHERE NOT EXISTS (SELECT 1 FROM #AgentStakeLevel cs2 
						WHERE cs1.custid = cs2.custid
							AND t.GameTypeID = cs2.GameTypeID
						)

		INSERT INTO CheckResultStakeLevel_Credit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
		SELECT DISTINCT 301 as RuleId,t.sportType,t.GameTypeID,cs1.CustID custidA,0 as custidB, '' as ValueA, '' ValueB
		FROM #MemberMissingStakeLevel cs1
			CROSS APPLY (SELECT SportType, GameTypeID FROM @GameType) t
		WHERE NOT EXISTS (SELECT 1 FROM #MemberStakeLevel cs2 
						WHERE cs1.custid = cs2.custid
							AND t.GameTypeID = cs2.GameTypeID
						)				
	END
	
	--check stake level super <> global setting		
	IF @ruleid IN (0,302)
	BEGIN
		INSERT INTO CheckResultStakeLevel_Credit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
		SELECT DISTINCT 302 as RuleId,cs1.sportType,cs1.GameTypeID,cs1.CustID custidA,0 as custidB, cs1.StakeLevelList as StakeLevelListA, cs2.StakeLevelList as StakeLevelListB
		FROM #SuperStakeLevel cs1
			CROSS APPLY CheckCustDB.dbo.strSplit(cs1.StakeLevelList,',') t
			INNER JOIN #GlobalStakeLevel cs2 ON cs1.GameTypeID = cs2.GameTypeID
		WHERE CHARINDEX(t.val,cs2.StakeLevelList,0) = 0	
			AND cs1.StakeLevelList <> ''
	END
	
	--stake level master not exist in super		
	IF @ruleid IN (0, 303)
	BEGIN
		INSERT INTO CheckResultStakeLevel_Credit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
		SELECT DISTINCT 303 as RuleId,cs1.sportType,cs1.GameTypeID,cs1.custid custidA,cs2.custid as custidB, cs1.StakeLevelList as StakeLevelListA, cs2.StakeLevelList as StakeLevelListB
		FROM #MasterStakeLevel cs1
			CROSS APPLY CheckCustDB.dbo.strSplit(cs1.StakeLevelList,',') t
			INNER JOIN #SuperStakeLevel cs2 ON cs1.GameTypeID = cs2.GameTypeID										
		WHERE CHARINDEX(t.val,cs2.StakeLevelList,0) = 0
			AND cs1.StakeLevelList <> ''
	END
	
	--stake level agent not exist in master		
	IF @ruleid IN (0, 304)
	BEGIN
		INSERT INTO CheckResultStakeLevel_Credit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
		SELECT DISTINCT 304 as RuleId,cs1.sportType,cs1.GameTypeID,cs1.custid custidA,cs2.custid as custidB, cs1.StakeLevelList as StakeLevelListA, cs2.StakeLevelList as StakeLevelListB
		FROM #AgentStakeLevel cs1
			CROSS APPLY CheckCustDB.dbo.strSplit(cs1.StakeLevelList,',') t
			INNER JOIN #MasterStakeLevel cs2 ON cs1.GameTypeID = cs2.GameTypeID
											AND cs1.mrecommend = cs2.custid	
		WHERE CHARINDEX(t.val,cs2.StakeLevelList,0) = 0
			AND cs1.StakeLevelList <> ''
	END
	
	--stake level member not exist in agent		
	IF @ruleid IN (0, 305)
	BEGIN
		INSERT INTO CheckResultStakeLevel_Credit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
		SELECT DISTINCT 305 as RuleId,cs1.sportType,cs1.GameTypeID,cs1.custid custidA,cs2.custid as custidB, cs1.StakeLevelList as StakeLevelListA, cs2.StakeLevelList as StakeLevelListB
		FROM #MemberStakeLevel cs1			
			INNER JOIN #AgentStakeLevel cs2 ON cs1.GameTypeID = cs2.GameTypeID
											AND cs1.recommend = cs2.custid	
		WHERE CHARINDEX(cs1.StakeLevelList,cs2.StakeLevelList,0) = 0
			AND cs1.StakeLevelList <> ''
	END
END
GO
