/*
Check VS
*/

	CREATE TABLE #CheckPTResult_Deposit(
		[RuleId] [smallint] NULL,
		[SportType] [smallint] NULL,
		[BetType] [smallint] NULL,
		[CustIdA] [int] NULL,
		[CustIdB] [int] NULL,
		[ValueA] [smallmoney] NULL,
		[ValueB] [smallmoney] NULL,
		[CreatedDate] [datetime] NULL,
		[IsLive] [bit] NULL
	)

	GO

	CREATE TABLE #supers (custid int)
	
	INSERT INTO #supers(custid)
	SELECT ci.custid
	FROM custInfo ci WITH (NOLOCK) 	
		INNER JOIN Dep_custsuper cs WITH (NOLOCK) ON ci.custid = cs.custid
	WHERE ci.username NOT LIKE '3rdSuper%'			
		AND ci.Enabled=1
		AND cs.site IN('12Bet','asiabet88','mansion88','alog','spondemo','TLC','SunGame','MayFair','Zzun88','HAIFA','Bodog','Vwin','Macaubet','Aoncash','ITCBet','Athena000','Avia','W88','9bet','3star88','OLE777',
		'88Macao','Boma365','Salon365','Ae88','Hengcai88','368Cash','Senibet','Happy1668','AG','M8bola','KeenOcean','9Club','XTD3','HONBET','Q8bola','BE7','iBET','ISC888','Liga','NBCbet','HonorW',
		'DEWA','IBO','Unobet','GamingSoft','Newhonbet','Hecbet','DBP','HL8','Abcasino','TGO','Starnet','365online','Bolanation','KhmerG','Gampag','IONclub','Sun988','Mayayule','HuangMa','Webet138','webet88',
		'BigGaming','Boying','Brown888','MrCat','CGame','PKbet','VCBA','Taipanbet','FLC','IGPTech','BetStar','TGame','Dawoo','Ty777','Uwoniwin','Sunrise','Swin','UN168','PanguGame','K8VN','ECLBET','GPIGAME','818Bet','SSSSEA',
		'Heaven','GOAB88','Bobo88','OPEBET','Jinyazhou','Sunriseb2b','Okada','396Club','Mybet88','e8casino','HongChow','TangChao','MAX88','BBIN2','YongBao','Fugui','GMASTER','ALPHA88','Citybk','Tripleone','GWORLD',
		'ENTAPLAY','MICL','zt828','Aplus','Arlocash','WBS','YBTech','Yibo','24TECH','Xinbo','BETSUN','HOT88','Monaco','Opadmin','Bonanza88','SSSGaming','JIBET','WINCLUB88','EU88','MARS','Dade','Nbbet',
		'Gameroom','ANGbet','Hongtu','Callmeboss','Hong88','BetDeal','SampleSite','VWIN66','A1game','HJTK','TitanOne','gbkj','skykey','Dachen','Bobbet','laba360','AEUG','XinYo','18Luck','Mbet','Kudatogel','WinWin',
		'HCVIP','ig128','AMG','MRCATSB','VN88')


	SELECT cs.CustID,ci.recommend,ci.mrecommend,ci.srecommend, cs.SportType,cs.BetType,cs.IsLive,cs.SuperPT,cs.MasterPT,cs.AgentPT,0 IsGroup
	INTO #MemberPT
	FROM dbo.CustInfo ci
		JOIN dbo.Dep_CustPTSetting_Member cs WITH (NOLOCK) ON ci.CustID = cs.CustID
		INNER JOIN dbo.Dep_CustProductStatus stt WITH (NOLOCK) ON ci.CustID = stt.CustID
		LEFT JOIN dbo.Dep_ProductStatusProfile prf WITH(NOLOCK) ON prf.Sporttype = cs.sporttype
	WHERE ci.srecommend IN (SELECT Custid FROM #supers)
			AND ci.roleid = 1  
			AND ci.Enabled = 1      
			AND ci.Currency NOT IN (20,27,28)     
			AND cs.SportType BETWEEN 180 AND 194
			
	
	INSERT INTO #MemberPT (CustID, recommend,mrecommend,srecommend,SportType,BetType,IsLive,SuperPT,MasterPT,AgentPT,IsGroup)
	SELECT ci.CustID,ci.recommend,ci.mrecommend,ci.srecommend, cs.SportType,cs.BetType,cs.IsLive,cs.SuperPT,cs.MasterPT,cs.AgentPT,1
	FROM dbo.CustInfo ci
		INNER JOIN dbo.Dep_CustSettingMode csm WITH (NOLOCK) ON ci.custid = csm.CustID AND csm.IsGroupedPT = 1
		INNER JOIN dbo.Dep_CustPTGroupSetting_Member cs WITH (NOLOCK) ON cs.AgentID = ci.recommend  
		INNER JOIN dbo.Dep_CustProductStatus stt WITH (NOLOCK) ON ci.CustID = stt.CustID
		LEFT JOIN dbo.Dep_ProductStatusProfile prf WITH(NOLOCK) ON prf.Sporttype = cs.sporttype
	WHERE ci.srecommend IN (SELECT Custid FROM #supers)
			AND ci.roleid = 1  
			AND ci.Enabled = 1      
			AND ci.Currency NOT IN (20,27,28)     
			AND cs.SportType BETWEEN 180 AND 194
			
			
	SELECT cs.CustID,ci.recommend,ci.mrecommend,ci.srecommend, cs.SportType,cs.BetType,cs.IsLive,cs.SuperPT,cs.MasterPT,cs.AgentPT
	INTO #AgentPT
	FROM dbo.CustInfo ci
		JOIN dbo.Dep_CustPTSetting_Agent cs WITH (NOLOCK) ON ci.CustID = cs.CustID
		INNER JOIN dbo.Dep_CustProductStatus stt WITH (NOLOCK) ON ci.CustID = stt.CustID
		LEFT JOIN dbo.Dep_ProductStatusProfile prf WITH(NOLOCK) ON prf.Sporttype = cs.sporttype
	WHERE ci.srecommend IN (SELECT Custid FROM #supers)
			AND ci.roleid = 2  
			AND ci.Enabled = 1      
			AND ci.Currency NOT IN (20,27,28)     
			AND cs.SportType BETWEEN 180 AND 194
			
			
	SELECT cs.CustID,ci.recommend,ci.mrecommend,ci.srecommend, cs.SportType,cs.BetType,cs.IsLive,cs.SuperPT,cs.MasterPT,cs.AgentPT
	INTO #MasterPT
	FROM dbo.CustInfo ci
		JOIN dbo.Dep_CustPTSetting_Agent cs WITH (NOLOCK) ON ci.CustID = cs.CustID
		INNER JOIN dbo.Dep_CustProductStatus stt WITH (NOLOCK) ON ci.CustID = stt.CustID
		LEFT JOIN dbo.Dep_ProductStatusProfile prf WITH(NOLOCK) ON prf.Sporttype = cs.sporttype
	WHERE ci.srecommend IN (SELECT Custid FROM #supers)
			AND ci.roleid = 3  
			AND ci.Enabled = 1      
			AND ci.Currency NOT IN (20,27,28)     
			AND cs.SportType BETWEEN 180 AND 194
			
	
	SELECT cs.CustID, cs.SportType,cs.BetType,cs.IsLive,cs.SuperPT,cs.MasterPT,cs.AgentPT
	INTO #SuperPT
	FROM dbo.CustInfo ci
		JOIN dbo.Dep_CustPTSetting_Agent cs WITH (NOLOCK) ON ci.CustID = cs.CustID
		INNER JOIN dbo.Dep_CustProductStatus stt WITH (NOLOCK) ON ci.CustID = stt.CustID
		LEFT JOIN dbo.Dep_ProductStatusProfile prf WITH(NOLOCK) ON prf.Sporttype = cs.sporttype
	WHERE ci.srecommend IN (SELECT Custid FROM #supers)
			AND ci.roleid = 4  
			AND ci.Enabled = 1      
			AND ci.Currency NOT IN (20,27,28)     
			AND cs.SportType BETWEEN 180 AND 194
					
	-- End of DATA PREPARATION				
	DECLARE @RuleId SMALLINT = 0
	-- Starting check PT Rule
	---- 1. S1 < 0 OR M1 < 0 OR A1 < 0  
	IF @RuleId IN (0,1)  
	BEGIN  
		----PRINT '1. S1 < 0 OR M1 < 0 OR A1 < 0 '  
		INSERT INTO #CheckPTResult_Deposit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)   
		SELECT 1 AS RuleId, cs.BetType, cs.SportType, cs.CustId, cs.CustId,  
			 CASE 
				WHEN cs.SuperPT < 0 THEN cs.SuperPT
				WHEN cs.MasterPT < 0 THEN cs.MasterPT
				WHEN cs.AgentPT < 0 THEN cs.AgentPT
				ELSE 0  
			 END,  
			 0,   
			 cs.Islive  
		FROM #MemberPT cs 
		WHERE cs.SuperPT < 0 OR cs.MasterPT < 0 OR cs.AgentPT < 0
		
	END  

	----2. S4 > 90 OR M4 > 90 OR A4 > 90  
	IF @RuleId IN (0,2)  
	BEGIN  
		----PRINT '2. S4 > 90 OR M4 > 90 OR A4 > 90 '
		INSERT INTO #CheckPTResult_Deposit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		SELECT 2 AS RuleId, cs.BetType, cs.SportType, cs.CustId, cs.CustId,  
			 CASE 
				WHEN cs.SuperPT > 90 THEN cs.SuperPT
				WHEN cs.MasterPT > 90 THEN cs.MasterPT
				WHEN cs.AgentPT > 90 THEN cs.AgentPT   
				ELSE 90   
			 END,  
			 90,  
			 cs.Islive
		FROM #SuperPT cs 
		WHERE cs.SuperPT > 90 OR cs.MasterPT > 90 OR cs.AgentPT > 90
		
	END  

	----3. S4 < M4   

	IF @RuleId IN (0,3)  
	BEGIN   
		----PRINT '3. S4 < M4 '
		INSERT INTO #CheckPTResult_Deposit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		SELECT 3 as RuleId, cs.BetType, cs.SportType, cs.CustId, cs.CustId
			, cs.SuperPT
			, cs.MasterPT
			, cs.IsLive  
		FROM #SuperPT cs 
		WHERE cs.SuperPT < cs.MasterPT

	END  

	----4. S4 < A4  

	IF @RuleId IN (0,4)  
	BEGIN  
		----PRINT '4. S4 < A4 '
		INSERT INTO #CheckPTResult_Deposit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		SELECT 4 as RuleId, cs.BetType, cs.SportType, cs.CustId, cs.CustId, cs.SuperPT, cs.AgentPT, cs.IsLive  
		FROM #SuperPT cs
		WHERE cs.SuperPT < cs.AgentPT
	END  	

	----8. S4 < S3 + M3   

	IF @RuleId IN (0,8)  
	BEGIN   
		----PRINT '8. S4 < S3 + M3   '
		INSERT INTO #CheckPTResult_Deposit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		SELECT 8 as RuleId, cs.BetType, cs.SportType, scs.CustId, cs.CustId, scs.SuperPT, cs.SuperPT + cs.MasterPT, scs.IsLive  
		FROM #MasterPT cs
			INNER JOIN #SuperPT scs ON scs.CustID = cs.srecommend AND scs.SportType = cs.SportType	AND scs.BetType = cs.BetType AND scs.IsLive = cs.IsLive 
		WHERE scs.SuperPT < cs.SuperPT + cs.MasterPT
		
	END  

	----9. S4 < S1 + M1 + A1   

	IF @RuleId IN (0,9)  
	BEGIN   
		----PRINT '9. S4 < S1 + M1 + A1   '
		INSERT INTO #CheckPTResult_Deposit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		SELECT 9 as RuleId, cs.BetType, cs.SportType, scs.CustId, cs.CustId, scs.SuperPT, cs.SuperPT + cs.MasterPT + cs.AgentPT, scs.IsLive  
		FROM #MemberPT cs
			INNER JOIN #SuperPT scs ON scs.CustID = cs.srecommend AND  scs.SportType = cs.SportType AND scs.BetType = cs.BetType AND scs.IsLive = cs.IsLive 
		WHERE scs.SuperPT < cs.SuperPT + cs.MasterPT + cs.AgentPT

	END  

	-----------------------------------------------------------------------  
	----11. M4 < A4  

	IF @RuleId IN (0,11)  
	BEGIN   
		----PRINT '11. M4 < A4  '
		INSERT INTO #CheckPTResult_Deposit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		SELECT 11 as RuleId, cs.BetType, cs.SportType, cs.CustId, cs.CustId, cs.MasterPT, cs.AgentPT, cs.IsLive  
		FROM #SuperPT cs 
		WHERE cs.MasterPT < cs.AgentPT
		
	END  
	----12. M4 < M3   
	IF @RuleId IN (0,12)  
	BEGIN  
		----PRINT '12. M4 < M3'
		INSERT INTO #CheckPTResult_Deposit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		SELECT 12 as RuleId, cs.BetType, cs.SportType, scs.CustId, cs.CustId, scs.MasterPT, cs.MasterPT, scs.IsLive  
		FROM #MasterPT cs
			INNER JOIN #SuperPT scs ON scs.CustID = cs.srecommend AND scs.SportType = cs.SportType AND scs.BetType = cs.BetType AND scs.IsLive = cs.IsLive   
		WHERE scs.MasterPT < cs.MasterPT
		 
	END  

	----16. M4 < M1 + A1   
	
	IF @RuleId IN (0,16)  
	BEGIN  
		----PRINT '16. M4 < M1 + A1 '
		INSERT INTO #CheckPTResult_Deposit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		SELECT 16 as RuleId, cs.BetType, cs.SportType, scs.CustId, cs.CustId, scs.MasterPT , cs.MasterPT + cs.AgentPT, scs.IsLive  
		FROM #MemberPT cs
			INNER JOIN #SuperPT scs ON scs.CustID = cs.srecommend AND  scs.SportType = cs.SportType AND scs.BetType = cs.BetType AND scs.IsLive = cs.IsLive  
		WHERE scs.MasterPT < cs.MasterPT + cs.AgentPT
	END  

	--------------------------------------------------------------------------------------------  
	----18. M3 < M2 + A2   

	IF @RuleId IN (0,18)  
	BEGIN   
		----PRINT '18. M3 < M2 + A2   '
		
		INSERT INTO #CheckPTResult_Deposit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		SELECT 18 as RuleId, cs.BetType, cs.SportType, scs.CustId, cs.CustId, scs.MasterPT, cs.MasterPT + cs.AgentPT, cs.IsLive  
		FROM #AgentPT cs
			INNER JOIN #MasterPT scs ON cs.mrecommend = scs.Custid AND scs.SportType = cs.SportType AND scs.BetType = cs.BetType AND scs.IsLive = cs.IsLive  
		WHERE scs.MasterPT < cs.MasterPT + cs.AgentPT
		
	END  

	----19. M3 < M1 + A1   

	IF @RuleId IN (0,19)  
	BEGIN   
		----PRINT '19. M3 < M1 + A1   '
		INSERT INTO #CheckPTResult_Deposit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		SELECT 19 as RuleId, cs.BetType, cs.SportType, scs.CustId, cs.CustId, scs.MasterPT, cs.MasterPT + cs.AgentPT, cs.IsLive  
		FROM #MemberPT cs
			INNER JOIN #MasterPT scs ON scs.CustID = cs.mrecommend AND scs.SportType = cs.SportType AND scs.BetType = cs.BetType AND scs.IsLive = cs.IsLive  
		WHERE scs.MasterPT < cs.MasterPT + cs.AgentPT
		
	END  


	----21. A4 < A2  

	IF @RuleId IN (0,21)  
	BEGIN   
		----PRINT '21. A4 < A2  '
		INSERT INTO #CheckPTResult_Deposit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLIve)  
		SELECT 21 as RuleId, cs.BetType, cs.SportType, scs.CustId, cs.CustId, scs.AgentPT, cs.AgentPT, scs.IsLive  
		FROM #AgentPT cs
			INNER JOIN #SuperPT scs ON scs.CustID = cs.srecommend AND scs.SportType = cs.SportType AND scs.BetType = cs.BetType AND scs.IsLive = cs.IsLive  
		WHERE scs.AgentPT < cs.AgentPT
		  
	END   


	----22. A4 < A1  

	IF @RuleId IN (0,22)  
	BEGIN  
		----PRINT '22. A4 < A1  '
		INSERT INTO #CheckPTResult_Deposit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		SELECT 22 as RuleId, cs.BetType, cs.SportType, scs.CustId, cs.CustId, scs.AgentPT, cs.AgentPT, scs.IsLive  
		FROM #MemberPT cs
			INNER JOIN #SuperPT scs ON scs.CustID = cs.srecommend AND scs.SportType = cs.SportType AND scs.BetType = cs.BetType AND scs.IsLive = cs.IsLive  
		WHERE scs.AgentPT < cs.AgentPT
			
	END   

	---- 30. PT setting of member exists in both Individual and group PT   
	IF @RuleId IN (0,30)  
	BEGIN   
		 ----PRINT ' 30. PT setting of member exists in both Individual and group PT'
		 INSERT INTO #CheckPTResult_Deposit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		 SELECT DISTINCT 30,NULL,NULL,M.CustID,M.CustID,NULL,NULL,NULL
		 FROM #MemberPT M
		 WHERE EXISTS (SELECT 1 FROM dbo.Dep_CustPTSetting_Member M1 WITH (NOLOCK) WHERE M1.CustID = M.CustID)
			   AND EXISTS (SELECT 1 FROM dbo.Dep_CustSettingMode csm WITH (NOLOCK) WHERE csm.CustID = M.CustID AND csm.IsGroupedPT = 1)	
	END	
	
	---- 31. IsGrouped Flag = 0 but not exists in Individual PT table
	IF @RuleId IN (0,31)  
	BEGIN   
		 ----PRINT '31. IsGrouped Flag = 0 but not exists in Individual PT table'
		 INSERT INTO #CheckPTResult_Deposit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		 SELECT DISTINCT 31,NULL,NULL,M.CustID,M.CustID,NULL,NULL,NULL
		 FROM #MemberPT M
		 WHERE EXISTS (SELECT 1 FROM dbo.Dep_CustSettingMode csm WITH (NOLOCK) WHERE csm.CustID = M.CustID AND csm.IsGroupedPT = 0)	
			   AND NOT EXISTS (SELECT 1 FROM dbo.Dep_CustPTSetting_Member M1 WITH (NOLOCK) WHERE M1.CustID = M.CustID)
			   
	END	 
	
	---- 32. IsGrouped Flag = 1 but not exists in Group PT table
	IF @RuleId IN (0,32)  
	BEGIN   
		 ----PRINT '32. IsGrouped Flag = 1 but not exists in Group PT table'
		 INSERT INTO #CheckPTResult_Deposit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		 SELECT DISTINCT 32,NULL,NULL,M.CustID,M.CustID,NULL,NULL,NULL
		 FROM #MemberPT M
		 WHERE EXISTS (SELECT 1 FROM dbo.Dep_CustSettingMode csm WITH (NOLOCK) WHERE csm.CustID = M.CustID AND csm.IsGroupedPT = 1)	
				AND NOT EXISTS (SELECT 1 FROM dbo.Dep_CustPTGroupSetting_Member M1 WITH (NOLOCK) WHERE M1.AgentID = M.recommend)
			   
	END	   
	

SELECT ca.username AS UsernameA, ca.roleid AS roleidA, cb.username AS UsernameB, cb.roleid AS roleidB, cs.* 
FROM #CheckPTResult_Deposit cs
	INNER JOIN CustInfo ca WITH (NOLOCK) ON cs.custidA = ca.custid
	INNER JOIN CustInfo cb WITH (NOLOCK) ON cs.custidB = cb.custid	
--WHERE ruleid BETWEEN 1 AND 29
ORDER BY ruleid	

DROP TABLE #CheckPTResult_Deposit
DROP TABLE #supers
DROP TABLE #AgentPT
DROP TABLE #MasterPT
DROP TABLE #MemberPT
DROP TABLE #SuperPT