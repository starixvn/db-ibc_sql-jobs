/*<info serverAlias="DBCHECK-CheckResultDB" executers="" viewers="" isFunction="0"></info>*/
USE CheckResultDB
GO

CREATE PROCEDURE [dbo].[DBA_CheckBetLimit_Dep]  
(	@srecommend INT   
	,@RuleId SMALLINT = 0  
 )

AS  
/*  
	Created: 20180816@Winnie
	Task: Monthly check bet limit setting for Deposit
	DB: DBCHECK/CheckResultDB  
	Revisions:  :
	Param's Explanation:   
	 @RuleId = 0 : 'all'  
	 @RuleId IN (110->118)  

*/  
	
BEGIN   
	
	SET NOCOUNT ON   

	IF @RuleId IN (0,110)  
	BEGIN  
		INSERT INTO CheckCommissionResult_Deposit (RuleId, BetType, SportType, CustIdA,  ValueA,CreatedDate)  
		SELECT 110 AS RuleId, 18001 , 204, custid  , NULL,GETDATE()
		FROM CheckCustDB.dbo.custInfo a WITH(NOLOCK) 
		WHERE a.srecommend = @srecommend AND  a.roleid IN(2,3,4) AND HideColossusBet=0 AND DisableColossusBet=0
			AND a.custid NOT IN(SELECT custid FROM CheckCustDB.dbo.Dep_AgentCommRate WITH(NOLOCK))

		INSERT INTO CheckCommissionResult_Deposit (RuleId, BetType, SportType, CustIdA,  ValueA,CreatedDate)  
		SELECT 110 AS RuleId, 18001 , 204, custid  , NULL,GETDATE()	
		FROM CheckCustDB.dbo.custInfo a WITH(NOLOCK) 
		WHERE a.srecommend = @srecommend AND  a.roleid =1 AND HideColossusBet=0 AND DisableColossusBet=0
			AND a.custid NOT IN(SELECT custid FROM CheckCustDB.dbo.Dep_CustCommRate WITH(NOLOCK))		
	END  
	
	IF @RuleId IN (0,111)  
	BEGIN  
		INSERT INTO CheckCommissionResult_Deposit (RuleId, BetType, SportType, CustIdA,  ValueA, ValueB,CreatedDate)  
		SELECT 111 AS RuleId, a.BetType , a.SportType, a.custid ,  a.playerdiscount,NULL,GETDATE()
		FROM CheckCustDB.dbo.Dep_CustCommRate a WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo b WITH(NOLOCK) ON a.custID=b.CustID
		WHERE b.srecommend = @srecommend  AND  a.playerdiscount<>0				
	END 

	IF @RuleId IN (0,112)  
	BEGIN  
		INSERT INTO CheckCommissionResult_Deposit (RuleId, BetType, SportType, CustIdA,  ValueA, ValueB,CreatedDate)  
		SELECT 112 AS RuleId, a.BetType , a.SportType, a.custid ,  a.sdiscount, a.adiscount	,GETDATE()
		FROM CheckCustDB.dbo.Dep_CustCommRate a WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo b WITH(NOLOCK) ON a.custID=b.CustID
		WHERE b.srecommend = @srecommend  AND a.sdiscount<>a.adiscount 

		INSERT INTO CheckCommissionResult_Deposit (RuleId, BetType, SportType, CustIdA,  ValueA, ValueB,CreatedDate)  
		SELECT 112 AS RuleId, a.BetType , a.SportType, a.custid ,  a.sdiscount, a.discount,GETDATE()
		FROM CheckCustDB.dbo.Dep_CustCommRate a WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo b WITH(NOLOCK) ON a.custID=b.CustID
		WHERE b.srecommend = @srecommend  AND a.sdiscount<>a.discount

		INSERT INTO CheckCommissionResult_Deposit (RuleId, BetType, SportType, CustIdA,  ValueA, ValueB,CreatedDate)  
		SELECT 112 AS RuleId, a.BetType , a.SportType, a.custid ,  a.adiscount, a.discount,GETDATE()
		FROM CheckCustDB.dbo.Dep_CustCommRate a WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo b WITH(NOLOCK) ON a.custID=b.CustID
		WHERE b.srecommend = @srecommend  AND a.adiscount<>a.discount
	END 
	IF @RuleId IN (0,113)  
	BEGIN  
		INSERT INTO CheckCommissionResult_Deposit (RuleId, BetType, SportType, CustIdA,  ValueA, ValueB,CreatedDate)  
		SELECT 113 AS RuleId, a.BetType , a.SportType, a.custid ,  a.CommRate, NULL	,GETDATE()
		FROM CheckCustDB.dbo.Dep_AgentCommRate a WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo b WITH(NOLOCK) ON a.custID=b.CustID
		WHERE b.srecommend = @srecommend  AND a.SportType=204 AND a.BetType=18001 AND a.CommRate<>0.1215
	END 
	IF @RuleId IN (0,114)  
	BEGIN  
		INSERT INTO CheckCommissionResult_Deposit (RuleId, BetType, SportType, CustIdA,  ValueA, ValueB,CreatedDate)  
		SELECT 114 AS RuleId, a.BetType , a.SportType, a.custid ,  a.CommRate, NULL	,GETDATE()
		FROM CheckCustDB.dbo.Dep_AgentCommRate a WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo b WITH(NOLOCK) ON a.custID=b.CustID
		WHERE  b.srecommend = @srecommend  AND a.SportType=204 AND a.BetType=18002 AND a.CommRate<>0.45
	END 
	IF @RuleId IN (0,115)  
	BEGIN  
		INSERT INTO CheckCommissionResult_Deposit (RuleId, BetType, SportType, CustIdA,  ValueA, ValueB,CreatedDate)  
		SELECT 115 AS RuleId,  901, 1, a.AgentID ,  a.HouseDeductionRate, NULL	,GETDATE()
		FROM CheckCustDB.dbo.BetTradeComm a WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo b WITH(NOLOCK) ON a.AgentID=b.CustID
		WHERE b.srecommend = @srecommend  AND HouseDeductionRate<>0.015
	END 
	IF @RuleId IN (0,116)  
	BEGIN  
		INSERT INTO CheckCommissionResult_Deposit (RuleId, BetType, SportType, CustIdA,  ValueA, ValueB,CreatedDate)  
		SELECT 116 AS RuleId, 901, 1, a.AgentID  ,  a.BetTradeComm, NULL	,GETDATE()
		FROM CheckCustDB.dbo.BetTradeComm a WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo b WITH(NOLOCK) ON a.AgentID=b.CustID
		WHERE  b.srecommend = @srecommend  AND bettradecomm <> 0.04
	END 
	IF @RuleId IN (0,117)  
	BEGIN  
		INSERT INTO CheckCommissionResult_Deposit (RuleId, BetType, SportType, CustIdA,  ValueA, ValueB,CreatedDate)  
		SELECT 117 AS RuleId, 901, 1, a.AgentID ,  a.Licenseecomm, NULL	,GETDATE()
		FROM CheckCustDB.dbo.BetTradeComm a WITH(NOLOCK)
			INNER JOIN CheckCustDB.dbo.custInfo b WITH(NOLOCK) ON a.AgentID=b.CustID 
		WHERE b.srecommend = @srecommend  AND a.IsBA=0 AND Licenseecomm <>0.03
	END 
	IF @RuleId IN (0,118)  
	BEGIN  
		INSERT INTO CheckCommissionResult_Deposit (RuleId, BetType, SportType, CustIdA,  ValueA, ValueB,CreatedDate)  
		SELECT 118 AS RuleId,  901, 1, a.AgentID ,  a.Licenseecomm, NULL,GETDATE()	
		FROM CheckCustDB.dbo.BetTradeComm a WITH(NOLOCK) 
			INNER JOIN CheckCustDB.dbo.custInfo b WITH(NOLOCK) ON a.AgentID=b.CustID 
		WHERE b.srecommend = @srecommend  AND a.IsBA=1 AND Licenseecomm <> 0
	END 


END