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

	DECLARE @UpdateTime		DATETIME, 
			@batch			INT=5000,
			@History_List	NVARCHAR(MAX)=NULL
	
	CREATE TABLE #tmpBetSetting_History (
			CustID			INT
		,	SportType		SMALLINT
		,	BetType			INT
		,	UpdateTime		DATETIME
	)

	CREATE TABLE #tmpStakeLevel_History (
			StakeLevelID	INT
		,	GameTypeID		INT
		,	UpdateTime		DATETIME
	)

	SET @UpdateTime = GETDATE()

	--History: SMA update member bet setting
	IF EXISTS (SELECT 1 FROM DBCUST.CustDB.dbo.CustMaxBetSetting_History WITH (NOLOCK))
	BEGIN
		INSERT INTO dbo.CustMaxBetSetting_History (CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime)
		OUTPUT inserted.CustID, inserted.SportType, inserted.BetType, inserted.UpdateTime
			INTO #tmpBetSetting_History (CustID, SportType, BetType, UpdateTime)
		SELECT TOP (@batch) CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime
		FROM DBCUST.CustDB.dbo.CustMaxBetSetting_History WITH (NOLOCK)

		SET @History_List = (SELECT	CustID				AS '@CustID',
									SportType			AS '@SportType',
									BetType				AS '@BetType',
									UpdateTime			AS '@UpdateTime'
							FROM #tmpBetSetting_History
							FOR XML PATH('r'), ROOT ('root')
							)

		--Delete data - DBCUST.CustDB
		EXEC DBCUST.CustDB.dbo.Task_DetectBet_DelBetSettingHistory @Mode=1, @History_List=@History_List

		TRUNCATE TABLE #tmpBetSetting_History
	END

	IF EXISTS (SELECT 1 FROM DBCUST.CustDB.dbo.Dep_CustMaxBetSetting_History WITH (NOLOCK))
	BEGIN
		INSERT INTO dbo.Dep_CustMaxBetSetting_History (CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime)
		OUTPUT inserted.CustID, inserted.SportType, inserted.BetType, inserted.UpdateTime
			INTO #tmpBetSetting_History (CustID, SportType, BetType, UpdateTime)
		SELECT TOP (@batch) CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime
		FROM DBCUST.CustDB.dbo.Dep_CustMaxBetSetting_History WITH (NOLOCK)

		SET @History_List = (SELECT	CustID				AS '@CustID',
									SportType			AS '@SportType',
									BetType				AS '@BetType',
									UpdateTime			AS '@UpdateTime'
							FROM #tmpBetSetting_History
							FOR XML PATH('r'), ROOT ('root')
							)

		--Delete data - DBCUST.CustDB
		EXEC DBCUST.CustDB.dbo.Task_DetectBet_DelBetSettingHistory @Mode=2, @History_List=@History_List

		TRUNCATE TABLE #tmpBetSetting_History
	END

	--History: update global bet setting
	IF EXISTS (SELECT 1 FROM DBCUST.CustDB.dbo.StakeLevel_History WITH (NOLOCK))
	BEGIN
		INSERT INTO dbo.StakeLevel_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, UpdateTime)
		OUTPUT inserted.StakeLevelID, inserted.UpdateTime
			INTO #tmpStakeLevel_History (StakeLevelID, UpdateTime)
		SELECT TOP (@batch) StakeLevelID, GameTypeID, MaxLabel, MaxStake, UpdateTime
		FROM DBCUST.CustDB.dbo.StakeLevel_History WITH (NOLOCK)
	
		SET @History_List = (SELECT	StakeLevelID	AS '@StakeLevelID',
									UpdateTime		AS '@UpdateTime'
							FROM #tmpStakeLevel_History
							FOR XML PATH('r'), ROOT ('root')
							)

		--Delete data - DBCUST.CustDB
		EXEC DBCUST.CustDB.dbo.Task_DetectBet_DelBetSettingHistory @Mode=3, @History_List=@History_List

		TRUNCATE TABLE #tmpStakeLevel_History
	
	END

	IF EXISTS (SELECT 1 FROM DBCUST.CustDB.dbo.Dep_StakeLevel_History WITH (NOLOCK))
	BEGIN
		INSERT INTO dbo.Dep_StakeLevel_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, SiteID, UpdateTime)
		OUTPUT inserted.StakeLevelID, inserted.UpdateTime
			INTO #tmpStakeLevel_History (StakeLevelID, UpdateTime)
		SELECT TOP (@batch) StakeLevelID, GameTypeID, MaxLabel, MaxStake, SiteID, UpdateTime
		FROM DBCUST.CustDB.dbo.Dep_StakeLevel_History WITH (NOLOCK)

		SET @History_List = (SELECT	StakeLevelID	AS '@StakeLevelID',
									UpdateTime		AS '@UpdateTime'
							FROM #tmpStakeLevel_History
							FOR XML PATH('r'), ROOT ('root')
							)

		--Delete data - DBCUST.CustDB
		EXEC DBCUST.CustDB.dbo.Task_DetectBet_DelBetSettingHistory @Mode=4, @History_List=@History_List

		TRUNCATE TABLE #tmpStakeLevel_History
	END

	----------------------------------------------------------------------------------------------------------
	IF EXISTS (SELECT 1 FROM DBCUST.CustDB.dbo.StakeLevelGroupDetail_History WITH (NOLOCK))
	BEGIN
		INSERT INTO dbo.StakeLevelGroupDetail_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime)
		OUTPUT inserted.StakeLevelID, inserted.GameTypeID, inserted.UpdateTime
			INTO #tmpStakeLevel_History (StakeLevelID, GameTypeID, UpdateTime)
		SELECT TOP (@batch) StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime
		FROM DBCUST.CustDB.dbo.StakeLevelGroupDetail_History WITH (NOLOCK)
		
		SET @History_List = (SELECT	StakeLevelID	AS '@StakeLevelID',
									GameTypeID		AS '@GameTypeID',
									UpdateTime		AS '@UpdateTime'
							FROM #tmpStakeLevel_History
							FOR XML PATH('r'), ROOT ('root')
							)

		--Delete data - DBCUST.CustDB
		EXEC DBCUST.CustDB.dbo.Task_DetectBet_DelBetSettingHistory @Mode=5, @History_List=@History_List

		TRUNCATE TABLE #tmpStakeLevel_History
	END


	IF EXISTS (SELECT 1 FROM DBCUST.CustDB.dbo.Dep_StakeLevelGroupDetail_History WITH (NOLOCK))
	BEGIN
		INSERT INTO dbo.Dep_StakeLevelGroupDetail_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime)
		OUTPUT inserted.StakeLevelID, inserted.GameTypeID, inserted.UpdateTime
			INTO #tmpStakeLevel_History (StakeLevelID, GameTypeID, UpdateTime)
		SELECT TOP (@batch) StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime
		FROM DBCUST.CustDB.dbo.Dep_StakeLevelGroupDetail_History WITH (NOLOCK)

		SET @History_List = (SELECT	StakeLevelID	AS '@StakeLevelID',
									GameTypeID		AS '@GameTypeID',
									UpdateTime		AS '@UpdateTime'
							FROM #tmpStakeLevel_History
							FOR XML PATH('r'), ROOT ('root')
							)

		--Delete data - DBCUST.CustDB
		EXEC DBCUST.CustDB.dbo.Task_DetectBet_DelBetSettingHistory @Mode=6, @History_List=@History_List

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