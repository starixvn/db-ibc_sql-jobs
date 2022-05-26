/*<info serverAlias="DBTP-bodb02" executers="bodbadminNet,bodbDownlineNet,bodbExtAccNet" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[Task_DetectBet_CustMaxBetSettingSel] 
		@CustList	VARCHAR(MAX) = '',
		@ErrCode	INT=0			 OUTPUT,
		@ErrMsg		NVARCHAR(MAX)='' OUTPUT
AS
/*
	Created: 20220523@Tacy
	Task : Get MaxBet at the time of place bet
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

/*	DECLARE @CustList VARCHAR(MAX)
	SET @CustList = '<root><r custid="16196129" BetType="2179" SportType="208" transid="100865730795" transdate="2018-12-23T23:54:55.480"/><r custid="16196129" BetType="2178" SportType="208" transid="100865730780" transdate="2018-12-23T23:54:55.480"/><r custid="14242644" BetType="2161" SportType="208" transid="100865638950" transdate="2018-12-23T22:34:14.430"/><r custid="14242644" BetType="2105" SportType="208" transid="100864516067" transdate="2018-12-23T08:26:50.243"/><r custid="14242644" BetType="2104" SportType="208" transid="100864510971" transdate="2018-12-23T08:23:00.060"/><r custid="14242644" BetType="2203" SportType="209" transid="100862352395" transdate="2018-12-22T05:02:31.390"/><r custid="14242644" BetType="2103" SportType="208" transid="100862283045" transdate="2018-12-22T04:06:53.563"/><r custid="1382337" BetType="2121" SportType="208" transid="100829926805" transdate="2018-12-05T06:22:44.110"/><r custid="1425064" BetType="2121" SportType="208" transid="100829528036" transdate="2018-12-05T01:46:05.127"/><r custid="1425064" BetType="2121" SportType="208" transid="100829528031" transdate="2018-12-05T01:46:05.123"/></root>'
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

	CREATE TABLE #RefBetSettingTbl (
			custid					INT
		,	SportType				SMALLINT
		,	BetType					INT
		,	TableBetSetting			VARCHAR(50)
		,	PRIMARY KEY CLUSTERED (custid, SportType, BetType)
	)

	CREATE TABLE #CustList_ChangedSMA (
			custid					INT
		,	transid					BIGINT
		,	SportType				SMALLINT
		,	BetType					INT
		,	MaxBet					MONEY
		,	MaxPerMatch				MONEY
		,	StakeLevelList			VARCHAR(200)
		,	PRIMARY KEY CLUSTERED (transid)
	)

	CREATE TABLE #CustList_ChangedGlobal (
			custid					INT
		,	transid					BIGINT
		,	SportType				SMALLINT
		,	BetType					INT
		,	MaxBet					MONEY
		,	StakeLevelList			VARCHAR(200)
		,	StakeLevelID_Changed	INT
		,	MaxStake_Changed		MONEY
		,	IsChangedGlobal			BIT
		,	PRIMARY KEY CLUSTERED (transid)
	)

	CREATE TABLE #returnTbl (
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
		RETURN
	
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
	INSERT INTO #RefBetSettingTbl (custid, SportType, BetType, TableBetSetting)
	SELECT DISTINCT 
		  cl.custid
		, ref.SportTypeRefBetSetting	AS SportType
		, ref.BetTypeRefBetSetting		AS BetType
		, ref.TableBetSetting
	FROM #tmpCustList cl
		LEFT JOIN dbtxn.bodb02.dbo.Sport_Bettype_Reference_Setting ref WITH (NOLOCK)
			ON	ref.Sporttype	= cl.sporttype 
			AND ref.Bettype		= cl.bettype
			AND ref.isLicensee	= cl.isLicensee
	
	--Get List cust: MaxBet is changed by SMA
	INSERT INTO #CustList_ChangedSMA(custid, transid, SportType, BetType, MaxBet, MaxPerMatch, StakeLevelList)
	SELECT cl.custid, cl.transid, cl.SportType, cl.BetType
		, CASE WHEN (cl.isLicensee=0 AND ch.custid IS NOT NULL) THEN ch.OldMaxBet
			   WHEN (cl.isLicensee=1 AND dch.custid IS NOT NULL) THEN dch.OldMaxBet END MaxBet
		
		, CASE WHEN (cl.isLicensee=0 AND ch.custid IS NOT NULL) THEN ch.OldMaxPerMatch
								WHEN (cl.isLicensee=1 AND dch.custid IS NOT NULL) THEN dch.OldMaxPerMatch END MaxPerMatch

		, CASE WHEN (cl.isLicensee=0 AND ch.custid IS NOT NULL) THEN ch.OldStakeLevelList
								WHEN (cl.isLicensee=1 AND dch.custid IS NOT NULL) THEN dch.OldStakeLevelList END StakeLevelList
	FROM #tmpCustList cl
		OUTER APPLY (SELECT TOP (1) ch. custid, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime 
					 FROM CustMaxBetSetting_History ch 
					 WHERE  ch.custid=cl.custid AND ch.SportType=cl.SportType
						AND ch.BetType=cl.BetType AND ch.UpdateTime>cl.transdate 
					 ) ch
		OUTER APPLY (SELECT TOP (1) dch.custid, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime 
					 FROM Dep_CustMaxBetSetting_History dch 
					 WHERE dch.custid=cl.custid AND dch.SportType=cl.SportType
						AND dch.BetType=cl.BetType AND dch.UpdateTime>cl.transdate  
					 ) dch
	WHERE (cl.isLicensee=0 AND ch.custid IS NOT NULL)
		OR 
		  (cl.isLicensee=1 AND dch.custid IS NOT NULL)

	--Get List cust: MaxBet is changed by Global ???
	IF EXISTS (SELECT 1 FROM #RefBetSettingTbl WHERE TableBetSetting IN ('CustStakeLevel_Member','Dep_custStakeLevel_member'))
	BEGIN
		;WITH CustList_Global1 AS (
			SELECT cl.custid, cl.transid, cl.SportType, cl.BetType
				, CASE WHEN cslm.CustID IS NOT NULL  THEN cslm.StakeLevelList
					   WHEN dcslm.CustID IS NOT NULL THEN dcslm.StakeLevelList
					END	AS StakeLevelList
			FROM #tmpCustList cl
				INNER JOIN #RefBetSettingTbl ref 
						ON ref.custid=cl.custid
						AND ref.SportType=cl.SportType
						AND ref.BetType=cl.BetType
				LEFT JOIN DBCust.CustDB.dbo.CustStakeLevel_Member cslm WITH (NOLOCK)
						ON cslm.custid=ref.custid
						AND cslm.SportType=ref.SportType
						AND cslm.BetType=ref.BetType
				LEFT JOIN DBCust.CustDB.dbo.Dep_CustStakeLevel_Member dcslm WITH (NOLOCK)
						ON dcslm.custid=ref.custid
						AND dcslm.SportType=ref.SportType
						AND dcslm.BetType=ref.BetType
			WHERE TableBetSetting IN ('CustStakeLevel_Member','Dep_custStakeLevel_member')
				AND (cslm.CustID IS NOT NULL OR dcslm.CustID IS NOT NULL)
				AND NOT EXISTS (SELECT 1 FROM #CustList_ChangedSMA sma 
								WHERE sma.transid=cl.transid)
		),
		CustList_Global2 AS (
			SELECT clg.custid, clg.transid
				, MAX(CASE WHEN st.StakeLevelID IS NOT NULL OR stg.StakeLevelID IS NOT NULL 
						OR dst.StakeLevelID IS NOT NULL OR dstg.StakeLevelID IS NOT NULL THEN 1 ELSE 0 
					END) AS isChangedGlobal
				, MAX(CASE	WHEN st.StakeLevelID IS NOT NULL	THEN st.StakeLevelID
							WHEN dst.StakeLevelID IS NOT NULL	THEN dst.StakeLevelID
							WHEN stg.StakeLevelID IS NOT NULL	THEN stg.StakeLevelID
							WHEN dstg.StakeLevelID IS NOT NULL	THEN dstg.StakeLevelID
						END) AS StakeLevelID_Changed 
				, MAX(CASE	WHEN st.StakeLevelID IS NOT NULL	THEN st.MaxLabel
							WHEN dst.StakeLevelID IS NOT NULL	THEN dst.MaxLabel
							WHEN stg.StakeLevelID IS NOT NULL	THEN stg.MaxGameStake
							WHEN dstg.StakeLevelID IS NOT NULL	THEN dstg.MaxGameStake
						END) AS MaxStake_Changed 
			FROM #CustList_ChangedGlobal clg
				INNER JOIN #tmpCustList cl ON cl.transid=clg.transid
				OUTER APPLY (SELECT RTRIM(LTRIM(value)) AS val FROM STRING_SPLIT(clg.StakeLevelList,',')) ss
				--Credit
				OUTER APPLY (SELECT TOP (1) StakeLevelID, MaxLabel, UpdateTime FROM StakeLevel_History st WITH (NOLOCK) 
							 WHERE st.StakeLevelID = CAST(ss.val AS INT)
								AND st.UpdateTime>cl.transdate
							 ) st
				OUTER APPLY (SELECT TOP (1) StakeLevelID, MaxGameStake, UpdateTime FROM StakeLevelGroupDetail_History stg WITH (NOLOCK) 
							 WHERE stg.StakeLevelID = CAST(ss.val AS INT)
								AND stg.UpdateTime>cl.transdate
							 ) stg
				--Deposit
				OUTER APPLY (SELECT TOP (1) StakeLevelID, MaxLabel, UpdateTime FROM Dep_StakeLevel_History dst WITH (NOLOCK) 
							 WHERE dst.StakeLevelID = CAST(ss.val AS INT)
								AND dst.UpdateTime>cl.transdate
							) dst
				OUTER APPLY (SELECT TOP (1) StakeLevelID, MaxGameStake, UpdateTime FROM Dep_StakeLevelGroupDetail_History dstg WITH (NOLOCK) 
							 WHERE dstg.StakeLevelID = CAST(ss.val AS INT)
								AND dstg.UpdateTime>cl.transdate
							 ) dstg
			GROUP BY clg.custid, clg.transid
		)
		INSERT INTO #CustList_ChangedGlobal (custid, transid, SportType, BetType, StakeLevelList, StakeLevelID_Changed, MaxStake_Changed, IsChangedGlobal)
		SELECT clg1.custid, clg1.transid, clg1.SportType, clg1.BetType, clg1.StakeLevelList
			, clg2.StakeLevelID_Changed, clg2.MaxStake_Changed, clg2.isChangedGlobal
		FROM CustList_Global1 clg1 
			LEFT JOIN CustList_Global2 clg2 ON clg2.transid=clg1.transid


		--UPDATE: MaxBet [IsChangedGlobal=1]
		;WITH tmp1 AS (--exclude StakeLevelID is changed [stakelevelList]
			SELECT gl.transid
				, MAX(CASE WHEN cl.isLicensee=0	
						THEN (CASE WHEN st.GameGroupID=0 THEN CAST(st.MaxLabel AS MONEY) ELSE stg.MaxStake END)
						ELSE (CASE WHEN dst.GameGroupID=0 THEN CAST(dst.MaxLabel AS MONEY) ELSE dstg.MaxStake END)
					END) AS MaxStake
			FROM #CustList_ChangedGlobal gl
				INNER JOIN #tmpCustList cl ON cl.transid=gl.transid
				CROSS APPLY (SELECT value AS val FROM STRING_SPLIT(gl.StakeLevelList,',')) ss
				--Credit
				LEFT JOIN StakeLevel st ON st.StakeLevelID=CAST(ss.val AS INT)
				OUTER APPLY (SELECT TOP 1 stg.StakeLevelID, CAST(stg.MaxLabel AS MONEY) AS MaxStake
							 FROM StakeLevelGroupDetail stg WITH (NOLOCK)
							 WHERE stg.StakeLevelID = st.StakeLevelID
							 ORDER BY CAST(stg.MaxLabel AS MONEY) DESC
							) stg
				--Deposit
				LEFT JOIN Dep_StakeLevel dst ON dst.StakeLevelID=CAST(ss.val AS INT)
				OUTER APPLY (SELECT TOP 1 stg.StakeLevelID, CAST(dstg.MaxLabel AS MONEY) AS MaxStake
							 FROM Dep_StakeLevelGroupDetail dstg WITH (NOLOCK)
							 WHERE dstg.StakeLevelID = dst.StakeLevelID
							 ORDER BY CAST(dstg.MaxLabel AS MONEY) DESC
							) dstg
			WHERE ((st.StakeLevelID IS NOT NULL AND st.StakeLevelID<>gl.StakeLevelID_Changed)
				OR (dst.StakeLevelID IS NOT NULL AND dst.StakeLevelID<>gl.StakeLevelID_Changed))
				AND gl.IsChangedGlobal=1
			GROUP BY gl.transid
		)--,
		UPDATE gl
		SET gl.MaxBet=CASE WHEN t.transid IS NOT NULL 
						THEN (CASE WHEN gl.MaxStake_Changed>t.MaxStake THEN gl.MaxStake_Changed ELSE t.MaxStake END)
						ELSE gl.MaxStake_Changed
					END
		FROM #CustList_ChangedGlobal gl
			LEFT JOIN tmp1 t ON t.transid=gl.transid 
		WHERE gl.IsChangedGlobal=1
	END

	--update old: MaxBet & Insert data into #returnTbl
	;WITH tmpCust1 AS (
		SELECT cl.transid
			, CASE	WHEN sma.transid IS NOT NULL	THEN sma.MaxBet
					WHEN sma.transid IS NULL
					 AND gl.transid IS NOT NULL		THEN gl.MaxBet
			END AS MaxBet
			, CASE	WHEN sma.transid IS NOT NULL	THEN sma.MaxPerMatch
			END AS MaxPerMatch
			, CASE	WHEN sma.transid IS NOT NULL	THEN sma.StakeLevelList
					WHEN sma.transid IS NULL
					 AND gl.transid IS NOT NULL		THEN gl.StakeLevelList
			END AS StakeLevelList
		FROM #tmpCustList cl
			LEFT JOIN #CustList_ChangedSMA sma ON sma.transid=cl.transid
			LEFT JOIN #CustList_ChangedGlobal gl ON gl.transid=cl.transid AND gl.IsChangedGlobal=1
		WHERE sma.transid IS NOT NULL OR gl.transid IS NOT NULL
	)
	INSERT INTO #returnTbl (custid, transid, SportType, BetType, MaxBet, MaxPerMatch, StakeLevelList)
	SELECT cl.custid, cl.transid, cl.SportType, cl.BetType
		, t.MaxBet, t.MaxPerMatch, t.StakeLevelList
	FROM #tmpCustList cl
		INNER JOIN tmpCust1 t ON t.transid=cl.transid

	DELETE cl
	FROM #tmpCustList cl
		INNER JOIN #returnTbl re ON re.transid=cl.transid

	--Get curent MaxBet
	IF EXISTS (SELECT 1 FROM #tmpCustList cl
					INNER JOIN #RefBetSettingTbl ref ON ref.custid=cl.custid AND ref.BetType=cl.BetType
													AND ref.SportType=cl.SportType
			   WHERE TableBetSetting NOT IN('Dep_custStakeLevel_member','CustStakeLevel_Member'))
	BEGIN
		WHILE 1=1
		BEGIN 
			SELECT TOP 1 @TableBetSetting=TableBetSetting
			FROM #tmpCustList cl
			INNER JOIN #RefBetSettingTbl ref ON ref.custid=cl.custid 
											AND ref.BetType=cl.BetType
											AND ref.SportType=cl.SportType
			WHERE TableBetSetting NOT IN('Dep_custStakeLevel_member','CustStakeLevel_Member')

			IF @@ROWCOUNT = 0	
				BREAK;
			
			SET @SQL = 'SELECT bs.custid, cls.transid, bs.SportType
							, bs.BetType, bs.MaxBet
							, bs.MaxPerMatch
						FROM DBCust.CustDB.dbo.[' + @TableBetSetting + '] bs WITH (NOLOCK)
						WHERE EXISTS (	SELECT 1 
										FROM #tmpCustList cl 
										WHERE	cls.custid		= bs.custid
											AND cls.SportType	= bs.SportType
											AND cls.BetType		= bs.BetType
											AND cls.TableBetSetting	= @TableBetSetting)'
			
			INSERT INTO #returnTbl (custid, transid, SportType, BetType, MaxBet, MaxPerMatch)
			EXECUTE sys.sp_executesql @SQL, N'@TableBetSetting	VARCHAR(50)', @TableBetSetting

			DELETE cl
			FROM #tmpCustList cl
				INNER JOIN #RefBetSettingTbl ref
							ON	ref.custid=cl.custid
							AND ref.SportType=cl.SportType
							AND ref.BetType=cl.BetType
			WHERE TableBetSetting=@TableBetSetting
		END
	END
	ELSE IF EXISTS (SELECT 1 FROM #CustList_ChangedGlobal WHERE IsChangedGlobal=0)
	BEGIN
		INSERT INTO #returnTbl (custid, transid, SportType, BetType, StakeLevelList)
		SELECT custid, transid, SportType, BetType, StakeLevelList
		FROM #CustList_ChangedGlobal cl
		WHERE IsChangedGlobal=0

		--UPDATE MAXBET : Credit
		IF EXISTS (SELECT 1 FROM #CustList_ChangedGlobal gl
					INNER JOIN #tmpCustList cl ON cl.transid=gl.transid
					WHERE gl.IsChangedGlobal=0 AND cl.isLicensee=0)
		BEGIN
			WITH csll AS (
				SELECT r.transid,r.custid, r.SportType, r.BetType, r.StakeLevelList
					, MAX(CASE WHEN st.GameGroupID=0 THEN st.MaxStake ELSE stgd.MaxStake END) AS MaxStake
				FROM #returnTbl r WITH (ROWLOCK, UPDLOCK)
					INNER JOIN #tmpCustList cl ON cl.transid=r.transid
					CROSS APPLY (SELECT CAST(value AS INT) AS StakeLevelList_Value FROM STRING_SPLIT(r.StakeLevelList,',')) ss
					INNER JOIN DBCust.CustDB.dbo.StakeLevel st WITH (NOLOCK) ON st.StakeLevelID = ss.StakeLevelList_Value
					CROSS APPLY (SELECT TOP 1 stg.StakeLevelID, CAST(stg.MaxLabel AS MONEY) AS MaxStake
									FROM DBCust.CustDB.dbo.StakeLevelGroupDetail stg WITH (NOLOCK)
									WHERE stg.StakeLevelID = st.StakeLevelID
									ORDER BY CAST(stg.MaxLabel AS MONEY) DESC
									) stgd
				WHERE cl.isLicensee=0
				GROUP BY r.transid,r.custid, r.SportType, r.BetType, r.StakeLevelList
			)
			UPDATE r
			SET r.MaxBet = t1.MaxStake
			FROM #returnTbl r WITH (ROWLOCK, UPDLOCK)
				INNER JOIN csll t1 ON r.transid=t1.transid
		END

		--UPDATE MAXBET : Deposit
		IF EXISTS (SELECT 1 FROM #CustList_ChangedGlobal gl
					INNER JOIN #tmpCustList cl ON cl.transid=gl.transid
					WHERE gl.IsChangedGlobal=0 AND cl.isLicensee=1)
		BEGIN
			WITH csll AS (
				SELECT r.transid,r.custid, r.SportType, r.BetType, r.StakeLevelList
					, MAX(CASE WHEN st.GameGroupID=0 THEN st.MaxStake ELSE stgd.MaxStake END) AS MaxStake
				FROM #returnTbl r WITH (ROWLOCK, UPDLOCK)
					INNER JOIN #tmpCustList cl ON cl.transid=r.transid
					CROSS APPLY (SELECT CAST(value AS INT) AS StakeLevelList_Value FROM STRING_SPLIT(r.StakeLevelList,',')) ss
					INNER JOIN DBCust.CustDB.dbo.Dep_StakeLevel st WITH (NOLOCK) ON st.StakeLevelID = ss.StakeLevelList_Value
					CROSS APPLY (SELECT TOP 1 stg.StakeLevelID, CAST(stg.MaxLabel AS MONEY) AS MaxStake
									FROM DBCust.CustDB.dbo.Dep_StakeLevelGroupDetail stg WITH (NOLOCK)
									WHERE stg.StakeLevelID = st.StakeLevelID
									ORDER BY CAST(stg.MaxLabel AS MONEY) DESC
									) stgd
				WHERE cl.isLicensee=1
				GROUP BY r.custid, r.SportType, r.BetType, r.StakeLevelList
			)
			UPDATE r
			SET r.MaxBet = t1.MaxStake
			FROM #returnTbl r WITH (ROWLOCK, UPDLOCK)
				INNER JOIN csll t1 ON t1.transid=r.transid
		END
	END

	IF @@ERROR<>0
	BEGIN
		SELECT @ErrCode=ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE();		
		RETURN
	END 

	SELECT *
	FROM #returnTbl 
	
	DROP TABLE #tmpCustList
	DROP TABLE #RefBetSettingTbl
	DROP TABLE #CustList_ChangedSMA
	DROP TABLE #CustList_ChangedGlobal
	DROP TABLE #returnTbl
END
GO