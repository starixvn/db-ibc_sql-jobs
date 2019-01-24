
/*
	Created: 20180827@Winnie.Vu
	Task :   Check PT rules (Deposit)
	DB: DB052.CheckResultDB
	Original:

	Revisions:
		-20180827@Winnie.Vu: Create SP
	Param's Explanation:
	
*/
SET NOCOUNT ON
BEGIN
	DECLARE @site VARCHAR(20)
	CREATE TABLE #Dummy (CustID INT PRIMARY KEY)
	CREATE TABLE #Trade (CustID INT PRIMARY KEY)	
	CREATE TABLE #tmpProfile(Sporttype INT,Bettype INT,IsLive BIT)
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

	DECLARE @RuleID INT=0
	CREATE TABLE #supersNG (custid int PRIMARY KEY)
	CREATE TABLE #supersALL (custid int PRIMARY KEY)
	
	INSERT INTO #supersNG(custid)
	
	SELECT DISTINCT ci.custid
	FROM custInfo ci WITH (NOLOCK) 	
		INNER JOIN Dep_custsuper cs WITH (NOLOCK) ON ci.custid = cs.custid
	WHERE ci.username NOT LIKE '3rdSuper%'			
		AND ci.Enabled=1
		AND cs.site IN('12Bet','asiabet88','mansion88','alog','spondemo','TLC','SunGame','MayFair','Zzun88','Bodog','Vwin','Macaubet','Aoncash','ITCBet','Athena000','Avia','W88','9bet','3star88','OLE777',
		'88Macao','Boma365','Salon365','Ae88','Hengcai88','368Cash','Senibet','Happy1668','AG','M8bola','9Club','XTD3','HONBET','Q8bola','BE7','iBET','ISC888','Liga','NBCbet','HonorW','Royal',
		'DEWA','IBO','Unobet','GamingSoft','Newhonbet','Hecbet','DBP','HL8','Abcasino','TGO','Starnet','365online','Bolanation','KhmerG','Gampag','IONclub','Sun988','Mayayule','HuangMa','Webet138','webet88',
		'BigGaming','Boying','Brown888','MrCat','CGame','PKbet','VCBA','Taipanbet','FLC','IGPTech','BetStar','TGame','Dawoo','Ty777','Uwoniwin','Sunrise','Swin','UN168','PanguGame','K8VN','ECLBET','GPIGAME','818Bet','SSSSEA',
		'Heaven','GOAB88','Bobo88','OPEBET','Jinyazhou','Sunriseb2b','Okada','396Club','Mybet88','e8casino','HongChow','TangChao','MAX88','YongBao','Fugui','GMASTER','ALPHA88','Citybk','Tripleone','GWORLD',
		'ENTAPLAY','MICL','zt828','Aplus','Arlocash','WBS','YBTech','Yibo','24TECH','Xinbo','BETSUN','HOT88','Monaco','Opadmin','Bonanza88','SSSGaming','JIBET','WINCLUB88','EU88','MARS','Dade','Nbbet',
		'Gameroom','ANGbet','Hongtu','Callmeboss','Hong88','BetDeal','SampleSite','VWIN66','A1game','HJTK','TitanOne','gbkj','skykey','Dachen','Bobbet','laba360','AEUG','XinYo','18Luck','Mbet','Kudatogel','WinWin',
		'HCVIP','ig128','AMG','MRCATSB','VN88')


	CREATE TABLE #supersVS (custid int PRIMARY KEY)
	
	INSERT INTO #supersVS(custid)
	SELECT DISTINCT ci.custid
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


	INSERT INTO #tmpProfile(Sporttype ,Bettype ,IsLive )
	SELECT Sporttype ,Bettype ,IsLive
	FROM Dep_ProductSetting ps WITH(NOLOCK)
		INNER JOIN Dep_ProductSettingDetail psd WITH(NOLOCK) ON ps.ProductSettingID=psd.ProductSettingID
		INNER JOIN Dep_LicenseeProductSetting l WITH(NOLOCK) ON l.ProductSettingID=psd.ProductSettingID
		INNER JOIN #supersVS s ON l.custid=s.custid
	WHERE  ps.SettingType=1 AND psd.SettingStatus=0


	INSERT INTO #supersALL(custid)
	SELECT Custid 
	FROM #supersNG
	UNION 
	SELECT Custid 
	FROM #supersVS

	INSERT INTO #Dummy(CustID)
	SELECT c.CustID 
	FROM Customer c WITH(NOLOCK) 
		INNER JOIN #supersALL s ON c.srecommend=s.custid
	WHERE roleid=3 AND (username LIKE '%Acc%' OR username LIKE '%Cas%' OR username LIKE '%LocalBank%')

	INSERT INTO #Trade(CustID)
	SELECT c.CustID 
	FROM Customer c WITH(NOLOCK) 
		INNER JOIN #supersALL s ON c.srecommend=s.custid
	WHERE roleid=1 AND (username LIKE '%Bettrade%' OR username LIKE '%CashOut%' OR username LIKE '%TransferUUS%')

	IF @RuleId IN (0,43)  
	BEGIN  
	
		INSERT INTO #CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 43,s.sporttype,s.bettype,c.custid,NULL,s.spositiontaking,NULL,GETDATE(),s.islive 
		FROM Dep_CustSetting3rd s WITH(NOLOCK)
			INNER JOIN Customer c WITH(NOLOCK) ON s.custid=c.custid
			INNER JOIN #supersNG su ON c.srecommend=su.custid
		WHERE c.roleid=1 AND s.spositiontaking<0 AND s.sporttype=161

		INSERT INTO #CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 43,s.sporttype,s.bettype,c.custid,NULL,s.mpositiontaking ,NULL,GETDATE(),s.islive 
		FROM Dep_CustSetting3rd s WITH(NOLOCK)
			INNER JOIN Customer c WITH(NOLOCK) ON s.custid=c.custid
			INNER JOIN #supersNG su ON c.srecommend=su.custid
		WHERE  c.roleid=1 AND s.mpositiontaking<0 AND s.sporttype=161

		INSERT INTO #CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 43,s.sporttype,s.bettype,c.custid,NULL,s.apositiontaking,NULL,GETDATE(),s.islive 
		FROM Dep_CustSetting3rd s WITH(NOLOCK)
			INNER JOIN Customer c WITH(NOLOCK) ON s.custid=c.custid
			INNER JOIN #supersNG su ON c.srecommend=su.custid
		WHERE c.roleid=1 AND s.apositiontaking<0 AND s.sporttype=161
		

		INSERT INTO #CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 43,s.sporttype,s.bettype,c.custid,NULL,s.SuperPT,NULL,GETDATE(),s.islive 
		FROM Dep_CustPTSetting_Member s WITH(NOLOCK)
			INNER JOIN Customer c WITH(NOLOCK) ON s.custid=c.custid
			INNER JOIN Dep_CustSettingMode d WITH(NOLOCK) ON c.custid=d.CustID
			INNER JOIN #supersVS su ON c.srecommend=su.custid
		WHERE  d.IsGroupedPT=0 AND c.roleid=1 AND s.SuperPT<0 AND s.SportType BETWEEN 180 AND 194

		INSERT INTO #CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 43,s.sporttype,s.bettype,c.custid,NULL,s.MasterPT ,NULL,GETDATE(),s.islive 
		FROM Dep_CustPTSetting_Member s WITH(NOLOCK)
			INNER JOIN Customer c WITH(NOLOCK) ON s.custid=c.custid
			INNER JOIN Dep_CustSettingMode d WITH(NOLOCK) ON c.custid=d.CustID
			INNER JOIN #supersVS su ON c.srecommend=su.custid
		WHERE  d.IsGroupedPT=0 AND c.roleid=1 AND s.MasterPT<0 AND s.SportType BETWEEN 180 AND 194

		INSERT INTO #CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 43,s.sporttype,s.bettype,c.custid,NULL,s.AgentPT ,NULL,GETDATE(),s.islive 
		FROM Dep_CustPTSetting_Member s WITH(NOLOCK)
			INNER JOIN Customer c WITH(NOLOCK) ON s.custid=c.custid
			INNER JOIN Dep_CustSettingMode d WITH(NOLOCK) ON c.custid=d.CustID
			INNER JOIN #supersVS su ON c.srecommend=su.custid
		WHERE d.IsGroupedPT=0 AND c.roleid=1 AND s.AgentPT<0 AND s.SportType BETWEEN 180 AND 194

		INSERT INTO #CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 43,s.sporttype,s.bettype,c.custid,NULL,s.SuperPT ,NULL,GETDATE(),s.islive 
		FROM Dep_CustPTGroupSetting_Member s WITH(NOLOCK)
			INNER JOIN Customer c WITH(NOLOCK) ON s.AgentID=c.custid
			INNER JOIN #supersVS su ON c.srecommend=su.custid 
		WHERE c.roleid=2 AND s.SuperPT<0 AND s.SportType BETWEEN 180 AND 194

		INSERT INTO #CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 43,s.sporttype,s.bettype,c.custid,NULL,s.MasterPT ,NULL,GETDATE(),s.islive 
		FROM Dep_CustPTGroupSetting_Member s WITH(NOLOCK)
			INNER JOIN Customer c WITH(NOLOCK) ON s.AgentID=c.custid
			INNER JOIN #supersVS su ON c.srecommend=su.custid
		WHERE c.roleid=2 AND s.MasterPT<0

		INSERT INTO #CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 43,s.sporttype,s.bettype,c.custid,NULL,s.AgentPT ,NULL,GETDATE(),s.islive 
		FROM Dep_CustPTGroupSetting_Member s WITH(NOLOCK)
			INNER JOIN Customer c WITH(NOLOCK) ON s.AgentID=c.custid
			INNER JOIN #supersVS su ON c.srecommend=su.custid
		WHERE c.roleid=2 AND s.AgentPT<0 AND s.SportType BETWEEN 180 AND 194

	END
	IF @RuleId IN (0,44)  
	BEGIN
		CREATE TABLE #tmpS(srecommend INT,Sporttype INT, Bettype INT, Islive BIT, PT SMALLMONEY,PRIMARY KEY(srecommend,Sporttype,Bettype,Islive))
		CREATE TABLE #tmpM(srecommend INT,CustID INT,Sporttype INT, Bettype INT, Islive BIT, PT SMALLMONEY,PRIMARY KEY(CustID,Sporttype,Bettype,Islive,srecommend))

		INSERT INTO #tmpS (srecommend,Sporttype , Bettype , Islive , PT)
		SELECT s.custid, s.sporttype,s.bettype,s.islive,s.spositiontaking
		FROM Dep_CustSetting3rd s WITH(NOLOCK)	
			INNER JOIN #supersNG su ON s.custid=su.custid
		WHERE s.sporttype=161		

		INSERT INTO #tmpM (srecommend,CustID,Sporttype , Bettype , Islive , PT)
		SELECT c.srecommend, c.custid, s.sporttype,s.bettype,s.islive,s.mpositiontaking
		FROM Dep_CustSetting3rd s WITH(NOLOCK)		
			INNER JOIN Customer c WITH(NOLOCK) ON s.custid=c.custid	
			INNER JOIN #supersNG su ON c.srecommend=su.custid
		WHERE  c.roleid=3 AND c.custid NOT IN(SELECT custid FROM #Dummy)
			AND s.sporttype=161	

		INSERT INTO #CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 44,s.sporttype,s.bettype,s.srecommend,m.CustID,s.PT ,m.PT,GETDATE(),s.islive 
		FROM #tmpS s 
			INNER JOIN #tmpM m ON s.Sporttype=m.Sporttype AND s.Bettype=m.Bettype AND s.Islive=m.Islive AND s.srecommend=m.srecommend
		WHERE s.PT<>m.PT

		TRUNCATE TABLE #tmpS
		TRUNCATE TABLE #tmpM		
		
		INSERT INTO #tmpS (srecommend,Sporttype , Bettype , Islive , PT)
		SELECT s.CustID, s.sporttype,s.bettype,IsLive,s.SuperPT
		FROM Dep_CustPTSetting_Agent s WITH(NOLOCK)	
			INNER JOIN #supersVS su ON s.CustID=su.custid		
		WHERE s.SportType BETWEEN 180 AND 194
		
		INSERT INTO #tmpM (srecommend,CustID,Sporttype , Bettype , Islive , PT)
		SELECT c.srecommend, c.custid, s.sporttype,s.bettype,IsLive,s.MasterPT
		FROM Dep_CustPTSetting_Agent s WITH(NOLOCK)		
			INNER JOIN Customer c WITH(NOLOCK) ON s.custid=c.custid	
			INNER JOIN #supersVS su ON c.srecommend=su.custid		
		WHERE c.roleid=3 AND c.custid NOT IN(SELECT custid FROM #Dummy)
			AND s.SportType BETWEEN 180 AND 194


		INSERT INTO #CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 44,s.sporttype,s.bettype,s.srecommend,m.CustID,s.PT ,m.PT,GETDATE(),s.islive 
		FROM #tmpS s 
			INNER JOIN #tmpM m ON s.Sporttype=m.Sporttype AND s.Bettype=m.Bettype AND s.Islive=m.Islive AND s.srecommend=m.srecommend
		WHERE s.PT<>m.PT
	END
	IF @RuleId IN (0,45)  
	BEGIN
		CREATE TABLE #tmpM45(CustID INT,Sporttype INT, Bettype INT, Islive BIT, PT SMALLMONEY,PRIMARY KEY(CustID,Sporttype,Bettype,Islive))
		CREATE TABLE #tmpA45(CustID INT,Sporttype INT, Bettype INT, Islive BIT,mrecommend INT, PT SMALLMONEY,PRIMARY KEY(CustID,Sporttype,Bettype,Islive,mrecommend))	
		
		INSERT INTO #tmpM45 (CustID, Sporttype , Bettype , Islive , PT)
		SELECT s.custid, s.sporttype,s.bettype,s.islive,s.mpositiontaking
		FROM Dep_CustSetting3rd s WITH(NOLOCK)	
			INNER JOIN Customer c WITH(NOLOCK) ON s.custid=c.custid		
			INNER JOIN #supersNG su ON c.srecommend=su.custid
		WHERE  c.roleid=3 AND c.custid NOT IN(SELECT custid FROM #Dummy) AND s.sporttype=161
		
		INSERT INTO #tmpA45 (CustID,Sporttype , Bettype , Islive , PT,mrecommend)
		SELECT c.custid, s.sporttype,s.bettype,s.islive,s.apositiontaking,c.mrecommend
		FROM Dep_CustSetting3rd s WITH(NOLOCK)		
			INNER JOIN Customer c WITH(NOLOCK) ON s.custid=c.custid	
			INNER JOIN #supersNG su ON c.srecommend=su.custid
		WHERE  c.roleid=2 AND s.sporttype=161

		INSERT INTO #CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 45,s.sporttype,s.bettype,s.CustID,m.CustID,s.PT ,m.PT,GETDATE(),s.islive 
		FROM #tmpM45 s 
			INNER JOIN #tmpA45 m ON s.Sporttype=m.Sporttype AND s.Bettype=m.Bettype AND s.Islive=m.Islive AND s.CustID=m.mrecommend
		WHERE s.PT<>m.PT

		TRUNCATE TABLE #tmpM45
		TRUNCATE TABLE #tmpA45		

		INSERT INTO #tmpM45 (CustID, Sporttype , Bettype , Islive , PT)
		SELECT s.custid, s.sporttype,s.bettype,IsLive,s.MasterPT
		FROM Dep_CustPTSetting_Agent s WITH(NOLOCK)	
			INNER JOIN Customer c WITH(NOLOCK) ON s.custid=c.custid	
			INNER JOIN #supersVS su ON c.srecommend=su.custid	
		WHERE c.roleid=3 AND c.custid NOT IN(SELECT custid FROM #Dummy) AND  s.SportType BETWEEN 180 AND 194
		
		INSERT INTO #tmpA45 (CustID,Sporttype , Bettype , Islive , PT,mrecommend)
		SELECT c.custid, s.sporttype,s.bettype,IsLive,s.AgentPT,c.mrecommend
		FROM Dep_CustPTSetting_Agent s WITH(NOLOCK)		
			INNER JOIN Customer c WITH(NOLOCK) ON s.custid=c.custid	
			INNER JOIN #supersVS su ON c.srecommend=su.custid	
		WHERE  c.roleid=2 AND  s.SportType BETWEEN 180 AND 194

		INSERT INTO #CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 45,s.sporttype,s.bettype,s.CustID,m.CustID,s.PT ,m.PT,GETDATE(),s.islive 
		FROM #tmpM45 s 
			INNER JOIN #tmpA45 m ON s.Sporttype=m.Sporttype AND s.Bettype=m.Bettype AND s.Islive=m.Islive AND s.CustID=m.mrecommend
		WHERE s.PT<>m.PT

	END
	IF @RuleId IN (0,46)  
	BEGIN		
		CREATE TABLE #tmpA1(CustID INT,Sporttype INT, Bettype INT, Islive BIT,recommend INT, PT SMALLMONEY,PRIMARY KEY(CustID,Sporttype,Bettype,Islive,recommend))
		CREATE TABLE #tmpA2(CustID INT,Sporttype INT, Bettype INT, Islive BIT, PT SMALLMONEY,PRIMARY KEY(CustID,Sporttype,Bettype,Islive))	
		
		INSERT INTO #tmpA2 (CustID, Sporttype , Bettype , Islive , PT)
		SELECT s.custid, s.sporttype,s.bettype,s.islive,s.apositiontaking
		FROM Dep_CustSetting3rd s WITH(NOLOCK)	
			INNER JOIN Customer c WITH(NOLOCK) ON s.custid=c.custid		
			INNER JOIN #supersNG su ON c.srecommend=su.custid	
		WHERE c.roleid=2 AND c.mrecommend NOT IN (SELECT custid FROM #Dummy) AND s.sporttype=161
		
		INSERT INTO #tmpA1 (CustID,Sporttype , Bettype , Islive , PT,recommend)
		SELECT c.custid, s.sporttype,s.bettype,s.islive,s.apositiontaking,c.recommend
		FROM Dep_CustSetting3rd s WITH(NOLOCK)		
			INNER JOIN Customer c WITH(NOLOCK) ON s.custid=c.custid	
			INNER JOIN #supersNG su ON c.srecommend=su.custid	
		WHERE c.roleid=1 AND c.custid NOT IN(SELECT custid FROM #Trade) AND s.sporttype=161

		INSERT INTO #CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 46,s.sporttype,s.bettype,s.CustID,m.CustID,s.PT ,m.PT,GETDATE(),s.islive 
		FROM #tmpA1 s 
			INNER JOIN #tmpA2 m ON s.Sporttype=m.Sporttype AND s.Bettype=m.Bettype AND s.Islive=m.Islive AND s.CustID=s.recommend
		WHERE s.PT<>m.PT

		TRUNCATE TABLE #tmpA1
		TRUNCATE TABLE #tmpA2		

		INSERT INTO #tmpA2 (CustID, Sporttype , Bettype , Islive , PT)
		SELECT s.custid, s.sporttype,s.bettype,IsLive,s.AgentPT
		FROM Dep_CustPTSetting_Agent s WITH(NOLOCK)	
			INNER JOIN Customer c WITH(NOLOCK) ON s.custid=c.custid		
			INNER JOIN #supersVS su ON c.srecommend=su.custid	
		WHERE  c.roleid=2 AND c.mrecommend NOT IN (SELECT custid FROM #Dummy) AND  s.SportType BETWEEN 180 AND 194

		INSERT INTO #tmpA1 (CustID,Sporttype , Bettype , Islive , PT,recommend)
		SELECT c.custid, s.sporttype,s.bettype,IsLive,s.AgentPT,c.recommend
		FROM Dep_CustPTSetting_Member s WITH(NOLOCK)		
			INNER JOIN Customer c WITH(NOLOCK) ON s.custid=c.custid	
			INNER JOIN Dep_CustSettingMode d WITH(NOLOCK) ON c.custid=d.CustID
			INNER JOIN #supersVS su ON c.srecommend=su.custid	
		WHERE c.roleid=1 AND d.IsGroupedPT=0 AND c.custid NOT IN(SELECT custid FROM #Trade) AND  s.SportType BETWEEN 180 AND 194

		INSERT INTO #tmpA1 (CustID,Sporttype , Bettype , Islive , PT,recommend)
		SELECT c.custid, s.sporttype,s.bettype,IsLive,s.AgentPT,c.recommend
		FROM Dep_CustPTGroupSetting_Member s WITH(NOLOCK)		
			INNER JOIN Customer c WITH(NOLOCK) ON s.AgentID=c.custid	
			INNER JOIN #supersVS su ON c.srecommend=su.custid	
		WHERE c.roleid=2 AND c.mrecommend NOT IN (SELECT custid FROM #Dummy) AND  s.SportType BETWEEN 180 AND 194

		INSERT INTO #CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 46,s.sporttype,s.bettype,s.CustID,m.CustID,s.PT ,m.PT,GETDATE(),s.islive 
		FROM #tmpA1 s 
			INNER JOIN #tmpA2 m ON s.Sporttype=m.Sporttype AND s.Bettype=m.Bettype AND s.Islive=m.Islive AND s.CustID=s.recommend
		WHERE s.PT<>m.PT

	END
	--IF @RuleId IN(0,47)
	--BEGIN

	--	INSERT INTO #CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
	--	SELECT 47,s.sporttype,s.bettype,c.custid,NULL,s.spositiontaking,s.mpositiontaking,GETDATE(),s.islive 
	--	FROM Dep_CustSetting3rd s WITH(NOLOCK)
	--		INNER JOIN Customer c WITH(NOLOCK) ON s.custid=c.custid
	--		INNER JOIN #supersNG su ON c.srecommend=su.custid	
	--	WHERE  c.roleid=1 AND s.spositiontaking+s.mpositiontaking <> 0
	--		AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)	
	--		AND c.custid NOT IN(SELECT custid FROM #Trade)	
	--		AND s.sporttype=161
	
	--	INSERT INTO #CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
	--	SELECT 47,s.sporttype,s.bettype,c.custid,NULL,s.SuperPT,s.MasterPT ,GETDATE(),s.islive 
	--	FROM Dep_CustPTSetting_Member s WITH(NOLOCK)
	--		INNER JOIN Customer c WITH(NOLOCK) ON s.custid=c.custid
	--		INNER JOIN Dep_CustSettingMode d WITH(NOLOCK) ON c.custid=d.CustID
	--		INNER JOIN #supersVS su ON c.srecommend=su.custid	
	--	WHERE c.roleid=1 AND d.IsGroupedPT=0 AND s.SuperPT + s.MasterPT <> 0	
	--		AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)	
	--		AND c.custid NOT IN(SELECT custid FROM #Trade)	
	--		AND  s.SportType BETWEEN 180 AND 194

	--	INSERT INTO #CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
	--	SELECT 47,s.sporttype,s.bettype,c.custid,NULL,s.SuperPT ,s.MasterPT ,GETDATE(),s.islive 
	--	FROM Dep_CustPTGroupSetting_Member s WITH(NOLOCK)
	--		INNER JOIN Customer c WITH(NOLOCK) ON s.AgentID=c.custid
	--		INNER JOIN #supersVS su ON c.srecommend=su.custid	
	--	WHERE  c.roleid=2 AND s.SuperPT + s.MasterPT <> 0	
	--		AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)	
	--		AND  s.SportType BETWEEN 180 AND 194
			
	--END
	IF @RuleId IN(0,48)
	BEGIN		
		
			INSERT INTO #CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
			SELECT 48,s.sporttype,s.bettype,s.custid,NULL,s.apositiontaking,NULL,GETDATE(),s.islive 
			FROM Dep_CustSetting3rd s WITH(NOLOCK)		
				INNER JOIN Customer c WITH(NOLOCK) ON s.custid=c.custid	
				INNER JOIN #supersNG su ON c.srecommend=su.custid		
			WHERE c.roleid=1 AND s.sporttype=161 AND s.apositiontaking <> 0.88 AND s.apositiontaking<>0	
				AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)
				AND c.custid NOT IN(SELECT custid FROM #Trade)	
	
	END
	IF @RuleId IN (0,49)
	BEGIN		
		
		INSERT INTO #CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 49,s.sporttype,s.bettype,s.custid,NULL,s.AgentPT,NULL,GETDATE(),s.islive 
		FROM Dep_CustPTSetting_Member s WITH(NOLOCK)			
			INNER JOIN Customer c WITH(NOLOCK) ON s.custid=c.custid		
			INNER JOIN Dep_CustSettingMode d WITH(NOLOCK) ON c.custid=d.CustID
			INNER JOIN #supersVS su ON c.srecommend=su.custid		
		WHERE c.roleid=1 AND d.IsGroupedPT=0 AND  s.SportType BETWEEN 180 AND 194 AND s.AgentPT <> 88	
			AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)
			AND c.custid NOT IN(SELECT custid FROM #Trade)	

		INSERT INTO #CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 49,s.sporttype,s.bettype,s.AgentID,NULL,s.AgentPT,NULL,GETDATE(),s.islive 
		FROM Dep_CustPTGroupSetting_Member s WITH(NOLOCK)		
			INNER JOIN Customer c WITH(NOLOCK) ON s.AgentID=c.custid	
			INNER JOIN #supersVS su ON c.srecommend=su.custid				
		WHERE c.roleid=2  AND  s.SportType BETWEEN 180 AND 194 AND s.AgentPT <> 88
			AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)
		
	END	
	

	IF @RuleId IN (0,54)
	BEGIN	
		INSERT INTO #CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 54,t.Sporttype,t.Bettype,c.custid,NULL,NULL,NULL,GETDATE(),t.IsLive
		FROM Customer c WITH(NOLOCK)
			CROSS APPLY #tmpProfile t
			LEFT JOIN Dep_CustPTGroupSetting_Member s WITH(NOLOCK) ON c.custid=s.AgentID AND t.Sporttype=s.SportType AND t.Bettype=s.BetType AND t.IsLive=s.IsLive			
			INNER JOIN #supersVS su ON c.srecommend=su.custid	
		WHERE c.mrecommend NOT IN(SELECT custid FROM #Dummy)
			AND c.roleid=2 AND s.AgentID IS NULL	
			 AND  s.SportType BETWEEN 180 AND 194
	END
	IF @RuleId IN (0,55)
	BEGIN	
		INSERT INTO #CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 55,t.Sporttype,t.Bettype,c.custid,NULL,NULL,NULL,GETDATE(),t.IsLive
		FROM Customer c WITH(NOLOCK)
			CROSS APPLY #tmpProfile t
			LEFT JOIN Dep_CustPTSetting_Agent s WITH(NOLOCK) ON c.custid=s.CustID AND t.Sporttype=s.SportType AND t.Bettype=s.BetType AND t.IsLive=s.IsLive	
			INNER JOIN #supersVS su ON c.srecommend=su.custid			
		WHERE  c.mrecommend NOT IN(SELECT custid FROM #Dummy)		
				AND c.roleid IN(2,3,4) AND s.CustID IS NULL	
				 AND  s.SportType BETWEEN 180 AND 194
	END

END

select * from #CheckPTResult_Deposit
