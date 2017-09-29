/*<info serverAlias="DBCHECK-CheckResultDB" executers="" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[DBA_CheckCommGame_Credit]  
(	@srecommend INT   
	,@SportType SMALLINT = 0  
	,@RuleId SMALLINT = 0  
 )
 WITH RECOMPILE
AS  
/*  
	Created: 20170110@Winnie
	Task: Monthly check commission setting for CustSettinggame  
	DB: DBCHECK.CheckResultDB  

	Revisions:  :
		- 20170929@Johnson: Add rule 44,45,46 check comm of SMA on member
	Param's Explanation:   
	 @RuleId = 0 : 'all'  
	 @RuleId IN (36->41)  
	
	TRUNCATE TABLE CheckCommResult_Credit  
	
	SELECT * from CheckCommResult_Credit (NOLOCK)  
	
	Step 1: Detect wrong Comm and save them into CheckCommResult_Credit
		EXEC DBA_CheckComm_CustSettinggame @srecommend = 15		  
	Step 2: SELECT * from CheckCommResult_Credit (NOLOCK) 

*/  
	
BEGIN   
	
	SET NOCOUNT ON   
	
	-- Starting DATA PREPARATION
	--TRUNCATE TABLE CheckCommResult_Credit
	
	SELECT cs.CustID,ci.recommend,ci.mrecommend,ci.srecommend, cs.SportType,cs.BetType,cs.sdiscount AS SuperDiscount, cs.adiscount AS MasterDiscount, cs.discount AS AgentDiscount, cs.PlayerDiscount
	INTO #MemberComm
	FROM CheckCustDB.dbo.CustInfo ci
		INNER JOIN CheckCustDB.dbo.custsettinggame cs WITH (NOLOCK) ON ci.CustID = cs.CustID
	WHERE ci.srecommend = @srecommend  
			AND ci.roleid = 1  
			AND ci.Enabled = 1      
			AND ci.Currency NOT IN (20,27,28)     
			AND cs.SportType = CASE WHEN @SportType = 0 then cs.SportType  ELSE @SportType END 	
			AND 0= CASE WHEN cs.SportType=202 THEN ci.HideKeno
						WHEN cs.SportType =255 THEN ci.HideGoldDeluxe						
						ELSE 0 END
	
	SELECT cs.CustID,ci.recommend,ci.mrecommend,ci.srecommend, cs.SportType,cs.BetType,cs.Discount
	INTO #AgentComm
	FROM CheckCustDB.dbo.CustInfo ci
		INNER JOIN CheckCustDB.dbo.custsettinggame cs WITH (NOLOCK) ON ci.CustID = cs.CustID		
	WHERE ci.srecommend = @srecommend  
			AND ci.roleid = 2  
			AND ci.Enabled = 1      
			AND ci.Currency NOT IN (20,27,28)     
			AND cs.SportType = CASE WHEN @SportType = 0 then cs.SportType  ELSE @SportType END 		
			AND 0= CASE WHEN cs.SportType=202 THEN ci.HideKeno
						WHEN cs.SportType =255 THEN ci.HideGoldDeluxe						
						ELSE 0 END
			
	SELECT cs.CustID,ci.recommend,ci.mrecommend,ci.srecommend, cs.SportType,cs.BetType,cs.adiscount AS Discount
	INTO #MasterComm
	FROM CheckCustDB.dbo.CustInfo ci
		INNER JOIN CheckCustDB.dbo.custsettinggame cs WITH (NOLOCK) ON ci.CustID = cs.CustID	
	WHERE ci.srecommend = @srecommend  
			AND ci.roleid = 3  
			AND ci.Enabled = 1      
			AND ci.Currency NOT IN (20,27,28)     
			AND cs.SportType = CASE WHEN @SportType = 0 then cs.SportType  ELSE @SportType END		
			AND 0= CASE WHEN cs.SportType=202 THEN ci.HideKeno
						WHEN cs.SportType =255 THEN ci.HideGoldDeluxe						
						ELSE 0 END

	SELECT cs.CustID, cs.SportType,cs.BetType,cs.sdiscount AS Discount
	INTO #SuperComm
	FROM CheckCustDB.dbo.CustInfo ci
		INNER JOIN CheckCustDB.dbo.custsettinggame cs WITH (NOLOCK) ON ci.CustID = cs.CustID		
	WHERE ci.srecommend = @srecommend  
			AND ci.roleid = 4  
			AND ci.Enabled = 1      
			AND ci.Currency NOT IN (20,27,28)     
			AND cs.SportType = CASE WHEN @SportType = 0 then cs.SportType  ELSE @SportType END 
			AND 0= CASE WHEN cs.SportType=202 THEN ci.HideKeno
						WHEN cs.SportType =255 THEN ci.HideGoldDeluxe						
						ELSE 0 END
			
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
		WHERE css.Discount < csm.Discount
		
	END  

	----37. Master''s Discount < Agent''s Discount
	IF @RuleId IN (0,37)  
	BEGIN  
		----PRINT '37. Master''s Discount < Agent''s Discount'
		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)  
		SELECT 37 AS RuleId, csa.BetType, csa.SportType, csm.CustId, csa.CustId, csm.Discount, csa.Discount  
		FROM #AgentComm csa
			INNER JOIN #MasterComm csm ON csm.BetType = csa.BetType AND csm.SportType = csa.SportType AND csa.mrecommend = csm.CustID
		WHERE csm.Discount < csa.Discount
		
	END  

	----38. Agent''s Discount < Player''s Discount
	IF @RuleId IN (0,38)  
	BEGIN   
		----PRINT '38. Agent''s Discount < Player''s Discount'
		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)  
		SELECT 38 AS RuleId, csa.BetType, csa.SportType, csa.CustId, csmem.CustId, csa.Discount, csmem.PlayerDiscount
		FROM #AgentComm csa
			INNER JOIN #MemberComm csmem ON csmem.BetType = csa.BetType AND csmem.SportType = csa.SportType AND csmem.recommend = csa.CustID
		WHERE csa.Discount < csmem.PlayerDiscount

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
	
	---- 44. Super''s Discount <> Super''s Discount on member level
	IF @RuleId IN (0,44)  
	BEGIN  
		----PRINT '44. Super''s Discount <> Super''s Discount on member level'  
		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)   
		SELECT 44 AS RuleId, css.BetType, css.SportType, css.CustId, csmem.CustId, css.Discount, csmem.SuperDiscount  
		FROM #SuperComm css 
			INNER JOIN #MemberComm csmem ON csmem.BetType = css.BetType AND csmem.SportType = css.SportType AND csmem.srecommend = css.custid
		WHERE css.Discount <> csmem.SuperDiscount
		
	END  
	
	---- 45. Master''s Discount <> Master''s Discount on member level
	IF @RuleId IN (0,45)  
	BEGIN  
		----PRINT '45. Master''s Discount < Master''s Discount on member level'  
		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)   
		SELECT 45 AS RuleId, css.BetType, css.SportType, css.CustId, csmem.CustId, css.Discount, csmem.MasterDiscount
		FROM #MasterComm css 
			INNER JOIN #MemberComm csmem ON csmem.BetType = css.BetType AND csmem.SportType = css.SportType AND csmem.mrecommend = css.custid
		WHERE css.Discount <> csmem.MasterDiscount
		
	END 
	
	---- 46. Agent''s Discount <> Agent''s Discount on member level
	IF @RuleId IN (0,46)  
	BEGIN  
		----PRINT '46. Agent''s Discount < Agent''s Discount on member level'  
		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)   
		SELECT 46 AS RuleId, css.BetType, css.SportType, css.CustId, csmem.CustId, css.Discount, csmem.AgentDiscount  
		FROM #AgentComm css 
			INNER JOIN #MemberComm csmem ON csmem.BetType = css.BetType AND csmem.SportType = css.SportType AND csmem.recommend = css.custid
		WHERE css.Discount <> csmem.AgentDiscount
		
	END
END
GO
