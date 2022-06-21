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

	DECLARE @CustList VARCHAR(MAX) = NULL

	CREATE TABLE #tmp_TransId (TransId BIGINT, CustId INT, Username NVARCHAR(100), sporttype SMALLINT, bettype SMALLINT, stake MONEY, srecommend INT, recommend INT, isLive BIT, transdate DATETIME)
	CREATE TABLE #tmp_TransId_MaxBet (TransId BIGINT, CustId INT, sporttype SMALLINT, bettype SMALLINT, MaxBet MONEY, MaxPerMatch MONEY)

	CREATE CLUSTERED INDEX CIX_tmp_transId ON #tmp_TransId (TransId)
	CREATE CLUSTERED INDEX CIX_tmp_transId_MaxBet ON #tmp_TransId_MaxBet (TransId)

	DECLARE @maxTransId_setting BIGINT
	
	SELECT @maxTransId_setting = CONVERT(BIGINT, c.ConfigValue)
	FROM dbo.CustMaxBetSetting_Config c WITH (NOLOCK)
	WHERE c.ConfigName = 'bettrans'

	INSERT INTO #tmp_TransId (TransId, CustId, Username, sporttype, bettype, stake, srecommend, recommend, isLive, transdate)
	SELECT TOP(@batchCount) b.transid, b.custid, b.Username, m.sporttype, b.bettype, b.stake, b.srecommend, b.recommend, b.liveindicator, b.transdate
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
		AND b.statusID NOT IN (101, 102, 103)
	ORDER BY  b.transid ASC 

	SET @maxTransId = (SELECT MAX(TransId) FROM #tmp_TransId)

	SET @CustList = (
			SELECT t.CustId AS '@c'
				,t.sporttype AS '@s'
				,t.bettype AS '@b'
				,t.TransId AS '@tid'
				,t.transdate AS '@t'
				,t.srecommend AS '@sr'
				,t.recommend AS '@r'
				,t.isLive AS '@il'
			FROM #tmp_TransId t
			FOR XML PATH('r'), ROOT('root')
		)

	INSERT INTO #tmp_TransId_MaxBet (CustId, TransId, sporttype, bettype, MaxBet, MaxPerMatch)
	EXEC dbo.Task_DetectBet_CustMaxBetSettingSel
		@CustList = @CustList
	
	INSERT INTO dbo.CustMaxBet_Invalid (TransID, CustID, SportType, BetType, MaxBet, Stake)
	SELECT t1.TransId, t1.CustId, t1.sporttype, t1.bettype, t2.MaxBet, t1.stake
	FROM #tmp_TransId t1
		OUTER APPLY(
			SELECT t2.MaxBet
			FROM #tmp_TransId_MaxBet t2 
			WHERE t2.TransId = t1.TransId
		)t2
	WHERE t1.stake > ISNULL(t2.MaxBet,0)

	DROP TABLE #tmp_TransId
	DROP TABLE #tmp_TransId_MaxBet
END


