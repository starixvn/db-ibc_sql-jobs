/*<info serverAlias="DBCHECK-CheckResultDB" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_CheckComm_DCS]  
(	@srecommend INT   
	,@SportType SMALLINT = 0  
	,@RuleId SMALLINT = 0  
 )
 WITH RECOMPILE
AS  
/*  
	Created: 20170103@Elodie
	Task: Monthly check commission setting for DCS  
	DB: DBCHECK.CheckResultDB  

	Revisions:  :
		- 20171003@Johnson: Add rule 107,108,109 check comm of SMA on member [Redmine: #73556]
		- 20180807@Elodie: Apply f_GetSportNotOffer function
		- 20230728@Eden: Simplify Live Casino Customer Setting [RedmineID: #189389]
		- 20231010@Eden: DCS Sportsbook Credit[redmine: #193083]

	Param's Explanation:   
	 @RuleId = 0 : 'all'  
	 @RuleId IN (101->200)  
	
	TRUNCATE TABLE CheckCommResult_Credit  
	
	SELECT * from CheckCommResult_Credit (NOLOCK)  
	
	Step 1: Detect wrong Comm and save them into CheckCommResult_Credit
		EXEC DBA_CheckComm_DCS @srecommend = 15		  
	Step 2: SELECT * from CheckCommResult_Credit (NOLOCK) 
	
	CheckCustDB.dbo.[CustDiscount3rd_Member]
			[CustDiscount3rd_Agent]
*/  
	
