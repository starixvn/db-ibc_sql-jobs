/*<info serverAlias="DBTP-bodb02" executers="bodbadminNet,bodbDownlineNet,bodbExtAccNet" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[Task_DetectBet_CustMaxBetSettingSel] 
		@CustList	VARCHAR(MAX) = '',
		@ErMsg		NVARCHAR(MAX)='' OUTPUT
AS
/*
	Created: 20220523@Tacy
	Task : Get current bet limit setting
	DB: DBTP/bodb02
	Original:

	Revisions:
		- 20220523@Tacy: Initial SP [RedmineID: #170739]

	Param's Explanation:
	• @CustList:
		<root>
			<r custid= ''1400001'' SportType=''248'' BetType=''4186'' transid=''12345678'' transdate="2022-03-10 04:10:10.000"/>
			<r custid=''23700002'' SportType=''176'' BetType=''8202'' transid=''13524659'' transdate="2022-03-10 04:10:10.000"/>
		</root>
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @xml				XML = NULL
		,	@TableBetSetting	VARCHAR(50)
		,	@SQL				NVARCHAR(MAX)

/*	DECLARE @CustList VARCHAR(MAX),@ErMsg nvarchar(max)
	SET @CustList = '<root><r custid="64074994" BetType="3704" SportType="170" transid="519399694" transdate="2022-05-23T00:00:00"/><r custid="52289958" BetType="2401" SportType="211" transid="519399693" transdate="2022-05-18T02:02:41.370"/><r custid="52289958" BetType="2401" SportType="211" transid="519399429" transdate="2022-05-18T02:01:28.820"/><r custid="52289958" BetType="2401" SportType="211" transid="519399157" transdate="2022-05-18T02:00:21.133"/><r custid="52289958" BetType="2401" SportType="211" transid="519398896" transdate="2022-05-18T01:59:11.523"/><r custid="23639495" BetType="3409" SportType="233" transid="519398746" transdate="2022-05-18T01:58:29.023"/><r custid="23639495" BetType="3409" SportType="233" transid="519398562" transdate="2022-05-18T01:57:39.960"/><r custid="52289958" BetType="2401" SportType="211" transid="519398272" transdate="2022-05-18T01:56:27.210"/><r custid="52289958" BetType="2401" SportType="211" transid="519398075" transdate="2022-05-18T01:55:28.507"/><r custid="52289958" BetType="2401" SportType="211" transid="519397805" transdate="2022-05-18T01:54:11.507"/></root>'
	*/
	CREATE TABLE #tmpCustList (
			custid		INT
		,	SportType	SMALLINT
		,	BetType		INT
		,	transid		BIGINT
		,	transdate	DATETIME
		,	isLicensee	BIT
		,	PRIMARY KEY CLUSTERED (transid)
	)

	CREATE TABLE #tmpCustListSel (
			custid			INT
		,	transid			BIGINT
		,	SportType		SMALLINT
		,	BetType			INT
		,	TableBetSetting VARCHAR(50)
		,	MaxBet			MONEY
		,	MaxPerMatch		MONEY
		,	StakeLevelList	VARCHAR(200)
		,	isLicensee		BIT
		,	isChangedSMA	BIT
		,	UpdateTime_SMA	DATETIME
		,	isChangedGlobal BIT
		,	StakeLevelID_Changed INT
		,	MaxStake_Changed MONEY
		,	UpdateTime_Global DATETIME
		,	transdate	DATETIME
		,	PRIMARY KEY CLUSTERED (transid)
	)

	CREATE TABLE #returnTable (
			custid			INT
		,	transid			BIGINT
		,	SportType		SMALLINT
		,	BetType			INT
		,	MaxBet			MONEY
		,	MaxPerMatch		MONEY
		,	StakeLevelList	VARCHAR(200)
		,	PRIMARY KEY CLUSTERED (transid)
	)
	
	--Check if XML is null or empty
	IF @CustList IS NULL OR @CustList=''
	BEGIN
		SET @ErMsg='Customer list is invalid.'
		RETURN
	END
	SET @xml = CONVERT(XML, @CustList)

	--Parse XML	
	DECLARE @iDoc INT

	EXEC sp_xml_preparedocument @iDoc OUTPUT
		, @xml

	INSERT INTO #tmpCustList(custid, SportType, BetType, transid, transdate)
	SELECT custid, SportType, BetType, transid, transdate
	FROM OPENXML(@iDoc, '/root/r', 1) 
	WITH (
			custid		INT
		,	SportType	SMALLINT
		,	BetType		INT
		,	transid		BIGINT
		,	transdate	DATETIME
		) t
		
	EXEC sp_xml_removedocument @iDoc

	--Update isLicensee
	UPDATE #tmpCustList
	SET isLicensee = CASE WHEN dep.custid IS NULL THEN 0 ELSE 1 END
	FROM #tmpCustList tc
		INNER JOIN DBCust.CustDB.dbo.CustInfo ci WITH (NOLOCK) ON ci.custid=tc.custid
		 LEFT JOIN DBCust.CustDB.dbo.Dep_CustSuper dep WITH (NOLOCK) ON dep.custid=ci.srecommend


	--Get: SportTypeBetSetting, BetTypeBetSetting, TableBetSetting
	INSERT INTO #tmpCustListSel (custid, transid, SportType, BetType, TableBetSetting, isLicensee, transdate)
	SELECT DISTINCT 
		  cl.custid
		, cl.transid
		, ref.SportTypeRefBetSetting	AS SportType
		, ref.BetTypeRefBetSetting		AS BetType
		, ref.TableBetSetting
		, cl.isLicensee
		, cl.transdate
	FROM #tmpCustList cl
		LEFT JOIN dbtxn.bodb02.dbo.Sport_Bettype_Reference_Setting ref WITH (NOLOCK)
			ON	ref.Sporttype	= cl.sporttype 
			AND ref.Bettype		= cl.bettype
			AND ref.isLicensee	= cl.isLicensee
		
	--Update: isChangedSMA
	UPDATE cls
	SET cls.isChangedSMA = CASE WHEN (cls.isLicensee=0 AND ch.custid IS NOT NULL)
									OR 
									 (cls.isLicensee=1 AND dch.custid IS NOT NULL) THEN 1 ELSE 0 END
		
		, cls.MaxBet= CASE WHEN (cls.isLicensee=0 AND ch.custid IS NOT NULL) THEN ch.OldMaxBet
						   WHEN (cls.isLicensee=1 AND dch.custid IS NOT NULL) THEN dch.OldMaxBet END
		
		, cls.MaxPerMatch= CASE WHEN (cls.isLicensee=0 AND ch.custid IS NOT NULL) THEN ch.OldMaxPerMatch
								WHEN (cls.isLicensee=1 AND dch.custid IS NOT NULL) THEN dch.OldMaxPerMatch END

		, cls.StakeLevelList= CASE WHEN (cls.isLicensee=0 AND ch.custid IS NOT NULL) THEN ch.OldStakeLevelList
								WHEN (cls.isLicensee=1 AND dch.custid IS NOT NULL) THEN dch.OldStakeLevelList END

		, cls.UpdateTime_SMA= CASE WHEN (cls.isLicensee=0 AND ch.custid IS NOT NULL) THEN ch.UpdateTime
							   WHEN (cls.isLicensee=1 AND dch.custid IS NOT NULL) THEN dch.UpdateTime END
	FROM #tmpCustListSel cls
		OUTER APPLY (SELECT TOP (1) ch. custid, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime 
					 FROM CustMaxBetSetting_History ch 
					 WHERE  ch.custid=cls.custid AND ch.SportType=cls.SportType
						AND ch.BetType=cls.BetType AND ch.UpdateTime>cls.transdate 
				--	 ORDER BY UpdateTime
					 ) ch
		OUTER APPLY (SELECT TOP (1) dch.custid, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime 
					 FROM Dep_CustMaxBetSetting_History dch 
					 WHERE dch.custid=cls.custid AND dch.SportType=cls.SportType
						AND dch.BetType=cls.BetType AND dch.UpdateTime>cls.transdate  
				--	 ORDER BY UpdateTime
					 ) dch
	
