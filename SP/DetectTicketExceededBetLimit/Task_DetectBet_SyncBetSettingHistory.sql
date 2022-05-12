/*<info serverAlias="DBTP-bodb02" executers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Task_DetectBet_SyncBetSettingHistory] 
AS
/*
	Created: 20220512@Tacy
	Task : Sync history of bet setting from DBcust.CustDB to DBTP.bodb02
	DB: DBTP/bodb02
	Original:

	Revisions:
		- 20220512@Tacy: Initial SP [RedmineID: #170739]

	Param's Explanation:

*/
BEGIN
	SET NOCOUNT ON

	DECLARE @UpdateTime DATETIME

	SET @UpdateTime = GETDATE()

	CREATE TABLE #tmpBetSetting_History (
			CustID			INT
		,	SportType		SMALLINT
		,	BetType			INT
		,	OldMaxBet		MONEY
		,	OldMaxPerMatch	MONEY
		,	StakeLevelList	VARCHAR(200)
		,	UpdateTime		DATETIME
	)

	CREATE TABLE #tmpStakeLevel_History (
			StakeLevelID	INT
		,	GameTypeID		INT
		,	MaxLabel		NVARCHAR(50)
		,	MaxStake		DECIMAL(19,8)
		,	MaxGameStake	DECIMAL(19,8)
		,	UpdateTime		DATETIME
	)

	--History: SMA update member bet setting
	IF EXISTS (SELECT 1 FROM DBCust.CustDB.dbo.CustMaxBetSetting_History)
	BEGIN
		INSERT INTO #tmpBetSetting_History (CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, StakeLevelList, UpdateTime)
		SELECT CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, StakeLevelList, UpdateTime
		FROM DBCust.CustDB.dbo.CustMaxBetSetting_History WITH (NOLOCK)

		INSERT INTO dbo.CustMaxBetSetting_History (CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, StakeLevelList, UpdateTime)
		SELECT CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, StakeLevelList, UpdateTime
		FROM #tmpBetSetting_History 

		DELETE cbsh
		FROM DBCust.CustDB.dbo.CustMaxBetSetting_History cbsh WITH (ROWLOCK)
			INNER JOIN #tmpBetSetting_History t 
				ON	t.CustID	= cbsh.CustID
				AND t.SportType	= cbsh.SportType
				AND t.BetType	= cbsh.BetType
				AND t.UpdateTime= cbsh.UpdateTime

		TRUNCATE TABLE #tmpBetSetting_History
	END

	IF EXISTS (SELECT 1 FROM DBCust.CustDB.dbo.Dep_CustMaxBetSetting_History)
	BEGIN
		INSERT INTO #tmpBetSetting_History (CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, StakeLevelList, UpdateTime)
		SELECT CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, StakeLevelList, UpdateTime
		FROM DBCust.CustDB.dbo.Dep_CustMaxBetSetting_History WITH (NOLOCK)

		INSERT INTO dbo.Dep_CustMaxBetSetting_History (CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, StakeLevelList, UpdateTime)
		SELECT CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, StakeLevelList, UpdateTime
		FROM #tmpBetSetting_History 

		DELETE cbsh
		FROM DBCust.CustDB.dbo.Dep_CustMaxBetSetting_History cbsh WITH (ROWLOCK)
			INNER JOIN #tmpBetSetting_History t 
				ON	t.CustID	= cbsh.CustID
				AND t.SportType	= cbsh.SportType
				AND t.BetType	= cbsh.BetType
				AND t.UpdateTime= cbsh.UpdateTime
		
		TRUNCATE TABLE #tmpBetSetting_History
	END

	--History: update global bet setting
	IF EXISTS (SELECT 1 FROM DBCust.CustDB.dbo.StakeLevel_History)
	BEGIN
		INSERT INTO #tmpStakeLevel_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, UpdateTime)
		SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, UpdateTime
		FROM DBCust.CustDB.dbo.StakeLevel_History WITH (NOLOCK)

		INSERT INTO dbo.StakeLevel_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, UpdateTime)
		SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, UpdateTime
		FROM #tmpStakeLevel_History

		DELETE cslh
		FROM DBCust.CustDB.dbo.StakeLevel_History cslh WITH (ROWLOCK)
			INNER JOIN #tmpStakeLevel_History t 
				ON	t.StakeLevelID	= cslh.StakeLevelID
				AND t.UpdateTime	= cslh.UpdateTime

		TRUNCATE TABLE #tmpStakeLevel_History
	END


	IF EXISTS (SELECT 1 FROM DBCust.CustDB.dbo.Dep_StakeLevel_History)
	BEGIN
		INSERT INTO #tmpStakeLevel_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, UpdateTime)
		SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, UpdateTime
		FROM DBCust.CustDB.dbo.Dep_StakeLevel_History WITH (NOLOCK)

		INSERT INTO dbo.Dep_StakeLevel_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, UpdateTime)
		SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, UpdateTime
		FROM #tmpStakeLevel_History

		DELETE cslh
		FROM DBCust.CustDB.dbo.Dep_StakeLevel_History cslh WITH (ROWLOCK)
			INNER JOIN #tmpStakeLevel_History t 
				ON	t.StakeLevelID	= cslh.StakeLevelID
				AND t.UpdateTime	= cslh.UpdateTime
		
		TRUNCATE TABLE #tmpStakeLevel_History
	END

	----------------------------------------------------------------------------------------------------------
	IF EXISTS (SELECT 1 FROM DBCust.CustDB.dbo.StakeLevelGroupDetail_History)
	BEGIN
		INSERT INTO #tmpStakeLevel_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime)
		SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, UpdateTime
		FROM DBCust.CustDB.dbo.StakeLevelGroupDetail_History WITH (NOLOCK)

		INSERT INTO dbo.StakeLevelGroupDetail_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime)
		SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, UpdateTime
		FROM #tmpStakeLevel_History

		DELETE cslgh
		FROM DBCust.CustDB.dbo.StakeLevelGroupDetail_History cslgh WITH (ROWLOCK)
			INNER JOIN #tmpStakeLevel_History t 
				ON	t.StakeLevelID	= cslh.StakeLevelID
				AND t.GameTypeID	= cslh.GameTypeID
				AND t.UpdateTime	= cslh.UpdateTime
		
		TRUNCATE TABLE #tmpStakeLevel_History
	END


	IF EXISTS (SELECT 1 FROM DBCust.CustDB.dbo.Dep_StakeLevelGroupDetail_History)
	BEGIN
		INSERT INTO #tmpStakeLevel_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime)
		SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, UpdateTime
		FROM DBCust.CustDB.dbo.Dep_StakeLevelGroupDetail_History WITH (NOLOCK)

		INSERT INTO dbo.Dep_StakeLevelGroupDetail_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime)
		SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, UpdateTime
		FROM #tmpStakeLevel_History

		DELETE cslgh
		FROM DBCust.CustDB.dbo.Dep_StakeLevelGroupDetail_History cslgh WITH (ROWLOCK)
			INNER JOIN #tmpStakeLevel_History t 
				ON	t.StakeLevelID	= cslh.StakeLevelID
				AND t.GameTypeID	= cslh.GameTypeID
				AND t.UpdateTime	= cslh.UpdateTime
		
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