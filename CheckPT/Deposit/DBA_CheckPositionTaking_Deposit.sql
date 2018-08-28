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
	IF @RuleId IN (0,43)  
	BEGIN  
		INSERT INTO [dbo].CheckPositionTakingResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 43,s.sporttype,s.bettype,c.custid,NULL,s.spositiontaking,NULL,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustSetting s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=1 AND s.spositiontaking<0

		INSERT INTO [dbo].CheckPositionTakingResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 43,s.sporttype,s.bettype,c.custid,NULL,s.mpositiontaking,NULL,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustSetting s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=1 AND s.mpositiontaking<0

		INSERT INTO [dbo].CheckPositionTakingResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 43,s.sporttype,s.bettype,c.custid,NULL,s.apositiontaking,NULL,GETDATE(),s.islive  
		FROM CheckCustDB.dbo.Dep_CustSetting s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=1 AND s.apositiontaking<0

		INSERT INTO [dbo].CheckPositionTakingResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 43,s.sporttype,s.bettype,c.custid,NULL,s.spositiontaking,NULL,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustSetting3rd s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=1 AND s.spositiontaking<0

		INSERT INTO [dbo].CheckPositionTakingResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 43,s.sporttype,s.bettype,c.custid,NULL,s.mpositiontaking ,NULL,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustSetting3rd s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=1 AND s.mpositiontaking<0

		INSERT INTO [dbo].CheckPositionTakingResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 43,s.sporttype,s.bettype,c.custid,NULL,s.apositiontaking,NULL,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustSetting3rd s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=1 AND s.apositiontaking<0

		INSERT INTO [dbo].CheckPositionTakingResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 43,s.sporttype,s.bettype,c.custid,NULL,s.spositiontaking ,NULL,GETDATE(),0
		FROM CheckCustDB.dbo.Dep_CustSettingGame s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=1 AND s.spositiontaking<0

		INSERT INTO [dbo].CheckPositionTakingResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 43,s.sporttype,s.bettype,c.custid,NULL,s.mpositiontaking,NULL,GETDATE(),0
		FROM CheckCustDB.dbo.Dep_CustSettingGame s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=1 AND s.mpositiontaking<0

		INSERT INTO [dbo].CheckPositionTakingResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 43,s.sporttype,s.bettype,c.custid,NULL,s.apositiontaking ,NULL,GETDATE(),0
		FROM CheckCustDB.dbo.Dep_CustSettingGame s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=1 AND s.apositiontaking<0

		INSERT INTO [dbo].CheckPositionTakingResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 43,s.sporttype,s.bettype,c.custid,NULL,s.SuperPT,NULL,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustPTSetting_Member s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=1 AND s.SuperPT<0

		INSERT INTO [dbo].CheckPositionTakingResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 43,s.sporttype,s.bettype,c.custid,NULL,s.MasterPT ,NULL,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustPTSetting_Member s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=1 AND s.MasterPT<0

		INSERT INTO [dbo].CheckPositionTakingResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 43,s.sporttype,s.bettype,c.custid,NULL,s.AgentPT ,NULL,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustPTSetting_Member s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=1 AND s.AgentPT<0

		INSERT INTO [dbo].CheckPositionTakingResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 43,s.sporttype,s.bettype,c.custid,NULL,s.SuperPT ,NULL,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustPTGroupSetting_Member s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.AgentID=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=2 AND s.SuperPT<0

		INSERT INTO [dbo].CheckPositionTakingResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 43,s.sporttype,s.bettype,c.custid,NULL,s.MasterPT ,NULL,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustPTGroupSetting_Member s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.AgentID=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=2 AND s.MasterPT<0

		INSERT INTO [dbo].CheckPositionTakingResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
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
		WHERE c.srecommend=@srecommend AND c.roleid=3

		INSERT INTO [dbo].CheckPositionTakingResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 44,s.sporttype,s.bettype,NULL,m.CustID,s.PT ,m.PT,GETDATE(),s.islive 
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
		FROM CheckCustDB.dbo.Dep_CustSetting3d s WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid	
		WHERE c.srecommend=@srecommend AND c.roleid=3

		INSERT INTO [dbo].CheckPositionTakingResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 44,s.sporttype,s.bettype,NULL,m.CustID,s.PT ,m.PT,GETDATE(),s.islive 
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
		WHERE c.srecommend=@srecommend AND c.roleid=3

		INSERT INTO [dbo].CheckPositionTakingResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 44,s.sporttype,s.bettype,NULL,m.CustID,s.PT ,m.PT,GETDATE(),s.islive 
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
		WHERE c.srecommend=@srecommend AND c.roleid=3

		INSERT INTO [dbo].CheckPositionTakingResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 44,s.sporttype,s.bettype,NULL,m.CustID,s.PT ,m.PT,GETDATE(),s.islive 
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
		WHERE c.srecommend=@srecommend AND c.roleid=3
		
		INSERT INTO #tmpA45 (CustID,Sporttype , Bettype , Islive , PT,mrecommend)
		SELECT c.custid, s.sporttype,s.bettype,s.islive,s.apositiontaking,c.mrecommend
		FROM CheckCustDB.dbo.Dep_CustSetting s WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid	
		WHERE c.srecommend=@srecommend AND c.roleid=2

		INSERT INTO [dbo].CheckPositionTakingResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
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
		WHERE c.srecommend=@srecommend AND c.roleid=3
		
		INSERT INTO #tmpA45 (CustID,Sporttype , Bettype , Islive , PT,mrecommend)
		SELECT c.custid, s.sporttype,s.bettype,s.islive,s.apositiontaking,c.mrecommend
		FROM CheckCustDB.dbo.Dep_CustSetting3rd s WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid	
		WHERE c.srecommend=@srecommend AND c.roleid=2

		INSERT INTO [dbo].CheckPositionTakingResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
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
		WHERE c.srecommend=@srecommend AND c.roleid=3
		
		INSERT INTO #tmpA45 (CustID,Sporttype , Bettype , Islive , PT,mrecommend)
		SELECT c.custid, s.sporttype,s.bettype,0,s.apositiontaking,c.mrecommend
		FROM CheckCustDB.dbo.Dep_CustSettingGame s WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid	
		WHERE c.srecommend=@srecommend AND c.roleid=2

		INSERT INTO [dbo].CheckPositionTakingResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
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
		WHERE c.srecommend=@srecommend AND c.roleid=3
		
		INSERT INTO #tmpA45 (CustID,Sporttype , Bettype , Islive , PT,mrecommend)
		SELECT c.custid, s.sporttype,s.bettype,IsLive,s.AgentPT,c.mrecommend
		FROM CheckCustDB.dbo.Dep_CustPTSetting_Agent s WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid	
		WHERE c.srecommend=@srecommend AND c.roleid=2

		INSERT INTO [dbo].CheckPositionTakingResult_Deposit(RulesID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
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
		WHERE c.srecommend=@srecommend AND c.roleid=2
		
		INSERT INTO #tmpA1 (CustID,Sporttype , Bettype , Islive , PT,recommend)
		SELECT c.custid, s.sporttype,s.bettype,s.islive,s.apositiontaking,c.recommend
		FROM CheckCustDB.dbo.Dep_CustSetting s WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid	
		WHERE c.srecommend=@srecommend AND c.roleid=1

		INSERT INTO [dbo].CheckPositionTakingResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
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
		WHERE c.srecommend=@srecommend AND c.roleid=2
		
		INSERT INTO #tmpA1 (CustID,Sporttype , Bettype , Islive , PT,recommend)
		SELECT c.custid, s.sporttype,s.bettype,s.islive,s.apositiontaking,c.recommend
		FROM CheckCustDB.dbo.Dep_CustSetting3rd s WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid	
		WHERE c.srecommend=@srecommend AND c.roleid=1

		INSERT INTO [dbo].CheckPositionTakingResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
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
		WHERE c.srecommend=@srecommend AND c.roleid=2
		
		INSERT INTO #tmpA1 (CustID,Sporttype , Bettype , Islive , PT,recommend)
		SELECT c.custid, s.sporttype,s.bettype,0,s.apositiontaking,c.recommend
		FROM CheckCustDB.dbo.Dep_CustSettingGame s WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid	
		WHERE c.srecommend=@srecommend AND c.roleid=1

		INSERT INTO [dbo].CheckPositionTakingResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
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
		WHERE c.srecommend=@srecommend AND c.roleid=2
		
		INSERT INTO #tmpA1 (CustID,Sporttype , Bettype , Islive , PT,recommend)
		SELECT c.custid, s.sporttype,s.bettype,IsLive,s.AgentPT,c.recommend
		FROM CheckCustDB.dbo.Dep_CustPTSetting_Member s WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid	
		WHERE c.srecommend=@srecommend AND c.roleid=1

		INSERT INTO #tmpA1 (CustID,Sporttype , Bettype , Islive , PT,recommend)
		SELECT c.custid, s.sporttype,s.bettype,IsLive,s.AgentPT,c.recommend
		FROM CheckCustDB.dbo.Dep_CustPTGroupSetting_Member s WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.AgentID=c.custid	
		WHERE c.srecommend=@srecommend AND c.roleid=2

		INSERT INTO [dbo].CheckPositionTakingResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 46,s.sporttype,s.bettype,s.CustID,m.CustID,s.PT ,m.PT,GETDATE(),s.islive 
		FROM #tmpA1 s 
			INNER JOIN #tmpA2 m ON s.Sporttype=m.Sporttype AND s.Bettype=m.Bettype AND s.Islive=m.Islive AND s.CustID=s.recommend
		WHERE s.PT<>m.PT

	END
	IF @RuleId IN(0,47)
	BEGIN
		INSERT INTO [dbo].CheckPositionTakingResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 47,s.sporttype,s.bettype,c.custid,NULL,s.spositiontaking,s.mpositiontaking,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustSetting s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=1 AND s.spositiontaking+s.mpositiontaking <> 0		

		INSERT INTO [dbo].CheckPositionTakingResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 47,s.sporttype,s.bettype,c.custid,NULL,s.spositiontaking,s.mpositiontaking,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustSetting3rd s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=1 AND s.spositiontaking+s.mpositiontaking <> 0		

		INSERT INTO [dbo].CheckPositionTakingResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 47,s.sporttype,s.bettype,c.custid,NULL,s.spositiontaking ,s.mpositiontaking,GETDATE(),0
		FROM CheckCustDB.dbo.Dep_CustSettingGame s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=1 AND s.spositiontaking+s.mpositiontaking <> 0	
	
		INSERT INTO [dbo].CheckPositionTakingResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 47,s.sporttype,s.bettype,c.custid,NULL,s.SuperPT,s.MasterPT ,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustPTSetting_Member s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=1 AND s.SuperPT + s.MasterPT <> 0	

		INSERT INTO [dbo].CheckPositionTakingResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 47,s.sporttype,s.bettype,c.custid,NULL,s.SuperPT ,s.MasterPT ,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustPTGroupSetting_Member s WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.AgentID=c.custid
		WHERE c.srecommend=@srecommend AND c.roleid=2 AND s.SuperPT + s.MasterPT <> 0	
	END
	IF @RuleId IN(0,48)
	BEGIN
		DECLARE @site VARCHAR(20)
		SELECT @site = Site FROM CheckCustDB.dbo.Dep_CustSuper WITH(NOLOCK) WHERE custid=@srecommend
		IF @site ='Haifa'
		BEGIN
			INSERT INTO [dbo].CheckPositionTakingResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
			SELECT 48,s.sporttype,s.bettype,s.custid,NULL,s.spositiontaking,NULL,GETDATE(),s.islive 
			FROM CheckCustDB.dbo.Dep_CustSetting s WITH(NOLOCK)			
			WHERE s.custid=@srecommend AND (s.sporttype<99 OR s.sporttype=154) AND s.spositiontaking <> 0.85	
		END
		ELSE
		BEGIN
			INSERT INTO [dbo].CheckPositionTakingResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
			SELECT 48,s.sporttype,s.bettype,s.custid,NULL,s.spositiontaking,NULL,GETDATE(),s.islive 
			FROM CheckCustDB.dbo.Dep_CustSetting s WITH(NOLOCK)			
			WHERE s.custid=@srecommend AND (s.sporttype<99 OR s.sporttype=154) AND s.spositiontaking <> 0.85	
		END


		INSERT INTO [dbo].CheckPositionTakingResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 48,s.sporttype,s.bettype,s.custid,NULL,s.spositiontaking,NULL,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustSetting3rd s WITH(NOLOCK)			
		WHERE s.custid=@srecommend AND s.sporttype=161 AND s.spositiontaking <> 0.85	

		INSERT INTO [dbo].CheckPositionTakingResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 48,s.sporttype,s.bettype,s.custid,NULL,s.SuperPT,NULL,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustPTSetting_Agent s WITH(NOLOCK)			
		WHERE s.custid=@srecommend AND s.sporttype BETWEEN 180 AND 186 AND s.SuperPT <> 85	

		
	END
END
	