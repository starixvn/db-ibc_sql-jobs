 ALTER PROCEDURE dbo.Acc_DynamicCustSetting3rd_09  
(  
 @agentID INT, @Threshold INT = 20, @target VARCHAR(30)  
)   
AS  
/*  
 Created By: Helen  
 Created Date: 20151027  
 Description: Scripts to maintain PT Group  
 DB: DBCust/CustDB  
 Param explaination:  
  @agentID: recommend  
  @Threshold: default 20, it means that it will be re-grouped   
     if number of grouped member is more than 20 percent the current one   
   
   
 EXEC DBA_CustSetting_GroupedPTSettingMaintenance @agentid = 1262, @Threshold = 20  
  
*/   
BEGIN  
	SET NOCOUNT ON  

	IF (@target = 'REPLICATED' AND @@SERVERNAME = 'DBCUST') RETURN	-- run at all replicated servers
	IF (@target = 'DBCUST' AND @@SERVERNAME <> 'DBCUST') RETURN -- run at DBCUST only
	
	IF NOT (dbo.f_CheckRepTable('CustInfo') = 1 
			AND dbo.f_CheckRepTable('CustPTSetting3rd_Agent') = 1
			AND dbo.f_CheckRepTable('CustSettingMode3rd') = 1
			AND dbo.f_CheckRepTable('CustPTSetting3rd_Member') = 1
			AND dbo.f_CheckRepTable('CustPTGroupSetting3rd_Member') = 1
	    
	   )
		RETURN
	  
	CREATE TABLE #tempData (custid int, cs1 bigint, cs2 int)  

	CREATE TABLE #tempGroup(cs1 bigint, cs2 int, memberCNT int, repCustID int)  

	SELECT CustID  
	INTO #tmpMembers  
	FROM CustInfo WITH (NOLOCK) WHERE Recommend = @AgentID AND roleid = 1  

	IF NOT EXISTS (SELECT 1 FROM #tmpMembers)
		RETURN
		
	;WITH _s as (  
	SELECT c.custid   
		,rdSetting = CAST(DENSE_RANK() OVER(ORDER BY sporttype, bettype, islive, superPT, masterPT, agentPT, isAutoMasterPT, AutoMasterPT, isAutoSuperPT, AutoSuperPT) as INT)  
		,rdProduct = CAST(DENSE_RANK() OVER(ORDER BY sporttype, bettype, islive) as INT)  
	FROM #tmpMembers c WITH(NOLOCK)  
		INNER JOIN dbo.CustPTSetting3rd_Member pt WITH(NOLOCK) ON c.custid = pt.custid    
	)  

	INSERT INTO #tempdata (custid, cs1, cs2)  
	SELECT custid, SUM(CONVERT(bigint,rdSetting) + POWER(2, rdProduct%10+1)), CHECKSUM_AGG(CHECKSUM(HASHBYTES('SHA1', CONVERT(nvarchar(max), rdSetting))))  
	FROM _s  
	GROUP BY custid  

	INSERT INTO #tempGroup(cs1, cs2, memberCNT, repCustID)  
	SELECT cs1, cs2, memberCnt, repCustID  
	FROM (  
	SELECT cs1, cs2, rn = ROW_NUMBER() OVER (ORDER BY count(1) desc, max(custid) desc), memberCnt = count(1), repCustID = max(custid)  
	FROM #tempdata  
	GROUP BY cs1, cs2  
	) x  
	WHERE rn = 1  

	DECLARE @GroupedPlayers_Current INT  
	DECLARE @GroupedPlayers_New INT  

	SET @GroupedPlayers_Current = (SELECT COUNT(*)   
		  FROM CustSettingMode3rd CS WITH (NOLOCK)   
		 JOIN #tmpMembers CI ON CS.CustID = CI.CustID  
		  WHERE IsGrouped = 1)  

	SET @GroupedPlayers_Current = @GroupedPlayers_Current + @GroupedPlayers_Current * @Threshold / 100  

	SET @GroupedPlayers_New = (SELECT memberCNT FROM #tempGroup)  

	/* Debug  

	SELECT @GroupedPlayers_Current, @GroupedPlayers_New  
	SELECT * FROM #tempGroup  
	SELECT * FROM #tempdata  

	SELECT DISTINCT sporttype, bettype, islive, superPT, masterPT, agentPT, isAutoMasterPT, AutoMasterPT, isAutoSuperPT, AutoSuperPT    
	FROM CustPTSetting3rd_Member T1    
	JOIN #tempdata T2 ON T1.CustID = T2.CustID    
	JOIN #tempGroup T3 ON T3.CS1 = T2.CS1 AND T3.CS2=T2.CS2    
	ORDER BY  sporttype, bettype, islive    


	SELECT DISTINCT sporttype, bettype, islive    
	FROM CustPTSetting3rd_Member T1    
	JOIN #tmpMembers T2 ON T1.CustID = t2.Custid    
	order by sporttype, bettype, islive    

	RETURN  

	*/  

	--SELECT @GroupedPlayers_Current, @GroupedPlayers_New  

	IF @GroupedPlayers_New > = @GroupedPlayers_Current  
	BEGIN  
	PRINT 'Starting regroup ....'  
	 
	DECLARE @repCustID INT = (SELECT repCustID FROM #tempGroup)  
	IF EXISTS( SELECT 1   
			  FROM CustPTGroupSetting3rd_Member T1 WITH (NOLOCK)   
			   JOIN  CustPTSetting3rd_Member T2 ON T1.SportType =  T2.SportType AND T1.BetType = T2.BetType AND T1.IsLive = T2.IsLive  
						 AND T1.SuperPT = T2.SuperPT AND T1.MasterPT = T2.MasterPT AND T1.AgentPT = T2.AgentPT  
						 AND T1.IsAutoMasterPT = T2.IsAutoMasterPT AND T1.AutoMasterPT =  T2.AutoMasterPT   
						 AND T1.IsAutoSuperPT = T2.IsAutoSuperPT AND T1.AutoSuperPT = T2.AutoSuperPT  
			  WHERE T1.agentID = @AgentID AND T2.CustID = @repCustID)  
	BEGIN
	  
		PRINT 'Starting: Processing for old group and new group has the same setting for this agent ...'  
		-- Update isGroup for player  
		UPDATE T  
		SET IsGrouped = 1  
		FROM CustSettingMode3rd T  
		 JOIN #tempdata T1 ON T1.CustID = T.CustID    
		 JOIN #tempGroup T3 ON T3.CS1 = T1.CS1 AND T3.CS2=T1.CS2    
		  
		-- Delete individual Setting  
		DELETE T  
		FROM CustPTSetting3rd_Member T  
		 JOIN #tempdata T1 ON T1.CustID = T.CustID    
		 JOIN #tempGroup T3 ON T3.CS1 = T1.CS1 AND T3.CS2=T1.CS2    
		PRINT 'Finished: Processing for old group and new group has the same setting for this agent ...'  
	END     
	ELSE  
	BEGIN  
		PRINT 'Starting: Processing for creating new group for this agent ...'  
		-- Move Old PT Group to individual Setting  
		INSERT INTO CustPTSetting3rd_Member  
		SELECT  cs.custid,T1.SportType,T1.BetType,T1.IsLive,T1.SuperPT,T1.MasterPT,T1.AgentPT,T1.IsAutoMasterPT,T1.AutoMasterPT,T1.IsAutoSuperPT,T1.AutoSuperPT  
		FROM CustSettingMode3rd CS WITH (NOLOCK)   
		 JOIN #tmpMembers m ON CS.Custid = m.Custid  
		 JOIN CustPTGroupSetting3rd_Member T1 WITH (NOLOCK) ON T1.AgentID = @AgentID  
		WHERE cs.IsGrouped = 1   
		  
		UPDATE CSM  
		 SET IsGrouped = 0  
		FROM CustSettingMode3rd CSM  
		 JOIN #tmpMembers m ON m.CustID = CSM.custid  
		WHERE CSM.IsGrouped = 1   
		  
		-- Create new Group PT for agent  
		DELETE FROM CustPTGroupSetting3rd_Member WHERE AgentID = @AgentID  
		  
		INSERT INTO CustPTGroupSetting3rd_Member  
		SELECT @agentID AS agentID ,  
		  T1.SportType,T1.BetType,T1.IsLive,T1.SuperPT,T1.MasterPT,T1.AgentPT,T1.IsAutoMasterPT,T1.AutoMasterPT,T1.IsAutoSuperPT,T1.AutoSuperPT  
		FROM CustPTSetting3rd_Member T1  
		WHERE T1.CustID = @repCustID  

		UPDATE CSM  
		 SET IsGrouped = 1  
		FROM CustSettingMode3rd CSM  
		 JOIN #tempdata TempD ON CSM.Custid = tempD.CustID  
		 JOIN #tempGroup TempG ON TempG.cs2 = TempD.cs2 AND TempD.cs1 = TempG.cs1  
		WHERE CSM.IsGrouped = 0  
		   
		-- Delete Individual setting for grouped players   
		DELETE T  
		FROM CustPTSetting3rd_Member T  
		 JOIN #tempdata TempD ON t.Custid = tempD.CustID  
		 JOIN #tempGroup TempG ON TempG.cs2 = TempD.cs2 AND TempD.cs1 = TempG.cs1  
		
		PRINT 'Finished: Processing for creating new group for this agent ...'   
	END   
     
 END  
   
 DROP TABLE #TempData  
 DROP TABLE #tempGroup  
 DROP TABLE #tmpMembers  
  
END

--STEP 1: Pick up the top agents that have most inefficient GROUP PT settings before re-grouping process
EXEC DBA_CustSetting_DetectGroupedPTSetting @Threshold_cnt = 100
/*
Note: if only pick up agents under particular line, we can pass param @srecommend when executing sp
for example:
EXEC DBA_CustSetting_DetectGroupedPTSetting @srecommend = 2, @Threshold_cnt = 100
*/

--STEP 2: Choose agents in the first step and run this command to start re-grouping process
	--2.1: backup data before regrouping process RUN THIS SCRIPT AT DBCUST -----

	TRUNCATE TABLE CustPTSetting3rd_Member_temp
	TRUNCATE TABLE CustPTGroupSetting3rd_Member_TEMP
	TRUNCATE TABLE CustSettingMode3rd_temp

	INSERT INTO CustPTSetting3rd_Member_temp
	SELECT C.* 
	FROM CustPTSetting3rd_Member C WITH (NOLOCK)
		JOIN CustInfo CI WITH (NOLOCK) ON C.CustID = CI.CustID
	WHERE CI.recommend = @agentID
		
	INSERT INTO CustPTGroupSetting3rd_Member_TEMP
	SELECT * 
	FROM CustPTGroupSetting3rd_Member WITH (NOLOCK)
	WHERE agentID = @agentID

	INSERT INTO CustSettingMode3rd_temp
	SELECT c.* 
	FROM CustSettingMode3rd C WITH (NOLOCK)
		JOIN CustInfo CI WITH (NOLOCK) ON C.CustID = CI.CustID
	WHERE CI.recommend = @agentID

	--2.2 BEGIN STEP 3: RUN THIS SCRIPT AT DBCUST -----
	EXEC dbo.Acc_DynamicCustSetting3rd_09 @agentid = ???, @Threshold = 20, @target = 'DBCUST'

	--2.3: RUN THIS SCRIPT AT ALL REPLICATED SERVERS (06/DBTP) -----
	EXEC Acc_DynamicCustSetting3rd_09 @agentid = ???, @Threshold = 20, @target = 'REPLICATED'

-- End of STEP 2			

-- STEP 3: CHECKING DATA: RUN THIS SCRIPT AT DBCUST -----
	CREATE TABLE #PT_Old([CustID] [int] ,[SportType] [smallint] ,[BetType] [smallint] ,	[IsLive] [bit] ,
						[SuperPT] [tinyint] ,[MasterPT] [tinyint] ,	[AgentPT] [tinyint] ,
						[IsAutoMasterPT] [bit] ,[AutoMasterPT] [tinyint] ,	[IsAutoSuperPT] [bit] ,
						[AutoSuperPT] [tinyint] ,IsOld BIT
						PRIMARY KEY CLUSTERED 
						(	[CustID] ASC,
							[SportType] ASC,
							[BetType] ASC,
							[IsLive] ASC
						)
					)

	CREATE TABLE #PT_New([CustID] [int] ,[SportType] [smallint] ,[BetType] [smallint] ,	[IsLive] [bit] ,
					[SuperPT] [tinyint] ,[MasterPT] [tinyint] ,	[AgentPT] [tinyint] ,
					[IsAutoMasterPT] [bit] ,[AutoMasterPT] [tinyint] ,	[IsAutoSuperPT] [bit] ,
					[AutoSuperPT] [tinyint] ,IsOld BIT
					PRIMARY KEY CLUSTERED 
					(	[CustID] ASC,
						[SportType] ASC,
						[BetType] ASC,
						[IsLive] ASC
					)
				)
	CREATE TABLE #PT_Match (CustID INT)
	
	INSERT INTO #PT_Old			
	SELECT CI.CustID, cs.SportType,cs.BetType,cs.IsLive,cs.SuperPT,cs.MasterPT,cs.AgentPT,cs.IsAutoMasterPT,cs.AutoMasterPT,cs.IsAutoSuperPT,cs.AutoSuperPT,1 IsOld
	FROM CustInfo ci WITH (NOLOCK)
		JOIN CustPTSetting3rd_Member_TEMP cs WITH (NOLOCK) ON ci.CustID = cs.CustID
	WHERE ci.recommend = @agentID
			AND ci.roleid = 1  
			AND ci.Enabled = 1      
			AND ci.Currency NOT IN (20,27,28)     
	UNION ALL
	SELECT ci.CustID, cs.SportType,cs.BetType,cs.IsLive,cs.SuperPT,cs.MasterPT,cs.AgentPT,cs.IsAutoMasterPT,cs.AutoMasterPT,cs.IsAutoSuperPT,cs.AutoSuperPT,1 IsOld
	FROM CustInfo ci (NOLOCK)
		INNER JOIN CustSettingMode3rd_TEMP csm WITH (NOLOCK) ON ci.custid = csm.CustID AND csm.IsGrouped = 1
		INNER JOIN CustPTGroupSetting3rd_Member_TEMP cs WITH (NOLOCK) ON cs.AgentID = ci.recommend  
	WHERE ci.recommend = @agentID
			AND ci.roleid = 1  
			AND ci.Enabled = 1      
			AND ci.Currency NOT IN (20,27,28)  
			
	INSERT INTO #PT_New		
	SELECT CI.CustID, cs.SportType,cs.BetType,cs.IsLive,cs.SuperPT,cs.MasterPT,cs.AgentPT,cs.IsAutoMasterPT,cs.AutoMasterPT,cs.IsAutoSuperPT,cs.AutoSuperPT,0 IsOld
	FROM CustInfo ci WITH (NOLOCK)
		JOIN CustPTSetting3rd_Member cs WITH (NOLOCK) ON ci.CustID = cs.CustID
	WHERE ci.recommend = @agentID
			AND ci.roleid = 1  
			AND ci.Enabled = 1      
			AND ci.Currency NOT IN (20,27,28)     
	UNION ALL
	SELECT ci.CustID, cs.SportType,cs.BetType,cs.IsLive,cs.SuperPT,cs.MasterPT,cs.AgentPT,cs.IsAutoMasterPT,cs.AutoMasterPT,cs.IsAutoSuperPT,cs.AutoSuperPT,0 IsOld
	FROM CustInfo ci (NOLOCK)
		INNER JOIN CustSettingMode3rd csm WITH (NOLOCK) ON ci.custid = csm.CustID AND csm.IsGrouped = 1
		INNER JOIN CustPTGroupSetting3rd_Member cs WITH (NOLOCK) ON cs.AgentID = ci.recommend  
	WHERE ci.recommend = @agentID
			AND ci.roleid = 1  
			AND ci.Enabled = 1      
			AND ci.Currency NOT IN (20,27,28)  
	
	INSERT INTO #PT_Match
	SELECT T1.CustID
	FROM #PT_Old T1
		INNER JOIN #PT_New T2 ON T1.CustID = T2.CustID AND T1.SportType = T2.SportType AND T1.BetType = T2.BetType AND T1.IsLive = T2.IsLive			
						 AND  T1.SuperPT = T2.SuperPT AND T1.MasterPT = T2.MasterPT AND T1.AgentPT = T2.AgentPT  
						 AND T1.IsAutoMasterPT = T2.IsAutoMasterPT AND T1.AutoMasterPT =  T2.AutoMasterPT   
						 AND T1.IsAutoSuperPT = T2.IsAutoSuperPT AND T1.AutoSuperPT = T2.AutoSuperPT  
	
	DECLARE @Count_Match INT = 0
	DECLARE @Count_Old INT = 0
	
	SET @Count_Match = (SELECT COUNT(*) FROM #PT_Match)
	
	SET @Count_Old = (SELECT COUNT(*) FROM #PT_Old)
	
	IF @Count_Old = @Count_Match
		PRINT 'PT of members are correct after regrouping process'
	ELSE
	BEGIN
		PRINT 'PT of members are NOT correct after regrouping process'
		PRINT 'Starting: Collecting members have wrong PT after regrouping process'
		SELECT T.*
		FROM 
		(	SELECT T1.*
			FROM #PT_Old T1
			WHERE NOT EXISTS (SELECT 1 FROM #PT_Match T WHERE T.CustID = T1.CustID)		
			UNION ALL
			SELECT T1.*
			FROM #PT_New T1
			WHERE NOT EXISTS (SELECT 1 FROM #PT_Match T WHERE T.CustID = T1.CustID)
		) AS T
		ORDER BY T.CustID, SportType,BetType,IsLive,IsOld
		PRINT 'Finished: Collecting members have wrong PT after regrouping process'
	END		
-- END of step 3	