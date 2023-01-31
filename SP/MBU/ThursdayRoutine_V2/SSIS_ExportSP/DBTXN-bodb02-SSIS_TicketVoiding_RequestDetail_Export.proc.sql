/*<info serverAlias="DBCTG-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_TicketVoiding_RequestDetail_Export]
	@winlostdate smalldatetime=null
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]	
	Database: DBTXN.bodb02
	Original: DB06x.bodb_archive.Task_Archive_Copy 
	
	Revisions:
		- 20130831@Bobby: Init
		- 20221003@Max: [TVS] Enhance archive process of TVS data regarding the Scale Out DB project - [Redmine: #178234]
 */
 BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    ---------match--------------------
	SELECT	AwayId,FilterBy,FilterFromTransTime,FilterToTransTime,HomeId,Id,IssueDetail,KickOffTime,LeagueId,LiveAwayScore,LiveHomeScore,MainParlayCount,MatchId,RequestId,RequestType,SingleCount,TransIds,VoidFromTime,VoidToTime,Usernames,ProductIds,TicketStatusIds,FromWinlostDate,ToWinlostDate, SubIssueTypeId
	FROM	dbo.TicketVoiding_RequestDetail AS t1 WITH (NOLOCK)
	WHERE	t1.MatchId NOT IN (9,29,2799)
		AND EXISTS (SELECT 1 FROM dbo.match14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.matchid AND t2.eventdate = @winlostdate)

	---------- outright -----------
	UNION --ALL
	SELECT	AwayId,FilterBy,FilterFromTransTime,FilterToTransTime,HomeId,Id,IssueDetail,KickOffTime,LeagueId,LiveAwayScore,LiveHomeScore,MainParlayCount,MatchId,RequestId,RequestType,SingleCount,TransIds,VoidFromTime,VoidToTime,Usernames,ProductIds,TicketStatusIds,FromWinlostDate,ToWinlostDate, SubIssueTypeId
	FROM	dbo.TicketVoiding_RequestDetail AS t1 WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.outright14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.orid AND t2.eventdate = @winlostdate)

	---------- VSOutright -----------
	UNION --ALL
	SELECT	AwayId,FilterBy,FilterFromTransTime,FilterToTransTime,HomeId,Id,IssueDetail,KickOffTime,LeagueId,LiveAwayScore,LiveHomeScore,MainParlayCount,MatchId,RequestId,RequestType,SingleCount,TransIds,VoidFromTime,VoidToTime,Usernames,ProductIds,TicketStatusIds,FromWinlostDate,ToWinlostDate, SubIssueTypeId
	FROM	dbo.TicketVoiding_RequestDetail AS t1 WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.VSOutright14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.orid AND t2.eventdate = @winlostdate)

	--------------- VSRaceInfo ------------------
	UNION --ALL
	SELECT	AwayId,FilterBy,FilterFromTransTime,FilterToTransTime,HomeId,Id,IssueDetail,KickOffTime,LeagueId,LiveAwayScore,LiveHomeScore,MainParlayCount,MatchId,RequestId,RequestType,SingleCount,TransIds,VoidFromTime,VoidToTime,Usernames,ProductIds,TicketStatusIds,FromWinlostDate,ToWinlostDate, SubIssueTypeId
	FROM	dbo.TicketVoiding_RequestDetail AS t1 WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.VSRaceInfo14 AS t2 WITH (NOLOCK) WHERE t1.matchid = t2.EventID AND t2.EventTime = @winlostdate)

	-----------  RequestDetail ---------
	UNION --ALL
	SELECT	AwayId,FilterBy,FilterFromTransTime,FilterToTransTime,HomeId,Id,IssueDetail,KickOffTime,LeagueId,LiveAwayScore,LiveHomeScore,MainParlayCount,MatchId,RequestId,RequestType,SingleCount,TransIds,VoidFromTime,VoidToTime,Usernames,ProductIds,TicketStatusIds,FromWinlostDate,ToWinlostDate, SubIssueTypeId
	FROM	dbo.TicketVoiding_RequestDetail AS t1 WITH (NOLOCK)
	CROSS APPLY (
			SELECT max(b.winlostdate) as winlostdate
			FROM dbo.TicketVoiding_RequestDetailTicket_Single s WITH (NOLOCK)
				INNER JOIN dbo.bettrans b WITH (NOLOCK) ON b.transid = s.TransId AND s.MatchId IN (9,29,2799)
				WHERE s.RequestId = t1.RequestId
			
			UNION --ALL
			SELECT max(b.winlostdate) as winlostdate
			FROM dbo.TicketVoiding_RequestDetailTicket_Single s WITH (NOLOCK)
				INNER JOIN dbo.bettrans14 b WITH (NOLOCK) ON b.transid = s.TransId AND s.MatchId IN (9,29,2799)
				WHERE s.RequestId = t1.RequestId
		)t
	WHERE t1.MatchId IN (9,29,2799)
		AND t.winlostdate = @winlostdate

END
GO

