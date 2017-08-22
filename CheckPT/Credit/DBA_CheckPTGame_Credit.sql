USE [CheckResultDB]
GO

ALTER PROCEDURE [dbo].[DBA_CheckPTGame_Credit]
	 @srecommend INT 
	,@SportType SMALLINT = 0
	,@RuleId	SMALLINT = 0
AS
/*
Created: 20140313@Sophia
Task: Check PT setting for credit customers - Game setting
DB: DBCHECK.CheckResultDB
Revisions:
	- 20140723@Sophia: Add Keno
	- 20140910@Sophia: Change the Filter of customer from closed = 0 and Reject = 0 to Enabled = 1
	- 20141111@Sophia: Correct bettype LiveCasino
	- 20150728@Elodie: Add GoldDeluxe product
	- 20170508@Elodie: Count PT Setting rows

Param's Explanation: 
	@RuleId = 0 : 'all' 
	IF @sporttype IN (162, 255) (Live Casino, GoldDeluxe) THEN @RuleId IN (1, 5, 6, 7, 8, 9, 10, 17, 18, 19, 20, 23, 24, 28, 30, 31 )
	IF @sporttype = 202 (Keno) THEN @RuleId IN (1, 5, 6, 7, 8, 9, 10, 17, 18, 19, 20, 23, 24, 28, 31, 32 )
*/
BEGIN 
	SET NOCOUNT ON
	CREATE TABLE #MemberPT (CustID INT, recommend INT, mrecommend INT, srecommend INT, sporttype SMALLINT, bettype SMALLINT, spositiontaking SMALLMONEY, mpositiontaking SMALLMONEY, apositiontaking SMALLMONEY, isautompositiontaking BIT, autompositiontaking SMALLMONEY, isautopositiontaking BIT, autopositiontaking SMALLMONEY, SyncLiveCasino BIT)
	CREATE TABLE #AgentPT (CustID INT, mrecommend INT, srecommend INT, sporttype SMALLINT, bettype SMALLINT, spositiontaking SMALLMONEY, mpositiontaking SMALLMONEY, apositiontaking SMALLMONEY, isautompositiontaking BIT, autompositiontaking SMALLMONEY, isautopositiontaking BIT, autopositiontaking SMALLMONEY, Minpositiontaking SMALLMONEY, SyncLiveCasino BIT)
	CREATE TABLE #MasterPT (CustID INT, srecommend INT, sporttype SMALLINT, bettype SMALLINT, spositiontaking SMALLMONEY, mpositiontaking SMALLMONEY, apositiontaking SMALLMONEY, isautompositiontaking BIT, autompositiontaking SMALLMONEY, isautopositiontaking BIT, autopositiontaking SMALLMONEY, Minpositiontaking SMALLMONEY, SyncLiveCasino BIT)
	CREATE TABLE #SuperPT (CustID INT, sporttype SMALLINT, bettype SMALLINT, spositiontaking SMALLMONEY, mpositiontaking SMALLMONEY, apositiontaking SMALLMONEY, isautompositiontaking BIT, autompositiontaking SMALLMONEY, isautopositiontaking BIT, autopositiontaking SMALLMONEY, Minpositiontaking SMALLMONEY, SyncLiveCasino BIT)

	DECLARE @RowCount TINYINT

	SELECT cs.sporttype, cs.bettype
	INTO #DataSample
	FROM CheckCustDB.dbo.custsettinggame cs WITH (NOLOCK)
	WHERE custid = 73104

	SELECT @RowCount = COUNT(1)
	FROM #DataSample
	-- Starting DATA PREPARATION
	INSERT INTO #MemberPT (CustID, recommend, mrecommend, srecommend, sporttype, bettype, spositiontaking, mpositiontaking, apositiontaking, isautompositiontaking, autompositiontaking, isautopositiontaking, autopositiontaking, SyncLiveCasino)
	SELECT ci.CustID, recommend, mrecommend, srecommend, sporttype, bettype, spositiontaking, mpositiontaking, apositiontaking, isautompositiontaking, autompositiontaking, isautopositiontaking, autopositiontaking, SyncLiveCasino
	FROM CheckCustDB.dbo.CustInfo ci
		INNER JOIN CheckCustDB.dbo.CustSettingGame cs WITH (NOLOCK) ON ci.CustID = cs.CustID
	WHERE ci.srecommend = @srecommend  
			AND ci.roleid = 1  
			AND ci.Enabled = 1
			AND ci.Currency NOT IN (20,27,28)     
			AND cs.SportType = CASE WHEN @SportType = 0 then cs.SportType  ELSE @SportType END 
	
	INSERT INTO #AgentPT (CustID, mrecommend, srecommend, sporttype, bettype, spositiontaking, mpositiontaking, apositiontaking, isautompositiontaking, autompositiontaking, isautopositiontaking, autopositiontaking, Minpositiontaking, SyncLiveCasino)
	SELECT ci.CustID, mrecommend, srecommend, cs.sporttype, cs.bettype, spositiontaking, mpositiontaking, apositiontaking, isautompositiontaking, autompositiontaking, isautopositiontaking, autopositiontaking, Minpositiontaking, SyncLiveCasino
	FROM CheckCustDB.dbo.CustInfo ci
		INNER JOIN CheckCustDB.dbo.CustSettingGame cs WITH (NOLOCK) ON ci.CustID = cs.CustID
		INNER JOIN CheckCustDB.dbo.custoverrideGame co WITH (NOLOCK) ON ci.CustID = co.CustID AND co.sporttype = cs.sporttype AND co.bettype = cs.bettype
	WHERE ci.srecommend = @srecommend  
			AND ci.roleid = 2  
			AND ci.Enabled = 1
			AND ci.Currency NOT IN (20,27,28)     
			AND cs.SportType = CASE WHEN @SportType = 0 then cs.SportType  ELSE @SportType END 

	INSERT INTO #MasterPT (CustID, srecommend, sporttype, bettype, spositiontaking, mpositiontaking, apositiontaking, isautompositiontaking, autompositiontaking, isautopositiontaking, autopositiontaking, Minpositiontaking, SyncLiveCasino)
	SELECT ci.CustID, srecommend, cs.sporttype, cs.bettype, spositiontaking, mpositiontaking, apositiontaking, isautompositiontaking, autompositiontaking, isautopositiontaking, autopositiontaking, Minpositiontaking, SyncLiveCasino
	FROM CheckCustDB.dbo.CustInfo ci
		INNER JOIN CheckCustDB.dbo.CustSettingGame cs WITH (NOLOCK) ON ci.CustID = cs.CustID
		INNER JOIN CheckCustDB.dbo.custoverrideGame co WITH (NOLOCK) ON ci.CustID = co.CustID AND co.sporttype = cs.sporttype AND co.bettype = cs.bettype
	WHERE ci.srecommend = @srecommend  
			AND ci.roleid = 3
			AND ci.Enabled = 1
			AND ci.Currency NOT IN (20,27,28)     
			AND cs.SportType = CASE WHEN @SportType = 0 then cs.SportType  ELSE @SportType END 

	INSERT INTO #SuperPT (CustID, sporttype, bettype, spositiontaking, mpositiontaking, apositiontaking, isautompositiontaking, autompositiontaking, isautopositiontaking, autopositiontaking, Minpositiontaking, SyncLiveCasino)
	SELECT ci.CustID, cs.sporttype, cs.bettype, spositiontaking, mpositiontaking, apositiontaking, isautompositiontaking, autompositiontaking, isautopositiontaking, autopositiontaking, Minpositiontaking, SyncLiveCasino
	FROM CheckCustDB.dbo.CustInfo ci
		INNER JOIN CheckCustDB.dbo.CustSettingGame cs WITH (NOLOCK) ON ci.CustID = cs.CustID
		INNER JOIN CheckCustDB.dbo.custoverrideGame co WITH (NOLOCK) ON ci.CustID = co.CustID AND co.sporttype = cs.sporttype AND co.bettype = cs.bettype
	WHERE ci.custid = @srecommend  
			AND ci.Enabled = 1
			AND ci.Currency NOT IN (20,27,28)     
			AND cs.SportType = CASE WHEN @SportType = 0 then cs.SportType  ELSE @SportType END 	
		
	SELECT CustID, COUNT(1) cnt
	INTO #MemberMissSetting
	FROM #MemberPT 
	GROUP BY CustID
	HAVING COUNT(1) < @RowCount

	SELECT CustID, COUNT(1) cnt
	INTO #AgentMissSetting
	FROM #AgentPT 
	GROUP BY CustID
	HAVING COUNT(1) < @RowCount

	SELECT CustID, COUNT(1) cnt
	INTO #MasterMissSetting
	FROM #MasterPT 
	GROUP BY CustID
	HAVING COUNT(1) < @RowCount

	SELECT CustID, COUNT(1) cnt
	INTO #SuperMissSetting
	FROM #SuperPT 
	GROUP BY CustID
	HAVING COUNT(1) < @RowCount
	
	--Miss all Casino product setting
	INSERT INTO #MemberMissSetting (CustID)	
	SELECT CustID
	FROM CheckCustDB.dbo.custInfo ci WITH (NOLOCK)
	WHERE ci.srecommend = @srecommend
		AND ci.roleid = 1
		AND ci.Enabled = 1
		AND ci.Currency NOT IN (20,27,28)   
		AND NOT EXISTS (SELECT 1 FROM #MemberPT WHERE CustID = ci.custid)

	INSERT INTO #AgentMissSetting (CustID)	       	
	SELECT CustID
	FROM CheckCustDB.dbo.custInfo ci WITH (NOLOCK)
	WHERE ci.srecommend = @srecommend
		AND ci.roleid = 2
		AND ci.Enabled = 1
		AND ci.Currency NOT IN (20,27,28)   
		AND NOT EXISTS (SELECT 1 FROM #AgentPT WHERE CustID = ci.custid)

	INSERT INTO #MasterMissSetting (CustID)	  	     	
	SELECT CustID
	FROM CheckCustDB.dbo.custInfo ci WITH (NOLOCK)
	WHERE ci.srecommend = @srecommend
		AND ci.roleid = 3
		AND ci.Enabled = 1
		AND ci.Currency NOT IN (20,27,28)   
		AND NOT EXISTS (SELECT 1 FROM #MasterPT WHERE CustID = ci.custid)

	INSERT INTO #SuperMissSetting (CustID)	  	      	       	
	SELECT CustID
	FROM CheckCustDB.dbo.custInfo ci WITH (NOLOCK)
	WHERE ci.custid = @srecommend
		AND ci.roleid = 4
		AND ci.Enabled = 1
		AND ci.Currency NOT IN (20,27,28)   
		AND NOT EXISTS (SELECT 1 FROM #SuperPT WHERE CustID = ci.custid)
	-- End DATA PREPARATION

	--Check a number of setting rows
	INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive) 
	SELECT	42 AS ruleid, ds.bettype, ds.sporttype, cs.CustID, cs.CustID, 0, 0, 0
	FROM	#MemberMissSetting cs
		CROSS APPLY (SELECT sporttype, bettype FROM #DataSample) ds
	WHERE NOT EXISTS (SELECT 1 FROM #MemberPT WHERE CustID = cs.CustID AND sporttype = ds.sporttype AND bettype = ds.bettype)
		
	INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive) 
	SELECT	42 AS ruleid, ds.bettype, ds.sporttype, cs.CustID, cs.CustID, 0, 0, 0
	FROM	#AgentMissSetting cs
		CROSS APPLY (SELECT sporttype, bettype FROM #DataSample) ds
	WHERE NOT EXISTS (SELECT 1 FROM #AgentPT WHERE CustID = cs.CustID AND sporttype = ds.sporttype AND bettype = ds.bettype)
	
	INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive) 
	SELECT	42 AS ruleid, ds.bettype, ds.sporttype, cs.CustID, cs.CustID, 0, 0, 0
	FROM	#MasterMissSetting cs
		CROSS APPLY (SELECT sporttype, bettype FROM #DataSample) ds
	WHERE NOT EXISTS (SELECT 1 FROM #MasterPT WHERE CustID = cs.CustID AND sporttype = ds.sporttype AND bettype = ds.bettype)

	INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive) 
	SELECT	42 AS ruleid, ds.bettype, ds.sporttype, cs.CustID, cs.CustID, 0, 0, 0
	FROM	#SuperMissSetting cs
		CROSS APPLY (SELECT sporttype, bettype FROM #DataSample) ds
	WHERE NOT EXISTS (SELECT 1 FROM #SuperPT WHERE CustID = cs.CustID AND sporttype = ds.sporttype AND bettype = ds.bettype)

	IF @sporttype IN (162, 202, 255) OR @sporttype = 0 
	BEGIN 
	---- 1. S1 < 0 OR M1 < 0 OR A1 < 0

		IF @RuleId IN (0,1)
		BEGIN
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive) 
			SELECT	1 as RuleId, cs.BetType, cs.SportType, cs.CustId, cs.CustId,
					CASE WHEN cs.spositiontaking < 0 THEN cs.spositiontaking 
						 WHEN cs.mpositiontaking < 0 THEN cs.mpositiontaking 
						 WHEN cs.apositiontaking < 0 THEN cs.apositiontaking
					ELSE 0
					END,
					0, 
					0
			FROM	#MemberPT cs
			WHERE	CASE WHEN cs.Sporttype = 162 THEN cs.SyncLiveCasino ELSE 1 END = 1
				AND (cs.spositiontaking < 0 OR cs.mpositiontaking < 0 OR cs.apositiontaking < 0)		
		END
		
		----5. S4 < N4  
		IF @RuleId IN (0,5)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	5 as RuleId, cs.BetType, cs.SportType, cs.CustId, cs.CustId, cs.spositiontaking, cs.minpositiontaking, 0
			FROM	#SuperPT cs
			WHERE CASE WHEN cs.Sporttype = 162 THEN cs.SyncLiveCasino ELSE 1 END = 1
				AND CASE WHEN @Sporttype <> 0 THEN cs.Sporttype ELSE @SportType END = @SportType
				AND cs.spositiontaking < cs.minpositiontaking
		END

		----6. S4 < US3 
		IF @RuleId IN (0,6)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	6 as RuleId, cs.BetType, cs.SportType, scs.CustId, cs.CustId, scs.spositiontaking , cs.autopositiontaking, 0
			FROM	#SuperPT scs			
				INNER JOIN	#MasterPT cs ON	cs.srecommend = scs.CustId AND cs.bettype = scs.bettype AND cs.sporttype = scs.sporttype
			WHERE	CASE WHEN cs.Sporttype = 162 THEN cs.SyncLiveCasino ELSE 1 END = 1
				AND scs.spositiontaking < cs.autopositiontaking
		END

		----7. S4 < US1 
		IF @RuleId IN (0,7)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	7 as RuleId, cs.BetType, cs.SportType, scs.CustId, cs.CustId, scs.spositiontaking, cs.autopositiontaking, 0
			FROM	#SuperPT scs			
			INNER JOIN	#MemberPT cs ON	cs.srecommend = scs.CustId AND cs.bettype = scs.bettype AND cs.sporttype = scs.sporttype
			WHERE CASE WHEN cs.Sporttype = 162 THEN cs.SyncLiveCasino ELSE 1 END = 1
				AND scs.spositiontaking < cs.autopositiontaking			
		END
	
		----8. S4 < S3 + M3 
		IF @RuleId IN (0,8)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	8 as RuleId, cs.BetType, cs.SportType, scs.CustId, cs.CustId, scs.spositiontaking, cs.spositiontaking + cs.mpositiontaking, 0
			FROM	#SuperPT scs			
				INNER JOIN	#MasterPT cs ON	cs.srecommend = scs.CustId AND cs.bettype = scs.bettype AND cs.sporttype = scs.sporttype
			WHERE CASE WHEN cs.Sporttype = 162 THEN cs.SyncLiveCasino ELSE 1 END = 1
				AND scs.spositiontaking < cs.spositiontaking + cs.mpositiontaking		
		END

		----9. S4 < S1 + M1 + A1 
		IF @RuleId IN (0,9)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	9 as RuleId, cs.BetType, cs.SportType, scs.CustId, cs.CustId, scs.spositiontaking, cs.spositiontaking + cs.mpositiontaking + cs.apositiontaking, 0
			FROM	#SuperPT scs			
				INNER JOIN	#MemberPT cs ON	cs.srecommend = scs.CustId AND cs.bettype = scs.bettype AND cs.sporttype = scs.sporttype
			WHERE CASE WHEN cs.Sporttype = 162 THEN cs.SyncLiveCasino ELSE 1 END = 1
				AND scs.spositiontaking < cs.spositiontaking + cs.mpositiontaking + cs.apositiontaking			
		END

		----10. N4 > S1 + M1 + A1 
		IF @RuleId IN (0,10)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	10 as RuleId, cs.BetType, cs.SportType, scs.CustId, cs.CustId, scs.minpositiontaking, cs.spositiontaking + cs.mpositiontaking + cs.apositiontaking, 0
			FROM	#SuperPT scs			
				INNER JOIN	#MemberPT cs ON	cs.srecommend = scs.CustId AND cs.bettype = scs.bettype AND cs.sporttype = scs.sporttype
			WHERE CASE WHEN cs.Sporttype = 162 THEN cs.SyncLiveCasino ELSE 1 END = 1
				AND scs.minpositiontaking > cs.spositiontaking + cs.mpositiontaking + cs.apositiontaking			
		END
		-----------------------------------------------------------------------
  
		----17. M3 < N3 
		IF @RuleId IN (0,17)
		BEGIN
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	17 as RuleId, cs.BetType, cs.SportType, cs.CustId, cs.CustId, cs.mpositiontaking, cs.minpositiontaking, 0
			FROM #MasterPT cs
			WHERE CASE WHEN cs.Sporttype = 162 THEN cs.SyncLiveCasino ELSE 1 END = 1
				AND cs.mpositiontaking < cs.minpositiontaking			
		END

		--------------------------------------------------------------------------------------------
		----18. M3 < M2 + A2 
		IF @RuleId IN (0,18)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	18 as RuleId, cs.BetType, cs.SportType, mcs.CustId, cs.CustId, mcs.mpositiontaking, cs.mpositiontaking + cs.apositiontaking, 0
			FROM	#MasterPT mcs		
			INNER JOIN	#AgentPT cs ON	cs.mrecommend = mcs.CustId AND cs.bettype = mcs.bettype AND cs.sporttype = mcs.sporttype
			WHERE CASE WHEN cs.Sporttype = 162 THEN cs.SyncLiveCasino ELSE 1 END = 1
				AND mcs.mpositiontaking < cs.mpositiontaking + cs.apositiontaking		
		END
	
		----19. M3 < M1 + A1 
		IF @RuleId IN (0,19)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	19 as RuleId, cs.BetType, cs.SportType, mcs.CustId, cs.CustId, mcs.mpositiontaking, cs.mpositiontaking + cs.apositiontaking, 0
			FROM	#MasterPT mcs		
				INNER JOIN	#MemberPT cs ON	cs.mrecommend = mcs.CustId AND cs.bettype = mcs.bettype AND cs.sporttype = mcs.sporttype
			WHERE CASE WHEN cs.Sporttype = 162 THEN cs.SyncLiveCasino ELSE 1 END = 1
				AND mcs.mpositiontaking < cs.mpositiontaking + cs.apositiontaking
		END
   
		----20. N3 > M1 + A1 
		IF @RuleId IN (0,20)
		BEGIN
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	20 as RuleId, cs.BetType, cs.SportType, mcs.CustId, cs.CustId, mcs.minpositiontaking, cs.mpositiontaking + cs.apositiontaking, 0
			FROM	#MasterPT mcs		
				INNER JOIN	#MemberPT cs ON	cs.mrecommend = mcs.CustId AND cs.bettype = mcs.bettype AND cs.sporttype = mcs.sporttype
			WHERE CASE WHEN cs.Sporttype = 162 THEN cs.SyncLiveCasino ELSE 1 END = 1
				AND mcs.minpositiontaking > cs.mpositiontaking + cs.apositiontaking
		END  
 
 		----23. A2 < N2
		IF @RuleId IN (0,23)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	23 as RuleId, cs.BetType, cs.SportType, cs.CustId, cs.CustId, cs.apositiontaking, cs.minpositiontaking, 0
			FROM	#AgentPT cs	
			WHERE CASE WHEN cs.Sporttype = 162 THEN cs.SyncLiveCasino ELSE 1 END = 1
				AND cs.apositiontaking < cs.minpositiontaking			
		END 
	  
		----24. N2 > A1
		IF @RuleId IN (0,24)
		BEGIN
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	24 as RuleId, cs.BetType, cs.SportType, acs.CustId, cs.CustId, acs.minpositiontaking, cs.apositiontaking, 0 
			FROM	#AgentPT acs		
			INNER JOIN	#MemberPT cs ON	cs.recommend = acs.CustId AND cs.bettype = acs.bettype AND cs.sporttype = acs.sporttype
			WHERE   CASE WHEN cs.Sporttype = 162 THEN cs.SyncLiveCasino ELSE 1 END = 1
				AND acs.minpositiontaking > cs.apositiontaking 			
		END
 		---------------------------------------------------
		----Note: Do not check rule 25, 26, 27 at CustSettingGame table
		---------------------------------------------------
		---- 28. MIN(S4-M1-A1, (IS1?US1,US3)) > S1
		IF @RuleId IN (0,28)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT 28 AS RuleId, cs.BetType, cs.SportType 
				,CASE	WHEN scs.spositiontaking - cs.mpositiontaking - cs.apositiontaking > (CASE WHEN cs.isautopositiontaking = 1 THEN cs.autopositiontaking	ELSE mcs.autopositiontaking END)			
						THEN (	CASE	WHEN cs.isautopositiontaking = 1 
										THEN cs.CustId 
										ELSE mcs.CustId 
								END)
						ELSE scs.CustId
				 END 
				,cs.CustId				
				,CASE	WHEN scs.spositiontaking - cs.mpositiontaking - cs.apositiontaking > (CASE WHEN cs.isautopositiontaking = 1 THEN cs.autopositiontaking	ELSE mcs.autopositiontaking END)			
						THEN (	CASE	WHEN cs.isautopositiontaking = 1 
										THEN cs.autopositiontaking 
										ELSE mcs.autopositiontaking 
								END)
						ELSE scs.spositiontaking - cs.mpositiontaking - cs.apositiontaking
				 END 
				,cs.spositiontaking
				,0
			FROM #MemberPT cs 		
			INNER JOIN	#MasterPT mcs ON	cs.mrecommend = mcs.CustId AND cs.bettype = mcs.bettype AND cs.sporttype = mcs.sporttype			
			INNER JOIN	#SuperPT scs ON	cs.srecommend = scs.CustId AND cs.bettype = scs.bettype AND cs.sporttype = scs.sporttype		
			WHERE CASE WHEN cs.Sporttype = 162 THEN cs.SyncLiveCasino ELSE 1 END = 1
				AND (cs.isautopositiontaking=1 OR mcs.isautopositiontaking=1)
				AND cs.spositiontaking < CASE	WHEN scs.spositiontaking - cs.mpositiontaking - cs.apositiontaking > (CASE WHEN cs.isautopositiontaking = 1 THEN cs.autopositiontaking	ELSE mcs.autopositiontaking END)			
												THEN (	CASE	WHEN cs.isautopositiontaking = 1 
																THEN cs.autopositiontaking 
																ELSE mcs.autopositiontaking 
														END)
												ELSE scs.spositiontaking - cs.mpositiontaking - cs.apositiontaking
										 END 		 
			END 

		----30. S4 > 0.93
			-->Live Casino, GoldDeluxe: Do not check Rule 2 Check rule 30 		
		IF @sporttype IN (0, 162, 255)
		BEGIN 
			IF @RuleId IN (0,30)
			BEGIN
				INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
				SELECT	30 as RuleId, cs.BetType, cs.SportType, cs.CustId, cs.CustId, cs.spositiontaking, 0.93, 0
				FROM #SuperPT cs
				WHERE ((cs.SportType = 162 AND cs.SyncLiveCasino = 1) OR cs.Sporttype = 255)					
					AND cs.spositiontaking > 0.93			
			END
		END

		---- 31. MIN (M3-A1,(IM1?UM1,UM2)) > M1
			---> Check Rule 31 instead of Rule 29 because it does not have M4, A4  [29. MIN (M4-A1, M3-A1,(IM1?UM1,UM2)) > M1]		 
		IF @RuleId IN (0,31)
		BEGIN 
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
			SELECT	31 AS RuleId, cs.BetType, cs.SportType,
					CASE WHEN mcs.mpositiontaking - cs.apositiontaking > (CASE WHEN cs.isautompositiontaking = 1 THEN cs.autompositiontaking ELSE acs.autompositiontaking END) 
								 THEN (CASE WHEN cs.isautompositiontaking = 1 
											THEN cs.CustId
											ELSE acs.CustId 
											END
									   )
					ELSE mcs.CustId
					END	
				,cs.CustId
				,CASE WHEN mcs.mpositiontaking - cs.apositiontaking > (CASE WHEN cs.isautompositiontaking = 1 THEN cs.autompositiontaking ELSE acs.autompositiontaking END) 
								 THEN (CASE WHEN cs.isautompositiontaking = 1 
											THEN cs.autompositiontaking
											ELSE acs.autompositiontaking 
									   END
									   )
					ELSE mcs.mpositiontaking - cs.apositiontaking
					END					
				,cs.mpositiontaking
				,0
			FROM #MemberPT cs 		
				INNER JOIN	#AgentPT acs ON	cs.recommend = acs.CustId AND cs.bettype = acs.bettype AND cs.sporttype = acs.sporttype
				INNER JOIN	#MasterPT mcs ON cs.mrecommend = mcs.CustId AND cs.bettype = mcs.bettype AND cs.sporttype = mcs.sporttype							
			WHERE CASE WHEN cs.Sporttype = 162 THEN cs.SyncLiveCasino ELSE 1 END = 1
				AND ( acs.isautompositiontaking = 1	OR cs.isautompositiontaking = 1 )
				AND cs.mpositiontaking <	CASE  WHEN mcs.mpositiontaking - cs.apositiontaking > (CASE WHEN cs.isautompositiontaking = 1 THEN cs.autompositiontaking ELSE acs.autompositiontaking END) 
													THEN (CASE WHEN cs.isautompositiontaking = 1 
															THEN cs.autompositiontaking
															ELSE acs.autompositiontaking 
														END
														)
													ELSE mcs.mpositiontaking - cs.apositiontaking
													END																							
	END 
		
		
		----32. S4 > 0.85
			--> Keno: Do not check Rule 2 Check rule 32 		
		IF @SportType IN (0,202)
		BEGIN 
			IF @RuleId IN (0,32)
			BEGIN
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)
				SELECT	32 as RuleId, cs.BetType, cs.SportType, cs.CustId, cs.CustId, cs.spositiontaking, 0.85, 0
				FROM	#SuperPT cs
				WHERE	cs.SportType = 202					
					AND cs.spositiontaking > 0.85
			END
		END

END
END