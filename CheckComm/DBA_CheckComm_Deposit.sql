/*<info serverAlias="DBCHECK-CheckResultDB" executers="" viewers="" isFunction="0"></info>*/
USE CheckResultDB
GO

ALTER PROCEDURE [dbo].[DBA_CheckComm_Deposit]  
(	@srecommend INT   
	,@SportType SMALLINT = 0  
	,@RuleId SMALLINT = 0  
 )
 WITH RECOMPILE
AS  
/*  
	Created: 20170705@Winnie
	Task: Monthly check commission setting for Dep_CustSetting  
	DB: DBCHECK/CheckResultDB  

	Revisions:  :

	Param's Explanation:   
	 @RuleId = 0 : 'all'  
	 @RuleId IN (42->43)  
	
	TRUNCATE TABLE CheckCommResult_DepositNew  
	
	SELECT * from CheckCommResult_DepositNew (NOLOCK)  
	
	Step 1: Detect wrong Comm and save them into CheckCommResult_DepositNew
		EXEC [DBA_CheckComm_Deposit] @srecommend = 15		  
	Step 2: SELECT * from CheckCommResult_DepositNew (NOLOCK) 
	
	CheckCustDB.dbo.[CustDiscount3rd_Member]
			[CustDiscount3rd_Agent]
*/  
	
BEGIN   
	
	SET NOCOUNT ON   
	
	-- Starting DATA PREPARATION
	--TRUNCATE TABLE CheckCommResult_DepositNew

	IF @RuleId IN (0,42)  
	BEGIN  
		SELECT LBA.LicenseeID, LBA.groupa AS groupa,LBA.groupb AS groupb,LBA.groupc AS groupc,LBA.groupd AS groupd, LBA.[1x2Comm] AS [1x2Comm], LBA.OtherComm AS OtherComm
		INTO #LicenseeCommBA
		FROM  CheckLicenseeDB.dbo.LicenseeBAConfig	LBA
		WHERE EnableBA=1
				 
		SELECT cs.CustID,BA.LicenseeID, cs.SportType,cs.BetType, cs.PlayerDiscount	,c.ugroup
		INTO #MemberCommBA
		FROM CheckCustDB.dbo.custInfo ci		
			INNER JOIN CheckCustDB.dbo.Dep_custsetting cs WITH (NOLOCK) ON ci.CustID = cs.CustID
			INNER JOIN CheckLicenseeDB.dbo.LicenseeBAHistory BA WITH (NOLOCK) ON ci.CustID = BA.CustID
			INNER JOIN 	CheckCustDB.dbo.customer c 	 WITH (NOLOCK) ON ci.CustID = c.CustID
		WHERE ci.srecommend = @srecommend  
				AND ci.roleid = 1  
				AND ci.Enabled = 1      
				AND ci.Currency NOT IN (20,27,28)     
				AND cs.SportType = CASE WHEN @SportType = 0 then cs.SportType  ELSE @SportType END 
				AND BA.[Status] = 'running' 
		
		----PRINT '42. Licensee BA Discount < Player BA Discount'
		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)  
		SELECT 42 AS RuleId, m.BetType, m.SportType, l.LicenseeID, m.CustId, l.groupa, m.PlayerDiscount
		FROM #LicenseeCommBA l
			INNER JOIN #MemberCommBA m ON l.LicenseeID=m.LicenseeID
		WHERE m.bettype  IN (1, 2, 3, 7, 8) AND ugroup IN('a', 'hka', 'dea')
		AND l.groupa < m.PlayerDiscount
		
		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)  
		SELECT 42 AS RuleId, m.BetType, m.SportType, l.LicenseeID, m.CustId, l.groupb, m.PlayerDiscount
		FROM #LicenseeCommBA l
			INNER JOIN #MemberCommBA m ON l.LicenseeID=m.LicenseeID
		WHERE m.bettype  IN (1, 2, 3, 7, 8) AND ugroup IN('b', 'hkb', 'deb')
		AND l.groupb < m.PlayerDiscount
		
		
		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)  
		SELECT 42 AS RuleId, m.BetType, m.SportType, l.LicenseeID, m.CustId, l.groupc, m.PlayerDiscount
		FROM #LicenseeCommBA l
			INNER JOIN #MemberCommBA m ON l.LicenseeID=m.LicenseeID
		WHERE m.bettype  IN (1, 2, 3, 7, 8) AND ugroup IN ('c', 'hkc', 'dec')
		AND l.groupc < m.PlayerDiscount
		
		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)  
		SELECT 42 AS RuleId, m.BetType, m.SportType, l.LicenseeID, m.CustId, l.groupd, m.PlayerDiscount
		FROM #LicenseeCommBA l
			INNER JOIN #MemberCommBA m ON l.LicenseeID=m.LicenseeID
		WHERE m.bettype  IN (1, 2, 3, 7, 8) AND ugroup IN  ('d', 'hkd', 'ded') 
		AND l.groupd < m.PlayerDiscount	
		
		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)  
		SELECT 42 AS RuleId, m.BetType, m.SportType, l.LicenseeID, m.CustId, l.[1x2Comm], m.PlayerDiscount
		FROM #LicenseeCommBA l
			INNER JOIN #MemberCommBA m ON l.LicenseeID=m.LicenseeID
		WHERE m.bettype =5
		AND l.[1x2Comm] < m.PlayerDiscount
		
		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)  
		SELECT 42 AS RuleId, m.BetType, m.SportType, l.LicenseeID, m.CustId, l.OtherComm, m.PlayerDiscount
		FROM #LicenseeCommBA l
			INNER JOIN #MemberCommBA m ON l.LicenseeID=m.LicenseeID
		WHERE m.bettype IN (4,6,9,10,20,21,22)
		AND l.OtherComm < m.PlayerDiscount
	END  

	IF @RuleId IN (0,43)  
	BEGIN  
		SELECT LCC.SBComm,LCC.CustID,LCC.LicenseeID
		INTO #LicenseeComm		
		FROM  CheckLicenseeDB.dbo.LicenseeCustComm	LCC
		INNER JOIN CheckLicenseeDB.dbo.LicenseeGroupComm LGC ON  LCC.GroupCommID = LGC.[id]	
				 
		SELECT cs.CustID, cs.SportType,cs.BetType, cs.PlayerDiscount
		INTO #MemberComm
		FROM CheckCustDB.dbo.custInfo ci			
			INNER JOIN CheckCustDB.dbo.Dep_custsetting cs WITH (NOLOCK) ON ci.CustID = cs.CustID			
			INNER JOIN 	CheckCustDB.dbo.customer c 	 WITH (NOLOCK) ON ci.CustID = c.CustID
		WHERE ci.srecommend = @srecommend  
				AND ci.roleid = 1  
				AND ci.Enabled = 1      
				AND ci.Currency NOT IN (20,27,28)     
				AND cs.SportType = CASE WHEN @SportType = 0 then cs.SportType  ELSE @SportType END 				
		
		----PRINT '43. Licensee  Discount < Player  Discount'

		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)  
		SELECT 43 AS RuleId, m.BetType, m.SportType, l.LicenseeID, m.CustId, l.SBComm, m.PlayerDiscount
		FROM #LicenseeComm l
			INNER JOIN #MemberComm m ON l.CustID=m.CustID
		WHERE  l.SBComm < m.PlayerDiscount
		
		
	END 
END