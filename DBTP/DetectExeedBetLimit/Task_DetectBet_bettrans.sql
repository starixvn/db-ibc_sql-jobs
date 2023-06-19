/*<info serverAlias="DBTP-bodb02" executers="bodbAdminNet" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Task_DetectBet_bettrans]
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
		- 20220721@Max: Change logic get stake for NG2 [Redmine: #170739]
		- 20220728@July: Scale out DBTRANS - Change maxTransIdSetting to SequenceIdSetting [Redmine: #175965]
		- 20220923@Max: Tuning [Redmine: #178156]
		- 20220831@July: Include product NG(NG, Happy 5) [Redmine: #170739]
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
	WHERE c.ConfigName = 'bettrans'

	SELECT @SyncHistoryDataLastTime = CONVERT(DATETIME, c.ConfigValue)
	FROM dbo.CustMaxBetSetting_Config c WITH (NOLOCK)
	WHERE c.ConfigName = 'SyncHistoryDataLastTime'

	INSERT INTO #tmp_TransId (TransId, CustId, sporttype, bettype, stake, srecommend, recommend, isLive, transdate, SequenceId)
	SELECT TOP(@batchCount) b.transid, b.custid, m.sporttype, b.bettype
		, CASE WHEN m.sporttype IN (213,214,215,217,218) THEN (b.stake/ISNULL(hdp1,1)) ELSE b.stake END AS stake
		, b.srecommend, b.recommend, b.liveindicator, b.transdate, b.sequenceid
	FROM dbo.bettrans b WITH (NOLOCK)
		CROSS APPLY (
			SELECT TOP(1) m.sporttype
			FROM dbo.match m WITH (NOLOCK) 
			WHERE m.matchid = b.matchid
				AND (
						m.sporttype BETWEEN 180 AND 186
						OR m.sporttype BETWEEN 190 AND 197
						OR m.sporttype IN (199)
						OR m.sporttype IN (161,164)
					)

			UNION ALL
			SELECT TOP(1) m.sporttype
			FROM dbo.Match3rd m WITH (NOLOCK) 
			WHERE m.Match3rdId = b.matchid
				AND m.SportType = 175 --Bitcoin

			UNION ALL
			SELECT TOP(1) pt.sporttype
			FROM dbo.SportBettypeMatrix pt WITH (NOLOCK) 
			WHERE pt.BetType = b.bettype
				AND pt.sporttype IN (213,214,215,217,218) --NG2
		)m
	WHERE b.SequenceID > @maxSequenceId_setting
		AND b.transdate <= DATEADD(MINUTE,-2,@SyncHistoryDataLastTime)
		AND b.statusID NOT IN (101, 102, 103)
	ORDER BY  b.sequenceid ASC 

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


