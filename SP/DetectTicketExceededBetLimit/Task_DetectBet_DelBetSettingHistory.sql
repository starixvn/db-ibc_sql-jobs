/*<info serverAlias="DBCUST-CustDB" executers="" isFunction="0" isNested="1"></info>*/

ALTER PROCEDURE [dbo].[Task_DetectBet_DelBetSettingHistory] 
			@Mode			TINYINT,
			@History_List	NVARCHAR(MAX)=NULL
AS
/*
	Created: 20220623@Tacy
	Task: Delete history of bet setting - DBcust.CustDB 
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20220623@Tacy: Initial SP [RedmineID: #170739]

	Param's Explanation:
		@Mode:
		- 1 : CustMaxBetSetting_History
		- 2 : Dep_CustMaxBetSetting_History
		- 3 : StakeLevel_History
		- 4 : Dep_StakeLevel_History
		- 5 : StakeLevelGroupDetail_History
		- 6 : Dep_StakeLevelGroupDetail_History
*/
BEGIN
	SET NOCOUNT ON 
	DECLARE @iDoc INT
	DECLARE @xml XML = NULL

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
		,	MaxLabel		VARCHAR(50)
		,	MaxStake		DECIMAL(19,8)
		,	MaxGameStake	DECIMAL(19,8)
		,	SiteID			INT
		,	UpdateTime		DATETIME
	)

	IF @History_List IS NULL OR @History_List=''
		RETURN

	SET @xml = CONVERT(XML, @History_List)
	
	IF @Mode=1	--CustMaxBetSetting_History
	BEGIN
		--Parse XML	
		EXEC sp_xml_preparedocument @iDoc OUTPUT
			, @xml

		INSERT INTO #tmpBetSetting_History(CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime)
		SELECT CustID, SportType, BetType
			, CASE WHEN ISNUMERIC(OldMaxBet)=1		THEN OldMaxBet ELSE NULL END OldMaxBet
			, CASE WHEN ISNUMERIC(OldMaxPerMatch)=1	THEN OldMaxPerMatch ELSE NULL END OldMaxPerMatch
			, CASE WHEN OldStakeLevelList<>'NULL'	THEN OldStakeLevelList ELSE NULL END OldStakeLevelList
			, UpdateTime
		FROM OPENXML(@iDoc, '/root/r', 1) WITH (
				CustID			INT
			,	SportType		SMALLINT
			,	BetType			INT
			,	OldMaxBet		VARCHAR(100)
			,	OldMaxPerMatch	VARCHAR(100)
			,	OldStakeLevelList VARCHAR(200)
			,	UpdateTime		DATETIME
		)
	
		EXEC sp_xml_removedocument @iDoc

		DELETE cbsh
		FROM CustMaxBetSetting_History cbsh WITH (ROWLOCK)
			INNER JOIN #tmpBetSetting_History t 
				ON	t.CustID	= cbsh.CustID
				AND t.SportType	= cbsh.SportType
				AND t.BetType	= cbsh.BetType
				AND t.UpdateTime= cbsh.UpdateTime
	END

	IF @Mode=2	--Dep_CustMaxBetSetting_History
	BEGIN
		--Parse XML	
		EXEC sp_xml_preparedocument @iDoc OUTPUT
			, @xml

		INSERT INTO #tmpBetSetting_History(CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, OldStakeLevelList, UpdateTime)
		SELECT CustID, SportType, BetType
			, CASE WHEN ISNUMERIC(OldMaxBet)=1		THEN OldMaxBet ELSE NULL END OldMaxBet
			, CASE WHEN ISNUMERIC(OldMaxPerMatch)=1	THEN OldMaxPerMatch ELSE NULL END OldMaxPerMatch
			, CASE WHEN OldStakeLevelList<>'NULL'	THEN OldStakeLevelList ELSE NULL END OldStakeLevelList
			, UpdateTime
		FROM OPENXML(@iDoc, '/root/r', 1) WITH (
				CustID			INT
			,	SportType		SMALLINT
			,	BetType			INT
			,	OldMaxBet		VARCHAR(100)
			,	OldMaxPerMatch	VARCHAR(100)
			,	OldStakeLevelList VARCHAR(200)
			,	UpdateTime		DATETIME
		)
	
		EXEC sp_xml_removedocument @iDoc

		DELETE cbsh
		FROM Dep_CustMaxBetSetting_History cbsh WITH (ROWLOCK)
			INNER JOIN #tmpBetSetting_History t 
				ON	t.CustID	= cbsh.CustID
				AND t.SportType	= cbsh.SportType
				AND t.BetType	= cbsh.BetType
				AND t.UpdateTime= cbsh.UpdateTime
	END

	IF @Mode=3	--StakeLevel_History
	BEGIN
		--Parse XML	
		EXEC sp_xml_preparedocument @iDoc OUTPUT
			, @xml

		INSERT INTO #tmpStakeLevel_History(StakeLevelID, GameTypeID, MaxLabel, MaxStake, UpdateTime)
		SELECT StakeLevelID, GameTypeID
			, CASE WHEN MaxLabel<>'NULL'		THEN MaxLabel ELSE NULL END MaxLabel
			, CASE WHEN ISNUMERIC(MaxStake)=1	THEN MaxStake ELSE NULL END MaxStake
			, UpdateTime
		FROM OPENXML(@iDoc, '/root/r', 1) WITH (
				StakeLevelID	INT
			,	GameTypeID		INT
			,	MaxLabel		VARCHAR(50)
			,	MaxStake		VARCHAR(50)
			,	UpdateTime		DATETIME
		)
	
		EXEC sp_xml_removedocument @iDoc

		DELETE cslh
		FROM StakeLevel_History cslh WITH (ROWLOCK)
			INNER JOIN #tmpStakeLevel_History t 
				ON	t.StakeLevelID	= cslh.StakeLevelID
				AND t.UpdateTime	= cslh.UpdateTime
	END

	IF @Mode=4	--Dep_StakeLevel_History
	BEGIN
		--Parse XML	
		EXEC sp_xml_preparedocument @iDoc OUTPUT
			, @xml

		INSERT INTO #tmpStakeLevel_History(StakeLevelID, GameTypeID, MaxLabel, MaxStake, SiteID, UpdateTime)
		SELECT StakeLevelID, GameTypeID
			, CASE WHEN MaxLabel<>'NULL'		THEN MaxLabel ELSE NULL END MaxLabel
			, CASE WHEN ISNUMERIC(MaxStake)=1	THEN MaxStake ELSE NULL END MaxStake
			, CASE WHEN ISNUMERIC(SiteID)=1		THEN SiteID ELSE NULL END SiteID
			, UpdateTime
		FROM OPENXML(@iDoc, '/root/r', 1) WITH (
				StakeLevelID	INT
			,	GameTypeID		INT
			,	MaxLabel		VARCHAR(50)
			,	MaxStake		VARCHAR(50)
			,	SiteID			VARCHAR(5)
			,	UpdateTime		DATETIME
		)
	
		EXEC sp_xml_removedocument @iDoc

		DELETE cslh
		FROM Dep_StakeLevel_History cslh WITH (ROWLOCK)
			INNER JOIN #tmpStakeLevel_History t 
				ON	t.StakeLevelID	= cslh.StakeLevelID
				AND t.UpdateTime	= cslh.UpdateTime
	END

	IF @Mode=5	--StakeLevelGroupDetail_History
	BEGIN
		--Parse XML	
		EXEC sp_xml_preparedocument @iDoc OUTPUT
			, @xml

		INSERT INTO #tmpStakeLevel_History(StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime)
		SELECT StakeLevelID, GameTypeID
			, CASE WHEN MaxLabel<>'NULL'			THEN MaxLabel ELSE NULL END MaxLabel
			, CASE WHEN ISNUMERIC(MaxStake)=1		THEN MaxStake ELSE NULL END MaxStake
			, CASE WHEN ISNUMERIC(MaxGameStake)=1	THEN MaxGameStake ELSE NULL END MaxGameStake
			, UpdateTime
		FROM OPENXML(@iDoc, '/root/r', 1) WITH (
				StakeLevelID	INT
			,	GameTypeID		INT
			,	MaxLabel		VARCHAR(50)
			,	MaxStake		VARCHAR(50)
			,	MaxGameStake	VARCHAR(100)
			,	UpdateTime		DATETIME
		)
	
		EXEC sp_xml_removedocument @iDoc

		DELETE cslgh
		FROM StakeLevelGroupDetail_History cslgh WITH (ROWLOCK)
			INNER JOIN #tmpStakeLevel_History t 
				ON	t.StakeLevelID	= cslgh.StakeLevelID
				AND t.GameTypeID	= cslgh.GameTypeID
				AND t.UpdateTime	= cslgh.UpdateTime
	END

	IF @Mode=6	--Dep_StakeLevelGroupDetail_History
	BEGIN
		--Parse XML	
		EXEC sp_xml_preparedocument @iDoc OUTPUT
			, @xml

		INSERT INTO #tmpStakeLevel_History(StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime)
		SELECT StakeLevelID, GameTypeID
			, CASE WHEN MaxLabel<>'NULL'			THEN MaxLabel ELSE NULL END MaxLabel
			, CASE WHEN ISNUMERIC(MaxStake)=1		THEN MaxStake ELSE NULL END MaxStake
			, CASE WHEN ISNUMERIC(MaxGameStake)=1	THEN MaxGameStake ELSE NULL END MaxGameStake
			, UpdateTime
		FROM OPENXML(@iDoc, '/root/r', 1) WITH (
				StakeLevelID	INT
			,	GameTypeID		INT
			,	MaxLabel		VARCHAR(50)
			,	MaxStake		VARCHAR(50)
			,	MaxGameStake	VARCHAR(100)
			,	UpdateTime		DATETIME
		)
	
		EXEC sp_xml_removedocument @iDoc

		DELETE cslgh
		FROM Dep_StakeLevelGroupDetail_History cslgh WITH (ROWLOCK)
			INNER JOIN #tmpStakeLevel_History t 
				ON	t.StakeLevelID	= cslgh.StakeLevelID
				AND t.GameTypeID	= cslgh.GameTypeID
				AND t.UpdateTime	= cslgh.UpdateTime
	END

	DROP TABLE #tmpBetSetting_History
	DROP TABLE #tmpStakeLevel_History
END
GO