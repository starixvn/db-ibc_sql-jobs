/*<info serverAlias="DBAGE-bodb_AGE" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_CDC_bettrans_Metric_Capture]
AS
/*
	Created by: 20231201@Bobby
	Task: 153357 - Alpha - CDC bettrans_compact - check SUMDATA Notify
	DB: DBAGE.bodb_AGE
	Revisions:
		- 20231201@Bobby:  Implement bettrans_compact Redmine: [#153357]
*/
BEGIN

	SET NOCOUNT ON;

	DECLARE @maxPoolRow INT = 100, @minExecCount INT = 50, @rolloverRowId BIGINT;
	DECLARE @lastRowId BIGINT, @lastRun DATETIME;

	SELECT TOP(1) 
		@lastRowId = JSON_VALUE(VValue, '$.lastRowId')
		,@lastRun = JSON_VALUE(VValue, '$.lastRun')
	FROM bodb_AGE.dbo.SystemSettings WITH(NOLOCK)
	WHERE VName='Age_cdc_bettrans_compact';

	SELECT TOP(1) @rolloverRowId = rowid
	FROM [dbo].[cdc_bettrans_metric_counter] WITH(NOLOCK)
	WHERE rowid <= @maxPoolRow
	ORDER BY creation_time ASC;

	;WITH CTE_tmpLog AS (
		SELECT @lastRun AS lastRun, @lastRowId AS lastRowId
			, ISNULL(cre.minRowId, @lastRowId) AS minRowId
			, ISNULL(cre.maxRowId, @lastRowId) AS maxRowId
			, ISNULL(cre.txnLogCount, 0) AS txnLogCount
			, ISNULL(totalLogCount, 0) AS totalLogCount
			, IIF(ISNULL(maxCreRowId,0) = 0, @lastRowId, maxCreRowId) AS maxCreRowId
			, IIF(ISNULL(minCreRowId,0) = 0, @lastRowId, minCreRowId) AS minCreRowId
		FROM  (
			SELECT MIN(rowId) AS minRowId
				, MAX(rowId) AS maxRowId
				, COUNT(1) AS totalLogCount
				, SUM(IIF(cs.custid IS NULL,1,0)) AS txnLogCount
				, MAX(IIF(cs.custid IS NULL,rowId,0)) AS maxCreRowId
				, MIN(IIF(cs.custid IS NULL,rowId,0)) AS minCreRowId
			FROM dbo.cdc_bettrans cdc WITH(NOLOCK)
			LEFT JOIN bodb02.dbo.Dep_CustSuper cs WITH(NOLOCK) ON cs.custid =  cdc.srecommend
			WHERE rowId > @lastRowId
		) AS cre
	),
	CTE_logStats AS (
		SELECT t.lastRun, t.lastRowId, t.minRowId, t.maxCreRowId, t.minCreRowId
			, t.maxRowId, t.txnLogCount, t.totalLogCount
			, DATEDIFF(MILLISECOND, MIN(IIF(cdc.rowid = t.maxRowId AND t.maxRowId <> t.minRowId, cdc.actiondate, GETDATE())), MIN(IIF(cdc.rowid = t.maxRowId AND t.maxRowId <> t.minRowId, cdc.createddatetime, GETDATE()))) AS cdcPullTime
			, DATEDIFF(MILLISECOND, MIN(IIF(cdc.rowid = t.maxRowId AND t.maxRowId <> t.minRowId, cdc.createddatetime, GETDATE())), GETDATE()) AS cdcBetTime
			, DATEDIFF(MILLISECOND, MIN(IIF(cdc.rowid = t.minCreRowId, cdc.actiondate, GETDATE())), MIN(IIF(cdc.rowid = t.maxCreRowId, cdc.actiondate, GETDATE()))) AS compactTime
		FROM dbo.cdc_bettrans cdc WITH(NOLOCK), CTE_tmpLog t 
		WHERE cdc.rowId IN (t.minRowId, t.maxRowId, t.minCreRowId, t.maxCreRowId)
		GROUP BY t.lastRun, t.lastRowId, t.minRowId, t.maxRowId, t.txnLogCount,t.totalLogCount, t.maxCreRowId, t.minCreRowId
	)
	UPDATE TOP(1) tg WITH(ROWLOCK, UPDLOCK)
	SET tg.[compact_latency] = pl.compactTime
		,tg.[compact_delayJob] = DATEDIFF(SECOND, pl.lastRun, GETDATE())
		,tg.[compact_txnLog] = pl.txnLogCount
		,tg.[cdc_pull_latency] = pl.cdcPullTime
		,tg.[cdc_bet_latency] = pl.cdcBetTime
		,tg.[creation_time] = GETDATE()
		,tg.[cdc_min_rowid] = pl.minRowId
		,tg.[cdc_max_rowid] = pl.maxRowId
	FROM [dbo].[cdc_bettrans_metric_counter] tg
	CROSS APPLY CTE_logStats pl 
	WHERE tg.rowid = @rolloverRowId 
	;

	-- SUM AVG by time range 100/10s
	DECLARE @timeRangeToAVG DATETIME = DATEADD(SECOND, -30, GETDATE())
		,@lastAVGTime DATETIME;

	SELECT @lastAVGTime = MAX(creation_time)--- last AVG creation_time
	FROM dbo.cdc_bettrans_metric_counter WITH(NOLOCK)
	WHERE creation_time > @timeRangeToAVG AND is_avg = 1;

	IF (@lastAVGTime IS NULL) --> 1st time RUN
	BEGIN
		SELECT @lastAVGTime = MIN(creation_time)
		FROM dbo.cdc_bettrans_metric_counter WITH(NOLOCK)
		WHERE rowid <= @maxPoolRow
	END

	;WITH CTE_statsAVG AS (
		SELECT AVG([compact_latency])	AS [compact_latency]
			, AVG([compact_delayJob])	AS [compact_delayJob]
			, AVG([compact_txnLog])		AS [compact_txnLog]
			, AVG([cdc_pull_latency])	AS [cdc_pull_latency]
			, AVG([cdc_bet_latency])	AS [cdc_bet_latency]
			, MIN([cdc_min_rowid])		AS [cdc_min_rowid]
			, MAX([cdc_max_rowid])		AS [cdc_max_rowid]
		FROM [dbo].[cdc_bettrans_metric_counter] WITH(NOLOCK)
		WHERE creation_time > @lastAVGTime AND is_avg = 0
		HAVING COUNT(1) >= @minExecCount
	)
	INSERT INTO [dbo].[cdc_bettrans_metric_counter](
		[compact_latency]
		,[compact_delayJob]
		,[compact_txnLog]
		,[cdc_pull_latency]
		,[cdc_bet_latency]
		,[creation_time]
		,[is_avg]
		,[cdc_min_rowid]
		,[cdc_max_rowid]
	)
	SELECT [compact_latency]
		,[compact_delayJob]
		,[compact_txnLog]
		,[cdc_pull_latency]
		,[cdc_bet_latency]
		,GETDATE() AS creation_time
		,1 AS [is_avg]
		,[cdc_min_rowid]
		,[cdc_max_rowid]
	FROM CTE_statsAVG
END
GO