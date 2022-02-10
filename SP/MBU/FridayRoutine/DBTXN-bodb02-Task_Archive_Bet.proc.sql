SET	QUOTED_IDENTIFIER ON;
SET	ANSI_NULLS ON;
GO
ALTER PROCEDURE [dbo].[Task_Archive_Bet]
(
	@winlostdate DATETIME = NULL,
	@StartDate DATETIME =  NULL,
	@EndDate DATETIME = NULL,
	@DeletedTarget VARCHAR(100) = '',
	@Action			VARCHAR(10)		= 'delete' -- delete / subtask	
)
AS
/*
	Created: 20171017@Lukas
	Task: delete data on table14 

	Revisions:
		- 20180725@Billy:	Change the way of deleting data of IP2Country tables - [Redmine: #98857]
		- 20190704@Billy:	Add [MarkedTransaction] to Friday Routine - [Redmine: #115199]
		- 20200728@Brice:	Add parameter @Action, Add 13 tables - [Redmine: #111093]
		- 20210225@Max: [TVS] Remove archived data [Redmine: #150524]
		- 20210625@Helen: [TVS] Perfomance tuning for archived process [Redmine: #157539]
		- 20210701@Helen: [TVS] Duplicate issue [Redmine: #157539]
		- 20210727@Patrick: Update Job to Support Parlay Range up to 3 Weeks [Redmine: #156498]
		- 20220121@Max: MBU - Clean up Cash Out Selling [Redmine: #167802]
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE	@WaitFor	VARCHAR(50);

	IF @Action = 'delete'
	BEGIN
		CREATE TABLE #DeletedList (id BIGINT PRIMARY KEY CLUSTERED, IsDone BIT)

		IF @DeletedTarget = 'betParlayDetail'
		BEGIN

			CREATE TABLE #__refno_parlaydetail (refno BIGINT, cnt INT)
			INSERT INTO #__refno_parlaydetail(refno, cnt)
			SELECT b.refno, COUNT(1) cnt
			FROM dbo.betparlaydetail b WITH(NOLOCK)
			WHERE winlostdate <= DATEADD(DAY, -14, @winlostdate)
			GROUP BY b.refno

			CREATE CLUSTERED INDEX cix_#__refno_parlaydetail ON #__refno_parlaydetail(refno)

			--remove refno which is still staying in bettrans
			;WITH __refno_bettrans AS (
				SELECT b.refno
				FROM dbo.bettrans b WITH(NOLOCK)
				WHERE matchid = 29
			)
			DELETE t 
			FROM #__refno_parlaydetail t
			WHERE EXISTS (SELECT TOP 1 1 FROM __refno_bettrans tt WHERE t.refno = tt.refno)
			
			--remove refno which is still staying in bettrans14
			;WITH __refno_bettrans14 AS (
				SELECT b.refno
				FROM dbo.bettrans14 b WITH(NOLOCK)
				WHERE matchid = 29 AND b.winlostdate > @winlostdate
			)
			DELETE t 
			FROM #__refno_parlaydetail t
			WHERE EXISTS (SELECT TOP 1 1 FROM __refno_bettrans14 tt WHERE t.refno = tt.refno)

			SELECT IDENTITY(INT,1,1) id, b.refno, SUM(cnt) cnt, 5000/SUM(cnt) AS batch_size
			INTO #tmp
			FROM #__refno_parlaydetail b
			GROUP BY b.refno 
			ORDER BY cnt DESC

			CREATE CLUSTERED INDEX CIX_id_TMP ON #tmp(id)
			DECLARE @rc INT,@i INT, @topn INT, @refnos VARCHAR(MAX) = ''
			SELECT @rc = MAX(id) FROM #tmp  

			SET @i = 1
			WHILE @i <= @rc 
			BEGIN	
				SELECT @topn = batch_size
				FROM #tmp
				WHERE id = @i 

				IF @topn = 0 OR @topn IS NULL
					SET @topn = 1

				SET @refnos = NULL
				SELECT TOP(@topn) @refnos = COALESCE(@refnos + '^' + CAST(refno AS VARCHAR(50)), CAST(refno AS VARCHAR(50)))
				FROM #tmp
				WHERE id >= @i 
				ORDER BY id ASC 

				EXEC dbo.ExecRep_09 @recommend = 0, @winlostdate = @winlostdate, @parlay = 29, @tableName = 'betParlayDetail', @refnos = @refnos
				SET @i = @i + @topn
			END 
			DROP TABLE #tmp
			DROP TABLE #__refno_parlaydetail
			RETURN
		END 
		ELSE IF @DeletedTarget = 'betParlayResult'
		BEGIN
			-- call execRep SP
			EXEC dbo.ExecRep_09 @recommend = 0, @winlostdate = @winlostdate, @parlay = 29, @tableName = 'betParlayResult'
		END

		ELSE IF	@DeletedTarget = 'Task_bettrans14_IP2Country'
		BEGIN;
			WHILE 0 = 0
			BEGIN;
				DELETE	TOP(10000)
				FROM	dbo.Task_bettrans14_IP2Country WITH (ROWLOCK) 
				WHERE	winlostdate <= @winlostdate;

				IF	@@ROWCOUNT = 0
					BREAK;

				-- Dynamic Delay Time --
				SELECT	@WaitFor = dbo.f_BU_GetDelayTime('IP2Country');
				WAITFOR DELAY @WaitFor;
			END;

			RETURN;
		END;

		ELSE IF	@DeletedTarget = 'Task_bettransRNG14_IP2Country'
		BEGIN;
			WHILE 0 = 0
			BEGIN;
				DELETE	TOP(10000)
				FROM	dbo.Task_bettransRNG14_IP2Country WITH (ROWLOCK) 
				WHERE	winlostdate <= @winlostdate;

				IF	@@ROWCOUNT = 0
					BREAK;

				-- Dynamic Delay Time --
				SELECT	@WaitFor = dbo.f_BU_GetDelayTime('IP2Country');
				WAITFOR DELAY @WaitFor;
			END;

			RETURN;
		END;

		ELSE IF	@DeletedTarget = 'Task_bettransLC14_IP2Country'
		BEGIN;
			WHILE 0 = 0
			BEGIN;
				DELETE	TOP(10000)
				FROM	dbo.Task_bettransLC14_IP2Country WITH (ROWLOCK) 
				WHERE	winlostdate <= @winlostdate;

				IF	@@ROWCOUNT = 0
					BREAK;

				-- Dynamic Delay Time --
				SELECT	@WaitFor = dbo.f_BU_GetDelayTime('IP2Country');
				WAITFOR DELAY @WaitFor;
			END;

			RETURN;
		END;

		ELSE IF	@DeletedTarget = 'MarkedTransaction'
		BEGIN;
			DECLARE	@transList AS TABLE (
						TransId		BIGINT,
						MatchId		INT
					);

			DECLARE	@transDel AS TABLE (
						TransId		BIGINT,
						MatchId		INT
					);

			DECLARE	@transDelStr	VARCHAR(MAX);

			INSERT INTO	@transList (TransId, MatchId)
			SELECT	tbl.transid, tbl.MatchId
			FROM		dbo.MarkedTransaction AS tbl WITH (NOLOCK)
			INNER JOIN	dbo.match14 AS m14 WITH (NOLOCK)
					ON	tbl.MatchId = m14.matchid
			WHERE	m14.eventdate <= @winlostdate;

			WHILE	0 = 0
			BEGIN;
				DELETE	@transDel;

				DELETE	TOP(200) @transList
				OUTPUT	Deleted.TransId, deleted.MatchId
				INTO	@transDel (TransId,MatchId);

				IF	@@ROWCOUNT = 0
					BREAK;

				SELECT @transDelStr = (SELECT	t.TransId AS '@transid'
										,t.MatchId AS '@matchid'
								FROM	@transDel t
								FOR XML PATH('r'), ROOT('root')
							)

				EXECUTE	dbo.ExecRep_02 @winlostdate = @winlostdate, @Command = 'ALL_DB', @DeletedTarget = 'MarkedTransaction', @transIds = @transDelStr;

				-- Dynamic Delay Time --
				SELECT	@WaitFor = dbo.f_BU_GetDelayTime('FriRoutine');
				WAITFOR DELAY @WaitFor;
			END;

			RETURN;
		END;
		
		/*-----TVS------*/
		ELSE IF @DeletedTarget = 'TicketVoiding_VoidedTransaction'
		BEGIN
			TRUNCATE TABLE #DeletedList
			
			--process for ticket single and main parlay and metrix gaming
			INSERT INTO #DeletedList (id,IsDone)
			SELECT	t1.id,0 
			FROM	dbo.TicketVoiding_VoidedTransaction AS t1 WITH (NOLOCK)
				INNER JOIN dbo.bettrans14 AS t2 WITH (NOLOCK) ON t2.transid = t1.TransId and t2.winlostdate = @StartDate
			WHERE	EXISTS (SELECT 1 from dbo.SportBettypeMatrix t3 WITH (NOLOCK) WHERE t2.bettype=t3.BetType
								 AND t3.ProductID IN (1,3,5,25,27,37) AND t2.statusID=102 and t1.matchid=0 )
			UNION 
			SELECT	t1.id,0
			FROM	dbo.TicketVoiding_VoidedTransaction AS t1 WITH (NOLOCK)
				INNER JOIN dbo.bettrans14 AS t2 WITH (NOLOCK) ON t2.refno = t1.TransId and t2.winlostdate = @StartDate 
			WHERE	EXISTS (SELECT 1 FROM dbo.SportBettypeMatrix t3 WITH (NOLOCK) WHERE t2.bettype=t3.BetType AND t3.bettype != 29
								AND t3.ProductID =1 AND t2.statusID=102)
					
			--process for ticket sub parlay (sportbook and virtual sport)
			INSERT INTO #DeletedList (id,IsDone)
			SELECT id,0 
			FROM dbo.TicketVoiding_VoidedTransaction AS t1 WITH (NOLOCK)
			WHERE 	EXISTS (SELECT 1 FROM dbo.match14 AS t2 WITH (NOLOCK) WHERE t1.MatchId != 0 AND  t1.matchid = t2.matchid AND t2.eventdate = @StartDate);
			
			EXEC [dbo].[Task_Archive_Bet] @Action = 'subtask', @DeletedTarget = 'TicketVoiding_VoidedTransaction'
			RETURN
		END

		ELSE IF @DeletedTarget = 'zzzbettrans'
		BEGIN			
			TRUNCATE TABLE #DeletedList
			INSERT INTO #DeletedList (id,IsDone)
			SELECT	t1.keyid,0
			FROM	dbo.zzzbettrans AS t1 WITH (NOLOCK)
				INNER JOIN dbo.bettrans14 AS t2 WITH (NOLOCK) ON t1.transid = t2.transid AND t2.winlostdate = @StartDate
			WHERE	t1.VoidingHistoryId IS NULL	
				AND EXISTS (SELECT 1 FROM dbo.SportBettypeMatrix t3 WITH (NOLOCK) WHERE t2.bettype=t3.BetType
									AND t3.ProductID IN (1,3,5,25,27,37) AND t2.statusID=102 )
			UNION 
			SELECT	t1.keyid,0
			FROM	dbo.zzzbettrans AS t1 WITH (NOLOCK)
				INNER JOIN dbo.bettransm14 t2 WITH (NOLOCK) ON t1.transid = t2.transid AND t2.statusID=102 and t1.matchid=t2.matchid AND t2.winlostdate = @StartDate
			WHERE	t1.VoidingHistoryId IS NULL	

			EXEC [dbo].[Task_Archive_Bet] @Action = 'subtask', @DeletedTarget = 'zzzbettrans'	
			RETURN
		END

		ELSE IF @DeletedTarget = 'zzzbettransM'
		BEGIN			
			TRUNCATE TABLE #DeletedList
			INSERT INTO #DeletedList (id,IsDone)
			SELECT keyid,0 FROM dbo.zzzbettransM AS t1 WITH (NOLOCK)
				WHERE	EXISTS (SELECT 1 FROM dbo.bettransm14 AS t2 WITH (NOLOCK) WHERE t1.transid = t2.transid AND t2.statusID=102 AND t1.matchid=t2.matchid AND t2.winlostdate = @StartDate)
					AND t1.VoidingHistoryId IS NULL;
			
			EXEC [dbo].[Task_Archive_Bet] @Action = 'subtask', @DeletedTarget = 'zzzbettransM'	
			RETURN
		END

		ELSE IF @DeletedTarget = 'TicketVoiding_RequestDetail'
		BEGIN			
			TRUNCATE TABLE #DeletedList
			-------Match-----------
			INSERT INTO #DeletedList (id,IsDone)
			SELECT id,0 
			FROM dbo.TicketVoiding_RequestDetail AS t1 WITH (NOLOCK)
			WHERE t1.MatchId NOT IN (9,29,2799)
				AND EXISTS (SELECT 1 FROM bodb02.dbo.match14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.matchid AND t2.eventdate BETWEEN @StartDate AND @EndDate);
				
			---------- outright -----------
			INSERT INTO #DeletedList (id,IsDone)
			SELECT id,0 
			FROM	bodb02.dbo.TicketVoiding_RequestDetail AS t1 WITH (NOLOCK)
			WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.outright14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.orid AND t2.eventdate BETWEEN @StartDate AND @EndDate)

			---------------------------VSOutright------------------
			INSERT INTO #DeletedList (id,IsDone)
			SELECT id,0 
			FROM	bodb02.dbo.TicketVoiding_RequestDetail AS t1 WITH (NOLOCK)
			WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.VSOutright14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.orid AND t2.eventdate BETWEEN @StartDate AND @EndDate)

			--------------- VSRaceInfo ------------------
			INSERT INTO #DeletedList (id,IsDone)
			SELECT id,0 
			FROM	bodb02.dbo.TicketVoiding_RequestDetail AS t1 WITH (NOLOCK)
			WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.VSRaceInfo14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.EventID AND t2.EventTime BETWEEN @StartDate AND @EndDate)

			
			EXEC [dbo].[Task_Archive_Bet] @Action = 'subtask', @DeletedTarget = 'TicketVoiding_RequestDetail'
			RETURN
		END

		ELSE IF @DeletedTarget = 'TicketVoiding_Request'
		BEGIN
			CREATE TABLE #tmpRequest(RequestId INT)

			INSERT INTO #tmpRequest (RequestId)
			SELECT RequestId
			FROM dbo.TicketVoiding_Request AS t1 WITH (NOLOCK)
				CROSS APPLY (
					SELECT MAX(m.eventdate) AS Max_EventDate
					FROM	bodb02.dbo.TicketVoiding_RequestDetail AS rd WITH (NOLOCK)
						CROSS APPLY (
							SELECT t2.eventdate AS eventdate
							FROM	bodb02.dbo.match14 AS t2 WITH (NOLOCK)
							WHERE	rd.MatchId NOT IN (9,29,2799) AND rd.MatchId = t2.matchid AND rd.RequestId = t1.RequestId
							UNION ALL
							SELECT t2.eventdate AS eventdate
							FROM	 bodb02.dbo.match AS t2 WITH (NOLOCK)
							WHERE	rd.MatchId NOT IN (9,29,2799) AND rd.MatchId = t2.matchid AND rd.RequestId = t1.RequestId

							UNION ALL
							SELECT t2.eventdate
							FROM	bodb02.dbo.outright14 AS t2 WITH (NOLOCK) 
							WHERE rd.matchid = t2.orid AND rd.RequestId = t1.RequestId
							UNION ALL
							SELECT t2.eventdate
							FROM	bodb02.dbo.outright AS t2 WITH (NOLOCK) 
							WHERE rd.matchid = t2.orid AND rd.RequestId = t1.RequestId

							UNION ALL
							SELECT t2.EventDate
							FROM	bodb02.dbo.VSOutright14 AS t2 WITH (NOLOCK) 
							WHERE rd.matchid = t2.orid AND rd.RequestId = t1.RequestId
							UNION ALL
							SELECT t2.EventDate
							FROM	bodb02.dbo.VSOutright AS t2 WITH (NOLOCK) 
							WHERE rd.matchid = t2.orid AND rd.RequestId = t1.RequestId

							UNION ALL
							SELECT t2.EventTime
							FROM	bodb02.dbo.VSRaceInfo14 AS t2 WITH (NOLOCK) 
							WHERE rd.matchid = t2.EventID AND rd.RequestId = t1.RequestId
							UNION ALL
							SELECT t2.EventTime
							FROM	bodb02.dbo.VSRaceInfo AS t2 WITH (NOLOCK) 
							WHERE rd.matchid = t2.EventID AND rd.RequestId = t1.RequestId

							UNION ALL
							SELECT MAX(bt.winlostdate) AS eventdate
							FROM	bodb02.dbo.TicketVoiding_RequestDetailTicket_Single s WITH (NOLOCK)
								CROSS APPLY (
										SELECT  b.winlostdate as winlostdate
										FROM	bodb02.dbo.bettrans b WITH (NOLOCK) 
										WHERE b.transid = s.TransId AND s.MatchId IN (9,29,2799) AND s.RequestId = t1.RequestId AND s.MatchId = rd.MatchId
			
										UNION ALL
										SELECT b.winlostdate as winlostdate
										FROM bodb02.dbo.bettrans14 b WITH (NOLOCK) 
										WHERE b.transid = s.TransId AND s.MatchId IN (9,29,2799) AND s.RequestId = t1.RequestId AND s.MatchId = rd.MatchId
								)bt
						)m
					WHERE  rd.RequestId = t1.RequestId
				)t	
			WHERE  t.Max_EventDate BETWEEN @StartDate AND @EndDate;
			
			-----TicketVoiding_Request----
			TRUNCATE TABLE #DeletedList
			INSERT INTO #DeletedList (id,IsDone)
			SELECT RequestId, 0 
			FROM #tmpRequest
			
			EXEC [dbo].[Task_Archive_Bet] @Action = 'subtask', @DeletedTarget = 'TicketVoiding_Request'

			-------Parlay for TicketVoiding_RequestDetail----------
			INSERT INTO #DeletedList (id,IsDone)
			SELECT id,0 
			FROM	bodb02.dbo.TicketVoiding_RequestDetail AS t1 WITH (NOLOCK)
				CROSS APPLY (
						SELECT max(b.winlostdate) as winlostdate
						FROM bodb02.dbo.TicketVoiding_RequestDetailTicket_Single s WITH (NOLOCK)
							INNER JOIN bodb02.dbo.bettrans b WITH (NOLOCK) ON b.transid = s.TransId AND s.MatchId IN (9,29,2799)
							WHERE s.RequestId = t1.RequestId
			
						UNION ALL
						SELECT max(b.winlostdate) as winlostdate
						FROM bodb02.dbo.TicketVoiding_RequestDetailTicket_Single s WITH (NOLOCK)
							INNER JOIN bodb02.dbo.bettrans14 b WITH (NOLOCK) ON b.transid = s.TransId AND s.MatchId IN (9,29,2799)
							WHERE s.RequestId = t1.RequestId
				)t
			WHERE t1.MatchId IN (9,29,2799)
				AND t.winlostdate BETWEEN @StartDate AND @EndDate

			EXEC [dbo].[Task_Archive_Bet] @Action = 'subtask', @DeletedTarget = 'TicketVoiding_RequestDetail'

			-----zzzbettransm----
			TRUNCATE TABLE #DeletedList
			INSERT INTO #DeletedList (id,IsDone)
			SELECT t1.keyid, 0 
			FROM dbo.zzzbettransm t1 WITH (NOLOCK)
				INNER JOIN dbo.TicketVoiding_VoidingHistory v WITH (NOLOCK) ON v.VoidingHistoryId = t1.VoidingHistoryId
				INNER JOIN #tmpRequest r ON r.RequestId = v.RequestId
			WHERE t1.VoidingHistoryId IS NOT NULL

			EXEC [dbo].[Task_Archive_Bet] @Action = 'subtask', @DeletedTarget = 'zzzbettransm'

			-----zzzbettrans----
			TRUNCATE TABLE #DeletedList
			INSERT INTO #DeletedList (id,IsDone)
			SELECT t1.keyid, 0 
			FROM dbo.zzzbettrans t1 WITH (NOLOCK)
				INNER JOIN dbo.TicketVoiding_VoidingHistory v WITH (NOLOCK) ON v.VoidingHistoryId = t1.VoidingHistoryId
				INNER JOIN #tmpRequest r ON r.RequestId = v.RequestId
			WHERE t1.VoidingHistoryId IS NOT NULL

			EXEC [dbo].[Task_Archive_Bet] @Action = 'subtask', @DeletedTarget = 'zzzbettrans'

			-----TicketVoiding_OperatorInfo----
			TRUNCATE TABLE #DeletedList
			INSERT INTO #DeletedList (id,IsDone)
			SELECT t1.Id, 0 
			FROM dbo.TicketVoiding_OperatorInfo t1 WITH (NOLOCK)
				INNER JOIN #tmpRequest r ON r.RequestId = t1.RequestId

			EXEC [dbo].[Task_Archive_Bet] @Action = 'subtask', @DeletedTarget = 'TicketVoiding_OperatorInfo'

			-----TicketVoiding_Queue----
			TRUNCATE TABLE #DeletedList
			INSERT INTO #DeletedList (id,IsDone)
			SELECT t1.QueueId, 0 
			FROM dbo.TicketVoiding_Queue t1 WITH (NOLOCK)
				INNER JOIN #tmpRequest r ON r.RequestId = t1.RequestId

			EXEC [dbo].[Task_Archive_Bet] @Action = 'subtask', @DeletedTarget = 'TicketVoiding_Queue'

			-----TicketVoiding_Reason----
			TRUNCATE TABLE #DeletedList
			INSERT INTO #DeletedList (id,IsDone)
			SELECT t1.ReasonId, 0 
			FROM dbo.TicketVoiding_Reason t1 WITH (NOLOCK)
				INNER JOIN dbo.TicketVoiding_VoidingHistory v WITH (NOLOCK) ON v.ReasonId = t1.ReasonId
				INNER JOIN #tmpRequest r ON r.RequestId = v.RequestId

			EXEC [dbo].[Task_Archive_Bet] @Action = 'subtask', @DeletedTarget = 'TicketVoiding_Reason'

			-----TicketVoiding_VoidingHistory----
			TRUNCATE TABLE #DeletedList
			INSERT INTO #DeletedList (id,IsDone)
			SELECT t1.VoidingHistoryId, 0 
			FROM dbo.TicketVoiding_VoidingHistory t1 WITH (NOLOCK)
				INNER JOIN #tmpRequest r ON r.RequestId = t1.RequestId

			EXEC [dbo].[Task_Archive_Bet] @Action = 'subtask', @DeletedTarget = 'TicketVoiding_VoidingHistory'

			-----TicketVoiding_RequestDetailTicket_Single----
			TRUNCATE TABLE #DeletedList
			INSERT INTO #DeletedList (id,IsDone)
			SELECT t1.Id, 0 
			FROM dbo.TicketVoiding_RequestDetailTicket_Single t1 WITH (NOLOCK)
				INNER JOIN #tmpRequest r ON r.RequestId = t1.RequestId

			EXEC [dbo].[Task_Archive_Bet] @Action = 'subtask', @DeletedTarget = 'TicketVoiding_RequestDetailTicket_Single'

			-----TicketVoiding_RequestDetailTicket_SubParlay----
			TRUNCATE TABLE #DeletedList
			INSERT INTO #DeletedList (id,IsDone)
			SELECT t1.Id, 0 
			FROM dbo.TicketVoiding_RequestDetailTicket_SubParlay t1 WITH (NOLOCK)
				INNER JOIN #tmpRequest r ON r.RequestId = t1.RequestId

			EXEC [dbo].[Task_Archive_Bet] @Action = 'subtask', @DeletedTarget = 'TicketVoiding_RequestDetailTicket_SubParlay'

			RETURN
		END

		ELSE IF @DeletedTarget = 'TicketVoiding_AutoUnmarkSetting'
		BEGIN			
			TRUNCATE TABLE #DeletedList
			INSERT INTO #DeletedList (id,IsDone)
			SELECT id,0 
			FROM dbo.TicketVoiding_AutoUnmarkSetting AS t1 WITH (NOLOCK)
			WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.match14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.matchid AND t2.eventdate BETWEEN @StartDate AND @EndDate);
			
			EXEC [dbo].[Task_Archive_Bet] @Action = 'subtask', @DeletedTarget = 'TicketVoiding_AutoUnmarkSetting'
			RETURN
		END

		ELSE IF @DeletedTarget = 'TicketVoiding_AutoVoidRequest_Queue'
		BEGIN			
			TRUNCATE TABLE #DeletedList
			INSERT INTO #DeletedList (id,IsDone)
			SELECT QueueId,0 
			FROM dbo.TicketVoiding_AutoVoidRequest_Queue AS t1 WITH (NOLOCK)
			WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.match14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.matchid AND t2.eventdate BETWEEN @StartDate AND @EndDate);
			
			EXEC [dbo].[Task_Archive_Bet] @Action = 'subtask', @DeletedTarget = 'TicketVoiding_AutoVoidRequest_Queue'
			RETURN
		END
		/*--------------*/

		/*------CashOutSelling--------*/
		ELSE IF @DeletedTarget = 'CashOutSelling'
		BEGIN			
			TRUNCATE TABLE #DeletedList
			INSERT INTO #DeletedList (id,IsDone)
			SELECT t1.TransID,0 
			FROM dbo.CashOutSelling AS t1 WITH (NOLOCK)
				INNER JOIN dbo.bettrans14 AS t2 WITH (NOLOCK) ON t1.transid = t2.transid AND t2.winlostdate = @StartDate
			
			EXEC [dbo].[Task_Archive_Bet] @Action = 'subtask', @DeletedTarget = 'CashOutSelling'
			RETURN
		END
	END
	ELSE IF @Action = 'subtask'
	BEGIN
		DECLARE @ids VARCHAR(MAX), @rowcount INT = 0, @topk INT = 300
		CREATE TABLE #output (id BIGINT)	

		SET @rowcount = 1
		WHILE @rowcount <> 0
		BEGIN
			TRUNCATE TABLE #output
			SET @ids = NULL

			DELETE TOP(@topk) t
			OUTPUT deleted.id INTO #output(id)
			FROM #DeletedList t
			
			SET @rowcount = ISNULL(@@ROWCOUNT,0)
			IF @rowcount = 0  BREAK;

			SELECT @ids = COALESCE(@ids + ',' + CAST(id AS VARCHAR(50)), CAST(id AS VARCHAR(50)))
			FROM #output  

			EXEC [dbo].[ExecRep_02] @Command = 'ALL_DB', @DeletedTarget = @DeletedTarget, @transIds = @ids, @winlostdate = ''
		END
		DROP TABLE #output
	END
END
GO
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/