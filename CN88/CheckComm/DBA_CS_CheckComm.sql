/*<info serverAlias="DBCHECK-CheckResultDB" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_CS_CheckComm]
	 @srecommend INT 
	,@SportType SMALLINT = 0
	,@RuleId	SMALLINT = 0
AS
/*
	Created: 20190722@Johnson
	Task: Weekly check Comm setting for CN88
	DB: DBCHECK.CheckResultDB
	
	Revisions:
		- 20190722@Johnson: Initial sp [redmine: #116922]
*/	
BEGIN 
	SET NOCOUNT ON
	
	CREATE TABLE #SuperComm (custid INT, sporttype INT, bettype INT, isLive BIT, GroupID INT, Discount DECIMAL(9,8), ValueID INT)
	CREATE TABLE #MasterComm (custid INT, srecommend INT, sporttype INT, bettype INT, isLive BIT, GroupID INT, Discount DECIMAL(9,8), ValueID INT)
	CREATE TABLE #AgentComm (custid INT, srecommend INT, mrecommend INT, sporttype INT, bettype INT, isLive BIT, GroupID INT, Discount DECIMAL(9,8), ValueID INT)
	CREATE TABLE #MemberComm (custid INT, srecommend INT, mrecommend INT, recommend INT, sporttype INT, bettype INT, isLive BIT, GroupID INT, PlayerDiscount DECIMAL(9,8), SuperDiscount DECIMAL(9,8), MasterDiscount DECIMAL(9,8), AgentDiscount DECIMAL(9,8))
	CREATE TABLE #MemberGroupComm (AgentID INT, srecommend INT, mrecommend INT, sporttype INT, bettype INT, isLive BIT, GroupID INT, PlayerDiscount DECIMAL(9,8), SuperDiscount DECIMAL(9,8), MasterDiscount DECIMAL(9,8), AgentDiscount DECIMAL(9,8))
		
	INSERT INTO #SuperComm(custid,sporttype,bettype,isLive,GroupID,Discount,ValueID)
	SELECT @srecommend,sporttype,bettype,isLive,GroupID,Discount,ValueID
	FROM CheckCustDB.dbo.f_CS_GetDiscount_Agent(@srecommend) cs
	WHERE sporttype = CASE WHEN @sporttype = 0 THEN sporttype ELSE @sporttype END
	
	INSERT INTO #MasterComm(custid,srecommend,sporttype,bettype,isLive,GroupID,Discount,ValueID)
	SELECT custid,srecommend,sporttype,bettype,isLive,GroupID,Discount,ValueID
	FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)
		CROSS APPLY CheckCustDB.dbo.f_CS_GetDiscount_Agent(custid) cs
	WHERE srecommend = @srecommend
		AND roleid = 3
		AND enabled = 1
		AND sporttype = CASE WHEN @sporttype = 0 THEN sporttype ELSE @sporttype END
		
	INSERT INTO #AgentComm(custid,srecommend,mrecommend,sporttype,bettype,isLive,GroupID,Discount,ValueID)
	SELECT custid,srecommend,recommend,sporttype,bettype,isLive,GroupID,Discount,ValueID
	FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)
		CROSS APPLY CheckCustDB.dbo.f_CS_GetDiscount_Agent(custid) cs
	WHERE srecommend = @srecommend
		AND roleid = 2
		AND enabled = 1
		AND sporttype = CASE WHEN @sporttype = 0 THEN sporttype ELSE @sporttype END
	
	INSERT INTO #MemberComm(custid,srecommend,mrecommend,recommend,sporttype,bettype,isLive,GroupID,PlayerDiscount,SuperDiscount,MasterDiscount,AgentDiscount)
	SELECT ci.custid,ci.srecommend,ci.mrecommend,ci.recommend,cs.sporttype,cs.bettype,cs.isLive,ISNULL(gc.GroupID,0),PlayerDiscount,SuperDiscount,MasterDiscount,AgentDiscount
	FROM CheckCustDB.dbo.custInfo ci WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.customer c WITH(NOLOCK) ON ci.custid = c.custid
		CROSS APPLY CheckCustDB.dbo.f_CS_GetDiscount_Member(ci.custid) cs
		LEFT JOIN CheckCustDB.dbo.CS_GroupConfig gc ON gc.SportType = cs.SportType AND gc.BetType = cs.BetType AND gc.IsLive = cs.IsLive AND gc.uGroup = c.ugroup
	WHERE ci.srecommend = @srecommend
		AND ci.roleid = 1
		AND ci.enabled = 1
		AND cs.sporttype = CASE WHEN @sporttype = 0 THEN cs.sporttype ELSE @sporttype END
		
	INSERT INTO #MemberGroupComm(AgentID,srecommend,mrecommend,sporttype,bettype,isLive,GroupID,PlayerDiscount,SuperDiscount,MasterDiscount,AgentDiscount)
	SELECT custid,srecommend,mrecommend,cs.sporttype,cs.bettype,cs.isLive,ISNULL(gc.GroupID,0),PlayerDiscount,SuperDiscount,MasterDiscount,AgentDiscount
	FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)
		CROSS APPLY CheckCustDB.dbo.f_CS_GetGroupDiscount_Member(custid) cs
		LEFT JOIN CheckCustDB.dbo.CS_GroupConfig gc ON gc.SportType = cs.SportType AND gc.BetType = cs.BetType AND gc.IsLive = cs.IsLive AND gc.uGroup = cs.uGroup
	WHERE srecommend = @srecommend
		AND roleid = 2
		AND enabled = 1	
		AND cs.sporttype = CASE WHEN @sporttype = 0 THEN cs.sporttype ELSE @sporttype END
		
	--super discount > default Max Discount
	IF @ruleid IN (0,10101)
	BEGIN
		INSERT INTO CS_CheckCommResult(ruleid,sporttype,bettype,isLive,groupID,custidA,custidB,ValueA,ValueB)
		SELECT 10101 ruleid, cs.sporttype, cs.bettype, cs.isLive, cs.groupID, cs.custid as custidA, cs.custid as custidB, cs.Discount as ValueA, CASE WHEN gc.GroupId IS NULL THEN ps.MaxDiscount ELSE gc.MaxValue END as ValueB
		FROM #SuperComm cs
			INNER JOIN CheckCustDB.dbo.CS_ProductSettingDetail ps  WITH (NOLOCK) ON ps.SportType = cs.SportType AND ps.BetType = cs.BetType AND ps.IsLive = cs.IsLive AND ps.SettingType = 2		
			LEFT JOIN CheckCustDB.dbo.CS_GroupConfig gc WITH (NOLOCK) ON gc.SportType = ps.SportType AND gc.BetType = ps.BetType AND gc.IsLive = ps.IsLive AND gc.GroupId = cs.GroupId
		WHERE cs.Discount > CASE WHEN gc.GroupId IS NULL THEN ps.MaxDiscount ELSE gc.MaxValue END
	END
	
	--super's discount < downlines master's discount
	IF @ruleid IN (0,10102)
	BEGIN
		INSERT INTO CS_CheckCommResult(ruleid,sporttype,bettype,isLive, groupID,custidA,custidB,ValueA,ValueB)
		SELECT 10102 ruleid, cs.sporttype, cs.bettype, cs.isLive, cs.groupID, cs.custid as custidA, mcs.custid as custidB, cs.Discount as ValueA, mcs.Discount as ValueB
		FROM #SuperComm cs
			INNER JOIN #MasterComm mcs ON mcs.SportType = cs.SportType 
										AND mcs.BetType = cs.BetType 
										AND mcs.IsLive = cs.IsLive	
										AND mcs.GroupID = cs.GroupID 
										AND mcs.srecommend = cs.custid		
		WHERE cs.Discount < mcs.Discount
	END
	
	--master's discount < downlines agent's discount
	IF @ruleid IN (0,10103)
	BEGIN
		INSERT INTO CS_CheckCommResult(ruleid,sporttype,bettype,isLive, groupID,custidA,custidB,ValueA,ValueB)
		SELECT 10103 ruleid, cs.sporttype, cs.bettype, cs.isLive, cs.groupID, cs.custid as custidA, acs.custid as custidB, cs.Discount as ValueA, acs.Discount as ValueB
		FROM #MasterComm cs
			INNER JOIN #AgentComm acs ON acs.SportType = cs.SportType 
										AND acs.BetType = cs.BetType 
										AND acs.IsLive = cs.IsLive	
										AND acs.GroupID = cs.GroupID 
										AND acs.mrecommend = cs.custid
		WHERE cs.Discount < acs.Discount
	END
	
	--Agent discount < individual downline's discount  
	IF @ruleid IN (0,10104)
	BEGIN
		INSERT INTO CS_CheckCommResult(ruleid,sporttype,bettype,isLive, groupID,custidA,custidB,ValueA,ValueB)
		SELECT 10104 ruleid, cs.sporttype, cs.bettype, cs.isLive, cs.groupID, cs.custid as custidA, acs.custid as custidB, cs.PlayerDiscount as ValueA, acs.Discount as ValueB
		FROM #AgentComm acs
			LEFT JOIN #MemberComm cs ON acs.SportType = cs.SportType 
										AND acs.BetType = cs.BetType 
										AND acs.IsLive = cs.IsLive	
										AND acs.GroupID = cs.GroupID 
										AND acs.custid = cs.recommend
		WHERE acs.Discount < cs.PlayerDiscount
	END
	
	--Agent discount < downlines group discount 
	IF @ruleid IN (0,10105)
	BEGIN
		INSERT INTO CS_CheckCommResult(ruleid,sporttype,bettype,isLive, groupID,custidA,custidB,ValueA,ValueB)
		SELECT 10105 ruleid, cs.sporttype, cs.bettype, cs.isLive, cs.groupID, cs.AgentID as custidA, acs.custid as custidB, cs.PlayerDiscount as ValueA, acs.Discount as ValueB
		FROM #AgentComm acs
			LEFT JOIN #MemberGroupComm cs ON acs.SportType = cs.SportType 
										AND acs.BetType = cs.BetType 
										AND acs.IsLive = cs.IsLive	
										AND acs.GroupID = cs.GroupID 
										AND acs.custid = cs.AgentID
		WHERE acs.Discount < cs.PlayerDiscount
	END
	
	--SuperDiscount < MasterDiscount on member level
	IF @ruleid IN (0,10106)
	BEGIN
		INSERT INTO CS_CheckCommResult(ruleid,sporttype,bettype,isLive, groupID,custidA,custidB,ValueA,ValueB)
		SELECT 10106 ruleid, cs.sporttype, cs.bettype, cs.isLive, cs.groupID, cs.custid as custidA, 0 as custidB, cs.SuperDiscount as ValueA, cs.MasterDiscount as ValueB
		FROM #MemberComm cs
		WHERE SuperDiscount < MasterDiscount
	END
	
	--SuperDiscount < MasterDiscount on member level on group setting
	IF @ruleid IN (0,10107)
	BEGIN
		INSERT INTO CS_CheckCommResult(ruleid,sporttype,bettype,isLive, groupID,custidA,custidB,ValueA,ValueB)
		SELECT 10107 ruleid, cs.sporttype, cs.bettype, cs.isLive, cs.groupID, cs.custid as custidA, 0 as custidB, cs.SuperDiscount as ValueA, cs.MasterDiscount as ValueB
		FROM #MemberGroupComm cs
		WHERE SuperDiscount < MasterDiscount
	END
	
	--MasterDiscount < AgentDiscount on member level
	IF @ruleid IN (0,10108)
	BEGIN
		INSERT INTO CS_CheckCommResult(ruleid,sporttype,bettype,isLive, groupID,custidA,custidB,ValueA,ValueB)
		SELECT 10108 ruleid, cs.sporttype, cs.bettype, cs.isLive, cs.groupID, cs.custid as custidA, 0 as custidB, cs.MasterDiscount as ValueA, cs.AgentDiscount as ValueB
		FROM #MemberComm cs
		WHERE MasterDiscount < AgentDiscount
	END
	
	--MasterDiscount < AgentDiscount on member level on group setting
	IF @ruleid IN (0,10109)
	BEGIN
		INSERT INTO CS_CheckCommResult(ruleid,sporttype,bettype,isLive, groupID,custidA,custidB,ValueA,ValueB)
		SELECT 10109 ruleid, cs.sporttype, cs.bettype, cs.isLive, cs.groupID, cs.AgentID as custidA, 0 as custidB, cs.MasterDiscount as ValueA, cs.AgentDiscount as ValueB
		FROM #MemberGroupComm cs
		WHERE MasterDiscount < AgentDiscount
	END
	
	--AgentDiscount < PlayerDiscount on member level
	IF @ruleid IN (0,10110)
	BEGIN
		INSERT INTO CS_CheckCommResult(ruleid,sporttype,bettype,isLive, groupID,custidA,custidB,ValueA,ValueB)
		SELECT 10110 ruleid, cs.sporttype, cs.bettype, cs.isLive, cs.groupID, cs.custid as custidA, 0 as custidB, cs.MasterDiscount as ValueA, cs.AgentDiscount as ValueB
		FROM #MemberComm cs
		WHERE AgentDiscount < PlayerDiscount
	END
	
	--AgentDiscount < PlayerDiscount on member level on group setting
	IF @ruleid IN (0,10111)
	BEGIN
		INSERT INTO CS_CheckCommResult(ruleid,sporttype,bettype,isLive, groupID,custidA,custidB,ValueA,ValueB)
		SELECT 10111 ruleid, cs.sporttype, cs.bettype, cs.isLive, cs.groupID, cs.AgentID as custidA, 0 as custidB, cs.MasterDiscount as ValueA, cs.AgentDiscount as ValueB
		FROM #MemberGroupComm cs
		WHERE AgentDiscount < PlayerDiscount
	END
	
	--Super's Discount <> Super's Discount on member level	
	IF @ruleid IN (0,10112)
	BEGIN
		INSERT INTO CS_CheckCommResult(ruleid,sporttype,bettype,isLive, groupID,custidA,custidB,ValueA,ValueB)
		SELECT 10112 ruleid, cs.sporttype, cs.bettype, cs.isLive, cs.groupID, scs.custid as custidA, cs.custid as custidB, scs.Discount as ValueA, cs.SuperDiscount as ValueB
		FROM #SuperComm scs
			LEFT JOIN #MemberComm cs ON scs.SportType = cs.SportType 
										AND scs.BetType = cs.BetType 
										AND scs.IsLive = cs.IsLive	
										AND scs.GroupID = cs.GroupID 
										AND scs.custid = cs.srecommend
		WHERE scs.Discount <> cs.SuperDiscount
	END
	
	--Super's Discount <> Super's Discount on member level on group setting
	IF @ruleid IN (0,10113)
	BEGIN
		INSERT INTO CS_CheckCommResult(ruleid,sporttype,bettype,isLive, groupID,custidA,custidB,ValueA,ValueB)
		SELECT 10113 ruleid, cs.sporttype, cs.bettype, cs.isLive, cs.groupID, scs.custid as custidA, cs.AgentID as custidB, scs.Discount as ValueA, cs.SuperDiscount as ValueB
		FROM #SuperComm scs
			LEFT JOIN #MemberGroupComm cs ON scs.SportType = cs.SportType 
										AND scs.BetType = cs.BetType 
										AND scs.IsLive = cs.IsLive	
										AND scs.GroupID = cs.GroupID 
										AND scs.custid = cs.srecommend
		WHERE scs.Discount <> cs.SuperDiscount
	END
	
	--Master's Discount <> Master's Discount on member level	
	IF @ruleid IN (0,10114)
	BEGIN
		INSERT INTO CS_CheckCommResult(ruleid,sporttype,bettype,isLive, groupID,custidA,custidB,ValueA,ValueB)
		SELECT 10114 ruleid, cs.sporttype, cs.bettype, cs.isLive, cs.groupID, mcs.custid as custidA, cs.custid as custidB, mcs.Discount as ValueA, cs.MasterDiscount as ValueB
		FROM #MasterComm mcs
			LEFT JOIN #MemberComm cs ON mcs.SportType = cs.SportType 
										AND mcs.BetType = cs.BetType 
										AND mcs.IsLive = cs.IsLive	
										AND mcs.GroupID = cs.GroupID 
										AND mcs.custid = cs.mrecommend
		WHERE mcs.Discount <> cs.MasterDiscount
	END
	
	--Master's Discount <> Master's Discount on member level on group setting
	IF @ruleid IN (0,10115)
	BEGIN
		INSERT INTO CS_CheckCommResult(ruleid,sporttype,bettype,isLive, groupID,custidA,custidB,ValueA,ValueB)
		SELECT 10115 ruleid, cs.sporttype, cs.bettype, cs.isLive, cs.groupID, mcs.custid as custidA, cs.custid as custidB, mcs.Discount as ValueA, cs.MasterDiscount as ValueB
		FROM #MasterComm mcs
			LEFT JOIN #MemberGroupComm cs ON mcs.SportType = cs.SportType 
										AND mcs.BetType = cs.BetType 
										AND mcs.IsLive = cs.IsLive	
										AND mcs.GroupID = cs.GroupID 
										AND mcs.custid = cs.mrecommend
		WHERE mcs.Discount <> cs.MasterDiscount
	END
	
	--Agent's Discount <> Agent's Discount on member level
	IF @ruleid IN (0,10116)
	BEGIN
		INSERT INTO CS_CheckCommResult(ruleid,sporttype,bettype,isLive, groupID,custidA,custidB,ValueA,ValueB)
		SELECT 10116 ruleid, cs.sporttype, cs.bettype, cs.isLive, cs.groupID, acs.custid as custidA, cs.custid as custidB, acs.Discount as ValueA, cs.AgentDiscount as ValueB
		FROM #AgentComm acs
			LEFT JOIN #MemberComm cs ON acs.SportType = cs.SportType 
										AND acs.BetType = cs.BetType 
										AND acs.IsLive = cs.IsLive	
										AND acs.GroupID = cs.GroupID 
										AND acs.custid = cs.recommend
		WHERE acs.Discount <> cs.AgentDiscount
	END
	
	--Agent's Discount <> Agent's Discount on member level on group setting
	IF @ruleid IN (0,10117)
	BEGIN
		INSERT INTO CS_CheckCommResult(ruleid,sporttype,bettype,isLive, groupID,custidA,custidB,ValueA,ValueB)
		SELECT 10117 ruleid, cs.sporttype, cs.bettype, cs.isLive, cs.groupID, acs.custid as custidA, cs.AgentID as custidB, acs.Discount as ValueA, cs.AgentDiscount as ValueB
		FROM #AgentComm acs
			LEFT JOIN #MemberGroupComm cs ON acs.SportType = cs.SportType 
										AND acs.BetType = cs.BetType 
										AND acs.IsLive = cs.IsLive	
										AND acs.GroupID = cs.GroupID 
										AND acs.custid = cs.AgentID
		WHERE acs.Discount <> cs.AgentDiscount
	END
	
END	
GO