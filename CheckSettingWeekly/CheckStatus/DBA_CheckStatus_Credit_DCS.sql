/*<info serverAlias="DBCHECK-CheckResultDB" executers="" viewers="" isFunction="0"></info>*/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[DBA_CheckStatus_Credit_DCS]
	@RuleId	SMALLINT = 0
	, @SportType SMALLINT = 0
AS
/*
Created: 20170328@Helen
Task: Monthly check Status setting for credit/deposit customers - [Redmine:73556]
DB: DBCHECK.CheckResultDB
Revisions:
	- 20171214@Johnson: add more rule to check un-sync customers for GD,Casino,VB,AB [Redmine: #87745]
	- 20180201@Johnson: update rule check un-sync customer for GD,Casino,VB,AB [Redmine: #87745]
	- 20190801@Johnson: exclude cn88 [redmine:#116551]
	- 20210419@Winfred: exclude inActive currency [redmine:#153659]
	- 20230208@Eden: Alpha - User can not see the new create agent's account in the Agent List [Redmine: #183486]
Param's Explanation: 
	@RuleId = 0 : 'all'
	@RuleId IN (1->9)

*/

BEGIN 

	SET NOCOUNT ON 

	CREATE TABLE #ProductStatusProfile(Sporttype smallint,Bettype smallint,bitmapOrder tinyint)

	INSERT INTO #ProductStatusProfile(Sporttype,Bettype,bitmapOrder)
	SELECT psp.Sporttype,psp.Bettype,psp.bitmapOrder
	FROM CheckCustDB.dbo.ProductStatusProfile PSP WITH (NOLOCK)
		INNER JOIN CheckCustDB.dbo.ProductSettingDetail d WITH(NOLOCK) 
			ON psp.Bettype = d.BetType 
			AND psp.Sporttype = d.SportType
		INNER JOIN CheckCustDB.dbo.ProductSettingType p  WITH(NOLOCK)
			ON d.SettingType = p.SettingType
	WHERE p.SettingName = 'Product Status'
		AND d.SettingStatus = 0
		AND PSP.Sporttype <> 50
		AND (@SportType = 0 OR PSP.Sporttype = @SportType)
	
	--super list excluded	
	DECLARE @tmpSuper TABLE(CustID INT)
	INSERT INTO @tmpSuper(custid)
	SELECT 	3984944	--	STE8
	UNION SELECT 	3590248	--	CSDTEST
	UNION SELECT 	62	--	SA-KW
	UNION SELECT 	63	--	SA-NZD
	UNION SELECT 	64	--	SA-UT
	UNION SELECT 	65	--	SA-UDI
	UNION SELECT 	66	--	SA-YUN
	UNION SELECT 	68	--	SA-POS
	UNION SELECT 	70	--	SA-MKK
	UNION SELECT 	71	--	SA-KHR
	UNION SELECT 	73	--	SA-LIR
	UNION SELECT 	7119552	--	skwrongxxx
	UNION SELECT 	8551070	--	gtwrong
	UNION SELECT 	69	--	SA-MMK
	UNION SELECT 	18	--	SA-ttt
	UNION SELECT 	21	--	SA-CAD
	UNION SELECT 	37	--	SA-P
	UNION SELECT 	40	--	SA-IRR
	UNION SELECT 	43	--	SA-THB
	UNION SELECT 	44	--	SA-PT
	UNION SELECT 	45	--	SA-WON
	UNION SELECT 	46	--	SA-BND
	UNION SELECT 	47	--	SA-DDD
	UNION SELECT 	48	--	SA-ZAR
	UNION SELECT 	49	--	SA-MXN
	UNION SELECT 	51	--	SA-INH
	UNION SELECT 	52	--	SA-DKK
	UNION SELECT 	53	--	SA-SEK
	UNION SELECT 	54	--	SA-NOK
	UNION SELECT 	55	--	SA-RUB
	UNION SELECT 	56	--	SA-PLN
	UNION SELECT 	57	--	SA-CZK
	UNION SELECT 	58	--	SA-RON
	UNION SELECT 	61	--	SA-INR
	UNION SELECT 	74	--	SA-TH
	UNION SELECT 	8	--	sabill
	UNION SELECT 	7	--	SM07
	UNION SELECT 	10	--	SM10
	UNION SELECT 	11	--	SM11
	UNION SELECT 	14	--	SM14
	UNION SELECT 	19	--	SM19
	UNION SELECT 	23	--	SM23
	UNION SELECT 	24	--	SM24
	UNION SELECT 	38	--	SM38
	UNION SELECT 	39	--	SM39
	UNION SELECT 	59	--	SM59
	UNION SELECT 	60	--	SM60
	UNION SELECT 	75	--	SM75
	UNION SELECT 	76	--	SM76
	UNION SELECT 	77	--	SM77
	UNION SELECT 	78	--	SM78
	UNION SELECT 	79	--	SM79
	UNION SELECT 	80	--	SM80
	UNION SELECT 	81	--	SM81
	UNION SELECT 	82	--	SM82
	UNION SELECT 	83	--	SM83
	UNION SELECT 	84	--	SM84
	UNION SELECT 	85	--	SM85
	UNION SELECT 	86	--	SM86
	UNION SELECT 	87	--	SM87
	UNION SELECT 	88	--	SM88
	UNION SELECT 	89	--	SM89
	UNION SELECT 	90	--	SM90
	UNION SELECT 	91	--	SM91
	UNION SELECT 	92	--	SM92
	UNION SELECT 	93	--	SM93
	UNION SELECT 	94	--	SM94
	UNION SELECT 	95	--	SM95
	UNION SELECT 	96	--	SM96
	UNION SELECT 	97	--	SM97
	UNION SELECT 	98	--	SM98
	UNION SELECT 	99	--	SM99
	UNION SELECT 	100	--	SM0*

	-------------------PREPARATION: GET LIST SUPER/Master/Agent disabled FIRST----------------------------
		
	CREATE TABLE #DCS_Super (custID INT, bitmapOrder INT, IsDisabled BIT, IsHidden BIT, IsSync BIT )
	CREATE TABLE #DCS_Master (custID INT, bitmapOrder INT, IsDisabled BIT, IsHidden BIT, IsSync BIT)
	CREATE TABLE #DCS_Agent (custID INT, bitmapOrder INT, IsDisabled BIT,  IsHidden BIT, IsSync BIT)
	
	INSERT INTO #DCS_Super (custID,bitmapOrder,IsDisabled,IsHidden,IsSync)
	SELECT CPS.CustID,T.bitmapOrder,CheckCustDB.dbo.f_GetProductStatus (cps.bitmapIsDisabled,T.bitmapOrder) IsDisabled, CheckCustDB.dbo.f_GetProductStatus (cps.bitmapIsHidden,T.bitmapOrder) AS IsHidden, CheckCustDB.dbo.f_GetProductStatus (cps.bitmapHasSynced,T.bitmapOrder) isSync
	FROM CheckCustDB.dbo.CustProductStatus CPS (NOLOCK)
		INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON CPS.CustID = CI.custid		
		INNER JOIN CheckCustDB.dbo.CustSuper CS WITH (NOLOCK)  ON CI.srecommend = CS.custid AND CS.IsInternal = 0
		CROSS APPLY (SELECT bitmapOrder FROM #ProductStatusProfile)	AS T
	WHERE CI.roleid = 4 		
		AND ci.srecommend NOT IN (SELECT custid FROM CheckCustDB.dbo.Dep_CustSuper WITH(NOLOCK))
		AND ci.srecommend NOT IN (SELECT custID FROM @tmpSuper)
		AND CI.Enabled = 1
		AND CI.Currency NOT IN (0,20,72,27)
		AND CI.username NOT LIKE '%Acc%'
		AND CI.username NOT LIKE '%3rdSuper%'
		AND CI.username NOT LIKE 'STEST%'
		AND CI.username NOT LIKE '%cashout%'
		AND CI.username NOT LIKE '%dummy%'
		AND CI.username NOT LIKE '%BetTrade%'
		AND	NOT EXISTS (SELECT 1 FROM dbo.f_GetCurrencyTest() AS ct WHERE ct.currency = ci.currency)
		
	INSERT INTO #DCS_Master (custID,bitmapOrder,IsDisabled,IsHidden,IsSync)
	SELECT CPS.CustID,T.bitmapOrder,(SELECT * FROM  CheckCustDB.dbo.f_CustSetting_ProductStatusSel (cps.bitmapIsDisabled,T.bitmapOrder))
		, (SELECT * FROM  CheckCustDB.dbo.f_CustSetting_ProductStatusSel (cps.bitmapIsHidden,T.bitmapOrder))
		,(SELECT * FROM  CheckCustDB.dbo.f_CustSetting_ProductStatusSel (cps.bitmapHasSynced,T.bitmapOrder))
	FROM CheckCustDB.dbo.CustProductStatus CPS (NOLOCK)
		INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON CPS.CustID = CI.custid
		INNER JOIN CheckCustDB.dbo.CustSuper CS WITH (NOLOCK)  ON CI.srecommend = CS.custid AND CS.IsInternal = 0 
		CROSS APPLY (SELECT bitmapOrder FROM #ProductStatusProfile)	AS T
	WHERE CI.roleid = 3 
		AND cs.CustID IN (SELECT CustID FROM #DCS_Super)
		AND (CheckCustDB.dbo.f_GetProductStatus (cps.bitmapIsDisabled,T.bitmapOrder) = 1 
			OR CheckCustDB.dbo.f_GetProductStatus (cps.bitmapIsHidden,T.bitmapOrder) = 1 
			OR CheckCustDB.dbo.f_GetProductStatus (cps.bitmapHasSynced,T.bitmapOrder) = 0
			)
		AND ci.srecommend NOT IN (SELECT custid FROM CheckCustDB.dbo.Dep_CustSuper WITH(NOLOCK))
		AND CI.Enabled = 1
		AND CI.Currency NOT IN (0,20,72,27)
		AND CI.username NOT LIKE '%Acc%'
		AND CI.username NOT LIKE '%3rdSuper%'
		AND CI.username NOT LIKE 'STEST%'
		AND CI.username NOT LIKE '%cashout%'
		AND CI.username NOT LIKE '%dummy%'
		AND CI.username NOT LIKE '%BetTrade%'
		AND	NOT EXISTS (SELECT 1 FROM dbo.f_GetCurrencyTest() AS ct WHERE ct.currency = ci.currency)
		
	INSERT INTO #DCS_Agent (custID,bitmapOrder,IsDisabled,IsHidden,IsSync)
	SELECT CPS.CustID,T.bitmapOrder,CheckCustDB.dbo.f_GetProductStatus (cps.bitmapIsDisabled,T.bitmapOrder), CheckCustDB.dbo.f_GetProductStatus (cps.bitmapIsHidden,T.bitmapOrder),CheckCustDB.dbo.f_GetProductStatus (cps.bitmapHasSynced,T.bitmapOrder)
	FROM CheckCustDB.dbo.CustProductStatus CPS (NOLOCK)
		INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON CPS.CustID = CI.custid
		INNER JOIN CheckCustDB.dbo.CustSuper CS WITH (NOLOCK)  ON CI.srecommend = CS.custid AND CS.IsInternal = 0 
		CROSS APPLY (SELECT bitmapOrder FROM #ProductStatusProfile)	AS T
	WHERE CI.roleid = 2 
		AND cs.CustID IN (SELECT CustID FROM #DCS_Super)
		AND (CheckCustDB.dbo.f_GetProductStatus (cps.bitmapIsDisabled,T.bitmapOrder) = 1 
			OR CheckCustDB.dbo.f_GetProductStatus (cps.bitmapIsHidden,T.bitmapOrder) = 1 
			OR CheckCustDB.dbo.f_GetProductStatus (cps.bitmapHasSynced,T.bitmapOrder) = 0
			)
		AND ci.srecommend NOT IN (SELECT custid FROM CheckCustDB.dbo.Dep_CustSuper WITH(NOLOCK))
		AND CI.Enabled = 1
		AND CI.Currency NOT IN (0,20,72,27)
		AND CI.username NOT LIKE '%Acc%'
		AND CI.username NOT LIKE '%3rdSuper%'
		AND CI.username NOT LIKE 'STEST%'
		AND CI.username NOT LIKE '%cashout%'
		AND CI.username NOT LIKE '%dummy%'
		AND CI.username NOT LIKE '%BetTrade%'
		AND	NOT EXISTS (SELECT 1 FROM dbo.f_GetCurrencyTest() AS ct WHERE ct.currency = ci.currency)
	-------------------END OF PREPARATION: GET LIST SUPER/Master/Agent disabled FIRST----------------------------
	----------------------------FINAL RESULT ------------------------------------
	-- Rule 1: Super IsDisabled= 1, Master IsDisabled = 0		
	IF @RuleId IN (0,1)
	BEGIN
		INSERT INTO CheckStatusResult_DCS (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		SELECT 1, PSP.Sporttype,PSP.Bettype, ci.custid AS MasterID,ci.srecommend,0,1,GETDATE() , 0
		FROM #DCS_Super S
			INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON S.CustID = CI.srecommend AND CI.roleid = 3
			INNER JOIN CheckCustDB.dbo.CustProductStatus CPS WITH (NOLOCK) ON CI.custid = CPS.CustID 
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
	END
	-- Rule 2: Master IsDisabled= 1, Agent IsDisabled = 0		
	IF @RuleId IN (0,2)
	BEGIN
		INSERT INTO CheckStatusResult_DCS (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit)
		SELECT 2, PSP.Sporttype,PSP.Bettype, ci.custid AS AgentID, ci.mrecommend,0,1,GETDATE(),0 
		FROM #DCS_Master m
			INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON m.CustID = CI.mrecommend AND CI.roleid = 2
			INNER JOIN CheckCustDB.dbo.CustProductStatus CPS WITH (NOLOCK) ON CI.custid = CPS.CustID 
			INNER JOIN #ProductStatusProfile PSP WITH (NOLOCK) ON M.bitmapOrder = PSP.bitmapOrder
		WHERE CI.Enabled = 1
			AND CheckCustDB.dbo.f_GetProductStatus (cps.bitmapIsDisabled,m.bitmapOrder) = 0
			AND M.IsDisabled = 1
			AND CI.username NOT LIKE '%Acc%'
			AND CI.username NOT LIKE '%3rdSuper%'
			AND CI.username NOT LIKE 'STEST%'
			AND CI.username NOT LIKE '%cashout%'
			AND CI.username NOT LIKE '%dummy%'
			AND CI.username NOT LIKE '%BetTrade%'
	END	
	-- Rule 3: Agent IsDisabled= 1, Member IsDisabled = 0		
	IF @RuleId IN (0,3)
	BEGIN
		INSERT INTO CheckStatusResult_DCS (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit)
		SELECT 3, PSP.Sporttype,PSP.Bettype, ci.custid AS MemberID,ci.recommend,0,1,GETDATE(),0 
		FROM #DCS_Agent a
			INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON a.CustID = CI.recommend AND CI.roleid = 1
			INNER JOIN CheckCustDB.dbo.CustProductStatus CPS WITH (NOLOCK) ON CI.custid = CPS.CustID 
			INNER JOIN #ProductStatusProfile PSP WITH (NOLOCK) ON A.bitmapOrder = PSP.bitmapOrder
		WHERE CI.Enabled = 1
			AND CheckCustDB.dbo.f_GetProductStatus (cps.bitmapIsDisabled,a.bitmapOrder) = 0
			AND A.IsDisabled = 1
			AND ci.custid NOT IN (20696396) --(20696396:QW107AA121)
			AND CI.username NOT LIKE '%Acc%'
			AND CI.username NOT LIKE '%3rdSuper%'
			AND CI.username NOT LIKE 'STEST%'
			AND CI.username NOT LIKE '%cashout%'
			AND CI.username NOT LIKE '%dummy%'
			AND CI.username NOT LIKE '%BetTrade%'
	END
	-- Rule 4: Super IsHidden= 1, Master IsHidden= 0		
	IF @RuleId IN (0,4)
	BEGIN
	
		INSERT INTO CheckStatusResult_DCS (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit)
		SELECT 4, PSP.Sporttype,PSP.Bettype, ci.custid AS MasterID,ci.srecommend,0,1,GETDATE(), 0 
		FROM #DCS_Super S
			INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON S.CustID = CI.srecommend AND CI.roleid = 3
			INNER JOIN CheckCustDB.dbo.CustProductStatus CPS WITH (NOLOCK) ON CI.custid = CPS.CustID 
			INNER JOIN #ProductStatusProfile PSP WITH (NOLOCK) ON S.bitmapOrder = PSP.bitmapOrder
		WHERE CI.Enabled = 1
			AND CheckCustDB.dbo.f_GetProductStatus (cps.bitmapIsHidden,s.bitmapOrder) = 0
			AND S.IsHidden = 1
			AND CI.username NOT LIKE '%Acc%'
			AND CI.username NOT LIKE '%3rdSuper%'
			AND CI.username NOT LIKE 'STEST%'
			AND CI.username NOT LIKE '%cashout%'
			AND CI.username NOT LIKE '%dummy%'
			AND CI.username NOT LIKE '%BetTrade%'
	END
	-- Rule 5: Master IsHidden= 1, Agent IsHidden= 0		
	IF @RuleId IN (0,5)
	BEGIN
		INSERT INTO CheckStatusResult_DCS (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit)
		SELECT 5, PSP.Sporttype,PSP.Bettype, ci.custid AS AgentID, ci.mrecommend,0,1,GETDATE(), 0 
		FROM #DCS_Master m
			INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON m.CustID = CI.mrecommend AND CI.roleid = 2
			INNER JOIN CheckCustDB.dbo.CustProductStatus CPS WITH (NOLOCK) ON CI.custid = CPS.CustID 
			INNER JOIN #ProductStatusProfile PSP WITH (NOLOCK) ON M.bitmapOrder = PSP.bitmapOrder
		WHERE CI.Enabled = 1
			AND CheckCustDB.dbo.f_GetProductStatus (cps.bitmapIsHidden,m.bitmapOrder) = 0
			AND m.IsHidden = 1
			AND CI.username NOT LIKE '%Acc%'
			AND CI.username NOT LIKE '%3rdSuper%'
			AND CI.username NOT LIKE 'STEST%'
			AND CI.username NOT LIKE '%cashout%'
			AND CI.username NOT LIKE '%dummy%'
			AND CI.username NOT LIKE '%BetTrade%'
	END	
	-- Rule 6: Agent IsHidden= 1, Member IsHidden= 0		 
	IF @RuleId IN (0,6)
	BEGIN
	
		INSERT INTO CheckStatusResult_DCS (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate, IsDeposit)
		SELECT 6, PSP.Sporttype,PSP.Bettype, ci.custid AS MemberID,ci.recommend,0,1,GETDATE(), 0 
		FROM #DCS_Agent a
			INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON a.CustID = CI.recommend AND CI.roleid = 1
			INNER JOIN CheckCustDB.dbo.CustProductStatus CPS WITH (NOLOCK) ON CI.custid = CPS.CustID 
			INNER JOIN #ProductStatusProfile PSP WITH (NOLOCK) ON A.bitmapOrder = PSP.bitmapOrder
		WHERE CI.Enabled = 1
			AND CheckCustDB.dbo.f_GetProductStatus (cps.bitmapIsHidden,a.bitmapOrder) = 0
			AND a.IsHidden = 1
			AND ci.custid NOT IN (20696396) --(20696396:QW107AA121)
			AND CI.username NOT LIKE '%Acc%'
			AND CI.username NOT LIKE '%3rdSuper%'
			AND CI.username NOT LIKE 'STEST%'
			AND CI.username NOT LIKE '%cashout%'
			AND CI.username NOT LIKE '%dummy%'
			AND CI.username NOT LIKE '%BetTrade%'
	
	END		
	
	-- Rule 7: IsSync= 0, IsHidden= 0		 
	IF @RuleId IN (0,7)
	BEGIN
	
		INSERT INTO CheckStatusResult_DCS (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit)
		-- Super Level
		SELECT 7, PSP.Sporttype,PSP.Bettype, ci.custid,ci.custid,0,0,GETDATE(),0 
		FROM #DCS_Super a
			INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON a.CustID = CI.CustID
			INNER JOIN #ProductStatusProfile PSP WITH (NOLOCK) ON A.bitmapOrder = PSP.bitmapOrder
		WHERE CI.Enabled = 1 AND a.IsSync = 0 AND A.IsHidden = 0
			AND CI.username NOT LIKE '%Acc%'
			AND CI.username NOT LIKE '%3rdSuper%'
			AND CI.username NOT LIKE 'STEST%'
			AND CI.username NOT LIKE '%cashout%'
			AND CI.username NOT LIKE '%dummy%'
			AND CI.username NOT LIKE '%BetTrade%'	
		
		-- Master Level
		UNION ALL
		
		SELECT 7, PSP.Sporttype,PSP.Bettype, ci.custid,ci.custid,0,0,GETDATE(),0 
		FROM #DCS_Master a
			INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON a.CustID = CI.custID
			INNER JOIN #ProductStatusProfile PSP WITH (NOLOCK) ON A.bitmapOrder = PSP.bitmapOrder
		WHERE CI.Enabled = 1 AND a.IsSync = 0 AND A.IsHidden = 0
			AND CI.username NOT LIKE '%Acc%'
			AND CI.username NOT LIKE '%3rdSuper%'
			AND CI.username NOT LIKE 'STEST%'
			AND CI.username NOT LIKE '%cashout%'
			AND CI.username NOT LIKE '%dummy%'
			AND CI.username NOT LIKE '%BetTrade%'
		
		-- Agent Level
		UNION ALL
		
		SELECT 7, PSP.Sporttype,PSP.Bettype, ci.custid,ci.custid,0,0,GETDATE(),0 
		FROM #DCS_Agent a
			INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON a.CustID = CI.custid 
			INNER JOIN #ProductStatusProfile PSP WITH (NOLOCK) ON A.bitmapOrder = PSP.bitmapOrder
		WHERE CI.Enabled = 1 AND a.IsSync = 0 AND A.IsHidden = 0	
			AND CI.username NOT LIKE '%Acc%'
			AND CI.username NOT LIKE '%3rdSuper%'
			AND CI.username NOT LIKE 'STEST%'
			AND CI.username NOT LIKE '%cashout%'
			AND CI.username NOT LIKE '%dummy%'
			AND CI.username NOT LIKE '%BetTrade%'
		
		-- Member Level
		UNION ALL
		
		SELECT 7, PSP.Sporttype,PSP.Bettype, ci.custid,ci.custid,0,0,GETDATE(),0 
		FROM CheckCustDB.dbo.custInfo CI (NOLOCK) 
			INNER JOIN CheckCustDB.dbo.CustSuper CS WITH (NOLOCK)  ON CI.srecommend = CS.custid AND CS.IsInternal = 0 
			INNER JOIN CheckCustDB.dbo.CustProductStatus CPS WITH (NOLOCK) ON CI.custid = CPS.CustID AND CI.roleid = 1
			CROSS APPLY (SELECT PSP.Sporttype,PSP.Bettype,PSP.bitmapOrder FROM  #ProductStatusProfile PSP) PSP
		WHERE CI.Enabled = 1 AND CheckCustDB.dbo.f_GetProductStatus (cps.bitmapHasSynced,psp.bitmapOrder) = 0 AND CheckCustDB.dbo.f_GetProductStatus(cps.bitmapIsHidden,psp.bitmapOrder) = 0
			AND ci.srecommend NOT IN (SELECT custid FROM CheckCustDB.dbo.Dep_CustSuper WITH(NOLOCK))
			AND CI.Currency NOT IN (0,20,72,27)
			AND ci.custid NOT IN (20696396) --(20696396:QW107AA121)
			AND CI.username NOT LIKE '%Acc%'
			AND CI.username NOT LIKE '%3rdSuper%'
			AND CI.username NOT LIKE 'STEST%'
			AND CI.username NOT LIKE '%cashout%'
			AND CI.username NOT LIKE '%dummy%'
			AND CI.username NOT LIKE '%BetTrade%'
	END	
	
	-- Rule 8: IsSync= 0, IsDisable= 0		 
	IF @RuleId IN (0,8)
	BEGIN
	
		INSERT INTO CheckStatusResult_DCS (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit)
		-- Super Level
		SELECT 8, PSP.Sporttype,PSP.Bettype, ci.custid,ci.custid,0,0,GETDATE(),0 
		FROM #DCS_Super a
			INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON a.CustID = CI.custID
			INNER JOIN #ProductStatusProfile PSP WITH (NOLOCK) ON A.bitmapOrder = PSP.bitmapOrder
		WHERE CI.Enabled = 1 AND a.IsSync = 0 AND A.IsDisabled = 0
			AND CI.username NOT LIKE '%Acc%'
			AND CI.username NOT LIKE '%3rdSuper%'
			AND CI.username NOT LIKE 'STEST%'
			AND CI.username NOT LIKE '%cashout%'
			AND CI.username NOT LIKE '%dummy%'
			AND CI.username NOT LIKE '%BetTrade%'	
		--Master Level
		UNION ALL
		
		SELECT 8, PSP.Sporttype,PSP.Bettype, ci.custid,ci.custid,0,0,GETDATE(),0 
		FROM #DCS_Master a
			INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON a.CustID = CI.custid
			INNER JOIN #ProductStatusProfile PSP WITH (NOLOCK) ON A.bitmapOrder = PSP.bitmapOrder
		WHERE CI.Enabled = 1 AND a.IsSync = 0 AND A.IsDisabled = 0
			AND CI.username NOT LIKE '%Acc%'
			AND CI.username NOT LIKE '%3rdSuper%'
			AND CI.username NOT LIKE 'STEST%'
			AND CI.username NOT LIKE '%cashout%'
			AND CI.username NOT LIKE '%dummy%'
			AND CI.username NOT LIKE '%BetTrade%'	
		-- Agent Level
		UNION ALL
		
		SELECT 8, PSP.Sporttype,PSP.Bettype, ci.custid,ci.custid,0,0,GETDATE(),0 
		FROM #DCS_Agent a
			INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON a.CustID = CI.custid
			INNER JOIN #ProductStatusProfile PSP WITH (NOLOCK) ON A.bitmapOrder = PSP.bitmapOrder
		WHERE CI.Enabled = 1 AND a.IsSync = 0 AND A.IsDisabled = 0	
			AND CI.username NOT LIKE '%Acc%'
			AND CI.username NOT LIKE '%3rdSuper%'
			AND CI.username NOT LIKE 'STEST%'
			AND CI.username NOT LIKE '%cashout%'
			AND CI.username NOT LIKE '%dummy%'
			AND CI.username NOT LIKE '%BetTrade%'
		-- Member Level
		UNION ALL
		
		SELECT 8, PSP.Sporttype,PSP.Bettype, ci.custid,ci.custid,0,0,GETDATE(),0 
		FROM CheckCustDB.dbo.custInfo CI (NOLOCK) 
			INNER JOIN CheckCustDB.dbo.CustSuper CS WITH (NOLOCK)  ON CI.srecommend = CS.custid AND CS.IsInternal = 0 
			INNER JOIN CheckCustDB.dbo.CustProductStatus CPS WITH (NOLOCK) ON CI.custid = CPS.CustID AND CI.roleid = 1
			CROSS APPLY (SELECT PSP.Sporttype,PSP.Bettype,PSP.bitmapOrder FROM  #ProductStatusProfile PSP) PSP
		WHERE CI.Enabled = 1 AND CheckCustDB.dbo.f_GetProductStatus (cps.bitmapHasSynced,psp.bitmapOrder) = 0 AND CheckCustDB.dbo.f_GetProductStatus(cps.bitmapIsDisabled,psp.bitmapOrder) = 0
			AND ci.srecommend NOT IN (SELECT custid FROM CheckCustDB.dbo.Dep_CustSuper WITH(NOLOCK))
			AND CI.Currency NOT IN (0,20,72,27)
			AND ci.custid NOT IN (20696396) --(20696396:QW107AA121)
			AND CI.username NOT LIKE '%Acc%'
			AND CI.username NOT LIKE '%3rdSuper%'
			AND CI.username NOT LIKE 'STEST%'
			AND CI.username NOT LIKE '%cashout%'
			AND CI.username NOT LIKE '%dummy%'
			AND CI.username NOT LIKE '%BetTrade%'
	END	
	
	-- Rule 9: Missing Product Status setting in the table CustProductStatus/CustProductStatus		
	IF @RuleId IN (0,9)
	BEGIN
		INSERT INTO CheckStatusResult_DCS (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit)
		SELECT 9, NULL,NULL, ci.custid,ci.custid,0,1,GETDATE(),0 
		FROM CheckCustDB.dbo.custInfo CI (NOLOCK)			
			INNER JOIN CheckCustDB.dbo.CustSuper CS WITH (NOLOCK)  ON CI.srecommend = CS.custid AND CS.IsInternal = 0 
			INNER JOIN 	CheckCustDB.dbo.customer C (NOLOCK) ON ci.custid = c.custid
		WHERE CI.Enabled = 1 AND NOT EXISTS (SELECT 1 FROM CheckCustDB.dbo.CustProductStatus CPS WITH (NOLOCK) WHERE CI.custid = CPS.CustID)
			AND ci.srecommend NOT IN (SELECT custid FROM CheckCustDB.dbo.Dep_CustSuper WITH(NOLOCK))
			AND CI.Currency NOT IN (0,20,72,27)
			AND ci.custid NOT IN (20696396) --(20696396:QW107AA121)
			AND CI.username NOT LIKE '%Acc%'
			AND CI.username NOT LIKE '%3rdSuper%'
			AND CI.username NOT LIKE 'STEST%'
			AND CI.username NOT LIKE '%cashout%'
			AND CI.username NOT LIKE '%dummy%'
			AND CI.username NOT LIKE '%BetTrade%'
			AND c.site <> 'CN88'
	END	
	------------------------ adding rule 10,11,12 ------------------------------------------------------------------------------------------
	-- Rule 10: Super IsSync= 0, Master IsSync = 1
	IF @RuleId IN (0,10)
	BEGIN
		INSERT INTO CheckStatusResult_DCS (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		SELECT 10, PSP.Sporttype,PSP.Bettype, ci.custid AS MasterID,ci.srecommend,1,0,GETDATE() , 0
		FROM #DCS_Super S
			INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON S.CustID = CI.srecommend AND CI.roleid = 3
			INNER JOIN CheckCustDB.dbo.CustProductStatus CPS WITH (NOLOCK) ON CI.custid = CPS.CustID 
			INNER JOIN #ProductStatusProfile PSP WITH (NOLOCK) ON S.bitmapOrder = PSP.bitmapOrder
		WHERE CI.Enabled = 1
			AND CheckCustDB.dbo.f_GetProductStatus (cps.bitmapHasSynced,s.bitmapOrder) = 1
			AND S.IsSync = 0
			AND CI.username NOT LIKE '%Acc%'
			AND CI.username NOT LIKE '%3rdSuper%'
			AND CI.username NOT LIKE 'STEST%'
			AND CI.username NOT LIKE '%cashout%'
			AND CI.username NOT LIKE '%dummy%'
			AND CI.username NOT LIKE '%BetTrade%'
	END
	-- Rule 11: Master IsSync= 0, Agent IsSync = 1		
	IF @RuleId IN (0,11)
	BEGIN
		INSERT INTO CheckStatusResult_DCS (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit)
		SELECT 11, PSP.Sporttype,PSP.Bettype, ci.custid AS AgentID, ci.mrecommend,1,0,GETDATE(),0 
		FROM #DCS_Master m
			INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON m.CustID = CI.mrecommend AND CI.roleid = 2
			INNER JOIN CheckCustDB.dbo.CustProductStatus CPS WITH (NOLOCK) ON CI.custid = CPS.CustID 
			INNER JOIN #ProductStatusProfile PSP WITH (NOLOCK) ON M.bitmapOrder = PSP.bitmapOrder
		WHERE CI.Enabled = 1
			AND CheckCustDB.dbo.f_GetProductStatus (cps.bitmapHasSynced,m.bitmapOrder) = 1
			AND M.IsSync = 0
			AND CI.username NOT LIKE '%Acc%'
			AND CI.username NOT LIKE '%3rdSuper%'
			AND CI.username NOT LIKE 'STEST%'
			AND CI.username NOT LIKE '%cashout%'
			AND CI.username NOT LIKE '%dummy%'
			AND CI.username NOT LIKE '%BetTrade%'
	END	
	-- Rule 12: Agent IsSync= 0, Member IsSync = 1		
	IF @RuleId IN (0,12)
	BEGIN
		INSERT INTO CheckStatusResult_DCS (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit)
		SELECT 12, PSP.Sporttype,PSP.Bettype, ci.custid AS MemberID,ci.recommend,1,0,GETDATE(),0 
		FROM #DCS_Agent a
			INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON a.CustID = CI.recommend AND CI.roleid = 1
			INNER JOIN CheckCustDB.dbo.CustProductStatus CPS WITH (NOLOCK) ON CI.custid = CPS.CustID 
			INNER JOIN #ProductStatusProfile PSP WITH (NOLOCK) ON A.bitmapOrder = PSP.bitmapOrder
		WHERE CI.Enabled = 1
			AND CheckCustDB.dbo.f_GetProductStatus (cps.bitmapHasSynced,a.bitmapOrder) = 1
			AND A.IsSync = 0
			AND ci.custid NOT IN (20696396) --(20696396:QW107AA121)
	END
	
	--Rule 13: Super IsSync= 0 (For VB,AB)
	IF @RuleId IN (0,13)
	BEGIN
		INSERT INTO CheckStatusResult_DCS (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		SELECT 13, PSP.Sporttype,PSP.Bettype, s.custid ,s.custID,0,0,GETDATE() , 0
		FROM #DCS_Super S
			INNER JOIN #ProductStatusProfile PSP WITH (NOLOCK) ON S.bitmapOrder = PSP.bitmapOrder
		WHERE S.IsSync = 0
			AND psp.SportType IN (211,212)
	END
	
	--Rule 14: Master IsSync= 0 (For VB,AB)
	IF @RuleId IN (0,14)
	BEGIN
		INSERT INTO CheckStatusResult_DCS (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		SELECT 14, PSP.Sporttype,PSP.Bettype, m.custid ,m.custID,0,0,GETDATE() , 0
		FROM #DCS_Master m
			INNER JOIN #ProductStatusProfile PSP WITH (NOLOCK) ON m.bitmapOrder = PSP.bitmapOrder
		WHERE m.IsSync = 0
			AND psp.SportType IN (211,212)
	END
	
	--Rule 15: Agent IsSync= 0 (For VB,AB)
	IF @RuleId IN (0,15)
	BEGIN
		INSERT INTO CheckStatusResult_DCS (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		SELECT 15, PSP.Sporttype,PSP.Bettype, a.custid ,a.custID,0,0,GETDATE() , 0
		FROM #DCS_Agent a
			INNER JOIN #ProductStatusProfile PSP WITH (NOLOCK) ON a.bitmapOrder = PSP.bitmapOrder
		WHERE a.IsSync = 0
			AND psp.SportType IN (211,212)
	END
	
	--Rule 16: Member IsSync= 0 (For VB,AB)
	IF @RuleId IN (0,16) 
	BEGIN
		INSERT INTO CheckStatusResult_DCS (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		SELECT 16, PSP.Sporttype,PSP.Bettype, CI.custid ,CI.custID,0,0,GETDATE() , 0
		FROM CheckCustDB.dbo.CustProductStatus CPS (NOLOCK)
			INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON CPS.CustID = CI.custid
			INNER JOIN CheckCustDB.dbo.CustSuper CS WITH (NOLOCK)  ON CI.srecommend = CS.custid AND CS.IsInternal = 0 
			CROSS APPLY (SELECT bitmapOrder FROM #ProductStatusProfile)	AS T
			INNER JOIN #ProductStatusProfile PSP WITH (NOLOCK) ON T.bitmapOrder = PSP.bitmapOrder
		WHERE CI.roleid = 1 
			AND cs.CustID IN (SELECT CustID FROM #DCS_Super)
			AND CheckCustDB.dbo.f_GetProductStatus (cps.bitmapHasSynced,T.bitmapOrder) = 0				
			AND ci.srecommend NOT IN (SELECT custid FROM CheckCustDB.dbo.Dep_CustSuper WITH(NOLOCK))
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (0,20,72,27)
			AND CI.username NOT LIKE '%Acc%'
			AND CI.username NOT LIKE '%3rdSuper%'
			AND CI.username NOT LIKE 'STEST%'
			AND CI.username NOT LIKE '%cashout%'
			AND CI.username NOT LIKE '%dummy%'
			AND CI.username NOT LIKE '%BetTrade%'
			AND PSP.SportType IN (211,212)
	END
	
	DROP TABLE #DCS_Agent
	DROP TABLE #DCS_Master
	DROP TABLE #DCS_Super
	DROP TABLE #ProductStatusProfile	

	SET NOCOUNT OFF	
		
END
GO