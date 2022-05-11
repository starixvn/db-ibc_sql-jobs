/*<info serverAlias="DBCust-CustDB" executers="bodbadminNet,bodbDownlineNet,bodbExtAccNet" isFunction="0" isNested=1></info>*/

ALTER PROCEDURE [dbo].[Task_DetectBet_CustMaxBetHistoryIns] 
		@CustList	VARCHAR(MAX) = '',
		@ErrMsg		NVARCHAR(200)= ''	OUTPUT
AS
/*
	Created: 20220511@Tacy
	Task : Insert history of member bet setting for Credit
	DB: DBCust/CustDB
	Original:

	Revisions:
		- 20220511@Tacy: Initial SP [RedmineID: #170739]

	Param's Explanation:
	• @CustList:
		<root>
			<r CustID= ''1400001''  SportType=''169'' BetType=''3612'' MaxBet=''100''  MaxPerMatch=''2000'' StakeLevelList=''NULL''  UpdateTime=''2022-03-10 04:10:10.000''/>
			<r CustID= ''23700002'' SportType=''176'' BetType=''8201'' MaxBet=''2500'' MaxPerMatch=''NULL'' StakeLevelList=''21136'' UpdateTime=''2022-03-10 04:10:10.000''/>
		</root>
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @xml XML = NULL

	CREATE TABLE #tmpCustList (
			CustID			INT
		,	SportType		SMALLINT
		,	BetType			SMALLINT
		,	MaxBet			MONEY
		,	MaxPerMatch		MONEY
		,	StakeLevelList	VARCHAR(200)
		,	UpdateTime		DATETIME
		,	PRIMARY KEY CLUSTERED (CustID, SportType, BetType, UpdateTime)
	)

	IF @@SERVERNAME NOT IN ('DBCUST','SITDBCUST','DB233','DB230\SQLSERVER2008R2','TESTDBCUST')
		SET @ErrMsg='Server name is invailid.'
		RETURN

	--Check if XML is null or empty
	IF @CustList IS NULL OR @CustList=''
		SET @ErrMsg='Customer list is invalid.'
		RETURN

	SET @xml = CONVERT(XML, @CustList)

	--Parse XML	
	DECLARE @iDoc INT

	EXEC sp_xml_preparedocument @iDoc OUTPUT
		, @xml

	INSERT INTO #tmpCustList(CustID, SportType, BetType, MaxBet, MaxPerMatch, StakeLevelList, UpdateTime)
	SELECT CustID, SportType, BetType
		, CASE WHEN ISNUMERIC(MaxBet)=1			THEN MaxBet ELSE NULL END MaxBet
		, CASE WHEN ISNUMERIC(MaxPerMatch)=1	THEN MaxPerMatch ELSE NULL END MaxPerMatch
		, CASE WHEN ISNUMERIC(StakeLevelList)=1 THEN StakeLevelList ELSE NULL END StakeLevelList
		, UpdateTime
	FROM OPENXML(@iDoc, '/root/r', 1) WITH (
			CustID			INT
		,	SportType		SMALLINT
		,	BetType			SMALLINT
		,	MaxBet			VARCHAR(100)
		,	MaxPerMatch		VARCHAR(100)
		,	StakeLevelList	VARCHAR(200)
		,	UpdateTime		DATETIME
		)
	
	EXEC sp_xml_removedocument @iDoc

	--get MaxBet - StakeLevelList
	IF EXISTS (SELECT 1 FROM #tmpCustList WHERE StakeLevelList IS NOT NULL)
	BEGIN
		WITH csll AS (
			SELECT tc.CustID, SportType, BetType, tc.StakeLevelList
				, MAX(CASE WHEN st.GameGroupID=0 THEN st.MaxStake ELSE stgd.MaxStake END) MaxStake
			FROM #tmpCustList tc 
				CROSS APPLY (SELECT value AS val FROM STRING_SPLIT(tc.StakeLevelList,',')) ss
				INNER JOIN StakeLevel st WITH (NOLOCK) ON st.StakeLevelID = CAST(ss.val AS INT)
				CROSS APPLY (SELECT TOP 1 stg.StakeLevelID, CAST(stg.MaxLabel AS MONEY) AS MaxStake
							 FROM StakeLevelGroupDetail stg WITH (NOLOCK)
							 WHERE stg.StakeLevelID = st.StakeLevelID
							 ORDER BY CAST(stg.MaxLabel AS MONEY) DESC
							 ) stgd
			WHERE tc.StakeLevelList IS NOT NULL
			GROUP BY tc.CustID, SportType, BetType, tc.StakeLevelList
		)
		UPDATE tc
		SET tc.MaxBet = t1.MaxStake
		FROM #tmpCustList tc
			INNER JOIN csll t1 ON t1.CustID	 = tc.CustID
							AND t1.BetType	 = tc.BetType
							AND t1.SportType = tc.SportType
	END

	INSERT INTO CustMaxBetSetting_History 
		  (CustID, SportType, BetType, OldMaxBet, OldMaxPerMatch, StakeLevelList, UpdateTime)
	SELECT CustID, SportType, BetType, MaxBet, MaxPerMatch, StakeLevelList, UpdateTime
	FROM #tmpCustList

	--check Error
	--ROLLBACK
	IF @@ERROR<>0
	BEGIN
		SET @ErrMsg='Insert history of member bet setting failed.'

		DELETE his
		FROM CustMaxBetSetting_History his
			INNER JOIN #tmpCustList t ON t.CustID=his.CustID 
		WHERE his.UpdateTime>=t.UpdateTime

		RETURN
	END

	DROP TABLE #tmpCustList
END
GO