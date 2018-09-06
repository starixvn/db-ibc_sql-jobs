USE CheckResultDB
 
GO 

ALTER PROCEDURE [dbo].DBA_CheckPositionTaking_Deposit
(
	@srecommend	INT   
	,@RuleId		SMALLINT = 0  
)
AS
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
	CREATE TABLE #Site (Site VARCHAR(20))
	CREATE TABLE #tmpProfile(Sporttype INT,Bettype INT,IsLive BIT)

	INSERT INTO #tmpProfile(Sporttype ,Bettype ,IsLive )
	SELECT Sporttype ,Bettype ,IsLive
	FROM CheckCustDB.dbo.Dep_ProductSetting ps WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.Dep_ProductSettingDetail psd WITH(NOLOCK) ON ps.ProductSettingID=psd.ProductSettingID
		INNER JOIN CheckCustDB.dbo.Dep_LicenseeProductSetting l WITH(NOLOCK) ON l.ProductSettingID=psd.ProductSettingID
	WHERE CustID=@srecommend AND ps.SettingType=1 AND psd.SettingStatus=0
	
	SELECT @site = Site FROM CheckCustDB.dbo.Dep_CustSuper WITH(NOLOCK) WHERE custid=@srecommend

	INSERT INTO #Site(Site)
	SELECT 	'9BET'
	UNION ALL
	SELECT 	'AONCASH'
	UNION ALL
	SELECT 	'BE7'
	UNION ALL
	SELECT 	'Bolanation'
	UNION ALL
	SELECT 	'Goobet'
	UNION ALL
	SELECT 	'ITCBET'
	UNION ALL
	SELECT 	'MACAUBET'
	UNION ALL
	SELECT 	'NBCBET'
	UNION ALL
	SELECT 	'Q8BOLA'
	UNION ALL
	SELECT 	'Sbcbet'
	UNION ALL
	SELECT 	'UNOBET'

	INSERT INTO #Dummy(CustID)
	SELECT CustID FROM CheckCustDB.dbo.Customer WITH(NOLOCK) WHERE srecommend=@srecommend AND roleid=3 AND username LIKE '%Acc%'

	INSERT INTO #Trade(CustID)
	SELECT CustID FROM CheckCustDB.dbo.Customer WITH(NOLOCK) WHERE srecommend=@srecommend AND roleid=1 AND (username LIKE '%Bettrade%' OR username LIKE '%CashOut%' OR username LIKE '%TransferUUS%')

	IF @RuleId IN (0,43)  
	BEGIN  
		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 43,s.sporttype,s.bettype,c.custid,NULL,s.spositiontaking,NULL,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustSetting s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=1 AND s.spositiontaking<0 

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 43,s.sporttype,s.bettype,c.custid,NULL,s.mpositiontaking,NULL,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustSetting s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=1 AND s.mpositiontaking<0

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 43,s.sporttype,s.bettype,c.custid,NULL,s.apositiontaking,NULL,GETDATE(),s.islive  
		FROM CheckCustDB.dbo.Dep_CustSetting s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=1 AND s.apositiontaking<0

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 43,s.sporttype,s.bettype,c.custid,NULL,s.spositiontaking,NULL,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustSetting3rd s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=1 AND s.spositiontaking<0

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 43,s.sporttype,s.bettype,c.custid,NULL,s.mpositiontaking ,NULL,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustSetting3rd s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=1 AND s.mpositiontaking<0

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 43,s.sporttype,s.bettype,c.custid,NULL,s.apositiontaking,NULL,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustSetting3rd s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=1 AND s.apositiontaking<0

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 43,s.sporttype,s.bettype,c.custid,NULL,s.spositiontaking ,NULL,GETDATE(),0
		FROM CheckCustDB.dbo.Dep_CustSettingGame s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=1 AND s.spositiontaking<0

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 43,s.sporttype,s.bettype,c.custid,NULL,s.mpositiontaking,NULL,GETDATE(),0
		FROM CheckCustDB.dbo.Dep_CustSettingGame s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=1 AND s.mpositiontaking<0

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 43,s.sporttype,s.bettype,c.custid,NULL,s.apositiontaking ,NULL,GETDATE(),0
		FROM CheckCustDB.dbo.Dep_CustSettingGame s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=1 AND s.apositiontaking<0

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 43,s.sporttype,s.bettype,c.custid,NULL,s.SuperPT,NULL,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustPTSetting_Member s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid
			INNER JOIN CheckCustDB.dbo.Dep_CustSettingMode d WITH(NOLOCK) ON c.custid=d.CustID
		WHERE c.srecommend=@srecommend AND d.IsGroupedPT=0 AND c.roleid=1 AND s.SuperPT<0

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 43,s.sporttype,s.bettype,c.custid,NULL,s.MasterPT ,NULL,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustPTSetting_Member s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid
			INNER JOIN CheckCustDB.dbo.Dep_CustSettingMode d WITH(NOLOCK) ON c.custid=d.CustID
		WHERE c.srecommend=@srecommend AND d.IsGroupedPT=0 AND c.roleid=1 AND s.MasterPT<0

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 43,s.sporttype,s.bettype,c.custid,NULL,s.AgentPT ,NULL,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustPTSetting_Member s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid
			INNER JOIN CheckCustDB.dbo.Dep_CustSettingMode d WITH(NOLOCK) ON c.custid=d.CustID
		WHERE c.srecommend=@srecommend AND d.IsGroupedPT=0 AND c.roleid=1 AND s.AgentPT<0

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 43,s.sporttype,s.bettype,c.custid,NULL,s.SuperPT ,NULL,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustPTGroupSetting_Member s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.AgentID=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=2 AND s.SuperPT<0

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 43,s.sporttype,s.bettype,c.custid,NULL,s.MasterPT ,NULL,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustPTGroupSetting_Member s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.AgentID=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=2 AND s.MasterPT<0

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 43,s.sporttype,s.bettype,c.custid,NULL,s.AgentPT ,NULL,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustPTGroupSetting_Member s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.AgentID=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=2 AND s.AgentPT<0

	END
	IF @RuleId IN (0,44)  
	BEGIN
		CREATE TABLE #tmpS(Sporttype INT, Bettype INT, Islive BIT, PT SMALLMONEY,PRIMARY KEY(Sporttype,Bettype,Islive))
		CREATE TABLE #tmpM(CustID INT,Sporttype INT, Bettype INT, Islive BIT, PT SMALLMONEY,PRIMARY KEY(CustID,Sporttype,Bettype,Islive))

		INSERT INTO #tmpS (Sporttype , Bettype , Islive , PT)
		SELECT s.sporttype,s.bettype,s.islive,s.spositiontaking
		FROM CheckCustDB.dbo.Dep_CustSetting s WITH(NOLOCK)			
		WHERE s.custid=@srecommend 
		
		INSERT INTO #tmpM (CustID,Sporttype , Bettype , Islive , PT)
		SELECT c.custid, s.sporttype,s.bettype,s.islive,s.mpositiontaking
		FROM CheckCustDB.dbo.Dep_CustSetting s WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid	
		WHERE c.srecommend=@srecommend AND c.roleid=3 AND c.custid NOT IN(SELECT custid FROM #Dummy)

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 44,s.sporttype,s.bettype,@srecommend,m.CustID,s.PT ,m.PT,GETDATE(),s.islive 
		FROM #tmpS s 
			INNER JOIN #tmpM m ON s.Sporttype=m.Sporttype AND s.Bettype=m.Bettype AND s.Islive=m.Islive
		WHERE s.PT<>m.PT

		TRUNCATE TABLE #tmpS
		TRUNCATE TABLE #tmpM
		
		INSERT INTO #tmpS (Sporttype , Bettype , Islive , PT)
		SELECT s.sporttype,s.bettype,s.islive,s.spositiontaking
		FROM CheckCustDB.dbo.Dep_CustSetting3rd s WITH(NOLOCK)			
		WHERE s.custid=@srecommend 
		
		INSERT INTO #tmpM (CustID,Sporttype , Bettype , Islive , PT)
		SELECT c.custid, s.sporttype,s.bettype,s.islive,s.mpositiontaking
		FROM CheckCustDB.dbo.Dep_CustSetting3rd s WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid	
		WHERE c.srecommend=@srecommend AND c.roleid=3 AND c.custid NOT IN(SELECT custid FROM #Dummy)

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 44,s.sporttype,s.bettype,@srecommend,m.CustID,s.PT ,m.PT,GETDATE(),s.islive 
		FROM #tmpS s 
			INNER JOIN #tmpM m ON s.Sporttype=m.Sporttype AND s.Bettype=m.Bettype AND s.Islive=m.Islive
		WHERE s.PT<>m.PT

		TRUNCATE TABLE #tmpS
		TRUNCATE TABLE #tmpM
		
		INSERT INTO #tmpS (Sporttype , Bettype , Islive , PT)
		SELECT s.sporttype,s.bettype,0,s.spositiontaking
		FROM CheckCustDB.dbo.Dep_CustSettingGame s WITH(NOLOCK)			
		WHERE s.custid=@srecommend 
		
		INSERT INTO #tmpM (CustID,Sporttype , Bettype , Islive , PT)
		SELECT c.custid, s.sporttype,s.bettype,0,s.mpositiontaking
		FROM CheckCustDB.dbo.Dep_CustSettingGame s WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid	
		WHERE c.srecommend=@srecommend AND c.roleid=3 AND c.custid NOT IN(SELECT custid FROM #Dummy)

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 44,s.sporttype,s.bettype,@srecommend,m.CustID,s.PT ,m.PT,GETDATE(),s.islive 
		FROM #tmpS s 
			INNER JOIN #tmpM m ON s.Sporttype=m.Sporttype AND s.Bettype=m.Bettype AND s.Islive=m.Islive
		WHERE s.PT<>m.PT

		TRUNCATE TABLE #tmpS
		TRUNCATE TABLE #tmpM
		
		INSERT INTO #tmpS (Sporttype , Bettype , Islive , PT)
		SELECT s.sporttype,s.bettype,IsLive,s.SuperPT
		FROM CheckCustDB.dbo.Dep_CustPTSetting_Agent s WITH(NOLOCK)			
		WHERE s.CustID=@srecommend 
		
		INSERT INTO #tmpM (CustID,Sporttype , Bettype , Islive , PT)
		SELECT c.custid, s.sporttype,s.bettype,IsLive,s.MasterPT
		FROM CheckCustDB.dbo.Dep_CustPTSetting_Agent s WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid	
		WHERE c.srecommend=@srecommend AND c.roleid=3 AND c.custid NOT IN(SELECT custid FROM #Dummy)

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 44,s.sporttype,s.bettype,@srecommend,m.CustID,s.PT ,m.PT,GETDATE(),s.islive 
		FROM #tmpS s 
			INNER JOIN #tmpM m ON s.Sporttype=m.Sporttype AND s.Bettype=m.Bettype AND s.Islive=m.Islive
		WHERE s.PT<>m.PT
	END
	IF @RuleId IN (0,45)  
	BEGIN
		CREATE TABLE #tmpM45(CustID INT,Sporttype INT, Bettype INT, Islive BIT, PT SMALLMONEY,PRIMARY KEY(CustID,Sporttype,Bettype,Islive))
		CREATE TABLE #tmpA45(CustID INT,Sporttype INT, Bettype INT, Islive BIT,mrecommend INT, PT SMALLMONEY,PRIMARY KEY(CustID,Sporttype,Bettype,Islive,mrecommend))

		INSERT INTO #tmpM45 (CustID, Sporttype , Bettype , Islive , PT)
		SELECT s.custid, s.sporttype,s.bettype,s.islive,s.mpositiontaking
		FROM CheckCustDB.dbo.Dep_CustSetting s WITH(NOLOCK)	
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid		
		WHERE c.srecommend=@srecommend AND c.roleid=3 AND c.custid NOT IN(SELECT custid FROM #Dummy)
		
		INSERT INTO #tmpA45 (CustID,Sporttype , Bettype , Islive , PT,mrecommend)
		SELECT c.custid, s.sporttype,s.bettype,s.islive,s.apositiontaking,c.mrecommend
		FROM CheckCustDB.dbo.Dep_CustSetting s WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid	
		WHERE c.srecommend=@srecommend AND c.roleid=2

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 45,s.sporttype,s.bettype,s.CustID,m.CustID,s.PT ,m.PT,GETDATE(),s.islive 
		FROM #tmpM45 s 
			INNER JOIN #tmpA45 m ON s.Sporttype=m.Sporttype AND s.Bettype=m.Bettype AND s.Islive=m.Islive AND s.CustID=m.mrecommend
		WHERE s.PT<>m.PT

		TRUNCATE TABLE #tmpM45
		TRUNCATE TABLE #tmpA45
		
		INSERT INTO #tmpM45 (CustID, Sporttype , Bettype , Islive , PT)
		SELECT s.custid, s.sporttype,s.bettype,s.islive,s.mpositiontaking
		FROM CheckCustDB.dbo.Dep_CustSetting3rd s WITH(NOLOCK)	
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid		
		WHERE c.srecommend=@srecommend AND c.roleid=3 AND c.custid NOT IN(SELECT custid FROM #Dummy)
		
		INSERT INTO #tmpA45 (CustID,Sporttype , Bettype , Islive , PT,mrecommend)
		SELECT c.custid, s.sporttype,s.bettype,s.islive,s.apositiontaking,c.mrecommend
		FROM CheckCustDB.dbo.Dep_CustSetting3rd s WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid	
		WHERE c.srecommend=@srecommend AND c.roleid=2

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 45,s.sporttype,s.bettype,s.CustID,m.CustID,s.PT ,m.PT,GETDATE(),s.islive 
		FROM #tmpM45 s 
			INNER JOIN #tmpA45 m ON s.Sporttype=m.Sporttype AND s.Bettype=m.Bettype AND s.Islive=m.Islive AND s.CustID=m.mrecommend
		WHERE s.PT<>m.PT

		TRUNCATE TABLE #tmpM45
		TRUNCATE TABLE #tmpA45
		
		INSERT INTO #tmpM45 (CustID, Sporttype , Bettype , Islive , PT)
		SELECT s.custid, s.sporttype,s.bettype,0,s.mpositiontaking
		FROM CheckCustDB.dbo.Dep_CustSettingGame s WITH(NOLOCK)	
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid		
		WHERE c.srecommend=@srecommend AND c.roleid=3 AND c.custid NOT IN(SELECT custid FROM #Dummy)
		
		INSERT INTO #tmpA45 (CustID,Sporttype , Bettype , Islive , PT,mrecommend)
		SELECT c.custid, s.sporttype,s.bettype,0,s.apositiontaking,c.mrecommend
		FROM CheckCustDB.dbo.Dep_CustSettingGame s WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid	
		WHERE c.srecommend=@srecommend AND c.roleid=2

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 45,s.sporttype,s.bettype,s.CustID,m.CustID,s.PT ,m.PT,GETDATE(),s.islive 
		FROM #tmpM45 s 
			INNER JOIN #tmpA45 m ON s.Sporttype=m.Sporttype AND s.Bettype=m.Bettype AND s.Islive=m.Islive AND s.CustID=m.mrecommend
		WHERE s.PT<>m.PT
		
		TRUNCATE TABLE #tmpM45
		TRUNCATE TABLE #tmpA45

		INSERT INTO #tmpM45 (CustID, Sporttype , Bettype , Islive , PT)
		SELECT s.custid, s.sporttype,s.bettype,IsLive,s.MasterPT
		FROM CheckCustDB.dbo.Dep_CustPTSetting_Agent s WITH(NOLOCK)	
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid		
		WHERE c.srecommend=@srecommend AND c.roleid=3 AND c.custid NOT IN(SELECT custid FROM #Dummy)
		
		INSERT INTO #tmpA45 (CustID,Sporttype , Bettype , Islive , PT,mrecommend)
		SELECT c.custid, s.sporttype,s.bettype,IsLive,s.AgentPT,c.mrecommend
		FROM CheckCustDB.dbo.Dep_CustPTSetting_Agent s WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid	
		WHERE c.srecommend=@srecommend AND c.roleid=2

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
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
		FROM CheckCustDB.dbo.Dep_CustSetting s WITH(NOLOCK)	
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid		
		WHERE c.srecommend=@srecommend AND c.roleid=2 AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)
		
		INSERT INTO #tmpA1 (CustID,Sporttype , Bettype , Islive , PT,recommend)
		SELECT c.custid, s.sporttype,s.bettype,s.islive,s.apositiontaking,c.recommend
		FROM CheckCustDB.dbo.Dep_CustSetting s WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid	
		WHERE c.srecommend=@srecommend AND c.roleid=1	AND c.custid NOT IN(SELECT custid FROM #Trade)

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 46,s.sporttype,s.bettype,s.CustID,m.CustID,s.PT ,m.PT,GETDATE(),s.islive 
		FROM #tmpA1 s 
			INNER JOIN #tmpA2 m ON s.Sporttype=m.Sporttype AND s.Bettype=m.Bettype AND s.Islive=m.Islive AND s.CustID=s.recommend
		WHERE s.PT<>m.PT

		TRUNCATE TABLE #tmpA1
		TRUNCATE TABLE #tmpA2
		
		INSERT INTO #tmpA2 (CustID, Sporttype , Bettype , Islive , PT)
		SELECT s.custid, s.sporttype,s.bettype,s.islive,s.apositiontaking
		FROM CheckCustDB.dbo.Dep_CustSetting3rd s WITH(NOLOCK)	
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid		
		WHERE c.srecommend=@srecommend AND c.roleid=2 AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)
		
		INSERT INTO #tmpA1 (CustID,Sporttype , Bettype , Islive , PT,recommend)
		SELECT c.custid, s.sporttype,s.bettype,s.islive,s.apositiontaking,c.recommend
		FROM CheckCustDB.dbo.Dep_CustSetting3rd s WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid	
		WHERE c.srecommend=@srecommend AND c.roleid=1 AND c.custid NOT IN(SELECT custid FROM #Trade)

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 46,s.sporttype,s.bettype,s.CustID,m.CustID,s.PT ,m.PT,GETDATE(),s.islive 
		FROM #tmpA1 s 
			INNER JOIN #tmpA2 m ON s.Sporttype=m.Sporttype AND s.Bettype=m.Bettype AND s.Islive=m.Islive AND s.CustID=s.recommend
		WHERE s.PT<>m.PT

		TRUNCATE TABLE #tmpA1
		TRUNCATE TABLE #tmpA2
		
		INSERT INTO #tmpA2 (CustID, Sporttype , Bettype , Islive , PT)
		SELECT s.custid, s.sporttype,s.bettype,0,s.apositiontaking
		FROM CheckCustDB.dbo.Dep_CustSettingGame s WITH(NOLOCK)	
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid		
		WHERE c.srecommend=@srecommend AND c.roleid=2 AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)
		
		INSERT INTO #tmpA1 (CustID,Sporttype , Bettype , Islive , PT,recommend)
		SELECT c.custid, s.sporttype,s.bettype,0,s.apositiontaking,c.recommend
		FROM CheckCustDB.dbo.Dep_CustSettingGame s WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid	
		WHERE c.srecommend=@srecommend AND c.roleid=1 AND c.custid NOT IN(SELECT custid FROM #Trade)

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 46,s.sporttype,s.bettype,s.CustID,m.CustID,s.PT ,m.PT,GETDATE(),s.islive 
		FROM #tmpA1 s 
			INNER JOIN #tmpA2 m ON s.Sporttype=m.Sporttype AND s.Bettype=m.Bettype AND s.Islive=m.Islive AND s.CustID=s.recommend
		WHERE s.PT<>m.PT

		TRUNCATE TABLE #tmpA1
		TRUNCATE TABLE #tmpA2

		INSERT INTO #tmpA2 (CustID, Sporttype , Bettype , Islive , PT)
		SELECT s.custid, s.sporttype,s.bettype,IsLive,s.AgentPT
		FROM CheckCustDB.dbo.Dep_CustPTSetting_Agent s WITH(NOLOCK)	
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid		
		WHERE c.srecommend=@srecommend AND c.roleid=2 AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)

		INSERT INTO #tmpA1 (CustID,Sporttype , Bettype , Islive , PT,recommend)
		SELECT c.custid, s.sporttype,s.bettype,IsLive,s.AgentPT,c.recommend
		FROM CheckCustDB.dbo.Dep_CustPTSetting_Member s WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid	
			INNER JOIN CheckCustDB.dbo.Dep_CustSettingMode d WITH(NOLOCK) ON c.custid=d.CustID
		WHERE c.srecommend=@srecommend AND c.roleid=1 AND d.IsGroupedPT=0 AND c.custid NOT IN(SELECT custid FROM #Trade)

		INSERT INTO #tmpA1 (CustID,Sporttype , Bettype , Islive , PT,recommend)
		SELECT c.custid, s.sporttype,s.bettype,IsLive,s.AgentPT,c.recommend
		FROM CheckCustDB.dbo.Dep_CustPTGroupSetting_Member s WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.AgentID=c.custid	
		WHERE c.srecommend=@srecommend AND c.roleid=2 AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 46,s.sporttype,s.bettype,s.CustID,m.CustID,s.PT ,m.PT,GETDATE(),s.islive 
		FROM #tmpA1 s 
			INNER JOIN #tmpA2 m ON s.Sporttype=m.Sporttype AND s.Bettype=m.Bettype AND s.Islive=m.Islive AND s.CustID=s.recommend
		WHERE s.PT<>m.PT

	END
	IF @RuleId IN(0,47)
	BEGIN
		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 47,s.sporttype,s.bettype,c.custid,NULL,s.spositiontaking,s.mpositiontaking,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustSetting s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=1 AND s.spositiontaking+s.mpositiontaking <> 0	
			AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)	
			AND c.custid NOT IN(SELECT custid FROM #Trade)	

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 47,s.sporttype,s.bettype,c.custid,NULL,s.spositiontaking,s.mpositiontaking,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustSetting3rd s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=1 AND s.spositiontaking+s.mpositiontaking <> 0
			AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)	
			AND c.custid NOT IN(SELECT custid FROM #Trade)	

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 47,s.sporttype,s.bettype,c.custid,NULL,s.spositiontaking ,s.mpositiontaking,GETDATE(),0
		FROM CheckCustDB.dbo.Dep_CustSettingGame s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=1 AND s.spositiontaking+s.mpositiontaking <> 0
			AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)	
			AND c.custid NOT IN(SELECT custid FROM #Trade)	
	
		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 47,s.sporttype,s.bettype,c.custid,NULL,s.SuperPT,s.MasterPT ,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustPTSetting_Member s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid
			INNER JOIN CheckCustDB.dbo.Dep_CustSettingMode d WITH(NOLOCK) ON c.custid=d.CustID
		WHERE c.srecommend=@srecommend AND c.roleid=1 AND d.IsGroupedPT=0 AND s.SuperPT + s.MasterPT <> 0	
			AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)	
			AND c.custid NOT IN(SELECT custid FROM #Trade)	

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 47,s.sporttype,s.bettype,c.custid,NULL,s.SuperPT ,s.MasterPT ,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustPTGroupSetting_Member s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.AgentID=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=2 AND s.SuperPT + s.MasterPT <> 0	
			AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)	
			
	END
	IF @RuleId IN(0,48)
	BEGIN		
		IF @site ='Haifa'
		BEGIN
			INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
			SELECT 48,s.sporttype,s.bettype,s.custid,NULL,s.apositiontaking,NULL,GETDATE(),s.islive 
			FROM CheckCustDB.dbo.Dep_CustSetting s WITH(NOLOCK)		
				INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid	
			WHERE c.srecommend=@srecommend AND c.roleid=1 AND (s.sporttype<99 OR s.sporttype=154) AND s.apositiontaking <> 0.905	
				AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)
				AND c.custid NOT IN(SELECT custid FROM #Trade)	
		END
		ELSE IF @site ='Tonybet'
		BEGIN
			INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
			SELECT 48,s.sporttype,s.bettype,s.custid,NULL,s.apositiontaking,NULL,GETDATE(),s.islive 
			FROM CheckCustDB.dbo.Dep_CustSetting s WITH(NOLOCK)		
				INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid		
			WHERE c.srecommend=@srecommend AND c.roleid=1 AND (s.sporttype<99 OR s.sporttype=154) AND s.apositiontaking <> 0.90	
				AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)
				AND c.custid NOT IN(SELECT custid FROM #Trade)	
		END
		ELSE
		BEGIN
			INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
			SELECT 48,s.sporttype,s.bettype,s.custid,NULL,s.apositiontaking,NULL,GETDATE(),s.islive 
			FROM CheckCustDB.dbo.Dep_CustSetting s WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid	
			WHERE c.srecommend=@srecommend AND c.roleid=1 AND (s.sporttype<99 OR s.sporttype=154) AND s.apositiontaking <> 0.85	
				AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)
				AND c.custid NOT IN(SELECT custid FROM #Trade)	
		END
		IF @site <>'Haifa'
		BEGIN
			INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
			SELECT 48,s.sporttype,s.bettype,s.custid,NULL,s.apositiontaking,NULL,GETDATE(),s.islive 
			FROM CheckCustDB.dbo.Dep_CustSetting3rd s WITH(NOLOCK)		
				INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid		
			WHERE c.srecommend=@srecommend  AND c.roleid=1 AND s.sporttype=161 AND s.apositiontaking <> 0.85	
				AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)
				AND c.custid NOT IN(SELECT custid FROM #Trade)	
		END		
	END
	IF @RuleId IN (0,49)
	BEGIN		
		IF @site ='Haifa'
		BEGIN
			INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
			SELECT 49,s.sporttype,s.bettype,s.custid,NULL,s.AgentPT,NULL,GETDATE(),s.islive 
			FROM CheckCustDB.dbo.Dep_CustPTSetting_Member s WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid		
				INNER JOIN CheckCustDB.dbo.Dep_CustSettingMode d WITH(NOLOCK) ON c.custid=d.CustID
			WHERE s.custid=@srecommend AND c.roleid=1 AND d.IsGroupedPT=0 AND (s.sporttype BETWEEN 190 AND 193 OR s.sporttype BETWEEN 180 AND 186 ) AND s.AgentPT <> 87.5	
				AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)
				AND c.custid NOT IN(SELECT custid FROM #Trade)	

			INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
			SELECT 49,s.sporttype,s.bettype,s.AgentID,NULL,s.AgentPT,NULL,GETDATE(),s.islive 
			FROM CheckCustDB.dbo.Dep_CustPTGroupSetting_Member s WITH(NOLOCK)		
				INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.AgentID=c.custid			
			WHERE c.srecommend=@srecommend AND c.roleid=2 AND (s.sporttype BETWEEN 190 AND 193 OR s.sporttype BETWEEN 180 AND 186 ) AND s.AgentPT <> 87.5
				AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)
			
		END
		ELSE
		BEGIN
			INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
			SELECT 49,s.sporttype,s.bettype,s.custid,NULL,s.AgentPT,NULL,GETDATE(),s.islive 
			FROM CheckCustDB.dbo.Dep_CustPTSetting_Member s WITH(NOLOCK)							
				INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid
				INNER JOIN CheckCustDB.dbo.Dep_CustSettingMode d WITH(NOLOCK) ON c.custid=d.CustID 		
			WHERE s.custid=@srecommend AND c.roleid=1 AND d.IsGroupedPT=0 AND (s.sporttype BETWEEN 190 AND 193 OR s.sporttype BETWEEN 180 AND 186 ) AND s.AgentPT <> 85
				AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)
				AND c.custid NOT IN(SELECT custid FROM #Trade)	

			INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
			SELECT 49,s.sporttype,s.bettype,s.AgentID,NULL,s.AgentPT,NULL,GETDATE(),s.islive 
			FROM CheckCustDB.dbo.Dep_CustPTGroupSetting_Member s WITH(NOLOCK)		
				INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.AgentID=c.custid			
			WHERE c.srecommend=@srecommend AND c.roleid=2 AND (s.sporttype BETWEEN 190 AND 193 OR s.sporttype BETWEEN 180 AND 186 ) AND s.AgentPT <> 85
				AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)
		END
		IF EXISTS (SELECT 1 FROM #Site WHERE Site=@site)
		BEGIN
			INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
			SELECT 49,s.sporttype,s.bettype,s.custid,NULL,s.AgentPT,NULL,GETDATE(),s.islive 
			FROM CheckCustDB.dbo.Dep_CustPTSetting_Member s WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid	
				INNER JOIN CheckCustDB.dbo.Dep_CustSettingMode d WITH(NOLOCK) ON c.custid=d.CustID 			
			WHERE s.custid=@srecommend AND c.roleid=1 AND d.IsGroupedPT=0 AND s.sporttype =211 AND s.AgentPT <> 85	
				AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)
				AND c.custid NOT IN(SELECT custid FROM #Trade)	

			INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
			SELECT 49,s.sporttype,s.bettype,s.AgentID,NULL,s.AgentPT,NULL,GETDATE(),s.islive 
			FROM CheckCustDB.dbo.Dep_CustPTGroupSetting_Member s WITH(NOLOCK)		
				INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.AgentID=c.custid			
			WHERE c.srecommend=@srecommend AND c.roleid=2 AND s.sporttype =211 AND s.AgentPT <> 85
				AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)
		END
		
	END
	IF @RuleId IN (0,50)
	BEGIN			
		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 50,s.sporttype,s.bettype,s.CustID,NULL,s.apositiontaking,NULL,GETDATE(),0
		FROM CheckCustDB.dbo.CustSettingGame s WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.CustID=c.custid			
		WHERE c.srecommend=@srecommend AND c.roleid=1 AND s.sporttype =202 AND s.apositiontaking <> 0.9
			AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)
			AND c.custid NOT IN(SELECT custid FROM #Trade)	

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 50,s.sporttype,s.bettype,s.custid,NULL,s.AgentPT,NULL,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustPTSetting_Member s WITH(NOLOCK)			
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid		
			INNER JOIN CheckCustDB.dbo.Dep_CustSettingMode d WITH(NOLOCK) ON c.custid=d.CustID 			
		WHERE s.custid=@srecommend AND c.roleid=1  AND d.IsGroupedPT=0 AND s.sporttype =220 AND s.AgentPT <> 90
			AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)
			AND c.custid NOT IN(SELECT custid FROM #Trade)	

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 50,s.sporttype,s.bettype,s.AgentID,NULL,s.AgentPT,NULL,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustPTGroupSetting_Member s WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.AgentID=c.custid			
		WHERE c.srecommend=@srecommend AND c.roleid=2 AND s.sporttype =220 AND s.AgentPT <> 90
			AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)

		IF EXISTS (SELECT 1 FROM #Site WHERE Site=@site)
		BEGIN
			INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
			SELECT 50,s.sporttype,s.bettype,s.custid,NULL,s.AgentPT,NULL,GETDATE(),s.islive 
			FROM CheckCustDB.dbo.Dep_CustPTSetting_Member s WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid		
				INNER JOIN CheckCustDB.dbo.Dep_CustSettingMode d WITH(NOLOCK) ON c.custid=d.CustID 			
			WHERE s.custid=@srecommend AND c.roleid=1  AND d.IsGroupedPT=0 AND s.sporttype =219 AND s.AgentPT <> 90
				AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)
				AND c.custid NOT IN(SELECT custid FROM #Trade)	

			INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
			SELECT 50,s.sporttype,s.bettype,s.AgentID,NULL,s.AgentPT,NULL,GETDATE(),s.islive 
			FROM CheckCustDB.dbo.Dep_CustPTGroupSetting_Member s WITH(NOLOCK)		
				INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.AgentID=c.custid			
			WHERE c.srecommend=@srecommend AND c.roleid=2 AND s.sporttype =219 AND s.AgentPT <> 90
				AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)
		END			
	END
	IF @RuleId IN (0,51)
	BEGIN	
		IF NOT EXISTS (SELECT 1 FROM #Site WHERE Site=@site)
		BEGIN
			INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
			SELECT 51,s.sporttype,s.bettype,s.custid,NULL,s.AgentPT,NULL,GETDATE(),s.islive 
			FROM CheckCustDB.dbo.Dep_CustPTSetting_Member s WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid		
				INNER JOIN CheckCustDB.dbo.Dep_CustSettingMode d WITH(NOLOCK) ON c.custid=d.CustID 			
			WHERE s.custid=@srecommend AND c.roleid=1  AND d.IsGroupedPT=0 AND (s.sporttype =211 OR s.sporttype =219)  AND s.AgentPT <> 92
				AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)
				AND c.custid NOT IN(SELECT custid FROM #Trade)	

			INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
			SELECT 51,s.sporttype,s.bettype,s.AgentID,NULL,s.AgentPT,NULL,GETDATE(),s.islive 
			FROM CheckCustDB.dbo.Dep_CustPTGroupSetting_Member s WITH(NOLOCK)		
				INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.AgentID=c.custid			
			WHERE c.srecommend=@srecommend AND c.roleid=2 AND (s.sporttype =211 OR s.sporttype =219) AND s.AgentPT <> 92
				AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)
		END		
	END
	IF @RuleId IN (0,52)
	BEGIN	
		IF NOT EXISTS (SELECT 1 FROM #Site WHERE Site=@site)
		BEGIN
			INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
			SELECT 52,s.sporttype,s.bettype,s.custid,NULL,s.AgentPT,NULL,GETDATE(),s.islive 
			FROM CheckCustDB.dbo.Dep_CustPTSetting_Member s WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid		
				INNER JOIN CheckCustDB.dbo.Dep_CustSettingMode d WITH(NOLOCK) ON c.custid=d.CustID 			
			WHERE s.custid=@srecommend AND c.roleid=1  AND d.IsGroupedPT=0 AND s.sporttype =212 AND s.AgentPT <> 93
				AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)
				AND c.custid NOT IN(SELECT custid FROM #Trade)	

			INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
			SELECT 52,s.sporttype,s.bettype,s.AgentID,NULL,s.AgentPT,NULL,GETDATE(),s.islive 
			FROM CheckCustDB.dbo.Dep_CustPTGroupSetting_Member s WITH(NOLOCK)		
				INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.AgentID=c.custid			
			WHERE c.srecommend=@srecommend AND c.roleid=2 AND s.sporttype =212 AND s.AgentPT <> 93
				AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)
		END		
	END
	IF @RuleId IN (0,53)
	BEGIN	
		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 53,s.sporttype,s.bettype,c.custid,NULL,s.spositiontaking+s.mpositiontaking+s.apositiontaking,NULL,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustSetting s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid
			INNER JOIN CheckCustDB.dbo.Dep_CustBAActive BA WITH(NOLOCK) ON c.custid=BA.CustId
		WHERE c.srecommend=@srecommend AND c.roleid=1 AND s.spositiontaking+s.mpositiontaking+s.apositiontaking <> 0

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 53,s.sporttype,s.bettype,c.custid,NULL,s.spositiontaking+s.mpositiontaking+s.apositiontaking,NULL,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustSetting3rd s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid
			INNER JOIN CheckCustDB.dbo.Dep_CustBAActive BA WITH(NOLOCK) ON c.custid=BA.CustId
		WHERE c.srecommend=@srecommend AND c.roleid=1 AND s.spositiontaking+s.mpositiontaking+s.apositiontaking <> 0

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 53,s.sporttype,s.bettype,c.custid,NULL,s.spositiontaking+s.mpositiontaking+s.apositiontaking ,NULL,GETDATE(),0
		FROM CheckCustDB.dbo.Dep_CustSettingGame s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid
			INNER JOIN CheckCustDB.dbo.Dep_CustBAActive BA WITH(NOLOCK) ON c.custid=BA.CustId
		WHERE c.srecommend=@srecommend AND c.roleid=1 AND s.spositiontaking+s.mpositiontaking+s.apositiontaking <> 0

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 53,s.sporttype,s.bettype,c.custid,NULL, s.SuperPT+s.MasterPT+s.AgentPT ,NULL,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustPTSetting_Member s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid
			INNER JOIN CheckCustDB.dbo.Dep_CustSettingMode d WITH(NOLOCK) ON c.custid=d.CustID
			INNER JOIN CheckCustDB.dbo.Dep_CustBAActive BA WITH(NOLOCK) ON c.custid=BA.CustId
		WHERE c.srecommend=@srecommend AND c.roleid=1 AND d.IsGroupedPT=0 AND s.SuperPT+s.MasterPT+s.AgentPT <> 0	

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 53,s.sporttype,s.bettype,c.custid,NULL, s.SuperPT+s.MasterPT+s.AgentPT ,NULL,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustPTGroupSetting_Member s WITH(NOLOCK)			
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.AgentID=c.recommend
			INNER JOIN CheckCustDB.dbo.Dep_CustBAActive BA WITH(NOLOCK) ON c.custid=BA.CustId
		WHERE c.srecommend=@srecommend AND s.SuperPT+s.MasterPT+s.AgentPT <> 0			
	END
	IF @RuleId IN (0,54)
	BEGIN	
		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 54,t.Sporttype,t.Bettype,c.custid,NULL,NULL,NULL,GETDATE(),t.IsLive
		FROM CheckCustDB.dbo.Customer c WITH(NOLOCK)
			CROSS APPLY #tmpProfile t
			LEFT JOIN CheckCustDB.dbo.Dep_CustPTGroupSetting_Member s WITH(NOLOCK) ON c.custid=s.AgentID AND t.Sporttype=s.SportType AND t.Bettype=s.BetType AND t.IsLive=s.IsLive			
		WHERE c.srecommend=@srecommend AND c.mrecommend NOT IN(SELECT custid FROM #Dummy)
			AND c.roleid=2 AND s.AgentID IS NULL	
	END
	IF @RuleId IN (0,55)
	BEGIN	
		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 55,t.Sporttype,t.Bettype,c.custid,NULL,NULL,NULL,GETDATE(),t.IsLive
		FROM CheckCustDB.dbo.Customer c WITH(NOLOCK)
			CROSS APPLY #tmpProfile t
			LEFT JOIN CheckCustDB.dbo.Dep_CustPTSetting_Agent s WITH(NOLOCK) ON c.custid=s.CustID AND t.Sporttype=s.SportType AND t.Bettype=s.BetType AND t.IsLive=s.IsLive			
		WHERE c.srecommend=@srecommend 
				AND c.mrecommend NOT IN(SELECT custid FROM #Dummy)		
				AND c.roleid IN(2,3,4) AND s.CustID IS NULL	
	END
	IF @RuleId IN (0,56)
	BEGIN	
		IF EXISTS(SELECT 1 FROm #tmpProfile)
		BEGIN
			INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
			SELECT 56,NULL,NULL,c.custid,NULL,NULL,NULL,GETDATE(),NULL
			FROM CheckCustDB.dbo.Customer c WITH(NOLOCK)		
				LEFT JOIN CheckCustDB.dbo.Dep_CustSettingMode s WITH(NOLOCK) ON c.custid=s.CustID 	
			WHERE c.srecommend=@srecommend 
					AND c.custid NOT IN(SELECT custid FROM #Trade)		
					AND c.mrecommend NOT IN(SELECT custid FROM #Dummy)	
					AND c.roleid =1 AND s.CustID IS NULL	
		END
	END
	IF @RuleId IN (0,57)
	BEGIN		
		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 57,1,911,c.custid,NULL,s.HousePT,NULL,GETDATE(),NULL
		FROM CheckCustDB.dbo.Customer c WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.TradeComm s WITH(NOLOCK) ON c.custid=s.AgentID 	
		WHERE c.srecommend=@srecommend AND s.HousePT<>1				
	END
	IF @RuleId IN (0,58)
	BEGIN		
		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 58,1,901,c.custid,NULL,s.HousePT,NULL,GETDATE(),NULL
		FROM CheckCustDB.dbo.Customer c WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.BetTradeComm s WITH(NOLOCK) ON c.custid=s.AgentID 	
		WHERE c.srecommend=@srecommend AND s.HousePT<>0.5				
	END
	IF @RuleId IN (0,59)
	BEGIN		
		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 59,1,901,c.custid,NULL,NULL,NULL,GETDATE(),NULL
		FROM CheckCustDB.dbo.Customer c WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.Dep_CustProductSetting s WITH(NOLOCK) ON c.custid=s.CustID 	
		WHERE c.srecommend=@srecommend AND s.ProductId=13 AND s.IsEnabled=1
			AND c.custid NOT IN(SELECT custid FROM #Trade)		
			AND c.recommend NOT IN(SELECT AgentID FROM CheckCustDB.dbo.BetTradeComm WITH(NOLOCK) )	
			AND c.mrecommend NOT IN(SELECT custid FROM #Dummy)		
			
		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 59,1,911,c.custid,NULL,NULL,NULL,GETDATE(),NULL
		FROM CheckCustDB.dbo.Customer c WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.Dep_CustProductSetting s WITH(NOLOCK) ON c.custid=s.CustID 	
		WHERE c.srecommend=@srecommend AND s.ProductId=25 AND s.IsEnabled=1
			AND c.custid NOT IN(SELECT custid FROM #Trade)		
			AND c.recommend NOT IN(SELECT AgentID FROM CheckCustDB.dbo.TradeComm WITH(NOLOCK) )		
			AND c.mrecommend NOT IN(SELECT custid FROM #Dummy)							
	END

END
	