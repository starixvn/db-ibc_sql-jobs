/*<info serverAlias="DBCHECK-CheckResultDB" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_CheckPT_DCS]  
(	@custid INT
	,@roleid TINYINT  
	,@SportType SMALLINT = 0  
	,@RuleId SMALLINT = 0  
 )
WITH RECOMPILE
AS  
/*  
	Created: 20151103@Helen
	Task: Monthly check PT setting for DCS  
	DB: DBCHECK/CheckResultDB  

	Revisions:  
		- 20161229@Elodie: Get MaxPT from ProductSettingDetail
		- 20170508@Elodie: Count PT Setting rows
		- 20180807@Elodie: Apply f_GetSportNotOffer function
		- 20190610@Johnson: add rule 36,37 for dummy super [redmine: #114675]
		- 20200422@Elodie: Apply rule 72 S4 = M4 = A4 = 0 [Redmine: #132604]
		- 20200429@Elodie: Apply DummyProduct term
		- 20200820@Johnson: add new settingtype = 18 for PT [redmine:#140011]
		- 20201211@Winfred: Change data type for PT [redmine:#140011]
		- 20220407@Winfred: Exclude Inactive Site MA and Member [redmine:#171114]
		- 20220615@Tacy: Hot modify Select Into statement to avoid dump [Redmine: #174035]
		- 20220627@Eden:  Implement the dependency between Macau Games Product Status and Jackpot Status [Redmine: #171715]
		- 20221003@Elodie: Only check setting for product already released production [Redmine: #178617]
		- 20230511@Eden: Ignore check missing sport setting if hidden [Redmine: #179711]

	Param's Explanation:   
	 @RuleId = 0 : 'all'  
	 @RuleId IN (1->29)  
	
	TRUNCATE TABLE CheckPTResult_Credit  
	
	SELECT * from CheckPTResult_Credit (NOLOCK)  
	
	Step 1: Detect wrong PT and save them into CheckPTResult_Credit
		EXEC DBA_CheckPT_DCS_TESTING @srecommend = 15		  
	Step 2: SELECT * from CheckPTResult_Credit (NOLOCK) 
	
	CheckCustDB.dbo.[CustPTSetting3rd_Member]
			[CustPTSetting3rd_Agent]
			[CustPTGroupSetting3rd_Member]
			[CustSettingMode3rd]
*/  
	
