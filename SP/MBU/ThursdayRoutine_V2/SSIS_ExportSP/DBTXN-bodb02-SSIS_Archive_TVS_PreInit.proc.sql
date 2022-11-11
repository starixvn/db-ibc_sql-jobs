/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_Archive_TVS_PreInit]
	@StartDate smalldatetime=null,
	@EndDate smalldatetime=null
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]				
	Database:	DBTXN.bodb02
	Revisions:
		- 20130831@Bobby: Init
		- 20221003@Max: [TVS] Enhance archive process of TVS data regarding the Scale Out DB project - [Redmine: #178234]
*/
BEGIN
	SET NOCOUNT ON;
	DELETE tvs FROM dbo.Task_Archive_TVS tvs;

	INSERT INTO dbo.Task_Archive_TVS(Winlostdate, RequestId, VoidingHistoryIds)
	SELECT	t.Max_EventDate AS Winlostdate, t1.RequestId, vh.VoidingHistoryIds
	FROM	dbo.TicketVoiding_Request AS t1 WITH (NOLOCK)
	CROSS APPLY (
		SELECT MAX(m.eventdate) AS Max_EventDate
		FROM	dbo.TicketVoiding_RequestDetail AS rd WITH (NOLOCK)
			CROSS APPLY (
				SELECT t2.eventdate AS eventdate
				FROM	dbo.match14 AS t2 WITH (NOLOCK)
				WHERE	rd.MatchId NOT IN (9,29,2799) AND rd.MatchId = t2.matchid AND rd.RequestId = t1.RequestId
				UNION ALL
				SELECT t2.eventdate AS eventdate
				FROM	 dbo.match AS t2 WITH (NOLOCK)
				WHERE	rd.MatchId NOT IN (9,29,2799) AND rd.MatchId = t2.matchid AND rd.RequestId = t1.RequestId

				UNION ALL
				SELECT t2.eventdate
				FROM	dbo.outright14 AS t2 WITH (NOLOCK) 
				WHERE rd.matchid = t2.orid AND rd.RequestId = t1.RequestId
				UNION ALL
				SELECT t2.eventdate
				FROM	dbo.outright AS t2 WITH (NOLOCK) 
				WHERE rd.matchid = t2.orid AND rd.RequestId = t1.RequestId

				UNION ALL
				SELECT t2.EventDate
				FROM	dbo.VSOutright14 AS t2 WITH (NOLOCK) 
				WHERE rd.matchid = t2.orid AND rd.RequestId = t1.RequestId
				UNION ALL
				SELECT t2.EventDate
				FROM	dbo.VSOutright AS t2 WITH (NOLOCK) 
				WHERE rd.matchid = t2.orid AND rd.RequestId = t1.RequestId

				UNION ALL
				SELECT t2.EventTime
				FROM	dbo.VSRaceInfo14 AS t2 WITH (NOLOCK) 
				WHERE rd.matchid = t2.EventID AND rd.RequestId = t1.RequestId
				UNION ALL
				SELECT t2.EventTime
				FROM	dbo.VSRaceInfo AS t2 WITH (NOLOCK) 
				WHERE rd.matchid = t2.EventID AND rd.RequestId = t1.RequestId

				UNION ALL
				SELECT MAX(bt.winlostdate) AS eventdate
				FROM	dbo.TicketVoiding_RequestDetailTicket_Single s WITH (NOLOCK)
					CROSS APPLY (
							SELECT  b.winlostdate as winlostdate
							FROM	dbo.bettrans b WITH (NOLOCK) 
							WHERE b.transid = s.TransId AND s.MatchId IN (9,29,2799) AND s.RequestId = t1.RequestId AND s.MatchId = rd.MatchId
			
							UNION ALL
							SELECT b.winlostdate as winlostdate
							FROM dbo.bettrans14 b WITH (NOLOCK) 
							WHERE b.transid = s.TransId AND s.MatchId IN (9,29,2799) AND s.RequestId = t1.RequestId AND s.MatchId = rd.MatchId
					)bt
			)m
		WHERE  rd.RequestId = t1.RequestId
	)t
	OUTER APPLY (
		SELECT STUFF((SELECT ',' + CAST(v.VoidingHistoryId AS VARCHAR(50))
		FROM dbo.TicketVoiding_VoidingHistory v WITH (NOLOCK)
		WHERE v.RequestId = t1.RequestId
		FOR XML PATH('')),1,1,'') AS VoidingHistoryIds
	)vh
	WHERE  1=1
		and t.Max_EventDate BETWEEN @StartDate AND @EndDate

	SELECT *
	FROM dbo.Task_Archive_TVS WITH(NOLOCK)
END
GO
