
/*
	Created By: Helen@20151105
	Description: Setup PT Group for UUS customers 
	@Mode = 0: 'Processing for old group and new group has the same setting for this agent ...'
	@Mode = 1: 'Processing for creating new group'
*/
--******************************************STEP 1 : Deploy this SP at DBCUST.CustDB, Run only in the FIRST running**************************************
ALTER PROCEDURE Acc_DynamicCustSetting3rd_09 @target VARCHAR(30), @Mode BIT = 0
AS

BEGIN   
	SET NOCOUNT ON
	
	IF (@target = 'REPLICATED' AND @@SERVERNAME = 'DBCUST') RETURN	-- run at all replicated servers
	IF (@target = 'DBCUST' AND @@SERVERNAME <> 'DBCUST') RETURN -- run at DBCUST only
	
	IF NOT (
		dbo.f_CheckRepTable('CustSettingMode3rd') = 1 
		AND dbo.f_CheckRepTable('CustPTSetting3rd_Member') = 1
		AND dbo.f_CheckRepTable('CustSettingMode3rd_Buffer') = 1
	   )
	  RETURN
	 
	IF @Mode = 0
	BEGIN
		--Update group mode	
		UPDATE main
		SET main.IsGrouped = buffer.IsGrouped
		FROM dbo.CustSettingMode3rd main WITH(ROWLOCK,UPDLOCK)
		INNER JOIN CustSettingMode3rd_Buffer buffer WITH(NOLOCK)
			ON buffer.custid = main.CustID
			
		--Delete individual settings		
		DELETE cs
		FROM dbo.CustPTSetting3rd_Member cs
		INNER JOIN CustSettingMode3rd_Buffer buffer WITH(NOLOCK)
			ON buffer.custid = cs.CustID
		WHERE buffer.IsGrouped = 1
		
	END
	ELSE IF @Mode = 1
	BEGIN

		PRINT 'Starting creating new group for this agent ...'
		-- Move Old PT Group to individual Setting
		INSERT INTO CustPTSetting3rd_Member
		SELECT  cs.custid,T1.SportType,T1.BetType,T1.IsLive,T1.SuperPT,T1.MasterPT,T1.AgentPT,T1.IsAutoMasterPT,T1.AutoMasterPT,T1.IsAutoSuperPT,T1.AutoSuperPT
		FROM CustSettingMode3rd_BUFFER CS WITH (NOLOCK) 
			CROSS APPLY(SELECT T1.SportType,T1.BetType,T1.IsLive,T1.SuperPT,T1.MasterPT,T1.AgentPT,T1.IsAutoMasterPT,T1.AutoMasterPT,T1.IsAutoSuperPT,T1.AutoSuperPT
						FROM CustPTGroupSetting3rd_Member_BUFFER T1 WITH (NOLOCK)
						) AS T1
		WHERE cs.IsGrouped = 1 

		UPDATE CSM
			SET IsGrouped = m.IsGrouped
		FROM CustSettingMode3rd CSM
			JOIN CustSettingMode3rd_BUFFER m ON m.CustID = CSM.custid

		-- Create new Group PT for agent
		DELETE FROM CustPTGroupSetting3rd_Member WHERE AgentID = @AgentID

		INSERT INTO CustPTGroupSetting3rd_Member
		SELECT @agentID AS agentID ,
				T1.SportType,T1.BetType,T1.IsLive,T1.SuperPT,T1.MasterPT,T1.AgentPT,T1.IsAutoMasterPT,T1.AutoMasterPT,T1.IsAutoSuperPT,T1.AutoSuperPT
		FROM CustPTSetting3rd_Member T1
		WHERE T1.CustID = @repCustID

		 
		-- Delete Individual setting for grouped players 
		DELETE T
		FROM CustPTSetting3rd_Member T
			JOIN CustSettingMode3rd_Buffer T1 ON T.CustID = T1.CustID
		WHERE T1.IsGrouped = 0	
	END
	
	
END