BEGIN   	
	SET NOCOUNT ON   
	DECLARE @srecommend INT = 0, 
			@mrecommend INT = 0, 
			@recommend INT = 0
	
	IF @roleid = 4
		SELECT @srecommend = @custid
	ELSE IF @roleid = 3
		SELECT @srecommend = srecommend FROM CheckCustDB.dbo.CustInfo WITH (NOLOCK) WHERE custid = @custid
	ELSE IF @roleid = 2
		SELECT @srecommend = srecommend, @mrecommend = mrecommend FROM CheckCustDB.dbo.CustInfo WITH (NOLOCK) WHERE custid = @custid
	ELSE 
		SELECT @srecommend = srecommend, @mrecommend = mrecommend, @recommend = recommend FROM CheckCustDB.dbo.CustInfo WITH (NOLOCK) WHERE custid = @custid
	
	-- Starting DATA PREPARATION
	--TRUNCATE TABLE CheckPTResult_Credit	
	CREATE TABLE #MemberPT (CustID INT, recommend INT, mrecommend INT, srecommend INT, sporttype SMALLINT, bettype SMALLINT, IsLive BIT, SuperPT SMALLMONEY, MasterPT SMALLMONEY, AgentPT SMALLMONEY, IsAutoMasterPT BIT, AutoMasterPT SMALLMONEY, IsAutoSuperPT BIT, AutoSuperPT SMALLMONEY, IsGroup BIT)
	CREATE TABLE #AgentPT (CustID INT, recommend INT, mrecommend INT, srecommend INT, sporttype SMALLINT, bettype SMALLINT, IsLive BIT, SuperPT SMALLMONEY, MasterPT SMALLMONEY, AgentPT SMALLMONEY, IsAutoMasterPT BIT, AutoMasterPT SMALLMONEY, IsAutoSuperPT BIT, AutoSuperPT SMALLMONEY, MinPT SMALLMONEY, MaxPT SMALLMONEY)
	CREATE TABLE #MasterPT (CustID INT, recommend INT, mrecommend INT, srecommend INT, sporttype SMALLINT, bettype SMALLINT, IsLive BIT, SuperPT SMALLMONEY, MasterPT SMALLMONEY, AgentPT SMALLMONEY, IsAutoMasterPT BIT, AutoMasterPT SMALLMONEY, IsAutoSuperPT BIT, AutoSuperPT SMALLMONEY, MinPT SMALLMONEY, MaxPT SMALLMONEY)
	CREATE TABLE #SuperPT (CustID INT, recommend INT, mrecommend INT, srecommend INT, sporttype SMALLINT, bettype SMALLINT, IsLive BIT, SuperPT SMALLMONEY, MasterPT SMALLMONEY, AgentPT SMALLMONEY, IsAutoMasterPT BIT, AutoMasterPT SMALLMONEY, IsAutoSuperPT BIT, AutoSuperPT SMALLMONEY, MinPT SMALLMONEY, MaxPT SMALLMONEY)

	CREATE TABLE #MemberPT_NotSynced (CustID INT, sporttype SMALLINT, bettype SMALLINT, IsLive BIT)
	CREATE TABLE #AgentPT_NotSynced (CustID INT, sporttype SMALLINT, bettype SMALLINT, IsLive BIT)
	CREATE TABLE #MasterPT_NotSynced (CustID INT, sporttype SMALLINT, bettype SMALLINT, IsLive BIT)
	CREATE TABLE #SuperPT_NotSynced (CustID INT, sporttype SMALLINT, bettype SMALLINT, IsLive BIT)
	
	CREATE TABLE #DirectMaster (CustID INT)

	CREATE TABLE #MemberMissSetting (custid INT)
	CREATE TABLE #AgentMissSetting (custid INT)
	CREATE TABLE #MasterMissSetting (custid INT)
	CREATE TABLE #SuperMissSetting (custid INT)
	
	DECLARE @isDummySuper BIT = 0
	
	INSERT INTO #DirectMaster(custid)
	SELECT custid
	FROM CheckCustDB.dbo.custInfo ci WITH(NOLOCK) 										
	WHERE  EXISTS (SELECT custid 
					FROM CheckCustDB.dbo.CustDirectAccount WITH(NOLOCK) 
					WHERE CustID = ci.custid)													
		AND ci.roleid=3 
		AND ci.srecommend = @srecommend
	
	IF @@rowcount > 0	
		SELECT @isDummySuper = 1
		
	INSERT INTO #MemberPT (CustID, recommend,mrecommend,srecommend,SportType,BetType,IsLive,SuperPT,MasterPT,AgentPT,IsAutoMasterPT,AutoMasterPT,IsAutoSuperPT,AutoSuperPT,IsGroup)
	SELECT cs.CustID,ci.recommend,ci.mrecommend,ci.srecommend, cs.SportType,cs.BetType,cs.IsLive,cs.SuperPT,cs.MasterPT,cs.AgentPT,cs.IsAutoMasterPT,cs.AutoMasterPT,cs.IsAutoSuperPT,cs.AutoSuperPT,0 IsGroup
	FROM CheckCustDB.dbo.CustInfo ci
		INNER JOIN 	CheckCustDB.dbo.customer c 	 WITH (NOLOCK) ON ci.CustID = c.CustID
		INNER JOIN CheckCustDB.dbo.CustPTSetting3rd_Member cs WITH (NOLOCK) ON ci.CustID = cs.CustID
		INNER JOIN CheckCustDB.dbo.CustProductStatus stt WITH (NOLOCK) ON ci.CustID = stt.CustID
		LEFT JOIN CheckCustDB.dbo.ProductStatusProfile prf WITH(NOLOCK) ON prf.Sporttype = cs.sporttype AND prf.bettype = cs.bettype
	WHERE ci.srecommend = @srecommend  
			AND ci.mrecommend = CASE WHEN @mrecommend = 0 THEN ci.mrecommend ELSE @mrecommend END
			AND	NOT EXISTS (SELECT 1 FROM dbo.f_GetSiteNotOffer() AS nos WHERE nos.site = c.site)
			AND ci.recommend = CASE WHEN @recommend = 0 THEN ci.recommend ELSE @recommend END
			AND ci.custid = CASE WHEN @roleid = 1 THEN @custid ELSE ci.custid END
			AND ci.roleid = 1  
			AND ci.Enabled = 1
			AND ci.Currency NOT IN (20,27,28)     
			AND cs.SportType = CASE WHEN @SportType = 0 then cs.SportType  ELSE @SportType END 
			AND cs.SportType NOT IN (SELECT sporttype FROM f_GetSportNotOffer ('CustSettingDCS')) 
			AND (
					ISNULL(bitmapOrder,0) < 5 --From VB onwards
					OR 
					CASE substring(bitmapHasSynced, 1+((bitmapOrder-1)/8), 1) & POWER(2, (bitmapOrder-1)%8) WHEN 0 THEN 0 ELSE 1 END = 1		 
				)
	
	INSERT INTO #MemberPT (CustID, recommend,mrecommend,srecommend,SportType,BetType,IsLive,SuperPT,MasterPT,AgentPT,IsAutoMasterPT,AutoMasterPT,IsAutoSuperPT,AutoSuperPT,IsGroup)
	SELECT ci.CustID,ci.recommend,ci.mrecommend,ci.srecommend, cs.SportType,cs.BetType,cs.IsLive,cs.SuperPT,cs.MasterPT,cs.AgentPT,cs.IsAutoMasterPT,cs.AutoMasterPT,cs.IsAutoSuperPT,cs.AutoSuperPT,1
	FROM CheckCustDB.dbo.CustInfo ci
		INNER JOIN 	CheckCustDB.dbo.customer c 	 WITH (NOLOCK) ON ci.CustID = c.CustID
		INNER JOIN CheckCustDB.dbo.CustSettingMode3rd csm WITH (NOLOCK) ON ci.custid = csm.CustID AND csm.IsGrouped = 1
		INNER JOIN CheckCustDB.dbo.CustPTGroupSetting3rd_Member cs WITH (NOLOCK) ON cs.AgentID = ci.recommend  
		INNER JOIN CheckCustDB.dbo.CustProductStatus stt WITH (NOLOCK) ON ci.CustID = stt.CustID
		LEFT JOIN CheckCustDB.dbo.ProductStatusProfile prf WITH(NOLOCK) ON prf.Sporttype = cs.sporttype AND prf.bettype = cs.bettype
	WHERE ci.srecommend = @srecommend  
			AND	NOT EXISTS (SELECT 1 FROM dbo.f_GetSiteNotOffer() AS nos WHERE nos.site = c.site)
			AND ci.mrecommend = CASE WHEN @mrecommend = 0 THEN ci.mrecommend ELSE @mrecommend END
			AND ci.recommend = CASE WHEN @recommend = 0 THEN ci.recommend ELSE @recommend END
			AND ci.custid = CASE WHEN @roleid = 1 THEN @custid ELSE ci.custid END
			AND ci.roleid = 1  
			AND ci.Enabled = 1
			AND ci.Currency NOT IN (20,27,28)     
			AND cs.SportType = CASE WHEN @SportType = 0 then cs.SportType  ELSE @SportType END 
			AND cs.SportType NOT IN (SELECT sporttype FROM f_GetSportNotOffer ('CustSettingDCS')) 
			AND (
					ISNULL(bitmapOrder,0) < 5 --From VB onwards
					OR 
					CASE substring(bitmapHasSynced, 1+((bitmapOrder-1)/8), 1) & POWER(2, (bitmapOrder-1)%8) WHEN 0 THEN 0 ELSE 1 END = 1		 
				)
	
	INSERT INTO #AgentPT (CustID, recommend,mrecommend,srecommend,SportType,BetType,IsLive,SuperPT,MasterPT,AgentPT,IsAutoMasterPT,AutoMasterPT,IsAutoSuperPT,AutoSuperPT, MinPT, MaxPT)			
	SELECT cs.CustID,ci.recommend,ci.mrecommend,ci.srecommend, cs.SportType,cs.BetType,cs.IsLive,cs.SuperPT,cs.MasterPT,cs.AgentPT,cs.IsAutoMasterPT,cs.AutoMasterPT,cs.IsAutoSuperPT,cs.AutoSuperPT,cs.MinPT,cs.MaxPT
	FROM CheckCustDB.dbo.CustInfo ci
		INNER JOIN 	CheckCustDB.dbo.customer c 	 WITH (NOLOCK) ON ci.CustID = c.CustID
		INNER JOIN CheckCustDB.dbo.CustPTSetting3rd_Agent cs WITH (NOLOCK) ON ci.CustID = cs.CustID
		INNER JOIN CheckCustDB.dbo.CustProductStatus stt WITH (NOLOCK) ON ci.CustID = stt.CustID
		LEFT JOIN CheckCustDB.dbo.ProductStatusProfile prf WITH(NOLOCK) ON prf.Sporttype = cs.sporttype AND prf.bettype = cs.bettype
	WHERE ci.srecommend = @srecommend 
			AND	NOT EXISTS (SELECT 1 FROM dbo.f_GetSiteNotOffer() AS nos WHERE nos.site = c.site)
			AND ci.mrecommend = CASE WHEN @mrecommend = 0 THEN ci.mrecommend ELSE @mrecommend END
			AND ci.recommend = CASE WHEN @recommend = 0 THEN ci.recommend ELSE @recommend END
			AND ci.roleid = 2  
			AND ci.Enabled = 1
			AND ci.Currency NOT IN (20,27,28)     
			AND cs.SportType = CASE WHEN @SportType = 0 then cs.SportType  ELSE @SportType END 
			AND cs.SportType NOT IN (SELECT sporttype FROM f_GetSportNotOffer ('CustSettingDCS')) 
			AND (
					ISNULL(bitmapOrder,0) < 5 --From VB onwards
					OR 
					CASE substring(bitmapHasSynced, 1+((bitmapOrder-1)/8), 1) & POWER(2, (bitmapOrder-1)%8) WHEN 0 THEN 0 ELSE 1 END = 1		 
				)
	
	INSERT INTO #MasterPT (CustID, recommend,mrecommend,srecommend,SportType,BetType,IsLive,SuperPT,MasterPT,AgentPT,IsAutoMasterPT,AutoMasterPT,IsAutoSuperPT,AutoSuperPT,MinPT,MaxPT)			
	SELECT cs.CustID,ci.recommend,ci.mrecommend,ci.srecommend, cs.SportType,cs.BetType,cs.IsLive,cs.SuperPT,cs.MasterPT,cs.AgentPT,cs.IsAutoMasterPT,cs.AutoMasterPT,cs.IsAutoSuperPT,cs.AutoSuperPT,cs.MinPT,cs.MaxPT
	FROM CheckCustDB.dbo.CustInfo ci
		INNER JOIN 	CheckCustDB.dbo.customer c 	 WITH (NOLOCK) ON ci.CustID = c.CustID
		INNER JOIN CheckCustDB.dbo.CustPTSetting3rd_Agent cs WITH (NOLOCK) ON ci.CustID = cs.CustID
		INNER JOIN CheckCustDB.dbo.CustProductStatus stt WITH (NOLOCK) ON ci.CustID = stt.CustID
		LEFT JOIN CheckCustDB.dbo.ProductStatusProfile prf WITH(NOLOCK) ON prf.Sporttype = cs.sporttype AND prf.bettype = cs.bettype
	WHERE ci.srecommend = @srecommend 
			AND	NOT EXISTS (SELECT 1 FROM dbo.f_GetSiteNotOffer() AS nos WHERE nos.site = c.site) 
			AND ci.mrecommend = CASE WHEN @mrecommend = 0 THEN ci.mrecommend ELSE @mrecommend END
			AND ci.roleid = 3  
			AND ci.Enabled = 1
			AND ci.Currency NOT IN (20,27,28)     
			AND cs.SportType = CASE WHEN @SportType = 0 then cs.SportType  ELSE @SportType END 
			AND cs.SportType NOT IN (SELECT sporttype FROM f_GetSportNotOffer ('CustSettingDCS')) 
			AND (
					ISNULL(bitmapOrder,0) < 5 --From VB onwards
					OR 
					CASE substring(bitmapHasSynced, 1+((bitmapOrder-1)/8), 1) & POWER(2, (bitmapOrder-1)%8) WHEN 0 THEN 0 ELSE 1 END = 1		 
				)
	
	INSERT INTO #SuperPT (CustID, SportType,BetType,IsLive,SuperPT,MasterPT,AgentPT,IsAutoMasterPT,AutoMasterPT,IsAutoSuperPT,AutoSuperPT,MinPT,MaxPT)			
	SELECT cs.CustID, cs.SportType,cs.BetType,cs.IsLive,cs.SuperPT,cs.MasterPT,cs.AgentPT,cs.IsAutoMasterPT,cs.AutoMasterPT,cs.IsAutoSuperPT,cs.AutoSuperPT,cs.MinPT,cs.MaxPT
	FROM CheckCustDB.dbo.CustInfo ci
		INNER JOIN 	CheckCustDB.dbo.customer c 	 WITH (NOLOCK) ON ci.CustID = c.CustID
		INNER JOIN CheckCustDB.dbo.CustPTSetting3rd_Agent cs WITH (NOLOCK) ON ci.CustID = cs.CustID
		INNER JOIN CheckCustDB.dbo.CustProductStatus stt WITH (NOLOCK) ON ci.CustID = stt.CustID
		LEFT JOIN CheckCustDB.dbo.ProductStatusProfile prf WITH(NOLOCK) ON prf.Sporttype = cs.sporttype AND prf.bettype = cs.bettype
	WHERE ci.srecommend = @srecommend  
			AND	NOT EXISTS (SELECT 1 FROM dbo.f_GetSiteNotOffer() AS nos WHERE nos.site = c.site) 
			AND ci.roleid = 4  
			AND ci.Enabled = 1
			AND ci.Currency NOT IN (20,27,28)     
			AND cs.SportType = CASE WHEN @SportType = 0 then cs.SportType  ELSE @SportType END 
			AND cs.SportType NOT IN (SELECT sporttype FROM f_GetSportNotOffer ('CustSettingDCS')) 
			AND (
					ISNULL(bitmapOrder,0) < 5 --From VB onwards
					OR 
					CASE substring(bitmapHasSynced, 1+((bitmapOrder-1)/8), 1) & POWER(2, (bitmapOrder-1)%8) WHEN 0 THEN 0 ELSE 1 END = 1		 
				)
	
	INSERT INTO #MemberPT_NotSynced (CustID, SportType,BetType,IsLive)
	SELECT cs.CustID,cs.SportType,cs.BetType,cs.IsLive
	FROM CheckCustDB.dbo.CustInfo ci
		INNER JOIN 	CheckCustDB.dbo.customer c 	 WITH (NOLOCK) ON ci.CustID = c.CustID
		INNER JOIN CheckCustDB.dbo.CustPTSetting3rd_Member cs WITH (NOLOCK) ON ci.CustID = cs.CustID
		INNER JOIN CheckCustDB.dbo.CustProductStatus stt WITH (NOLOCK) ON ci.CustID = stt.CustID
		LEFT JOIN CheckCustDB.dbo.ProductStatusProfile prf WITH(NOLOCK) ON prf.Sporttype = cs.sporttype AND prf.bettype = cs.bettype
	WHERE ci.srecommend = @srecommend  
			AND	NOT EXISTS (SELECT 1 FROM dbo.f_GetSiteNotOffer() AS nos WHERE nos.site = c.site) 
			AND ci.mrecommend = CASE WHEN @mrecommend = 0 THEN ci.mrecommend ELSE @mrecommend END
			AND ci.recommend = CASE WHEN @recommend = 0 THEN ci.recommend ELSE @recommend END
			AND ci.custid = CASE WHEN @roleid = 1 THEN @custid ELSE ci.custid END
			AND ci.roleid = 1  
			AND ci.Enabled = 1
			AND ci.Currency NOT IN (20,27,28)     
			AND cs.SportType = CASE WHEN @SportType = 0 then cs.SportType  ELSE @SportType END 
			AND cs.SportType NOT IN (SELECT sporttype FROM f_GetSportNotOffer ('CustSettingDCS')) 
			AND ISNULL(bitmapOrder,0) >= 5 --From VB onwards
			AND CASE substring(bitmapHasSynced, 1+((bitmapOrder-1)/8), 1) & POWER(2, (bitmapOrder-1)%8) WHEN 0 THEN 0 ELSE 1 END = 0		 
	
	INSERT INTO #MemberPT_NotSynced (CustID, SportType,BetType,IsLive)
	SELECT ci.CustID,cs.SportType,cs.BetType,cs.IsLive
	FROM CheckCustDB.dbo.CustInfo ci
		INNER JOIN 	CheckCustDB.dbo.customer c 	 WITH (NOLOCK) ON ci.CustID = c.CustID
		INNER JOIN CheckCustDB.dbo.CustSettingMode3rd csm WITH (NOLOCK) ON ci.custid = csm.CustID AND csm.IsGrouped = 1
		INNER JOIN CheckCustDB.dbo.CustPTGroupSetting3rd_Member cs WITH (NOLOCK) ON cs.AgentID = ci.recommend  
		INNER JOIN CheckCustDB.dbo.CustProductStatus stt WITH (NOLOCK) ON ci.CustID = stt.CustID
		LEFT JOIN CheckCustDB.dbo.ProductStatusProfile prf WITH(NOLOCK) ON prf.Sporttype = cs.sporttype AND prf.bettype = cs.bettype
	WHERE ci.srecommend = @srecommend 
			AND	NOT EXISTS (SELECT 1 FROM dbo.f_GetSiteNotOffer() AS nos WHERE nos.site = c.site)  
			AND ci.mrecommend = CASE WHEN @mrecommend = 0 THEN ci.mrecommend ELSE @mrecommend END
			AND ci.recommend = CASE WHEN @recommend = 0 THEN ci.recommend ELSE @recommend END
			AND ci.custid = CASE WHEN @roleid = 1 THEN @custid ELSE ci.custid END
			AND ci.roleid = 1  
			AND ci.Enabled = 1
			AND ci.Currency NOT IN (20,27,28)     
			AND cs.SportType = CASE WHEN @SportType = 0 then cs.SportType  ELSE @SportType END 
			AND cs.SportType NOT IN (SELECT sporttype FROM f_GetSportNotOffer ('CustSettingDCS')) 
			AND ISNULL(bitmapOrder,0) >= 5 --From VB onwards
			AND CASE substring(bitmapHasSynced, 1+((bitmapOrder-1)/8), 1) & POWER(2, (bitmapOrder-1)%8) WHEN 0 THEN 0 ELSE 1 END = 0	
	
	INSERT INTO #AgentPT_NotSynced (CustID, SportType,BetType,IsLive)			
	SELECT cs.CustID,cs.SportType,cs.BetType,cs.IsLive
	FROM CheckCustDB.dbo.CustInfo ci
		INNER JOIN 	CheckCustDB.dbo.customer c 	 WITH (NOLOCK) ON ci.CustID = c.CustID
		INNER JOIN CheckCustDB.dbo.CustPTSetting3rd_Agent cs WITH (NOLOCK) ON ci.CustID = cs.CustID
		INNER JOIN CheckCustDB.dbo.CustProductStatus stt WITH (NOLOCK) ON ci.CustID = stt.CustID
		LEFT JOIN CheckCustDB.dbo.ProductStatusProfile prf WITH(NOLOCK) ON prf.Sporttype = cs.sporttype AND prf.bettype = cs.bettype
	WHERE ci.srecommend = @srecommend 
			AND	NOT EXISTS (SELECT 1 FROM dbo.f_GetSiteNotOffer() AS nos WHERE nos.site = c.site)
			AND ci.mrecommend = CASE WHEN @mrecommend = 0 THEN ci.mrecommend ELSE @mrecommend END
			AND ci.recommend = CASE WHEN @recommend = 0 THEN ci.recommend ELSE @recommend END
			AND ci.roleid = 2  
			AND ci.Enabled = 1
			AND ci.Currency NOT IN (20,27,28)     
			AND cs.SportType = CASE WHEN @SportType = 0 then cs.SportType  ELSE @SportType END 
			AND cs.SportType NOT IN (SELECT sporttype FROM f_GetSportNotOffer ('CustSettingDCS')) 
			AND ISNULL(bitmapOrder,0) >= 5 --From VB onwards
			AND CASE substring(bitmapHasSynced, 1+((bitmapOrder-1)/8), 1) & POWER(2, (bitmapOrder-1)%8) WHEN 0 THEN 0 ELSE 1 END = 0	
	
	INSERT INTO #MasterPT_NotSynced (CustID, SportType,BetType,IsLive)			
	SELECT cs.CustID,cs.SportType,cs.BetType,cs.IsLive
	FROM CheckCustDB.dbo.CustInfo ci
		INNER JOIN 	CheckCustDB.dbo.customer c 	 WITH (NOLOCK) ON ci.CustID = c.CustID
		INNER JOIN CheckCustDB.dbo.CustPTSetting3rd_Agent cs WITH (NOLOCK) ON ci.CustID = cs.CustID
		INNER JOIN CheckCustDB.dbo.CustProductStatus stt WITH (NOLOCK) ON ci.CustID = stt.CustID
		LEFT JOIN CheckCustDB.dbo.ProductStatusProfile prf WITH(NOLOCK) ON prf.Sporttype = cs.sporttype AND prf.bettype = cs.bettype
	WHERE ci.srecommend = @srecommend 
			AND	NOT EXISTS (SELECT 1 FROM dbo.f_GetSiteNotOffer() AS nos WHERE nos.site = c.site) 
			AND ci.mrecommend = CASE WHEN @mrecommend = 0 THEN ci.mrecommend ELSE @mrecommend END
			AND ci.roleid = 3  
			AND ci.Enabled = 1
			AND ci.Currency NOT IN (20,27,28)     
			AND cs.SportType = CASE WHEN @SportType = 0 then cs.SportType  ELSE @SportType END 
			AND cs.SportType NOT IN (SELECT sporttype FROM f_GetSportNotOffer ('CustSettingDCS')) 
			AND ISNULL(bitmapOrder,0) >= 5 --From VB onwards
			AND CASE substring(bitmapHasSynced, 1+((bitmapOrder-1)/8), 1) & POWER(2, (bitmapOrder-1)%8) WHEN 0 THEN 0 ELSE 1 END = 0	
	
	INSERT INTO #SuperPT_NotSynced (CustID, SportType,BetType,IsLive)			
	SELECT cs.CustID, cs.SportType,cs.BetType,cs.IsLive
	FROM CheckCustDB.dbo.CustInfo ci
		INNER JOIN 	CheckCustDB.dbo.customer c 	 WITH (NOLOCK) ON ci.CustID = c.CustID
		INNER JOIN CheckCustDB.dbo.CustPTSetting3rd_Agent cs WITH (NOLOCK) ON ci.CustID = cs.CustID
		INNER JOIN CheckCustDB.dbo.CustProductStatus stt WITH (NOLOCK) ON ci.CustID = stt.CustID
		LEFT JOIN CheckCustDB.dbo.ProductStatusProfile prf WITH(NOLOCK) ON prf.Sporttype = cs.sporttype AND prf.bettype = cs.bettype
	WHERE ci.srecommend = @srecommend 
			AND	NOT EXISTS (SELECT 1 FROM dbo.f_GetSiteNotOffer() AS nos WHERE nos.site = c.site)  
			AND ci.roleid = 4  
			AND ci.Enabled = 1
			AND ci.Currency NOT IN (20,27,28)     
			AND cs.SportType = CASE WHEN @SportType = 0 then cs.SportType  ELSE @SportType END 
			AND cs.SportType NOT IN (SELECT sporttype FROM f_GetSportNotOffer ('CustSettingDCS')) 
			AND ISNULL(bitmapOrder,0) >= 5 --From VB onwards
			AND CASE substring(bitmapHasSynced, 1+((bitmapOrder-1)/8), 1) & POWER(2, (bitmapOrder-1)%8) WHEN 0 THEN 0 ELSE 1 END = 0	

	CREATE CLUSTERED INDEX CIX_MemberPT ON #MemberPT(CustID, sporttype, bettype)
	CREATE CLUSTERED INDEX CIX_AgentPT ON #AgentPT(CustID, sporttype, bettype)
	CREATE CLUSTERED INDEX CIX_MasterPT ON #MasterPT(CustID, sporttype, bettype)
	CREATE CLUSTERED INDEX CIX_SuperPT ON #SuperPT(CustID, sporttype, bettype)
	CREATE CLUSTERED INDEX CIX_MemberPT_NotSynced ON #MemberPT_NotSynced(CustID, sporttype, bettype)
	CREATE CLUSTERED INDEX CIX_AgentPT_NotSynced ON #AgentPT_NotSynced(CustID, sporttype, bettype)
	CREATE CLUSTERED INDEX CIX_MasterPT_NotSynced ON #MasterPT_NotSynced(CustID, sporttype, bettype)
	CREATE CLUSTERED INDEX CIX_SuperPT_NotSynced ON #SuperPT_NotSynced(CustID, sporttype, bettype)

	DECLARE @_Site VARCHAR(10), @_SiteID INT, @_Currency TINYINT
	CREATE TABLE #ProductSetting(
		[SportType] [smallint] NOT NULL,
		[BetType] [smallint] NOT NULL,
		[IsLive] [bit] NOT NULL,
		[BitmapOrder] [TINYINT] 
	)
	CREATE TABLE #OfferedProductList(
		[ProductID] [tinyint] NOT NULL,
		[SportType] [smallint] NOT NULL,
		[BetType] [smallint] NOT NULL,
		[IsHidden] [BIT] NOT NULL
	)

	SELECT @_Site = Site, @_Currency = currency FROM CheckCustDB.dbo.Customer WITH(NOLOCK) WHERE CustID = @srecommend
	SELECT @_SiteID = siteid FROM CheckCustDB.dbo.Site WITH(NOLOCK) WHERE site = @_Site

	INSERT INTO #OfferedProductList (ProductID, SportType, BetType, IsHidden)
	SELECT DISTINCT ps.RealProductId, ps.SportType, ps.BetType, ps.IsHidden
	FROM CheckCustDB.dbo.ProductSettingDetail ps WITH (NOLOCK)
		INNER JOIN CheckCustDB.dbo.ProductSettingType s WITH (NOLOCK)
		ON ps.SettingType = s.SettingType
	WHERE s.SettingName = 'Product Status'  
		AND ps.SettingStatus = 0
		
	UPDATE op
	SET op.IsHidden = stt.IsHidden
	FROM #OfferedProductList op
		INNER JOIN CheckCustDB.dbo.ProductStatusSiteCurrency stt WITH(NOLOCK) ON op.SportType = stt.SportType AND op.Bettype = stt.Bettype
	WHERE stt.Currency = @_Currency AND (stt.SiteID = @_SiteID OR stt.SiteID = 0)
			
	UPDATE op
	SET op.IsHidden = stt.IsHidden
	FROM #OfferedProductList op
		INNER JOIN CheckCustDB.dbo.ProductStatusSiteCurrency stt WITH(NOLOCK) ON op.SportType = stt.SportType AND op.Bettype = stt.Bettype
	WHERE (stt.Currency = @_Currency OR stt.Currency = 0 ) AND stt.SiteID = @_SiteID

	UPDATE op
	SET op.IsHidden = CASE WHEN @_Site = 'IMBC' THEN 0 ELSE 1 END
	FROM #OfferedProductList op
	WHERE ProductID = 20

	INSERT #ProductSetting(SportType,BetType,IsLive)
	SELECT ps.SportType
			,ps.BetType
			,IsLive
	FROM CheckCustDB.[dbo].[ProductSettingDetail] ps WITH(NOLOCK)
		INNER JOIN (SELECT DISTINCT ProductID, IsHidden FROM #OfferedProductList WITH (NOLOCK)) op ON ps.RealProductId = op.ProductID
	WHERE op.IsHidden = 0 AND SettingType IN (1 ,18)
		AND ps.SettingStatus = 0
	-- End of DATA PREPARATION			
	
	UPDATE t
	SET t.BitmapOrder = pl.bitmapOrder
	FROM #ProductSetting t
		INNER JOIN CheckCustDB.dbo.ProductStatusProfile pl WITH(NOLOCK) 
			ON pl.sporttype = t.sporttype 
			AND pl.bettype = t.bettype

	
	-- Starting check PT Rule
	---- Count PT setting rows
	DECLARE @RowCount TINYINT

	SELECT @RowCount = COUNT(1)
	FROM #ProductSetting
	WHERE SportType = CASE WHEN @SportType = 0 then SportType  ELSE @SportType END 
		AND SportType NOT IN (SELECT sporttype FROM f_GetSportNotOffer ('CustSettingDCS')) 

	INSERT INTO #MemberMissSetting
	SELECT custid
	FROM (SELECT custid FROM #MemberPT UNION ALL SELECT custid FROM #MemberPT_NotSynced) cs
	GROUP BY CustID
	HAVING COUNT(1)<@RowCount

	INSERT INTO #AgentMissSetting
	SELECT custid	
	FROM (SELECT custid FROM #AgentPT UNION ALL SELECT custid FROM #AgentPT_NotSynced) cs
	GROUP BY CustID
	HAVING COUNT(1)<@RowCount

	INSERT INTO #MasterMissSetting
	SELECT custid
	FROM (SELECT custid FROM #MasterPT UNION ALL SELECT custid FROM #MasterPT_NotSynced) cs
	GROUP BY CustID
	HAVING COUNT(1)<@RowCount

	INSERT INTO #SuperMissSetting
	SELECT custid
	FROM (SELECT custid FROM #SuperPT UNION ALL SELECT custid FROM #SuperPT_NotSynced) cs
	GROUP BY CustID
	HAVING COUNT(1)<@RowCount
	
	--Miss all Sportbook setting
	INSERT INTO #MemberMissSetting (CustID)	
	SELECT ci.CustID
	FROM CheckCustDB.dbo.custInfo ci WITH (NOLOCK)
		INNER JOIN 	CheckCustDB.dbo.customer c 	 WITH (NOLOCK) ON ci.CustID = c.CustID
	WHERE ci.srecommend = @srecommend  
		AND	NOT EXISTS (SELECT 1 FROM dbo.f_GetSiteNotOffer() AS nos WHERE nos.site = c.site)
		AND ci.mrecommend = CASE WHEN @mrecommend = 0 THEN ci.mrecommend ELSE @mrecommend END
		AND ci.recommend = CASE WHEN @recommend = 0 THEN ci.recommend ELSE @recommend END
		AND ci.custid = CASE WHEN @roleid = 1 THEN @custid ELSE ci.custid END
		AND ci.roleid = 1  
		AND ci.Enabled = 1
		AND ci.Currency NOT IN (20,27,28)   
		AND NOT EXISTS (SELECT 1 FROM #MemberPT WHERE CustID = ci.custid)
		AND NOT EXISTS (SELECT 1 FROM #MemberPT_NotSynced WHERE CustID = ci.custid)

	INSERT INTO #AgentMissSetting (CustID)	       	
	SELECT ci.CustID
	FROM CheckCustDB.dbo.custInfo ci WITH (NOLOCK)
		INNER JOIN 	CheckCustDB.dbo.customer c 	 WITH (NOLOCK) ON ci.CustID = c.CustID
	WHERE ci.srecommend = @srecommend 
		AND	NOT EXISTS (SELECT 1 FROM dbo.f_GetSiteNotOffer() AS nos WHERE nos.site = c.site)
		AND ci.mrecommend = CASE WHEN @mrecommend = 0 THEN ci.mrecommend ELSE @mrecommend END
		AND ci.recommend = CASE WHEN @recommend = 0 THEN ci.recommend ELSE @recommend END
		AND ci.roleid = 2  
		AND ci.Enabled = 1
		AND ci.Currency NOT IN (20,27,28)    
		AND NOT EXISTS (SELECT 1 FROM #AgentPT WHERE CustID = ci.custid)
		AND NOT EXISTS (SELECT 1 FROM #AgentPT_NotSynced WHERE CustID = ci.custid)

	INSERT INTO #MasterMissSetting (CustID)	  	     	
	SELECT ci.CustID
	FROM CheckCustDB.dbo.custInfo ci WITH (NOLOCK)
		INNER JOIN 	CheckCustDB.dbo.customer c 	 WITH (NOLOCK) ON ci.CustID = c.CustID
	WHERE ci.srecommend = @srecommend  
		AND	NOT EXISTS (SELECT 1 FROM dbo.f_GetSiteNotOffer() AS nos WHERE nos.site = c.site)
		AND ci.mrecommend = CASE WHEN @mrecommend = 0 THEN ci.mrecommend ELSE @mrecommend END
		AND ci.roleid = 3  
		AND ci.Enabled = 1
		AND ci.Currency NOT IN (20,27,28)      
		AND NOT EXISTS (SELECT 1 FROM #MasterPT WHERE CustID = ci.custid)
		AND NOT EXISTS (SELECT 1 FROM #MasterPT_NotSynced WHERE CustID = ci.custid)

	INSERT INTO #SuperMissSetting (CustID)	  	      	       	
	SELECT ci.CustID
	FROM CheckCustDB.dbo.custInfo ci WITH (NOLOCK)
		INNER JOIN 	CheckCustDB.dbo.customer c 	 WITH (NOLOCK) ON ci.CustID = c.CustID
	WHERE ci.srecommend = @srecommend   
		AND	NOT EXISTS (SELECT 1 FROM dbo.f_GetSiteNotOffer() AS nos WHERE nos.site = c.site) 
		AND ci.roleid = 4  
		AND ci.Enabled = 1
		AND ci.Currency NOT IN (20,27,28) 
		AND NOT EXISTS (SELECT 1 FROM #SuperPT WHERE CustID = ci.custid)
		AND NOT EXISTS (SELECT 1 FROM #SuperPT_NotSynced WHERE CustID = ci.custid)
	-- End DATA PREPARATION

	--Check a number of setting rows
	INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive) 
	SELECT	42 AS ruleid, ds.bettype, ds.sporttype, cs.CustID, cs.CustID, 0, 0, 0
	FROM	#MemberMissSetting cs
		CROSS APPLY (SELECT sporttype, bettype, IsLive,BitmapOrder FROM #ProductSetting) ds
		INNER JOIN CheckCustDB.dbo.CustProductStatus cps WITH(NOLOCK) ON cs.custid = cps.CustID 
	WHERE NOT EXISTS (SELECT 1 FROM #MemberPT WHERE CustID = cs.CustID AND sporttype = ds.sporttype AND bettype = ds.bettype)
		AND NOT EXISTS (SELECT 1 FROM #MemberPT_NotSynced WHERE CustID = cs.CustID AND sporttype = ds.sporttype AND bettype = ds.bettype)
		AND CheckCustDB.dbo.f_GetProductStatus (cps.bitmapIsHidden,ds.bitmapOrder) = 0 

	INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive) 
	SELECT	42 AS ruleid, ds.bettype, ds.sporttype, cs.CustID, cs.CustID, 0, 0, 0
	FROM	#AgentMissSetting cs
		CROSS APPLY (SELECT sporttype, bettype, IsLive,BitmapOrder FROM #ProductSetting) ds
		INNER JOIN CheckCustDB.dbo.CustProductStatus cps WITH(NOLOCK) ON cs.custid = cps.CustID  
	WHERE NOT EXISTS (SELECT 1 FROM #AgentPT WHERE CustID = cs.CustID AND sporttype = ds.sporttype AND bettype = ds.bettype)
		AND NOT EXISTS (SELECT 1 FROM #AgentPT_NotSynced WHERE CustID = cs.CustID AND sporttype = ds.sporttype AND bettype = ds.bettype)
		AND CheckCustDB.dbo.f_GetProductStatus (cps.bitmapIsHidden,ds.bitmapOrder) = 0 

	INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive) 
	SELECT	42 AS ruleid, ds.bettype, ds.sporttype, cs.CustID, cs.CustID, 0, 0, 0
	FROM	#MasterMissSetting cs
		CROSS APPLY (SELECT sporttype, bettype, IsLive,BitmapOrder FROM #ProductSetting) ds
		INNER JOIN CheckCustDB.dbo.CustProductStatus cps WITH(NOLOCK) ON cs.custid = cps.CustID  
	WHERE NOT EXISTS (SELECT 1 FROM #MasterPT WHERE CustID = cs.CustID AND sporttype = ds.sporttype AND bettype = ds.bettype)
		AND NOT EXISTS (SELECT 1 FROM #MasterPT_NotSynced WHERE CustID = cs.CustID AND sporttype = ds.sporttype AND bettype = ds.bettype)
		AND CheckCustDB.dbo.f_GetProductStatus (cps.bitmapIsHidden,ds.bitmapOrder) = 0 

	INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive) 
	SELECT	42 AS ruleid, ds.bettype, ds.sporttype, cs.CustID, cs.CustID, 0, 0, 0
	FROM	#SuperMissSetting cs
		CROSS APPLY (SELECT sporttype, bettype, IsLive,BitmapOrder FROM #ProductSetting) ds
		INNER JOIN CheckCustDB.dbo.CustProductStatus cps WITH(NOLOCK) ON cs.custid = cps.CustID 
	WHERE NOT EXISTS (SELECT 1 FROM #SuperPT WHERE CustID = cs.CustID AND sporttype = ds.sporttype AND bettype = ds.bettype)
		AND NOT EXISTS (SELECT 1 FROM #SuperPT_NotSynced WHERE CustID = cs.CustID AND sporttype = ds.sporttype AND bettype = ds.bettype)
		AND CheckCustDB.dbo.f_GetProductStatus (cps.bitmapIsHidden,ds.bitmapOrder) = 0 

	---- 1. S1 < 0 OR M1 < 0 OR A1 < 0  
	IF @RuleId IN (0,1)  
	BEGIN  
		----PRINT '1. S1 < 0 OR M1 < 0 OR A1 < 0 '  
		INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)   
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

	----2. S4 > MaxPT OR M4 > MaxPT OR A4 > MaxPT  
	IF @RuleId IN (0,2)  
	BEGIN  
		----PRINT '2. S4 > 90 OR M4 > 90 OR A4 > 90 '
		INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		SELECT 2 AS RuleId, cs.BetType, cs.SportType, cs.CustId, cs.CustId,  
			 CASE 
				WHEN cs.SuperPT > ps.MaxPT THEN cs.SuperPT
				WHEN cs.MasterPT > ps.MaxPT THEN cs.MasterPT
				WHEN cs.AgentPT > ps.MaxPT THEN cs.AgentPT   
				ELSE ps.MaxPT   
			 END,  
			 ps.MaxPT,  
			 cs.Islive
		FROM #SuperPT cs 
			INNER JOIN CheckCustDB.dbo.ProductSettingDetail ps ON cs.SportType = ps.SportType AND cs.Bettype = ps.Bettype AND cs.IsLive = ps.IsLive AND ps.Settingtype IN (1,18)
		WHERE cs.SuperPT > ps.MaxPT OR cs.MasterPT > ps.MaxPT OR cs.AgentPT > ps.MaxPT
		
	END  

	----3. S4 < M4   

	IF @RuleId IN (0,3)  
	BEGIN   
		----PRINT '3. S4 < M4 '
		INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
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
		INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		SELECT 4 as RuleId, cs.BetType, cs.SportType, cs.CustId, cs.CustId, cs.SuperPT, cs.AgentPT, cs.IsLive  
		FROM #SuperPT cs
		WHERE cs.SuperPT < cs.AgentPT
	END  
	
	----5. S4 < N4   

	IF @RuleId IN (0,5)  
	BEGIN   
		----PRINT '5. S4 < N4 '
		INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		SELECT 5 as RuleId, cs.BetType, cs.SportType, cs.CustId, cs.CustId, cs.SuperPT, cs.MinPT, cs.IsLive  
		FROM #SuperPT cs  
		WHERE cs.superPT < cs.MinPT

	END  
	

	----6. S4 < US3   
	
	IF @RuleId IN (0,6)  
	BEGIN   
		----PRINT '6. S4 < US3   '
		INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		SELECT 6 as RuleId, cs.BetType, cs.SportType, scs.CustId, cs.CustId, scs.SuperPT , cs.AutoSuperPT, cs.IsLive  
		FROM #MasterPT cs 
			JOIN #SuperPT scs ON scs.CustID = cs.srecommend  AND scs.SportType = cs.SportType  
											AND scs.BetType = cs.BetType 
											AND scs.IsLive = cs.IsLive  
		WHERE scs.SuperPT < cs.AutoSuperPT
		
	END  
	
	----7. S4 < US1   

	IF @RuleId IN (0,7)  
	BEGIN   
		----PRINT '7. S4 < US1'
		INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		SELECT 7 as RuleId, cs.BetType, cs.SportType, scs.CustId, cs.CustId, scs.SuperPT, cs.AutoSuperPT, scs.IsLive
		FROM #MemberPT cs
			INNER JOIN #SuperPT scs ON scs.CustID = cs.srecommend AND scs.SportType = cs.SportType  
											AND scs.BetType = cs.BetType 
											AND scs.IsLive = cs.IsLive 
		WHERE scs.SuperPT < cs.AutoSuperPT
		
	END  

	----8. S4 < S3 + M3   

	IF @RuleId IN (0,8)  
	BEGIN   
		----PRINT '8. S4 < S3 + M3   '
		INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		SELECT 8 as RuleId, cs.BetType, cs.SportType, scs.CustId, cs.CustId, scs.SuperPT, cs.SuperPT + cs.MasterPT, scs.IsLive  
		FROM #MasterPT cs
			INNER JOIN #SuperPT scs ON scs.CustID = cs.srecommend AND scs.SportType = cs.SportType	AND scs.BetType = cs.BetType AND scs.IsLive = cs.IsLive 
		WHERE scs.SuperPT < cs.SuperPT + cs.MasterPT
		
	END  

	----9. S4 < S1 + M1 + A1   

	IF @RuleId IN (0,9)  
	BEGIN   
		----PRINT '9. S4 < S1 + M1 + A1   '
		INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		SELECT 9 as RuleId, cs.BetType, cs.SportType, scs.CustId, cs.CustId, scs.SuperPT, cs.SuperPT + cs.MasterPT + cs.AgentPT, scs.IsLive  
		FROM #MemberPT cs
			INNER JOIN #SuperPT scs ON scs.CustID = cs.srecommend AND  scs.SportType = cs.SportType AND scs.BetType = cs.BetType AND scs.IsLive = cs.IsLive 
		WHERE scs.SuperPT < cs.SuperPT + cs.MasterPT + cs.AgentPT

	END  

	----10. N4 > S1 + M1 + A1   
	----PRINT '10. N4 > S1 + M1 + A1 '
	IF @RuleId IN (0,10)  
	BEGIN 
		INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		SELECT 10 as RuleId, cs.BetType, cs.SportType, scs.CustId, cs.CustId, scs.MinPT, cs.SuperPT + cs.MasterPT + cs.AgentPT, scs.IsLive  
		FROM #MemberPT cs
			INNER JOIN #SuperPT scs ON scs.CustID = cs.srecommend AND scs.SportType = cs.SportType AND scs.BetType = cs.BetType AND scs.IsLive = cs.IsLive  
		WHERE scs.MinPT > cs.SuperPT + cs.MasterPT + cs.AgentPT
		  
	END  


	-----------------------------------------------------------------------  
	----11. M4 < A4  

	IF @RuleId IN (0,11)  
	BEGIN   
		----PRINT '11. M4 < A4  '
		INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		SELECT 11 as RuleId, cs.BetType, cs.SportType, cs.CustId, cs.CustId, cs.MasterPT, cs.AgentPT, cs.IsLive  
		FROM #SuperPT cs 
		WHERE cs.MasterPT < cs.AgentPT
		
	END  
	----12. M4 < M3   
	IF @RuleId IN (0,12)  
	BEGIN  
		----PRINT '12. M4 < M3'
		INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		SELECT 12 as RuleId, cs.BetType, cs.SportType, scs.CustId, cs.CustId, scs.MasterPT, cs.MasterPT, scs.IsLive  
		FROM #MasterPT cs
			INNER JOIN #SuperPT scs ON scs.CustID = cs.srecommend AND scs.SportType = cs.SportType AND scs.BetType = cs.BetType AND scs.IsLive = cs.IsLive   
		WHERE scs.MasterPT < cs.MasterPT
		 
	END  
	----13. M4 < N3   

	IF @RuleId IN (0,13)  
	BEGIN  
		----PRINT '13. M4 < N3'
		INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		SELECT 13 as RuleId, scs.BetType, scs.SportType, scs.CustId, cs.CustId, scs.MasterPT , cs.MinPT, scs.IsLive  
		FROM #MasterPT cs
			INNER JOIN #SuperPT scs ON scs.CustID = cs.srecommend AND scs.SportType = cs.SportType AND scs.BetType = cs.BetType AND scs.IsLive = cs.IsLive   
		WHERE scs.MasterPT < cs.MinPT


	END  
	----14. M4 < UM2   

	IF @RuleId IN (0,14)  
	BEGIN  
		----PRINT '14. M4 < UM2 '
		INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		SELECT 14 as RuleId, cs.BetType, cs.SportType, scs.CustId, cs.CustId, scs.MasterPT, cs.AutoMasterPT, scs.IsLive  
		FROM #AgentPT cs
			INNER JOIN #SuperPT scs ON scs.CustID = cs.srecommend AND scs.SportType = cs.SportType AND scs.BetType = cs.BetType AND scs.IsLive = cs.IsLive   
		WHERE scs.MasterPT < cs.AutoMasterPT
		
	END  

	----15. M4 < UM1   

	IF @RuleId IN (0,15)  
	BEGIN  
		----PRINT '15. M4 < UM1   '
		INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		SELECT 15 as RuleId, cs.BetType, cs.SportType, scs.CustId, cs.CustId, scs.MasterPT, cs.AutoMasterPT, scs.IsLive  
		FROM #MemberPT cs
			INNER JOIN #SuperPT scs ON scs.CustID = cs.srecommend AND  scs.SportType = cs.SportType AND scs.BetType = cs.BetType AND scs.IsLive = cs.IsLive  
		WHERE scs.MasterPT < cs.AutoMasterPT
			
	END  

	----16. M4 < M1 + A1   
	
	IF @RuleId IN (0,16)  
	BEGIN  
		----PRINT '16. M4 < M1 + A1 '
		INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		SELECT 16 as RuleId, cs.BetType, cs.SportType, scs.CustId, cs.CustId, scs.MasterPT , cs.MasterPT + cs.AgentPT, scs.IsLive  
		FROM #MemberPT cs
			INNER JOIN #SuperPT scs ON scs.CustID = cs.srecommend AND  scs.SportType = cs.SportType AND scs.BetType = cs.BetType AND scs.IsLive = cs.IsLive  
		WHERE scs.MasterPT < cs.MasterPT + cs.AgentPT
	END  


	----17. M3 < N3   

	IF @RuleId IN (0,17)  
	BEGIN  
		----PRINT '17. M3 < N3   '
		
		INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		SELECT 17 as RuleId, cs.BetType, cs.SportType, cs.CustId, cs.CustId, cs.MasterPT, cs.MinPT, cs.IsLive  
		FROM #MasterPT cs
		WHERE cs.MasterPT < cs.MinPT
		
	END  

	--------------------------------------------------------------------------------------------  
	----18. M3 < M2 + A2   

	IF @RuleId IN (0,18)  
	BEGIN   
		----PRINT '18. M3 < M2 + A2   '
		
		INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		SELECT 18 as RuleId, cs.BetType, cs.SportType, scs.CustId, cs.CustId, scs.MasterPT, cs.MasterPT + cs.AgentPT, cs.IsLive  
		FROM #AgentPT cs
			INNER JOIN #MasterPT scs ON cs.mrecommend = scs.Custid AND scs.SportType = cs.SportType AND scs.BetType = cs.BetType AND scs.IsLive = cs.IsLive  
		WHERE scs.MasterPT < cs.MasterPT + cs.AgentPT
		
	END  

	----19. M3 < M1 + A1   

	IF @RuleId IN (0,19)  
	BEGIN   
		----PRINT '19. M3 < M1 + A1   '
		INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		SELECT 19 as RuleId, cs.BetType, cs.SportType, scs.CustId, cs.CustId, scs.MasterPT, cs.MasterPT + cs.AgentPT, cs.IsLive  
		FROM #MemberPT cs
			INNER JOIN #MasterPT scs ON scs.CustID = cs.mrecommend AND scs.SportType = cs.SportType AND scs.BetType = cs.BetType AND scs.IsLive = cs.IsLive  
		WHERE scs.MasterPT < cs.MasterPT + cs.AgentPT
		
	END  

	 
	----20. N3 > M1 + A1   

	IF @RuleId IN (0,20)  
	BEGIN  
		----PRINT '20. N3 > M1 + A1   '
		INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		SELECT 20 as RuleId, cs.BetType, cs.SportType, scs.CustId, cs.CustId, scs.MinPT, cs.MasterPT + cs.AgentPT, cs.IsLive  
		FROM #MemberPT cs
			INNER JOIN #MasterPT scs ON scs.CustID = cs.mrecommend AND scs.SportType = cs.SportType AND scs.BetType = cs.BetType AND scs.IsLive = cs.IsLive  
		WHERE scs.MinPT > cs.MasterPT + cs.AgentPT
		
	END    


	----21. A4 < A2  

	IF @RuleId IN (0,21)  
	BEGIN   
		----PRINT '21. A4 < A2  '
		INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLIve)  
		SELECT 21 as RuleId, cs.BetType, cs.SportType, scs.CustId, cs.CustId, scs.AgentPT, cs.AgentPT, scs.IsLive  
		FROM #AgentPT cs
			INNER JOIN #SuperPT scs ON scs.CustID = cs.srecommend AND scs.SportType = cs.SportType AND scs.BetType = cs.BetType AND scs.IsLive = cs.IsLive  
		WHERE scs.AgentPT < cs.AgentPT
		  
	END   


	----22. A4 < A1  

	IF @RuleId IN (0,22)  
	BEGIN  
		----PRINT '22. A4 < A1  '
		INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		SELECT 22 as RuleId, cs.BetType, cs.SportType, scs.CustId, cs.CustId, scs.AgentPT, cs.AgentPT, scs.IsLive  
		FROM #MemberPT cs
			INNER JOIN #SuperPT scs ON scs.CustID = cs.srecommend AND scs.SportType = cs.SportType AND scs.BetType = cs.BetType AND scs.IsLive = cs.IsLive  
		WHERE scs.AgentPT < cs.AgentPT
			
	END   

	----23. A2 < N2  

	IF @RuleId IN (0,23)  
	BEGIN   
		----PRINT '23. A2 < N2  '	
		INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		SELECT 23 as RuleId, cs.BetType, cs.SportType, cs.CustId, cs.CustId, cs.AgentPT, cs.MinPT, cs.IsLive
		FROM #AgentPT  cs
		WHERE cs.AgentPT < cs.MinPT
		  
	END   

	----24. N2 > A1  

	IF @RuleId IN (0,24)  
	BEGIN  
		----PRINT '24. N2 > A1  '
		INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		SELECT 24 as RuleId, cs.BetType, cs.SportType, scs.CustId, cs.CustId, scs.MinPT, cs.AgentPT, cs.IsLive   
		FROM #MemberPT cs
			INNER JOIN #AgentPT scs ON scs.CustID = cs.recommend AND scs.SportType = cs.SportType AND scs.BetType = cs.BetType AND scs.IsLive = cs.IsLive  
		WHERE   scs.MinPT > cs.AgentPT

		  
	END  


	---------------------------------------------------  
	---- 25. L4 < S1 + M1 + A1   
	IF @RuleId IN (0,25)  
	BEGIN   
		----PRINT '25. L4 < S1 + M1 + A1   '
		INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		SELECT 25 as RuleId, cs.BetType, cs.SportType, scs.CustId, cs.CustId, scs.MaxPT, cs.SuperPT + cs.MasterPT + cs.AgentPT, cs.IsLive  
		FROM #MemberPT cs
			INNER JOIN #SuperPT scs ON scs.CustID = cs.srecommend AND scs.SportType = cs.SportType AND scs.BetType = cs.BetType AND scs.IsLive = cs.IsLive  
		WHERE scs.MaxPT < cs.SuperPT + cs.MasterPT + cs.AgentPT

		  
	END  

	---- 26. L3 < M1 +A1  
	IF @RuleId IN (0,26)  
	BEGIN  
		----PRINT '26. L3 < M1 +A1  '
		INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		SELECT 26 as RuleId, cs.BetType, cs.SportType, scs.CustId, cs.CustId, scs.MaxPT, cs.MasterPT + cs.AgentPT, cs.IsLive  
		FROM #MemberPT cs
			INNER JOIN #MasterPT scs ON scs.CustID = cs.mrecommend AND scs.SportType = cs.SportType AND scs.BetType = cs.BetType AND scs.IsLive = cs.IsLive  
		WHERE scs.MaxPT < cs.MasterPT + cs.AgentPT
		
	END    
	---- 27. L2 < A1   
	IF @RuleId IN (0,27)  
	BEGIN  
		----PRINT '27. L2 < A1   '
		INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		SELECT 27 as RuleId, cs.BetType, cs.SportType, scs.CustId, cs.CustId, scs.MaxPT, cs.AgentPT, cs.IsLive  
		FROM #MemberPT cs
			INNER JOIN #AgentPT scs	ON scs.CustID = cs.recommend AND scs.SportType = cs.SportType AND scs.BetType = cs.BetType AND scs.IsLive = cs.IsLive  
		WHERE  scs.MaxPT < cs.AgentPT

	END  


	---- 28. MIN(S4-M1-A1, (IS1?US1,US3)) > S1  
	IF @RuleId IN (0,28)  
	BEGIN   
		----PRINT '28. MIN(S4-M1-A1, (IS1?US1,US3)) > S1  '
		INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		SELECT 28 AS RuleId, cs.BetType, cs.SportType   
				,CASE WHEN scs.SuperPT - cs.MasterPT - cs.AgentPT > (CASE WHEN cs.IsAutoSuperPT = 1 THEN cs.AutoSuperPT ELSE mcs.AutoSuperPT END)     
				  THEN ( CASE WHEN cs.IsAutoSuperPT = 1   
					  THEN cs.CustId   
					  ELSE mcs.CustId   
					END)  
				  ELSE scs.CustId  
				 END   
				,cs.CustId      
				,CASE WHEN scs.SuperPT - cs.MasterPT - cs.AgentPT > (CASE WHEN cs.IsAutoSuperPT = 1 THEN cs.AutoSuperPT ELSE mcs.AutoSuperPT END)     
				  THEN ( CASE WHEN cs.IsAutoSuperPT = 1   
					  THEN cs.AutoSuperPT   
					  ELSE mcs.AutoSuperPT   
					END)  
				  ELSE scs.SuperPT - cs.MasterPT - cs.AgentPT
				 END   
				,cs.SuperPT  
				,cs.IsLive  
		FROM #MemberPT cs WITH (NOLOCK)  
			INNER JOIN #SuperPT scs ON scs.CustID = cs.srecommend AND scs.SportType = cs.SportType  AND scs.bettype = cs.bettype  AND scs.IsLive = cs.IsLive  
			INNER JOIN #MasterPT mcs ON mcs.CustID = cs.mrecommend AND mcs.SportType = cs.SportType AND mcs.bettype = cs.bettype AND mcs.IsLive = cs.IsLive 							   
		
		WHERE (cs.IsAutoSuperPT = 1 OR mcs.IsAutoSuperPT = 1)  
			AND cs.SuperPT < CASE WHEN scs.SuperPT - cs.MasterPT - cs.AgentPT > (CASE WHEN cs.IsAutoSuperPT = 1 THEN cs.AutoSuperPT ELSE mcs.AutoSuperPT END)     
					THEN ( CASE WHEN cs.IsAutoSuperPT = 1   
						THEN cs.AutoSuperPT   
						ELSE mcs.AutoSuperPT   
					  END)  
					ELSE scs.SuperPT - cs.MasterPT - cs.AgentPT  
				   END   
				   
	END   

	
	---- 29. MIN (M4-A1, M3-A1,(IM1?UM1,UM2)) > M1 
	IF @RuleId IN (0,29)  
	BEGIN   
		----PRINT '29. MIN (M4-A1, M3-A1,(IM1?UM1,UM2)) > M1   '
		INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		SELECT 29 AS RuleId, cs.BetType, cs.SportType   
		,CASE WHEN scs.MasterPT > mcs.MasterPT   
		   THEN CASE WHEN mcs.MasterPT - cs.AgentPT > (CASE WHEN cs.IsAutoMasterPT = 1 THEN cs.AutoMasterPT ELSE acs.AutoMasterPT END)   
			 THEN (CASE WHEN cs.IsAutoMasterPT = 1   
			   THEN cs.CustId  
			   ELSE acs.CustId   
			   END  
				)  
			 ELSE mcs.CustId  
		   END  
		 ELSE   
		   CASE WHEN scs.MasterPT - cs.AgentPT > (CASE WHEN cs.IsAutoMasterPT = 1 THEN cs.AutoMasterPT ELSE acs.AutoMasterPT END)   
			 THEN (CASE WHEN cs.IsAutoMasterPT = 1   
			   THEN cs.CustId  
			   ELSE acs.CustId   
			  END  
			  )  
			 ELSE scs.CustId  
		   END  
		 END  
		,cs.CustId  
		,CASE WHEN scs.MasterPT > mcs.MasterPT   
		   THEN CASE WHEN mcs.MasterPT - cs.AgentPT > (CASE WHEN cs.IsAutoMasterPT = 1 THEN cs.AutoMasterPT ELSE acs.AutoMasterPT END)   
			 THEN (CASE WHEN cs.IsAutoMasterPT = 1   
			   THEN cs.AutoMasterPT  
			   ELSE acs.AutoMasterPT   
				END  
				)  
			 ELSE mcs.MasterPT - cs.AgentPT  
		   END  
		 ELSE   
		   CASE WHEN scs.MasterPT - cs.AgentPT > (CASE WHEN cs.IsAutoMasterPT = 1 THEN cs.AutoMasterPT ELSE acs.AutoMasterPT END)   
			 THEN (CASE WHEN cs.IsAutoMasterPT = 1   
			   THEN cs.AutoMasterPT  
			   ELSE acs.AutoMasterPT   
			  END  
			  )  
			 ELSE scs.MasterPT - cs.AgentPT  
		   END  
		 END  
		,cs.MasterPT  
		,cs.IsLive  
		FROM #MemberPT cs 
			INNER JOIN #SuperPT scs ON scs.CustID = cs.srecommend AND scs.SportType = cs.SportType AND scs.bettype = cs.bettype AND scs.IsLive = cs.IsLive
			INNER JOIN #MasterPT mcs ON mcs.CustId = cs.mrecommend AND mcs.SportType = cs.SportType AND mcs.bettype = cs.bettype AND mcs.IsLive = cs.IsLive
			INNER JOIN #AgentPT acs ON acs.CustId = cs.recommend  AND acs.SportType = cs.SportType AND acs.bettype = cs.bettype AND acs.IsLive = cs.IsLive	   		     
				   
		WHERE ( acs.IsAutoMasterPT = 1 OR cs.IsAutoMasterPT = 1 )  
			AND cs.MasterPT < CASE WHEN scs.MasterPT > mcs.MasterPT   
					 THEN CASE  WHEN mcs.MasterPT - cs.AgentPT > (CASE WHEN cs.IsAutoMasterPT = 1 THEN cs.AutoMasterPT ELSE acs.AutoMasterPT END)   
					   THEN (CASE WHEN cs.IsAutoMasterPT = 1   
						 THEN cs.AutoMasterPT  
						 ELSE acs.AutoMasterPT
						  END  
						  )  
					   ELSE mcs.MasterPT - cs.AgentPT  
					   END  
					ELSE   
					  CASE WHEN scs.MasterPT - cs.AgentPT > (CASE WHEN cs.IsAutoMasterPT = 1 THEN cs.AutoMasterPT ELSE acs.AutoMasterPT END)   
						THEN (CASE WHEN cs.IsAutoMasterPT = 1   
						  THEN cs.AutoMasterPT  
						  ELSE acs.AutoMasterPT   
						 END  
						 )  
						ELSE scs.MasterPT - cs.AgentPT  
						END  
					END  

	END   

	---- 33. PT setting of member exists in both Individual and group PT   
	IF @RuleId IN (0,33)  
	BEGIN   
		 ----PRINT ' 30. PT setting of member exists in both Individual and group PT'
		 INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		 SELECT DISTINCT 33,NULL,NULL,M.CustID,M.CustID,NULL,NULL,NULL
		 FROM #MemberPT M
		 WHERE EXISTS (SELECT 1 FROM CheckCustDB.dbo.CustPTSetting3rd_Member M1 WITH (NOLOCK) WHERE M1.CustID = M.CustID)
			   AND EXISTS (SELECT 1 FROM CheckCustDB.dbo.CustSettingMode3rd csm WITH (NOLOCK) WHERE csm.CustID = M.CustID AND csm.IsGrouped = 1)	
	END	
	
	---- 34. IsGrouped Flag = 0 but not exists in Individual PT table
	IF @RuleId IN (0,34)  
	BEGIN   
		 ----PRINT '31. IsGrouped Flag = 0 but not exists in Individual PT table'
		 INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		 SELECT DISTINCT 34,NULL,NULL,M.CustID,M.CustID,NULL,NULL,NULL
		 FROM #MemberPT M
		 WHERE EXISTS (SELECT 1 FROM CheckCustDB.dbo.CustSettingMode3rd csm WITH (NOLOCK) WHERE csm.CustID = M.CustID AND csm.IsGrouped = 0)	
			   AND NOT EXISTS (SELECT 1 FROM CheckCustDB.dbo.CustPTSetting3rd_Member M1 WITH (NOLOCK) WHERE M1.CustID = M.CustID)
			   
	END	 
	
	---- 35. IsGrouped Flag = 1 but not exists in Group PT table
	IF @RuleId IN (0,35)  
	BEGIN   
		 ----PRINT '32. IsGrouped Flag = 1 but not exists in Group PT table'
		 INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		 SELECT DISTINCT 35,NULL,NULL,M.CustID,M.CustID,NULL,NULL,NULL
		 FROM #MemberPT M
		 WHERE EXISTS (SELECT 1 FROM CheckCustDB.dbo.CustSettingMode3rd csm WITH (NOLOCK) WHERE csm.CustID = M.CustID AND csm.IsGrouped = 1)	
				AND NOT EXISTS (SELECT 1 FROM CheckCustDB.dbo.CustPTGroupSetting3rd_Member M1 WITH (NOLOCK) WHERE M1.AgentID = M.recommend)
			   
	END	 
		
	IF @isDummySuper = 1
	BEGIN
		---- 36. dummy super has s3<> 0
		IF @RuleId IN (0,36)
		BEGIN 	
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive) 
			SELECT	36 as RuleId, cs.BetType, cs.SportType, cs.CustId, cs.CustId,
					SuperPT,
					0, 
					0
			FROM #MasterPT cs
			WHERE SuperPT<>0 
				AND custid IN (SELECT custid FROM #DirectMaster)			
		END
		
		--37. dummy super has s1 <> 0
		IF @RuleId IN (0,37)
		BEGIN 	
			INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive) 
			SELECT	37 as RuleId, cs.BetType, cs.SportType, cs.CustId, cs.CustId,
					SuperPT,
					0, 
					0
			FROM #MemberPT cs
			WHERE SuperPT<>0 
				AND mrecommend IN (SELECT custid FROM #DirectMaster)			
		END
	END		
	
	---- 72. S4 = M4 = A4 = 0
	IF @RuleId IN (0,72)  
	BEGIN   
		 ----PRINT '72. S4 = M4 = A4 = 0'
		 INSERT INTO CheckPTResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB, IsLive)  
		 SELECT DISTINCT 72,bettype,sporttype,CustID,CustID,NULL,NULL,IsLive
		 FROM #SuperPT 
		 WHERE SuperPT = 0 AND MasterPT = 0 AND AgentPT = 0	   
	END	 
END