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
	SELECT TOP(@batchCount) b.translogid, b.custid, b.productID, b.gameID, b.stake, b.srecommend, b.recommend, 0, b.transdate, b.sequenceid
	FROM dbo.translog b WITH (NOLOCK)
	WHERE b.SequenceID > @maxSequenceId_setting
		AND b.transdate <= DATEADD(MINUTE,-2,@SyncHistoryDataLastTime)
		AND b.statusID NOT IN (101, 102, 103)
		AND b.productID IN (220,222,223,231,169)
	ORDER BY  b.translogid ASC
	-------------------

	--For products which bet limit is min/max per game Round (Virtual Games,..)
	INSERT INTO #tmp_TransId (TransId, CustId, sporttype, bettype, srecommend, recommend, isLive, transdate, Gameid3rd, SequenceId)
	SELECT TOP(@batchCount) b.translogid, b.custid, b.productID, b.gameID, b.srecommend, b.recommend, 0, b.transdate, Gameid3rd, b.sequenceid
	FROM dbo.translog b WITH (NOLOCK)
	WHERE b.SequenceID > @maxSequenceId_setting
		AND b.transdate <= DATEADD(MINUTE,-2,@SyncHistoryDataLastTime)
		AND b.statusID NOT IN (101, 102, 103)
		AND b.productID IN (245)
	ORDER BY  b.translogid ASC

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

	SET @maxSequenceId = (SELECT MAX(SequenceId) FROM #tmp_TransId)

	--Process detect invalid
	EXEC dbo.Task_DetectBet_CustMaxBetSettingSel
	
	INSERT INTO dbo.CustMaxBet_Invalid (TransID, CustID, SportType, BetType, MaxBet, Stake)
	SELECT t1.TransId, t1.CustId, t1.sporttype, t1.bettype, t1.MaxBet, t1.stake
	FROM #tmp_TransId t1
	WHERE t1.IsInvalid = 1

	DROP TABLE #tmp_TransId
END


