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
			@StakeLevel_Time				DATETIME=NULL,
			@StakeLevelGroupDetail_Time		DATETIME=NULL,
			@Dep_StakeLevel_Time			DATETIME=NULL,
			@Dep_StakeLevelGroupDetail_Time	DATETIME=NULL,
			@CustMaxBetSetting_Time			DATETIME=NULL,
			@Dep_CustMaxBetSetting_Time		DATETIME=NULL

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

	--History: SMA update member bet setting
	IF EXISTS (SELECT 1 FROM DBCUST.CustDB.dbo.CustMaxBetSetting_History)
	BEGIN
		SET @rows = (SELECT COUNT(1) FROM DBCUST.CustDB.dbo.CustMaxBetSetting_History WITH (NOLOCK))

		IF @rows<=@batch
		BEGIN
			SET @CustMaxBetSetting_Time=(SELECT MAX(UpdateTime) FROM DBCUST.CustDB.dbo.CustMaxBetSetting_History WITH (NOLOCK))
		END
		ELSE
		BEGIN
			SET @CustMaxBetSetting_Time=(SELECT MAX(UpdateTime)
										  FROM (SELECT TOP (@batch+1) UpdateTime
												FROM DBCUST.CustDB.dbo.CustMaxBetSetting_History WITH (NOLOCK)
												ORDER BY UpdateTime) t
										)
		END

		INSERT INTO #tmpBetSetting_History (CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime)
		SELECT CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime
		FROM DBCUST.CustDB.dbo.CustMaxBetSetting_History WITH (NOLOCK)
		WHERE UpdateTime<@CustMaxBetSetting_Time

		INSERT INTO dbo.CustMaxBetSetting_History (CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime)
		SELECT CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime
		FROM #tmpBetSetting_History 

		TRUNCATE TABLE #tmpBetSetting_History
	END

	IF EXISTS (SELECT 1 FROM DBCUST.CustDB.dbo.Dep_CustMaxBetSetting_History)
	BEGIN
		SET @rows = (SELECT COUNT(1) FROM DBCUST.CustDB.dbo.Dep_CustMaxBetSetting_History WITH (NOLOCK))

		IF @rows<=@batch
		BEGIN
			SET @Dep_CustMaxBetSetting_Time=(SELECT MAX(UpdateTime) FROM DBCUST.CustDB.dbo.Dep_CustMaxBetSetting_History WITH (NOLOCK))
		END
		ELSE
		BEGIN
			SET @Dep_CustMaxBetSetting_Time=(SELECT MAX(UpdateTime)
									  FROM (SELECT TOP (@batch+1) UpdateTime
											FROM DBCUST.CustDB.dbo.Dep_CustMaxBetSetting_History WITH (NOLOCK)
											ORDER BY UpdateTime) t
									)
		END

		INSERT INTO #tmpBetSetting_History (CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime)
		SELECT CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime
		FROM DBCUST.CustDB.dbo.Dep_CustMaxBetSetting_History WITH (NOLOCK)
		WHERE UpdateTime<@Dep_CustMaxBetSetting_Time

		INSERT INTO dbo.Dep_CustMaxBetSetting_History (CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime)
		SELECT CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime
		FROM #tmpBetSetting_History 

		TRUNCATE TABLE #tmpBetSetting_History
	END

	--History: update global bet setting
	IF EXISTS (SELECT 1 FROM DBCUST.CustDB.dbo.StakeLevel_History)
	BEGIN
		SET @rows=(SELECT COUNT(1) FROM DBCUST.CustDB.dbo.StakeLevel_History WITH (NOLOCK))

		IF @rows<=@batch
		BEGIN
			SET @StakeLevel_Time=(SELECT MAX(UpdateTime) FROM DBCUST.CustDB.dbo.StakeLevel_History WITH (NOLOCK))
		END
		ELSE 
		BEGIN
			SET @StakeLevel_Time=(SELECT MAX(UpdateTime)
								  FROM (SELECT TOP (@batch+1) UpdateTime
										FROM DBCUST.CustDB.dbo.StakeLevel_History WITH (NOLOCK)
										ORDER BY UpdateTime) t
									)
		END

		INSERT INTO #tmpStakeLevel_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, UpdateTime)
		SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, UpdateTime
		FROM DBCUST.CustDB.dbo.StakeLevel_History WITH (NOLOCK)
		WHERE UpdateTime<@StakeLevel_Time
		
		INSERT INTO dbo.StakeLevel_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, UpdateTime)
		SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, UpdateTime
		FROM #tmpStakeLevel_History

		TRUNCATE TABLE #tmpStakeLevel_History
	END

	IF EXISTS (SELECT 1 FROM DBCUST.CustDB.dbo.Dep_StakeLevel_History)
	BEGIN
		SET @rows=(SELECT COUNT(1) FROM DBCUST.CustDB.dbo.Dep_StakeLevel_History WITH (NOLOCK))

		IF @rows<=@batch
		BEGIN
			SET @Dep_StakeLevel_Time=(SELECT MAX(UpdateTime) FROM DBCUST.CustDB.dbo.Dep_StakeLevel_History WITH (NOLOCK))
		END
		ELSE
		BEGIN
			SET @Dep_StakeLevel_Time=(SELECT MAX(UpdateTime)
									  FROM (SELECT TOP (@batch+1) UpdateTime
											FROM DBCUST.CustDB.dbo.Dep_StakeLevel_History WITH (NOLOCK)
											ORDER BY UpdateTime) t
									)
		END

		INSERT INTO #tmpStakeLevel_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, SiteID, UpdateTime)
		SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, SiteID, UpdateTime
		FROM DBCUST.CustDB.dbo.Dep_StakeLevel_History WITH (NOLOCK)
		WHERE UpdateTime<@Dep_StakeLevel_Time

		INSERT INTO dbo.Dep_StakeLevel_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, SiteID, UpdateTime)
		SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, SiteID, UpdateTime
		FROM #tmpStakeLevel_History

		TRUNCATE TABLE #tmpStakeLevel_History
	END

	----------------------------------------------------------------------------------------------------------
	IF EXISTS (SELECT 1 FROM DBCUST.CustDB.dbo.StakeLevelGroupDetail_History)
	BEGIN
		SET @rows=(SELECT COUNT(1) FROM DBCUST.CustDB.dbo.StakeLevelGroupDetail_History WITH (NOLOCK))

		IF @rows<=@batch
		BEGIN
			SET @StakeLevelGroupDetail_Time=(SELECT MAX(UpdateTime) FROM DBCUST.CustDB.dbo.StakeLevelGroupDetail_History WITH (NOLOCK))
		END
		ELSE
		BEGIN
			SET @StakeLevelGroupDetail_Time=(SELECT MAX(UpdateTime)
											  FROM (SELECT TOP (@batch+1) UpdateTime
													FROM DBCUST.CustDB.dbo.StakeLevelGroupDetail_History WITH (NOLOCK)
													ORDER BY UpdateTime) t
											)
		END

		INSERT INTO #tmpStakeLevel_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime)
		SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime
		FROM DBCUST.CustDB.dbo.StakeLevelGroupDetail_History WITH (NOLOCK)
		WHERE UpdateTime<@StakeLevelGroupDetail_Time

		INSERT INTO dbo.StakeLevelGroupDetail_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime)
		SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake , UpdateTime
		FROM #tmpStakeLevel_History

		TRUNCATE TABLE #tmpStakeLevel_History
	END


	IF EXISTS (SELECT 1 FROM DBCUST.CustDB.dbo.Dep_StakeLevelGroupDetail_History)
	BEGIN
		SET @rows=(SELECT COUNT(1) FROM DBCUST.CustDB.dbo.Dep_StakeLevelGroupDetail_History WITH (NOLOCK))

		IF @rows<=@batch
		BEGIN
			SET @Dep_StakeLevelGroupDetail_Time=(SELECT MAX(UpdateTime) FROM DBCUST.CustDB.dbo.Dep_StakeLevelGroupDetail_History WITH (NOLOCK))
		END
		ELSE
		BEGIN
			SET @Dep_StakeLevelGroupDetail_Time=(SELECT MAX(UpdateTime)
												  FROM (SELECT TOP (@batch+1) UpdateTime
														FROM DBCUST.CustDB.dbo.Dep_StakeLevelGroupDetail_History WITH (NOLOCK)
														ORDER BY UpdateTime) t
												)
		END

		INSERT INTO #tmpStakeLevel_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime)
		SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime
		FROM DBCUST.CustDB.dbo.Dep_StakeLevelGroupDetail_History WITH (NOLOCK)
		WHERE UpdateTime<@Dep_StakeLevelGroupDetail_Time

		INSERT INTO dbo.Dep_StakeLevelGroupDetail_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime)
		SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime
		FROM #tmpStakeLevel_History

		TRUNCATE TABLE #tmpStakeLevel_History
	END

	--update ConfigValue
	UPDATE conf
	SET ConfigValue=CONVERT(VARCHAR, @UpdateTime, 121)
	FROM CustMaxBetSetting_Config AS conf WITH (ROWLOCK, UPDLOCK)
	WHERE ConfigName='SyncHistoryDataLastTime'

	--Delete data - DBCUST.CustDB
	EXEC DBCUST.CustDB.dbo.Task_DetectBet_DelBetSettingHistory
		@StakeLevel_Time				= @StakeLevel_Time,
		@StakeLevelGroupDetail_Time		= @StakeLevelGroupDetail_Time,
		@Dep_StakeLevel_Time			= @Dep_StakeLevel_Time, 
		@Dep_StakeLevelGroupDetail_Time	= @Dep_StakeLevelGroupDetail_Time,
		@CustMaxBetSetting_Time			= @CustMaxBetSetting_Time,
		@Dep_CustMaxBetSetting_Time		= @Dep_CustMaxBetSetting_Time


	DROP TABLE #tmpBetSetting_History
	DROP TABLE #tmpStakeLevel_History
END
GO