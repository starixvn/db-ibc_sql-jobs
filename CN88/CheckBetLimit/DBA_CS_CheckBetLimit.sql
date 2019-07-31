/*<info serverAlias="DBCHECK-CheckResultDB" executers="" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_CS_CheckBetLimit]
	 @srecommend INT 
	,@SportType SMALLINT = 0
	,@RuleId	SMALLINT = 0
AS
/*
	Created: 20190723@Johnson
	Task: Weekly check PT setting for CN88
	DB: DBCHECK.CheckResultDB
	
	Revisions:
		- 20190723@Johnson: Initial sp [redmine: #116922]
*/	
BEGIN 
	SET NOCOUNT ON
	
	CREATE TABLE #SuperBL (custid INT, sporttype INT, bettype INT, isLive BIT, MaxBet MONEY, MaxPerEvent MONEY)
	CREATE TABLE #MasterBL (custid INT, srecommend INT, sporttype INT, bettype INT, isLive BIT, MaxBet MONEY, MaxPerEvent MONEY)
	CREATE TABLE #AgentBL (custid INT, srecommend INT, mrecommend INT, sporttype INT, bettype INT, isLive BIT, MaxBet MONEY, MaxPerEvent MONEY)
	CREATE TABLE #MemberBL (custid INT, srecommend INT, mrecommend INT, recommend INT, sporttype INT, bettype INT, isLive BIT, MaxBet MONEY, MaxPerEvent MONEY)
	
	INSERT INTO #SuperBL(custid,sporttype,bettype,isLive,MaxBet,MaxPerEvent)
	SELECT custid,sporttype,bettype,isLive,MaxBet,MaxPerEvent
	FROM CheckCustDB.dbo.CS_CustBetSetting_Agent cs WITH(NOLOCK)
	WHERE custid = @srecommend
		AND sporttype = CASE WHEN @sporttype = 0 THEN cs.sporttype ELSE @sporttype END
		
	INSERT INTO #MasterBL(custid,srecommend,sporttype,bettype,isLive,MaxBet,MaxPerEvent)
	SELECT custid,srecommend,sporttype,bettype,isLive,MaxBet,MaxPerEvent
	FROM  CheckCustDB.dbo.custinfo ci WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.CS_CustBetSetting_Agent cs WITH(NOLOCK) ON ci.custid = cs.custid
	WHERE custid = @srecommend
		AND sporttype = CASE WHEN @sporttype = 0 THEN cs.sporttype ELSE @sporttype END
		AND roleid = 3
		AND enabled = 1
	
	INSERT INTO #AgentBL(custid,srecommend,mrecommend,sporttype,bettype,isLive,MaxBet,MaxPerEvent)
	SELECT custid,srecommend,mrecommend,sporttype,bettype,isLive,MaxBet,MaxPerEvent
	FROM  CheckCustDB.dbo.custinfo ci WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.CS_CustBetSetting_Agent cs WITH(NOLOCK) ON ci.custid = cs.custid
	WHERE custid = @srecommend
		AND sporttype = CASE WHEN @sporttype = 0 THEN cs.sporttype ELSE @sporttype END
		AND roleid = 2
		AND enabled = 1
	
	INSERT INTO #MemberBL(custid,srecommend,mrecommend,recommend,sporttype,bettype,isLive,MaxBet,MaxPerEvent)
	SELECT custid,srecommend,mrecommend,recommend,sporttype,bettype,isLive,MaxBet,MaxPerEvent
	FROM  CheckCustDB.dbo.custinfo ci WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.CS_CustBetSetting_Member cs WITH(NOLOCK) ON ci.custid = cs.custid
	WHERE custid = @srecommend
		AND sporttype = CASE WHEN @sporttype = 0 THEN cs.sporttype ELSE @sporttype END
		AND roleid = 1
		AND enabled = 1
		
	--rule 1: super maxbet < master maxbet 
	IF @ruleid IN (0,10201)
	BEGIN	
		INSERT INTO dbo.CS_CheckBetLimitResult(ruleID,SportType,bettype,isLive,CustIDA,custidB,ValueA,ValueB)
		SELECT 10201, cs.SportType, cs.bettype, cs.isLive, cs.custID as CustIDA, mcs.custid as custidB, cs.MaxBet ValueA,mcs.MaxBet ValueB
		FROM #SuperBL cs
			INNER JOIN #MasterBL mcs ON mcs.srecommend = cs.custid
									AND mcs.sporttype = cs.sporttype
									AND mcs.bettype = cs.bettype
									AND mcs.isLive = cs.isLive
		WHERE cs.MaxBet < mcs.MaxBet	
	END
	
	--rule 2: super MaxPerEvent < master MaxPerEvent  
	IF @ruleid IN (0,10202)
	BEGIN
		INSERT INTO dbo.CS_CheckBetLimitResult(ruleID,SportType,bettype,isLive,CustIDA,custidB,ValueA,ValueB)
		SELECT 10202, cs.SportType, cs.bettype, cs.isLive, cs.custID as CustIDA, mcs.custid as custidB, cs.MaxPerEvent ValueA,mcs.MaxPerEvent ValueB
		FROM #SuperBL cs
			INNER JOIN #MasterBL mcs ON mcs.srecommend = cs.custid
									AND mcs.sporttype = cs.sporttype
									AND mcs.bettype = cs.bettype
									AND mcs.isLive = cs.isLive
		WHERE cs.MaxPerEvent < mcs.MaxPerEvent
	END
	
	--rule 3: master maxbet < agent maxbet  
	IF @ruleid IN (0,10203)
	BEGIN
		INSERT INTO dbo.CS_CheckBetLimitResult(ruleID,SportType,bettype,isLive,CustIDA,custidB,ValueA,ValueB)
		SELECT 10203, cs.SportType, cs.bettype, cs.isLive, cs.custID as CustIDA, acs.custid as custidB, cs.MaxBet ValueA,acs.MaxBet ValueB
		FROM #MasterBL cs
			INNER JOIN #AgentBL acs ON acs.mrecommend = cs.custid
									AND acs.sporttype = cs.sporttype
									AND acs.bettype = cs.bettype
									AND acs.isLive = cs.isLive
		WHERE cs.MaxBet < acs.MaxBet	
	END
	
	--rule 4: master MaxPerEvent < agent MaxPerEvent  
	IF @ruleid IN (0,10204)
	BEGIN
		INSERT INTO dbo.CS_CheckBetLimitResult(ruleID,SportType,bettype,isLive,CustIDA,custidB,ValueA,ValueB)
		SELECT 10204, cs.SportType, cs.bettype, cs.isLive, cs.custID as CustIDA, acs.custid as custidB, cs.MaxPerEvent ValueA,acs.MaxPerEvent ValueB
		FROM #MasterBL cs
			INNER JOIN #AgentBL acs ON acs.mrecommend = cs.custid
									AND acs.sporttype = cs.sporttype
									AND acs.bettype = cs.bettype
									AND acs.isLive = cs.isLive
		WHERE cs.MaxPerEvent < mcs.MaxPerEvent
	END
	
	--rule 5: agent maxbet < member maxbet  
	IF @ruleid IN (0,10205)
	BEGIN
		INSERT INTO dbo.CS_CheckBetLimitResult(ruleID,SportType,bettype,isLive,CustIDA,custidB,ValueA,ValueB)
		SELECT 10205, cs.SportType, cs.bettype, cs.isLive, cs.custID as CustIDA, mem.custid as custidB, cs.MaxBet ValueA,mem.MaxBet ValueB
		FROM #AgentBL cs
			INNER JOIN #MemberBL mem ON mem.recommend = cs.custid
									AND mem.sporttype = cs.sporttype
									AND mem.bettype = cs.bettype
									AND mem.isLive = cs.isLive
		WHERE cs.MaxBet < mem.MaxBet	
	END
	
	--rule 6: agent MaxPerEvent < member MaxPerEvent  
	IF @ruleid IN (0,10206)
	BEGIN
		INSERT INTO dbo.CS_CheckBetLimitResult(ruleID,SportType,bettype,isLive,CustIDA,custidB,ValueA,ValueB)
		SELECT 10206, cs.SportType, cs.bettype, cs.isLive, cs.custID as CustIDA, mem.custid as custidB, cs.MaxPerEvent ValueA,mem.MaxPerEvent ValueB
		FROM #AgentBL cs
			INNER JOIN #MemberBL mem ON mem.recommend = cs.custid
									AND mem.sporttype = cs.sporttype
									AND mem.bettype = cs.bettype
									AND mem.isLive = cs.isLive
		WHERE cs.MaxPerEvent < mem.MaxPerEvent
	END	
END
GO	