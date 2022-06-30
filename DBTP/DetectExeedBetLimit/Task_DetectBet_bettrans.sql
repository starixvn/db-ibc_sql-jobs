/*<info serverAlias="DBTP-bodb02" executers="bodbAdminNet" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Task_DetectBet_bettrans]
(	
	@batchCount INT = 0
	, @maxTransId BIGINT = NULL OUTPUT
)
AS
/*	Created by: Max
	Date : 20220525
	Task: Detect player exceeded the bet limit of the Agent's setting [Redmine: #170739]
	DB: DBTP/bodb02
	
	Revisions: 
		- 20220525@Max: Create SP [Redmine: #170739]
	
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
	)

	DECLARE @maxTransId_setting BIGINT, @SyncHistoryDataLastTime DATETIME
	
	SELECT @maxTransId_setting = CONVERT(BIGINT, c.ConfigValue)
	FROM dbo.CustMaxBetSetting_Config c WITH (NOLOCK)
	WHERE c.ConfigName = 'bettrans'

	SELECT @SyncHistoryDataLastTime = CONVERT(DATETIME, c.ConfigValue)
	FROM dbo.CustMaxBetSetting_Config c WITH (NOLOCK)
	WHERE c.ConfigName = 'SyncHistoryDataLastTime'

	INSERT INTO #tmp_TransId (TransId, CustId, sporttype, bettype, stake, srecommend, recommend, isLive, transdate)
	SELECT TOP(@batchCount) b.transid, b.custid, m.sporttype, b.bettype, b.stake, b.srecommend, b.recommend, b.liveindicator, b.transdate
	FROM dbo.bettrans b WITH (NOLOCK)
		CROSS APPLY (
			SELECT m.sporttype
			FROM dbo.match m WITH (NOLOCK) 
			WHERE m.matchid = b.matchid
				AND (
						m.sporttype BETWEEN 180 AND 186
						OR m.sporttype BETWEEN 190 AND 197
						OR m.sporttype IN (213,214,215,217,218,199)
					)

			UNION ALL
			SELECT m.sporttype
			FROM dbo.Match3rd m WITH (NOLOCK) 
			WHERE m.Match3rdId = b.matchid
				AND m.SportType = 175 --Bitcoin
		)m
	WHERE b.transid > @maxTransId_setting
		AND b.transdate <= @SyncHistoryDataLastTime
		AND b.statusID NOT IN (101, 102, 103)
	ORDER BY  b.transid ASC 

	SET @maxTransId = (SELECT MAX(TransId) FROM #tmp_TransId)

	--Process detect invalid
	EXEC dbo.Task_DetectBet_CustMaxBetSettingSel
	
	INSERT INTO dbo.CustMaxBet_Invalid (TransID, CustID, SportType, BetType, MaxBet, Stake)
	SELECT t1.TransId, t1.CustId, t1.sporttype, t1.bettype, t1.MaxBet, t1.stake
	FROM #tmp_TransId t1
	WHERE t1.IsInvalid = 1

	DROP TABLE #tmp_TransId
END


