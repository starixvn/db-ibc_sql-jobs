/*<info serverAlias="DBCHECK-CheckResultDB" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_CS_CheckBetLimit]
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
	
	DECLARE @currency INT 
	
	SELECT @currency = currency
	FROM CheckCustDB.dbo.custinfo WITH(NOLOCK)
	WHERE custid = @srecommend
	
	INSERT INTO #SuperBL(custid,sporttype,bettype,isLive,MaxBet,MaxPerEvent)
	SELECT custid,sporttype,bettype,isLive,MaxBet,MaxPerEvent
	FROM CheckCustDB.dbo.CS_CustBetSetting_Agent cs WITH(NOLOCK)
	WHERE custid = @srecommend
		AND sporttype = CASE WHEN @sporttype = 0 THEN cs.sporttype ELSE @sporttype END
		
	INSERT INTO #MasterBL(custid,srecommend,sporttype,bettype,isLive,MaxBet,MaxPerEvent)
	SELECT ci.custid,srecommend,sporttype,bettype,isLive,MaxBet,MaxPerEvent
	FROM  CheckCustDB.dbo.custinfo ci WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.CS_CustBetSetting_Agent cs WITH(NOLOCK) ON ci.custid = cs.custid
	WHERE ci.srecommend = @srecommend
		AND sporttype = CASE WHEN @sporttype = 0 THEN cs.sporttype ELSE @sporttype END
		AND roleid = 3
		AND enabled = 1
	
	INSERT INTO #AgentBL(custid,srecommend,mrecommend,sporttype,bettype,isLive,MaxBet,MaxPerEvent)
	SELECT ci.custid,srecommend,mrecommend,sporttype,bettype,isLive,MaxBet,MaxPerEvent
	FROM  CheckCustDB.dbo.custinfo ci WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.CS_CustBetSetting_Agent cs WITH(NOLOCK) ON ci.custid = cs.custid
	WHERE ci.srecommend = @srecommend
		AND sporttype = CASE WHEN @sporttype = 0 THEN cs.sporttype ELSE @sporttype END
		AND roleid = 2
		AND enabled = 1
	
	INSERT INTO #MemberBL(custid,srecommend,mrecommend,recommend,sporttype,bettype,isLive,MaxBet,MaxPerEvent)
	SELECT ci.custid,srecommend,mrecommend,recommend,sporttype,bettype,isLive,MaxBet,MaxPerEvent
	FROM  CheckCustDB.dbo.custinfo ci WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.CS_CustBetSetting_Member cs WITH(NOLOCK) ON ci.custid = cs.custid
	WHERE srecommend = @srecommend
		AND sporttype = CASE WHEN @sporttype = 0 THEN cs.sporttype ELSE @sporttype END
		AND roleid = 1
		AND enabled = 1
	
	--rule 1: super maxbet > global maxbet
	IF @ruleid IN (0,10201)
	BEGIN
		INSERT INTO dbo.CS_CheckBetLimitResult(ruleID,SportType,bettype,isLive,CustIDA,custidB,ValueA,ValueB)
		SELECT 10201, cs.SportType, cs.bettype, cs.isLive, cs.custID as CustIDA, 0 as custidB, cs.MaxBet ValueA,gb.MaxBet ValueB
		FROM #SuperBL cs
			INNER JOIN CheckCustDB.dbo.CS_ProductBetSetting gb ON gb.SportType = cs.SportType AND gb.BetType = cs.Bettype AND gb.IsLive = cs.IsLive AND gb.Currency = @Currency
		WHERE cs.Maxbet > gb.MaxBet		
	END
	
	--rule 2: super MaxPerEvent > global MaxPerEvent
	IF @ruleid IN (0,10202)
	BEGIN
		INSERT INTO dbo.CS_CheckBetLimitResult(ruleID,SportType,bettype,isLive,CustIDA,custidB,ValueA,ValueB)
		SELECT 10202, cs.SportType, cs.bettype, cs.isLive, cs.custID as CustIDA, 0 as custidB, cs.MaxPerEvent ValueA,gb.MaxPerEvent ValueB
		FROM #SuperBL cs
			INNER JOIN CheckCustDB.dbo.CS_ProductBetSetting gb ON gb.SportType = cs.SportType AND gb.BetType = cs.Bettype AND gb.IsLive = cs.IsLive AND gb.Currency = @Currency
		WHERE cs.MaxPerEvent > gb.MaxPerEvent		
	END
	
	--rule 3: super maxbet > super MaxPerEvent
	IF @ruleid IN (0,10203)
	BEGIN
		INSERT INTO dbo.CS_CheckBetLimitResult(ruleID,SportType,bettype,isLive,CustIDA,custidB,ValueA,ValueB)
		SELECT 10203, cs.SportType, cs.bettype, cs.isLive, cs.custID as CustIDA, cs.custid as custidB, cs.MaxBet ValueA,cs.MaxPerEvent ValueB
		FROM #SuperBL cs
		WHERE Maxbet > MaxPerEvent
	END
	
	--rule 4: super maxbet < master maxbet 
	IF @ruleid IN (0,10204)
	BEGIN	
		INSERT INTO dbo.CS_CheckBetLimitResult(ruleID,SportType,bettype,isLive,CustIDA,custidB,ValueA,ValueB)
		SELECT 10204, cs.SportType, cs.bettype, cs.isLive, cs.custID as CustIDA, mcs.custid as custidB, cs.MaxBet ValueA,mcs.MaxBet ValueB
		FROM #SuperBL cs
			INNER JOIN #MasterBL mcs ON mcs.srecommend = cs.custid
									AND mcs.sporttype = cs.sporttype
									AND mcs.bettype = cs.bettype
									AND mcs.isLive = cs.isLive
		WHERE cs.MaxBet < mcs.MaxBet	
	END
	
	--rule 5: super MaxPerEvent < master MaxPerEvent  
	IF @ruleid IN (0,10205)
	BEGIN
		INSERT INTO dbo.CS_CheckBetLimitResult(ruleID,SportType,bettype,isLive,CustIDA,custidB,ValueA,ValueB)
		SELECT 10205, cs.SportType, cs.bettype, cs.isLive, cs.custID as CustIDA, mcs.custid as custidB, cs.MaxPerEvent ValueA,mcs.MaxPerEvent ValueB
		FROM #SuperBL cs
			INNER JOIN #MasterBL mcs ON mcs.srecommend = cs.custid
									AND mcs.sporttype = cs.sporttype
									AND mcs.bettype = cs.bettype
									AND mcs.isLive = cs.isLive
		WHERE cs.MaxPerEvent < mcs.MaxPerEvent
	END
	
	--rule 6: master maxbet > master MaxPerEvent
	IF @ruleid IN (0,10206)
	BEGIN
		INSERT INTO dbo.CS_CheckBetLimitResult(ruleID,SportType,bettype,isLive,CustIDA,custidB,ValueA,ValueB)
		SELECT 10206, cs.SportType, cs.bettype, cs.isLive, cs.custID as CustIDA, cs.custid as custidB, cs.MaxBet ValueA,cs.MaxPerEvent ValueB
		FROM #MasterBL cs
		WHERE Maxbet > MaxPerEvent
	END
	
	--rule 7: master maxbet < agent maxbet  
	IF @ruleid IN (0,10207)
	BEGIN
		INSERT INTO dbo.CS_CheckBetLimitResult(ruleID,SportType,bettype,isLive,CustIDA,custidB,ValueA,ValueB)
		SELECT 10207, cs.SportType, cs.bettype, cs.isLive, cs.custID as CustIDA, acs.custid as custidB, cs.MaxBet ValueA,acs.MaxBet ValueB
		FROM #MasterBL cs
			INNER JOIN #AgentBL acs ON acs.mrecommend = cs.custid
									AND acs.sporttype = cs.sporttype
									AND acs.bettype = cs.bettype
									AND acs.isLive = cs.isLive
		WHERE cs.MaxBet < acs.MaxBet	
	END
	
	--rule 8: master MaxPerEvent < agent MaxPerEvent  
	IF @ruleid IN (0,10208)
	BEGIN
		INSERT INTO dbo.CS_CheckBetLimitResult(ruleID,SportType,bettype,isLive,CustIDA,custidB,ValueA,ValueB)
		SELECT 10208, cs.SportType, cs.bettype, cs.isLive, cs.custID as CustIDA, acs.custid as custidB, cs.MaxPerEvent ValueA,acs.MaxPerEvent ValueB
		FROM #MasterBL cs
			INNER JOIN #AgentBL acs ON acs.mrecommend = cs.custid
									AND acs.sporttype = cs.sporttype
									AND acs.bettype = cs.bettype
									AND acs.isLive = cs.isLive
		WHERE cs.MaxPerEvent < acs.MaxPerEvent
	END
	
	--rule 9: agent maxbet > agent MaxPerEvent
	IF @ruleid IN (0,10209)
	BEGIN
		INSERT INTO dbo.CS_CheckBetLimitResult(ruleID,SportType,bettype,isLive,CustIDA,custidB,ValueA,ValueB)
		SELECT 10209, cs.SportType, cs.bettype, cs.isLive, cs.custID as CustIDA, cs.custid as custidB, cs.MaxBet ValueA,cs.MaxPerEvent ValueB
		FROM #AgentBL cs
		WHERE Maxbet > MaxPerEvent
	END
	
	--rule 10: agent maxbet < member maxbet  
	IF @ruleid IN (0,10210)
	BEGIN
		INSERT INTO dbo.CS_CheckBetLimitResult(ruleID,SportType,bettype,isLive,CustIDA,custidB,ValueA,ValueB)
		SELECT 10210, cs.SportType, cs.bettype, cs.isLive, cs.custID as CustIDA, mem.custid as custidB, cs.MaxBet ValueA,mem.MaxBet ValueB
		FROM #AgentBL cs
			INNER JOIN #MemberBL mem ON mem.recommend = cs.custid
									AND mem.sporttype = cs.sporttype
									AND mem.bettype = cs.bettype
									AND mem.isLive = cs.isLive
		WHERE cs.MaxBet < mem.MaxBet	
	END
	
	--rule 11: agent MaxPerEvent < member MaxPerEvent  
	IF @ruleid IN (0,10211)
	BEGIN
		INSERT INTO dbo.CS_CheckBetLimitResult(ruleID,SportType,bettype,isLive,CustIDA,custidB,ValueA,ValueB)
		SELECT 10211, cs.SportType, cs.bettype, cs.isLive, cs.custID as CustIDA, mem.custid as custidB, cs.MaxPerEvent ValueA,mem.MaxPerEvent ValueB
		FROM #AgentBL cs
			INNER JOIN #MemberBL mem ON mem.recommend = cs.custid
									AND mem.sporttype = cs.sporttype
									AND mem.bettype = cs.bettype
									AND mem.isLive = cs.isLive
		WHERE cs.MaxPerEvent < mem.MaxPerEvent
	END	
	
	--rule 11: member MaxPerEvent < member MaxBet
	IF @ruleid IN (0,10212)
	BEGIN
		INSERT INTO dbo.CS_CheckBetLimitResult(ruleID,SportType,bettype,isLive,CustIDA,custidB,ValueA,ValueB)
		SELECT 10212, cs.SportType, cs.bettype, cs.isLive, cs.custID as CustIDA, 0 as custidB, cs.MaxBet ValueA,cs.MaxPerEvent ValueB
		FROM #MemberBL cs
		WHERE MaxPerEvent < MaxBet
	END	
END
GO	