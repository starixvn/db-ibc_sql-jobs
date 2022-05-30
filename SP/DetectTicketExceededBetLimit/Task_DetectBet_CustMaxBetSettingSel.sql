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

	CREATE TABLE #tmpCustList (
			custid		INT
		,	SportType	SMALLINT
		,	BetType		INT
		,	transid		BIGINT
		,	transdate	DATETIME
		,	isLicensee	BIT
		,	isSupportStakeLvl BIT
		,	PRIMARY KEY CLUSTERED (transid)
	)

	CREATE TABLE #RefBetSettingTbl (
			custid					INT
		,	SportType				SMALLINT
		,	BetType					INT
		,	SportTypeRef			SMALLINT
		,	BetTypeRef				INT
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
		,	UpdateTime_SMA			DATETIME
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
		,	MaxStake_Old			MONEY
		,	IsChangedGlobal			BIT
		,	UpdateTime_Global		DATETIME
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
	INSERT INTO #RefBetSettingTbl (custid, SportType, BetType, SportTypeRef, BetTypeRef,TableBetSetting)
	SELECT DISTINCT 
		  cl.custid
		, cl.SportType
		, cl.BetType
		, ref.SportTypeRefBetSetting	AS SportTypeRef
		, ref.BetTypeRefBetSetting		AS BetTypeRef
		, ref.TableBetSetting
	FROM #tmpCustList cl
		LEFT JOIN dbacc.bodb02.dbo.Sport_Bettype_Reference_Setting ref WITH (NOLOCK)
			ON	ref.Sporttype	= cl.sporttype 
			AND ref.Bettype		= cl.bettype
			AND ref.isLicensee	= cl.isLicensee

	--Update isSupportStakeLvl
	UPDATE cl
	SET isSupportStakeLvl = CASE WHEN TableBetSetting NOT IN ('CustStakeLevel_Member','Dep_custStakeLevel_member') THEN 0 
								 WHEN TableBetSetting IN ('CustStakeLevel_Member','Dep_custStakeLevel_member') THEN 1 
							END
	FROM #tmpCustList cl
		INNER JOIN #RefBetSettingTbl ref ON cl.CustID=ref.CustID
										AND cl.SportType=ref.SportType
										AND cl.BetType=ref.BetType

	-- @sporttype: not support StakeLevel
	IF EXISTS (SELECT 1 FROM #tmpCustList WHERE isSupportStakeLvl=0)
	BEGIN
		INSERT INTO #returnTbl(custid, transid, SportType, BetType, MaxBet, MaxPerMatch, StakeLevelList)
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
		WHERE cl.isSupportStakeLvl=0 AND
			(
			  (cl.isLicensee=0 AND ch.custid IS NOT NULL)
			OR 
			  (cl.isLicensee=1 AND dch.custid IS NOT NULL)
			)

		--Current Maxbet
		IF EXISTS (	SELECT 1 FROM #tmpCustList cl
					WHERE cl.isSupportStakeLvl=0
						AND NOT EXISTS (SELECT 1 FROM #returnTbl re 
										WHERE re.transid=cl.transid)
					)
		BEGIN
			WHILE 1=1
			BEGIN 
				SELECT TOP 1 @TableBetSetting=TableBetSetting
				FROM #tmpCustList cl
				INNER JOIN #RefBetSettingTbl ref ON ref.custid=cl.custid 
												AND ref.BetType=cl.BetType
												AND ref.SportType=cl.SportType
				WHERE cl.isSupportStakeLvl=0
					AND NOT EXISTS (SELECT 1 FROM #returnTbl re 
									WHERE re.transid=cl.transid)

				IF @@ROWCOUNT = 0	
					BREAK;
			
				SET @SQL = 'SELECT bs.custid, cl.transid, bs.SportType
								, bs.BetType, bs.MaxBet
								, bs.MaxPerMatch
							FROM DBCust.CustDB.dbo.[' + @TableBetSetting + '] bs WITH (NOLOCK)
							CROSS APPLY (SELECT transid
										 FROM #tmpCustList cl 
											INNER JOIN #RefBetSettingTbl ref ON ref.custid=cl.custid 
																			AND ref.BetType=cl.BetType
																			AND ref.SportType=cl.SportType
										 WHERE	cl.custid		= bs.custid
											AND cl.SportType	= bs.SportType
											AND cl.BetType		= bs.BetType
											AND TableBetSetting	= @TableBetSetting) cl'
			
				INSERT INTO #returnTbl (custid, transid, SportType, BetType, MaxBet, MaxPerMatch)
				EXECUTE sys.sp_executesql @SQL, N'@TableBetSetting	VARCHAR(50)', @TableBetSetting

				DELETE cl
				FROM #tmpCustList cl
					INNER JOIN #RefBetSettingTbl ref
								ON	ref.custid=cl.custid
								AND ref.SportType=cl.SportType
								AND ref.BetType=cl.BetType
				WHERE TableBetSetting=@TableBetSetting
				 AND cl.isSupportStakeLvl=0
			END

			DELETE #tmpCustList WHERE isSupportStakeLvl=0
		END
	END
	-- @sporttype: support StakeLevel
	IF EXISTS (SELECT 1 FROM #tmpCustList WHERE isSupportStakeLvl=1)
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
						 WHERE  ch.custid=cl.custid AND ch.SportType=cl.SportType
							AND ch.BetType=cl.BetType AND ch.UpdateTime>cl.transdate 
						 ) ch
			OUTER APPLY (SELECT TOP (1) dch.custid, OldMaxBet, OldStakeLevelList, UpdateTime 
						 FROM Dep_CustMaxBetSetting_History dch 
						 WHERE dch.custid=cl.custid AND dch.SportType=cl.SportType
							AND dch.BetType=cl.BetType AND dch.UpdateTime>cl.transdate  
						 ) dch
		WHERE cl.isSupportStakeLvl=1 AND
			(
			  (cl.isLicensee=0 AND ch.custid IS NOT NULL)
			OR 
			  (cl.isLicensee=1 AND dch.custid IS NOT NULL)
			)
		
		--Is changed global?
		;WITH CustList_Global1 AS (--get StakeLevelList
			SELECT cl.custid, cl.transid, cl.SportType, cl.BetType
				, CASE	WHEN sma.transid IS NOT NULL  THEN sma.StakeLevelList
						WHEN cslm.CustID IS NOT NULL  THEN cslm.StakeLevelList
						WHEN dcslm.CustID IS NOT NULL THEN dcslm.StakeLevelList
					END	AS StakeLevelList
			FROM #tmpCustList cl
				INNER JOIN #RefBetSettingTbl ref 
						ON ref.custid=cl.custid
						AND ref.SportType=cl.SportType
						AND ref.BetType=cl.BetType
				LEFT JOIN DBCust.CustDB.dbo.CustStakeLevel_Member cslm WITH (NOLOCK)
						ON cslm.custid=ref.custid
						AND cslm.SportType=ref.SportTypeRef
						AND cslm.BetType=ref.BetTypeRef
				LEFT JOIN DBCust.CustDB.dbo.Dep_CustStakeLevel_Member dcslm WITH (NOLOCK)
						ON dcslm.custid=ref.custid
						AND dcslm.SportType=ref.SportTypeRef
						AND dcslm.BetType=ref.BetTypeRef
				LEFT JOIN #CustList_ChangedSMA sma ON sma.transid=cl.transid
			WHERE isSupportStakeLvl=1 AND 
					(cslm.CustID IS NOT NULL OR dcslm.CustID IS NOT NULL)
		),
		CustList_Global2 AS (
			SELECT clg.custid, clg.transid
				, CASE	WHEN st.StakeLevelID IS NOT NULL THEN st.UpdateTime
						WHEN dst.StakeLevelID IS NOT NULL THEN dst.UpdateTime
						WHEN stg.StakeLevelID IS NOT NULL THEN stg.UpdateTime
						WHEN dstg.StakeLevelID IS NOT NULL THEN dstg.UpdateTime
					END UpdateTime
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
						END) AS MaxStake_old
			FROM CustList_Global1 clg
				INNER JOIN #tmpCustList cl ON cl.transid=clg.transid
				OUTER APPLY (SELECT RTRIM(LTRIM(value)) AS val FROM STRING_SPLIT(clg.StakeLevelList,',')) ss
				--Credit
				OUTER APPLY (SELECT TOP (1) StakeLevelID, MaxLabel, UpdateTime FROM StakeLevel_History st WITH (NOLOCK) 
							 WHERE st.StakeLevelID = CAST(ss.val AS INT)
								AND st.UpdateTime>cl.transdate
							) st
				OUTER APPLY (SELECT TOP (1) StakeLevelID
										, CASE WHEN MaxGameStake IS NOT NULL THEN MaxGameStake ELSE CAST(MaxLabel AS MONEY) END MaxGameStake
										, UpdateTime 
							 FROM StakeLevelGroupDetail_History stg WITH (NOLOCK) 
							 WHERE stg.StakeLevelID = CAST(ss.val AS INT)
								AND stg.GameTypeID=cl.BetType
								AND stg.UpdateTime>cl.transdate
							) stg
				--Deposit
				OUTER APPLY (SELECT TOP (1) StakeLevelID, MaxLabel, UpdateTime FROM Dep_StakeLevel_History dst WITH (NOLOCK) 
							 WHERE dst.StakeLevelID = CAST(ss.val AS INT)
								AND dst.UpdateTime>cl.transdate
							) dst
				OUTER APPLY (SELECT TOP (1) StakeLevelID
										, CASE WHEN MaxGameStake IS NOT NULL THEN MaxGameStake ELSE CAST(MaxLabel AS MONEY) END MaxGameStake
										, UpdateTime 
							 FROM Dep_StakeLevelGroupDetail_History dstg WITH (NOLOCK) 
							 WHERE dstg.StakeLevelID = CAST(ss.val AS INT)
								AND dstg.GameTypeID=cl.BetType
								AND dstg.UpdateTime>cl.transdate
								) dstg
			GROUP BY clg.custid, clg.transid
				, CASE	WHEN st.StakeLevelID IS NOT NULL THEN st.UpdateTime
					WHEN dst.StakeLevelID IS NOT NULL THEN dst.UpdateTime
					WHEN stg.StakeLevelID IS NOT NULL THEN stg.UpdateTime
					WHEN dstg.StakeLevelID IS NOT NULL THEN dstg.UpdateTime
				END
		)
		INSERT INTO #CustList_ChangedGlobal (custid, transid, SportType, BetType, StakeLevelList, StakeLevelID_Changed, MaxStake_Old, IsChangedGlobal, UpdateTime_Global)
		SELECT clg1.custid, clg1.transid, clg1.SportType, clg1.BetType, clg1.StakeLevelList
			, clg2.StakeLevelID_Changed, clg2.MaxStake_old, clg2.isChangedGlobal, clg2.UpdateTime
		FROM CustList_Global1 clg1 
			INNER JOIN CustList_Global2 clg2 ON clg2.transid=clg1.transid

		----
		;WITH tmpCustList1 AS (
			SELECT gl.transid, gl.StakeLevelList
				, MAX(CASE WHEN cl.isLicensee=0	
						THEN (CASE WHEN st.GameGroupID=0 THEN CAST(st.MaxLabel AS MONEY) ELSE stg.MaxGameStake END)
						ELSE (CASE WHEN dst.GameGroupID=0 THEN CAST(dst.MaxLabel AS MONEY) ELSE dstg.MaxGameStake END)
				END) AS MaxStake
			FROM #CustList_ChangedGlobal gl
				INNER JOIN #tmpCustList cl ON gl.transid=cl.transid
				CROSS APPLY (SELECT CAST(value AS INT) StakeLevelList_Value FROM STRING_SPLIT(gl.StakeLevelList,',')) ss
				--Credit
				LEFT JOIN DBCust.CustDB.dbo.StakeLevel st WITH (NOLOCK) ON st.StakeLevelID = ss.StakeLevelList_Value
				OUTER APPLY (SELECT TOP 1 stg.StakeLevelID
										, CASE WHEN MaxGameStake IS NOT NULL THEN MaxGameStake ELSE CAST(MaxLabel AS MONEY) END MaxGameStake
								FROM DBCust.CustDB.dbo.StakeLevelGroupDetail stg WITH (NOLOCK)
								WHERE stg.StakeLevelID = st.StakeLevelID
									AND stg.GameTypeID=cl.BetType
								) stg 
				--Deposit
				LEFT JOIN DBCust.CustDB.dbo.Dep_StakeLevel dst WITH (NOLOCK) ON dst.StakeLevelID = ss.StakeLevelList_Value
				OUTER APPLY (SELECT TOP 1 dstg.StakeLevelID
										, CASE WHEN MaxGameStake IS NOT NULL THEN MaxGameStake ELSE CAST(MaxLabel AS MONEY) END MaxGameStake
								FROM DBCust.CustDB.dbo.Dep_StakeLevelGroupDetail dstg WITH (NOLOCK)
								WHERE dstg.StakeLevelID = dst.StakeLevelID
									AND dstg.GameTypeID=cl.BetType
								) dstg 
			WHERE gl.IsChangedGlobal=0 AND
				(
				  (cl.isLicensee=0 AND st.StakeLevelID IS NOT NULL)
				OR 
				  (cl.isLicensee=1 AND dst.StakeLevelID IS NOT NULL)
				)
			GROUP BY gl.transid, gl.StakeLevelList
		)
		INSERT INTO #returnTbl (custid, transid, SportType, BetType, MaxBet, StakeLevelList)
		SELECT gl.custid, gl.transid, gl.SportType, gl.BetType, t.MaxStake, t.StakeLevelList
		FROM #CustList_ChangedGlobal gl
			 INNER JOIN tmpCustList1 t ON gl.transid=t.transid

		;WITH tmpMaxBet1 AS (--exclude StakeLevelID is changed [stakelevelList: ',']
			SELECT gl.transid
				, MAX(CASE WHEN cl.isLicensee=0	
						THEN (CASE WHEN st.GameGroupID=0 THEN CAST(st.MaxLabel AS MONEY) ELSE stg.MaxGameStake END)
						ELSE (CASE WHEN dst.GameGroupID=0 THEN CAST(dst.MaxLabel AS MONEY) ELSE dstg.MaxGameStake END)
					END) AS MaxStake
			FROM #CustList_ChangedGlobal gl
				INNER JOIN #tmpCustList cl ON cl.transid=gl.transid
				INNER JOIN #CustList_ChangedSMA sma ON sma.transid=gl.transid
				CROSS APPLY (SELECT value AS val FROM STRING_SPLIT(sma.StakeLevelList,',')) ss
				--Credit
				LEFT JOIN StakeLevel st ON st.StakeLevelID=CAST(ss.val AS INT)
				OUTER APPLY (SELECT TOP 1 stg.StakeLevelID
									, CASE WHEN MaxGameStake IS NOT NULL THEN MaxGameStake ELSE CAST(MaxLabel AS MONEY) END MaxGameStake
							 FROM StakeLevelGroupDetail stg WITH (NOLOCK)
							 WHERE stg.StakeLevelID = st.StakeLevelID
								AND stg.GameTypeID=cl.BetType
							) stg
				--Deposit
				LEFT JOIN Dep_StakeLevel dst ON dst.StakeLevelID=CAST(ss.val AS INT)
				OUTER APPLY (SELECT TOP 1 stg.StakeLevelID
									, CASE WHEN MaxGameStake IS NOT NULL THEN MaxGameStake ELSE CAST(MaxLabel AS MONEY) END MaxGameStake
							 FROM Dep_StakeLevelGroupDetail dstg WITH (NOLOCK)
							 WHERE dstg.StakeLevelID = dst.StakeLevelID
								AND dstg.GameTypeID=cl.BetType
							) dstg
			WHERE gl.IsChangedGlobal=1
				AND gl.UpdateTime_Global<sma.UpdateTime_SMA AND CHARINDEX(sma.StakeLevelList, ',')=1
				AND ((st.StakeLevelID IS NOT NULL AND st.StakeLevelID<>gl.StakeLevelID_Changed)
					OR (dst.StakeLevelID IS NOT NULL AND dst.StakeLevelID<>gl.StakeLevelID_Changed))
			GROUP BY gl.transid
		),
		tmpMaxBet2 AS (
			SELECT gl.transid
				, CASE WHEN gl.MaxStake_Old>t.MaxStake THEN gl.MaxStake_Old ELSE t.MaxStake END MaxStake
			FROM #CustList_ChangedGlobal gl
				INNER JOIN tmpMaxBet1 t ON t.transid=gl.transid 
		)
		INSERT INTO #returnTbl (custid, transid, SportType, BetType, MaxBet, StakeLevelList)
		SELECT cl.custid, cl.transid, cl.SportType, cl.BetType
			, CASE WHEN sma.transid IS NOT NULL AND gl.transid IS NULL	THEN sma.MaxBet
				   WHEN sma.transid IS NULL AND gl.transid IS NOT NULL	THEN gl.MaxStake_Old
				   WHEN sma.UpdateTime_SMA<gl.UpdateTime_Global			THEN sma.MaxBet 
				   ELSE
						CASE WHEN CHARINDEX(sma.StakeLevelList,',')=0	
							THEN gl.MaxStake_Old
							ELSE t.MaxStake
						END
			END MaxBet
			, CASE WHEN sma.transid IS NOT NULL THEN sma.StakeLevelList ELSE gl.StakeLevelID_Changed 
			END StakeLevelList
		FROM #tmpCustList cl
			LEFT JOIN #CustList_ChangedSMA sma ON sma.transid=cl.transid
			LEFT JOIN #CustList_ChangedGlobal gl ON gl.transid=cl.transid AND gl.IsChangedGlobal=1.
			LEFT JOIN tmpMaxBet2 t ON  t.transid=cl.transid
		WHERE isSupportStakeLvl=1 AND
			(sma.transid IS NOT NULL OR gl.transid IS NOT NULL OR t.transid IS NOT NULL)
		AND NOT EXISTS (SELECT 1 FROM #returnTbl re WHERE re.transid=cl.transid)
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