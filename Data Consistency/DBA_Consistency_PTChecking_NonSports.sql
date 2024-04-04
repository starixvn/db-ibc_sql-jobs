/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_PTChecking_NonSports]
	@tablename		VARCHAR(50)		= NULL
	,@ErrCode		INT				= 0		OUTPUT
	,@ErrMsg		VARCHAR(MAX)	= ''	OUTPUT 
	,@SampleData	VARCHAR(MAX)	= ''	OUTPUT
AS
/*
	Created: 20240312@July
	Task: Check PT rules of customer for 3rd products
	DB: DBCONSISTENCY/bodb_Consistency

	Revisions: 
		- 20240312@July: Create new SP [Redmine:#200454]
	
	Param's Expanation:
		Apply for deposit only.
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @transId		VARCHAR(MAX)
		  , @yesterday		SMALLDATETIME 
		  , @batch			INT = 100

	SET @transId = ''
	SET @yesterday = DATEADD(DAY,-1,CAST(GETDATE() AS DATE))
	
	CREATE TABLE #tmp_TransId (
		 TransId BIGINT
		, CustId INT
		, sporttype SMALLINT
		, bettype SMALLINT
		, srecommend INT
		, isLive BIT
		, apositiontaking SMALLMONEY
	)

	CREATE TABLE #tmp_CustId (
		  CustId INT
		, sporttype SMALLINT
		, bettype SMALLINT
		, isLive BIT
		, apositiontaking SMALLMONEY
	)
	
	IF  @tablename = 'bettrans'
	BEGIN	
		DECLARE @tmBettypes TABLE (Bettype SMALLINT, SportType SMALLINT)
		INSERT INTO @tmBettypes (Bettype, SportType)
		SELECT	DISTINCT BetType, SportType
		FROM bodb02.dbo.SportBettypeMatrix WITH(NOLOCK)
		WHERE RefTable = 0
			AND IsTest = 0 AND Enabled = 1
			AND ProductID NOT IN (1) -- NOT Sportbook
		
		INSERT INTO #tmp_TransId (TransId, CustId, sporttype, bettype, srecommend, isLive, apositiontaking)
		SELECT b.transid, b.custid, m.sporttype, b.bettype, b.srecommend, b.liveindicator, b.apositiontaking
		FROM bodb02.dbo.bettrans b WITH (NOLOCK)
			CROSS APPLY (
				SELECT TOP(1) m.sporttype
				FROM bodb02.dbo.match m WITH (NOLOCK) 
				WHERE m.matchid = b.matchid

				UNION ALL

				SELECT TOP(1) m.sporttype
				FROM bodb02.dbo.Match3rd m WITH (NOLOCK) 
				WHERE m.Match3rdId = b.matchid
					AND m.SportType = 175 --Bitcoin
			)m
			INNER JOIN @tmBettypes bt ON b.bettype = bt.Bettype AND m.sporttype = bt.SportType
		WHERE b.winlostdate = @yesterday
		    AND EXISTS (SELECT TOP 1 1 FROM bodb02.dbo.Dep_CustSuper d WITH (NOLOCK) WHERE d.custid = b.srecommend)
	END
	IF  @tablename = 'bettransLC'
	BEGIN	
		INSERT INTO #tmp_TransId (TransId, CustId, sporttype, bettype, srecommend, isLive, apositiontaking)
		SELECT b.transid, b.custid, b.productID, b.gameID, b.srecommend, 0, b.apositiontaking
		FROM bodb02.dbo.bettransLC b WITH (NOLOCK)
		WHERE b.winlostdate = @yesterday
		    AND EXISTS (SELECT TOP 1 1 FROM bodb02.dbo.Dep_CustSuper d WITH (NOLOCK) WHERE d.custid = b.srecommend)
	END
	IF @tablename = 'bettransRNG'
	BEGIN
		INSERT INTO #tmp_TransId (TransId, CustId, sporttype, bettype, srecommend, isLive, apositiontaking)
		SELECT b.transid, b.custid, b.productID, b.gameID, b.srecommend, 0, b.apositiontaking
		FROM bodb02.dbo.bettransRNG b WITH (NOLOCK)
		WHERE b.winlostdate = @yesterday
		    AND EXISTS (SELECT TOP 1 1 FROM bodb02.dbo.Dep_CustSuper d WITH (NOLOCK) WHERE d.custid = b.srecommend)
	END

	INSERT INTO #tmp_CustId (CustId, sporttype, bettype, isLive, apositiontaking)
	SELECT DISTINCT CustId, sporttype, bettype, isLive, apositiontaking
	FROM #tmp_TransId

	;WITH CTE_WrongPTSetting
	 AS (
		SELECT TOP (@batch) c.CustId, c.sporttype, c.bettype, c.isLive, c.apositiontaking
		FROM #tmp_CustId c
		CROSS APPLY bodb02.[dbo].[f_Dep_CustPTSetting_Select] (c.CustId, c.sporttype, c.bettype, c.isLive) f
		WHERE  c.apositiontaking <> (f.AgentPT/100)
	)
	SELECT @transId = STRING_AGG(CONVERT(VARCHAR(MAX),tmp.transId), ',') 
	FROM (
		SELECT TOP (@batch) t.TransId
		FROM CTE_WrongPTSetting c
		INNER JOIN #tmp_TransId t 
			ON  c.CustId = t.CustId 
			AND c.sporttype = t.sporttype 
			AND c.bettype = t.bettype 
			AND c.isLive = t.isLive
			AND c.apositiontaking = t.apositiontaking
		)tmp
		
	IF @transId <> ''
	BEGIN
		SELECT	@transId = @transId
				,@ErrCode = 100
				,@ErrMsg = 'Wrong PT setting ticket vs PT setting of customer for 3rd products.' 
				,@SampleData = @tablename + '.TransId in (' + @transId + ')'
	END

	DROP TABLE #tmp_TransId		
	DROP TABLE #tmp_CustId
END
GO
