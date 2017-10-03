/*<info serverAlias="DBCHECK-CheckResultDB" executers="" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[DBA_CheckComm_Credit]  
(	@srecommend INT   
	,@SportType SMALLINT = 0  
	,@RuleId SMALLINT = 0  
 )
 WITH RECOMPILE
AS  
/*  
	Created: 20170110@Winnie
	Task: Monthly check commission setting for CustSetting  
	DB: DBCHECK.CheckResultDB  

	Revisions:  :
		- 20170928@Johnson: Add rule 44,45,46 check comm of SMA on member [Redmine: #73556]
	Param's Explanation:   
	 @RuleId = 0 : 'all'  
	 @RuleId IN (36->41)  
	
	TRUNCATE TABLE CheckCommResult_Credit  
	
	SELECT * from CheckCommResult_Credit (NOLOCK)  
	
	Step 1: Detect wrong Comm and save them into CheckCommResult_Credit
		EXEC DBA_CheckComm_CustSetting @srecommend = 15		  
	Step 2: SELECT * from CheckCommResult_Credit (NOLOCK) 
	
	CheckCustDB.dbo.[CustDiscount3rd_Member]
			[CustDiscount3rd_Agent]
*/  
	
BEGIN   
	
	SET NOCOUNT ON   
	
	-- Starting DATA PREPARATION
	--TRUNCATE TABLE CheckCommResult_Credit
	
	SELECT cs.CustID,ci.recommend,ci.mrecommend,ci.srecommend, cs.SportType,cs.BetType,cs.sdiscount AS SuperDiscount, cs.adiscount AS MasterDiscount, cs.discount AS AgentDiscount
	, cs.PlayerDiscount	,c.ugroup
	INTO #MemberComm
	FROM CheckCustDB.dbo.custInfo ci
		INNER JOIN CheckCustDB.dbo.Custsetting cs WITH (NOLOCK) ON ci.CustID = cs.CustID
		INNER JOIN 	CheckCustDB.dbo.customer c 	 WITH (NOLOCK) ON ci.CustID = c.CustID
	WHERE ci.srecommend = @srecommend  
			AND ci.roleid = 1  
			AND ci.Enabled = 1      
			AND ci.Currency NOT IN (20,27,28)     
			AND cs.SportType = CASE WHEN @SportType = 0 then cs.SportType  ELSE @SportType END 
		
		
	
	SELECT cs.CustID,ci.recommend,ci.mrecommend,ci.srecommend, cs.SportType,cs.BetType,cs.Discount
	,cs.groupa,cs.groupb,cs.groupc,cs.groupd
	INTO #AgentComm
	FROM CheckCustDB.dbo.CustInfo ci
		INNER JOIN CheckCustDB.dbo.Custsetting cs WITH (NOLOCK) ON ci.CustID = cs.CustID		
	WHERE ci.srecommend = @srecommend  
			AND ci.roleid = 2  
			AND ci.Enabled = 1      
			AND ci.Currency NOT IN (20,27,28)     
			AND cs.SportType = CASE WHEN @SportType = 0 then cs.SportType  ELSE @SportType END 
	

			
			
	SELECT cs.CustID,ci.recommend,ci.mrecommend,ci.srecommend, cs.SportType,cs.BetType,cs.adiscount AS Discount
	,cs.groupa,cs.groupb,cs.groupc,cs.groupd
	INTO #MasterComm
	FROM CheckCustDB.dbo.CustInfo ci
		INNER JOIN CheckCustDB.dbo.Custsetting cs WITH (NOLOCK) ON ci.CustID = cs.CustID	
	WHERE ci.srecommend = @srecommend  
			AND ci.roleid = 3  
			AND ci.Enabled = 1      
			AND ci.Currency NOT IN (20,27,28)     
			AND cs.SportType = CASE WHEN @SportType = 0 then cs.SportType  ELSE @SportType END 

		

	SELECT cs.CustID, cs.SportType,cs.BetType,cs.sdiscount AS Discount
	,cs.groupa,cs.groupb,cs.groupc,cs.groupd
	INTO #SuperComm
	FROM CheckCustDB.dbo.CustInfo ci
		INNER JOIN CheckCustDB.dbo.Custsetting cs WITH (NOLOCK) ON ci.CustID = cs.CustID		
	WHERE ci.srecommend = @srecommend  
			AND ci.roleid = 4  
			AND ci.Enabled = 1      
			AND ci.Currency NOT IN (20,27,28)     
			AND cs.SportType = CASE WHEN @SportType = 0 then cs.SportType  ELSE @SportType END 

			
	-- End of DATA PREPARATION				
	
	-- Starting check Comm Rule
	---- 36. Super''s Discount < Master''s Discount
	IF @RuleId IN (0,36)  
	BEGIN  
		----PRINT '36. Super''s Discount < Master''s Discount'  
		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)   
		SELECT 36 AS RuleId, css.BetType, css.SportType, css.CustId, csm.CustId, css.Discount, csm.Discount  
		FROM #SuperComm css 
			INNER JOIN #MasterComm csm ON csm.BetType = css.BetType AND csm.SportType = css.SportType AND csm.srecommend = css.custid
		WHERE css.Discount < csm.Discount AND csm.bettype NOT IN (1, 2, 3, 7, 8)

		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)   
		SELECT 36 AS RuleId, css.BetType, css.SportType, css.CustId, csm.CustId, css.groupa, csm.groupa  
		FROM #SuperComm css 
			INNER JOIN #MasterComm csm ON csm.BetType = css.BetType AND csm.SportType = css.SportType AND csm.srecommend = css.custid
		WHERE css.groupa<csm.groupa AND csm.bettype  IN (1, 2, 3, 7, 8)

		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)   
		SELECT 36 AS RuleId, css.BetType, css.SportType, css.CustId, csm.CustId, css.groupb, csm.groupb  
		FROM #SuperComm css 
			INNER JOIN #MasterComm csm ON csm.BetType = css.BetType AND csm.SportType = css.SportType AND csm.srecommend = css.custid
		WHERE css.groupb<csm.groupb  AND csm.bettype  IN (1, 2, 3, 7, 8)

		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)   
		SELECT 36 AS RuleId, css.BetType, css.SportType, css.CustId, csm.CustId, css.groupc, csm.groupc  
		FROM #SuperComm css 
			INNER JOIN #MasterComm csm ON csm.BetType = css.BetType AND csm.SportType = css.SportType AND csm.srecommend = css.custid
		WHERE css.groupc<csm.groupc  AND csm.bettype  IN (1, 2, 3, 7, 8)
		
		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)   
		SELECT 36 AS RuleId, css.BetType, css.SportType, css.CustId, csm.CustId, css.groupd, csm.groupd  
		FROM #SuperComm css 
			INNER JOIN #MasterComm csm ON csm.BetType = css.BetType AND csm.SportType = css.SportType AND csm.srecommend = css.custid
		WHERE css.groupd<csm.groupd   AND csm.bettype  IN (1, 2, 3, 7, 8)
	END  

	----37. Master''s Discount < Agent''s Discount
	IF @RuleId IN (0,37)  
	BEGIN  
		----PRINT '37. Master''s Discount < Agent''s Discount'
		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)  
		SELECT 37 AS RuleId, csa.BetType, csa.SportType, csm.CustId, csa.CustId, csm.Discount, csa.Discount  
		FROM #AgentComm csa 
			INNER JOIN #MasterComm csm ON csm.BetType = csa.BetType AND csm.SportType = csa.SportType AND csa.mrecommend = csm.CustID
		WHERE csm.Discount < csa.Discount  AND csm.bettype NOT IN (1, 2, 3, 7, 8)

		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)  
		SELECT 37 AS RuleId, csa.BetType, csa.SportType, csm.CustId, csa.CustId, csm.groupa, csa.groupa  
		FROM #AgentComm csa
			INNER JOIN #MasterComm csm ON csm.BetType = csa.BetType AND csm.SportType = csa.SportType AND csa.mrecommend = csm.CustID
		WHERE csm.groupa<csa.groupa  AND csm.bettype  IN (1, 2, 3, 7, 8)

		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)  
		SELECT 37 AS RuleId, csa.BetType, csa.SportType, csm.CustId, csa.CustId, csm.groupb, csa.groupb  
		FROM #AgentComm csa
			INNER JOIN #MasterComm csm ON csm.BetType = csa.BetType AND csm.SportType = csa.SportType AND csa.mrecommend = csm.CustID
		WHERE csm.groupb<csa.groupb  AND csm.bettype  IN (1, 2, 3, 7, 8)

		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)  
		SELECT 37 AS RuleId, csa.BetType, csa.SportType, csm.CustId, csa.CustId, csm.groupc, csa.groupc  
		FROM #AgentComm csa
			INNER JOIN #MasterComm csm ON csm.BetType = csa.BetType AND csm.SportType = csa.SportType AND csa.mrecommend = csm.CustID
		WHERE csm.groupc<csa.groupc  AND csm.bettype  IN (1, 2, 3, 7, 8)
		
		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)  
		SELECT 37 AS RuleId, csa.BetType, csa.SportType, csm.CustId, csa.CustId, csm.groupd, csa.groupd  
		FROM #AgentComm csa
			INNER JOIN #MasterComm csm ON csm.BetType = csa.BetType AND csm.SportType = csa.SportType AND csa.mrecommend = csm.CustID
		WHERE csm.groupd<csa.groupd  AND csm.bettype  IN (1, 2, 3, 7, 8)
	END  

	----38. Agent''s Discount < Player''s Discount
	IF @RuleId IN (0,38)  
	BEGIN   
		----PRINT '38. Agent''s Discount < Player''s Discount'
		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)  
		SELECT 38 AS RuleId, csa.BetType, csa.SportType, csa.CustId, csmem.CustId, csa.Discount, csmem.PlayerDiscount
		FROM #AgentComm csa
			INNER JOIN #MemberComm csmem ON csmem.BetType = csa.BetType AND csmem.SportType = csa.SportType AND csmem.recommend = csa.CustID
		WHERE csa.bettype  IN (1, 2, 3, 7, 8) AND ugroup IN('a', 'hka', 'dea')
		AND csa.groupa < csmem.PlayerDiscount
		
		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)  
		SELECT 38 AS RuleId, csa.BetType, csa.SportType, csa.CustId, csmem.CustId, csa.Discount, csmem.PlayerDiscount
		FROM #AgentComm csa
			INNER JOIN #MemberComm csmem ON csmem.BetType = csa.BetType AND csmem.SportType = csa.SportType AND csmem.recommend = csa.CustID
		WHERE csa.bettype  IN (1, 2, 3, 7, 8) AND ugroup IN ('b', 'hkb', 'deb')
		AND csa.groupb < csmem.PlayerDiscount
		
		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)  
		SELECT 38 AS RuleId, csa.BetType, csa.SportType, csa.CustId, csmem.CustId, csa.Discount, csmem.PlayerDiscount
		FROM #AgentComm csa
			INNER JOIN #MemberComm csmem ON csmem.BetType = csa.BetType AND csmem.SportType = csa.SportType AND csmem.recommend = csa.CustID
		WHERE csa.bettype  IN (1, 2, 3, 7, 8) AND ugroup IN ('c', 'hkc', 'dec')
		AND csa.groupc < csmem.PlayerDiscount
		
		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)  
		SELECT 38 AS RuleId, csa.BetType, csa.SportType, csa.CustId, csmem.CustId, csa.Discount, csmem.PlayerDiscount
		FROM #AgentComm csa
			INNER JOIN #MemberComm csmem ON csmem.BetType = csa.BetType AND csmem.SportType = csa.SportType AND csmem.recommend = csa.CustID
		WHERE csa.bettype  IN (1, 2, 3, 7, 8) AND ugroup IN ('d', 'hkd', 'ded') 
		AND csa.groupd < csmem.PlayerDiscount
		
		
		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)  
		SELECT 38 AS RuleId, csa.BetType, csa.SportType, csa.CustId, csmem.CustId, csa.Discount, csmem.PlayerDiscount
		FROM #AgentComm csa
			INNER JOIN #MemberComm csmem ON csmem.BetType = csa.BetType AND csmem.SportType = csa.SportType AND csmem.recommend = csa.CustID
		WHERE csa.bettype NOT IN (1, 2, 3, 7, 8)
		AND csa.Discount < csmem.PlayerDiscount

	END  

	----39. SuperDiscount < MasterDiscount on member level
	IF @RuleId IN (0,39)  
	BEGIN  
		----PRINT '39. SuperDiscount < MasterDiscount on member level'
		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)  
		SELECT 39 as RuleId, csmem.BetType, csmem.SportType, csmem.CustId, csmem.CustId, csmem.SuperDiscount, csmem.MasterDiscount
		FROM #MemberComm csmem
		WHERE csmem.SuperDiscount < csmem.MasterDiscount
	END  
	
	----40. MasterDiscount < AgentDiscount on member level
	IF @RuleId IN (0,40)  
	BEGIN   
		----PRINT '40. MasterDiscount < AgentDiscount on member level'
		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)  
		SELECT 40 as RuleId, csmem.BetType, csmem.SportType, csmem.CustId, csmem.CustId, csmem.MasterDiscount, csmem.AgentDiscount
		FROM #MemberComm csmem
		WHERE csmem.MasterDiscount < csmem.AgentDiscount

	END  

	----41. AgentDiscount < PlayerDiscount on member level
	IF @RuleId IN (0,41)  
	BEGIN   
		----PRINT '41. AgentDiscount < PlayerDiscount on member level'
		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)  
		SELECT 41 as RuleId, csmem.BetType, csmem.SportType, csmem.CustId, csmem.CustId, csmem.AgentDiscount, csmem.PlayerDiscount
		FROM #MemberComm csmem
		WHERE csmem.AgentDiscount < csmem.PlayerDiscount
	END  
	
	---44. SuperDiscount <> SuperDiscount on member level
	IF @RuleId IN (0,44)
	BEGIN
		----PRINT '44. SuperDiscount <> SuperDiscount on member level'  
		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)   
		SELECT 44 AS RuleId, css.BetType, css.SportType, css.CustId, csmem.CustId, css.Discount, csmem.SuperDiscount  
		FROM #SuperComm css 
			INNER JOIN #MemberComm csmem ON csmem.BetType = css.BetType AND csmem.SportType = css.SportType AND csmem.srecommend = css.custid
		WHERE css.Discount <> csmem.SuperDiscount 			
			AND csmem.bettype NOT IN (1, 2, 3, 7, 8)

		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)   
		SELECT 44 AS RuleId, css.BetType, css.SportType, css.CustId, csmem.CustId, css.groupa, csmem.SuperDiscount  
		FROM #SuperComm css 
			INNER JOIN #MemberComm csmem ON csmem.BetType = css.BetType AND csmem.SportType = css.SportType AND csmem.srecommend = css.custid
		WHERE css.groupa<>csmem.SuperDiscount 
			AND csmem.bettype  IN (1, 2, 3, 7, 8)
			AND ugroup IN('a', 'hka', 'dea')

		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)   
		SELECT 44 AS RuleId, css.BetType, css.SportType, css.CustId, csmem.CustId, css.groupb, csmem.SuperDiscount  
		FROM #SuperComm css 
			INNER JOIN #MemberComm csmem ON csmem.BetType = css.BetType AND csmem.SportType = css.SportType AND csmem.srecommend = css.custid
		WHERE css.groupb<>csmem.SuperDiscount  
			AND csmem.bettype  IN (1, 2, 3, 7, 8)
			AND ugroup IN('b', 'hkb', 'deb')

		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)   
		SELECT 44 AS RuleId, css.BetType, css.SportType, css.CustId, csmem.CustId, css.groupc, csmem.SuperDiscount  
		FROM #SuperComm css 
			INNER JOIN #MemberComm csmem ON csm.BetType = css.BetType AND csmem.SportType = css.SportType AND csmem.srecommend = css.custid
		WHERE css.groupc<>csmem.SuperDiscount  
			AND csmem.bettype  IN (1, 2, 3, 7, 8)
			AND ugroup IN('c', 'hkc', 'dec')
			
		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)   
		SELECT 44 AS RuleId, css.BetType, css.SportType, css.CustId, csmem.CustId, css.groupd, csmem.SuperDiscount  
		FROM #SuperComm css 
			INNER JOIN #MemberComm csmem ON csmem.BetType = css.BetType AND csmem.SportType = css.SportType AND csmem.srecommend = css.custid
		WHERE css.groupd<>csmem.SuperDiscount   
			AND csmem.bettype  IN (1, 2, 3, 7, 8)
			AND ugroup IN('d', 'hkd', 'ded')
	END
	
	---45. MasterDiscount <> MasterDiscount on member level
	IF @RuleId IN (0,45)
	BEGIN
		----PRINT '45. MasterDiscount <> MasterDiscount on member level'  
		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)   
		SELECT 45 AS RuleId, css.BetType, css.SportType, css.CustId, csmem.CustId, css.Discount, csmem.MasterDiscount  
		FROM #MasterComm css 
			INNER JOIN #MemberComm csmem ON csmem.BetType = css.BetType AND csmem.SportType = css.SportType AND csmem.mrecommend = css.custid
		WHERE css.Discount <> csmem.MasterDiscount 			
			AND csmem.bettype NOT IN (1, 2, 3, 7, 8)

		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)   
		SELECT 45 AS RuleId, css.BetType, css.SportType, css.CustId, csmem.CustId, css.groupa, csmem.MasterDiscount  
		FROM #MasterComm css 
			INNER JOIN #MemberComm csmem ON csmem.BetType = css.BetType AND csmem.SportType = css.SportType AND csmem.mrecommend = css.custid
		WHERE css.groupa<>csmem.MasterDiscount 
			AND csmem.bettype  IN (1, 2, 3, 7, 8)
			AND ugroup IN('a', 'hka', 'dea')

		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)   
		SELECT 45 AS RuleId, css.BetType, css.SportType, css.CustId, csmem.CustId, css.groupb, csmem.MasterDiscount  
		FROM #MasterComm css 
			INNER JOIN #MemberComm csmem ON csmem.BetType = css.BetType AND csmem.SportType = css.SportType AND csmem.mrecommend = css.custid
		WHERE css.groupb<>csmem.MasterDiscount  
			AND csmem.bettype  IN (1, 2, 3, 7, 8)
			AND ugroup IN('b', 'hkb', 'deb')

		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)   
		SELECT 45 AS RuleId, css.BetType, css.SportType, css.CustId, csmem.CustId, css.groupc, csmem.MasterDiscount  
		FROM #MasterComm css 
			INNER JOIN #MemberComm csmem ON csm.BetType = css.BetType AND csmem.SportType = css.SportType AND csmem.mrecommend = css.custid
		WHERE css.groupc<>csmem.MasterDiscount  
			AND csmem.bettype  IN (1, 2, 3, 7, 8)
			AND ugroup IN('c', 'hkc', 'dec')
		
		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)   
		SELECT 45 AS RuleId, css.BetType, css.SportType, css.CustId, csmem.CustId, css.groupd, csmem.MasterDiscount  
		FROM #MasterComm css 
			INNER JOIN #MemberComm csmem ON csmem.BetType = css.BetType AND csmem.SportType = css.SportType AND csmem.mrecommend = css.custid
		WHERE css.groupd<>csmem.MasterDiscount   
			AND csmem.bettype  IN (1, 2, 3, 7, 8)
			AND ugroup IN('d', 'hkd', 'ded')
	END
	
	---46. AgentDiscount <> AgentDiscount on member level
	IF @RuleId IN (0,46)
	BEGIN
		----PRINT '46. AgentDiscount <> AgentDiscount on member level'  
		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)   
		SELECT 46 AS RuleId, css.BetType, css.SportType, css.CustId, csmem.CustId, css.Discount, csmem.AgentDiscount  
		FROM #AgentComm css 
			INNER JOIN #MemberComm csmem ON csmem.BetType = css.BetType AND csmem.SportType = css.SportType AND csmem.recommend = css.custid
		WHERE css.Discount <> csmem.AgentDiscount 			
			AND csmem.bettype NOT IN (1, 2, 3, 7, 8)

		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)   
		SELECT 46 AS RuleId, css.BetType, css.SportType, css.CustId, csmem.CustId, css.groupa, csmem.AgentDiscount  
		FROM #AgentComm css 
			INNER JOIN #MemberComm csmem ON csmem.BetType = css.BetType AND csmem.SportType = css.SportType AND csmem.recommend = css.custid
		WHERE css.groupa<>csmem.AgentDiscount 
			AND csmem.bettype  IN (1, 2, 3, 7, 8)
			AND ugroup IN('a', 'hka', 'dea')

		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)   
		SELECT 46 AS RuleId, css.BetType, css.SportType, css.CustId, csmem.CustId, css.groupb, csmem.AgentDiscount  
		FROM #AgentComm css 
			INNER JOIN #MemberComm csmem ON csmem.BetType = css.BetType AND csmem.SportType = css.SportType AND csmem.recommend = css.custid
		WHERE css.groupb<>csmem.AgentDiscount  
			AND csmem.bettype  IN (1, 2, 3, 7, 8)
			AND ugroup IN('b', 'hkb', 'deb')

		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)   
		SELECT 46 AS RuleId, css.BetType, css.SportType, css.CustId, csmem.CustId, css.groupc, csmem.AgentDiscount  
		FROM #AgentComm css 
			INNER JOIN #MemberComm csmem ON csm.BetType = css.BetType AND csmem.SportType = css.SportType AND csmem.recommend = css.custid
		WHERE css.groupc<>csmem.AgentDiscount  
			AND csmem.bettype  IN (1, 2, 3, 7, 8)
			AND ugroup IN('c', 'hkc', 'dec')
		
		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)   
		SELECT 46 AS RuleId, css.BetType, css.SportType, css.CustId, csmem.CustId, css.groupd, csmem.AgentDiscount  
		FROM #AgentComm css 
			INNER JOIN #MemberComm csmem ON csmem.BetType = css.BetType AND csmem.SportType = css.SportType AND csmem.recommend = css.custid
		WHERE css.groupd<>csmem.AgentDiscount   
			AND csmem.bettype  IN (1, 2, 3, 7, 8)
			AND ugroup IN('d', 'hkd', 'ded')
	END
END
GO
