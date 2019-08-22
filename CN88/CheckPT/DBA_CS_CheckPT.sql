/*<info serverAlias="DBCHECK-CheckResultDB" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_CS_CheckPT]
	 @srecommend INT 
	,@SportType SMALLINT = 0
	,@RuleId	SMALLINT = 0
AS
/*
	Created: 20190718@Johnson
	Task: Weekly check PT setting for CN88
	DB: DBCHECK.CheckResultDB
	
	Revisions:
		- 20190718@Johnson: Initial sp [redmine: #116922]
*/	
BEGIN 
	SET NOCOUNT ON
	
	CREATE TABLE #MemberPT (AgentID INT, mrecommend INT, srecommend INT, sporttype SMALLINT, bettype SMALLINT, IsLive BIT, SuperPT TINYINT, MasterPT TINYINT, AgentPT TINYINT, SuperPT2 TINYINT, MasterPT2 TINYINT, AgentPT2 TINYINT)
	CREATE TABLE #AgentPT (CustID INT, mrecommend INT, srecommend INT, sporttype SMALLINT, bettype SMALLINT, IsLive BIT, SuperPT TINYINT, MasterPT TINYINT, AgentPT TINYINT, MinPT TINYINT, MaxPT TINYINT, SuperPT2 TINYINT, MasterPT2 TINYINT, AgentPT2 TINYINT, MinPT2 TINYINT, MaxPT2 TINYINT)
	CREATE TABLE #MasterPT (CustID INT, mrecommend INT, srecommend INT, sporttype SMALLINT, bettype SMALLINT, IsLive BIT, SuperPT TINYINT, MasterPT TINYINT, AgentPT TINYINT, MinPT TINYINT, MaxPT TINYINT, SuperPT2 TINYINT, MasterPT2 TINYINT, AgentPT2 TINYINT, MinPT2 TINYINT, MaxPT2 TINYINT)
	CREATE TABLE #SuperPT (CustID INT, sporttype SMALLINT, bettype SMALLINT, IsLive BIT, SuperPT TINYINT, MasterPT TINYINT, AgentPT TINYINT, MinPT TINYINT, MaxPT TINYINT, SuperPT2 TINYINT, MasterPT2 TINYINT, AgentPT2 TINYINT, MinPT2 TINYINT, MaxPT2 TINYINT)
	
	INSERT INTO #SuperPT(custid,sporttype,bettype,isLive,MinPT,MaxPT,MinPT2,MaxPT2)
	SELECT @srecommend,sporttype,bettype,isLive,MinPT,MaxPT,MinPT2,MaxPT2
	FROM CheckCustDB.dbo.f_CS_GetPT_Agent(@srecommend)
	WHERE sporttype = CASE WHEN @sporttype = 0 THEN sporttype ELSE @sporttype END
	
	INSERT INTO #MasterPT(custid,srecommend,sporttype,bettype,isLive,SuperPT,SuperPT2)
	SELECT custid,srecommend,sporttype,bettype,isLive,SuperPT,SuperPT2
	FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)
		CROSS APPLY CheckCustDB.dbo.f_CS_GetPT_Agent(custid) cs
	WHERE ci.srecommend = @srecommend
		AND roleid = 3
		AND ci.Enabled = 1
		AND sporttype = CASE WHEN @sporttype = 0 THEN sporttype ELSE @sporttype END
	
	INSERT INTO #AgentPT(custid,srecommend,mrecommend,sporttype,bettype,isLive,MasterPT,AgentPT,MasterPT2,AgentPT2)
	SELECT custid,srecommend,mrecommend,sporttype,bettype,isLive,MasterPT,AgentPT,MasterPT2,AgentPT2
	FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)
		CROSS APPLY CheckCustDB.dbo.f_CS_GetPT_Agent(custid) cs
	WHERE ci.srecommend = @srecommend
		AND roleid = 2
		AND ci.Enabled = 1
		AND sporttype = CASE WHEN @sporttype = 0 THEN sporttype ELSE @sporttype END
		
	INSERT INTO #MemberPT(AgentID,srecommend,mrecommend,sporttype,bettype,isLive,SuperPT,MasterPT,AgentPT,SuperPT2,MasterPT2,AgentPT2)
	SELECT custid,srecommend,mrecommend,sporttype,bettype,isLive,SuperPT,MasterPT,AgentPT,SuperPT2,MasterPT2,AgentPT2
	FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)
		CROSS APPLY CheckCustDB.dbo.f_CS_GetPTGroup_Member(custid) cs
	WHERE ci.srecommend = @srecommend
		AND roleid = 2
		AND ci.Enabled = 1	
		AND sporttype = CASE WHEN @sporttype = 0 THEN sporttype ELSE @sporttype END
		
	--rule 10001: n4 > MaxPT
	IF @ruleID IN (0,10001)
	BEGIN	
		INSERT INTO CS_CheckPTResult (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive) 
		SELECT 10001, cs.BetType, cs.SportType, cs.custid, cs.custid, 
				CASE WHEN cs.MinPT > ps.MaxPT THEN cs.MinPT ELSE cs.MinPT2 END, 
				ps.MaxPT, cs.isLive
		FROM #SuperPT cs
			INNER JOIN CheckCustDB.dbo.CS_ProductSettingDetail ps WITH(NOLOCK) ON cs.SportType = ps.Sporttype AND cs.BetType = ps.bettype AND cs.IsLive = ps.IsLive AND ps.SettingType = 1
		WHERE cs.MinPT > ps.MaxPT 
			OR cs.MinPT2 > ps.MaxPT			
	END
	
	-- l4 > MaxPT
	IF @ruleID IN (0,10002)
	BEGIN	
		INSERT INTO CS_CheckPTResult (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive) 
		SELECT 10002, cs.BetType, cs.SportType, cs.custid, cs.custid, 
			CASE WHEN cs.MaxPT > ps.MaxPT THEN cs.MaxPT	ELSE cs.MaxPT2 END, 
			ps.MaxPT, cs.isLive
		FROM #SuperPT cs
			INNER JOIN CheckCustDB.dbo.CS_ProductSettingDetail ps WITH(NOLOCK) ON cs.SportType = ps.Sporttype AND cs.BetType = ps.bettype AND cs.IsLive = ps.IsLive AND ps.SettingType = 1
		WHERE cs.MaxPT > ps.MaxPT 
			OR cs.MaxPT2 > ps.MaxPT
	END
	
	--s3 > l4
	IF @ruleID IN (0,10003)
	BEGIN	
		INSERT INTO CS_CheckPTResult (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive) 
		SELECT 10003, cs.BetType, cs.SportType, cs.custid, scs.custid, cs.SuperPT, scs.MaxPT, cs.isLive
		FROM #SuperPT scs
			INNER JOIN #MasterPT cs ON cs.srecommend = scs.custid 
									 AND cs.SportType = scs.Sporttype 
									 AND cs.BetType = scs.bettype 
									 AND cs.IsLive = scs.IsLive
		WHERE cs.SuperPT > scs.MaxPT
	END
	
	--n4 > s1+m1+a1
	IF @ruleID IN (0,10004)
	BEGIN	
		INSERT INTO CS_CheckPTResult (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive) 
		SELECT 10004, cs.BetType, cs.SportType, cs.AgentID, scs.custid, 
			CASE WHEN cs.SuperPT + cs.MasterPT + cs.AgentPT < scs.MinPT THEN cs.SuperPT + cs.MasterPT + cs.AgentPT ELSE 
				cs.SuperPT2 + cs.MasterPT2 + cs.AgentPT2 END,
			CASE WHEN cs.SuperPT + cs.MasterPT + cs.AgentPT < scs.MinPT THEN scs.MinPT ELSE scs.MinPT2 END,
			cs.isLive
		FROM #SuperPT scs
			INNER JOIN #MemberPT cs ON cs.srecommend = scs.custid 
									 AND cs.SportType = scs.Sporttype 
									 AND cs.BetType = scs.bettype 
									 AND cs.IsLive = scs.IsLive
		WHERE cs.SuperPT + cs.MasterPT + cs.AgentPT < scs.MinPT
			OR cs.SuperPT2 + cs.MasterPT2 + cs.AgentPT2 < scs.MinPT2
	END
	
	--l4 < s1+m1+a1
	IF @ruleID IN (0,10005)
	BEGIN
		INSERT INTO CS_CheckPTResult (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive) 
		SELECT 10005, cs.BetType, cs.SportType, cs.AgentID, scs.custid, 
			CASE WHEN cs.SuperPT + cs.MasterPT + cs.AgentPT > scs.MaxPT THEN cs.SuperPT + cs.MasterPT + cs.AgentPT ELSE 
				cs.SuperPT2 + cs.MasterPT2 + cs.AgentPT2 END,
			CASE WHEN cs.SuperPT + cs.MasterPT + cs.AgentPT > scs.MaxPT THEN scs.MaxPT ELSE scs.MaxPT2 END,
			cs.isLive
		FROM #SuperPT scs
			INNER JOIN #MemberPT cs ON cs.srecommend = scs.custid 
									 AND cs.SportType = scs.Sporttype 
									 AND cs.BetType = scs.bettype 
									 AND cs.IsLive = scs.IsLive
		WHERE cs.SuperPT + cs.MasterPT + cs.AgentPT > scs.MaxPT
			OR cs.SuperPT2 + cs.MasterPT2 + cs.AgentPT2 > scs.MaxPT2
	END
			
	--s3 < n4 - (m2+a2)
	IF @ruleID IN (0,10006)
	BEGIN	
		INSERT INTO CS_CheckPTResult (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive) 
		SELECT 10006, cs.BetType, cs.SportType, mcs.custid, cs.AgentID, 
			CASE WHEN mcs.SuperPT < scs.MinPT - (cs.MasterPT + cs.AgentPT) THEN mcs.SuperPT ELSE 
				mcs.SuperPT2 END,
			CASE WHEN mcs.SuperPT < scs.MinPT - (cs.MasterPT + cs.AgentPT) THEN scs.MinPT - (cs.MasterPT + cs.AgentPT)
				ELSE scs.MinPT2 - (cs.MasterPT2 + cs.AgentPT2) END,
			cs.isLive
		FROM #SuperPT scs
			INNER JOIN #MasterPT mcs ON mcs.srecommend = scs.custid 
									 AND mcs.SportType = scs.Sporttype 
									 AND mcs.BetType = scs.bettype 
									 AND mcs.IsLive = scs.IsLive
			INNER JOIN #AgentPT cs ON cs.srecommend = scs.custid 
									 AND cs.SportType = scs.Sporttype 
									 AND cs.BetType = scs.bettype 
									 AND cs.IsLive = scs.IsLive
		WHERE mcs.SuperPT < scs.MinPT - (cs.MasterPT + cs.AgentPT)
			OR mcs.SuperPT2 < scs.MinPT2 - (cs.MasterPT2 + cs.AgentPT2)
	END
	
	--s3 > l4 - (m2+a2)
	IF @ruleID IN (0,10007)
	BEGIN
		INSERT INTO CS_CheckPTResult (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive) 
		SELECT 10007, cs.BetType, cs.SportType, mcs.custid, cs.AgentID, 
			CASE WHEN mcs.SuperPT > scs.MaxPT - (cs.MasterPT + cs.AgentPT) THEN mcs.SuperPT ELSE 
				mcs.SuperPT2 END,
			CASE WHEN mcs.SuperPT > scs.MaxPT - (cs.MasterPT + cs.AgentPT) THEN scs.MaxPT - (cs.MasterPT + cs.AgentPT)
				ELSE scs.MaxPT2 - (cs.MasterPT2 + cs.AgentPT2) END,
			cs.isLive
		FROM #SuperPT scs
			INNER JOIN #MasterPT mcs ON mcs.srecommend = scs.custid 
									 AND mcs.SportType = scs.Sporttype 
									 AND mcs.BetType = scs.bettype 
									 AND mcs.IsLive = scs.IsLive
			INNER JOIN #AgentPT cs ON cs.srecommend = scs.custid 
									 AND cs.SportType = scs.Sporttype 
									 AND cs.BetType = scs.bettype 
									 AND cs.IsLive = scs.IsLive
		WHERE mcs.SuperPT > scs.MaxPT - (cs.MasterPT + cs.AgentPT)
			OR mcs.SuperPT2 > scs.MaxPT2 - (cs.MasterPT2 + cs.AgentPT2)
	END
	
	--m2 > l4
	IF @ruleID IN (0,10008)
	BEGIN
		INSERT INTO CS_CheckPTResult (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive) 
		SELECT 10008, scs.BetType, scs.SportType, acs.custid, scs.custid, 
			CASE WHEN acs.MasterPT > scs.MaxPT THEN acs.MasterPT ELSE 
				acs.MasterPT2 END,
			CASE WHEN acs.MasterPT > scs.MaxPT THEN scs.MaxPT
				ELSE scs.MaxPT2 END,
			scs.isLive
		FROM #SuperPT scs
			INNER JOIN #AgentPT acs ON acs.srecommend = scs.custid 
									 AND acs.SportType = scs.Sporttype 
									 AND acs.BetType = scs.bettype 
									 AND acs.IsLive = scs.IsLive
		WHERE acs.MasterPT > scs.MaxPT
			OR acs.MasterPT2 > scs.MaxPT2
	END
	
	--a2 > l4		
	IF @ruleID IN (0,10009)
	BEGIN
		INSERT INTO CS_CheckPTResult (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive) 
		SELECT 10009, scs.BetType, scs.SportType, acs.custid, scs.custid, 
			CASE WHEN acs.AgentPT > scs.MaxPT THEN acs.AgentPT ELSE 
				acs.AgentPT2 END,
			CASE WHEN acs.AgentPT > scs.MaxPT THEN scs.MaxPT
				ELSE scs.MaxPT2 END,
			scs.isLive
		FROM #SuperPT scs
			INNER JOIN #AgentPT acs ON acs.srecommend = scs.custid 
									 AND acs.SportType = scs.Sporttype 
									 AND acs.BetType = scs.bettype 
									 AND acs.IsLive = scs.IsLive
		WHERE acs.AgentPT > scs.MaxPT
			OR acs.AgentPT2 > scs.MaxPT2	
	END		
END
GO
