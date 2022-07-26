/*<info serverAlias="DBCUST-CustDB" executers="" isFunction="0" isNested="1"></info>*/

ALTER PROCEDURE [dbo].[Task_DetectBet_DelBetSettingHistory] 
			@Mode			TINYINT,
			@History_List	VARCHAR(MAX)=NULL
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
		,	UpdateTime		DATETIME
	)

	CREATE TABLE #tmpStakeLevel_History (
			StakeLevelID	INT
		,	GameTypeID		INT
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

		INSERT INTO #tmpBetSetting_History(CustID, SportType, BetType, UpdateTime)
		SELECT c, s, b, u
		FROM OPENXML(@iDoc, '/root/r', 1) WITH (
				c	INT
			,	s	SMALLINT
			,	b	INT
			,	u	DATETIME
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

		INSERT INTO #tmpBetSetting_History(CustID, SportType, BetType, UpdateTime)
		SELECT c, s, b, u
		FROM OPENXML(@iDoc, '/root/r', 1) WITH (
				c	INT
			,	s	SMALLINT
			,	b	INT
			,	u	DATETIME
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

		INSERT INTO #tmpStakeLevel_History(StakeLevelID, UpdateTime)
		SELECT sl, u
		FROM OPENXML(@iDoc, '/root/r', 1) WITH (
				sl	INT
			,	u	DATETIME
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

		INSERT INTO #tmpStakeLevel_History(StakeLevelID, UpdateTime)
		SELECT sl, u
		FROM OPENXML(@iDoc, '/root/r', 1) WITH (
				sl	INT
			,	u	DATETIME
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

		INSERT INTO #tmpStakeLevel_History(StakeLevelID, GameTypeID, UpdateTime)
		SELECT sl, gt, u
		FROM OPENXML(@iDoc, '/root/r', 1) WITH (
				sl	INT
			,	gt	INT
			,	u	DATETIME
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

		INSERT INTO #tmpStakeLevel_History(StakeLevelID, GameTypeID, UpdateTime)
		SELECT sl, gt, u
		FROM OPENXML(@iDoc, '/root/r', 1) WITH (
				sl	INT
			,	gt	INT
			,	u	DATETIME
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