/*<info serverAlias="DBTP-bodb02" executers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[Task_DetectBet_CustMaxBetSettingSel] 
		@CustList	VARCHAR(MAX) = ''
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
			<r c= ''1400001'' s=''248'' b=''4186'' tid=''12345678'' t=''2022-03-10 04:10:10.000'' sr=''1300001''  r=''1300003''  il=''0''/>
			<r c=''23700002'' s=''176'' b=''8202'' tid=''13524659'' t=''2022-03-10 04:10:10.000'' sr=''23600001'' r=''23600003'' il=''0''/>
		</root>

	• c: custid
      s: sporttype
      b: bettype
      t: transdate
      tid: transid
      sr: srecommend
      r: recommend
      il: isLive
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @xml			XML = NULL
		,	@SettingType	VARCHAR(50)
		,	@SQL			NVARCHAR(MAX)

	CREATE TABLE #tmpCustList (
			custid				INT
		,	SportType			SMALLINT
		,	BetType				INT
		,	transid				BIGINT
		,	transdate			DATETIME
		,	srecommend			INT
		,	recommend			INT
		,	isLive				BIT
		,	SportTypeRef		SMALLINT
		,	BetTypeRef			INT
		,	SettingType			TINYINT
		,	isLicensee			BIT
		,	PRIMARY KEY CLUSTERED (transid)
	)

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
	
	--nonClustered
	CREATE NONCLUSTERED INDEX IX_tmpCustList ON #tmpCustList(custid,SportTypeRef,BetTypeRef)

	--Check if XML is null or empty
	IF @CustList IS NULL OR @CustList=''
		RETURN
	
	SET @xml = CONVERT(XML, @CustList)

	--Parse XML	
	DECLARE @iDoc INT

	EXEC sp_xml_preparedocument @iDoc OUTPUT
		, @xml

	INSERT INTO #tmpCustList(custid, SportType, BetType, transid, transdate, srecommend, recommend, isLive)
	SELECT c, s, b, tid, t, sr, r, il
	FROM OPENXML(@iDoc, '/root/r', 1) 
	WITH (
			c	INT
		,	s	SMALLINT
		,	b	INT
		,	tid	BIGINT
		,	t	DATETIME
		,	sr	INT
		,	r	INT
		,	il	BIT
		) t
		
	EXEC sp_xml_removedocument @iDoc

	--Update isLicensee
	UPDATE #tmpCustList
	SET isLicensee = CASE WHEN dep.custid IS NULL THEN 0 ELSE 1 END
	FROM #tmpCustList tc
		LEFT JOIN Dep_CustSuper dep WITH (NOLOCK) ON dep.custid=tc.srecommend

	--Get: SportTypeBetSetting, BetTypeBetSetting, SettingType
	UPDATE cl 
	SET cl.SportTypeRef=ref.SportTypeRefBetSetting
	, cl.BetTypeRef=ref.BetTypeRefBetSetting
	, cl.SettingType=ps.SettingType
	FROM #tmpCustList cl
		INNER JOIN dbtxn.bodb02.dbo.Sport_Bettype_Reference_Setting ref WITH (NOLOCK)
			ON	ref.Sporttype	= cl.sporttype 
			AND ref.Bettype		= cl.bettype
			AND ref.isLicensee	= cl.isLicensee
			AND ref.isLive		= cl.isLive
		INNER JOIN ProductSettingDetail ps ON ps.SportType=ref.SportTypeRefBetSetting
										AND ps.BetType=ref.BetTypeRefBetSetting
	WHERE ps.SettingType IN (2,7,8,9,16,20)

	-- @sporttype: not support StakeLevel
	IF EXISTS (SELECT 1 FROM #tmpCustList WHERE SettingType NOT IN (7,8))
	BEGIN
		INSERT INTO #returnTbl(custid, transid, SportType, BetType, MaxBet, MaxPerMatch)
		SELECT cl.custid, cl.transid, cl.SportType, cl.BetType

			, CASE WHEN (cl.isLicensee=0 AND ch.custid IS NOT NULL) THEN ch.OldMaxBet
				   WHEN (cl.isLicensee=1 AND dch.custid IS NOT NULL) THEN dch.OldMaxBet END MaxBet
		
			, CASE WHEN (cl.isLicensee=0 AND ch.custid IS NOT NULL) THEN ch.OldMaxPerMatch
					WHEN (cl.isLicensee=1 AND dch.custid IS NOT NULL) THEN dch.OldMaxPerMatch END MaxPerMatch
		FROM #tmpCustList cl
			OUTER APPLY (SELECT TOP (1) ch. custid, OldMaxBet, OldMaxPerMatch, UpdateTime 
						 FROM CustMaxBetSetting_History ch 
						 WHERE  ch.custid=cl.custid AND ch.SportType=cl.SportTypeRef
							AND ch.BetType=cl.BetTypeRef AND ch.UpdateTime>cl.transdate 
						 ORDER BY UpdateTime
						 ) ch
			OUTER APPLY (SELECT TOP (1) dch.custid, OldMaxBet, OldMaxPerMatch, UpdateTime 
						 FROM Dep_CustMaxBetSetting_History dch 
						 WHERE dch.custid=cl.custid AND dch.SportType=cl.SportTypeRef
							AND dch.BetType=cl.BetTypeRef AND dch.UpdateTime>cl.transdate  
						 ORDER BY UpdateTime
						 ) dch
		WHERE cl.SettingType NOT IN (7,8) AND
			(
			  (cl.isLicensee=0 AND ch.custid IS NOT NULL)
			OR 
			  (cl.isLicensee=1 AND dch.custid IS NOT NULL)
			)

		--Current Maxbet
		--Credit
		IF EXISTS (	SELECT 1 FROM #tmpCustList cl
					WHERE cl.SettingType NOT IN (7,8) AND cl.isLicensee=0
						AND NOT EXISTS (SELECT 1 FROM #returnTbl re 
										WHERE re.transid=cl.transid)
					)
		BEGIN
			INSERT INTO #returnTbl(custid, transid, SportType, BetType, MaxBet, MaxPerMatch)
			SELECT cl.custid, cl.transid, cl.SportType, cl.BetType, cbs.MaxBet, cbs.MaxPerMatch
			FROM #tmpCustList cl
				INNER JOIN CustBetSetting3rd_Member cbs WITH (NOLOCK) ON cbs.CustID=cl.custid
																	AND cbs.SportType=cl.SportTypeRef
																	AND cbs.BetType=cl.BetTypeRef
			WHERE cl.SettingType NOT IN (7,8) AND cl.isLicensee=0
				AND NOT EXISTS (SELECT 1 FROM #returnTbl re 
								WHERE re.transid=cl.transid)
		END
		--deposit
		IF EXISTS (	SELECT 1 FROM #tmpCustList cl
					WHERE cl.SettingType NOT IN (7,8) AND cl.isLicensee=1
						AND NOT EXISTS (SELECT 1 FROM #returnTbl re 
										WHERE re.transid=cl.transid)
					)
		BEGIN
			INSERT INTO #returnTbl(custid, transid, SportType, BetType, MaxBet, MaxPerMatch)
			SELECT cl.custid, cl.transid, cl.SportType, cl.BetType, dcbs.MaxBet, dcbs.MaxPerMatch
			FROM #tmpCustList cl
				INNER JOIN Dep_CustBetSetting_Member dcbs WITH (NOLOCK) ON dcbs.CustID=cl.custid
																		AND dcbs.SportType=cl.SportTypeRef
																		AND dcbs.BetType=cl.BetTypeRef
			WHERE cl.SettingType NOT IN (7,8) AND cl.isLicensee=1
				AND NOT EXISTS (SELECT 1 FROM #returnTbl re 
								WHERE re.transid=cl.transid)
		END

		DELETE #tmpCustList WHERE SettingType NOT IN (7,8)
	END

	-- @sporttype: support StakeLevel - SettingType=7
	IF EXISTS (SELECT 1 FROM #tmpCustList WHERE SettingType=7)
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
		FROM #tmpCustList cl
			OUTER APPLY (SELECT TOP (1) ch. custid, OldMaxBet, OldStakeLevelList, UpdateTime 
						 FROM CustMaxBetSetting_History ch 
						 WHERE  ch.custid=cl.custid AND ch.SportType=cl.SportTypeRef
							AND ch.BetType=cl.BetTypeRef AND ch.UpdateTime>cl.transdate 
						 ORDER BY UpdateTime
						) ch
			OUTER APPLY (SELECT TOP (1) dch.custid, OldMaxBet, OldStakeLevelList, UpdateTime 
						 FROM Dep_CustMaxBetSetting_History dch 
						 WHERE dch.custid=cl.custid AND dch.SportType=cl.SportTypeRef
							AND dch.BetType=cl.BetTypeRef AND dch.UpdateTime>cl.transdate  
						 ORDER BY UpdateTime
						) dch
		WHERE cl.SettingType=7 AND
			(
			  (cl.isLicensee=0 AND ch.custid IS NOT NULL)
			OR 
			  (cl.isLicensee=1 AND dch.custid IS NOT NULL)
			)

		--flag isChangedGlobal???
		;WITH CustList_Global1 AS (--get StakeLevelList
			SELECT cl.custid, cl.transid, cl.SportType, cl.BetType
				, CASE	WHEN sma.transid IS NOT NULL  THEN sma.StakeLevelList
						WHEN cslm.CustID IS NOT NULL  THEN cslm.StakeLevelList
						WHEN dcslm.CustID IS NOT NULL THEN dcslm.StakeLevelList
					END	AS StakeLevelList
			FROM #tmpCustList cl
				LEFT JOIN CustStakeLevel_Member cslm WITH (NOLOCK)
						ON cslm.custid=cl.custid
						AND cslm.SportType=cl.SportTypeRef
						AND cslm.BetType=cl.BetTypeRef
				LEFT JOIN Dep_CustStakeLevel_Member dcslm WITH (NOLOCK)
						ON dcslm.custid=cl.custid
						AND dcslm.SportType=cl.SportTypeRef
						AND dcslm.BetType=cl.BetTypeRef
				LEFT JOIN #CustList_ChangedSMA sma ON sma.transid=cl.transid
			WHERE SettingType=7 AND 
				(cslm.CustID IS NOT NULL OR dcslm.CustID IS NOT NULL)
		),
		CustList_Global2 AS (--get isChangedGlobal, MaxStake_old
			SELECT clg.custid, clg.transid
				, CASE	WHEN cre.StakeLevelID IS NOT NULL THEN cre.UpdateTime
						WHEN dep.StakeLevelID IS NOT NULL THEN dep.UpdateTime
					END UpdateTime_Global
				, MAX(CASE	WHEN cre.StakeLevelID IS NOT NULL THEN cre.isChangedGlobal
							WHEN dep.StakeLevelID IS NOT NULL THEN dep.isChangedGlobal END) AS isChangedGlobal
				, MAX(CASE	WHEN cre.StakeLevelID IS NOT NULL	 THEN cre.MaxLabel
							WHEN dep.StakeLevelID IS NOT NULL	 THEN dep.MaxLabel
						END) AS MaxStake_old
			FROM CustList_Global1 clg
				INNER JOIN #tmpCustList cl ON cl.transid=clg.transid
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
				, CASE	WHEN cre.StakeLevelID IS NOT NULL THEN cre.UpdateTime
						WHEN dep.StakeLevelID IS NOT NULL THEN dep.UpdateTime
					END
		)
		INSERT INTO #returnTbl (custid, transid, SportType, BetType, MaxBet)
		SELECT cl.custid, cl.transid, cl.SportType, cl.BetType
			, CASE WHEN sma.UpdateTime_SMA IS NOT NULL AND gl.isChangedGlobal=0			THEN sma.MaxBet
				   WHEN sma.UpdateTime_SMA IS NULL										THEN gl.MaxStake_Old
				   WHEN sma.UpdateTime_SMA<gl.UpdateTime_Global	AND isChangedGlobal=1	THEN sma.MaxBet
				   WHEN sma.UpdateTime_SMA>gl.UpdateTime_Global							THEN gl.MaxStake_Old
			END MaxBet
		FROM #tmpCustList cl
			LEFT JOIN #CustList_ChangedSMA sma ON sma.transid=cl.transid
			LEFT JOIN CustList_Global2 gl ON gl.transid=cl.transid 
		WHERE SettingType=7 
			AND (sma.transid IS NOT NULL OR gl.transid IS NOT NULL)
			AND NOT EXISTS (SELECT 1 FROM #returnTbl re WHERE re.transid=cl.transid)

		DELETE #tmpCustList WHERE SettingType=7
		DELETE #CustList_ChangedSMA
	END

	-- @sporttype: support StakeLevel - SettingType=8
	IF EXISTS (SELECT 1 FROM #tmpCustList WHERE SettingType=8)
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
		FROM #tmpCustList cl
			OUTER APPLY (SELECT TOP (1) ch. custid, OldMaxBet, OldStakeLevelList, UpdateTime 
						 FROM CustMaxBetSetting_History ch 
						 WHERE  ch.custid=cl.custid AND ch.SportType=cl.SportTypeRef
							AND ch.BetType=cl.BetTypeRef AND ch.UpdateTime>cl.transdate 
						 ORDER BY UpdateTime
						) ch
			OUTER APPLY (SELECT TOP (1) dch.custid, OldMaxBet, OldStakeLevelList, UpdateTime 
						 FROM Dep_CustMaxBetSetting_History dch 
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

		--flag isChangedGlobal???
		;WITH CustList_Global1 AS (--get StakeLevelList
			SELECT cl.custid, cl.transid, cl.SportType, cl.BetType
				, CASE	WHEN sma.transid IS NOT NULL  THEN sma.StakeLevelList
						WHEN cslm.CustID IS NOT NULL  THEN cslm.StakeLevelList
						WHEN dcslm.CustID IS NOT NULL THEN dcslm.StakeLevelList
					END	AS StakeLevelList
			FROM #tmpCustList cl
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
				(cslm.CustID IS NOT NULL OR dcslm.CustID IS NOT NULL)
		),
		CustList_Global2 AS (--get isChangedGlobal, MaxStake_old
			SELECT clg.custid, clg.transid
				, CASE	WHEN stg.StakeLevelID IS NOT NULL THEN stg.UpdateTime
						WHEN dstg.StakeLevelID IS NOT NULL THEN dstg.UpdateTime
					END UpdateTime_Global
				, CASE WHEN stg.StakeLevelID IS NOT NULL OR dstg.StakeLevelID IS NOT NULL 
						THEN 1 ELSE 0 END AS isChangedGlobal
				, CASE	WHEN stg.StakeLevelID IS NOT NULL	 THEN stg.MaxGameStake
						WHEN dstg.StakeLevelID IS NOT NULL	 THEN dstg.MaxGameStake
						--current
						WHEN stgc.StakeLevelID IS NOT NULL	 THEN stgc.MaxGameStake
						WHEN dstgc.StakeLevelID IS NOT NULL THEN dstgc.MaxGameStake
					END AS MaxStake_old
			FROM CustList_Global1 clg
				INNER JOIN #tmpCustList cl ON cl.transid=clg.transid
				--Credit
				OUTER APPLY (SELECT TOP (1) StakeLevelID
										, CASE WHEN MaxGameStake IS NOT NULL THEN MaxGameStake ELSE CAST(MaxLabel AS MONEY) END MaxGameStake
										, UpdateTime 
							 FROM StakeLevelGroupDetail_History stg WITH (NOLOCK) 
							 WHERE stg.StakeLevelID = clg.StakeLevelList
								AND stg.GameTypeID=cl.BetType
								AND stg.UpdateTime>cl.transdate
							) stg
				--Deposit
				OUTER APPLY (SELECT TOP (1) StakeLevelID
										, CASE WHEN MaxGameStake IS NOT NULL THEN MaxGameStake ELSE CAST(MaxLabel AS MONEY) END MaxGameStake
										, UpdateTime 
							 FROM Dep_StakeLevelGroupDetail_History dstg WITH (NOLOCK) 
							 WHERE dstg.StakeLevelID = clg.StakeLevelList
								AND dstg.GameTypeID=cl.BetType
								AND dstg.UpdateTime>cl.transdate
								) dstg
				--current
				--Credit
				OUTER APPLY (SELECT TOP 1 stg.StakeLevelID
										, CASE WHEN MaxGameStake IS NOT NULL THEN MaxGameStake ELSE CAST(MaxLabel AS MONEY) END MaxGameStake
								FROM StakeLevelGroupDetail stg WITH (NOLOCK)
								WHERE stg.StakeLevelID = clg.StakeLevelList
									AND stg.GameTypeID=cl.BetType
								) stgc 
				--Deposit
				OUTER APPLY (SELECT TOP 1 dstg.StakeLevelID
										, CASE WHEN MaxGameStake IS NOT NULL THEN MaxGameStake ELSE CAST(MaxLabel AS MONEY) END MaxGameStake
								FROM Dep_StakeLevelGroupDetail dstg WITH (NOLOCK)
								WHERE dstg.StakeLevelID = clg.StakeLevelList
									AND dstg.GameTypeID=cl.BetType
								) dstgc
		)
		INSERT INTO #returnTbl (custid, transid, SportType, BetType, MaxBet)
		SELECT cl.custid, cl.transid, cl.SportType, cl.BetType
			, CASE WHEN sma.UpdateTime_SMA IS NOT NULL AND gl.UpdateTime_Global IS NULL	THEN sma.MaxBet
				   WHEN sma.UpdateTime_SMA IS NULL AND gl.UpdateTime_Global IS NOT NULL	THEN gl.MaxStake_Old
																						ELSE gl.MaxStake_Old
			END MaxBet
		FROM #tmpCustList cl
			LEFT JOIN #CustList_ChangedSMA sma ON sma.transid=cl.transid
			LEFT JOIN CustList_Global2 gl ON gl.transid=cl.transid 
		WHERE SettingType=8 
			AND (sma.transid IS NOT NULL OR gl.transid IS NOT NULL)
			AND NOT EXISTS (SELECT 1 FROM #returnTbl re WHERE re.transid=cl.transid)
	
		DELETE #tmpCustList WHERE SettingType=8
	END

	SELECT custid, transid, SportType
		, BetType, MaxBet, MaxPerMatch
	FROM #returnTbl
	
	DROP TABLE #tmpCustList
	DROP TABLE #CustList_ChangedSMA
	DROP TABLE #returnTbl
END
GO