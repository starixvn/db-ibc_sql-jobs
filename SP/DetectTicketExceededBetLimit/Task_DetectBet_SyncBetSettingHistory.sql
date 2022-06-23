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
			@ID			INT,
			@ID_max		INT,
			@rows		INT,
			@batch		INT = 5000

	SET @UpdateTime = GETDATE()

	CREATE TABLE #tmpBetSetting_History (
			ID				INT
		,	CustID			INT
		,	SportType		SMALLINT
		,	BetType			INT
		,	OldMaxBet		MONEY
		,	OldMaxPerMatch	MONEY
		,	OldStakeLevelList VARCHAR(200)
		,	UpdateTime		DATETIME
	)

	CREATE TABLE #tmpStakeLevel_History (
			ID				INT
		,	StakeLevelID	INT
		,	GameTypeID		INT
		,	MaxLabel		NVARCHAR(50)
		,	MaxStake		DECIMAL(19,8)
		,	MaxGameStake	DECIMAL(19,8)
		,	SiteID			INT
		,	UpdateTime		DATETIME
	)

	--History: SMA update member bet setting
	IF EXISTS (SELECT 1 FROM DBCUST.CustDB.dbo.CustMaxBetSetting_History)
	BEGIN
		SET @ID = (SELECT CAST(ConfigValue AS INT) FROM CustMaxBetSetting_Config WITH (NOLOCK) WHERE ConfigName='CustMaxBetSetting_ID')
		
		SELECT @rows=COUNT(1), @ID_max=MAX(ID) 
		FROM DBCUST.CustDB.dbo.CustMaxBetSetting_History WITH (NOLOCK) 

		IF @rows<=@batch
		BEGIN
			INSERT INTO #tmpBetSetting_History (CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime)
			SELECT CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime
			FROM DBCUST.CustDB.dbo.CustMaxBetSetting_History WITH (NOLOCK)
			
			INSERT INTO dbo.CustMaxBetSetting_History (CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime)
			SELECT CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime
			FROM #tmpBetSetting_History 
		END
		ELSE
		BEGIN
			WHILE @rows>0
			BEGIN 
				INSERT TOP (@batch) INTO #tmpBetSetting_History (ID, CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime)
				SELECT ID, CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime
				FROM DBCUST.CustDB.dbo.CustMaxBetSetting_History WITH (NOLOCK)
				WHERE ID BETWEEN @ID AND (@ID+@batch)

				INSERT INTO dbo.CustMaxBetSetting_History (CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime)
				SELECT CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime
				FROM #tmpBetSetting_History 
				WHERE ID BETWEEN @ID AND (@ID+@batch)

				SET @rows=@rows-@batch
				SET @ID=@ID+@batch
			END
		END

		EXEC DBCUST.CustDB.dbo.Task_DetectBet_DelBetSettingHistory @ID=@ID_max, @IsLicensee=0

		--update ID:
		UPDATE conf
		SET ConfigValue=CAST(@ID_max AS VARCHAR)
		FROM CustMaxBetSetting_Config AS conf WITH (ROWLOCK, UPDLOCK)
		WHERE ConfigName='CustMaxBetSetting_ID'

		TRUNCATE TABLE #tmpBetSetting_History
	END

	IF EXISTS (SELECT 1 FROM DBCUST.CustDB.dbo.Dep_CustMaxBetSetting_History)
	BEGIN
		SET @ID = (SELECT CAST(ConfigValue AS INT) FROM CustMaxBetSetting_Config WITH (NOLOCK) WHERE ConfigName='Dep_CustMaxBetSetting_ID')
		
		SELECT @rows=COUNT(1), @ID_max=MAX(ID) 
		FROM DBCUST.CustDB.dbo.Dep_CustMaxBetSetting_History WITH (NOLOCK) 

		IF @rows<=@batch
		BEGIN
			INSERT INTO #tmpBetSetting_History (CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime)
			SELECT CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime
			FROM DBCUST.CustDB.dbo.Dep_CustMaxBetSetting_History WITH (NOLOCK)

			INSERT INTO dbo.Dep_CustMaxBetSetting_History (CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime)
			SELECT CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime
			FROM #tmpBetSetting_History 
		END
		ELSE
		BEGIN
			WHILE @rows>0
			BEGIN
				INSERT TOP (@batch) INTO #tmpBetSetting_History (CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime)
				SELECT CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime
				FROM DBCUST.CustDB.dbo.Dep_CustMaxBetSetting_History WITH (NOLOCK)
				WHERE ID BETWEEN @ID AND (@ID+@batch)

				INSERT INTO dbo.Dep_CustMaxBetSetting_History (CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime)
				SELECT CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime
				FROM #tmpBetSetting_History 
				WHERE ID BETWEEN @ID AND (@ID+@batch)

				SET @rows=@rows-@batch
				SET @ID=@ID+@batch
			END 
		END

		EXEC DBCUST.CustDB.dbo.Task_DetectBet_DelBetSettingHistory @ID=@ID_max, @IsLicensee=1
		
		--update ID:
		UPDATE conf
		SET ConfigValue=CAST(@ID_max AS VARCHAR)
		FROM CustMaxBetSetting_Config AS conf WITH (ROWLOCK, UPDLOCK)
		WHERE ConfigName='Dep_CustMaxBetSetting_ID'

		TRUNCATE TABLE #tmpBetSetting_History
	END

	--History: update global bet setting
	IF EXISTS (SELECT 1 FROM DBCUST.CustDB.dbo.StakeLevel_History)
	BEGIN
		SET @ID = (SELECT CAST(ConfigValue AS INT) FROM CustMaxBetSetting_Config WITH (NOLOCK) WHERE ConfigName='StakeLevel_ID')
		
		SELECT @rows=COUNT(1), @ID_max=MAX(ID) 
		FROM DBCUST.CustDB.dbo.StakeLevel_History WITH (NOLOCK) 

		IF @rows<=@batch
		BEGIN
			INSERT INTO #tmpStakeLevel_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, UpdateTime)
			SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, UpdateTime
			FROM DBCUST.CustDB.dbo.StakeLevel_History WITH (NOLOCK)

			INSERT INTO dbo.StakeLevel_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, UpdateTime)
			SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, UpdateTime
			FROM #tmpStakeLevel_History
		END
		ELSE 
		BEGIN
			WHILE @rows>0
			BEGIN
				INSERT TOP (@batch) INTO #tmpStakeLevel_History (ID, StakeLevelID, GameTypeID, MaxLabel, MaxStake, UpdateTime)
				SELECT ID, StakeLevelID, GameTypeID, MaxLabel, MaxStake, UpdateTime
				FROM DBCUST.CustDB.dbo.StakeLevel_History WITH (NOLOCK)
				WHERE ID BETWEEN @ID AND (@ID+@batch)

				INSERT INTO dbo.StakeLevel_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, UpdateTime)
				SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, UpdateTime
				FROM #tmpStakeLevel_History
				WHERE ID BETWEEN @ID AND (@ID+@batch)

				SET @rows=@rows-@batch
				SET @ID=@ID+@batch
			END
		END

		EXEC DBCUST.CustDB.dbo.Task_DetectBet_DelBetSettingHistory @ID=@ID_max, @IsLicensee=0, @IsGroup=0

		--update ID:
		UPDATE conf
		SET ConfigValue=CAST(@ID_max AS VARCHAR)
		FROM CustMaxBetSetting_Config AS conf WITH (ROWLOCK, UPDLOCK)
		WHERE ConfigName='StakeLevel_ID'

		TRUNCATE TABLE #tmpStakeLevel_History
	END

	IF EXISTS (SELECT 1 FROM DBCUST.CustDB.dbo.Dep_StakeLevel_History)
	BEGIN
		SET @ID = (SELECT CAST(ConfigValue AS INT) FROM CustMaxBetSetting_Config WITH (NOLOCK) WHERE ConfigName='Dep_StakeLevel_ID')
		
		SELECT @rows=COUNT(1), @ID_max=MAX(ID) 
		FROM DBCUST.CustDB.dbo.Dep_StakeLevel_History WITH (NOLOCK) 

		IF @rows<=@batch
		BEGIN
			INSERT INTO #tmpStakeLevel_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, SiteID, UpdateTime)
			SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, SiteID, UpdateTime
			FROM DBCUST.CustDB.dbo.Dep_StakeLevel_History WITH (NOLOCK)

			INSERT INTO dbo.Dep_StakeLevel_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, SiteID, UpdateTime)
			SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, SiteID, UpdateTime
			FROM #tmpStakeLevel_History
		END
		ELSE
		BEGIN
			WHILE @rows>0
			BEGIN
				INSERT TOP (@batch) INTO #tmpStakeLevel_History (ID, StakeLevelID, GameTypeID, MaxLabel, MaxStake, SiteID, UpdateTime)
				SELECT ID, StakeLevelID, GameTypeID, MaxLabel, MaxStake, SiteID, UpdateTime
				FROM DBCUST.CustDB.dbo.Dep_StakeLevel_History WITH (NOLOCK)
				WHERE ID BETWEEN @ID AND (@ID+@batch)

				INSERT INTO dbo.Dep_StakeLevel_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, SiteID, UpdateTime)
				SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, SiteID, UpdateTime
				FROM #tmpStakeLevel_History
				WHERE ID BETWEEN @ID AND (@ID+@batch)

				SET @rows=@rows-@batch
				SET @ID=@ID+@batch
			END
		END

		EXEC DBCUST.CustDB.dbo.Task_DetectBet_DelBetSettingHistory @ID=@ID_max, @IsLicensee=0, @IsGroup=1
		
		--update ID:
		UPDATE conf
		SET ConfigValue=CAST(@ID_max AS VARCHAR)
		FROM CustMaxBetSetting_Config AS conf WITH (ROWLOCK, UPDLOCK)
		WHERE ConfigName='Dep_StakeLevel_ID'

		TRUNCATE TABLE #tmpStakeLevel_History
	END

	----------------------------------------------------------------------------------------------------------
	IF EXISTS (SELECT 1 FROM DBCUST.CustDB.dbo.StakeLevelGroupDetail_History)
	BEGIN
		SET @ID = (SELECT CAST(ConfigValue AS INT) FROM CustMaxBetSetting_Config WITH (NOLOCK) WHERE ConfigName='StakeLevelGroupDetail_ID')
		
		SELECT @rows=COUNT(1), @ID_max=MAX(ID) 
		FROM DBCUST.CustDB.dbo.StakeLevelGroupDetail_History WITH (NOLOCK) 

		IF @rows<=@batch
		BEGIN
			INSERT INTO #tmpStakeLevel_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime)
			SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime
			FROM DBCUST.CustDB.dbo.StakeLevelGroupDetail_History WITH (NOLOCK)

			INSERT INTO dbo.StakeLevelGroupDetail_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime)
			SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake , UpdateTime
			FROM #tmpStakeLevel_History
		END
		ELSE
		BEGIN
			WHILE @rows>0
			BEGIN
				INSERT TOP (@batch) INTO #tmpStakeLevel_History (ID, StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime)
				SELECT ID, StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime
				FROM DBCUST.CustDB.dbo.StakeLevelGroupDetail_History WITH (NOLOCK)
				WHERE ID BETWEEN @ID AND (@ID+@batch)

				INSERT INTO dbo.StakeLevelGroupDetail_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime)
				SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake , UpdateTime
				FROM #tmpStakeLevel_History
				WHERE ID BETWEEN @ID AND (@ID+@batch)

				SET @rows=@rows-@batch
				SET @ID=@ID+@batch
			END
		END

		INSERT INTO dbo.StakeLevelGroupDetail_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime)
		SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake , UpdateTime
		FROM #tmpStakeLevel_History

		EXEC DBCUST.CustDB.dbo.Task_DetectBet_DelBetSettingHistory @ID=@ID_max, @IsLicensee=1, @IsGroup=0

		--update ID:
		UPDATE conf
		SET ConfigValue=CAST(@ID_max AS VARCHAR)
		FROM CustMaxBetSetting_Config AS conf WITH (ROWLOCK, UPDLOCK)
		WHERE ConfigName='StakeLevelGroupDetail_ID'

		TRUNCATE TABLE #tmpStakeLevel_History
	END


	IF EXISTS (SELECT 1 FROM DBCUST.CustDB.dbo.Dep_StakeLevelGroupDetail_History)
	BEGIN
		SET @ID = (SELECT CAST(ConfigValue AS INT) FROM CustMaxBetSetting_Config WITH (NOLOCK) WHERE ConfigName='StakeLevelGroupDetail_ID')
		
		SELECT @rows=COUNT(1), @ID_max=MAX(ID) 
		FROM DBCUST.CustDB.dbo.Dep_StakeLevelGroupDetail_History WITH (NOLOCK) 

		IF @rows<=@batch
		BEGIN
			INSERT INTO #tmpStakeLevel_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime)
			SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime
			FROM DBCUST.CustDB.dbo.Dep_StakeLevelGroupDetail_History WITH (NOLOCK)

			INSERT INTO dbo.Dep_StakeLevelGroupDetail_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime)
			SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime
			FROM #tmpStakeLevel_History
		END
		ELSE
		BEGIN
			WHILE @rows>0
			BEGIN
				INSERT TOP (@batch) INTO #tmpStakeLevel_History (ID, StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime)
				SELECT ID, StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime
				FROM DBCUST.CustDB.dbo.Dep_StakeLevelGroupDetail_History WITH (NOLOCK)
				WHERE ID BETWEEN @ID AND (@ID+@batch)

				INSERT INTO dbo.Dep_StakeLevelGroupDetail_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime)
				SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime
				FROM #tmpStakeLevel_History
				WHERE ID BETWEEN @ID AND (@ID+@batch)

				SET @rows=@rows-@batch
				SET @ID=@ID+@batch
			END
		END

		--Delete data DBCUST.CustDB
		EXEC DBCUST.CustDB.dbo.Task_DetectBet_DelBetSettingHistory @ID=@ID_max, @IsLicensee=1, @IsGroup=1

		--update ID:
		UPDATE conf
		SET ConfigValue=CAST(@ID_max AS VARCHAR)
		FROM CustMaxBetSetting_Config AS conf WITH (ROWLOCK, UPDLOCK)
		WHERE ConfigName='Dep_StakeLevelGroupDetail_ID'

		TRUNCATE TABLE #tmpStakeLevel_History
	END

	--update ConfigValue
	UPDATE conf
	SET ConfigValue=CONVERT(VARCHAR, @UpdateTime, 121)
	FROM CustMaxBetSetting_Config AS conf WITH (ROWLOCK, UPDLOCK)
	WHERE ConfigName='SyncHistoryDataLastTime'


	DROP TABLE #tmpBetSetting_History
	DROP TABLE #tmpStakeLevel_History
END
GO