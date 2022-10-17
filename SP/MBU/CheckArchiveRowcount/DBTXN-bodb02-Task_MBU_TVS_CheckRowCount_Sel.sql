/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/
GO
CREATE PROCEDURE [dbo].[Task_MBU_TVS_CheckRowCount_Sel]
	@StartDate		SMALLDATETIME	= NULL
	,@EndDate		SMALLDATETIME = NULL 
	,@tablename		VARCHAR(50) = NULL
	,@OutputData VARCHAR(4000) = '' OUTPUT
AS
/*
	Created: 20210628@Helen
	Task: Check consistency data for archiving process for TVS
	DB:DBTXN/bodb02 - clone from SP Task_MBU_Bet_CheckRowCount_Sel

	Revisions:
		- 20210628@Helen:	Initial - [RedmineId: #157539]
		- 20210701@Helen: [TVS] Duplicate issue [Redmine: #157539]
		- 20220113@Max: [TVS] Cannot execute auto void queue for test match [Redmine: #166895]
		- 20220309@Max: MBU - Copy data of Cash Out Selling to bk table [Redmine: #169593]
		- 20221003@Max: [TVS] Enhance archive process of TVS data regarding the Scale Out DB project - [Redmine: #178234]
	Notes:
		- check by one day: TicketVoiding_VoidedTransaction
		- check by range from startdate & enddate: others	
		
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @__tempCount TABLE (rowcnt INT, tableName VARCHAR(128), ArchiveDate SMALLDATETIME)
	DECLARE @StartDate_tmp	SMALLDATETIME	= @StartDate
			,@EndDate_tmp	SMALLDATETIME = @EndDate 
	
	CREATE TABLE #tmpRequest (RequestID INT)
	-------------------Part 1: for table only based on checking by range from startdate to enddate ------------------------
	--//1 - TicketVoiding_RequestDetail
	IF @tablename = 'TicketVoiding_RequestDetail'
	BEGIN
		INSERT INTO @__tempCount(rowcnt, tableName)
		SELECT	SUM(temp.cnt), 'TicketVoiding_RequestDetail'
		FROM (
				SELECT COUNT(1) as cnt
				FROM	bodb02.dbo.TicketVoiding_RequestDetail AS t1 WITH (NOLOCK)
				WHERE	t1.MatchId NOT IN (9,29,2799)
					AND EXISTS (SELECT 1 FROM bodb02.dbo.match14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.matchid AND t2.eventdate BETWEEN @StartDate AND @EndDate)
				UNION All
				
				SELECT	COUNT(1) as cnt
				FROM	bodb02.dbo.TicketVoiding_RequestDetail AS t1 WITH (NOLOCK)
				WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.VSOutright14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.orid AND t2.eventdate BETWEEN @StartDate AND @EndDate)
				
				UNION All
				SELECT	COUNT(1) as cnt
				FROM	bodb02.dbo.TicketVoiding_RequestDetail AS t1 WITH (NOLOCK)
				WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.VSRaceInfo14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.EventID AND t2.EventTime BETWEEN @StartDate AND @EndDate)
				
				UNION ALL
				SELECT COUNT(1) cnt
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
		
				) AS temp
	END	
	ELSE IF @tablename = 'TicketVoiding_Request'
	BEGIN		
		--//2 - TicketVoiding_Request
		INSERT INTO #tmpRequest (RequestID)
		SELECT	RequestId
		FROM	bodb02.dbo.TicketVoiding_Request AS t1 WITH (NOLOCK)
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
		WHERE  t.Max_EventDate BETWEEN @StartDate AND @EndDate
		
		INSERT INTO @__tempCount(rowcnt, tableName)
		SELECT	COUNT(1), 'TicketVoiding_Request'
		FROM #tmpRequest
		
		--//-- Tables archived basing on requestid of TicketVoiding_Request (TVS)
		--2.1 zzzbettransM
		INSERT INTO @__tempCount(rowcnt, tableName)
		SELECT	COUNT(1), 'zzzbettransM'
		FROM	bodb02.dbo.zzzbettransM AS t1 WITH (NOLOCK)
			INNER JOIN DBCTG.bodb02.dbo.TicketVoiding_VoidingHistory v WITH (NOLOCK) ON v.VoidingHistoryId = t1.VoidingHistoryId
			CROSS APPLY (
					SELECT	RequestId
					FROM	#tmpRequest t
					WHERE t.RequestId = v.RequestId
			) r
		WHERE	t1.VoidingHistoryId IS NOT NULL
		
		--2.2 zzzbettrans
		INSERT INTO @__tempCount(rowcnt, tableName)
		SELECT	COUNT(1), 'zzzbettrans'	
		FROM	bodb02.dbo.zzzbettrans AS t1 WITH (NOLOCK)
			INNER JOIN DBCTG.bodb02.dbo.TicketVoiding_VoidingHistory v WITH (NOLOCK) ON v.VoidingHistoryId = t1.VoidingHistoryId
			CROSS APPLY (
					SELECT	RequestId
					FROM	#tmpRequest t
					WHERE t.RequestId = v.RequestId
			) r
			WHERE	t1.VoidingHistoryId IS NOT NULL
				AND r.RequestId IS NOT NULL
		--2.3 TicketVoiding_OperatorInfo_bk	
		INSERT INTO @__tempCount(rowcnt, tableName)
		SELECT	COUNT(1), 'TicketVoiding_OperatorInfo'	
		FROM	bodb02.dbo.TicketVoiding_OperatorInfo AS t1 WITH (NOLOCK)
			CROSS APPLY (
					SELECT	RequestId
					FROM	#tmpRequest t
					WHERE t.RequestId = t1.RequestId
			) r
		
		-- 2.5 TicketVoiding_VoidingHistory
		INSERT INTO @__tempCount(rowcnt, tableName)
		SELECT	COUNT(1), 'TicketVoiding_VoidingHistory'
		FROM	bodb02.dbo.TicketVoiding_VoidingHistory AS t1 WITH (NOLOCK)
			CROSS APPLY (
						SELECT	RequestId
						FROM	#tmpRequest t
						WHERE t.RequestId = t1.RequestId
				) r
		
		-- 2.6 TicketVoiding_RequestDetailTicket_Single
		INSERT INTO @__tempCount(rowcnt, tableName)
		SELECT	COUNT(1), 'TicketVoiding_RequestDetailTicket_Single'
		FROM	bodb02.dbo.TicketVoiding_RequestDetailTicket_Single AS t1 WITH (NOLOCK)
				CROSS APPLY (
						SELECT	RequestId
						FROM	#tmpRequest t
						WHERE t.RequestId = t1.RequestId
				) r
		-- 2.7 TicketVoiding_RequestDetailTicket_SubParlay
		INSERT INTO @__tempCount(rowcnt, tableName)
		SELECT	COUNT(1), 'TicketVoiding_RequestDetailTicket_SubParlay'
		FROM	bodb02.dbo.TicketVoiding_RequestDetailTicket_SubParlay AS t1 WITH (NOLOCK)
			CROSS APPLY (
						SELECT	RequestId
						FROM	#tmpRequest t
						WHERE t.RequestId = t1.RequestId
				) r
		
		-- 2.8 TicketVoiding_Reason
		INSERT INTO @__tempCount(rowcnt, tableName)
		SELECT	COUNT(1), 'TicketVoiding_Reason'
		FROM	bodb02.dbo.TicketVoiding_Reason AS t1 WITH (NOLOCK)
			INNER JOIN bodb02.dbo.TicketVoiding_VoidingHistory v WITH (NOLOCK) ON v.ReasonId = t1.ReasonId
			CROSS APPLY (
					SELECT	RequestId
					FROM	#tmpRequest t
					WHERE t.RequestId = v.RequestId
			) r

	END	
	ELSE IF @tablename = 'TicketVoiding_AutoUnmarkSetting'
	BEGIN
		-- 4 TicketVoiding_AutoUnmarkSetting
		INSERT INTO @__tempCount(rowcnt, tableName)
		SELECT	COUNT(1), 'TicketVoiding_AutoUnmarkSetting'
		FROM	bodb02.dbo.TicketVoiding_AutoUnmarkSetting AS t1 WITH (NOLOCK)
		WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.match14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.matchid AND t2.eventdate BETWEEN @StartDate AND @EndDate)
	END	
	ELSE IF @tablename = 'TicketVoiding_VoidedTransaction'
	BEGIN
	-------------------Part 2: for table only based on checking by range from startdate to Check by one by one by startdate ------------------------
		INSERT INTO @__tempCount(rowcnt, tableName, ArchiveDate)
		SELECT SUM (tmp.cnt), 'TicketVoiding_VoidedTransaction',@StartDate_tmp
		FROM
		(	
			--process for ticket single and main parlay and metrix gaming
			SELECT	COUNT(1) AS cnt
			FROM (SELECT t1.Id
					FROM	bodb02.dbo.TicketVoiding_VoidedTransaction AS t1 WITH (NOLOCK)
						INNER JOIN bodb02.dbo.bettrans14 AS t2 WITH (NOLOCK) ON t2.transid = t1.TransId and t2.winlostdate = @StartDate
					WHERE	EXISTS (SELECT 1 from bodb02.dbo.SportBettypeMatrix t3 WITH (NOLOCK) where t2.bettype=t3.BetType
										 AND t3.ProductID IN (1,3,5,25,27,37) AND t2.statusID=102 and t1.matchid=0 )
					
					UNION 
					SELECT t1.Id
					FROM	bodb02.dbo.TicketVoiding_VoidedTransaction AS t1 WITH (NOLOCK)
						INNER JOIN bodb02.dbo.bettrans14 AS t2 WITH (NOLOCK) ON t2.refno = t1.TransId and t2.winlostdate = @StartDate 
					WHERE	EXISTS (SELECT 1 from bodb02.dbo.SportBettypeMatrix t3 WITH (NOLOCK) WHERE t2.bettype=t3.BetType AND t3.bettype != 29 
										AND t3.ProductID =1 AND t2.statusID=102)
				) AS t
			--process for ticket sub parlay (sportbook and virtual sport)
			UNION All
			SELECT	COUNT(1)
			FROM	bodb02.dbo.TicketVoiding_VoidedTransaction AS t1 WITH (NOLOCK)
			WHERE 	EXISTS (SELECT 1 FROM bodb02.dbo.match14 AS t2 WITH (NOLOCK) WHERE t1.MatchId != 0 AND  t1.matchid = t2.matchid AND t2.eventdate = @StartDate)
		) AS tmp
	END
	ELSE IF @tablename = 'zzzbettrans'
	BEGIN
		-------------- PROCESS for tables that user void without TVS, use old function of special delete ---------------------
		--5.1 zzzbettrans	
		INSERT INTO @__tempCount(rowcnt, tableName)
		SELECT COUNT (1) AS cnt, 'zzzbettrans'
		FROM (
			
			SELECT	t1.keyid
			FROM	bodb02.dbo.zzzbettrans AS t1 WITH (NOLOCK)
				INNER JOIN bodb02.dbo.bettrans14 AS t2 WITH (NOLOCK) ON t1.transid = t2.transid AND t2.winlostdate = @StartDate
			WHERE	t1.VoidingHistoryId IS NULL	
				AND EXISTS (SELECT 1 FROM bodb02.dbo.SportBettypeMatrix t3 WITH (NOLOCK) WHERE t2.bettype=t3.BetType
									AND t3.ProductID IN (1,3,5,25,27,37) AND t2.statusID=102 )
			UNION 
			SELECT	t1.keyid
			FROM	bodb02.dbo.zzzbettrans AS t1 WITH (NOLOCK)
				INNER JOIN bodb02.dbo.bettransm14 t2 WITH (NOLOCK) ON t1.transid = t2.transid AND t2.statusID=102 and t1.matchid=t2.matchid AND t2.winlostdate = @StartDate
			WHERE	t1.VoidingHistoryId IS NULL	
		) AS tmp
	END
	ELSE IF @tablename = 'zzzbettransM'	
	BEGIN
		-- 5.2 zzzbettransM
		INSERT INTO @__tempCount(rowcnt, tableName)
		SELECT	COUNT(1),'zzzbettransM'
		FROM	bodb02.dbo.zzzbettransM AS t1 WITH (NOLOCK)
		WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.bettransm14 AS t2 WITH (NOLOCK) WHERE t1.transid = t2.transid AND t2.statusID=102 and t1.matchid=t2.matchid AND t2.winlostdate = @StartDate)
			AND t1.VoidingHistoryId IS NULL
	END	
	ELSE IF @tablename = 'CashOutSelling'	
	BEGIN
		INSERT INTO @__tempCount(rowcnt, tableName)
		SELECT	COUNT(1),'CashOutSelling'
		FROM	bodb02.dbo.CashOutSelling AS t1 WITH (NOLOCK)
			INNER JOIN bodb02.dbo.bettrans14 AS t2 WITH (NOLOCK) ON t1.transid = t2.transid AND t2.winlostdate = @StartDate	
		
	END	
	---------------------------------------------------------------------		
	SELECT @OutputData = (
		SELECT rowcnt AS r, tableName AS t,ArchiveDate AS ADate
		FROM @__tempCount
		FOR XML RAW ('r')
	)

	DROP TABLE #tmpRequest	
END

