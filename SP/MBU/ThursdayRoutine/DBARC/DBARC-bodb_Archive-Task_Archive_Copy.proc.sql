/*<info serverAlias="DBARC-bodb_Archive" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE	dbo.Task_Archive_Copy
						@StartDate		DATETIME	= NULL
					,	@EndDate			DATETIME = NULL
					,	@TableName			NVARCHAR(128)	= ''
					
AS
/*
	Created:	20200720@Brice
	Task:		Archive on DBARC - [Redmine: #111093]
	Database:	DBARC.bodb_Archive

	Revisions:
		- 20200720@Brice:	Initialize [Redmine: #111093]
		- 20201125@Brice:	hotfix duplicate key [Redmine: #111093]
		- 20201210@Max: TVS - New issue type Abnormal Accounts [Redmine: #143666]
		- 20200209@Helen: TVS - New issue type Abnormal Accounts - archive zzzbettrans  [Redmine: #143666]
		- 20200211@Helen: TVS - New issue type Abnormal Accounts - hotfix  [Redmine: #143666]
		- 20210304@Max: [TVS] Remove archived data [Redmine: #150524]
		- 20210604@Max: [TVS] Danger Accept Enhancement - Phase 9 [Redmine: #153216]
		- 20210625@Helen: [TVS] Perfomance tuning for archived process [Redmine: #157539]
		- 20210701@Helen: [TVS] Duplicate issue [Redmine: #157539]
		- 20211126@Kathy: Add 2 new column bettype,betid [Redmine:#140180]
		- 20211126@Kathy: get bettype,betid from active table[Redmine:#140180]
		- 20220113@Max: [TVS] Cannot execute auto void queue for test match [Redmine: #166895]
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE	@Query	NVARCHAR(MAX), @RequestIds NVARCHAR(MAX)
	DECLARE @tmpRequest TABLE (RequestId INT)
	CREATE TABLE #tmpRequest(
		[RequestId] [int],
		[Sporttype] [smallint] ,
		[SubIssueTypeId] [smallint] ,
		[ActionId] [tinyint] ,
		[Provider] [nvarchar](200) ,
		[Source] [nvarchar](200) ,
		[DecidedBy] [nvarchar](200) ,
		[MistakenBy] [nvarchar](200) ,
		[Remark] [nvarchar](max) ,
		[CheckedBy] [int] ,
		[UserId] [int] ,
		[CreatedDate] [datetime] ,
		[LastModifiedBy] [int] ,
		[LastModifiedDate] [datetime] ,
		[IsTest] [bit] ,
		[IssueTypeId] [tinyint] ,
		[isFinish] [bit]
	)

	---------------Table 1: TicketVoiding_RequestDetail_bk --------------------
	IF	@TableName = N'TicketVoiding_RequestDetail_bk'
	BEGIN;
		---------match--------------------
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.TicketVoiding_RequestDetail_bk
	(AwayId,FilterBy,FilterFromBetId,FilterFromTransTime,FilterToBetId,FilterToTransTime,HomeId,Id,IsCheckedAwayTeam,IsCheckedHomeTeam,IsFilterByTransTime,IssueDetail,KickOffTime,LeagueId,LiveAwayScore,LiveHomeScore,MainParlayCount,MatchId,MaxMainParlayTransId,MaxSingleTransId,MinMainParlayTransId,MinSingleTransId,RequestId,RequestType,SingleCount,TransIds,VoidFromTime,VoidToTime,Usernames,ProductIds,TicketStatusIds,FromWinlostDate,ToWinlostDate, SubIssueTypeId)
SELECT AwayId,FilterBy,FilterFromBetId,FilterFromTransTime,FilterToBetId,FilterToTransTime,HomeId,Id,IsCheckedAwayTeam,IsCheckedHomeTeam,IsFilterByTransTime,IssueDetail,KickOffTime,LeagueId,LiveAwayScore,LiveHomeScore,MainParlayCount,MatchId,MaxMainParlayTransId,MaxSingleTransId,MinMainParlayTransId,MinSingleTransId,RequestId,RequestType,SingleCount,TransIds,VoidFromTime,VoidToTime,Usernames,ProductIds,TicketStatusIds,FromWinlostDate,ToWinlostDate, SubIssueTypeId
FROM	OPENQUERY(DBTXN, ''\
DECLARE	@StartDate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @StartDate, 121) + ''''';
DECLARE	@EndDate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @EndDate, 121) + ''''';

SELECT	AwayId,FilterBy,FilterFromBetId,FilterFromTransTime,FilterToBetId,FilterToTransTime,HomeId,Id,IsCheckedAwayTeam,IsCheckedHomeTeam,IsFilterByTransTime,IssueDetail,KickOffTime,LeagueId,LiveAwayScore,LiveHomeScore,MainParlayCount,MatchId,MaxMainParlayTransId,MaxSingleTransId,MinMainParlayTransId,MinSingleTransId,RequestId,RequestType,SingleCount,TransIds,VoidFromTime,VoidToTime,Usernames,ProductIds,TicketStatusIds,FromWinlostDate,ToWinlostDate, SubIssueTypeId
FROM	bodb02.dbo.TicketVoiding_RequestDetail AS t1 WITH (NOLOCK)
WHERE	t1.MatchId NOT IN (9,29,2799)
	AND EXISTS (SELECT 1 FROM bodb02.dbo.match14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.matchid AND t2.eventdate BETWEEN @StartDate AND @EndDate)	

	;'');';

		EXECUTE	sys.sp_executesql @Query;
		
		---------- outright -----------
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.TicketVoiding_RequestDetail_bk
	(AwayId,FilterBy,FilterFromBetId,FilterFromTransTime,FilterToBetId,FilterToTransTime,HomeId,Id,IsCheckedAwayTeam,IsCheckedHomeTeam,IsFilterByTransTime,IssueDetail,KickOffTime,LeagueId,LiveAwayScore,LiveHomeScore,MainParlayCount,MatchId,MaxMainParlayTransId,MaxSingleTransId,MinMainParlayTransId,MinSingleTransId,RequestId,RequestType,SingleCount,TransIds,VoidFromTime,VoidToTime,Usernames,ProductIds,TicketStatusIds,FromWinlostDate,ToWinlostDate, SubIssueTypeId)
SELECT AwayId,FilterBy,FilterFromBetId,FilterFromTransTime,FilterToBetId,FilterToTransTime,HomeId,Id,IsCheckedAwayTeam,IsCheckedHomeTeam,IsFilterByTransTime,IssueDetail,KickOffTime,LeagueId,LiveAwayScore,LiveHomeScore,MainParlayCount,MatchId,MaxMainParlayTransId,MaxSingleTransId,MinMainParlayTransId,MinSingleTransId,RequestId,RequestType,SingleCount,TransIds,VoidFromTime,VoidToTime,Usernames,ProductIds,TicketStatusIds,FromWinlostDate,ToWinlostDate, SubIssueTypeId
FROM	OPENQUERY(DBTXN, ''\
DECLARE	@StartDate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @StartDate, 121) + ''''';
DECLARE	@EndDate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @EndDate, 121) + ''''';

SELECT	AwayId,FilterBy,FilterFromBetId,FilterFromTransTime,FilterToBetId,FilterToTransTime,HomeId,Id,IsCheckedAwayTeam,IsCheckedHomeTeam,IsFilterByTransTime,IssueDetail,KickOffTime,LeagueId,LiveAwayScore,LiveHomeScore,MainParlayCount,MatchId,MaxMainParlayTransId,MaxSingleTransId,MinMainParlayTransId,MinSingleTransId,RequestId,RequestType,SingleCount,TransIds,VoidFromTime,VoidToTime,Usernames,ProductIds,TicketStatusIds,FromWinlostDate,ToWinlostDate, SubIssueTypeId
FROM	bodb02.dbo.TicketVoiding_RequestDetail AS t1 WITH (NOLOCK)
WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.outright14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.orid AND t2.eventdate BETWEEN @StartDate AND @EndDate)

	;'');';

		EXECUTE	sys.sp_executesql @Query;
		
		---------------------------VSOutright------------------
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.TicketVoiding_RequestDetail_bk
	(AwayId,FilterBy,FilterFromBetId,FilterFromTransTime,FilterToBetId,FilterToTransTime,HomeId,Id,IsCheckedAwayTeam,IsCheckedHomeTeam,IsFilterByTransTime,IssueDetail,KickOffTime,LeagueId,LiveAwayScore,LiveHomeScore,MainParlayCount,MatchId,MaxMainParlayTransId,MaxSingleTransId,MinMainParlayTransId,MinSingleTransId,RequestId,RequestType,SingleCount,TransIds,VoidFromTime,VoidToTime,Usernames,ProductIds,TicketStatusIds,FromWinlostDate,ToWinlostDate, SubIssueTypeId)
SELECT AwayId,FilterBy,FilterFromBetId,FilterFromTransTime,FilterToBetId,FilterToTransTime,HomeId,Id,IsCheckedAwayTeam,IsCheckedHomeTeam,IsFilterByTransTime,IssueDetail,KickOffTime,LeagueId,LiveAwayScore,LiveHomeScore,MainParlayCount,MatchId,MaxMainParlayTransId,MaxSingleTransId,MinMainParlayTransId,MinSingleTransId,RequestId,RequestType,SingleCount,TransIds,VoidFromTime,VoidToTime,Usernames,ProductIds,TicketStatusIds,FromWinlostDate,ToWinlostDate, SubIssueTypeId
FROM	OPENQUERY(DBTXN, ''\
DECLARE	@StartDate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @StartDate, 121) + ''''';
DECLARE	@EndDate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @EndDate, 121) + ''''';


SELECT	AwayId,FilterBy,FilterFromBetId,FilterFromTransTime,FilterToBetId,FilterToTransTime,HomeId,Id,IsCheckedAwayTeam,IsCheckedHomeTeam,IsFilterByTransTime,IssueDetail,KickOffTime,LeagueId,LiveAwayScore,LiveHomeScore,MainParlayCount,MatchId,MaxMainParlayTransId,MaxSingleTransId,MinMainParlayTransId,MinSingleTransId,RequestId,RequestType,SingleCount,TransIds,VoidFromTime,VoidToTime,Usernames,ProductIds,TicketStatusIds,FromWinlostDate,ToWinlostDate, SubIssueTypeId
FROM	bodb02.dbo.TicketVoiding_RequestDetail AS t1 WITH (NOLOCK)
WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.VSOutright14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.orid AND t2.eventdate BETWEEN @StartDate AND @EndDate)

	;'');';

		EXECUTE	sys.sp_executesql @Query;
		
		--------------- VSRaceInfo ------------------
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.TicketVoiding_RequestDetail_bk
	(AwayId,FilterBy,FilterFromBetId,FilterFromTransTime,FilterToBetId,FilterToTransTime,HomeId,Id,IsCheckedAwayTeam,IsCheckedHomeTeam,IsFilterByTransTime,IssueDetail,KickOffTime,LeagueId,LiveAwayScore,LiveHomeScore,MainParlayCount,MatchId,MaxMainParlayTransId,MaxSingleTransId,MinMainParlayTransId,MinSingleTransId,RequestId,RequestType,SingleCount,TransIds,VoidFromTime,VoidToTime,Usernames,ProductIds,TicketStatusIds,FromWinlostDate,ToWinlostDate, SubIssueTypeId)
SELECT AwayId,FilterBy,FilterFromBetId,FilterFromTransTime,FilterToBetId,FilterToTransTime,HomeId,Id,IsCheckedAwayTeam,IsCheckedHomeTeam,IsFilterByTransTime,IssueDetail,KickOffTime,LeagueId,LiveAwayScore,LiveHomeScore,MainParlayCount,MatchId,MaxMainParlayTransId,MaxSingleTransId,MinMainParlayTransId,MinSingleTransId,RequestId,RequestType,SingleCount,TransIds,VoidFromTime,VoidToTime,Usernames,ProductIds,TicketStatusIds,FromWinlostDate,ToWinlostDate, SubIssueTypeId
FROM	OPENQUERY(DBTXN, ''\
DECLARE	@StartDate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @StartDate, 121) + ''''';
DECLARE	@EndDate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @EndDate, 121) + ''''';

SELECT	AwayId,FilterBy,FilterFromBetId,FilterFromTransTime,FilterToBetId,FilterToTransTime,HomeId,Id,IsCheckedAwayTeam,IsCheckedHomeTeam,IsFilterByTransTime,IssueDetail,KickOffTime,LeagueId,LiveAwayScore,LiveHomeScore,MainParlayCount,MatchId,MaxMainParlayTransId,MaxSingleTransId,MinMainParlayTransId,MinSingleTransId,RequestId,RequestType,SingleCount,TransIds,VoidFromTime,VoidToTime,Usernames,ProductIds,TicketStatusIds,FromWinlostDate,ToWinlostDate, SubIssueTypeId
FROM	bodb02.dbo.TicketVoiding_RequestDetail AS t1 WITH (NOLOCK)
WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.VSRaceInfo14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.EventID AND t2.EventTime BETWEEN @StartDate AND @EndDate)

	;'');';

		EXECUTE	sys.sp_executesql @Query;
		-----------  RequestDetail ---------
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.TicketVoiding_RequestDetail_bk
	(AwayId,FilterBy,FilterFromBetId,FilterFromTransTime,FilterToBetId,FilterToTransTime,HomeId,Id,IsCheckedAwayTeam,IsCheckedHomeTeam,IsFilterByTransTime,IssueDetail,KickOffTime,LeagueId,LiveAwayScore,LiveHomeScore,MainParlayCount,MatchId,MaxMainParlayTransId,MaxSingleTransId,MinMainParlayTransId,MinSingleTransId,RequestId,RequestType,SingleCount,TransIds,VoidFromTime,VoidToTime,Usernames,ProductIds,TicketStatusIds,FromWinlostDate,ToWinlostDate, SubIssueTypeId)
SELECT AwayId,FilterBy,FilterFromBetId,FilterFromTransTime,FilterToBetId,FilterToTransTime,HomeId,Id,IsCheckedAwayTeam,IsCheckedHomeTeam,IsFilterByTransTime,IssueDetail,KickOffTime,LeagueId,LiveAwayScore,LiveHomeScore,MainParlayCount,MatchId,MaxMainParlayTransId,MaxSingleTransId,MinMainParlayTransId,MinSingleTransId,RequestId,RequestType,SingleCount,TransIds,VoidFromTime,VoidToTime,Usernames,ProductIds,TicketStatusIds,FromWinlostDate,ToWinlostDate, SubIssueTypeId
FROM	OPENQUERY(DBTXN, ''\
DECLARE	@StartDate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @StartDate, 121) + ''''';
DECLARE	@EndDate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @EndDate, 121) + ''''';

SELECT	AwayId,FilterBy,FilterFromBetId,FilterFromTransTime,FilterToBetId,FilterToTransTime,HomeId,Id,IsCheckedAwayTeam,IsCheckedHomeTeam,IsFilterByTransTime,IssueDetail,KickOffTime,LeagueId,LiveAwayScore,LiveHomeScore,MainParlayCount,MatchId,MaxMainParlayTransId,MaxSingleTransId,MinMainParlayTransId,MinSingleTransId,RequestId,RequestType,SingleCount,TransIds,VoidFromTime,VoidToTime,Usernames,ProductIds,TicketStatusIds,FromWinlostDate,ToWinlostDate, SubIssueTypeId
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
	;'');';

		EXECUTE	sys.sp_executesql @Query;
		
	END;

	---------------Table 2: TicketVoiding_Request_bk -----------------------------
	-- Need confirm: No sync column [SettlementStatus]?
	ELSE IF	@TableName = N'TicketVoiding_Request_bk'
	BEGIN;
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	#tmpRequest
	(	RequestId, Sporttype, SubIssueTypeId, ActionId, Provider, Source, DecidedBy, MistakenBy, Remark, CheckedBy, UserId, CreatedDate, LastModifiedBy, LastModifiedDate, IssueTypeId, IsTest)
SELECT	RequestId, Sporttype, SubIssueTypeId, ActionId, Provider, Source, DecidedBy, MistakenBy, Remark, CheckedBy, UserId, CreatedDate, LastModifiedBy, LastModifiedDate, IssueTypeId, IsTest
FROM	OPENQUERY(DBTXN, ''\
DECLARE	@StartDate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @StartDate, 121) + ''''';
DECLARE	@EndDate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @EndDate, 121) + ''''';

SELECT	t1.RequestId, Sporttype, SubIssueTypeId, ActionId, Provider, Source, DecidedBy, MistakenBy, Remark, CheckedBy, UserId, CreatedDate, LastModifiedBy, LastModifiedDate, IssueTypeId, IsTest
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
;'');';

		EXECUTE	sys.sp_executesql @Query;
		
		-----------------------------------------------
		INSERT INTO	dbo.TicketVoiding_Request_bk
			(	RequestId, Sporttype, SubIssueTypeId, ActionId, Provider, Source, DecidedBy, MistakenBy, Remark, CheckedBy, UserId, CreatedDate, LastModifiedBy, LastModifiedDate, IssueTypeId, IsTest)
		SELECT	RequestId, Sporttype, SubIssueTypeId, ActionId, Provider, Source, DecidedBy, MistakenBy, Remark, CheckedBy, UserId, CreatedDate, LastModifiedBy, LastModifiedDate, IssueTypeId, IsTest
		FROM #tmpRequest

		WHILE (1=1)
		BEGIN
			SET @RequestIds = ''
			DELETE @tmpRequest

			UPDATE TOP(100) r SET r.isFinish = 1
				OUTPUT deleted.RequestId
			INTO @tmpRequest
			FROM #tmpRequest r
			WHERE r.isFinish IS NULL

			IF @@ROWCOUNT = 0 BREAK

			SET @RequestIds = STUFF((SELECT ',' + CAST(RequestId AS VARCHAR(50)) FROM @tmpRequest FOR XML PATH('')),1,1,'')
			
			---------------Table: zzzbettransM_bk --------------------
			SELECT	@Query = '';
			SELECT	@Query = @Query + N'\
INSERT INTO	dbo.zzzbettransM_bk
	(transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, STATUS, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, matchid, bettype, keyid, VoidingHistoryId)
SELECT transid, custid, transdate, 
oddsid, hdp1, hdp2, odds, stake, STATUS, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, matchid, bettype, keyid, VoidingHistoryId
FROM	OPENQUERY(DBTXN, ''\
DECLARE	@RequestIds	NVARCHAR(MAX) = ''''' + CONVERT(NVARCHAR(MAX), @RequestIds) + ''''';

SELECT	transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, STATUS, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, matchid, bettype, keyid, t1.VoidingHistoryId
FROM	bodb02.dbo.zzzbettransM AS t1 WITH (NOLOCK)
	INNER JOIN bodb02.dbo.TicketVoiding_VoidingHistory v WITH (NOLOCK) ON v.VoidingHistoryId = t1.VoidingHistoryId
	CROSS APPLY (
				SELECT	val AS RequestId
				FROM	bodb02.dbo.f_SplitString(@RequestIds, '''','''')
				WHERE val = v.RequestId
		) r
WHERE	t1.VoidingHistoryId IS NOT NULL
	AND r.RequestId IS NOT NULL
OPTION (maxrecursion 0);'');';

			EXECUTE	sys.sp_executesql @Query;

		---------------Table: zzzbettrans_bk --------------------
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.zzzbettrans_bk
	(	transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, STATUS, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, matchid, bettype, keyid, VoidingHistoryId)
SELECT	transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, STATUS, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, matchid, bettype, keyid, VoidingHistoryId
FROM	OPENQUERY(DBTXN, ''\
DECLARE	@RequestIds	NVARCHAR(MAX) = ''''' + CONVERT(NVARCHAR(MAX), @RequestIds) + ''''';

SELECT	transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, STATUS, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, matchid, bettype, keyid, t1.VoidingHistoryId
FROM	bodb02.dbo.zzzbettrans AS t1 WITH (NOLOCK)
	INNER JOIN bodb02.dbo.TicketVoiding_VoidingHistory v WITH (NOLOCK) ON v.VoidingHistoryId = t1.VoidingHistoryId
		CROSS APPLY (
					SELECT	val AS RequestId
					FROM	bodb02.dbo.f_SplitString(@RequestIds, '''','''')
					WHERE val = v.RequestId
			) r
	WHERE	t1.VoidingHistoryId IS NOT NULL
		AND r.RequestId IS NOT NULL
	OPTION (maxrecursion 0)
	;'');';

		EXECUTE	sys.sp_executesql @Query;

		---------------Table: TicketVoiding_OperatorInfo_bk -----------------------------
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.TicketVoiding_OperatorInfo_bk
	(	 RequestId, OperatorId, OperatorTypeId, Id)
SELECT	RequestId, OperatorId, OperatorTypeId, Id
FROM	OPENQUERY(DBTXN, ''\
DECLARE	@RequestIds	NVARCHAR(MAX) = ''''' + CONVERT(NVARCHAR(MAX), @RequestIds) + ''''';

SELECT	t1.RequestId, OperatorId, OperatorTypeId, Id
FROM	bodb02.dbo.TicketVoiding_OperatorInfo AS t1 WITH (NOLOCK)
	CROSS APPLY (
					SELECT	val AS RequestId
					FROM	bodb02.dbo.f_SplitString(@RequestIds, '''','''')
					WHERE val = t1.RequestId
			) r
OPTION (maxrecursion 0)
	;'');';
		EXECUTE	sys.sp_executesql @Query;

		---------------Table:  TicketVoiding_Queue_bk -----------------------------
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.TicketVoiding_Queue_bk
	(	QueueId, RequestId, MatchId, VoidingHistoryId, TransIds, StatusId, UserId, Starttime, Exectime, Duration, IP, VoidingTypeId, TotalTicket, ErrMsg, FailedTransIds, NegativeBalanceUsers)
SELECT	QueueId, RequestId, MatchId, VoidingHistoryId, TransIds, StatusId, UserId, Starttime, Exectime, Duration, IP, VoidingTypeId, TotalTicket, ErrMsg, FailedTransIds, NegativeBalanceUsers
FROM	OPENQUERY(DBTXN, ''\
DECLARE	@RequestIds	NVARCHAR(MAX) = ''''' + CONVERT(NVARCHAR(MAX), @RequestIds) + ''''';

SELECT	QueueId, t1.RequestId, MatchId, VoidingHistoryId, TransIds, StatusId, UserId, Starttime, Exectime, Duration, IP, VoidingTypeId, TotalTicket, ErrMsg, FailedTransIds, NegativeBalanceUsers
FROM	bodb02.dbo.TicketVoiding_Queue AS t1 WITH (NOLOCK)
	CROSS APPLY (
					SELECT	val AS RequestId
					FROM	bodb02.dbo.f_SplitString(@RequestIds, '''','''')
					WHERE val = t1.RequestId
			) r
OPTION (maxrecursion 0)
	;'');';

		EXECUTE	sys.sp_executesql @Query;

		---------------Table:  TicketVoiding_VoidingHistory_bk -----------------------------
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.TicketVoiding_VoidingHistory_bk
	(	VoidingHistoryId, RequestId, MessageId, StatusId, ReasonId, UserId, CreatedDate, ModifiedDate, TransIds,VoidData)
SELECT	VoidingHistoryId, RequestId, MessageId, StatusId, ReasonId, UserId, CreatedDate, ModifiedDate, TransIds,CONVERT(xml,VoidData)
FROM	OPENQUERY(DBTXN, ''\
DECLARE	@RequestIds	NVARCHAR(MAX) = ''''' + CONVERT(NVARCHAR(MAX), @RequestIds) + ''''';

SELECT	VoidingHistoryId, t1.RequestId, MessageId, StatusId, ReasonId, UserId, CreatedDate, ModifiedDate, TransIds,CONVERT(NVARCHAR(MAX),VoidData) AS VoidData
FROM	bodb02.dbo.TicketVoiding_VoidingHistory AS t1 WITH (NOLOCK)
	CROSS APPLY (
					SELECT	val AS RequestId
					FROM	bodb02.dbo.f_SplitString(@RequestIds, '''','''')
					WHERE val = t1.RequestId
			) r
OPTION (maxrecursion 0)
	;'');';
		EXECUTE	sys.sp_executesql @Query;

		---------------Table:  TicketVoiding_RequestDetailTicket_Single_bk -----------------------------
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.TicketVoiding_RequestDetailTicket_Single_bk
	(	Id, RequestId, IssueTypeId, SubIssueTypeId,TransId, MatchId,RequestDetailId, bettype, betid)
SELECT	Id, RequestId, IssueTypeId, SubIssueTypeId,TransId, MatchId,RequestDetailId, bettype, betid
FROM	OPENQUERY(DBTXN, ''\
SELECT	t1.Id, t1.RequestId, t1.IssueTypeId, t1.SubIssueTypeId,t1.TransId, t1.MatchId,t1.RequestDetailId, t1.bettype, t1.betid
FROM	bodb02.dbo.TicketVoiding_RequestDetailTicket_Single AS t1 WITH (NOLOCK)
WHERE t1.requestid in (' + @requestids + ')
	;'');';

		EXECUTE	sys.sp_executesql @Query;

		---------------Table: TicketVoiding_RequestDetailTicket_SubParlay_bk -----------------------------
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.TicketVoiding_RequestDetailTicket_SubParlay_bk
	(	Id, RequestId, IssueTypeId, SubIssueTypeId,TransId, MatchId,RequestDetailId,MainTransId)
SELECT	Id, RequestId, IssueTypeId, SubIssueTypeId,TransId, MatchId,RequestDetailId,MainTransId
FROM	OPENQUERY(DBTXN, ''\
DECLARE	@RequestIds	NVARCHAR(MAX) = ''''' + CONVERT(NVARCHAR(MAX), @RequestIds) + ''''';

SELECT	Id, t1.RequestId, IssueTypeId, SubIssueTypeId,TransId, MatchId,RequestDetailId,MainTransId
FROM	bodb02.dbo.TicketVoiding_RequestDetailTicket_SubParlay AS t1 WITH (NOLOCK)
	CROSS APPLY (
					SELECT	val AS RequestId
					FROM	bodb02.dbo.f_SplitString(@RequestIds, '''','''')
					WHERE val = t1.RequestId
			) r
OPTION (maxrecursion 0)
	;'');';

		EXECUTE	sys.sp_executesql @Query;

		---------------Table:  TicketVoiding_Reason_bk -----------------------------
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.TicketVoiding_Reason_bk
	(	ReasonId, ReasonEnglish, ReasonChineseSimplified)
SELECT	ReasonId, ReasonEnglish, ReasonChineseSimplified
FROM	OPENQUERY(DBTXN, ''\
DECLARE	@RequestIds	NVARCHAR(MAX) = ''''' + CONVERT(NVARCHAR(MAX), @RequestIds) + ''''';

SELECT	t1.ReasonId, ReasonEnglish, ReasonChineseSimplified
FROM	bodb02.dbo.TicketVoiding_Reason AS t1 WITH (NOLOCK)
	INNER JOIN bodb02.dbo.TicketVoiding_VoidingHistory v WITH (NOLOCK) ON v.ReasonId = t1.ReasonId
		CROSS APPLY (
					SELECT	val AS RequestId
					FROM	bodb02.dbo.f_SplitString(@RequestIds, '''','''')
					WHERE val = v.RequestId
			) r
	WHERE	r.RequestId IS NOT NULL
	OPTION (maxrecursion 0)
	;'');';

		EXECUTE	sys.sp_executesql @Query;

		---------------Table:  TicketVoiding_AutoVoidRequest_Queue_bk -----------------------------
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.TicketVoiding_AutoVoidRequest_Queue_bk
	(	QueueId, RequestId, MatchId, [Action], StatusId, UserId, Starttime, Exectime, Duration, IP, ErrMsg, sporttype)
SELECT	QueueId, RequestId, MatchId, [Action], StatusId, UserId, Starttime, Exectime, Duration, IP, ErrMsg, sporttype
FROM	OPENQUERY(DBTXN, ''\
DECLARE	@RequestIds	NVARCHAR(MAX) = ''''' + CONVERT(NVARCHAR(MAX), @RequestIds) + ''''';

SELECT	QueueId, RequestId, MatchId, [Action], StatusId, UserId, Starttime, Exectime, Duration, IP, ErrMsg, sporttype
FROM	bodb02.dbo.TicketVoiding_AutoVoidRequest_Queue AS t1 WITH (NOLOCK)
WHERE	t1.requestid in (' + @requestids + ')
;'');';
		
		EXECUTE	sys.sp_executesql @Query;

		END
	END;

		
	---------------Table 5: TicketVoiding_AutoVoidRequest_Queue_bk --------------------
	ELSE IF	@TableName = N'TicketVoiding_AutoVoidRequest_Queue_bk'
	BEGIN;
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.TicketVoiding_AutoVoidRequest_Queue_bk
	(	QueueId, RequestId, MatchId, [Action], StatusId, UserId, Starttime, Exectime, Duration, IP, ErrMsg, sporttype)
SELECT	QueueId, RequestId, MatchId, [Action], StatusId, UserId, Starttime, Exectime, Duration, IP, ErrMsg, sporttype
FROM	OPENQUERY(DBTXN, ''\
DECLARE	@StartDate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @StartDate, 121) + ''''';
DECLARE	@EndDate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @EndDate, 121) + ''''';

SELECT	QueueId, RequestId, MatchId, [Action], StatusId, UserId, Starttime, Exectime, Duration, IP, ErrMsg, sporttype
FROM	bodb02.dbo.TicketVoiding_AutoVoidRequest_Queue AS t1 WITH (NOLOCK)
WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.match14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.matchid AND t2.eventdate BETWEEN @StartDate AND @EndDate)
	AND t1.RequestId = 0
;'');';

		EXECUTE	sys.sp_executesql @Query;
	END;

	---------------Table 6: TicketVoiding_AutoUnmarkSetting_bk --------------------
	ELSE IF	@TableName = N'TicketVoiding_AutoUnmarkSetting_bk'
	BEGIN;
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.TicketVoiding_AutoUnmarkSetting_bk
	(	ID, Matchid, Bettype, IsConfirm, CreatedDate, UserId, MarkedBy, betid)
SELECT	ID, Matchid, Bettype, IsConfirm, CreatedDate, UserId, MarkedBy, betid
FROM	OPENQUERY(DBTXN, ''\
DECLARE	@StartDate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @StartDate, 121) + ''''';
DECLARE	@EndDate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @EndDate, 121) + ''''';

SELECT	ID, Matchid, Bettype, IsConfirm, CreatedDate, UserId, MarkedBy, betid
FROM	bodb02.dbo.TicketVoiding_AutoUnmarkSetting AS t1 WITH (NOLOCK)
WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.match14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.matchid AND t2.eventdate BETWEEN @StartDate AND @EndDate);'');';

		EXECUTE	sys.sp_executesql @Query;
	END;


	---------------Table 7:  TicketVoiding_VoidedTransaction_bk -----------------------------
	ELSE IF	@TableName = N'TicketVoiding_VoidedTransaction_bk'
	BEGIN;
		--process for ticket single and main parlay and metrix gaming
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.TicketVoiding_VoidedTransaction_bk
	(	TransId, MessageId, ReasonId, MatchId, CreatedDate, Id, IssueTypeID, SubIssueTypeID, CustID)
SELECT	TransId, MessageId, ReasonId, MatchId, CreatedDate, Id, IssueTypeID, SubIssueTypeID, CustID
FROM	OPENQUERY(DBTXN, ''\
DECLARE	@StartDate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @StartDate, 121) + ''''';

SELECT	t1.TransId, t1.MessageId, t1.ReasonId,t1. MatchId, t1.CreatedDate, t1.Id, t1.IssueTypeID, t1.SubIssueTypeID, t1.CustID
FROM	bodb02.dbo.TicketVoiding_VoidedTransaction AS t1 WITH (NOLOCK)
	INNER JOIN bodb02.dbo.bettrans14 AS t2 WITH (NOLOCK) ON t2.transid = t1.TransId and t2.winlostdate = @StartDate
WHERE	EXISTS (SELECT 1 from bodb02.dbo.SportBettypeMatrix t3 WITH (NOLOCK) where t2.bettype=t3.BetType
					 AND t3.ProductID IN (1,3,5,25,27,37) AND t2.statusID=102 and t1.matchid=0 )
UNION 

SELECT	t1.TransId, t1.MessageId, t1.ReasonId,t1. MatchId, t1.CreatedDate, t1.Id, t1.IssueTypeID, t1.SubIssueTypeID, t1.CustID
FROM	bodb02.dbo.TicketVoiding_VoidedTransaction AS t1 WITH (NOLOCK)
	INNER JOIN bodb02.dbo.bettrans14 AS t2 WITH (NOLOCK) ON t2.refno = t1.TransId and t2.winlostdate = @StartDate 
WHERE	EXISTS (SELECT 1 from bodb02.dbo.SportBettypeMatrix t3 WITH (NOLOCK) WHERE t2.bettype=t3.BetType AND t3.bettype != 29 
					AND t3.ProductID =1 AND t2.statusID=102)
					
	;'');';

		EXECUTE	sys.sp_executesql @Query;
		
		--process for ticket sub parlay (sportbook and virtual sport)
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.TicketVoiding_VoidedTransaction_bk
	(	TransId, MessageId, ReasonId, MatchId, CreatedDate, Id, IssueTypeID, SubIssueTypeID, CustID)
SELECT	TransId, MessageId, ReasonId, MatchId, CreatedDate, Id, IssueTypeID, SubIssueTypeID, CustID
FROM	OPENQUERY(DBTXN, ''\
DECLARE	@StartDate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @StartDate, 121) + ''''';

SELECT	TransId, MessageId, ReasonId, MatchId, CreatedDate, Id, IssueTypeID, SubIssueTypeID, CustID
FROM	bodb02.dbo.TicketVoiding_VoidedTransaction AS t1 WITH (NOLOCK)
WHERE 	EXISTS (SELECT 1 FROM bodb02.dbo.match14 AS t2 WITH (NOLOCK) WHERE t1.MatchId != 0 AND  t1.matchid = t2.matchid AND t2.eventdate = @StartDate)
	;'');';
					
		EXECUTE	sys.sp_executesql @Query;
	END;
	
	---------------Table 4: zzzbettrans_bk --------------------
	ELSE IF	@TableName = N'zzzbettrans_bk'
	BEGIN;
		SELECT	@Query = N'';
		SELECT	@Query = @Query + N'\
INSERT INTO	dbo.zzzbettrans_bk
	(	transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, STATUS, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, matchid, bettype, keyid, VoidingHistoryId)
SELECT	transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, STATUS, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, matchid, bettype, keyid, VoidingHistoryId
FROM	OPENQUERY(DBTXN, ''\
DECLARE	@StartDate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @StartDate, 121) + ''''';

SELECT	t1.transid, t1.custid, t1.transdate, t1.oddsid, t1.hdp1, t1.hdp2, t1.odds, t1.stake, t1.STATUS, t1.winlost, t1.livehomescore, t1.liveawayscore, t1.liveindicator, t1.betteam, t1.creator, t1.refno, t1.comstatus, t1.winlostdate, t1.betfrom, t1.betcheck, t1.checktime, t1.matchid, t1.bettype, t1.keyid, t1.VoidingHistoryId
FROM	bodb02.dbo.zzzbettrans AS t1 WITH (NOLOCK)
	INNER JOIN bodb02.dbo.bettrans14 AS t2 WITH (NOLOCK) ON t1.transid = t2.transid AND t2.winlostdate = @StartDate
WHERE	t1.VoidingHistoryId IS NULL	
	AND EXISTS (SELECT 1 FROM bodb02.dbo.SportBettypeMatrix t3 WITH (NOLOCK) WHERE t2.bettype=t3.BetType
						AND t3.ProductID IN (1,3,5,25,27,37) AND t2.statusID=102 )
UNION 
SELECT	t1.transid, t1.custid, t1.transdate, t1.oddsid, t1.hdp1, t1.hdp2, t1.odds, t1.stake, t1.STATUS, t1.winlost, t1.livehomescore, t1.liveawayscore, t1.liveindicator, t1.betteam, t1.creator, t1.refno, t1.comstatus, t1.winlostdate, t1.betfrom, t1.betcheck, t1.checktime, t1.matchid, t1.bettype, t1.keyid, t1.VoidingHistoryId
FROM	bodb02.dbo.zzzbettrans AS t1 WITH (NOLOCK)
	INNER JOIN bodb02.dbo.bettransm14 t2 WITH (NOLOCK) ON t1.transid = t2.transid AND t2.statusID=102 and t1.matchid=t2.matchid AND t2.winlostdate = @StartDate
WHERE	t1.VoidingHistoryId IS NULL	
				
;'');';

		EXECUTE	sys.sp_executesql @Query;
	END
	---------------Table 3: zzzbettransM_bk --------------------
	ELSE IF	@TableName = N'zzzbettransM_bk'
	BEGIN;
			SELECT	@Query = '';
			SELECT	@Query = @Query + N'\
INSERT INTO	dbo.zzzbettransM_bk
	(transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, STATUS, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, matchid, bettype, keyid, VoidingHistoryId)
SELECT transid, custid, transdate, 
oddsid, hdp1, hdp2, odds, stake, STATUS, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, matchid, bettype, keyid, VoidingHistoryId
FROM	OPENQUERY(DBTXN, ''\
DECLARE	@StartDate	SMALLDATETIME = ''''' + CONVERT(NVARCHAR(50), @StartDate, 121) + ''''';

SELECT	transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, STATUS, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, matchid, bettype, keyid, VoidingHistoryId
FROM	bodb02.dbo.zzzbettransM AS t1 WITH (NOLOCK)
WHERE	EXISTS (SELECT 1 FROM bodb02.dbo.bettransm14 AS t2 WITH (NOLOCK) WHERE t1.transid = t2.transid AND t2.statusID=102 and t1.matchid=t2.matchid AND t2.winlostdate = @StartDate)
	AND t1.VoidingHistoryId IS NULL;'');';

			EXECUTE	sys.sp_executesql @Query;
	END

END
GO
/*<info serverAlias="DBARC-bodb_archive" executers="" viewers="" isFunction="0" isNested="1"></info>*/