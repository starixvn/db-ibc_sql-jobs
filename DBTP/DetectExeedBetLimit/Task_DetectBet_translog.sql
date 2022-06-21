/*<info serverAlias="DBTP-bodb02" executers="bodbAdminNet" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Task_DetectBet_translog]
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

	CREATE TABLE #tmp_TransId (TransId BIGINT, CustId INT, Username NVARCHAR(100), sporttype SMALLINT, bettype SMALLINT, stake MONEY, srecommend INT, recommend INT, isLive BIT, transdate DATETIME, Gameid3rd NVARCHAR(50))
	CREATE TABLE #tmp_TransId_MaxBet (TransId BIGINT, CustId INT, sporttype SMALLINT, bettype SMALLINT, MaxBet MONEY, MaxPerMatch MONEY)

	CREATE CLUSTERED INDEX CIX_tmp_transId ON #tmp_TransId (TransId)
	CREATE CLUSTERED INDEX CIX_tmp_transId_MaxBet ON #tmp_TransId_MaxBet (TransId)

	DECLARE @maxTransId_setting BIGINT
	
	SELECT @maxTransId_setting = CONVERT(BIGINT, c.ConfigValue)
	FROM dbo.CustMaxBetSetting_Config c WITH (NOLOCK)
	WHERE c.ConfigName = 'translog'

	--For normal products
	INSERT INTO #tmp_TransId (TransId, CustId, Username, sporttype, bettype, stake, srecommend, recommend, isLive, transdate)
	SELECT TOP(@batchCount) b.translogid, b.custid, b.Username, b.productID, b.gameID, b.stake, b.srecommend, b.recommend, 0, b.transdate
	FROM dbo.translog b WITH (NOLOCK)
	WHERE b.translogid > @maxTransId_setting
		AND b.statusID NOT IN (101, 102, 103)
		AND b.productID IN (202,220,222,223,231,169)
	ORDER BY  b.translogid ASC
	-------------------

	--For products which bet limit is min/max per game Round (Virtual Games,..)
	INSERT INTO #tmp_TransId (TransId, CustId, Username, sporttype, bettype, srecommend, recommend, isLive, transdate, Gameid3rd)
	SELECT TOP(@batchCount) b.translogid, b.custid, b.Username, b.productID, b.gameID, b.srecommend, b.recommend, 0, b.transdate, Gameid3rd
	FROM dbo.translog b WITH (NOLOCK)
	WHERE b.translogid > @maxTransId_setting
		AND b.statusID NOT IN (101, 102, 103)
		AND b.productID IN (245)
	ORDER BY  b.translogid ASC

	UPDATE c SET c.stake = t.stake
	FROM #tmp_TransId c
		CROSS APPLY (
				SELECT SUM(b.stake) AS stake
				FROM dbo.translog b WITH (NOLOCK)
				WHERE b.Gameid3rd= c.Gameid3rd
		)t
	---------------------

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
	
	INSERT INTO dbo.CustMaxBet_Invalid (TransID, CustID, SportType, BetType, MaxBet, Stake, Remark)
	SELECT t1.TransId, t1.CustId, t1.sporttype, t1.bettype, t2.MaxBet, t1.stake, t1.Gameid3rd
	FROM #tmp_TransId t1
		INNER JOIN #tmp_TransId_MaxBet t2 ON t2.TransId = t1.TransId
	WHERE t1.stake > ISNULL(t2.MaxBet,0)

	DROP TABLE #tmp_TransId
	DROP TABLE #tmp_TransId_MaxBet
END


