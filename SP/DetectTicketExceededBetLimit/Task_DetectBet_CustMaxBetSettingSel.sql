/*<info serverAlias="DBTP-bodb02" executers="" isFunction="0" isNested="1"></info>*/

ALTER PROCEDURE [dbo].[Task_DetectBet_CustMaxBetSettingSel] 
AS
/*
	Created: 20220523@Tacy
	Task : Get MaxBet at the time of place bet
	DB: DBTP/bodb02
	Original:

	Revisions:
		- 20220523@Tacy: Initial SP [RedmineID: #170739]
		- 20220810@Elodie: Change name of temp table
		- 20220811@Tacy: Detect maxbet for Keno, Number Game product [RedmineID: #170739]

	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON

	CREATE TABLE #ListTmp (
			custid			INT
		,	SportType		SMALLINT
		,	BetType			INT
		,	GameTypeId		INT
		,	transid			BIGINT
		,	transdate		DATETIME
		,	srecommend		INT
		,	recommend		INT
		,	isLive			BIT
		,	SportTypeRef	SMALLINT
		,	BetTypeRef		INT
		,	SettingType		TINYINT
		,	isLicensee		BIT
	)
	CREATE CLUSTERED INDEX PK_transid ON #ListTmp (transid)

	CREATE TABLE #CustList_ChangedSMA (
			custid				INT
		,	transid				BIGINT
		,	SportType			SMALLINT
		,	BetType				INT
		,	MaxBet				MONEY
		,	MaxPerMatch			MONEY
		,	StakeLevelList		VARCHAR(200)
		,	UpdateTime_SMA		DATETIME
		,	PRIMARY KEY CLUSTERED (transid)
	)
	
	CREATE TABLE #returnTbl (
			custid			INT
		,	transid			BIGINT
		,	SportType		SMALLINT
		,	BetType			INT
		,	MaxBet			MONEY
		,	MaxPerMatch		MONEY
		,	PRIMARY KEY CLUSTERED (transid)
	)

	DECLARE @tmp_GameType TABLE (GameTypeID INT, GameTypeName NVARCHAR(50), IsDisabled BIT, IBCBettypeID INT)

	BEGIN TRY		
		INSERT INTO @tmp_GameType (GameTypeID, GameTypeName, IsDisabled, IBCBettypeID)
		SELECT GameTypeID, GameTypeName, IsDisabled, IBCBettypeID 
		FROM DBAGE.bodb02.dbo.GameType WITH (NOLOCK)
		WHERE IBCBetTypeID BETWEEN 1501 AND 1599	--Keno
	END TRY
	BEGIN CATCH		
		INSERT INTO @tmp_GameType (GameTypeID, GameTypeName, IsDisabled, IBCBettypeID)
		SELECT GameTypeID, GameTypeName, IsDisabled, IBCBettypeID 
		FROM DBTXN.bodb02.dbo.GameType WITH (NOLOCK)
		WHERE IBCBetTypeID BETWEEN 1501 AND 1599	--Keno
	END CATCH
	
	--nonClustered
	CREATE NONCLUSTERED INDEX IX_tmpCustList ON #ListTmp(custid,SportTypeRef,BetTypeRef)

	-- checking dependency        
	IF OBJECT_ID('tempdb..#tmp_TransId') IS NULL
	BEGIN  
		RETURN
	END

	--Get data from #tmp_TransId (exists in super sp: [Task_DetectBet_bettrans], [Task_DetectBet_bettransLC], [Task_DetectBet_bettransRnG])
	INSERT INTO #ListTmp (custid, SportType, BetType, transid, transdate, srecommend, recommend, isLive)
	SELECT custid, SportType, BetType, transid, transdate, srecommend, recommend, isLive
	FROM #tmp_TransId
	
	--Update isLicensee
	UPDATE #ListTmp
	SET isLicensee = CASE WHEN dep.custid IS NULL THEN 0 ELSE 1 END
	FROM #ListTmp tc
		LEFT JOIN Dep_CustSuper dep WITH (NOLOCK) ON dep.custid=tc.srecommend

	--Get: SportTypeBetSetting, BetTypeBetSetting, SettingType, GameTypeId
	--Credit
	UPDATE cl 
	SET cl.SportTypeRef=ref.SportTypeRefBetSetting
	, cl.BetTypeRef=ref.BetTypeRefBetSetting
	, cl.GameTypeId=CASE WHEN cl.SportType IN (171,150,200,237) --VGaming, SABA.Games, MaxGame
					THEN ref.BetTypeRefBetSetting ELSE cl.BetType END
	, cl.SettingType=ps.SettingType
	FROM #ListTmp cl
		INNER JOIN SportBettypeSettingMatrix ref WITH (NOLOCK)
				ON	ref.Sporttype	= cl.sporttype 
				AND ref.Bettype		= cl.bettype
				AND ref.isLicensee	= cl.isLicensee
				AND ref.isLive		= cl.isLive
		INNER JOIN ProductSettingDetail ps WITH (NOLOCK)
				ON ps.SportType=ref.SportTypeRefBetSetting
				AND ps.BetType=ref.BetTypeRefBetSetting
	WHERE ps.SettingType IN (2,7,8,9,16,17,20) AND cl.isLicensee=0 AND ps.SettingStatus=0

	--NG, Keno:
	UPDATE cl 
	SET cl.SportTypeRef=cl.SportType
	, cl.BetTypeRef=cl.BetType
	FROM #ListTmp cl
		INNER JOIN SportBettypeSettingMatrix ref WITH (NOLOCK)
				ON	ref.Sporttype	= cl.sporttype 
				AND ref.Bettype		= cl.bettype
				AND ref.isLicensee	= cl.isLicensee
				AND ref.isLive		= cl.isLive
	WHERE cl.SportType IN (161,164,168,202) AND cl.isLicensee=0

	--Keno: GameTypeId
	UPDATE cl 
	SET cl.GameTypeId=gt.GameTypeID
	FROM #ListTmp cl
		INNER JOIN @tmp_GameType gt ON gt.IBCBettypeID=cl.BetType
	WHERE SportType=202 AND cl.isLicensee=0

	--Deposit
	UPDATE cl 
	SET cl.SportTypeRef=ref.SportTypeRefBetSetting
	, cl.BetTypeRef=ref.BetTypeRefBetSetting
	, cl.GameTypeId=CASE WHEN cl.SportType IN (171,150,200,237) --VGaming, SABA.Games, MaxGame
					THEN ref.BetTypeRefBetSetting ELSE cl.BetType END
	, cl.SettingType=ps.SettingType
	FROM #ListTmp cl
		INNER JOIN SportBettypeSettingMatrix ref WITH (NOLOCK)
				ON	ref.Sporttype	= cl.sporttype 
				AND ref.Bettype		= cl.bettype
				AND ref.isLicensee	= cl.isLicensee
				AND ref.isLive		= cl.isLive
		INNER JOIN Dep_ProductSettingDetail psd WITH (NOLOCK) 
				ON psd.SportType=ref.SportTypeRefBetSetting
				AND psd.BetType=ref.BetTypeRefBetSetting
		INNER JOIN Dep_ProductSetting ps WITH (NOLOCK) 
				ON ps.ProductSettingID=psd.ProductSettingID
	WHERE ps.SettingType IN (2,7,8,10,11,12) AND cl.isLicensee=1 AND psd.SettingStatus=0

	-- @sporttype: not support StakeLevel
	IF EXISTS (SELECT 1 FROM #ListTmp WHERE SettingType NOT IN (7,8,17) OR SportType IN (161,164,168,202))
	BEGIN
		INSERT INTO #returnTbl(custid, transid, SportType, BetType, MaxBet, MaxPerMatch)
		SELECT cl.custid, cl.transid, cl.SportType, cl.BetType
			, CASE WHEN (cl.isLicensee=0 AND ch.custid IS NOT NULL) THEN ch.OldMaxBet
				   WHEN (cl.isLicensee=1 AND dch.custid IS NOT NULL) THEN dch.OldMaxBet END MaxBet
		
			, CASE WHEN (cl.isLicensee=0 AND ch.custid IS NOT NULL) THEN ch.OldMaxPerMatch
					WHEN (cl.isLicensee=1 AND dch.custid IS NOT NULL) THEN dch.OldMaxPerMatch END MaxPerMatch
		FROM #ListTmp cl
		--CREDIT
			OUTER APPLY (SELECT TOP (1) ch. custid, OldMaxBet, OldMaxPerMatch, UpdateTime 
						 FROM CustMaxBetSetting_History ch WITH (NOLOCK)
						 WHERE  ch.custid=cl.custid AND ch.SportType=cl.SportTypeRef
							AND ch.BetType=cl.BetTypeRef AND ch.UpdateTime>cl.transdate 
						 ORDER BY UpdateTime
						 ) ch
		--DEPOSIT
			OUTER APPLY (SELECT TOP (1) dch.custid, OldMaxBet, OldMaxPerMatch, UpdateTime 
						 FROM Dep_CustMaxBetSetting_History dch WITH (NOLOCK)
						 WHERE dch.custid=cl.custid AND dch.SportType=cl.SportTypeRef
							AND dch.BetType=cl.BetTypeRef AND dch.UpdateTime>cl.transdate  
						 ORDER BY UpdateTime
						 ) dch
		WHERE (cl.SettingType NOT IN (7,8,17) OR SportType IN (161,164,168,202)) AND
			(
			  (cl.isLicensee=0 AND ch.custid IS NOT NULL)
			OR 
			  (cl.isLicensee=1 AND dch.custid IS NOT NULL)
			)

		--Current Maxbet
		--CREDIT
		IF EXISTS (	SELECT 1 FROM #ListTmp cl
					WHERE (cl.SettingType NOT IN (7,8,17) OR SportType IN (161,164,168,202)) 
						AND cl.isLicensee=0
						AND NOT EXISTS (SELECT 1 FROM #returnTbl re 
										WHERE re.transid=cl.transid)
					)
		BEGIN
			INSERT INTO #returnTbl(custid, transid, SportType, BetType, MaxBet, MaxPerMatch)
			SELECT a.custid, a.transid, a.SportType, a.BetType, a.MaxBet, a.MaxPerMatch
			FROM (	SELECT cl.custid, cl.transid, cl.SportType, cl.BetType, cbs.MaxBet, cbs.MaxPerMatch
					FROM #ListTmp cl
						INNER JOIN CustBetSetting3rd_Member cbs WITH (NOLOCK) ON cbs.CustID=cl.custid
																			AND cbs.SportType=cl.SportTypeRef
																			AND cbs.BetType=cl.BetTypeRef
					WHERE cl.SettingType NOT IN (7,8,17) AND cl.isLicensee=0
						AND NOT EXISTS (SELECT 1 FROM #returnTbl re 
										WHERE re.transid=cl.transid)
					UNION	--NumberGame
					SELECT cl.custid, cl.transid, cl.SportType, cl.BetType, cbs.MaxBet, cbs.MaxPerMatch
					FROM #ListTmp cl
						INNER JOIN CustBetSetting_Member cbs WITH (NOLOCK) ON cbs.CustID=cl.custid
																		AND cbs.SportType=cl.SportTypeRef
																		AND cbs.BetType=cl.BetTypeRef
					WHERE cl.SportType IN (161,164,168) AND cl.isLicensee=0
						AND NOT EXISTS (SELECT 1 FROM #returnTbl re 
										WHERE re.transid=cl.transid)
					UNION	--Keno
					SELECT cl.custid, cl.transid, cl.SportType, cl.BetType, cgt.MaxBet, cgt.MaxPerGameType
					FROM #ListTmp cl
						INNER JOIN CustGameType cgt WITH (NOLOCK) ON cl.custid=cgt.CustID
																AND cl.GameTypeId=cgt.GameTypeID
																AND cgt.IsDisabled=0
					WHERE cl.SportType=202 AND cl.isLicensee=0
						AND NOT EXISTS (SELECT 1 FROM #returnTbl re 
										WHERE re.transid=cl.transid)
				) a
		END

		--DEPOSIT
		IF EXISTS (	SELECT 1 FROM #ListTmp cl
					WHERE (cl.SettingType NOT IN (7,8,17) OR SportType IN (161,164,168,202)) 
						AND cl.isLicensee=1
						AND NOT EXISTS (SELECT 1 FROM #returnTbl re 
										WHERE re.transid=cl.transid)
					)
		BEGIN
			INSERT INTO #returnTbl(custid, transid, SportType, BetType, MaxBet, MaxPerMatch)
			SELECT a.custid, a.transid, a.SportType, a.BetType, a.MaxBet, a.MaxPerMatch
			FROM (	SELECT cl.custid, cl.transid, cl.SportType, cl.BetType, dcbs.MaxBet, dcbs.MaxPerMatch
					FROM #ListTmp cl
					INNER JOIN Dep_CustBetSetting_Member dcbs WITH (NOLOCK) ON dcbs.CustID=cl.custid
																			AND dcbs.SportType=cl.SportTypeRef
																			AND dcbs.BetType=cl.BetTypeRef
					WHERE cl.SettingType NOT IN (7,8,17) AND cl.isLicensee=1
						AND NOT EXISTS (SELECT 1 FROM #returnTbl re 
										WHERE re.transid=cl.transid)
					UNION --NumberGame
					SELECT	cl.custid, cl.transid, cl.SportType, cl.BetType, 
							CASE WHEN mode.IsGroupedBetLimit=0 THEN dcbs.MaxBet		 
								 WHEN mode.IsGroupedBetLimit=1 THEN gg.MaxBet		 
							END MaxBet,
							CASE WHEN mode.IsGroupedBetLimit=0 THEN dcbs.MaxPerMatch 
								 WHEN mode.IsGroupedBetLimit=1 THEN gg.MaxPerMatch 
							END MaxPerMatch
					FROM #ListTmp cl
						INNER JOIN Dep_custsettingmode mode WITH (NOLOCK) ON mode.CustID=cl.custid
						LEFT JOIN Dep_CustBetSettingGameGroup_Member gg WITH (NOLOCK) ON gg.AgentID=cl.recommend
																					AND gg.SportType=cl.SportTypeRef
																					AND gg.BetType=cl.BetTypeRef
						LEFT JOIN Dep_CustBetSettingGame_Member dcbs WITH (NOLOCK) ON dcbs.CustID=cl.custid
																	AND dcbs.SportType=cl.SportTypeRef
																	AND dcbs.BetType=cl.BetTypeRef
					WHERE cl.SportType IN (161,164,168) AND cl.isLicensee=1
						AND NOT EXISTS (SELECT 1 FROM #returnTbl re 
										WHERE re.transid=cl.transid)
				) a
		END

		DELETE #ListTmp WHERE SettingType NOT IN (7,8,17) OR SportType IN (161,164,168,202)
	END

	-- @sporttype: support StakeLevel - SettingType IN (7,17)
	IF EXISTS (SELECT 1 FROM #ListTmp WHERE SettingType IN (7,17))
	BEGIN
		--Get List cust: MaxBet is changed by SMA
		INSERT INTO #CustList_ChangedSMA(custid, transid, SportType, BetType, MaxBet, StakeLevelList, UpdateTime_SMA)
		SELECT cl.custid, cl.transid, cl.SportType, cl.BetType
			
			, CASE WHEN (cl.isLicensee=0 AND ch.custid IS NOT NULL) THEN ch.OldMaxBet
				   WHEN (cl.isLicensee=1 AND dch.custid IS NOT NULL) THEN dch.OldMaxBet END MaxBet

			, CASE WHEN (cl.isLicensee=0 AND ch.custid IS NOT NULL) THEN ch.OldStakeLevelList
					WHEN (cl.isLicensee=1 AND dch.custid IS NOT NULL) THEN dch.OldStakeLevelList END StakeLevelList
			
			, CASE WHEN (cl.isLicensee=0 AND ch.custid IS NOT NULL) THEN ch.UpdateTime
					WHEN (cl.isLicensee=1 AND dch.custid IS NOT NULL) THEN dch.UpdateTime END UpdateTime_SMA
		FROM #ListTmp cl
			OUTER APPLY (SELECT TOP (1) ch. custid, OldMaxBet, OldStakeLevelList, UpdateTime 
						 FROM CustMaxBetSetting_History ch WITH (NOLOCK)
						 WHERE  ch.custid=cl.custid AND ch.SportType=cl.SportTypeRef
							AND ch.BetType=cl.BetTypeRef AND ch.UpdateTime>cl.transdate 
						 ORDER BY UpdateTime
						) ch
			OUTER APPLY (SELECT TOP (1) dch.custid, OldMaxBet, OldStakeLevelList, UpdateTime 
						 FROM Dep_CustMaxBetSetting_History dch WITH (NOLOCK)
						 WHERE dch.custid=cl.custid AND dch.SportType=cl.SportTypeRef
							AND dch.BetType=cl.BetTypeRef AND dch.UpdateTime>cl.transdate  
						 ORDER BY UpdateTime
						) dch
		WHERE cl.SettingType IN (7,17) AND
			(
			  (cl.isLicensee=0 AND ch.custid IS NOT NULL)
			OR 
			  (cl.isLicensee=1 AND dch.custid IS NOT NULL)
			)


		;WITH CustList_Global1 AS (--get StakeLevelList
			SELECT cl.custid, cl.transid, cl.SportType, cl.BetType
				, CASE	WHEN sma.transid IS NOT NULL  THEN sma.StakeLevelList
						WHEN cslm.CustID IS NOT NULL  THEN cslm.StakeLevelList
						WHEN dcslm.CustID IS NOT NULL THEN dcslm.StakeLevelList
					END	AS StakeLevelList
			FROM #ListTmp cl
				LEFT JOIN CustStakeLevel_Member cslm WITH (NOLOCK)
						ON cslm.custid=cl.custid
						AND cslm.SportType=cl.SportTypeRef
						AND cslm.BetType=cl.BetTypeRef
				LEFT JOIN Dep_CustStakeLevel_Member dcslm WITH (NOLOCK)
						ON dcslm.custid=cl.custid
						AND dcslm.SportType=cl.SportTypeRef
						AND dcslm.BetType=cl.BetTypeRef
				LEFT JOIN #CustList_ChangedSMA sma ON sma.transid=cl.transid
			WHERE SettingType IN (7,17) AND 
				(cslm.CustID IS NOT NULL OR dcslm.CustID IS NOT NULL OR sma.transid IS NOT NULL)
		),
		CustList_Global2 AS (--get isChangedGlobal, MaxStake_old
			SELECT clg.custid, clg.transid
				, CASE	WHEN cre.StakeLevelID IS NOT NULL AND cl.isLicensee=0 THEN cre.UpdateTime
						WHEN dep.StakeLevelID IS NOT NULL AND cl.isLicensee=1 THEN dep.UpdateTime
					END UpdateTime_Global
				, MAX(CASE	WHEN cre.StakeLevelID IS NOT NULL AND cl.isLicensee=0 THEN cre.isChangedGlobal
							WHEN dep.StakeLevelID IS NOT NULL AND cl.isLicensee=1 THEN dep.isChangedGlobal END) AS isChangedGlobal
				, MAX(CASE	WHEN cre.StakeLevelID IS NOT NULL AND cl.isLicensee=0 THEN cre.MaxLabel
							WHEN dep.StakeLevelID IS NOT NULL AND cl.isLicensee=1 THEN dep.MaxLabel
						END) AS MaxStake_old
				, ss.StakeLevelID
			FROM CustList_Global1 clg
				INNER JOIN #ListTmp cl ON cl.transid=clg.transid
				OUTER APPLY (SELECT CAST(value AS INT) AS StakeLevelID FROM STRING_SPLIT(clg.StakeLevelList,',')) ss
				--Credit
				OUTER APPLY (SELECT TOP (1) StakeLevelID, MaxLabel, UpdateTime, isChangedGlobal
							 FROM 
								(SELECT TOP (1) StakeLevelID, CAST(MaxLabel AS MONEY) AS MaxLabel, UpdateTime, 1 AS isChangedGlobal
								 FROM StakeLevel_History st WITH (NOLOCK) 
								 WHERE st.StakeLevelID = ss.StakeLevelID
									AND st.UpdateTime>cl.transdate
								 ORDER BY UpdateTime
								 UNION ALL
								 SELECT TOP (1) StakeLevelID, CAST(MaxLabel AS MONEY) AS MaxLabel, GETDATE() AS UpdateTime, 0 AS isChangedGlobal
								 FROM StakeLevel stc WITH (NOLOCK) 
								 WHERE stc.StakeLevelID = ss.StakeLevelID) a
							 ORDER BY UpdateTime
							) cre
				--Deposit
				OUTER APPLY (SELECT TOP (1) StakeLevelID, MaxLabel, UpdateTime, isChangedGlobal
							 FROM 
								(SELECT TOP (1) StakeLevelID, CAST(MaxLabel AS MONEY) AS MaxLabel, UpdateTime, 1 AS isChangedGlobal
								 FROM Dep_StakeLevel_History dst WITH (NOLOCK) 
								 WHERE dst.StakeLevelID = ss.StakeLevelID
									AND dst.UpdateTime>cl.transdate
								 ORDER BY UpdateTime
								 UNION ALL
								 SELECT TOP (1) StakeLevelID, CAST(MaxLabel AS MONEY) AS MaxLabel, GETDATE() AS UpdateTime, 0 AS isChangedGlobal
								 FROM Dep_StakeLevel dstc WITH (NOLOCK) 
								 WHERE dstc.StakeLevelID = ss.StakeLevelID) a
							 ORDER BY UpdateTime
							) dep
			GROUP BY clg.custid, clg.transid
				, CASE	WHEN cre.StakeLevelID IS NOT NULL AND cl.isLicensee=0 THEN cre.UpdateTime
						WHEN dep.StakeLevelID IS NOT NULL AND cl.isLicensee=1 THEN dep.UpdateTime
					END
				, ss.StakeLevelID
		),
		CustList_Global_tmp AS (
			SELECT gl.transid, MAX(gl.MaxStake_old) MaxStake_old
			FROM CustList_Global2 gl
				CROSS APPLY (SELECT gl2.transid, COUNT(DISTINCT gl2.StakeLevelID) AS cnt 
							 FROM CustList_Global2 gl2 
							 WHERE gl.transid=gl2.transid
							 GROUP BY gl2.transid) gl2
			WHERE gl2.cnt>1
			GROUP BY gl.transid
		)
		INSERT INTO #returnTbl (custid, transid, SportType, BetType, MaxBet)
		SELECT cl.custid, cl.transid, cl.SportType, cl.BetType
			, CASE WHEN t.transid IS NOT NULL											THEN t.MaxStake_old
				   WHEN sma.UpdateTime_SMA IS NOT NULL AND gl.isChangedGlobal=0			THEN gl.MaxStake_Old
				   WHEN sma.UpdateTime_SMA IS NULL										THEN gl.MaxStake_Old
				   WHEN sma.UpdateTime_SMA<gl.UpdateTime_Global	AND isChangedGlobal=1	THEN sma.MaxBet
				   WHEN sma.UpdateTime_SMA>gl.UpdateTime_Global							THEN gl.MaxStake_Old
			END MaxBet
		FROM #ListTmp cl
			LEFT JOIN #CustList_ChangedSMA sma ON sma.transid=cl.transid
			LEFT JOIN CustList_Global_tmp t ON t.transid=cl.transid
			OUTER APPLY (SELECT gl.transid, gl.MaxStake_old, gl.isChangedGlobal, gl.UpdateTime_Global
						 FROM CustList_Global2 gl
						 WHERE gl.transid=cl.transid
						 AND NOT EXISTS (SELECT 1 FROM CustList_Global_tmp t WHERE t.transid=gl.transid)) gl
		WHERE SettingType IN (7,17) 
			AND (sma.transid IS NOT NULL OR gl.transid IS NOT NULL OR t.transid IS NOT NULL)
			AND NOT EXISTS (SELECT 1 FROM #returnTbl re WHERE re.transid=cl.transid)

		DELETE #ListTmp WHERE SettingType IN (7,17)
		DELETE #CustList_ChangedSMA
	END

	-- @sporttype: support StakeLevel - SettingType=8; 
	IF EXISTS (SELECT 1 FROM #ListTmp WHERE SettingType=8)
	BEGIN
		--Get List cust: MaxBet is changed by SMA
		INSERT INTO #CustList_ChangedSMA(custid, transid, SportType, BetType, MaxBet, StakeLevelList, UpdateTime_SMA)
		SELECT cl.custid, cl.transid, cl.SportType, cl.BetType
			
			, CASE WHEN (cl.isLicensee=0 AND ch.custid IS NOT NULL) THEN ch.OldMaxBet
				   WHEN (cl.isLicensee=1 AND dch.custid IS NOT NULL) THEN dch.OldMaxBet END MaxBet

			, CASE WHEN (cl.isLicensee=0 AND ch.custid IS NOT NULL) THEN ch.OldStakeLevelList
					WHEN (cl.isLicensee=1 AND dch.custid IS NOT NULL) THEN dch.OldStakeLevelList END StakeLevelList
			
			, CASE WHEN (cl.isLicensee=0 AND ch.custid IS NOT NULL) THEN ch.UpdateTime
					WHEN (cl.isLicensee=1 AND dch.custid IS NOT NULL) THEN dch.UpdateTime END UpdateTime_SMA
		FROM #ListTmp cl
			OUTER APPLY (SELECT TOP (1) ch. custid, OldMaxBet, OldStakeLevelList, UpdateTime 
						 FROM CustMaxBetSetting_History ch WITH (NOLOCK)
						 WHERE  ch.custid=cl.custid AND ch.SportType=cl.SportTypeRef
							AND ch.BetType=cl.BetTypeRef AND ch.UpdateTime>cl.transdate 
						 ORDER BY UpdateTime
						) ch
			OUTER APPLY (SELECT TOP (1) dch.custid, OldMaxBet, OldStakeLevelList, UpdateTime 
						 FROM Dep_CustMaxBetSetting_History dch WITH (NOLOCK)
						 WHERE dch.custid=cl.custid AND dch.SportType=cl.SportTypeRef
							AND dch.BetType=cl.BetTypeRef AND dch.UpdateTime>cl.transdate  
						 ORDER BY UpdateTime
						) dch
		WHERE cl.SettingType=8 AND
			(
			  (cl.isLicensee=0 AND ch.custid IS NOT NULL)
			OR 
			  (cl.isLicensee=1 AND dch.custid IS NOT NULL)
			)


		;WITH CustList_Global1 AS (--get StakeLevelList
			SELECT cl.custid, cl.transid, cl.SportType, cl.BetType
				, CASE	WHEN sma.transid IS NOT NULL  THEN sma.StakeLevelList
						WHEN cslm.CustID IS NOT NULL  THEN cslm.StakeLevelList
						WHEN dcslm.CustID IS NOT NULL THEN dcslm.StakeLevelList
					END	AS StakeLevelList
			FROM #ListTmp cl
				LEFT JOIN CustStakeLevel_Member cslm WITH (NOLOCK)
						ON cslm.custid=cl.custid
						AND cslm.SportType=cl.SportTypeRef
						AND cslm.BetType=cl.BetTypeRef
				LEFT JOIN Dep_CustStakeLevel_Member dcslm WITH (NOLOCK)
						ON dcslm.custid=cl.custid
						AND dcslm.SportType=cl.SportTypeRef
						AND dcslm.BetType=cl.BetTypeRef
				LEFT JOIN #CustList_ChangedSMA sma ON sma.transid=cl.transid
			WHERE SettingType=8 AND 
				(cslm.CustID IS NOT NULL OR dcslm.CustID IS NOT NULL OR sma.transid IS NOT NULL)
		),
		CustList_Global2 AS (--get MaxStake_old
			SELECT clg.custid, clg.transid
				, CASE	WHEN cre.StakeLevelID IS NOT NULL AND cl.isLicensee=0 THEN cre.UpdateTime
						WHEN dep.StakeLevelID IS NOT NULL AND cl.isLicensee=1 THEN dep.UpdateTime
					END UpdateTime_Global
				, CASE	WHEN cre.StakeLevelID IS NOT NULL AND cl.isLicensee=0 THEN cre.MaxGameStake
						WHEN dep.StakeLevelID IS NOT NULL AND cl.isLicensee=1 THEN dep.MaxGameStake
					END AS MaxStake_old
			FROM CustList_Global1 clg
				INNER JOIN #ListTmp cl ON cl.transid=clg.transid
				--Credit
				OUTER APPLY (SELECT TOP (1) StakeLevelID, MaxGameStake, UpdateTime
							 FROM
								(SELECT TOP (1) StakeLevelID
											, CASE WHEN MaxGameStake IS NOT NULL THEN MaxGameStake ELSE CAST(MaxLabel AS MONEY) END MaxGameStake
											, UpdateTime
								 FROM StakeLevelGroupDetail_History stg WITH (NOLOCK) 
								 WHERE stg.StakeLevelID = clg.StakeLevelList
									AND stg.GameTypeID=cl.GameTypeId
									AND stg.UpdateTime>cl.transdate
								UNION ALL
								SELECT TOP (1) StakeLevelID
											, CASE WHEN MaxGameStake IS NOT NULL THEN MaxGameStake ELSE CAST(MaxLabel AS MONEY) END MaxGameStake
											, GETDATE() AS UpdateTime
								 FROM StakeLevelGroupDetail stgc WITH (NOLOCK) 
								 WHERE stgc.StakeLevelID = clg.StakeLevelList
									AND stgc.GameTypeID=cl.GameTypeId
								) a
								ORDER BY UpdateTime
							) cre
				--Deposit
				OUTER APPLY (SELECT TOP (1) StakeLevelID, MaxGameStake, UpdateTime
							 FROM
								(SELECT TOP (1) StakeLevelID
											, CASE WHEN MaxGameStake IS NOT NULL THEN MaxGameStake ELSE CAST(MaxLabel AS MONEY) END MaxGameStake
											, UpdateTime
								 FROM Dep_StakeLevelGroupDetail_History dstg WITH (NOLOCK) 
								 WHERE dstg.StakeLevelID = clg.StakeLevelList
									AND dstg.GameTypeID=cl.GameTypeId
									AND dstg.UpdateTime>cl.transdate
								UNION ALL
								SELECT TOP (1) StakeLevelID
											, CASE WHEN MaxGameStake IS NOT NULL THEN MaxGameStake ELSE CAST(MaxLabel AS MONEY) END MaxGameStake
											, GETDATE() AS UpdateTime
								 FROM Dep_StakeLevelGroupDetail dstgc WITH (NOLOCK) 
								 WHERE dstgc.StakeLevelID = clg.StakeLevelList
									AND dstgc.GameTypeID=cl.GameTypeId
								) a
								ORDER BY UpdateTime
							) dep
		)
		INSERT INTO #returnTbl (custid, transid, SportType, BetType, MaxBet)
		SELECT cl.custid, cl.transid, cl.SportType, cl.BetType, gl.MaxStake_Old
		FROM #ListTmp cl
			LEFT JOIN #CustList_ChangedSMA sma ON sma.transid=cl.transid
			LEFT JOIN CustList_Global2 gl ON gl.transid=cl.transid 
		WHERE SettingType=8
			AND (sma.transid IS NOT NULL OR gl.transid IS NOT NULL)
			AND NOT EXISTS (SELECT 1 FROM #returnTbl re WHERE re.transid=cl.transid)
	
		DELETE #ListTmp WHERE SettingType=8
	END

	UPDATE t1 
	SET IsInvalid = 1, 
		t1.MaxBet = t2.MaxBet
	FROM #tmp_TransId t1
		OUTER APPLY(
			SELECT t2.MaxBet
			FROM #returnTbl t2 
			WHERE t2.TransId = t1.TransId
		)t2
	WHERE t1.stake > ISNULL(t2.MaxBet,0)

	DROP TABLE #ListTmp
	DROP TABLE #CustList_ChangedSMA
	DROP TABLE #returnTbl
END
GO