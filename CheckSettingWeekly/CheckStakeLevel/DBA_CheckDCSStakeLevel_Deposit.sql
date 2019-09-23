/*<info serverAlias="DBCHECK-CheckResultDB" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_CheckDCSStakeLevel_Deposit]
	 @srecommend INT 
	,@SportType SMALLINT = 0
	,@RuleId	SMALLINT = 0
AS
/*
	Created: 20180726@Johnson
	Task: Check DCS StakeLevel setting on CustGameType for deposit customers
	DB: DBCHECK.CheckResultDB
	Revisions:
		- 20190130@Winnie:	Remove ClearBal Acc - [Redmine: #73556]
		- 20190801@Winnie: Change Check stake level RedmineID:#117919
	Parameter's Explanations:
*/
BEGIN 
	SET NOCOUNT ON
	
	CREATE TABLE #SuperStakeLevel (CustID INT, SportType INT, bettype INT, StakeLevelList VARCHAR(100), PRIMARY KEY(CustID,SportType , bettype))
	CREATE TABLE #MasterStakeLevel (CustID INT, SportType INT, bettype INT, StakeLevelList VARCHAR(100), PRIMARY KEY(CustID,SportType , bettype))
	CREATE TABLE #AgentStakeLevel (CustID INT, SportType INT, bettype INT, mrecommend INT, StakeLevelList VARCHAR(100), PRIMARY KEY(CustID,SportType , bettype))
	CREATE TABLE #MemberStakeLevel (CustID INT, SportType INT, bettype INT, recommend INT, StakeLevelList VARCHAR(100), PRIMARY KEY(CustID,SportType , bettype))
	CREATE TABLE #GlobalStakeLevel (sporttype INT, bettype INT, StakeLevelList VARCHAR(100))
	CREATE TABLE #OfferedProductList(ProductID TINYINT, ProductSettingID INT,SportType SMALLINT ,BetType SMALLINT)	
	DECLARE @SportBettypeFilter TABLE(SportType INT, Bettype INT)
	DECLARE @currency INT, @rowcount INT
		
	SELECT @currency = currency 
	FROM CheckCustDB.dbo.custinfo WITH(NOLOCK)
	WHERE custid = @srecommend
	
	--product has offered stakelevel
	INSERT INTO #OfferedProductList (ProductID, ProductSettingID, SportType, BetType)
	SELECT DISTINCT ProductID, ps.ProductSettingID, SportType, BetType
	FROM CheckCustDB.dbo.Dep_ProductSetting pd WITH (NOLOCK)
		INNER JOIN CheckCustDB.dbo.Dep_ProductSettingDetail ps WITH(NOLOCK) ON pd.ProductSettingID = ps.ProductSettingID
	WHERE pd.SettingType IN (7,8) 
		AND ps.SettingStatus = 0
		AND ps.sportType = CASE WHEN @sportType = 0 THEN ps.sportType ELSE @sportType END
						
	--get sport/bettype has stakelevel setting for this licensee
	INSERT INTO @SportBettypeFilter(sporttype,bettype)
	SELECT sporttype, bettype
	FROM #OfferedProductList op
		INNER JOIN CheckCustDB.dbo.Dep_LicenseeProductSetting ls WITH(NOLOCK) ON ls.custid = @srecommend
																				AND ls.ProductSettingID = op.ProductSettingID		
	SELECT @Rowcount = count(1)
	FROM @SportBettypeFilter
	
	IF @Rowcount = 0
		RETURN
		
	INSERT INTO #GlobalStakeLevel(sporttype,bettype,StakeLevelList)		
	SELECT t.sportType,s1.GameTypeID,  STUFF((SELECT ',' + cast(StakeLevelID as VARCHAR(10)) 
						FROM CheckCustDB.dbo.Dep_StakeLevel s2 (NOLOCK) 
						WHERE s2.GameTypeID = s1.gametypeid and s2.ExchangeId = @currency
						FOR XML PATH('')
						),1,1,'')
	FROM CheckCustDB.dbo.Dep_StakeLevel s1 WITH(NOLOCK)
		INNER JOIN @sportBettypeFilter t ON s1.gametypeid = t.bettype
	WHERE ExchangeId = @currency
	GROUP BY t.sportType,s1.GameTypeID
			
	INSERT INTO #SuperStakeLevel(custid,sporttype,bettype,StakeLevelList)
	SELECT custid, cs.sporttype, cs.bettype, StakeLevelList
	FROM CheckCustDB.dbo.Dep_CustStakeLevel_Agent cs WITH(NOLOCK)
		INNER JOIN @sportBettypeFilter t ON cs.sporttype = t.sporttype
											AND cs.bettype = t.bettype
	WHERE custid = @srecommend		
	
	INSERT INTO #MasterStakeLevel(custid,sporttype,bettype,StakeLevelList)
	SELECT cs.custid, cs.sporttype,cs.bettype,StakeLevelList
	FROM CheckCustDB.dbo.Dep_CustStakeLevel_Agent cs WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.CustInfo ci WITH(NOLOCK) ON cs.custid = ci.custid
		INNER JOIN @sportBettypeFilter t ON cs.sporttype = t.sporttype
											AND cs.bettype = t.bettype
	WHERE srecommend = @srecommend
		AND roleid = 3
		AND Currency NOT IN (20,72,27,28)
		AND Enabled = 1
			
	INSERT INTO #AgentStakeLevel(custid,mrecommend,sporttype,bettype,StakeLevelList)
	SELECT cs.custid, mrecommend, cs.sporttype, cs.bettype, StakeLevelList
	FROM CheckCustDB.dbo.Dep_CustStakeLevel_Agent cs WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.CustInfo ci WITH(NOLOCK) ON cs.custid = ci.custid
		INNER JOIN @sportBettypeFilter t ON cs.sporttype = t.sporttype
											AND cs.bettype = t.bettype
	WHERE srecommend = @srecommend
		AND roleid = 2
		AND Currency NOT IN (20,72,27,28)
		AND Enabled = 1
			
	INSERT INTO #MemberStakeLevel(custid,recommend,sporttype,bettype,StakeLevelList)
	SELECT cs.custid, recommend, cs.sporttype, cs.bettype, StakeLevelList
	FROM CheckCustDB.dbo.Dep_CustStakeLevel_Member cs WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.CustInfo ci WITH(NOLOCK) ON cs.custid = ci.custid
		INNER JOIN @sportBettypeFilter t ON cs.sporttype = t.sporttype
											AND cs.bettype = t.bettype
	WHERE ci.srecommend = @srecommend
		AND roleid = 1
		AND Currency NOT IN (20,72,27,28)
		AND Enabled = 1
	--END PREPARATION DATA
	
	--check missing setting
	IF @ruleid IN (0,301)
	BEGIN
		INSERT INTO CheckResultStakeLevel_Deposit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
		SELECT DISTINCT 301 as RuleId,t.sportType,t.bettype,ci.CustID custidA,0 as custidB, '' as ValueA, '' ValueB
		FROM CheckCustDB.dbo.CustInfo ci WITH(NOLOCK) 
			CROSS APPLY (SELECT SportType, bettype FROM #GlobalStakeLevel) t
		WHERE ci.custid = @srecommend
			AND roleid = 4
			AND Enabled = 1			
			AND Currency NOT IN (20,72,27,28) 
			AND NOT EXISTS (SELECT 1 FROM #SuperStakeLevel cs2 
						WHERE ci.custid = cs2.custid
							AND t.bettype = cs2.bettype
							AND t.sportType = cs2.sportType							
						)
		
		INSERT INTO CheckResultStakeLevel_Deposit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
		SELECT DISTINCT 301 as RuleId,t.sportType,t.bettype,ci.CustID custidA,0 as custidB, '' as ValueA, '' ValueB
		FROM CheckCustDB.dbo.CustInfo ci WITH(NOLOCK) 
			CROSS APPLY (SELECT SportType, bettype FROM #GlobalStakeLevel) t
		WHERE ci.srecommend = @srecommend
			AND roleid = 3
			AND Enabled = 1
			AND mrecommend NOT IN (SELECT custid 
									FROM CheckCustDB.dbo.custinfo WITH(NOLOCK)
									WHERE srecommend=@srecommend 
										AND username like '%Acc%' AND roleid=3)
			AND Currency NOT IN (20,72,27,28) 
			AND NOT EXISTS (SELECT 1 FROM #MasterStakeLevel cs2 
						WHERE ci.custid = cs2.custid
							AND t.bettype = cs2.bettype
							AND t.sportType = cs2.sportType	
						)
						
		INSERT INTO CheckResultStakeLevel_Deposit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
		SELECT DISTINCT 301 as RuleId,t.sportType,t.bettype,ci.CustID custidA,0 as custidB, '' as ValueA, '' ValueB
		FROM CheckCustDB.dbo.CustInfo ci WITH(NOLOCK) 
			CROSS APPLY (SELECT SportType, bettype FROM #GlobalStakeLevel) t
		WHERE ci.srecommend = @srecommend
			AND roleid = 2
			AND Enabled = 1
			AND mrecommend NOT IN (SELECT custid 
									FROM CheckCustDB.dbo.custinfo WITH(NOLOCK)
									WHERE srecommend=@srecommend 
										AND username like '%Acc%' AND roleid=3)
			AND Currency NOT IN (20,72,27,28) 
			AND NOT EXISTS (SELECT 1 FROM #AgentStakeLevel cs2 
						WHERE ci.custid = cs2.custid
							AND t.bettype = cs2.bettype
							AND t.sportType = cs2.sportType	
						)

		INSERT INTO CheckResultStakeLevel_Deposit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
		SELECT DISTINCT 301 as RuleId,t.sportType,t.bettype,ci.CustID custidA,0 as custidB, '' as ValueA, '' ValueB
		FROM CheckCustDB.dbo.CustInfo ci WITH(NOLOCK) 
			CROSS APPLY (SELECT SportType, bettype FROM #GlobalStakeLevel) t
		WHERE ci.srecommend = @srecommend
			AND roleid = 1
			AND Enabled = 1
			AND mrecommend NOT IN (SELECT custid 
									FROM CheckCustDB.dbo.custinfo WITH(NOLOCK)
									WHERE srecommend=@srecommend 
										AND username like '%Acc%' AND roleid=3)
			AND Currency NOT IN (20,72,27,28) 
			AND ci.username NOT LIKE '%cashout%'
			AND ci.username NOT LIKE '%BetTrade%'
			AND ci.username NOT LIKE '%ClearBal%'
			AND NOT EXISTS (SELECT 1 FROM #MemberStakeLevel cs2 
						WHERE ci.custid = cs2.custid
							AND t.bettype = cs2.bettype
							AND t.sportType = cs2.sportType	
						)				
	END
	
	--check stake level super <> global setting		
	IF @ruleid IN (0,302)
	BEGIN
		INSERT INTO CheckResultStakeLevel_Deposit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
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
		INSERT INTO CheckResultStakeLevel_Deposit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
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
		INSERT INTO CheckResultStakeLevel_Deposit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
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
		INSERT INTO CheckResultStakeLevel_Deposit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
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
	