/*<info serverAlias="DBTP-bodb02" executers="bodbAdminNet" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Task_DetectBet_translog]
(	
	@batchCount INT = 0
	, @maxSequenceId BIGINT = NULL OUTPUT
)
AS
/*	Created by: Max
	Date : 20220525
	Task: Detect player exceeded the bet limit of the Agent's setting [Redmine: #170739]
	DB: DBTP/bodb02
	
	Revisions: 
		- 20220525@Max: Create SP [Redmine: #170739]
		- 20220728@July: Scale out DBTRANS - Change maxTransIdSetting to SequenceIdSetting [Redmine: #175965]
		- 20220923@Max: Tuning [Redmine: #178156]
		- 20220831@July: Include product NG(Happy 5 Linked Game), RNG Keno [Redmine: #170739]
		- 20221028@Max: Detect player exceeded the bet limit of the Agent's setting - Update rule 10 for 2 special bet choices of RNG Keno [Redmine: #179115]
		- 20230619@Max: Remove duplicate transid in case issue with page split sql [Redmine: #00000]

	Param's explanation:		
*/
BEGIN
	SET NOCOUNT ON

	CREATE TABLE #tmp_TransId (
		TransId BIGINT
		, CustId INT
		, sporttype SMALLINT
		, bettype SMALLINT
		, stake MONEY
		, srecommend INT
		, recommend INT
		, isLive BIT
		, transdate DATETIME
		, MaxBet MONEY
		, MaxPerMatch MONEY
		, Remark VARCHAR(100)
		, Gameid3rd NVARCHAR(50)
		, IsInvalid BIT DEFAULT(0)
		, SequenceId BIGINT
	)

	DECLARE @maxSequenceId_setting BIGINT, @SyncHistoryDataLastTime DATETIME
	
	SELECT @maxSequenceId_setting = CONVERT(BIGINT, c.ConfigValue)
	FROM dbo.CustMaxBetSetting_Config c WITH (NOLOCK)
	WHERE c.ConfigName = 'translog'

	SELECT @SyncHistoryDataLastTime = CONVERT(DATETIME, c.ConfigValue)
	FROM dbo.CustMaxBetSetting_Config c WITH (NOLOCK)
	WHERE c.ConfigName = 'SyncHistoryDataLastTime'

	--For normal products
	INSERT INTO #tmp_TransId (TransId, CustId, sporttype, bettype, stake, srecommend, recommend, isLive, transdate, SequenceId)
	SELECT TOP(@batchCount) b.translogid, b.custid, b.productID, b.gameID
		, CASE WHEN b.productID = 202 AND (b.transdesc like '%,33' OR b.transdesc like '%,34') --Special Game of RNG Keno which ChoiceID = 33, 34 (Index Big, Index Small)
			THEN (b.stake / b.custom2)
			ELSE b.stake
		END AS Stake
		, b.srecommend, b.recommend, CASE WHEN b.productID = 168 THEN b.liveindicator ELSE 0 END, b.transdate, b.sequenceid
	FROM dbo.translog b WITH (NOLOCK)
	WHERE b.SequenceID > @maxSequenceId_setting
		AND b.transdate <= DATEADD(MINUTE,-2,@SyncHistoryDataLastTime)
		AND b.statusID NOT IN (101, 102, 103)
		AND b.productID IN (220,222,223,231,169,168,202)
	ORDER BY  b.sequenceid ASC
	-------------------

	--For products which bet limit is min/max per game Round (Virtual Games,..)
	INSERT INTO #tmp_TransId (TransId, CustId, sporttype, bettype, srecommend, recommend, isLive, transdate, Gameid3rd, SequenceId)
	SELECT TOP(@batchCount) b.translogid, b.custid, b.productID, b.gameID, b.srecommend, b.recommend, 0, b.transdate, Gameid3rd, b.sequenceid
	FROM dbo.translog b WITH (NOLOCK)
	WHERE b.SequenceID > @maxSequenceId_setting
		AND b.transdate <= DATEADD(MINUTE,-2,@SyncHistoryDataLastTime)
		AND b.statusID NOT IN (101, 102, 103)
		AND b.productID IN (245)
	ORDER BY  b.sequenceid ASC

	UPDATE c SET c.stake = t.stake
	FROM #tmp_TransId c
		CROSS APPLY (
				SELECT SUM(b.stake) AS stake
				FROM dbo.translog b WITH (NOLOCK)
				WHERE b.Gameid3rd = c.Gameid3rd
					AND b.custid = c.CustId
		)t
	WHERE c.sporttype IN (245)
	---------------------
	--Remove duplicate in case issue with page split
	;WITH CTE
	(
		TransId, 
		DuplicateCount
	)
	AS (SELECT TransId, 
			   ROW_NUMBER() OVER(PARTITION BY TransId
			   ORDER BY TransId) AS DuplicateCount
		FROM #tmp_TransId)
	DELETE FROM CTE
	WHERE DuplicateCount > 1;

	SET @maxSequenceId = (SELECT MAX(SequenceId) FROM #tmp_TransId)

	--Process detect invalid
	EXEC dbo.Task_DetectBet_CustMaxBetSettingSel
	
	INSERT INTO dbo.CustMaxBet_Invalid (TransID, CustID, SportType, BetType, MaxBet, Stake, Remark)
	SELECT t1.TransId, t1.CustId, t1.sporttype, t1.bettype, t1.MaxBet, t1.stake, t1.Gameid3rd
	FROM #tmp_TransId t1
	WHERE t1.IsInvalid = 1

	DROP TABLE #tmp_TransId
END


