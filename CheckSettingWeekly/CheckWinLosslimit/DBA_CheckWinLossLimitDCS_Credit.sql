/*<info serverAlias="DBCHECK-CheckResultDB" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_CheckWinLossLimitDCS_Credit]
	 @srecommend INT 
	,@SportType SMALLINT = 0
	,@RuleId	SMALLINT = 0
AS
/*
	Created: 20191029@Johnson
	Task: Check winloss limit setting for credit customers for dcs product
	DB: DBCHECK.CheckResultDB
	Revisions:
		-20191025@Johnson: initial sp [redmine:#122666]
	Parameter's Explanations:
*/
BEGIN 
	SET NOCOUNT ON
	
	CREATE TABLE #SuperWinLossLimit (custid INT, sporttype SMALLINT, bettype SMALLINT, MaxWinLimit SMALLMONEY, MaxLossLimit	money, IsAutoReset BIT, PRIMARY KEY(CustID,SportType,Bettype))
	CREATE TABLE #MasterWinLossLimit (custid INT, sporttype SMALLINT, bettype SMALLINT, MaxWinLimit SMALLMONEY, MaxLossLimit	money, IsAutoReset BIT, PRIMARY KEY(CustID,SportType,Bettype))
	CREATE TABLE #AgentWinLossLimit (custid INT, mrecommend INT, sporttype SMALLINT, bettype SMALLINT, MaxWinLimit SMALLMONEY, MaxLossLimit	money, IsAutoReset BIT, PRIMARY KEY(CustID,SportType,Bettype))
	CREATE TABLE #MemberWinLossLimit (custid INT, recommend INT, mrecommend INT, sporttype SMALLINT, bettype SMALLINT, MaxWinLimit SMALLMONEY, MaxLossLimit	money, IsAutoReset BIT, PRIMARY KEY(CustID,SportType,Bettype))
	DECLARE @SportBettype TABLE (ProductID INT, sporttype INT, bettype INT, WinLimit BIT)
	DECLARE @currency INT
	
	SELECT @currency = currency FROM CheckCustDB.dbo.custinfo WITH(NOLOCK)
	WHERE custid = @srecommend
	
	INSERT INTO @SportBettype (productID,sporttype,bettype,WinLimit)
	SELECT productID,sporttype,bettype, CASE WHEN SettingType = 12 THEN 0 ELSE 1 END
	FROM CheckCustDB.dbo.ProductSettingDetail ps WITH(NOLOCK) 
	WHERE SettingType in (6,12)
		AND ps.SettingStatus = 0
		AND sporttype = CASE WHEN @sporttype = 0 THEN sporttype ELSE @sporttype END
		AND sporttype NOT IN (245)
		
	INSERT INTO #SuperWinLossLimit (custid, sporttype, bettype, MaxWinLimit, MaxLossLimit, IsAutoReset)
	SELECT custid, cs.sporttype, cs.bettype, ISNULL(MaxWinLimit,0), ISNULL(MaxLossLimit,0), ISNULL(IsAutoReset,0)
	FROM CheckCustDB.dbo.CustWinLossLimit_Agent cs WITH (NOLOCK)
		INNER JOIN @SportBettype s ON cs.sporttype = s.sporttype AND cs.bettype =s.bettype
	WHERE custid = @srecommend		
	
	INSERT INTO #MasterWinLossLimit (custid, sporttype, bettype, MaxWinLimit, MaxLossLimit, IsAutoReset)
	SELECT cs.custid, cs.sporttype, cs.bettype, ISNULL(MaxWinLimit,0), ISNULL(MaxLossLimit,0), ISNULL(IsAutoReset,0)
	FROM CheckCustDB.dbo.CustWinLossLimit_Agent cs WITH (NOLOCK)
		INNER JOIN CheckCustDB.dbo.custinfo ci WITH(NOLOCK) ON ci.custid = cs.custid
		INNER JOIN @SportBettype s ON cs.sporttype = s.sporttype AND cs.bettype =s.bettype
	WHERE ci.srecommend = @srecommend
		AND roleid = 3
		AND enabled = 1
	
	INSERT INTO #AgentWinLossLimit (custid, mrecommend, sporttype, bettype, MaxWinLimit, MaxLossLimit, IsAutoReset)
	SELECT cs.custid, mrecommend, cs.sporttype, cs.bettype, ISNULL(MaxWinLimit,0), ISNULL(MaxLossLimit,0), ISNULL(IsAutoReset,0)
	FROM CheckCustDB.dbo.CustWinLossLimit_Agent cs WITH (NOLOCK)
		INNER JOIN CheckCustDB.dbo.custinfo ci WITH(NOLOCK) ON ci.custid = cs.custid
		INNER JOIN @SportBettype s ON cs.sporttype = s.sporttype AND cs.bettype =s.bettype
	WHERE ci.srecommend = @srecommend
		AND roleid = 2
		AND enabled = 1
		
	INSERT INTO #MemberWinLossLimit (custid, mrecommend, recommend, sporttype, bettype, MaxWinLimit, MaxLossLimit, IsAutoReset)
	SELECT cs.custid, mrecommend, recommend, cs.sporttype, cs.bettype, ISNULL(MaxWinLimit,0), ISNULL(MaxLossLimit,0), ISNULL(IsAutoReset,0)
	FROM CheckCustDB.dbo.CustWinLossLimit_Member cs WITH (NOLOCK)
		INNER JOIN CheckCustDB.dbo.custinfo ci WITH(NOLOCK) ON ci.custid = cs.custid
		INNER JOIN @SportBettype s ON cs.sporttype = s.sporttype AND cs.bettype =s.bettype
	WHERE ci.srecommend = @srecommend
		AND roleid = 1	
		AND enabled = 1
		
	--missing settings
	IF @ruleid IN (0,501)
	BEGIN
		INSERT INTO CheckWinLossLimitResult_Credit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
		SELECT 501, s.sporttype, s.bettype, t.custid as custidA, 0, 0 , 0
		FROM @SportBettype s
			CROSS JOIN (SELECT @srecommend as custid) t
		WHERE NOT EXISTS (SELECT 1 FROM #SuperWinLossLimit cs 
						WHERE t.custid = cs.custid
							AND cs.sporttype = s.sporttype
							AND cs.bettype = s.bettype
						)
		
		INSERT INTO CheckWinLossLimitResult_Credit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
		SELECT 501, s.sporttype, s.bettype, ci.custid as custidA, 0, 0 , 0
		FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)
			CROSS JOIN (SELECT * FROM @SportBettype ) s
		WHERE ci.srecommend = @srecommend
			AND roleid = 3
			AND enabled = 1
			AND NOT EXISTS (SELECT 1 FROM #MasterWinLossLimit cs 
						WHERE ci.custid = cs.custid
							AND cs.sporttype = s.sporttype
							AND cs.bettype = s.bettype
						)
		
		INSERT INTO CheckWinLossLimitResult_Credit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
		SELECT 501, s.sporttype, s.bettype, ci.custid as custidA, 0, 0 , 0
		FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)
			CROSS JOIN (SELECT * FROM @SportBettype ) s
		WHERE ci.srecommend = @srecommend
			AND roleid = 2
			AND enabled = 1
			AND NOT EXISTS (SELECT 1 FROM #AgentWinLossLimit cs 
						WHERE ci.custid = cs.custid
							AND cs.sporttype = s.sporttype
							AND cs.bettype = s.bettype
						)
		
		INSERT INTO CheckWinLossLimitResult_Credit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
		SELECT 501, s.sporttype, s.bettype, ci.custid as custidA, 0, 0 , 0
		FROM CheckCustDB.dbo.custinfo ci WITH(NOLOCK)
			CROSS JOIN (SELECT * FROM @SportBettype ) s
		WHERE ci.srecommend = @srecommend
			AND roleid = 1
			AND enabled = 1
			AND NOT EXISTS (SELECT 1 FROM #MemberWinLossLimit cs 
						WHERE ci.custid = cs.custid
							AND cs.sporttype = s.sporttype
							AND cs.bettype = s.bettype
						)
	END
	
	--Super's Maximum Win < Master's Maximum Win		
	IF @ruleid IN (0,502)
	BEGIN
		INSERT INTO CheckWinLossLimitResult_Credit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
		SELECT 502, scs.sporttype, scs.bettype, scs.custid as custidA, mcs.custid as custidB, scs.MaxWinLimit , mcs.MaxWinLimit
		FROM #SuperWinLossLimit scs
			INNER JOIN #MasterWinLossLimit mcs ON scs.sporttype = mcs.sporttype AND scs.bettype = mcs.bettype
			INNER JOIN @SportBettype s ON scs.sporttype = s.sporttype AND scs.bettype = s.bettype AND s.Winlimit = 1
		WHERE scs.MaxWinLimit > 0 
			AND (mcs.MaxWinLimit = 0 OR mcs.MaxWinLimit > scs.MaxWinLimit)
	END
	
	--Master's Maximum Win < Agent's Maximum Win		
	IF @ruleid IN (0,503)
	BEGIN
		INSERT INTO CheckWinLossLimitResult_Credit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
		SELECT 503, mcs.sporttype, mcs.bettype, mcs.custid as custidA, acs.custid as custidB, mcs.MaxWinLimit , acs.MaxWinLimit
		FROM #MasterWinLossLimit mcs
			INNER JOIN #AgentWinLossLimit acs ON acs.mrecommend = mcs.custid 
												AND acs.sporttype = mcs.sporttype 
												AND acs.bettype = mcs.bettype
			INNER JOIN @SportBettype s ON mcs.sporttype = s.sporttype AND mcs.bettype = s.bettype AND s.Winlimit = 1									
		WHERE mcs.MaxWinLimit > 0 
			AND (acs.MaxWinLimit = 0 OR acs.MaxWinLimit > mcs.MaxWinLimit)
	END
	
	--Agent's Maximum Win < Member's Maximum Win		
	IF @ruleid IN (0,504)
	BEGIN
		INSERT INTO CheckWinLossLimitResult_Credit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
		SELECT 504, acs.sporttype, acs.bettype, acs.custid as custidA, cs.custid as custidB, acs.MaxWinLimit , cs.MaxWinLimit
		FROM #AgentWinLossLimit acs
			INNER JOIN #MemberWinLossLimit acs ON cs.recommend = acs.custid 
												AND cs.sporttype = acs.sporttype 
												AND cs.bettype = acs.bettype
			INNER JOIN @SportBettype s ON mcs.sporttype = s.sporttype AND mcs.bettype = s.bettype AND s.Winlimit = 1																		
		WHERE acs.MaxWinLimit > 0 
			AND (cs.MaxWinLimit = 0 OR cs.MaxWinLimit > acs.MaxWinLimit)
	END
	
	--Maximum Loss < MinLossLimit of LossLimit_GlobalSetting		
	IF @ruleid IN (0,505)
	BEGIN		
		INSERT INTO CheckWinLossLimitResult_Credit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
		SELECT 505, scs.sporttype, scs.bettype, scs.custid as custidA, 0 custidB, scs.MaxLossLimit , g.MinLossLimit
		FROM #SuperWinLossLimit scs			
			INNER JOIN CheckCustDB.dbo.LossLimit_GlobalSetting g WITH(NOLOCK) ON s.productID = g.productID AND g.currency = @currency
		WHERE scs.MaxLossLimit < g.MinLossLimit
		
		INSERT INTO CheckWinLossLimitResult_Credit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
		SELECT 505, cs.sporttype, cs.bettype, cs.custid as custidA, 0 custidB, cs.MaxLossLimit , g.MinLossLimit
		FROM #MasterWinLossLimit cs			
			INNER JOIN CheckCustDB.dbo.LossLimit_GlobalSetting g WITH(NOLOCK) ON s.productID = g.productID AND g.currency = @currency
		WHERE cs.MaxLossLimit < g.MinLossLimit
		
		INSERT INTO CheckWinLossLimitResult_Credit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
		SELECT 505, cs.sporttype, cs.bettype, cs.custid as custidA, 0 custidB, cs.MaxLossLimit , g.MinLossLimit
		FROM #AgentWinLossLimit cs			
			INNER JOIN CheckCustDB.dbo.LossLimit_GlobalSetting g WITH(NOLOCK) ON s.productID = g.productID AND g.currency = @currency
		WHERE cs.MaxLossLimit < g.MinLossLimit
		
		INSERT INTO CheckWinLossLimitResult_Credit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
		SELECT 505, cs.sporttype, cs.bettype, cs.custid as custidA, 0 custidB, cs.MaxLossLimit , g.MinLossLimit
		FROM #MemberWinLossLimit cs			
			INNER JOIN CheckCustDB.dbo.LossLimit_GlobalSetting g WITH(NOLOCK) ON s.productID = g.productID AND g.currency = @currency
		WHERE cs.MaxLossLimit < g.MinLossLimit
	END

	--Super's Maximum Loss < Master's Maximum Loss		
	IF @ruleid IN (0,506)
	BEGIN
		INSERT INTO CheckWinLossLimitResult_Credit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
		SELECT 506, scs.sporttype, scs.bettype, scs.custid as custidA, mcs.custid as custidB, scs.MaxWinLimit , mcs.MaxWinLimit
		FROM #SuperWinLossLimit scs
			INNER JOIN #MasterWinLossLimit mcs ON scs.sporttype = mcs.sporttype AND scs.bettype = mcs.bettype			
		WHERE  scs.MaxLossLimit > 0 
			AND (mcs.MaxLossLimit = 0 OR mcs.MaxLossLimit > scs.MaxLossLimit)
	END
	
	--Master's Maximum Loss < Agent's Maximum Loss
	IF @ruleid IN (0,507)
	BEGIN
		INSERT INTO CheckWinLossLimitResult_Credit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
		SELECT 507, mcs.sporttype, mcs.bettype, mcs.custid as custidA, acs.custid as custidB, mcs.MaxWinLimit , acs.MaxWinLimit
		FROM #MasterWinLossLimit mcs
			INNER JOIN #AgentWinLossLimit acs ON acs.mrecommend = mcs.custid 
												AND acs.sporttype = mcs.sporttype 
												AND acs.bettype = mcs.bettype			
		WHERE mcs.MaxLossLimit > 0
			AND (acs.MaxLossLimit = 0 OR acs.MaxLossLimit > mcs.MaxLossLimit)
	END
	
	-- 	Agent's Maximum Loss < Member's Maximum Loss
	IF @ruleid IN (0,508)
	BEGIN
		INSERT INTO CheckWinLossLimitResult_Credit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
		SELECT 508, acs.sporttype, acs.bettype, acs.custid as custidA, cs.custid as custidB, acs.MaxWinLimit , cs.MaxWinLimit
		FROM #AgentWinLossLimit acs
			INNER JOIN #MemberWinLossLimit cs ON cs.recommend = acs.custid 
												AND cs.sporttype = acs.sporttype 
												AND cs.bettype = acs.bettype			
		WHERE  acs.MaxLossLimit > 0
			AND (cs.MaxLossLimit = 0 OR cs.MaxLossLimit > acs.MaxLossLimit)
	END
	
	--Upline's IsAutoReset = 0 => Downlines's IsAutoReset = 1		
	IF @ruleid IN (0,509)
	BEGIN
		INSERT INTO CheckWinLossLimitResult_Credit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
		SELECT 509, scs.sporttype, scs.bettype, scs.custid as custidA, mcs.custid as custidB, scs.IsAutoReset , mcs.IsAutoReset
		FROM #SuperWinLossLimit scs
			INNER JOIN #MasterWinLossLimit mcs ON scs.sporttype = mcs.sporttype AND scs.bettype = mcs.bettype			
		WHERE  scs.IsAutoReset = 0 AND mcs.IsAutoReset = 1
		
		INSERT INTO CheckWinLossLimitResult_Credit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
		SELECT 509, mcs.sporttype, mcs.bettype, mcs.custid as custidA, acs.custid as custidB, mcs.IsAutoReset , acs.IsAutoReset
		FROM #MasterWinLossLimit mcs
			INNER JOIN #AgentWinLossLimit acs ON acs.sporttype = mcs.sporttype AND acs.bettype = mcs.bettype			
		WHERE  mcs.IsAutoReset = 0 AND acs.IsAutoReset = 1
		
		INSERT INTO CheckWinLossLimitResult_Credit(RuleID,SportType,bettype,CustIDA,CustIDB,ValueA,ValueB) 
		SELECT 509, acs.sporttype, acs.bettype, acs.custid as custidA, cs.custid as custidB, acs.IsAutoReset , cs.IsAutoReset
		FROM #AgentWinLossLimit acs
			INNER JOIN #MemberWinLossLimit cs ON acs.sporttype = cs.sporttype AND acs.bettype = cs.bettype			
		WHERE  acs.IsAutoReset = 0 AND cs.IsAutoReset = 1
	END
END
GO


	