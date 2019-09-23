ALTER PROCEDURE [dbo].[DBA_CheckCommGame_Deposit]  
(	@srecommend INT   
	,@SportType SMALLINT = 0  
	,@RuleId SMALLINT = 0  
 )
 WITH RECOMPILE
AS  
/*  
	Created: 20170110@Winnie
	Task: Monthly check commission setting for Dep_CustSettinggame  
	DB: DBCHECK.CheckResultDB  

	Revisions:  :

	Param's Explanation:   
	 @RuleId = 0 : 'all'  
	 @RuleId IN (43)  
	
	TRUNCATE TABLE CheckCommResult_DepositNew  
	
	SELECT * from CheckCommResult_DepositNew (NOLOCK)  
	
	Step 1: Detect wrong Comm and save them into CheckCommResult_DepositNew
		EXEC [[DBA_CheckCommGame_Deposit]] @srecommend = 15		  
	Step 2: SELECT * from CheckCommResult_DepositNew (NOLOCK) 

*/  
	
BEGIN   
	
	SET NOCOUNT ON   
	
	-- Starting DATA PREPARATION
	--TRUNCATE TABLE CheckCommResult_Credit
	
	IF @RuleId IN (0,43)  
	BEGIN  
		SELECT LCC.RacingComm,LCC.NGComm,LCC.LCComm,LCC.RNGComm,LCC.CustID,LCC.LicenseeID
		INTO #LicenseeComm		
		FROM  CheckLicenseeDB.dbo.LicenseeCustComm	LCC
		INNER JOIN CheckLicenseeDB.dbo.LicenseeGroupComm LGC ON  LCC.GroupCommID = LGC.[id]	
				 
		SELECT cs.CustID, cs.SportType,cs.BetType, cs.PlayerDiscount
		INTO #MemberComm
		FROM CheckCustDB.dbo.custInfo ci			
			INNER JOIN CheckCustDB.dbo.Dep_CustSettingGame cs WITH (NOLOCK) ON ci.CustID = cs.CustID			
			INNER JOIN 	CheckCustDB.dbo.customer c 	 WITH (NOLOCK) ON ci.CustID = c.CustID
		WHERE ci.srecommend = @srecommend  
				AND ci.roleid = 1  
				AND ci.Enabled = 1      
				AND ci.Currency NOT IN (20,27,28)     
				AND cs.SportType = CASE WHEN @SportType = 0 then cs.SportType  ELSE @SportType END 				
		
		----PRINT '43. Licensee  Discount < Player  Discount'

		INSERT INTO CheckCommResult_Credit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)  
		SELECT 43 AS RuleId, m.BetType, m.SportType, l.LicenseeID, m.CustId, 
							CASE WHEN m.sporttype IN (151,152,153) THEN ISNULL(l.[RacingComm],0.00)
							WHEN m.sporttype IN (161) THEN ISNULL(l.[NGComm],0.00)
							WHEN m.sporttype IN (162) THEN ISNULL(l.[LCComm],0.00)
							WHEN m.sporttype IN (251) THEN ISNULL(l.[RNGComm],0.00)
							ELSE 0.00 END AS ValueA,						 
							m.PlayerDiscount
		FROM #LicenseeComm l
			INNER JOIN #MemberComm m ON l.CustID=m.CustID
		WHERE 	CASE WHEN m.sporttype IN (151,152,153) THEN ISNULL(l.[RacingComm],0.00)
							WHEN m.sporttype IN (161) THEN ISNULL(l.[NGComm],0.00)
							WHEN m.sporttype IN (162) THEN ISNULL(l.[LCComm],0.00)
							WHEN m.sporttype IN (251) THEN ISNULL(l.[RNGComm],0.00)
							ELSE 0.00
						 END
						 < m.playerdiscount
	END
END