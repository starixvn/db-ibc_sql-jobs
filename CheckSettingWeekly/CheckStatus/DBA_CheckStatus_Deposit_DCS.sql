/*<info serverAlias="DBCHECK-CheckResultDB" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_CheckStatus_Deposit_DCS]
	@RuleId	SMALLINT = 0
	, @SportType SMALLINT = 0
AS
/*
Created: 20170328@Helen
Task: Monthly check Status setting for credit/deposit customers - [Redmine:73556]
DB: DB054.CheckResultDB
Revisions:
	- 20201211@Winfred: Remove OddAdj Acc[redmine:#147005]
	- 20201223@Winfred: not check data from CustSuper table[redmine:#147408]	
	- 20220301@Eden: Deposit - Sportsbook - Revise customer settings [Redmine: #167898] 
Param's Explanation: 
	@RuleId = 0 : 'all'
	@RuleId IN (1->9)

*/

BEGIN 

	SET NOCOUNT ON 
	
	SELECT *
	INTO #ProductStatusProfile
	FROM CheckCustDB.dbo.Dep_ProductStatusProfile PSP WITH (NOLOCK)
	WHERE (@SportType = 0 OR PSP.Sporttype = @SportType) AND PSP.Sporttype <> 50
	
	-------------------PREPARATION: GET LIST SUPER/Master/Agent disabled FIRST----------------------------
		
	CREATE TABLE #DCS_Super_Hidden_Disabled (custID INT, bitmapOrder INT, IsDisabled BIT, IsHidden BIT )
	CREATE TABLE #DCS_Master_Hidden_Disabled (custID INT, bitmapOrder INT, IsDisabled BIT, IsHidden BIT)
	CREATE TABLE #DCS_Agent_Hidden_Disabled (custID INT, bitmapOrder INT, IsDisabled BIT,  IsHidden BIT)
	
	INSERT INTO #DCS_Super_Hidden_Disabled (custID,bitmapOrder,IsDisabled,IsHidden)
	SELECT CPS.CustID,T.bitmapOrder,CheckCustDB.dbo.f_GetProductStatus (cps.bitmapIsDisabled,T.bitmapOrder) IsDisabled, CheckCustDB.dbo.f_GetProductStatus (cps.bitmapIsHidden,T.bitmapOrder) AS IsHidden
	FROM CheckCustDB.dbo.Dep_CustProductStatus CPS (NOLOCK)
		INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON CPS.CustID = CI.custid
		CROSS APPLY (SELECT bitmapOrder FROM #ProductStatusProfile)	AS T
	WHERE CI.roleid = 4 AND (CheckCustDB.dbo.f_GetProductStatus (cps.bitmapIsDisabled,T.bitmapOrder) = 1 OR CheckCustDB.dbo.f_GetProductStatus (cps.bitmapIsHidden,T.bitmapOrder) = 1)
		AND ci.srecommend IN (SELECT custid FROM CheckCustDB.dbo.Dep_CustSuper WITH(NOLOCK))
		AND CI.Enabled = 1 AND CI.Currency NOT IN (20,72,27)
		AND CI.username NOT LIKE '%Acc%'
		AND CI.username NOT LIKE '%3rdSuper%'
		AND CI.username NOT LIKE 'STEST%'
		AND CI.username NOT LIKE '%cashout%'
		AND CI.username NOT LIKE '%dummy%'
		AND CI.username NOT LIKE '%BetTrade%'
		AND CI.username NOT LIKE '%OddsAdj%'
		AND ci.username NOT LIKE '%ClearBal%'
	INSERT INTO #DCS_Master_Hidden_Disabled (custID,bitmapOrder,IsDisabled,IsHidden)
	SELECT CPS.CustID,T.bitmapOrder,CheckCustDB.dbo.f_GetProductStatus (cps.bitmapIsDisabled,T.bitmapOrder),CheckCustDB.dbo.f_GetProductStatus (cps.bitmapIsHidden,T.bitmapOrder) 
	FROM CheckCustDB.dbo.Dep_CustProductStatus CPS (NOLOCK)
		INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON CPS.CustID = CI.custid
		CROSS APPLY (SELECT bitmapOrder FROM #ProductStatusProfile)	AS T
	WHERE CI.roleid = 3 AND (CheckCustDB.dbo.f_GetProductStatus (cps.bitmapIsDisabled,T.bitmapOrder) = 1 OR CheckCustDB.dbo.f_GetProductStatus (cps.bitmapIsHidden,T.bitmapOrder) = 1)
		AND ci.srecommend IN (SELECT custid FROM CheckCustDB.dbo.Dep_CustSuper WITH(NOLOCK))
		AND CI.Enabled = 1 AND CI.Currency NOT IN (20,72,27)
		AND CI.username NOT LIKE '%Acc%'
		AND CI.username NOT LIKE '%3rdSuper%'
		AND CI.username NOT LIKE 'STEST%'
		AND CI.username NOT LIKE '%cashout%'
		AND CI.username NOT LIKE '%dummy%'
		AND CI.username NOT LIKE '%BetTrade%'
		AND CI.username NOT LIKE '%OddsAdj%'
		AND ci.username NOT LIKE '%ClearBal%'
	INSERT INTO #DCS_Agent_Hidden_Disabled (custID,bitmapOrder,IsDisabled,IsHidden)
	SELECT CPS.CustID,T.bitmapOrder,CheckCustDB.dbo.f_GetProductStatus (cps.bitmapIsDisabled,T.bitmapOrder),CheckCustDB.dbo.f_GetProductStatus (cps.bitmapIsHidden,T.bitmapOrder) 
	FROM CheckCustDB.dbo.Dep_CustProductStatus CPS (NOLOCK)
		INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON CPS.CustID = CI.custid
		CROSS APPLY (SELECT bitmapOrder FROM #ProductStatusProfile)	AS T
	WHERE CI.roleid = 2 AND (CheckCustDB.dbo.f_GetProductStatus (cps.bitmapIsDisabled,T.bitmapOrder) = 1 OR CheckCustDB.dbo.f_GetProductStatus (cps.bitmapIsHidden,T.bitmapOrder) = 1)
		AND ci.srecommend IN (SELECT custid FROM CheckCustDB.dbo.Dep_CustSuper WITH(NOLOCK))
		AND CI.Enabled = 1 AND CI.Currency NOT IN (20,72,27)
		AND CI.username NOT LIKE '%Acc%'
		AND CI.username NOT LIKE '%3rdSuper%'
		AND CI.username NOT LIKE 'STEST%'
		AND CI.username NOT LIKE '%cashout%'
		AND CI.username NOT LIKE '%dummy%'
		AND CI.username NOT LIKE '%BetTrade%'
		AND CI.username NOT LIKE '%OddsAdj%'
		AND ci.username NOT LIKE '%ClearBal%'
	-------------------END OF PREPARATION: GET LIST SUPER/Master/Agent disabled FIRST----------------------------
	----------------------------FINAL RESULT ------------------------------------
	-- Rule 1: Super IsDisabled= 1, Master IsDisabled = 0		
	IF @RuleId IN (0,1)
	BEGIN
		INSERT INTO CheckStatusResult_DCS (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		SELECT 1, PSP.Sporttype,PSP.Bettype, ci.custid AS MasterID,ci.srecommend,0,1,GETDATE() , 1
		FROM #DCS_Super_Hidden_Disabled S
			INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON S.CustID = CI.srecommend AND CI.roleid = 3
			INNER JOIN CheckCustDB.dbo.Dep_CustProductStatus CPS WITH (NOLOCK) ON CI.custid = CPS.CustID 
			INNER JOIN #ProductStatusProfile PSP WITH (NOLOCK) ON S.bitmapOrder = PSP.bitmapOrder
		WHERE CI.Enabled = 1
			AND CheckCustDB.dbo.f_GetProductStatus (cps.bitmapIsDisabled,s.bitmapOrder) = 0
			AND S.IsDisabled = 1
			AND CI.username NOT LIKE '%Acc%'
			AND CI.username NOT LIKE '%3rdSuper%'
			AND CI.username NOT LIKE 'STEST%'
			AND CI.username NOT LIKE '%cashout%'
			AND CI.username NOT LIKE '%dummy%'
			AND CI.username NOT LIKE '%BetTrade%'
			AND CI.username NOT LIKE '%OddsAdj%'
			AND ci.username NOT LIKE '%ClearBal%'
	END
	-- Rule 2: Master IsDisabled= 1, Agent IsDisabled = 0		
	IF @RuleId IN (0,2)
	BEGIN
		INSERT INTO CheckStatusResult_DCS (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit)
		SELECT 2, PSP.Sporttype,PSP.Bettype, ci.custid AS AgentID, ci.mrecommend,0,1,GETDATE(),1 
		FROM #DCS_Master_Hidden_Disabled m
			INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON m.CustID = CI.mrecommend AND CI.roleid = 2
			INNER JOIN CheckCustDB.dbo.Dep_CustProductStatus CPS WITH (NOLOCK) ON CI.custid = CPS.CustID 
			INNER JOIN #ProductStatusProfile PSP WITH (NOLOCK) ON M.bitmapOrder = PSP.bitmapOrder
		WHERE CI.Enabled = 1
			AND CheckCustDB.dbo.f_GetProductStatus (cps.bitmapIsDisabled,m.bitmapOrder) = 0
			AND M.IsDisabled = 1
			AND CI.username NOT LIKE '%3rdSuper%'
			AND CI.username NOT LIKE 'STEST%'
			AND CI.username NOT LIKE '%cashout%'
			AND CI.username NOT LIKE '%dummy%'
			AND CI.username NOT LIKE '%BetTrade%'
			AND CI.username NOT LIKE '%OddsAdj%'
			AND ci.username NOT LIKE '%ClearBal%'
	END	
	-- Rule 3: Agent IsDisabled= 1, Member IsDisabled = 0		
	IF @RuleId IN (0,3)
	BEGIN
		INSERT INTO CheckStatusResult_DCS (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit)
		SELECT 3, PSP.Sporttype,PSP.Bettype, ci.custid AS MemberID,ci.recommend,0,1,GETDATE(),1 
		FROM #DCS_Agent_Hidden_Disabled a
			INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON a.CustID = CI.recommend AND CI.roleid = 1
			INNER JOIN CheckCustDB.dbo.Dep_CustProductStatus CPS WITH (NOLOCK) ON CI.custid = CPS.CustID 
			INNER JOIN #ProductStatusProfile PSP WITH (NOLOCK) ON A.bitmapOrder = PSP.bitmapOrder
		WHERE CI.Enabled = 1
			AND CheckCustDB.dbo.f_GetProductStatus (cps.bitmapIsDisabled,a.bitmapOrder) = 0
			AND A.IsDisabled = 1
			AND ci.custid NOT IN (20696396) --(20696396:QW107AA121)
			AND CI.username NOT LIKE '%3rdSuper%'
			AND CI.username NOT LIKE 'STEST%'
			AND CI.username NOT LIKE '%cashout%'
			AND CI.username NOT LIKE '%dummy%'
			AND CI.username NOT LIKE '%BetTrade%'
			AND CI.username NOT LIKE '%OddsAdj%'
			AND ci.username NOT LIKE '%ClearBal%'
	END
	-- Rule 4: Super IsHidden= 1, Master IsHidden= 0		
	IF @RuleId IN (0,4)
	BEGIN
	
		INSERT INTO CheckStatusResult_DCS (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit)
		SELECT 4, PSP.Sporttype,PSP.Bettype, ci.custid AS MasterID,ci.srecommend,0,1,GETDATE(), 1 
		FROM #DCS_Super_Hidden_Disabled S
			INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON S.CustID = CI.srecommend AND CI.roleid = 3
			INNER JOIN CheckCustDB.dbo.Dep_CustProductStatus CPS WITH (NOLOCK) ON CI.custid = CPS.CustID 
			INNER JOIN #ProductStatusProfile PSP WITH (NOLOCK) ON S.bitmapOrder = PSP.bitmapOrder
		WHERE CI.Enabled = 1
			AND CheckCustDB.dbo.f_GetProductStatus (cps.bitmapIsHidden,s.bitmapOrder) = 0
			AND S.IsHidden = 1
			AND CI.username NOT LIKE '%3rdSuper%'
			AND CI.username NOT LIKE 'STEST%'
			AND CI.username NOT LIKE '%cashout%'
			AND CI.username NOT LIKE '%dummy%'
			AND CI.username NOT LIKE '%BetTrade%'
			AND CI.username NOT LIKE '%OddsAdj%'
			AND ci.username NOT LIKE '%ClearBal%'
	END
	-- Rule 5: Master IsHidden= 1, Agent IsHidden= 0		
	IF @RuleId IN (0,5)
	BEGIN
		INSERT INTO CheckStatusResult_DCS (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit)
		SELECT 5, PSP.Sporttype,PSP.Bettype, ci.custid AS AgentID, ci.mrecommend,0,1,GETDATE(), 1 
		FROM #DCS_Master_Hidden_Disabled m
			INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON m.CustID = CI.mrecommend AND CI.roleid = 2
			INNER JOIN CheckCustDB.dbo.Dep_CustProductStatus CPS WITH (NOLOCK) ON CI.custid = CPS.CustID 
			INNER JOIN #ProductStatusProfile PSP WITH (NOLOCK) ON M.bitmapOrder = PSP.bitmapOrder
		WHERE CI.Enabled = 1
			AND CheckCustDB.dbo.f_GetProductStatus (cps.bitmapIsHidden,m.bitmapOrder) = 0
			AND m.IsHidden = 1
			AND CI.username NOT LIKE '%3rdSuper%'
			AND CI.username NOT LIKE 'STEST%'
			AND CI.username NOT LIKE '%cashout%'
			AND CI.username NOT LIKE '%dummy%'
			AND CI.username NOT LIKE '%BetTrade%'
			AND CI.username NOT LIKE '%OddsAdj%'
			AND ci.username NOT LIKE '%ClearBal%'
	END	
	-- Rule 6: Agent IsHidden= 1, Member IsHidden= 0		 
	IF @RuleId IN (0,6)
	BEGIN
	
		INSERT INTO CheckStatusResult_DCS (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate, IsDeposit)
		SELECT 6, PSP.Sporttype,PSP.Bettype, ci.custid AS MemberID,ci.recommend,0,1,GETDATE(), 1 
		FROM #DCS_Agent_Hidden_Disabled a
			INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON a.CustID = CI.recommend AND CI.roleid = 1
			INNER JOIN CheckCustDB.dbo.Dep_CustProductStatus CPS WITH (NOLOCK) ON CI.custid = CPS.CustID 
			INNER JOIN #ProductStatusProfile PSP WITH (NOLOCK) ON A.bitmapOrder = PSP.bitmapOrder
		WHERE CI.Enabled = 1
			AND CheckCustDB.dbo.f_GetProductStatus (cps.bitmapIsHidden,a.bitmapOrder) = 0
			AND a.IsHidden = 1
			AND ci.custid NOT IN (20696396) --(20696396:QW107AA121)
			AND CI.username NOT LIKE '%3rdSuper%'
			AND CI.username NOT LIKE 'STEST%'
			AND CI.username NOT LIKE '%cashout%'
			AND CI.username NOT LIKE '%dummy%'
			AND CI.username NOT LIKE '%BetTrade%'
			AND CI.username NOT LIKE '%OddsAdj%'
			AND ci.username NOT LIKE '%ClearBal%'
	END	
	
	DROP TABLE #DCS_Agent_Hidden_Disabled
	DROP TABLE #DCS_Master_Hidden_Disabled
	DROP TABLE #DCS_Super_Hidden_Disabled
	DROP TABLE #ProductStatusProfile	

	SET NOCOUNT OFF	
		
END