--	select * from #tmpCustListSel

	--Update: StakeLevelList current
	IF EXISTS (SELECT 1 FROM #tmpCustListSel WHERE TableBetSetting='CustStakeLevel_Member')
	BEGIN
		UPDATE cls
		SET cls.StakeLevelList=cslm.StakeLevelList
		FROM #tmpCustListSel cls
			INNER JOIN DBCust.CustDB.dbo.CustStakeLevel_Member cslm WITH (NOLOCK)
					ON cslm.custid=cls.custid
					AND cslm.SportType=cls.SportType
					AND cslm.BetType=cls.BetType
		WHERE cls.StakeLevelList IS NULL AND cls.isChangedSMA=0
	END

	IF EXISTS (SELECT 1 FROM #tmpCustListSel WHERE TableBetSetting='Dep_CustStakeLevel_Member')
	BEGIN
		UPDATE cls
		SET cls.StakeLevelList=cslm.StakeLevelList
		FROM #tmpCustListSel cls
			INNER JOIN DBCust.CustDB.dbo.Dep_CustStakeLevel_Member cslm WITH (NOLOCK)
					ON cslm.custid=cls.custid
					AND cslm.SportType=cls.SportType
					AND cslm.BetType=cls.BetType
		WHERE cls.StakeLevelList IS NULL AND cls.isChangedSMA=0
	END
--	select * from #tmpCustListSel

	--Update: isChangedGlobal
	;WITH changedGlobal AS (
		SELECT cls.custid, cls.transid
			, CASE WHEN st.StakeLevelID IS NOT NULL THEN st.UpdateTime
				WHEN dst.StakeLevelID IS NOT NULL THEN dst.UpdateTime
				WHEN stg.StakeLevelID IS NOT NULL THEN st.UpdateTime
				WHEN dstg.StakeLevelID IS NOT NULL THEN dst.UpdateTime
			END UpdateTime
			, MAX(CASE WHEN st.StakeLevelID IS NOT NULL OR stg.StakeLevelID IS NOT NULL 
						OR dst.StakeLevelID IS NOT NULL OR dstg.StakeLevelID IS NOT NULL THEN 1 ELSE 0 END) AS isChangedGlobal
			, MAX(CASE WHEN st.StakeLevelID IS NOT NULL THEN st.StakeLevelID
					WHEN dst.StakeLevelID IS NOT NULL THEN dst.StakeLevelID
					WHEN stg.StakeLevelID IS NOT NULL THEN st.StakeLevelID
					WHEN dstg.StakeLevelID IS NOT NULL THEN dst.StakeLevelID
				  END) AS StakeLevelID_Changed 
			, MAX(CASE WHEN st.StakeLevelID IS NOT NULL THEN st.StakeLevelID
					WHEN dst.StakeLevelID IS NOT NULL THEN dst.StakeLevelID
					WHEN stg.StakeLevelID IS NOT NULL THEN st.StakeLevelID
					WHEN dstg.StakeLevelID IS NOT NULL THEN dst.StakeLevelID
				  END) AS MaxStake_Changed 
		FROM #tmpCustListSel cls
		OUTER APPLY (SELECT value AS val FROM STRING_SPLIT(cls.StakeLevelList,',')) ss
		OUTER APPLY (SELECT TOP (1) StakeLevelID, MaxLabel, UpdateTime FROM StakeLevel_History st WITH (NOLOCK) 
					 WHERE st.StakeLevelID = CAST(ss.val AS INT)
						AND st.UpdateTime>cls.transdate
				--	 ORDER BY UpdateTime
					 ) st
		OUTER APPLY (SELECT TOP (1) StakeLevelID, MaxLabel, UpdateTime FROM Dep_StakeLevel_History dst WITH (NOLOCK) 
					 WHERE dst.StakeLevelID = CAST(ss.val AS INT)
						AND dst.UpdateTime>cls.transdate
				--	 ORDER BY UpdateTime
					) dst
		OUTER APPLY (SELECT TOP (1) StakeLevelID, MaxLabel, UpdateTime FROM StakeLevelGroupDetail_History stg WITH (NOLOCK) 
					 WHERE stg.StakeLevelID = CAST(ss.val AS INT)
						AND stg.UpdateTime>cls.transdate
				--	 ORDER BY UpdateTime
					 ) stg
		OUTER APPLY (SELECT TOP (1) StakeLevelID, MaxLabel, UpdateTime FROM Dep_StakeLevelGroupDetail_History dstg WITH (NOLOCK) 
					 WHERE dstg.StakeLevelID = CAST(ss.val AS INT)
						AND dstg.UpdateTime>cls.transdate
				--	 ORDER BY UpdateTime
					 ) dstg
		WHERE cls.StakeLevelList IS NOT NULL
		GROUP BY cls.custid, cls.transid
			, CASE WHEN st.StakeLevelID IS NOT NULL THEN st.UpdateTime
				WHEN dst.StakeLevelID IS NOT NULL THEN dst.UpdateTime
				WHEN stg.StakeLevelID IS NOT NULL THEN st.UpdateTime
				WHEN dstg.StakeLevelID IS NOT NULL THEN dst.UpdateTime
			END
	)
	UPDATE cls
	SET cls.isChangedGlobal=cg.isChangedGlobal
		, cls.StakeLevelID_Changed=cg.StakeLevelID_Changed
		, cls.MaxStake_Changed=cg.MaxStake_Changed
		, cls.UpdateTime_Global=cg.UpdateTime
	FROM #tmpCustListSel cls
		LEFT JOIN changedGlobal cg ON cg.transid=cls.transid
	
--	select * from #tmpCustListSel

	--update Global only
	IF EXISTS (SELECT 1 FROM #tmpCustListSel WHERE isChangedGlobal=1)
	BEGIN
		;WITH tmp1 AS (
			SELECT cls.transid
				, MAX(CASE WHEN st.GameGroupID=0 THEN CAST(st.MaxLabel AS MONEY) ELSE stg.MaxStake END) MaxStake
			FROM #tmpCustListSel cls
			OUTER APPLY (SELECT TRIM(value) AS val FROM STRING_SPLIT(cls.StakeLevelList,',')) ss
			LEFT JOIN StakeLevel st ON st.StakeLevelID=CAST(ss.val AS INT)
									AND st.StakeLevelID<>cls.StakeLevelID_Changed
			OUTER APPLY (SELECT TOP 1 stg.StakeLevelID, CAST(stg.MaxLabel AS MONEY) AS MaxStake
						 FROM StakeLevelGroupDetail stg WITH (NOLOCK)
						 WHERE stg.StakeLevelID = st.StakeLevelID
						 ORDER BY CAST(stg.MaxLabel AS MONEY) DESC
						) stg
			WHERE isChangedGlobal=1
			GROUP BY cls.transid
		),
		tmp2 AS (
			SELECT cls.transid
				, CASE WHEN cls.MaxStake_Changed>t.MaxStake THEN cls.MaxStake_Changed ELSE t.MaxStake END tmp_MaxBet
			FROM #tmpCustListSel cls
				LEFT JOIN tmp1 t ON t.transid=cls.transid
			WHERE isChangedGlobal=1
		)
		UPDATE cls
		SET	cls.MaxBet=CASE WHEN cls.MaxBet>t.tmp_MaxBet THEN cls.MaxBet ELSE t.tmp_MaxBet END
		FROM #tmpCustListSel cls
			LEFT JOIN tmp2 t ON t.transid=cls.transid

	END
--	select * from #tmpCustListSel

	-- Insert result data
	INSERT INTO #returnTable (custid, transid, SportType, BetType, MaxBet, MaxPerMatch, StakeLevelList)
	SELECT custid, transid, SportType, BetType, MaxBet, MaxPerMatch, StakeLevelList
	FROM #tmpCustListSel
	WHERE isChangedSMA=1 OR isChangedGlobal=1

	select @@ROWCOUNT

	--Get Current MaxBet
	IF EXISTS (SELECT 1 FROM #tmpCustListSel WHERE isChangedSMA=0 AND isChangedGlobal=0)
	BEGIN
		WHILE 1=1
		BEGIN 
			SELECT TOP 1 @TableBetSetting=TableBetSetting
			FROM #tmpCustListSel
			WHERE TableBetSetting NOT IN ('CustStakeLevel_Member','Dep_CustStakeLevel_Member')
				AND isChangedSMA=0 AND isChangedGlobal=0

		--	select @TableBetSetting

			IF @@ROWCOUNT = 0	
				BREAK;
			
			SET @SQL = 'SELECT bs.custid, cls.transid, bs.SportType
							, bs.BetType, bs.MaxBet
							, bs.MaxPerMatch
						FROM DBCust.CustDB.dbo.[' + @TableBetSetting + '] bs WITH (NOLOCK)
						WHERE EXISTS (	SELECT 1 
										FROM #tmpCustListSel cls 
										WHERE	cls.custid		= bs.custid
											AND cls.SportType	= bs.SportType
											AND cls.BetType		= bs.BetType
											AND cls.TableBetSetting	= @TableBetSetting
											AND isChangedSMA=0 AND isChangedGlobal=0)'
			
	--		INSERT INTO #returnTable (custid, transid, SportType, BetType, MaxBet, MaxPerMatch)
			EXECUTE sys.sp_executesql @SQL, N'@TableBetSetting	VARCHAR(50)', @TableBetSetting

		/*	ELSE
			BEGIN
				SET @SQL = 'SELECT bs.custid, cls.transid, bs.SportType
								, bs.BetType, bs.StakeLevelList
							FROM [' + @TableBetSetting + '] bs WITH (NOLOCK)
							WHERE EXISTS (	SELECT 1 
											FROM #tmpCustListSel cls
											WHERE	cls.custid		= bs.custid
												AND cls.SportType	= bs.SportType
												AND cls.BetType		= bs.BetType
												AND cls.TableBetSetting	= @TableBetSetting)'

				INSERT INTO #returnTable (custid, transid, SportType, BetType, StakeLevelList)
				EXECUTE sys.sp_executesql @SQL, N'@TableBetSetting VARCHAR(500)', @TableBetSetting;
			END*/
		
			DELETE FROM #tmpCustListSel
			WHERE TableBetSetting=@TableBetSetting
		END
		
		IF @@ERROR<>0
			RETURN
		TRUNCATE TABLE #tmpCustListSel

		select * from #returnTable
	
		--UPDATE MAXBET : Credit
		IF EXISTS (SELECT 1 
					FROM #returnTable r
						INNER JOIN #tmpCustList cl ON cl.custid=r.custid
					WHERE r.StakeLevelList IS NOT NULL AND r.MaxBet IS NULL
						AND cl.isLicensee=0)
		BEGIN
			WITH csll AS (
				SELECT r.custid, r.SportType, r.BetType, r.StakeLevelList
					, MAX(CASE WHEN st.GameGroupID=0 THEN st.MaxStake ELSE stgd.MaxStake END) AS MaxStake
				FROM #returnTable r WITH (ROWLOCK, UPDLOCK)
					INNER JOIN #tmpCustList cl ON cl.custid=r.custid
					CROSS APPLY (SELECT CAST(value AS INT) AS StakeLevelList_Value FROM STRING_SPLIT(r.StakeLevelList,',')) ss
					INNER JOIN DBCust.CustDB.dbo.StakeLevel st WITH (NOLOCK) ON st.StakeLevelID = ss.StakeLevelList_Value
					CROSS APPLY (SELECT TOP 1 stg.StakeLevelID, CAST(stg.MaxLabel AS MONEY) AS MaxStake
								 FROM DBCust.CustDB.dbo.StakeLevelGroupDetail stg WITH (NOLOCK)
								 WHERE stg.StakeLevelID = st.StakeLevelID
								 ORDER BY CAST(stg.MaxLabel AS MONEY) DESC
								 ) stgd

				WHERE r.StakeLevelList IS NOT NULL
					AND cl.isLicensee=0 AND r.MaxBet IS NULL
				GROUP BY r.custid, r.SportType, r.BetType, r.StakeLevelList
			)
			UPDATE r
			SET r.MaxBet = t1.MaxStake
			FROM #returnTable r WITH (ROWLOCK, UPDLOCK)
				INNER JOIN csll t1 ON t1.custid	= r.custid
								AND t1.BetType	= r.BetType
								AND t1.SportType= R.SportType
		END

		--UPDATE MAXBET : Deposit
		IF EXISTS (SELECT 1 
				FROM #returnTable r
					INNER JOIN #tmpCustList cls ON cls.custid=r.custid
				WHERE r.StakeLevelList IS NOT NULL AND r.MaxBet IS NULL
					AND cls.isLicensee=1)
		BEGIN
			WITH csll AS (
				SELECT r.custid, r.SportType, r.BetType, r.StakeLevelList
					, MAX(CASE WHEN st.GameGroupID=0 THEN st.MaxStake ELSE stgd.MaxStake END) AS MaxStake
				FROM #returnTable r WITH (ROWLOCK, UPDLOCK)
					INNER JOIN #tmpCustList cl ON cl.custid=r.custid
					CROSS APPLY (SELECT CAST(value AS INT) AS StakeLevelList_Value FROM STRING_SPLIT(r.StakeLevelList,',')) ss
					INNER JOIN DBCust.CustDB.dbo.Dep_StakeLevel st WITH (NOLOCK) ON st.StakeLevelID = ss.StakeLevelList_Value
					CROSS APPLY (SELECT TOP 1 stg.StakeLevelID, CAST(stg.MaxLabel AS MONEY) AS MaxStake
								 FROM DBCust.CustDB.dbo.Dep_StakeLevelGroupDetail stg WITH (NOLOCK)
								 WHERE stg.StakeLevelID = st.StakeLevelID
								 ORDER BY CAST(stg.MaxLabel AS MONEY) DESC
								 ) stgd
				WHERE r.StakeLevelList IS NOT NULL
					AND cl.isLicensee=1 AND r.MaxBet IS NULL
				GROUP BY r.custid, r.SportType, r.BetType, r.StakeLevelList
			)
			UPDATE r
			SET r.MaxBet = t1.MaxStake
			FROM #returnTable r WITH (ROWLOCK, UPDLOCK)
				INNER JOIN csll t1 ON t1.custid	= r.custid
								AND t1.BetType	= r.BetType
								AND t1.SportType= R.SportType
		END
	END

	SELECT *
	FROM #returnTable 
	
	DROP TABLE #tmpCustList
	DROP TABLE #tmpCustListSel
	DROP TABLE #returnTable
END
GO