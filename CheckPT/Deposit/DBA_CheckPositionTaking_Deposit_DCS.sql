/*<info serverAlias="DBCHECK-CheckResultDB" executers="" viewers="" isFunction="0"></info>*/
USE CheckResultDB
GO
ALTER PROCEDURE [dbo].[DBA_CheckPositionTaking_Deposit_DCS]
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
		-20190128@Winnie: Update PT RedmineID:#108062
		-20190409@Winnie: Fix check PT RedmineID:#111663
		-20190604@Winnie: [Bobbet,A1game,ig128] Update SB PT to reflect new terms RedmineID:#113387
		-20190708@Winnie: Rules PT RedmineID:#116469
	Param's Explanation:
	
*/
SET NOCOUNT ON
BEGIN
	IF @srecommend IN(1752415,932209,1574083,179457)--'AB88SuperRM' , '12BETSuperSD$',MS88SuperBND,'ITSA'
	RETURN

	DECLARE @site VARCHAR(20),@currency INT,@IsAthena BIT=0

	CREATE TABLE #tmpProfile(Sporttype INT,Bettype INT,IsLive BIT)

	INSERT INTO #tmpProfile(Sporttype ,Bettype ,IsLive )
	SELECT Sporttype ,Bettype ,IsLive
	FROM CheckCustDB.dbo.Dep_ProductSetting ps WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.Dep_ProductSettingDetail psd WITH(NOLOCK) ON ps.ProductSettingID=psd.ProductSettingID
		INNER JOIN CheckCustDB.dbo.Dep_LicenseeProductSetting l WITH(NOLOCK) ON l.ProductSettingID=psd.ProductSettingID
	WHERE CustID=@srecommend AND ps.SettingType=1 AND psd.SettingStatus=0
	
	SELECT @site = Site,@currency=currency FROM CheckCustDB.dbo.Dep_CustSuper WITH(NOLOCK) WHERE custid=@srecommend

	IF EXISTS(
	SELECT TOP 1 1
	FROM [bodb_OIC].[dbo].[Licensee] l WITH (NOLOCK)
		INNER JOIN [bodb_OIC].[dbo].[LicenseeType] t WITH (NOLOCK) ON t.LicenseeTypeId = l.LicenseeTypeId
	WHERE t.LicenseeTypeName LIKE '%Athena' AND ([LicenseeName]=@site OR [RegisteredLicenseeName]=@site))
	BEGIN
		SELECT @IsAthena=1
	END

	CREATE TABLE #tmpDumMember (CustID INT , username VARCHAR(30),RoleID INT,PRIMARY KEY(CustID,RoleID))
	CREATE TABLE #Trade (CustID INT PRIMARY KEY)
	CREATE TABLE #Dummy (CustID INT PRIMARY KEY)

	INSERT INTO #tmpDumMember(custid, username,RoleID)
	SELECT c.CustID, fc.username,c.RoleID
	FROM CheckCustDB.dbo.CustInfo c WITH(NOLOCK) 
	 CROSS APPLY (
	  SELECT TOP 1 custid, username
	  FROM CheckCustDB.dbo.Customer cc WITH(NOLOCK)
	  WHERE c.custid = cc.custid 
	 ) fc
	WHERE c.srecommend = @srecommend
	 AND c.roleid IN(1,3)	
	 AND c.Enabled=1

	INSERT INTO #Dummy(CustID)
	SELECT d.custid
	FROM #tmpDumMember d
	WHERE (username LIKE '%Acc%' OR username LIKE '%LocalBank%' OR username LIKE '%AFF%' OR username like 'AB88'+'CAS%')	
	AND d.RoleID=3

	INSERT INTO #Trade(CustID)
	SELECT d.custid
	FROM #tmpDumMember d
	WHERE (username LIKE '%Bettrade%' OR username LIKE '%CashOut%' OR username LIKE '%TransferUUS%' OR username LIKE '%ClearBal%')
	AND d.RoleID =1
	UNION
	SELECT c.CustID
	FROM CheckCustDB.dbo.CustInfo c WITH(NOLOCK)
		INNER JOIN #Dummy d ON c.mrecommend=d.CustID

	DELETE m
	FROM #tmpDumMember m
		INNER JOIN #Trade t ON m.CustID=t.CustID
	
	IF @RuleId IN (0,44)  
	BEGIN
		CREATE TABLE #tmpS(Sporttype INT, Bettype INT, Islive BIT, PT SMALLMONEY,PRIMARY KEY(Sporttype,Bettype,Islive))
		CREATE TABLE #tmpM(CustID INT,Sporttype INT, Bettype INT, Islive BIT, PT SMALLMONEY,PRIMARY KEY(CustID,Sporttype,Bettype,Islive))	
		
		INSERT INTO #tmpS (Sporttype , Bettype , Islive , PT)
		SELECT s.sporttype,s.bettype,IsLive,s.SuperPT
		FROM CheckCustDB.dbo.Dep_CustPTSetting_Agent s WITH(NOLOCK)			
		WHERE s.CustID=@srecommend 
		
		INSERT INTO #tmpM (CustID,Sporttype , Bettype , Islive , PT)
		SELECT c.custid, s.sporttype,s.bettype,IsLive,s.MasterPT
		FROM CheckCustDB.dbo.Dep_CustPTSetting_Agent s WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.CustInfo c WITH(NOLOCK) ON s.custid=c.custid	
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
		SELECT s.custid, s.sporttype,s.bettype,IsLive,s.MasterPT
		FROM CheckCustDB.dbo.Dep_CustPTSetting_Agent s WITH(NOLOCK)	
			INNER JOIN CheckCustDB.dbo.CustInfo c WITH(NOLOCK) ON s.custid=c.custid		
		WHERE c.srecommend=@srecommend AND c.roleid=3 AND c.custid NOT IN(SELECT custid FROM #Dummy)
		
		INSERT INTO #tmpA45 (CustID,Sporttype , Bettype , Islive , PT,mrecommend)
		SELECT c.custid, s.sporttype,s.bettype,IsLive,s.AgentPT,c.mrecommend
		FROM CheckCustDB.dbo.Dep_CustPTSetting_Agent s WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.CustInfo c WITH(NOLOCK) ON s.custid=c.custid	
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
		SELECT s.custid, s.sporttype,s.bettype,IsLive,s.AgentPT
		FROM CheckCustDB.dbo.Dep_CustPTSetting_Agent s WITH(NOLOCK)	
			INNER JOIN CheckCustDB.dbo.CustInfo c WITH(NOLOCK) ON s.custid=c.custid		
		WHERE c.srecommend=@srecommend AND c.roleid=2 AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)
			AND s.SportType<>43

		INSERT INTO #tmpA1 (CustID,Sporttype , Bettype , Islive , PT,recommend)
		SELECT c.custid, s.sporttype,s.bettype,IsLive,s.AgentPT,c.recommend
		FROM CheckCustDB.dbo.Dep_CustPTSetting_Member s WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.CustInfo c WITH(NOLOCK) ON s.custid=c.custid	
			INNER JOIN CheckCustDB.dbo.Dep_CustSettingMode d WITH(NOLOCK) ON c.custid=d.CustID
		WHERE c.srecommend=@srecommend AND c.roleid=1 AND d.IsGroupedPT=0 AND c.custid NOT IN(SELECT custid FROM #Trade)
			AND s.SportType<>43

		INSERT INTO #tmpA1 (CustID,Sporttype , Bettype , Islive , PT,recommend)
		SELECT c.custid, s.sporttype,s.bettype,IsLive,s.AgentPT,c.recommend
		FROM CheckCustDB.dbo.Dep_CustPTGroupSetting_Member s WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.CustInfo c WITH(NOLOCK) ON s.AgentID=c.custid	
		WHERE c.srecommend=@srecommend AND c.roleid=2 AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)
			AND s.SportType<>43

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 46,s.sporttype,s.bettype,s.CustID,m.CustID,s.PT ,m.PT,GETDATE(),s.islive 
		FROM #tmpA1 s 
			INNER JOIN #tmpA2 m ON s.Sporttype=m.Sporttype AND s.Bettype=m.Bettype AND s.Islive=m.Islive AND m.CustID=s.recommend
		WHERE s.PT<>m.PT
	END
	IF @RuleId IN (0,71)
	BEGIN	
		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 71,s.sporttype,s.bettype,s.custid,NULL,s.AgentPT,NULL,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustPTSetting_Member s WITH(NOLOCK)							
			INNER JOIN CheckCustDB.dbo.CustInfo c WITH(NOLOCK) ON s.custid=c.custid
			INNER JOIN CheckCustDB.dbo.Dep_CustSettingMode d WITH(NOLOCK) ON c.custid=d.CustID 			
		WHERE s.custid=@srecommend AND c.roleid=1 AND d.IsGroupedPT=0 AND  (s.sporttype BETWEEN 180 AND 186  OR s.sporttype BETWEEN 190 AND 194) AND (s.AgentPT NOT IN(85,88) OR s.SuperPT<>0 OR s.MasterPT<>0)
			AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)
			AND c.custid NOT IN(SELECT custid FROM #Trade)	

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 71,s.sporttype,s.bettype,s.AgentID,NULL,s.AgentPT,NULL,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustPTGroupSetting_Member s WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.CustInfo c WITH(NOLOCK) ON s.AgentID=c.custid			
		WHERE c.srecommend=@srecommend AND c.roleid=2 AND  (s.sporttype BETWEEN 180 AND 186 OR s.sporttype BETWEEN 190 AND 194) AND (s.AgentPT NOT IN(85,88) OR s.SuperPT<>0 OR s.MasterPT<>0)
			AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)
	
		IF(@IsAthena=0)
		BEGIN
			INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
			SELECT 71,s.sporttype,s.bettype,s.custid,NULL,s.AgentPT,NULL,GETDATE(),s.islive 
			FROM CheckCustDB.dbo.Dep_CustPTSetting_Member s WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid	
				INNER JOIN CheckCustDB.dbo.Dep_CustSettingMode d WITH(NOLOCK) ON c.custid=d.CustID 				
			WHERE s.custid=@srecommend AND c.roleid=1 AND d.IsGroupedPT=0 AND s.sporttype =211 AND (s.AgentPT <> 85	OR s.SuperPT<>0 OR s.MasterPT<>0)
				AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)
				AND c.custid NOT IN(SELECT custid FROM #Trade)					

			INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
			SELECT 71,s.sporttype,s.bettype,s.AgentID,NULL,s.AgentPT,NULL,GETDATE(),s.islive 
			FROM CheckCustDB.dbo.Dep_CustPTGroupSetting_Member s WITH(NOLOCK)		
				INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.AgentID=c.custid	
			WHERE c.srecommend=@srecommend AND c.roleid=2 AND s.sporttype =211 AND (s.AgentPT <> 85 OR s.SuperPT<>0 OR s.MasterPT<>0)
				AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)				
		END
		ELSE
		BEGIN
			INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
			SELECT 71,s.sporttype,s.bettype,s.custid,NULL,s.AgentPT,NULL,GETDATE(),s.islive 
			FROM CheckCustDB.dbo.Dep_CustPTSetting_Member s WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid	
				INNER JOIN CheckCustDB.dbo.Dep_CustSettingMode d WITH(NOLOCK) ON c.custid=d.CustID 
			WHERE s.custid=@srecommend AND c.roleid=1 AND d.IsGroupedPT=0 AND s.sporttype =211 AND (s.AgentPT <> 92	OR s.SuperPT<>0 OR s.MasterPT<>0)
				AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)
				AND c.custid NOT IN(SELECT custid FROM #Trade)	

			INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
			SELECT 71,s.sporttype,s.bettype,s.AgentID,NULL,s.AgentPT,NULL,GETDATE(),s.islive 
			FROM CheckCustDB.dbo.Dep_CustPTGroupSetting_Member s WITH(NOLOCK)		
				INNER JOIN CheckCustDB.dbo.CustInfo c WITH(NOLOCK) ON s.AgentID=c.custid	
			WHERE c.srecommend=@srecommend AND c.roleid=2 AND s.sporttype =211 AND (s.AgentPT <> 92 OR s.SuperPT<>0 OR s.MasterPT<>0)
				AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)
		END 

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 71,s.sporttype,s.bettype,s.custid,NULL,s.AgentPT,NULL,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustPTSetting_Member s WITH(NOLOCK)			
			INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid	
			INNER JOIN CheckCustDB.dbo.Dep_CustSettingMode d WITH(NOLOCK) ON c.custid=d.CustID				
		WHERE s.custid=@srecommend AND c.roleid=1 AND d.IsGroupedPT=0 AND s.sporttype =212 AND (s.AgentPT <> 93	OR s.SuperPT<>0 OR s.MasterPT<>0)
			AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)
			AND c.custid NOT IN(SELECT custid FROM #Trade)	

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 71,s.sporttype,s.bettype,s.AgentID,NULL,s.AgentPT,NULL,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustPTGroupSetting_Member s WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.CustInfo c WITH(NOLOCK) ON s.AgentID=c.custid	
		WHERE c.srecommend=@srecommend AND c.roleid=2 AND s.sporttype =212 AND (s.AgentPT <> 93 OR s.SuperPT<>0 OR s.MasterPT<>0)
			AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)

		IF(@IsAthena=0)
		BEGIN
			INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
			SELECT 71,s.sporttype,s.bettype,s.custid,NULL,s.AgentPT,NULL,GETDATE(),s.islive 
			FROM CheckCustDB.dbo.Dep_CustPTSetting_Member s WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid	
				INNER JOIN CheckCustDB.dbo.Dep_CustSettingMode d WITH(NOLOCK) ON c.custid=d.CustID 					
			WHERE s.custid=@srecommend AND c.roleid=1 AND d.IsGroupedPT=0 AND s.sporttype IN(219,248) AND (s.AgentPT <> 92	OR s.SuperPT<>0 OR s.MasterPT<>0)
				AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)
				AND c.custid NOT IN(SELECT custid FROM #Trade)					

			INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
			SELECT 71,s.sporttype,s.bettype,s.AgentID,NULL,s.AgentPT,NULL,GETDATE(),s.islive 
			FROM CheckCustDB.dbo.Dep_CustPTGroupSetting_Member s WITH(NOLOCK)		
				INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.AgentID=c.custid								
			WHERE c.srecommend=@srecommend AND c.roleid=2 AND s.sporttype  IN(219,248) AND (s.AgentPT <> 92 OR s.SuperPT<>0 OR s.MasterPT<>0)
				AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)				
		END
		ELSE
		BEGIN
			INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
			SELECT 71,s.sporttype,s.bettype,s.custid,NULL,s.AgentPT,NULL,GETDATE(),s.islive 
			FROM CheckCustDB.dbo.Dep_CustPTSetting_Member s WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.custid=c.custid	
				INNER JOIN CheckCustDB.dbo.Dep_CustSettingMode d WITH(NOLOCK) ON c.custid=d.CustID 					
			WHERE s.custid=@srecommend AND c.roleid=1 AND d.IsGroupedPT=0 AND s.sporttype  IN(219,248) AND (s.AgentPT <> 90	OR s.SuperPT<>0 OR s.MasterPT<>0)
				AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)
				AND c.custid NOT IN(SELECT custid FROM #Trade)	

			INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
			SELECT 71,s.sporttype,s.bettype,s.AgentID,NULL,s.AgentPT,NULL,GETDATE(),s.islive 
			FROM CheckCustDB.dbo.Dep_CustPTGroupSetting_Member s WITH(NOLOCK)		
				INNER JOIN CheckCustDB.dbo.Customer c WITH(NOLOCK) ON s.AgentID=c.custid	
			WHERE c.srecommend=@srecommend AND c.roleid=2 AND s.sporttype IN(219,248) AND (s.AgentPT <> 90 OR s.SuperPT<>0 OR s.MasterPT<>0)
				AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)	
		END

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 71,s.sporttype,s.bettype,s.custid,NULL,s.AgentPT,NULL,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustPTSetting_Member s WITH(NOLOCK)			
			INNER JOIN CheckCustDB.dbo.CustInfo c WITH(NOLOCK) ON s.custid=c.custid		
			INNER JOIN CheckCustDB.dbo.Dep_CustSettingMode d WITH(NOLOCK) ON c.custid=d.CustID 			
		WHERE s.custid=@srecommend AND c.roleid=1  AND d.IsGroupedPT=0 AND s.sporttype =220 AND (s.AgentPT IN(90,94) OR s.SuperPT<>0 OR s.MasterPT<>0)
			AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)
			AND c.custid NOT IN(SELECT custid FROM #Trade)	

		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 71,s.sporttype,s.bettype,s.AgentID,NULL,s.AgentPT,NULL,GETDATE(),s.islive 
		FROM CheckCustDB.dbo.Dep_CustPTGroupSetting_Member s WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.CustInfo c WITH(NOLOCK) ON s.AgentID=c.custid			
		WHERE c.srecommend=@srecommend AND c.roleid=2 AND s.sporttype =220 AND (s.AgentPT IN(90,94) OR s.SuperPT<>0 OR s.MasterPT<>0)
			AND c.mrecommend NOT IN (SELECT custid FROM #Dummy)
		
	END
		
	IF @RuleId IN (0,54)
	BEGIN	
		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 54,t.Sporttype,t.Bettype,c.custid,NULL,NULL,NULL,GETDATE(),t.IsLive
		FROM CheckCustDB.dbo.CustInfo c WITH(NOLOCK)
			CROSS APPLY #tmpProfile t
			LEFT JOIN CheckCustDB.dbo.Dep_CustPTGroupSetting_Member s WITH(NOLOCK) ON c.custid=s.AgentID AND t.Sporttype=s.SportType AND t.Bettype=s.BetType AND t.IsLive=s.IsLive			
		WHERE c.srecommend=@srecommend AND c.mrecommend NOT IN(SELECT custid FROM #Dummy)
			AND c.roleid=2 AND s.AgentID IS NULL	
	END
	IF @RuleId IN (0,55)
	BEGIN	
		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 55,t.Sporttype,t.Bettype,c.custid,NULL,NULL,NULL,GETDATE(),t.IsLive
		FROM CheckCustDB.dbo.CustInfo c WITH(NOLOCK)
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
			FROM CheckCustDB.dbo.CustInfo c WITH(NOLOCK)		
				LEFT JOIN CheckCustDB.dbo.Dep_CustSettingMode s WITH(NOLOCK) ON c.custid=s.CustID 	
			WHERE c.srecommend=@srecommend 
					AND c.custid NOT IN(SELECT custid FROM #Trade)		
					AND c.mrecommend NOT IN(SELECT custid FROM #Dummy)	
					AND c.roleid =1 AND s.CustID IS NULL	
		END
	END
	
	IF @RuleId IN(0,60)
	BEGIN
		IF @site='asiabet88' AND @currency IN(3,6)
		BEGIN
			INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
			SELECT 60,NULL,NULL,BA.custid,NULL, NULL ,NULL,GETDATE(),NULL
			FROM CheckCustDB.dbo.Dep_CustSettingMode d WITH(NOLOCK)
				INNER JOIN CheckCustDB.dbo.Dep_CustBAActive BA WITH(NOLOCK) ON d.custid=BA.CustId
				INNER  JOIN #tmpDumMember t ON BA.CustId=t.CustID					
			WHERE t.roleid=1 AND d.IsGroupedPT<>1 
		END
	END
	IF @RuleId IN(0,61)
	BEGIN		
		IF @site='asiabet88' AND @currency IN(3,6)
		BEGIN	
			INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
			SELECT 61,s.sporttype,s.bettype,c.custid,NULL,s.AgentPT ,NULL,GETDATE(),s.islive 
			FROM CheckCustDB.dbo.Dep_CustPTGroupSetting_Member s WITH(NOLOCK)			
				INNER JOIN CheckCustDB.dbo.CustInfo c WITH(NOLOCK) ON s.AgentID=c.recommend
				INNER JOIN CheckCustDB.dbo.Dep_CustBAActive BA WITH(NOLOCK) ON c.custid=BA.CustId
				INNER JOIN CheckCustDB.dbo.Dep_ProductSettingDetail p WITH(NOLOCK) ON s.SportType=p.SportType AND s.BetType=p.BetType AND s.IsLive=p.IsLive		
				INNER JOIN CheckCustDB.dbo.Dep_ProductSetting ps WITH(NOLOCK) ON p.ProductSettingID=ps.ProductSettingID
			WHERE c.srecommend=@srecommend AND (s.SuperPT<>0 OR s.MasterPT<>0 OR s.AgentPT <> 0)		
				AND p.IsApplyBA=1 AND ps.SettingType=1
		END
	END
	IF @RuleId IN(0,62)
	BEGIN
		IF @site='asiabet88' AND @currency IN(3,6)
		BEGIN
			INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
			SELECT 62,NULL,NULL,d.custid,NULL, NULL ,NULL,GETDATE(),NULL
			FROM CheckCustDB.dbo.Dep_CustSettingMode d WITH(NOLOCK)
				INNER  JOIN #tmpDumMember t ON d.CustId=t.CustID	
			WHERE t.roleid=1 AND d.IsGroupedPT<>0 AND NOT EXISTS(SELECT TOP 1 1 FROM CheckCustDB.dbo.Dep_CustBAActive BA WITH(NOLOCK) WHERE d.CustID=BA.CustId)
		END
	END
	IF @RuleId IN(0,63)
	BEGIN
		IF @site='asiabet88' AND @currency IN(3,6)
		BEGIN
			INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
			SELECT 63,d.SportType,d.BetType,d.custid,NULL, NULL ,NULL,GETDATE(),d.IsLive
			FROM CheckCustDB.dbo.Dep_CustPTSetting_Member d WITH(NOLOCK)
				INNER  JOIN #tmpDumMember t ON d.CustId=t.CustID	
			WHERE t.roleid=1 AND NOT EXISTS(SELECT TOP 1 1 FROM #tmpProfile t WITH(NOLOCK) WHERE t.Sporttype=d.SportType AND t.Bettype=d.BetType AND t.IsLive=d.IsLive)
		END
	END
	IF @RuleId IN(0,64)
	BEGIN
		IF @site='asiabet88' AND @currency IN(3,6)
		BEGIN
			INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
			SELECT 64,m.SportType,m.BetType,m.custid,a.CustID, m.AgentPT ,a.AgentPT,GETDATE(),m.IsLive
			FROM CheckCustDB.dbo.Dep_CustPTSetting_Member m WITH(NOLOCK)
				INNER JOIN CheckCustDB.dbo.custInfo ci WITH(NOLOCK) ON m.CustID=ci.custid
				INNER JOIN CheckCustDB.dbo.Dep_CustPTSetting_Agent a WITH(NOLOCK) ON a.CustID=ci.recommend	AND m.SportType=a.SportType AND m.BetType=a.BetType AND m.IsLive=a.IsLive					
			WHERE ci.srecommend=@srecommend AND ci.roleid=1 AND NOT EXISTS(SELECT TOP 1 1 FROM CheckCustDB.dbo.Dep_CustBAActive BA WITH(NOLOCK) WHERE m.CustID=BA.CustId)
				AND (m.SuperPT<>a.SuperPT OR m.MasterPT<>a.MasterPT OR m.AgentPT<>a.AgentPT)
		END
	END
	IF @RuleId IN(0,65)
	BEGIN
		IF @site<>'asiabet88' OR(@site='asiabet88' AND @currency NOT IN(3,6))
		BEGIN
			INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
			SELECT 65,NULL,NULL,BA.custid,NULL, NULL ,NULL,GETDATE(),NULL
			FROM CheckCustDB.dbo.Dep_CustSettingMode d WITH(NOLOCK)
				INNER JOIN CheckCustDB.dbo.Dep_CustBAActive BA WITH(NOLOCK) ON d.custid=BA.CustId
				INNER  JOIN #tmpDumMember t ON BA.CustId=t.CustID					
			WHERE t.roleid=1 AND d.IsGroupedPT<>0
		END
	END
	IF @RuleId IN(0,66)
	BEGIN
		IF @site<>'asiabet88' OR(@site='asiabet88' AND @currency NOT IN(3,6))
		BEGIN
			INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
			SELECT 66,d.SportType,d.BetType,d.custid,NULL, NULL ,NULL,GETDATE(),d.IsLive
			FROM CheckCustDB.dbo.Dep_CustPTSetting_Member d WITH(NOLOCK)
				INNER  JOIN #tmpDumMember t ON d.CustId=t.CustID	
			WHERE t.roleid=1 AND NOT EXISTS(SELECT TOP 1 1 FROM #tmpProfile t WITH(NOLOCK) WHERE t.Sporttype=d.SportType AND t.Bettype=d.BetType AND t.IsLive=d.IsLive)
		END
	END
	IF @RuleId IN(0,67)
	BEGIN
		IF @site<>'asiabet88' OR(@site='asiabet88' AND @currency NOT IN(3,6))
		BEGIN			
			INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
			SELECT 67,s.sporttype,s.bettype,t.custid,NULL,s.AgentPT ,NULL,GETDATE(),s.islive 
			FROM CheckCustDB.dbo.Dep_CustPTSetting_Member s WITH(NOLOCK)
				INNER JOIN #tmpDumMember t ON s.CustID=t.CustID	
				INNER JOIN CheckCustDB.dbo.Dep_CustBAActive BA WITH(NOLOCK) ON t.custid=BA.CustId
				INNER JOIN CheckCustDB.dbo.Dep_ProductSettingDetail p WITH(NOLOCK) ON s.SportType=p.SportType AND s.BetType=p.BetType AND s.IsLive=p.IsLive		
				INNER JOIN CheckCustDB.dbo.Dep_ProductSetting ps WITH(NOLOCK) ON p.ProductSettingID=ps.ProductSettingID
			WHERE t.RoleID=1 AND( s.SuperPT<>0 OR s.MasterPT<>0 OR s.AgentPT <> 0	)	
				AND p.IsApplyBA=1	AND ps.SettingType=1
		END
	END
	IF @RuleId IN(0,68)
	BEGIN
		IF @site<>'asiabet88' OR(@site='asiabet88' AND @currency NOT IN(3,6))
		BEGIN
			INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
			SELECT 68,m.SportType,m.BetType,m.custid,a.CustID, m.AgentPT ,a.AgentPT,GETDATE(),m.IsLive
			FROM CheckCustDB.dbo.Dep_CustPTSetting_Member m WITH(NOLOCK)
				INNER JOIN CheckCustDB.dbo.Dep_CustBAActive BA WITH(NOLOCK) ON m.custid=BA.CustId		
				INNER JOIN CheckCustDB.dbo.custInfo ci WITH(NOLOCK) ON m.CustID=ci.custid
				INNER JOIN CheckCustDB.dbo.Dep_CustPTSetting_Agent a WITH(NOLOCK) ON a.CustID=ci.recommend AND m.SportType=a.SportType AND m.BetType=a.BetType AND m.IsLive=a.IsLive				
				INNER JOIN CheckCustDB.dbo.Dep_ProductSettingDetail p WITH(NOLOCK) ON m.SportType=p.SportType AND m.BetType=p.BetType AND m.IsLive=p.IsLive	
				INNER JOIN CheckCustDB.dbo.Dep_ProductSetting ps WITH(NOLOCK) ON p.ProductSettingID=ps.ProductSettingID		
			WHERE ci.srecommend=@srecommend AND ci.roleid=1 
				AND (m.SuperPT<>a.SuperPT OR m.MasterPT<>a.MasterPT OR m.AgentPT<>a.AgentPT)
				AND p.IsApplyBA=0 AND ps.SettingType=1
		END
	END
	IF @RuleId IN(0,69)
	BEGIN
		IF @site<>'asiabet88' OR(@site='asiabet88' AND @currency NOT IN(3,6))
		BEGIN
			INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
			SELECT 69,NULL,NULL,d.custid,NULL, NULL ,NULL,GETDATE(),NULL
			FROM CheckCustDB.dbo.Dep_CustSettingMode d WITH(NOLOCK)
				INNER  JOIN #tmpDumMember t ON d.CustId=t.CustID	
			WHERE t.roleid=1 AND d.IsGroupedPT<>1 AND NOT EXISTS(SELECT TOP 1 1 FROM CheckCustDB.dbo.Dep_CustBAActive BA WITH(NOLOCK) WHERE d.CustID=BA.CustId)
		END
	END
	IF @RuleId IN(0,70)
	BEGIN		
		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 70,d.SportType,d.BetType,d.AgentID,NULL, d.AgentPT ,NULL,GETDATE(),d.IsLive
		FROM CheckCustDB.dbo.Dep_CustPTGroupSetting_Member d WITH(NOLOCK)
			INNER  JOIN  CheckCustDB.dbo.custInfo ci WITH(NOLOCK) ON d.AgentID=ci.custid
		WHERE ci.srecommend=@srecommend AND d.SportType=43 AND d.AgentPT NOT IN(85,88,91,92.5)
			AND d.AgentID NOT IN(SELECT CustID FROM #Trade)		
	END
	IF @RuleId IN (0,57)
	BEGIN		
		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 57,1,911,c.custid,NULL,s.HousePT,NULL,GETDATE(),NULL
		FROM CheckCustDB.dbo.CustInfo c WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.TradeComm s WITH(NOLOCK) ON c.custid=s.AgentID 	
		WHERE c.srecommend=@srecommend AND s.HousePT<>1				
	END

	IF @RuleId IN (0,59)
	BEGIN		
	
		INSERT INTO [dbo].CheckPTResult_Deposit(RuleID,[SportType],[BetType],[CustIdA],[CustIdB],[ValueA],[ValueB],[CreatedDate],[IsLive])
		SELECT 59,1,911,c.custid,NULL,NULL,NULL,GETDATE(),NULL
		FROM CheckCustDB.dbo.CustInfo c WITH(NOLOCK)		
			INNER JOIN CheckCustDB.dbo.Dep_CustProductSetting s WITH(NOLOCK) ON c.custid=s.CustID 	
		WHERE c.srecommend=@srecommend AND s.ProductId=25 AND s.IsEnabled=1
			AND c.custid NOT IN(SELECT custid FROM #Trade)		
			AND c.recommend NOT IN(SELECT AgentID FROM CheckCustDB.dbo.TradeComm WITH(NOLOCK) )		
			AND c.mrecommend NOT IN(SELECT custid FROM #Dummy)							
	END
END
	
