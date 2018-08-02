
ALTER PROCEDURE [dbo].[DBA_CheckDCSStakeLevel_Credit]
	 @srecommend INT 
	,@SportType SMALLINT = 0
	,@RuleId	SMALLINT = 0
AS
/*
	Created: 20180726@Johnson
	Task: Check StakeLevel setting on DCS for credit customers
	DB: DBCHECK.CheckResultDB
	Revisions:

	Parameter's Explanations:
*/
BEGIN 
	SET NOCOUNT ON
	
	CREATE TABLE #SuperStakeLevel (CustID INT, SportType INT, bettype INT, StakeLevelList VARCHAR(100), PRIMARY KEY(CustID,SportType,Bettype))
	CREATE TABLE #MasterStakeLevel (CustID INT, SportType INT, bettype INT, StakeLevelList VARCHAR(100), PRIMARY KEY(CustID,SportType,Bettype))
	CREATE TABLE #AgentStakeLevel (CustID INT, SportType INT, bettype INT, mrecommend INT, StakeLevelList VARCHAR(100), PRIMARY KEY(CustID,SportType,Bettype))
	CREATE TABLE #MemberStakeLevel (CustID INT, SportType INT, bettype INT, recommend INT, StakeLevelList VARCHAR(100), PRIMARY KEY(CustID,SportType,Bettype))
	CREATE TABLE #GlobalStakeLevel (sporttype INT, bettype INT, StakeLevelList VARCHAR(100))
	CREATE TABLE #OfferedProductList(ProductID [tinyint],[SportType] [smallint] ,[BetType] [smallint], IsHidden BIT)
	
	DECLARE @SportBettypeFilter TABLE(SportType INT, Bettype INT)
	DECLARE @currency INT,@Site VARCHAR(10), @SiteID INT, @Rowcount INT
	
	SELECT @currency = currency,@site = site 
	FROM CheckCustDB.dbo.customer WITH(NOLOCK)
	WHERE custid = @srecommend
	
	--product has offered stakelevel
	INSERT INTO #OfferedProductList (ProductID, SportType, BetType, IsHidden)
	SELECT DISTINCT ProductID, SportType, BetType, IsHidden
	FROM CheckCustDB.dbo.ProductSettingDetail ps WITH (NOLOCK)		
	WHERE SettingType IN (4,11,13) AND ps.SettingStatus = 0
		AND ps.ProductID in (SELECT productid FROM CheckCustDB.dbo.ProductSettingDetail ps2 WITH(NOLOCK)
							WHERE ps2.SettingType in (7,8)
								AND ps2.sportType = CASE WHEN @sportType = 0 THEN ps2.sportType ELSE @sportType END
							)
			
	UPDATE op
	SET op.IsHidden = stt.IsHidden
	FROM #OfferedProductList op
		INNER JOIN CheckCustDB.dbo.ProductStatusSiteCurrency stt WITH(NOLOCK) ON op.SportType = stt.SportType AND op.Bettype = stt.Bettype
	WHERE stt.Currency = @Currency AND (stt.SiteID = @SiteID OR stt.SiteID = 0)
			
	UPDATE op
	SET op.IsHidden = stt.IsHidden
	FROM #OfferedProductList op
		INNER JOIN CheckCustDB.dbo.ProductStatusSiteCurrency stt WITH(NOLOCK) ON op.SportType = stt.SportType AND op.Bettype = stt.Bettype
	WHERE (stt.Currency = @Currency OR stt.Currency = 0 ) AND stt.SiteID = @SiteID

	INSERT INTO @sportBettypeFilter (sportType,bettype)
	SELECT sportType,bettype
	FROM #OfferedProductList op	
	WHERE op.IsHidden = 0      
	
	SELECT @Rowcount = count(1)
	FROM @SportBettypeFilter
	
	IF @Rowcount = 0
		RETURN
	-- End of DATA PREPARATION	
	
	INSERT INTO #GlobalStakeLevel(sporttype,bettype,StakeLevelList)		
	SELECT t.SportType, s1.GameTypeID,  STUFF((SELECT ',' + cast(StakeLevelID as VARCHAR(10)) 
						FROM CheckCustDB.dbo.StakeLevel s2 (NOLOCK) 
						WHERE s2.GameTypeID = s1.gametypeid and s2.ExchangeId = @currency
						FOR XML PATH('')
						),1,1,'')
	FROM CheckCustDB.dbo.StakeLevel s1 WITH(NOLOCK)
		INNER JOIN @sportBettypeFilter t ON s1.gametypeid = t.bettype
	WHERE ExchangeId = @currency
	GROUP BY t.SportType,  s1.GameTypeID
			
	INSERT INTO #SuperStakeLevel(custid,sporttype,bettype,StakeLevelList)
	SELECT custid, cs.sporttype, cs.bettype, StakeLevelList
	FROM CheckCustDB.dbo.CustStakeLevel_Agent cs WITH(NOLOCK)
		INNER JOIN @sportBettypeFilter t ON cs.sporttype = t.sporttype
											AND cs.bettype = t.bettype
	WHERE custid = @srecommend		
	
	INSERT INTO #MasterStakeLevel(custid,sporttype,bettype,StakeLevelList)
	SELECT cs.custid, cs.sporttype,cs.bettype,StakeLevelList
	FROM CheckCustDB.dbo.CustStakeLevel_Agent cs WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.CustInfo ci WITH(NOLOCK) ON cs.custid = ci.custid
		INNER JOIN @sportBettypeFilter t ON cs.sporttype = t.sporttype
											AND cs.bettype = t.bettype
	WHERE ci.srecommend = @srecommend
		AND roleid = 3
		AND Enabled = 1
		AND ci.Currency NOT IN (20,27,28) 
			
	INSERT INTO #AgentStakeLevel(custid,mrecommend,sporttype,bettype,StakeLevelList)
	SELECT cs.custid, mrecommend, cs.sporttype, cs.bettype, StakeLevelList
	FROM CheckCustDB.dbo.CustStakeLevel_Agent cs WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.CustInfo ci WITH(NOLOCK) ON cs.custid = ci.custid
		INNER JOIN @sportBettypeFilter t ON cs.sporttype = t.sporttype
											AND cs.bettype = t.bettype
	WHERE ci.srecommend = @srecommend
		AND roleid = 2
		AND Enabled = 1
		AND ci.Currency NOT IN (20,27,28) 
			
	INSERT INTO #MemberStakeLevel(custid,recommend,sporttype,bettype,StakeLevelList)
	SELECT cs.custid, recommend, cs.sporttype, cs.bettype, StakeLevelList
	FROM CheckCustDB.dbo.CustStakeLevel_Member cs WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.CustInfo ci WITH(NOLOCK) ON cs.custid = ci.custid
		INNER JOIN @sportBettypeFilter t ON cs.sporttype = t.sporttype
											AND cs.bettype = t.bettype
	WHERE ci.srecommend = @srecommend
		AND roleid = 1
		AND Enabled = 1
		AND ci.Currency NOT IN (20,27,28) 
	
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
		AND ci.Currency NOT IN (20,27,28) 
		AND NOT EXISTS (SELECT 1 FROM #SuperStakeLevel cs WHERE cs.custid = ci.custid)
	
	INSERT INTO #MasterMissingStakeLevel(custid)
	SELECT custid	
	FROM CheckCustDB.dbo.CustInfo ci WITH(NOLOCK) 
	WHERE srecommend = @srecommend
		AND roleid = 3
		AND Enabled = 1
		AND Currency NOT IN (20,27,28) 		
		AND NOT EXISTS (SELECT 1 FROM #MasterStakeLevel cs WHERE cs.custid = ci.custid)
	
	INSERT INTO #AgentMissingStakeLevel(custid)
	SELECT custid	
	FROM CheckCustDB.dbo.CustInfo ci WITH(NOLOCK) 
	WHERE srecommend = @srecommend
		AND roleid = 2
		AND Enabled = 1	
		AND Currency NOT IN (20,27,28) 
		AND NOT EXISTS (SELECT 1 FROM #AgentStakeLevel cs WHERE cs.custid = ci.custid)
	
	INSERT INTO #MemberMissingStakeLevel(custid)
	SELECT custid	
	FROM CheckCustDB.dbo.CustInfo ci WITH(NOLOCK) 
	WHERE srecommend = @srecommend
		AND roleid = 1
		AND Enabled = 1	
		AND Currency NOT IN (20,27,28) 
		AND NOT EXISTS (SELECT 1 FROM #MemberStakeLevel cs WHERE cs.custid = ci.custid)
	
	--check missing setting
	IF @ruleid IN (0,301)
	BEGIN
		INSERT INTO CheckResultStakeLevel_Credit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
		SELECT DISTINCT 301 as RuleId,t.sportType,t.bettype,cs1.CustID custidA,0 as custidB, '' as ValueA, '' ValueB
		FROM #SuperMissingStakeLevel cs1
			CROSS APPLY (SELECT SportType, bettype FROM @sportBettypeFilter) t
		WHERE NOT EXISTS (SELECT 1 FROM #SuperStakeLevel cs2 
						WHERE cs1.custid = cs2.custid
							AND t.bettype = cs2.bettype
							AND t.sportType = cs2.sportType							
						)
		
		INSERT INTO CheckResultStakeLevel_Credit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
		SELECT DISTINCT 301 as RuleId,t.sportType,t.bettype,cs1.CustID custidA,0 as custidB, '' as ValueA, '' ValueB
		FROM #MasterMissingStakeLevel cs1
			CROSS APPLY (SELECT SportType, bettype FROM @sportBettypeFilter) t
		WHERE NOT EXISTS (SELECT 1 FROM #MasterStakeLevel cs2 
						WHERE cs1.custid = cs2.custid
							AND t.bettype = cs2.bettype
							AND t.sportType = cs2.sportType	
						)
						
		INSERT INTO CheckResultStakeLevel_Credit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
		SELECT DISTINCT 301 as RuleId,t.sportType,t.bettype,cs1.CustID custidA,0 as custidB, '' as ValueA, '' ValueB
		FROM #AgentMissingStakeLevel cs1
			CROSS APPLY (SELECT SportType, bettype FROM @sportBettypeFilter) t
		WHERE NOT EXISTS (SELECT 1 FROM #AgentStakeLevel cs2 
						WHERE cs1.custid = cs2.custid
							AND t.bettype = cs2.bettype
							AND t.sportType = cs2.sportType	
						)

		INSERT INTO CheckResultStakeLevel_Credit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
		SELECT DISTINCT 301 as RuleId,t.sportType,t.bettype,cs1.CustID custidA,0 as custidB, '' as ValueA, '' ValueB
		FROM #MemberMissingStakeLevel cs1
			CROSS APPLY (SELECT SportType, bettype FROM @sportBettypeFilter) t
		WHERE NOT EXISTS (SELECT 1 FROM #MemberStakeLevel cs2 
						WHERE cs1.custid = cs2.custid
							AND t.bettype = cs2.bettype
							AND t.sportType = cs2.sportType	
						)				
	END
	
	--check stake level super <> global setting		
	IF @ruleid IN (0,302)
	BEGIN
		INSERT INTO CheckResultStakeLevel_Credit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
		SELECT DISTINCT 302 as RuleId,cs1.sportType,cs1.bettype,cs1.CustID custidA,0 as custidB, cs1.StakeLevelList as StakeLevelListA, cs2.StakeLevelList as StakeLevelListB
		FROM #SuperStakeLevel cs1
			CROSS APPLY CheckCustDB.dbo.strSplit(cs1.StakeLevelList,',') t
			INNER JOIN #GlobalStakeLevel cs2 ON cs1.bettype = cs2.bettype
		WHERE CHARINDEX(t.val,cs2.StakeLevelList,0) = 0	
			AND cs1.StakeLevelList <> ''
	END
	
	--stake level master not exist in super		
	IF @ruleid IN (0, 303)
	BEGIN
		INSERT INTO CheckResultStakeLevel_Credit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
		SELECT DISTINCT 303 as RuleId,cs1.sportType,cs1.bettype,cs1.custid custidA,cs2.custid as custidB, cs1.StakeLevelList as StakeLevelListA, cs2.StakeLevelList as StakeLevelListB
		FROM #MasterStakeLevel cs1
			CROSS APPLY CheckCustDB.dbo.strSplit(cs1.StakeLevelList,',') t
			INNER JOIN #SuperStakeLevel cs2 ON cs1.bettype = cs2.bettype
											AND cs1.sporttype = cs2.sportType		
		WHERE CHARINDEX(t.val,cs2.StakeLevelList,0) = 0
			AND cs1.StakeLevelList <> ''
	END
	
	--stake level agent not exist in master		
	IF @ruleid IN (0, 304)
	BEGIN
		INSERT INTO CheckResultStakeLevel_Credit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
		SELECT DISTINCT 304 as RuleId,cs1.sportType,cs1.bettype,cs1.custid custidA,cs2.custid as custidB, cs1.StakeLevelList as StakeLevelListA, cs2.StakeLevelList as StakeLevelListB
		FROM #AgentStakeLevel cs1
			CROSS APPLY CheckCustDB.dbo.strSplit(cs1.StakeLevelList,',') t
			INNER JOIN #MasterStakeLevel cs2 ON cs1.bettype = cs2.bettype
											AND cs1.sporttype = cs2.sportType
											AND cs1.mrecommend = cs2.custid	
		WHERE CHARINDEX(t.val,cs2.StakeLevelList,0) = 0
			AND cs1.StakeLevelList <> ''
	END
	
	--stake level member not exist in agent		
	IF @ruleid IN (0, 305)
	BEGIN
		INSERT INTO CheckResultStakeLevel_Credit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
		SELECT DISTINCT 305 as RuleId,cs1.sportType,cs1.bettype,cs1.custid custidA,cs2.custid as custidB, cs1.StakeLevelList as StakeLevelListA, cs2.StakeLevelList as StakeLevelListB
		FROM #MemberStakeLevel cs1			
			INNER JOIN #AgentStakeLevel cs2 ON cs1.bettype = cs2.bettype
											AND cs1.sporttype = cs2.sportType
											AND cs1.recommend = cs2.custid	
		WHERE CHARINDEX(cs1.StakeLevelList,cs2.StakeLevelList,0) = 0
			AND cs1.StakeLevelList <> ''
	END	
END
GO
	