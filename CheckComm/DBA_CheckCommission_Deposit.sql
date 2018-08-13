/*<info serverAlias="DBCHECK-CheckResultDB" executers="" viewers="" isFunction="0"></info>*/
USE CheckResultDB
GO

CREATE PROCEDURE [dbo].[DBA_CheckCommission_Deposit]  
(	@srecommend INT   
	,@RuleId SMALLINT = 0  
 )
 WITH RECOMPILE
AS  
/*  
	Created: 20180806@Winnie
	Task: Monthly check commission setting for Deposit
	DB: DBCHECK/CheckResultDB  

	Revisions:  :

	Param's Explanation:   
	 @RuleId = 0 : 'all'  
	 @RuleId IN (110->118)  
	
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

	IF @RuleId IN (0,110)  
	BEGIN  
		INSERT INTO CheckCommissionResult_Deposit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)  
		SELECT 110 AS RuleId, 18001 , 204, custid , NULL , NULL, NULL	
		FROM CheckCustDB.dbo.custInfo a WITH(NOLOCK) 
		WHERE a.srecommend = @srecommend AND  a.roleid IN(2,3,4) AND HideColossusBet=0
			AND a.custid NOT IN(SELECT custid FROM CheckCustDB.dbo.Dep_AgentCommRate WITH(NOLOCK))

		INSERT INTO CheckCommissionResult_Deposit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)  
		SELECT 110 AS RuleId, 18001 , 204, custid , NULL , NULL, NULL	
		FROM CheckCustDB.dbo.custInfo a WITH(NOLOCK) 
		WHERE a.srecommend = @srecommend AND  a.roleid =1 AND HideColossusBet=0
			AND a.custid NOT IN(SELECT custid FROM CheckCustDB.dbo.Dep_CustCommRate WITH(NOLOCK))		
	END  
	
	IF @RuleId IN (0,111)  
	BEGIN  
		INSERT INTO CheckCommissionResult_Deposit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)  
		SELECT 111 AS RuleId, a.BetType , a.SportType, custid , NULL , NULL, NULL	
		FROM CheckCustDB.dbo.Dep_CustCommRate a WITH(NOLOCK) 
		WHERE a.playerdiscount<>0				
	END 

	IF @RuleId IN (0,112)  
	BEGIN  
		INSERT INTO CheckCommissionResult_Deposit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)  
		SELECT 112 AS RuleId, a.BetType , a.SportType, a.custid , NULL , NULL, NULL	
		FROM CheckCustDB.dbo.Dep_CustCommRate a WITH(NOLOCK) 
		WHERE a.sdiscount<>a.adiscount OR a.sdiscount<>a.discount OR a.adiscount<>a.discount
	END 
	IF @RuleId IN (0,113)  
	BEGIN  
		INSERT INTO CheckCommissionResult_Deposit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)  
		SELECT 113 AS RuleId, a.BetType , a.SportType, a.custid , NULL , NULL, NULL	
		FROM CheckCustDB.dbo.Dep_AgentCommRate a WITH(NOLOCK) 
		WHERE a.SportType=204 AND a.BetType=18001 AND a.CommRate<>0.1215
	END 
	IF @RuleId IN (0,114)  
	BEGIN  
		INSERT INTO CheckCommissionResult_Deposit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)  
		SELECT 114 AS RuleId, a.BetType , a.SportType, a.custid , NULL , NULL, NULL	
		FROM CheckCustDB.dbo.Dep_AgentCommRate a WITH(NOLOCK) 
		WHERE a.SportType=204 AND a.BetType=18002 AND a.CommRate<>0.45
	END 
	IF @RuleId IN (0,115)  
	BEGIN  
		INSERT INTO CheckCommissionResult_Deposit (RuleId, BetType, SportType, CustIdA, CustIdB, ValueA, ValueB)  
		SELECT 114 AS RuleId, a.BetType , a.SportType, a.custid , NULL , NULL, NULL	
		FROM CheckCustDB.dbo.Dep_AgentCommRate a WITH(NOLOCK) 
		WHERE a.SportType=204 AND a.BetType=18002 AND a.CommRate<>0.45
	END 

END