/*<info serverAlias="DBCust-CustDB" executers="bodbadminNet,bodbDownlineNet,bodbExtAccNet" isFunction="0" isNested="1"></info>*/

ALTER PROCEDURE [dbo].[Task_DetectBet_StakeLevelHistory_Insert] 
		@SettingList	VARCHAR(MAX) = '',
		@IsGroup		BIT,
		@ErrMsg			NVARCHAR(200)= ''	OUTPUT
AS
/*
	Created: 20220520@Tacy
	Task : Insert history of global bet setting for Credit
	DB: DBCust/CustDB
	Original:

	Revisions:
		- 20220520@Tacy: Initial SP [RedmineID: #170739]

	Param's Explanation:
	• @SettingList:
		<root>
			<r StakeLevelID= ''1400001'' GameTypeID=''3612'' MaxLabel=''2000'' MaxStake=''2000'' MaxGameStake=''2000'' UpdateTime=''2022-03-10 04:10:10.000''/>
			<r StakeLevelID= ''1400002'' GameTypeID=''3612'' MaxLabel=''2000'' MaxStake=''2000'' MaxGameStake=''NULL'' UpdateTime=''2022-03-10 04:10:10.000''/>
		</root>
*/
BEGIN
	IF @@SERVERNAME NOT IN ('DBCUST','SITDBCUST','DB233','DB230\SQLSERVER2008R2','TESTDBCUST')
	BEGIN
		SET @ErrMsg='Server name is invailid.'
		RETURN
	END

	SET NOCOUNT ON

	DECLARE @XML XML

	CREATE TABLE #tmpSettingList (
			StakeLevelID	INT
		,	GameTypeID		INT
		,	MaxLabel		NVARCHAR(50)
		,	MaxStake		DECIMAL(19,8)
		,	MaxGameStake	DECIMAL(19,8)
		,	UpdateTime		DATETIME
		,	IsGroup			BIT
		,	PRIMARY KEY CLUSTERED (StakeLevelID, GameTypeID, UpdateTime)
	)

	--Check if XML is null or empty
	IF @SettingList IS NULL OR @SettingList=''
	BEGIN
		SET @ErrMsg='Setting list is invalid.'
		RETURN
	END

	SET @xml = CONVERT(XML, @SettingList)

	--Parse XML	
	DECLARE @iDoc INT

	EXEC sp_xml_preparedocument @iDoc OUTPUT
		, @xml

	INSERT INTO #tmpSettingList(StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, IsGroup, UpdateTime)
	SELECT StakeLevelID, GameTypeID
		, CASE WHEN MaxLabel<>'NULL'			THEN MaxLabel		ELSE NULL END MaxLabel
		, CASE WHEN ISNUMERIC(MaxStake)=1		THEN MaxStake		ELSE NULL END MaxStake
		, CASE WHEN ISNUMERIC(MaxGameStake)=1	THEN MaxGameStake	ELSE NULL END MaxGameStake
		, @IsGroup
		, UpdateTime
	FROM OPENXML(@iDoc, '/root/r', 1) WITH (
			StakeLevelID	INT
		,	GameTypeID		INT
		,	MaxLabel		VARCHAR(50)
		,	MaxStake		VARCHAR(50)
		,	MaxGameStake	VARCHAR(50)
		,	UpdateTime		DATETIME
		)
	
	EXEC sp_xml_removedocument @iDoc

	IF @IsGroup=0
	BEGIN
		INSERT INTO StakeLevel_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, UpdateTime)
		SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, UpdateTime
		FROM #tmpSettingList
	END
	ELSE
	BEGIN
		INSERT INTO StakeLevelGroupDetail_History (StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime)
		SELECT StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime
		FROM #tmpSettingList
	END


	--ROLLBACK
	IF @@ERROR<>0
	BEGIN
		SET @ErrMsg='Insert history of global bet setting failed.'

		IF @IsGroup=0
		BEGIN
			DELETE slh
			FROM StakeLevel_History slh
				INNER JOIN #tmpSettingList t ON t.StakeLevelID=slh.StakeLevelID 
											AND t.UpdateTime=slh.UpdateTime
		END
		ELSE
		BEGIN
			DELETE slgh
			FROM StakeLevelGroupDetail_History slgh
				INNER JOIN #tmpSettingList t ON t.StakeLevelID=slgh.StakeLevelID 
											AND t.GameTypeID=slgh.GameTypeID
											AND t.UpdateTime=slgh.UpdateTime
		END

		RETURN
	END

	DROP TABLE #tmpSettingList
END
GO