GO
ALTER PROCEDURE dbo.DBA_CustSetting_GroupedPTSettingMaintenance
(
	@agentID INT, @Threshold INT = 20
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
		
	CREATE TABLE #tempData (custid int, cs1 bigint, cs2 int)
	
	CREATE TABLE #tempGroup(cs1 bigint, cs2 int, memberCNT int, repCustID int)
	
	SELECT CustID
	INTO #tmpMembers
	FROM CustInfo WITH (NOLOCK) WHERE Recommend = @AgentID AND roleid = 1
	
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
		SELECT cs1, cs2, rn = ROW_NUMBER() OVER (ORDER BY count(1) desc), memberCnt = count(1), repCustID = max(custid)
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
	
	IF @GroupedPlayers_New > = @GroupedPlayers_Current
	BEGIN
			PRINT 'Starting regroup ....'
			
			TRUNCATE TABLE CustSettingMode3rd_buffer
			
			DECLARE @repCustID INT = (SELECT repCustID FROM #tempGroup)
			IF EXISTS( SELECT 1 
						FROM CustPTGroupSetting3rd_Member T1 WITH (NOLOCK) 
							JOIN  CustPTSetting3rd_Member T2 ON T1.SportType =  T2.SportType AND T1.BetType = T2.BetType AND T1.IsLive = T2.IsLive
																	AND T1.SuperPT = T2.SuperPT AND T1.MasterPT = T2.MasterPT AND T1.AgentPT = T2.AgentPT
																	AND T1.IsAutoMasterPT = T2.IsAutoMasterPT AND T1.AutoMasterPT =  T2.AutoMasterPT 
																	AND T1.IsAutoSuperPT = T2.IsAutoSuperPT	AND T1.AutoSuperPT = T2.AutoSuperPT
						WHERE T1.agentID = @AgentID	AND T2.CustID = @repCustID)
			BEGIN
				PRINT 'Processing for old group and new group has the same setting for this agent ...'
				-- Update isGroup for player
				INSERT INTO CustSettingMode3rd_buffer
				SELECT T.CustID , 1
				FROM CustSettingMode3rd T
					JOIN #tempdata T1 ON T1.CustID = T.CustID  
					JOIN #tempGroup T3 ON T3.CS1 = T1.CS1 AND T3.CS2=T1.CS2  
				
				--*********************************** Run this SP at DBCust ***********
				EXEC Acc_DynamicCustSetting3rd_09 @target = 'DBCUST'
				
				--***********************************STEP 6 : Run this SP at replicated DB ***********
				EXEC Acc_DynamicCustSetting3rd_09 @target = 'REPLICATED'
				
			END			
			ELSE
			BEGIN
				
				TRUNCATE TABLE CustPTGroupSetting3rd_Member_BUFFER
				
				-- Update IsGroup in case of Moving Old PT Group to individual Setting
				INSERT INTO CustSettingMode3rd_buffer
				SELECT CSM.CustID, 0
				FROM CustSettingMode3rd CSM
					JOIN #tmpMembers m ON m.CustID = CSM.custid
				WHERE CSM.IsGrouped = 1 
				
				-- Update IsGroup in case of Creating new Group PT for agent
				INSERT INTO CustSettingMode3rd_buffer
				SELECT CSM.Custid,	1
				FROM CustSettingMode3rd CSM
					JOIN #tempdata TempD ON CSM.Custid = tempD.CustID
					JOIN #tempGroup TempG ON TempG.cs2 = TempD.cs2 AND TempD.cs1 = TempG.cs1
				WHERE CSM.IsGrouped = 0
				
				INSERT INTO CustPTGroupSetting3rd_Member_BUFFER
				SELECT T1.AgentID,T1.SportType,T1.BetType,T1.IsLive,T1.SuperPT,T1.MasterPT,T1.AgentPT,T1.IsAutoMasterPT,T1.AutoMasterPT,T1.IsAutoSuperPT,T1.AutoSuperPT 
				FROM CustPTGroupSetting3rd_Member T1 WITH (NOLOCK) 
				WHERE T1.AgentID = @AgentID
				
				INSERT INTO CustPTGroupSetting3rd_Member
				SELECT @agentID AS agentID ,
						T1.SportType,T1.BetType,T1.IsLive,T1.SuperPT,T1.MasterPT,T1.AgentPT,T1.IsAutoMasterPT,T1.AutoMasterPT,T1.IsAutoSuperPT,T1.AutoSuperPT
				FROM CustPTSetting3rd_Member T1
				WHERE T1.CustID = @repCustID
				
				--*********************************** Run this SP at DBCust ***********
				EXEC Acc_DynamicCustSetting3rd_09 @target = 'DBCUST'
				
				--***********************************STEP 6 : Run this SP at replicated DB ***********
				EXEC Acc_DynamicCustSetting3rd_09 @target = 'REPLICATED'
								
			END	
			
	END
	
	DROP TABLE #TempData
	DROP TABLE #tempGroup
	DROP TABLE #tmpMembers

END