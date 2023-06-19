/*<info serverAlias="DBTP-bodb02" executers="bodbAdminNet" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Task_DetectBet_bettransLC]
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
	WHERE c.ConfigName = 'bettransLC'

	SELECT @SyncHistoryDataLastTime = CONVERT(DATETIME, c.ConfigValue)
	FROM dbo.CustMaxBetSetting_Config c WITH (NOLOCK)
	WHERE c.ConfigName = 'SyncHistoryDataLastTime'

	INSERT INTO #tmp_TransId (TransId, CustId, sporttype, bettype, stake, srecommend, recommend, isLive, transdate, SequenceId)
	SELECT TOP(@batchCount) b.transid, b.custid, b.productID, b.gameID, b.stake, b.srecommend, b.recommend, 0, b.transdate, b.sequenceid
	FROM dbo.bettransLC b WITH (NOLOCK)
	WHERE b.SequenceID > @maxSequenceId_setting
		AND b.transdate <= DATEADD(MINUTE,-2,@SyncHistoryDataLastTime)
		AND b.statusID NOT IN (101, 102, 103)
		AND b.productID IN (211,243,242,233,225,239,170,176)
	ORDER BY b.sequenceid ASC

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
	
	INSERT INTO dbo.CustMaxBet_Invalid (TransID, CustID, SportType, BetType, MaxBet, Stake)
	SELECT t1.TransId, t1.CustId, t1.sporttype, t1.bettype, t1.MaxBet, t1.stake
	FROM #tmp_TransId t1
	WHERE t1.IsInvalid = 1

	DROP TABLE #tmp_TransId
END


