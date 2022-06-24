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
			@batch		INT = 5000,
			@StakeLevel_Time				DATETIME=NULL,
			@StakeLevelGroupDetail_Time		DATETIME=NULL,
			@Dep_StakeLevel_Time			DATETIME=NULL,
			@Dep_StakeLevelGroupDetail_Time	DATETIME=NULL,
			@CustMaxBetSetting_Time			DATETIME=NULL,
			@Dep_CustMaxBetSetting_Time		DATETIME=NULL

	SET @UpdateTime = GETDATE()

	--History: SMA update member bet setting
	IF EXISTS (SELECT 1 FROM DBCUST.CustDB.dbo.CustMaxBetSetting_History)
	BEGIN
		SET @CustMaxBetSetting_Time=(SELECT MAX(UpdateTime)
									 FROM (SELECT TOP (@batch+1) UpdateTime
											FROM DBCUST.CustDB.dbo.CustMaxBetSetting_History WITH (NOLOCK)
											ORDER BY UpdateTime) t
									)

		INSERT INTO dbo.CustMaxBetSetting_History (CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime)
		SELECT CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime
		FROM DBCUST.CustDB.dbo.CustMaxBetSetting_History WITH (NOLOCK)
		WHERE UpdateTime<@CustMaxBetSetting_Time
	END

	IF EXISTS (SELECT 1 FROM DBCUST.CustDB.dbo.Dep_CustMaxBetSetting_History)
	BEGIN
		SET @Dep_CustMaxBetSetting_Time=(SELECT MAX(UpdateTime)
										 FROM (SELECT TOP (@batch+1) UpdateTime
											FROM DBCUST.CustDB.dbo.Dep_CustMaxBetSetting_History WITH (NOLOCK)
											ORDER BY UpdateTime) t
										)

		INSERT INTO dbo.Dep_CustMaxBetSetting_History (CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime)
		SELECT CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime
		FROM DBCUST.CustDB.dbo.Dep_CustMaxBetSetting_History WITH (NOLOCK)
		WHERE UpdateTime<@Dep_CustMaxBetSetting_Time
	END

	--History: update global bet setting
	IF EXISTS (SELECT 1 FROM DBCUST.CustDB.dbo.StakeLevel_History)
	BEGIN
		SET @StakeLevel_Time=(SELECT MAX(UpdateTime)
							  FROM (SELECT TOP (@batch+1) UpdateTime
									FROM DBCUST.CustDB.dbo.StakeLevel_History WITH (NOLOCK)
									ORDER BY UpdateTime) t
							)
		
		INSERT INTO dbo.StakeLevel_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, UpdateTime)
		SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, UpdateTime
		FROM DBCUST.CustDB.dbo.StakeLevel_History WITH (NOLOCK)
		WHERE UpdateTime<@StakeLevel_Time
	END

	IF EXISTS (SELECT 1 FROM DBCUST.CustDB.dbo.Dep_StakeLevel_History)
	BEGIN
		SET @Dep_StakeLevel_Time=(SELECT MAX(UpdateTime)
								  FROM (SELECT TOP (@batch+1) UpdateTime
										FROM DBCUST.CustDB.dbo.Dep_StakeLevel_History WITH (NOLOCK)
										ORDER BY UpdateTime) t
								)

		INSERT INTO dbo.Dep_StakeLevel_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, SiteID, UpdateTime)
		SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, SiteID, UpdateTime
		FROM DBCUST.CustDB.dbo.Dep_StakeLevel_History WITH (NOLOCK)
		WHERE UpdateTime<@Dep_StakeLevel_Time
	END

	----------------------------------------------------------------------------------------------------------
	IF EXISTS (SELECT 1 FROM DBCUST.CustDB.dbo.StakeLevelGroupDetail_History)
	BEGIN
		SET @StakeLevelGroupDetail_Time=(SELECT MAX(UpdateTime)
										 FROM (SELECT TOP (@batch+1) UpdateTime
												FROM DBCUST.CustDB.dbo.StakeLevelGroupDetail_History WITH (NOLOCK)
												ORDER BY UpdateTime) t
										)

		INSERT INTO dbo.StakeLevelGroupDetail_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime)
		SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime
		FROM DBCUST.CustDB.dbo.StakeLevelGroupDetail_History WITH (NOLOCK)
		WHERE UpdateTime<@StakeLevelGroupDetail_Time
	END


	IF EXISTS (SELECT 1 FROM DBCUST.CustDB.dbo.Dep_StakeLevelGroupDetail_History)
	BEGIN
		SET @Dep_StakeLevelGroupDetail_Time=(SELECT MAX(UpdateTime)
											FROM (SELECT TOP (@batch+1) UpdateTime
												  FROM DBCUST.CustDB.dbo.Dep_StakeLevelGroupDetail_History WITH (NOLOCK)
												  ORDER BY UpdateTime) t
											)

		INSERT INTO dbo.Dep_StakeLevelGroupDetail_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime)
		SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime
		FROM DBCUST.CustDB.dbo.Dep_StakeLevelGroupDetail_History WITH (NOLOCK)
		WHERE UpdateTime<@Dep_StakeLevelGroupDetail_Time
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
END
GO