/*<info serverAlias="DBTP-bodb02" executers="bodbAdminNet" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Task_DetectBet_bettransRnG]
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
		- 20220722@Max: Exclude some bettypes [Redmine: #170739]
		- 20220728@July: Scale out DBTRANS - Change maxTransIdSetting to SequenceIdSetting [Redmine: #175965]
		- 20220923@Max: Tuning [Redmine: #178156]
		- 20220830@July: Include product SEAL Entertainment [Redmine: #177003]

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
	WHERE c.ConfigName = 'bettransRnG'

	SELECT @SyncHistoryDataLastTime = CONVERT(DATETIME, c.ConfigValue)
	FROM dbo.CustMaxBetSetting_Config c WITH (NOLOCK)
	WHERE c.ConfigName = 'SyncHistoryDataLastTime'

	INSERT INTO #tmp_TransId (TransId, CustId, sporttype, bettype, stake, srecommend, recommend, isLive, transdate, Remark, SequenceId)
	SELECT TOP(@batchCount) b.transid, b.custid, b.productID, b.gameID, b.stake, b.srecommend, b.recommend, 0, b.transdate
		, CASE WHEN bt.typedesc = 'BuyBonus' THEN '1' ELSE NULL END
		, b.sequenceid
	FROM dbo.bettransRnG b WITH (NOLOCK)
		INNER JOIN dbo.bettype bt WITH (NOLOCK) ON bt.typeid = b.gameID
	WHERE b.SequenceID > @maxSequenceId_setting
		AND b.transdate <= DATEADD(MINUTE,-2,@SyncHistoryDataLastTime)
		AND b.statusID NOT IN (101, 102, 103)
		AND b.productID IN (208,209,212,248,165,247,232,234,237,238,167,172,174,150,200,224,171,173,156)
	ORDER BY  b.sequenceid ASC

	SET @maxSequenceId = (SELECT MAX(SequenceId) FROM #tmp_TransId)

	--Remove unsupport deposit ticket
	DELETE b
	FROM #tmp_TransId b
		INNER JOIN Dep_CustSuper s WITH (NOLOCK) ON s.custid = b.srecommend
	WHERE b.sporttype IN (247) --SG
		AND b.bettype IN (4326, 4385, 4386)

	--Remove unsupport bettype of SABA.games, Vgaming, Saba Casino, Macau Games
	DELETE b
	FROM #tmp_TransId b
	WHERE b.sporttype IN (208,209,212,150,200,171,173)
		AND b.bettype IN (1650,1652,3836,3837,2105,2120,2104,4004)

	--Process detect invalid
	EXEC dbo.Task_DetectBet_CustMaxBetSettingSel
	
	INSERT INTO dbo.CustMaxBet_Invalid (TransID, CustID, SportType, BetType, MaxBet, Stake, Remark)
	SELECT t1.TransId, t1.CustId, t1.sporttype, t1.bettype, t1.MaxBet, t1.stake, t1.Remark
	FROM #tmp_TransId t1
	WHERE t1.IsInvalid = 1

	DROP TABLE #tmp_TransId
END


