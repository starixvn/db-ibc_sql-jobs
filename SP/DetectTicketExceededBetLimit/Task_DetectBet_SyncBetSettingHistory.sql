/*<info serverAlias="DBTP-bodb02" executers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Task_DetectBet_SyncBetSettingHistory] 
AS
/*
	Created: 20220512@Tacy
	Task : Sync history of bet setting from DBCUST.CustDB to DBTP.bodb02
	DB: DBTP/bodb02
	Original:

	Revisions:
		- 20220512@Tacy: Initial SP [RedmineID: #170739]

	Param's Explanation:

*/
BEGIN
	SET NOCOUNT ON

	DECLARE @UpdateTime DATETIME, 
			@rows		INT,
			@batch		INT = 5000,
			@StakeLevel_ID					INT=NULL,
			@StakeLevelGroupDetail_ID		INT=NULL,
			@Dep_StakeLevel_ID				INT=NULL,
			@Dep_StakeLevelGroupDetail_ID	INT=NULL,
			@CustMaxBetSetting_ID			INT=NULL,
			@Dep_CustMaxBetSetting_ID		INT=NULL

	SET @UpdateTime = GETDATE()

	CREATE TABLE #tmpBetSetting_History (
			CustID			INT
		,	SportType		SMALLINT
		,	BetType			INT
		,	OldMaxBet		MONEY
		,	OldMaxPerMatch	MONEY
		,	OldStakeLevelList VARCHAR(200)
		,	UpdateTime		DATETIME
	)

	CREATE TABLE #tmpStakeLevel_History (
			StakeLevelID	INT
		,	GameTypeID		INT
		,	MaxLabel		NVARCHAR(50)
		,	MaxStake		DECIMAL(19,8)
		,	MaxGameStake	DECIMAL(19,8)
		,	SiteID			INT
		,	UpdateTime		DATETIME
	)

	SET @CustMaxBetSetting_ID = (SELECT CAST(ConfigValue AS INT) FROM CustMaxBetSetting_Config WITH (NOLOCK) WHERE ConfigName='CustMaxBetSetting_ID')
	SET @Dep_CustMaxBetSetting_ID = (SELECT CAST(ConfigValue AS INT) FROM CustMaxBetSetting_Config WITH (NOLOCK) WHERE ConfigName='Dep_CustMaxBetSetting_ID')
	SET @StakeLevel_ID = (SELECT CAST(ConfigValue AS INT) FROM CustMaxBetSetting_Config WITH (NOLOCK) WHERE ConfigName='StakeLevel_ID')
	SET @StakeLevelGroupDetail_ID = (SELECT CAST(ConfigValue AS INT) FROM CustMaxBetSetting_Config WITH (NOLOCK) WHERE ConfigName='StakeLevelGroupDetail_ID')
	SET @Dep_StakeLevel_ID = (SELECT CAST(ConfigValue AS INT) FROM CustMaxBetSetting_Config WITH (NOLOCK) WHERE ConfigName='Dep_StakeLevel_ID')
	SET @Dep_StakeLevelGroupDetail_ID = (SELECT CAST(ConfigValue AS INT) FROM CustMaxBetSetting_Config WITH (NOLOCK) WHERE ConfigName='Dep_StakeLevelGroupDetail_ID')

	--History: SMA update member bet setting
	IF EXISTS (SELECT 1 FROM DBCUST.CustDB.dbo.CustMaxBetSetting_History)
	BEGIN
		SET @rows = (SELECT COUNT(1) FROM DBCUST.CustDB.dbo.CustMaxBetSetting_History WITH (NOLOCK))

		IF @rows<=@batch
		BEGIN
			INSERT INTO #tmpBetSetting_History (CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime)
			SELECT CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime
			FROM DBCUST.CustDB.dbo.CustMaxBetSetting_History WITH (NOLOCK)

			SET @CustMaxBetSetting_ID=(SELECT MAX(ID) FROM DBCUST.CustDB.dbo.CustMaxBetSetting_History WITH (NOLOCK))
		END
		ELSE
		BEGIN
			INSERT TOP (@batch) INTO #tmpBetSetting_History (CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime)
			SELECT CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime
			FROM DBCUST.CustDB.dbo.CustMaxBetSetting_History WITH (NOLOCK)
			WHERE ID BETWEEN @CustMaxBetSetting_ID AND (@CustMaxBetSetting_ID+@batch)

			SET @CustMaxBetSetting_ID=@CustMaxBetSetting_ID+@batch
		END

		INSERT INTO dbo.CustMaxBetSetting_History (CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime)
		SELECT CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime
		FROM #tmpBetSetting_History 

		--update ID:
		UPDATE conf
		SET ConfigValue=CAST(@CustMaxBetSetting_ID AS VARCHAR)
		FROM CustMaxBetSetting_Config AS conf WITH (ROWLOCK, UPDLOCK)
		WHERE ConfigName='CustMaxBetSetting_ID'

		TRUNCATE TABLE #tmpBetSetting_History
	END

	IF EXISTS (SELECT 1 FROM DBCUST.CustDB.dbo.Dep_CustMaxBetSetting_History)
	BEGIN
		SET @rows = (SELECT COUNT(1) FROM DBCUST.CustDB.dbo.Dep_CustMaxBetSetting_History WITH (NOLOCK))

		IF @rows<=@batch
		BEGIN
			INSERT INTO #tmpBetSetting_History (CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime)
			SELECT CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime
			FROM DBCUST.CustDB.dbo.Dep_CustMaxBetSetting_History WITH (NOLOCK)

			SET @Dep_CustMaxBetSetting_ID=(SELECT MAX(ID) FROM DBCUST.CustDB.dbo.Dep_CustMaxBetSetting_History WITH (NOLOCK))
		END
		ELSE
		BEGIN
			WHILE @rows>0
			BEGIN
				INSERT TOP (@batch) INTO #tmpBetSetting_History (CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime)
				SELECT CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime
				FROM DBCUST.CustDB.dbo.Dep_CustMaxBetSetting_History WITH (NOLOCK)
				WHERE ID BETWEEN @Dep_CustMaxBetSetting_ID AND (@Dep_CustMaxBetSetting_ID+@batch)

				SET @Dep_CustMaxBetSetting_ID=@Dep_CustMaxBetSetting_ID+@batch
			END 
		END

		INSERT INTO dbo.Dep_CustMaxBetSetting_History (CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime)
		SELECT CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime
		FROM #tmpBetSetting_History 

		--update ID:
		UPDATE conf
		SET ConfigValue=CAST(@Dep_CustMaxBetSetting_ID AS VARCHAR)
		FROM CustMaxBetSetting_Config AS conf WITH (ROWLOCK, UPDLOCK)
		WHERE ConfigName='Dep_CustMaxBetSetting_ID'

		TRUNCATE TABLE #tmpBetSetting_History
	END

	--History: update global bet setting
	IF EXISTS (SELECT 1 FROM DBCUST.CustDB.dbo.StakeLevel_History)
	BEGIN
		SET @rows=(SELECT COUNT(1) FROM DBCUST.CustDB.dbo.StakeLevel_History WITH (NOLOCK))

		IF @rows<=@batch
		BEGIN
			INSERT INTO #tmpStakeLevel_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, UpdateTime)
			SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, UpdateTime
			FROM DBCUST.CustDB.dbo.StakeLevel_History WITH (NOLOCK)

			SET @StakeLevel_ID=(SELECT MAX(ID) FROM DBCUST.CustDB.dbo.StakeLevel_History WITH (NOLOCK))
		END
		ELSE 
		BEGIN
			WHILE @rows>0
			BEGIN
				INSERT TOP (@batch) INTO #tmpStakeLevel_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, UpdateTime)
				SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, UpdateTime
				FROM DBCUST.CustDB.dbo.StakeLevel_History WITH (NOLOCK)
				WHERE ID BETWEEN @StakeLevel_ID AND (@StakeLevel_ID+@batch)

				SET @StakeLevel_ID=@StakeLevel_ID+@batch
			END
		END

		INSERT INTO dbo.StakeLevel_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, UpdateTime)
		SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, UpdateTime
		FROM #tmpStakeLevel_History

		--update ID:
		UPDATE conf
		SET ConfigValue=CAST(@StakeLevel_ID AS VARCHAR)
		FROM CustMaxBetSetting_Config AS conf WITH (ROWLOCK, UPDLOCK)
		WHERE ConfigName='StakeLevel_ID'

		TRUNCATE TABLE #tmpStakeLevel_History
	END

	IF EXISTS (SELECT 1 FROM DBCUST.CustDB.dbo.Dep_StakeLevel_History)
	BEGIN
		SET @rows=(SELECT COUNT(1) FROM DBCUST.CustDB.dbo.Dep_StakeLevel_History WITH (NOLOCK))

		IF @rows<=@batch
		BEGIN
			INSERT INTO #tmpStakeLevel_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, SiteID, UpdateTime)
			SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, SiteID, UpdateTime
			FROM DBCUST.CustDB.dbo.Dep_StakeLevel_History WITH (NOLOCK)

			SET @Dep_StakeLevel_ID=(SELECT MAX(ID) FROM DBCUST.CustDB.dbo.Dep_StakeLevel_History WITH (NOLOCK))
		END
		ELSE
		BEGIN
			INSERT TOP (@batch) INTO #tmpStakeLevel_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, SiteID, UpdateTime)
			SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, SiteID, UpdateTime
			FROM DBCUST.CustDB.dbo.Dep_StakeLevel_History WITH (NOLOCK)
			WHERE ID BETWEEN @Dep_StakeLevel_ID AND (@Dep_StakeLevel_ID+@batch)

			SET @Dep_StakeLevel_ID=@Dep_StakeLevel_ID+@batch
		END

		INSERT INTO dbo.Dep_StakeLevel_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, SiteID, UpdateTime)
		SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, SiteID, UpdateTime
		FROM #tmpStakeLevel_History
		
		--update ID:
		UPDATE conf
		SET ConfigValue=CAST(@Dep_StakeLevel_ID AS VARCHAR)
		FROM CustMaxBetSetting_Config AS conf WITH (ROWLOCK, UPDLOCK)
		WHERE ConfigName='Dep_StakeLevel_ID'

		TRUNCATE TABLE #tmpStakeLevel_History
	END

	----------------------------------------------------------------------------------------------------------
	IF EXISTS (SELECT 1 FROM DBCUST.CustDB.dbo.StakeLevelGroupDetail_History)
	BEGIN
		SET @rows=(SELECT COUNT(1) FROM DBCUST.CustDB.dbo.StakeLevelGroupDetail_History WITH (NOLOCK))

		IF @rows<=@batch
		BEGIN
			INSERT INTO #tmpStakeLevel_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime)
			SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime
			FROM DBCUST.CustDB.dbo.StakeLevelGroupDetail_History WITH (NOLOCK)

			SET @StakeLevelGroupDetail_ID=(SELECT MAX(ID) FROM DBCUST.CustDB.dbo.StakeLevelGroupDetail_History WITH (NOLOCK))
		END
		ELSE
		BEGIN
			INSERT TOP (@batch) INTO #tmpStakeLevel_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime)
			SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime
			FROM DBCUST.CustDB.dbo.StakeLevelGroupDetail_History WITH (NOLOCK)
			WHERE ID BETWEEN @StakeLevelGroupDetail_ID AND (@StakeLevelGroupDetail_ID+@batch)

			SET @StakeLevelGroupDetail_ID=@StakeLevelGroupDetail_ID+@batch
		END

		INSERT INTO dbo.StakeLevelGroupDetail_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime)
		SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake , UpdateTime
		FROM #tmpStakeLevel_History

		--update ID:
		UPDATE conf
		SET ConfigValue=CAST(@StakeLevelGroupDetail_ID AS VARCHAR)
		FROM CustMaxBetSetting_Config AS conf WITH (ROWLOCK, UPDLOCK)
		WHERE ConfigName='StakeLevelGroupDetail_ID'

		TRUNCATE TABLE #tmpStakeLevel_History
	END


	IF EXISTS (SELECT 1 FROM DBCUST.CustDB.dbo.Dep_StakeLevelGroupDetail_History)
	BEGIN
		SET @rows=(SELECT COUNT(1) FROM DBCUST.CustDB.dbo.Dep_StakeLevelGroupDetail_History WITH (NOLOCK))

		IF @rows<=@batch
		BEGIN
			INSERT INTO #tmpStakeLevel_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime)
			SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime
			FROM DBCUST.CustDB.dbo.Dep_StakeLevelGroupDetail_History WITH (NOLOCK)

			SET @Dep_StakeLevelGroupDetail_ID=(SELECT MAX(ID) FROM DBCUST.CustDB.dbo.Dep_StakeLevelGroupDetail_History WITH (NOLOCK))
		END
		ELSE
		BEGIN
			INSERT TOP (@batch) INTO #tmpStakeLevel_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime)
			SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime
			FROM DBCUST.CustDB.dbo.Dep_StakeLevelGroupDetail_History WITH (NOLOCK)
			WHERE ID BETWEEN @Dep_StakeLevelGroupDetail_ID AND (@Dep_StakeLevelGroupDetail_ID+@batch)
				
			SET @Dep_StakeLevelGroupDetail_ID=@Dep_StakeLevelGroupDetail_ID+@batch
		END

		INSERT INTO dbo.Dep_StakeLevelGroupDetail_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime)
		SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime
		FROM #tmpStakeLevel_History

		--update ID:
		UPDATE conf
		SET ConfigValue=CAST(@Dep_StakeLevelGroupDetail_ID AS VARCHAR)
		FROM CustMaxBetSetting_Config AS conf WITH (ROWLOCK, UPDLOCK)
		WHERE ConfigName='Dep_StakeLevelGroupDetail_ID'

		TRUNCATE TABLE #tmpStakeLevel_History
	END

	--update ConfigValue
	UPDATE conf
	SET ConfigValue=CONVERT(VARCHAR, @UpdateTime, 121)
	FROM CustMaxBetSetting_Config AS conf WITH (ROWLOCK, UPDLOCK)
	WHERE ConfigName='SyncHistoryDataLastTime'

	--Delete data - DBCUST.CustDB
	EXEC DBCUST.CustDB.dbo.Task_DetectBet_DelBetSettingHistory
		@StakeLevel_ID					= @StakeLevel_ID,
		@StakeLevelGroupDetail_ID		= @StakeLevelGroupDetail_ID,
		@Dep_StakeLevel_ID				= @Dep_StakeLevel_ID, 
		@Dep_StakeLevelGroupDetail_ID	= @Dep_StakeLevelGroupDetail_ID,
		@CustMaxBetSetting_ID			= @CustMaxBetSetting_ID,
		@Dep_CustMaxBetSetting_ID		= @Dep_CustMaxBetSetting_ID


	DROP TABLE #tmpBetSetting_History
	DROP TABLE #tmpStakeLevel_History
END
GO