/*<info serverAlias="DBCHECK-CheckResultDB" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_CheckBetLimit_Credit_DCS]
	@srecommend INT
	,@RuleId	SMALLINT = 0
	,@SportType SMALLINT = 0
AS
/*
Created: 20170328@Helen
Task: weekly check bet limit setting for credit/deposit customers - [Redmine:73556]
DB: DBCHECK.CheckResultDB
Revisions:
	-20180802@Johnson: update ruleid [redmine: #73556]
	-20201118@Eden: Insert New SettingType = 20, new rules [Redmine: #131370]
	-20220407@Winfred: Exclude Inactive Site MA and Member [redmine:#171114]
Param's Explanation: 

	CustBetSetting3rd_Member, CustBetSetting3rd_Agent
*/

BEGIN 

	SET NOCOUNT ON 	
	-------------------PREPARATION: GET LIST SUPER/Master/Agent disabled FIRST----------------------------
		
	CREATE TABLE #DCS_Super (custID INT,SportType SMALLINT, BetType SMALLINT, minbet MONEY, maxbet MONEY, maxpermatch MONEY)
	CREATE TABLE #DCS_Master (custID INT, UplineID INT,SportType SMALLINT, BetType SMALLINT, minbet MONEY, maxbet MONEY, maxpermatch MONEY)
	CREATE TABLE #DCS_Agent (custID INT,UplineID INT,SportType SMALLINT, BetType SMALLINT, minbet MONEY, maxbet MONEY, maxpermatch MONEY)
	CREATE TABLE #OfferedProductList(ProductID [tinyint],[SportType] [smallint] ,[BetType] [smallint], IsHidden BIT,RealProductID TINYINT)
	CREATE TABLE #GlobalSetting([SportType] [smallint] ,[BetType] [smallint], Maxbet [MONEY], Minbet [MONEY])
	
	DECLARE @SportBettypeFilter TABLE(SportType INT, Bettype INT, SettingType SMALLINT)
	DECLARE @currency INT,@Site VARCHAR(10), @SiteID INT, @Rowcount INT
	DECLARE @GlobalMaxBet money
	
	SELECT @currency = currency,@site = site 
	FROM CheckCustDB.dbo.customer WITH(NOLOCK)
	WHERE custid = @srecommend
	
	SELECT @SiteID = SiteID
	FROM CheckCustDB.dbo.site WITH(NOLOCK)
	WHERE site = @site
	
	--product has offered stakelevel
	INSERT INTO #OfferedProductList (ProductID,SportType,BetType,IsHidden,RealProductID)
	SELECT ProductID,Sporttype,Bettype,IsHidden,RealProductId
	FROM CheckCustDB.dbo.ProductSettingDetail ps2 WITH(NOLOCK)
	WHERE ps2.SettingType in (4,11,13) 
		AND ps2.SettingStatus = 0 
			
	UPDATE op
	SET op.IsHidden = stt.IsHidden
	FROM #OfferedProductList op
		INNER JOIN CheckCustDB.dbo.ProductStatusSiteCurrency stt WITH(NOLOCK) ON op.SportType = stt.SportType AND op.Bettype = stt.Bettype
	WHERE stt.Currency = @Currency AND (stt.SiteID = @SiteID OR stt.SiteID = 0)
			
	UPDATE op
	SET op.IsHidden = stt.IsHidden
	FROM #OfferedProductList op
		INNER JOIN CheckCustDB.dbo.ProductStatusSiteCurrency stt WITH(NOLOCK) ON op.SportType = stt.SportType AND op.Bettype = stt.Bettype
	WHERE (stt.Currency = @Currency OR stt.Currency = 0 ) AND stt.SiteID = @SiteID

	INSERT INTO @sportBettypeFilter (sportType,bettype,SettingType)
	SELECT ps.SportType,ps.BetType,ps.SettingType
	FROM CheckCustDB.dbo.ProductSettingDetail ps WITH(NOLOCK)
		CROSS APPLY (	SELECT IsHidden
						FROM #OfferedProductList ps2
						WHERE ps2.ProductID = ps.ProductID 
							AND ps2.SportType = ps.SportType 
							AND ps2.BetType = ps.BetType
							AND ps2.IsHidden = 0 
					) ProductStatus
	WHERE SettingType in (2,9,16,20)
		AND SettingStatus = 0
		AND sportType NOT IN (SELECT sportType FROM dbo.f_GetSportNotOffer(NULL))
		AND sportType = CASE WHEN @sportType = 0 THEN sportType ELSE @sportType END
		AND ProductID = 16
	UNION ALL
	SELECT ps.SportType,ps.BetType,ps.SettingType
	FROM CheckCustDB.dbo.ProductSettingDetail ps WITH(NOLOCK)
		CROSS APPLY (	SELECT IsHidden
						FROM #OfferedProductList ps2
						WHERE ps2.RealProductId = ps.RealProductId 
							AND ps2.IsHidden = 0
					) ProductStatus
	WHERE SettingType in (2,9,16,20)
		AND SettingStatus = 0
		AND sportType NOT IN (SELECT sportType FROM dbo.f_GetSportNotOffer(NULL))
		AND sportType = CASE WHEN @sportType = 0 THEN sportType ELSE @sportType END
		AND ProductID <> 16
	
	SELECT @Rowcount = count(1)
	FROM @SportBettypeFilter

	IF @Rowcount = 0
		RETURN	

	INSERT INTO #GlobalSetting(SportType,BetType,Maxbet,Minbet)
	SELECT s.Sporttype,s.Bettype,ISNULL(s.MaxBet,0),ISNULL(s.MinBet,0)
	FROM CheckCustDB.dbo.ProductBetSetting s WITH(NOLOCK) 
		INNER JOIN @SportBettypeFilter p ON p.SportType = s.Sporttype AND p.Bettype = s.Bettype AND p.SettingType = 20
	WHERE s.Currency = @currency 
		AND (ISNULL(s.MaxBet,0) <> 0 OR ISNULL(s.MinBet,0) <> 0)
	
	INSERT INTO #DCS_Super (custID,SportType,BetType,minbet,maxbet,maxpermatch)
	SELECT CPS.CustID,CPS.SportType,CPS.BetType,cps.MinBet,CPS.MaxBet,cps.MaxPerMatch
	FROM CheckCustDB.dbo.CustBetSetting3rd_Agent CPS (NOLOCK)
		INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON CPS.CustID = CI.custid
		INNER JOIN CheckCustDB.dbo.customer c 	 WITH (NOLOCK) ON ci.CustID = c.CustID
		INNER JOIN CheckCustDB.dbo.CustSuper CS WITH (NOLOCK)  ON CI.srecommend = CS.custid AND CS.IsInternal = 0
		INNER JOIN @SportBettypeFilter T ON T.SportType = CPS.SportType AND T.BetType = CPS.Bettype
	WHERE CI.roleid = 4 
		AND	NOT EXISTS (SELECT 1 FROM dbo.f_GetSiteNotOffer() AS nos WHERE nos.site = c.site)	
		AND ci.srecommend = @srecommend
		AND CI.Enabled = 1
		AND CI.Currency NOT IN (20,72,27,28)
		AND (cps.MinBet <> 0 OR CPS.MaxBet <> 0 OR CPS.maxpermatch <> 0)
		
	INSERT INTO #DCS_Master (custID,UplineID,SportType,BetType,minbet,maxbet,maxpermatch)
	SELECT CPS.CustID,ci.srecommend,cps.SportType,cps.BetType,cps.MinBet,CPS.MaxBet,cps.MaxPerMatch
	FROM CheckCustDB.dbo.CustBetSetting3rd_Agent CPS (NOLOCK)
		INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON CPS.CustID = CI.custid
		INNER JOIN CheckCustDB.dbo.customer c 	 WITH (NOLOCK) ON ci.CustID = c.CustID
		INNER JOIN CheckCustDB.dbo.CustSuper CS WITH (NOLOCK)  ON CI.srecommend = CS.custid AND CS.IsInternal = 0 
		INNER JOIN @SportBettypeFilter T ON T.SportType = CPS.SportType AND T.BetType = CPS.Bettype
	WHERE CI.roleid = 3 
		AND	NOT EXISTS (SELECT 1 FROM dbo.f_GetSiteNotOffer() AS nos WHERE nos.site = c.site)	
		AND ci.srecommend = @srecommend
		AND CI.Enabled = 1
		AND CI.Currency NOT IN (20,72,27,28)
		AND (cps.MinBet <> 0 OR CPS.MaxBet <> 0 OR CPS.maxpermatch <> 0)
			
	INSERT INTO #DCS_Agent (custID,UplineID,SportType,BetType,minbet,maxbet,maxpermatch)
	SELECT CPS.CustID,ci.mrecommend,cps.SportType,cps.BetType,cps.MinBet,CPS.MaxBet,cps.MaxPerMatch
	FROM CheckCustDB.dbo.CustBetSetting3rd_Agent CPS (NOLOCK)
		INNER JOIN CheckCustDB.dbo.custInfo CI (NOLOCK) ON CPS.CustID = CI.custid
		INNER JOIN CheckCustDB.dbo.customer c 	 WITH (NOLOCK) ON ci.CustID = c.CustID
		INNER JOIN CheckCustDB.dbo.CustSuper CS WITH (NOLOCK)  ON CI.srecommend = CS.custid AND CS.IsInternal = 0 
		INNER JOIN @SportBettypeFilter T ON T.SportType = CPS.SportType AND T.BetType = CPS.Bettype
	WHERE CI.roleid = 2 
		AND	NOT EXISTS (SELECT 1 FROM dbo.f_GetSiteNotOffer() AS nos WHERE nos.site = c.site)	
		AND ci.srecommend = @srecommend
		AND CI.Enabled = 1
		AND CI.Currency NOT IN (20,72,27,28)
		AND (cps.MinBet <> 0 OR CPS.MaxBet <> 0 OR CPS.maxpermatch <> 0)
	
	-------------------END OF PREPARATION: GET LIST SUPER/Master/Agent disabled FIRST----------------------------
	----------------------------FINAL RESULT ------------------------------------
	DECLARE @CreatedDate DATETIME = GETDATE()
		
	-- Rule 313: Missing bet limit setting, for DCS Products								
	IF @RuleId IN (0,313)
	BEGIN
		INSERT INTO CheckBetLimitResult_DCS (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		SELECT 313,T3.SportType,T3.BetType,CI.custID,CI.custID,NULL,NULL,@CreatedDate,0
		FROM CheckCustDB.dbo.custInfo CI WITH (NOLOCK)
			INNER JOIN CheckCustDB.dbo.customer c 	 WITH (NOLOCK) ON ci.CustID = c.CustID
			CROSS JOIN @SportBettypeFilter AS T3
		WHERE CI.custid NOT IN (SELECT custID FROM #DCS_Super T5 WHERE T5.SportType = T3.SportType AND T5.BetType = T3.BetType)
			AND NOT EXISTS (SELECT 1 FROM CheckCustDB.dbo.CustBetSetting3rd_Agent T4 WITH (NOLOCK) WHERE T4.custid = CI.CustID AND T4.SportType = T3.SportType AND T4.BetType = T3.BetType)
			AND CI.roleid = 4
			AND	NOT EXISTS (SELECT 1 FROM dbo.f_GetSiteNotOffer() AS nos WHERE nos.site = c.site)	
			AND ci.srecommend = @srecommend
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
				
		UNION ALL	
		
		SELECT 313,T3.SportType,T3.BetType,CI.custID,CI.custID,NULL,NULL,@CreatedDate,0
		FROM CheckCustDB.dbo.custInfo CI WITH (NOLOCK)
			INNER JOIN CheckCustDB.dbo.customer c 	 WITH (NOLOCK) ON ci.CustID = c.CustID
			CROSS JOIN @SportBettypeFilter AS T3
		WHERE CI.custid NOT IN (SELECT custID FROM #DCS_Master T5 WHERE T5.SportType = T3.SportType AND T5.BetType = T3.BetType)
			AND NOT EXISTS (SELECT 1 FROM CheckCustDB.dbo.CustBetSetting3rd_Agent T4 WITH (NOLOCK) WHERE T4.custid = CI.CustID AND T4.SportType = T3.SportType AND T4.BetType = T3.BetType)		
			AND CI.roleid = 3
			AND	NOT EXISTS (SELECT 1 FROM dbo.f_GetSiteNotOffer() AS nos WHERE nos.site = c.site)
			AND ci.srecommend = @srecommend
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
		
		UNION ALL	
		
		SELECT 313,T3.SportType,T3.BetType,CI.custID,CI.custID,NULL,NULL,@CreatedDate,0
		FROM CheckCustDB.dbo.custInfo CI WITH (NOLOCK)
			INNER JOIN CheckCustDB.dbo.customer c 	 WITH (NOLOCK) ON ci.CustID = c.CustID
			CROSS JOIN @SportBettypeFilter AS T3
		WHERE CI.custid NOT IN (SELECT custID FROM #DCS_Agent T5 WHERE T5.SportType = T3.SportType AND T5.BetType = T3.BetType)
			AND NOT EXISTS (SELECT 1 FROM CheckCustDB.dbo.CustBetSetting3rd_Agent T4 WITH (NOLOCK) WHERE T4.custid = CI.CustID AND T4.SportType = T3.SportType AND T4.BetType = T3.BetType)		
			AND CI.roleid = 2
			AND	NOT EXISTS (SELECT 1 FROM dbo.f_GetSiteNotOffer() AS nos WHERE nos.site = c.site)
			AND ci.srecommend = @srecommend
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
		
		UNION ALL	
		
		SELECT 313,T3.SportType,T3.BetType,CI.custID,CI.custID,NULL,NULL,@CreatedDate,0
		FROM CheckCustDB.dbo.custInfo CI WITH (NOLOCK)
			INNER JOIN CheckCustDB.dbo.customer c 	 WITH (NOLOCK) ON ci.CustID = c.CustID
			CROSS JOIN @SportBettypeFilter AS T3
		WHERE NOT EXISTS (SELECT 1 FROM CheckCustDB.dbo.CustBetSetting3rd_Member T4 WITH (NOLOCK) WHERE T4.custid = CI.CustID AND T4.SportType = T3.SportType AND T4.BetType = T3.BetType)		
			AND CI.roleid = 1
			AND	NOT EXISTS (SELECT 1 FROM dbo.f_GetSiteNotOffer() AS nos WHERE nos.site = c.site)
			AND ci.srecommend = @srecommend
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
		
							
	END
	
	-- Rule 314: minbet < 0								
	IF @RuleId IN (0,314)
	BEGIN
		INSERT INTO CheckBetLimitResult_DCS (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		SELECT 314,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.minbet,T1.minbet,@CreatedDate,0
		FROM #DCS_Super T1
		WHERE T1.minbet < 0
		
		UNION ALL
		
		SELECT 314,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.minbet,T1.minbet,@CreatedDate,0
		FROM #DCS_Master T1
		WHERE T1.minbet < 0
		
		UNION ALL
		
		SELECT 314,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.minbet,T1.minbet,@CreatedDate,0
		FROM #DCS_Agent T1
		WHERE T1.minbet < 0
		
		
		UNION ALL
		
		SELECT 314,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.minbet,T1.minbet,@CreatedDate,0
		FROM CheckCustDB.dbo.CustBetSetting3rd_Member T1 WITH (NOLOCK)
			INNER JOIN  CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON T1.CustID = CI.custid
			INNER JOIN @SportBettypeFilter P ON T1.SportType = p.SportType AND T1.BetType = p.Bettype
		WHERE T1.minbet < 0
			AND ci.srecommend = @srecommend
			AND ci.roleid = 1
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
		
	END
	
	-- Rule 315: maxbet < 0										
	IF @RuleId IN (0,315)
	BEGIN
		INSERT INTO CheckBetLimitResult_DCS (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		SELECT 315,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.maxbet,T1.maxbet,@CreatedDate,0
		FROM #DCS_Super T1
		WHERE T1.maxbet < 0
		
		UNION ALL
		
		SELECT 315,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.maxbet,T1.maxbet,@CreatedDate,0
		FROM #DCS_Master T1
		WHERE T1.maxbet < 0
		
		UNION ALL
		
		SELECT 315,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.maxbet,T1.maxbet,@CreatedDate,0
		FROM #DCS_Agent T1
		WHERE T1.maxbet < 0
		
		
		UNION ALL
		
		SELECT 315,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.maxbet,T1.maxbet,@CreatedDate,0
		FROM CheckCustDB.dbo.CustBetSetting3rd_Member T1 WITH (NOLOCK)
			INNER JOIN  CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON T1.CustID = CI.custid
			INNER JOIN @SportBettypeFilter P ON T1.SportType = p.SportType AND T1.BetType = p.Bettype
		WHERE T1.maxbet < 0
			AND ci.srecommend = @srecommend
			AND ci.roleid = 1
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
		
	END
	
	-- Rule 316: max per match < 0								
	IF @RuleId IN (0,316)
	BEGIN
		INSERT INTO CheckBetLimitResult_DCS (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		SELECT 316,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.maxpermatch,T1.maxpermatch,@CreatedDate,0
		FROM #DCS_Super T1
		WHERE T1.maxpermatch < 0
		
		UNION ALL
		
		SELECT 316,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.maxpermatch,T1.maxpermatch,@CreatedDate,0
		FROM #DCS_Master T1
		WHERE T1.maxpermatch < 0
		
		UNION ALL
		
		SELECT 316,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.maxpermatch,T1.maxpermatch,@CreatedDate,0
		FROM #DCS_Agent T1
		WHERE T1.maxpermatch < 0
		
		
		UNION ALL
		
		SELECT 316,T1.SportType,T1.BetType,T1.custID,T1.custID,T1.maxpermatch,T1.maxpermatch,@CreatedDate,0
		FROM CheckCustDB.dbo.CustBetSetting3rd_Member T1 WITH (NOLOCK)
			INNER JOIN  CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON T1.CustID = CI.custid
			INNER JOIN @SportBettypeFilter P ON T1.SportType = p.SportType AND T1.BetType = p.Bettype
		WHERE T1.maxpermatch < 0
			AND ci.srecommend = @srecommend
			AND ci.roleid = 1
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
		
	END

	-- Rule 329: Maxbet > Global Maxbet -- only settingtype = 20								
	IF @RuleId IN (0,329)
	BEGIN
		INSERT INTO CheckBetLimitResult_DCS (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		SELECT 329,T1.SportType,T1.BetType,T1.custID,0,T1.maxbet,T2.Maxbet,@CreatedDate,0
		FROM #DCS_Super T1
			INNER JOIN #GlobalSetting T2 ON t1.SportType = t2.SportType AND t1.BetType = t2.BetType AND t2.Maxbet <> 0
		WHERE T1.maxbet > T2.Maxbet AND T1.Maxbet >= 1
		UNION ALL
		SELECT 329,T1.SportType,T1.BetType,T1.custID,0,T1.maxbet,T2.Maxbet,@CreatedDate,0
		FROM #DCS_Master T1
			INNER JOIN #GlobalSetting T2 ON t1.SportType = t2.SportType AND t1.BetType = t2.BetType AND t2.Maxbet <> 0
		WHERE T1.maxbet > T2.Maxbet AND T1.Maxbet >= 1
		UNION ALL
		SELECT 329,T1.SportType,T1.BetType,T1.custID,0,T1.maxbet,T2.Maxbet,@CreatedDate,0
		FROM #DCS_Agent T1
			INNER JOIN #GlobalSetting T2 ON t1.SportType = t2.SportType AND t1.BetType = t2.BetType AND t2.Maxbet <> 0
		WHERE T1.maxbet > T2.Maxbet AND T1.Maxbet >= 1
		UNION ALL
		SELECT 329,T1.SportType,T1.BetType,T1.custID,0,T1.maxbet,T2.Maxbet,@CreatedDate,0
		FROM CheckCustDB.dbo.CustBetSetting3rd_Member T1 WITH (NOLOCK)
			INNER JOIN CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON T1.CustID = CI.custid
			INNER JOIN #GlobalSetting T2 ON t1.SportType = t2.SportType AND t1.BetType = t2.BetType AND t2.Maxbet <> 0
		WHERE T1.MaxBet > t2.Maxbet AND T1.Maxbet >= 1
			AND ci.srecommend = @srecommend
			AND ci.roleid = 1
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
		
	END

	IF @RuleId IN (0,330) -- Minbet < Global Minbet -- only settingtype = 20	
	BEGIN
		INSERT INTO CheckBetLimitResult_DCS (RuleId, SportType, BetType, CustIdA, CustIdB, ValueA, ValueB, CreatedDate,IsDeposit )
		SELECT 330,T1.SportType,T1.BetType,T1.custID,0,T1.minbet,T2.minbet,@CreatedDate,0
		FROM #DCS_Super T1
			INNER JOIN #GlobalSetting T2 ON t1.SportType = t2.SportType AND t1.BetType = t2.BetType AND t2.Minbet <> 0
		WHERE T1.minbet < T2.Minbet AND T1.Maxbet >= 1
		UNION ALL
		SELECT 330,T1.SportType,T1.BetType,T1.custID,0,T1.minbet,T2.minbet,@CreatedDate,0
		FROM #DCS_Master T1
			INNER JOIN #GlobalSetting T2 ON t1.SportType = t2.SportType AND t1.BetType = t2.BetType AND t2.Minbet <> 0
		WHERE T1.minbet < T2.Minbet AND T1.Maxbet >= 1
		UNION ALL
		SELECT 330,T1.SportType,T1.BetType,T1.custID,0,T1.minbet,T2.minbet,@CreatedDate,0
		FROM #DCS_Agent T1
			INNER JOIN #GlobalSetting T2 ON t1.SportType = t2.SportType AND t1.BetType = t2.BetType AND t2.Minbet <> 0
		WHERE T1.minbet < T2.Minbet AND T1.Maxbet >= 1
		UNION ALL
		SELECT 330,T1.SportType,T1.BetType,T1.custID,0,T1.minbet,T2.minbet,@CreatedDate,0
		FROM CheckCustDB.dbo.CustBetSetting3rd_Member T1 WITH (NOLOCK)
			INNER JOIN CheckCustDB.dbo.custInfo CI WITH (NOLOCK) ON T1.CustID = CI.custid
			INNER JOIN #GlobalSetting T2 ON t1.SportType = t2.SportType AND t1.BetType = t2.BetType AND t2.Minbet <> 0
		WHERE T1.minbet < T2.Minbet AND T1.Maxbet >= 1
			AND ci.srecommend = @srecommend
			AND ci.roleid = 1
			AND CI.Enabled = 1
			AND CI.Currency NOT IN (20,72,27,28)
	END

	SET NOCOUNT OFF	
		
END