BEGIN   
	
	SET NOCOUNT ON   
	
	-- Starting DATA PREPARATION
	--TRUNCATE TABLE CheckCommResult_Credit
	DECLARE @_Site VARCHAR(10), @_SiteID INT, @_Currency TINYINT
	CREATE TABLE #ProductSetting(
		[SportType] [smallint] NOT NULL,
		[BetType] [smallint] NOT NULL,
		[BitmapOrder] [TINYINT]
	)
	CREATE TABLE #OfferedProductList(
		[ProductID] [tinyint] NOT NULL,
		[SportType] [smallint] NOT NULL,
		[BetType] [smallint] NOT NULL,
		[IsHidden] [BIT] NOT NULL
	)

	CREATE TABLE #MemberComm(
		  CustID			INT
		 ,recommend			INT
		 ,mrecommend		INT
		 ,srecommend		INT
		 ,SportType			SMALLINT
		 ,BetType			SMALLINT
		 ,SuperDiscount		DECIMAL(9,8)
		 ,MasterDiscount	DECIMAL(9,8)
		 ,AgentDiscount		DECIMAL(9,8)
		 ,PlayerDiscount	DECIMAL(9,8)
		 ,ugroup			VARCHAR(3)
	)

	CREATE TABLE #AgentComm(
		  CustID			INT
		 ,mrecommend		INT
		 ,srecommend		INT
		 ,SportType			SMALLINT
		 ,BetType			SMALLINT
		 ,Discount			DECIMAL(9,8)
	)

	CREATE TABLE #MasterComm(
		  CustID			INT
		 ,srecommend		INT
		 ,SportType			SMALLINT
		 ,BetType			SMALLINT
		 ,Discount			DECIMAL(9,8)
	)

	CREATE TABLE #SuperComm(
		  CustID			INT
		 ,SportType			SMALLINT
		 ,BetType			SMALLINT
		 ,Discount			DECIMAL(9,8)
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

	INSERT #ProductSetting(SportType,BetType)
	SELECT ps.SportType
			,ps.BetType
	FROM CheckCustDB.[dbo].[ProductSettingDetail] ps WITH(NOLOCK)
		INNER JOIN (SELECT DISTINCT ProductID, IsHidden FROM #OfferedProductList WITH (NOLOCK)) op ON ps.RealProductId = op.ProductID
	WHERE op.IsHidden = 0 AND SettingType IN (3,19)
		AND ps.SettingStatus = 0		
	
	--Delete sport non offer
	DELETE sb		
	FROM #ProductSetting sb
		INNER JOIN CheckCustDB.[dbo].[SportNonOfferedSiteCurrency] stt WITH(NOLOCK) ON sb.SportType = stt.SportType AND sb.Bettype = stt.Bettype
	WHERE stt.Currency = @_Currency AND (stt.SiteID = @_SiteID OR stt.SiteID = 0)	
	
	DELETE sb		
	FROM #ProductSetting sb
		INNER JOIN CheckCustDB.[dbo].[SportNonOfferedSiteCurrency] stt WITH(NOLOCK) ON sb.SportType = stt.SportType AND sb.Bettype = stt.Bettype
	WHERE (stt.Currency = @_Currency OR stt.Currency = 0 ) AND stt.SiteID = @_SiteID

	UPDATE cs
	SET cs.BitmapOrder = prf.bitmapOrder
	FROM #ProductSetting cs
		INNER JOIN CheckCustDB.dbo.ProductStatusProfile prf WITH(NOLOCK) 
			ON prf.Sporttype = CASE WHEN cs.sporttype IN (242) THEN 9911 ELSE cs.sporttype END -- IBCBet Live Casino use status of Live Casino (9911)
			AND prf.bettype = CASE WHEN cs.sporttype IN (242) THEN 2400 ELSE cs.bettype END

	-- For Sportsbook
	INSERT #ProductSetting(SportType,BetType,BitmapOrder)
	SELECT ps.SportType
			,ps.BetType
			,0 AS BitmapOrder 
	FROM CheckCustDB.[dbo].[ProductSettingDetail] ps WITH(NOLOCK)
	WHERE SettingType IN (25)
		AND ps.SettingStatus = 0
	--------------------------------------------------------------------

	INSERT INTO #MemberComm (CustID,recommend,mrecommend,srecommend,SportType,BetType,SuperDiscount,MasterDiscount,AgentDiscount,PlayerDiscount,ugroup)
	SELECT cs.CustID,ci.recommend,ci.mrecommend,ci.srecommend, cs.SportType,cs.BetType,cs.SuperDiscount, cs.MasterDiscount, cs.AgentDiscount, cs.PlayerDiscount,c.ugroup
	FROM CheckCustDB.dbo.CustInfo ci WITH (NOLOCK)
		INNER JOIN CheckCustDB.dbo.customer c WITH (NOLOCK) ON ci.CustID = c.CustID
		INNER JOIN CheckCustDB.dbo.CustDiscount3rd_Member cs WITH (NOLOCK) ON ci.CustID = cs.CustID
		INNER JOIN #ProductSetting p ON cs.SportType = p.SportType AND cs.BetType = p.BetType
		INNER JOIN CheckCustDB.dbo.CustProductStatus stt WITH (NOLOCK) ON ci.CustID = stt.CustID
	WHERE ci.srecommend = @srecommend  
			AND ci.roleid = 1  
			AND ci.Enabled = 1      
			AND ci.Currency NOT IN (20,27,28)     
			AND cs.SportType = CASE WHEN @SportType = 0 then cs.SportType  ELSE @SportType END 
			AND cs.SportType NOT IN (SELECT sporttype FROM f_GetSportNotOffer ('CustSettingDCS')) 
			AND (
					ISNULL(bitmapOrder,0) < 5--From VB onwards
					OR 
					CASE substring(bitmapHasSynced, 1+((bitmapOrder-1)/8), 1) & POWER(2, (bitmapOrder-1)%8) WHEN 0 THEN 0 ELSE 1 END = 1		 
				)
			AND CheckCustDB.dbo.f_GetProductStatus (stt.bitmapIsHidden,p.bitmapOrder) = 0
	
	INSERT INTO #AgentComm (CustID,mrecommend,srecommend,SportType,BetType,Discount)
	SELECT cs.CustID,ci.mrecommend,ci.srecommend, cs.SportType,cs.BetType,cs.Discount
	FROM CheckCustDB.dbo.CustInfo ci WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.CustDiscount3rd_Agent cs WITH (NOLOCK) ON ci.CustID = cs.CustID
		INNER JOIN #ProductSetting p ON cs.SportType = p.SportType AND cs.BetType = p.BetType
		INNER JOIN CheckCustDB.dbo.CustProductStatus stt WITH (NOLOCK) ON ci.CustID = stt.CustID
	WHERE ci.srecommend = @srecommend  
			AND ci.roleid = 2  
			AND ci.Enabled = 1      
			AND ci.Currency NOT IN (20,27,28)     
			AND cs.SportType = CASE WHEN @SportType = 0 then cs.SportType  ELSE @SportType END 
			AND cs.SportType NOT IN (SELECT sporttype FROM f_GetSportNotOffer ('CustSettingDCS')) 
			AND (
					ISNULL(bitmapOrder,0) < 5--From VB onwards
					OR 
					CASE substring(bitmapHasSynced, 1+((bitmapOrder-1)/8), 1) & POWER(2, (bitmapOrder-1)%8) WHEN 0 THEN 0 ELSE 1 END = 1		 
				)
			AND CheckCustDB.dbo.f_GetProductStatus (stt.bitmapIsHidden,p.bitmapOrder) = 0
			
	INSERT INTO #MasterComm (CustID,srecommend,SportType,BetType,Discount)
	SELECT cs.CustID,ci.srecommend, cs.SportType,cs.BetType,cs.Discount
	FROM CheckCustDB.dbo.CustInfo ci WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.CustDiscount3rd_Agent cs WITH (NOLOCK) ON ci.CustID = cs.CustID
		INNER JOIN #ProductSetting p ON cs.SportType = p.SportType AND cs.BetType = p.BetType
		INNER JOIN CheckCustDB.dbo.CustProductStatus stt WITH (NOLOCK) ON ci.CustID = stt.CustID
	WHERE ci.srecommend = @srecommend  
			AND ci.roleid = 3  
			AND ci.Enabled = 1      
			AND ci.Currency NOT IN (20,27,28)     
			AND cs.SportType = CASE WHEN @SportType = 0 then cs.SportType  ELSE @SportType END 
			AND cs.SportType NOT IN (SELECT sporttype FROM f_GetSportNotOffer ('CustSettingDCS')) 
			AND (
					ISNULL(bitmapOrder,0) < 5--From VB onwards
					OR 
					CASE substring(bitmapHasSynced, 1+((bitmapOrder-1)/8), 1) & POWER(2, (bitmapOrder-1)%8) WHEN 0 THEN 0 ELSE 1 END = 1		 
				)
			AND CheckCustDB.dbo.f_GetProductStatus (stt.bitmapIsHidden,p.bitmapOrder) = 0
	
	INSERT INTO #SuperComm (CustID,SportType,BetType,Discount)
	SELECT cs.CustID, cs.SportType,cs.BetType,cs.Discount
	FROM CheckCustDB.dbo.CustInfo ci WITH(NOLOCK)
		INNER JOIN CheckCustDB.dbo.CustDiscount3rd_Agent cs WITH (NOLOCK) ON ci.CustID = cs.CustID
		INNER JOIN #ProductSetting p ON cs.SportType = p.SportType AND cs.BetType = p.BetType
		INNER JOIN CheckCustDB.dbo.CustProductStatus stt WITH (NOLOCK) ON ci.CustID = stt.CustID
	WHERE ci.srecommend = @srecommend  
			AND ci.roleid = 4  
			AND ci.Enabled = 1      
			AND ci.Currency NOT IN (20,27,28)     
			AND cs.SportType = CASE WHEN @SportType = 0 then cs.SportType  ELSE @SportType END 
			AND cs.SportType NOT IN (SELECT sporttype FROM f_GetSportNotOffer ('CustSettingDCS')) 
			AND (
					ISNULL(bitmapOrder,0) < 5--From VB onwards
					OR 
					CASE substring(bitmapHasSynced, 1+((bitmapOrder-1)/8), 1) & POWER(2, (bitmapOrder-1)%8) WHEN 0 THEN 0 ELSE 1 END = 1		 
				)
			AND CheckCustDB.dbo.f_GetProductStatus (stt.bitmapIsHidden,p.bitmapOrder) = 0
			
	-- End of DATA PREPARATION		
	
	-- Starting check Comm Rule
	---- 101. Super''s Discount < Master''s Discount
	IF @RuleId IN (0,101)  
	BEGIN  
		----PRINT '101. Super''s Discount < Master''s Discount'  
		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)   
		SELECT 101 AS RuleId, css.BetType, css.SportType, css.CustId, csm.CustId, css.Discount, csm.Discount  
		FROM #SuperComm css 
			INNER JOIN #MasterComm csm ON csm.BetType = css.BetType AND csm.SportType = css.SportType AND csm.srecommend = css.custid
		WHERE css.Discount < csm.Discount
		
	END  

	----102. Master''s Discount < Agent''s Discount
	IF @RuleId IN (0,102)  
	BEGIN  
		----PRINT '102. Master''s Discount < Agent''s Discount'
		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)  
		SELECT 102 AS RuleId, csa.BetType, csa.SportType, csm.CustId, csa.CustId, csm.Discount, csa.Discount  
		FROM #AgentComm csa
			INNER JOIN #MasterComm csm ON csm.BetType = csa.BetType AND csm.SportType = csa.SportType AND csa.mrecommend = csm.CustID
		WHERE csm.Discount < csa.Discount
		
	END  

	----103. Agent''s Discount < Player''s Discount
	IF @RuleId IN (0,103)  
	BEGIN   
		----PRINT '103. Agent''s Discount < Player''s Discount'
		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)  
		SELECT 103 AS RuleId, csa.BetType, csa.SportType, csa.CustId, csmem.CustId, csa.Discount, csmem.PlayerDiscount
		FROM #AgentComm csa
			INNER JOIN #MemberComm csmem ON csmem.BetType = csa.BetType AND csmem.SportType = csa.SportType AND csmem.recommend = csa.CustID
		WHERE csa.Discount < csmem.PlayerDiscount
			AND NOT (csmem.SportType = 1 AND csmem.BetType = 1)

		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)  
		SELECT 103 AS RuleId, csa.BetType, csa.SportType, csa.CustId, csmem.CustId, csa.Discount, csmem.PlayerDiscount
		FROM #AgentComm csa
			INNER JOIN #MemberComm csmem 
				ON CASE WHEN csmem.ugroup IN('a', 'hka', 'dea') THEN 1 
						WHEN csmem.ugroup IN('b', 'hkb', 'deb') THEN 3
						WHEN csmem.ugroup IN('c', 'hkc', 'dec') THEN 7
						WHEN csmem.ugroup IN('d', 'hkd', 'ded') THEN 8
					END = csa.BetType 
				AND csmem.SportType = csa.SportType 
				AND csmem.recommend = csa.CustID
		WHERE csa.Discount < csmem.PlayerDiscount
			AND csmem.SportType = 1 AND csmem.BetType = 1
	END  

	----104. SuperDiscount < MasterDiscount on member level
	IF @RuleId IN (0,104)  
	BEGIN  
		----PRINT '104. SuperDiscount < MasterDiscount on member level'
		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)  
		SELECT 104 as RuleId, csmem.BetType, csmem.SportType, csmem.CustId, csmem.CustId, csmem.SuperDiscount, csmem.MasterDiscount
		FROM #MemberComm csmem
		WHERE csmem.SuperDiscount < csmem.MasterDiscount
	END  
	
	----105. MasterDiscount < AgentDiscount on member level
	IF @RuleId IN (0,105)  
	BEGIN   
		----PRINT '105. MasterDiscount < AgentDiscount on member level'
		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)  
		SELECT 105 as RuleId, csmem.BetType, csmem.SportType, csmem.CustId, csmem.CustId, csmem.MasterDiscount, csmem.AgentDiscount
		FROM #MemberComm csmem
		WHERE csmem.MasterDiscount < csmem.AgentDiscount

	END  

	----106. AgentDiscount < PlayerDiscount on member level
	IF @RuleId IN (0,106)  
	BEGIN   
		----PRINT '106. AgentDiscount < PlayerDiscount on member level'
		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)  
		SELECT 106 as RuleId, csmem.BetType, csmem.SportType, csmem.CustId, csmem.CustId, csmem.AgentDiscount, csmem.PlayerDiscount
		FROM #MemberComm csmem
		WHERE csmem.AgentDiscount < csmem.PlayerDiscount
	END  
	
	---- 107. Super''s Discount <> Super''s Discount on member level
	IF @RuleId IN (0,107)  
	BEGIN  
		----PRINT '107. Super''s Discount <> Super''s Discount on member level'  
		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)   
		SELECT 107 AS RuleId, css.BetType, css.SportType, css.CustId, csmem.CustId, css.Discount, csmem.SuperDiscount  
		FROM #SuperComm css 
			INNER JOIN #MemberComm csmem ON csmem.BetType = css.BetType AND csmem.SportType = css.SportType AND csmem.srecommend = css.custid
		WHERE css.Discount <> csmem.SuperDiscount
			AND NOT (csmem.SportType = 1 AND csmem.BetType = 1)

		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)   
		SELECT 107 AS RuleId, css.BetType, css.SportType, css.CustId, csmem.CustId, css.Discount, csmem.SuperDiscount  
		FROM #SuperComm css 
			INNER JOIN #MemberComm csmem 
				ON CASE WHEN csmem.ugroup IN('a', 'hka', 'dea') THEN 1 
						WHEN csmem.ugroup IN('b', 'hkb', 'deb') THEN 3
						WHEN csmem.ugroup IN('c', 'hkc', 'dec') THEN 7
						WHEN csmem.ugroup IN('d', 'hkd', 'ded') THEN 8
					END = css.BetType  
				AND csmem.SportType = css.SportType 
				AND csmem.srecommend = css.custid
		WHERE css.Discount <> csmem.SuperDiscount
			AND csmem.SportType = 1 AND csmem.BetType = 1
		
	END  
	
	---- 108. Master''s Discount <> Master''s Discount on member level
	IF @RuleId IN (0,108)  
	BEGIN  
		----PRINT '108. Master''s Discount < Master''s Discount on member level'  
		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)   
		SELECT 108 AS RuleId, css.BetType, css.SportType, css.CustId, csmem.CustId, css.Discount, csmem.MasterDiscount
		FROM #MasterComm css 
			INNER JOIN #MemberComm csmem ON csmem.BetType = css.BetType AND csmem.SportType = css.SportType AND csmem.mrecommend = css.custid
		WHERE css.Discount <> csmem.MasterDiscount
			AND NOT (csmem.SportType = 1 AND csmem.BetType = 1)

		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)   
		SELECT 108 AS RuleId, css.BetType, css.SportType, css.CustId, csmem.CustId, css.Discount, csmem.MasterDiscount
		FROM #MasterComm css 
			INNER JOIN #MemberComm csmem 
				ON CASE WHEN csmem.ugroup IN('a', 'hka', 'dea') THEN 1 
						WHEN csmem.ugroup IN('b', 'hkb', 'deb') THEN 3
						WHEN csmem.ugroup IN('c', 'hkc', 'dec') THEN 7
						WHEN csmem.ugroup IN('d', 'hkd', 'ded') THEN 8
					END = css.BetType 
				AND csmem.SportType = css.SportType 
				AND csmem.mrecommend = css.custid
		WHERE css.Discount <> csmem.MasterDiscount
			AND csmem.SportType = 1 AND csmem.BetType = 1
		
	END 
	
	---- 109. Agent''s Discount <> Agent''s Discount on member level
	IF @RuleId IN (0,109)  
	BEGIN  
		----PRINT '109. Agent''s Discount < Agent''s Discount on member level'  
		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)   
		SELECT 109 AS RuleId, css.BetType, css.SportType, css.CustId, csmem.CustId, css.Discount, csmem.AgentDiscount  
		FROM #AgentComm css 
			INNER JOIN #MemberComm csmem ON csmem.BetType = css.BetType AND csmem.SportType = css.SportType AND csmem.recommend = css.custid
		WHERE css.Discount <> csmem.AgentDiscount
		AND NOT (csmem.SportType = 1 AND csmem.BetType = 1)

		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)   
		SELECT 108 AS RuleId, css.BetType, css.SportType, css.CustId, csmem.CustId, css.Discount, csmem.AgentDiscount
		FROM #AgentComm css 
			INNER JOIN #MemberComm csmem 
				ON CASE WHEN csmem.ugroup IN('a', 'hka', 'dea') THEN 1 
						WHEN csmem.ugroup IN('b', 'hkb', 'deb') THEN 3
						WHEN csmem.ugroup IN('c', 'hkc', 'dec') THEN 7
						WHEN csmem.ugroup IN('d', 'hkd', 'ded') THEN 8
					END = css.BetType 
				AND csmem.SportType = css.SportType 
				AND csmem.recommend = css.custid
		WHERE css.Discount <> csmem.AgentDiscount
			AND csmem.SportType = 1 AND csmem.BetType = 1
		
	END

	DROP TABLE #MemberComm
	DROP TABLE #AgentComm
	DROP TABLE #MasterComm
	DROP TABLE #SuperComm
	DROP TABLE #OfferedProductList
	DROP TABLE #ProductSetting
END
GO