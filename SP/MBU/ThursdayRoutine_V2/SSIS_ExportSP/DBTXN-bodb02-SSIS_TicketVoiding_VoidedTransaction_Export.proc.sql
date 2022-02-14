/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_TicketVoiding_VoidedTransaction_Export]
	@winlostdate smalldatetime=null
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]	
	Database: DBTXN.bodb02
	Original: DB06x.bodb_archive.Task_Archive_Copy 
	
	Revisions:
		- 20130831@Bobby: Init
 */
 BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--process for ticket single and main parlay and metrix gaming
	SELECT	t1.TransId, t1.MessageId, t1.ReasonId,t1. MatchId, t1.CreatedDate, t1.Id, t1.IssueTypeID, t1.SubIssueTypeID, t1.CustID
	FROM	dbo.TicketVoiding_VoidedTransaction AS t1 WITH (NOLOCK)
		INNER JOIN dbo.bettrans14 AS t2 WITH (NOLOCK) ON t2.transid = t1.TransId and t2.winlostdate = @winlostdate
	WHERE	EXISTS (SELECT 1 from dbo.SportBettypeMatrix t3 WITH (NOLOCK) where t2.bettype=t3.BetType
						 AND t3.ProductID IN (1,3,5,25,27,37) AND t2.statusID=102 and t1.matchid=0 )
	UNION 

	SELECT	t1.TransId, t1.MessageId, t1.ReasonId,t1. MatchId, t1.CreatedDate, t1.Id, t1.IssueTypeID, t1.SubIssueTypeID, t1.CustID
	FROM	dbo.TicketVoiding_VoidedTransaction AS t1 WITH (NOLOCK)
		INNER JOIN dbo.bettrans14 AS t2 WITH (NOLOCK) ON t2.refno = t1.TransId and t2.winlostdate = @winlostdate 
	WHERE	EXISTS (SELECT 1 from dbo.SportBettypeMatrix t3 WITH (NOLOCK) WHERE t2.bettype=t3.BetType AND t3.bettype != 29 
					AND t3.ProductID =1 AND t2.statusID=102)

	--process for ticket sub parlay (sportbook and virtual sport)
	UNION --ALL
	SELECT	TransId, MessageId, ReasonId, MatchId, CreatedDate, Id, IssueTypeID, SubIssueTypeID, CustID
	FROM	dbo.TicketVoiding_VoidedTransaction AS t1 WITH (NOLOCK)
	WHERE 	EXISTS (SELECT 1 FROM dbo.match14 AS t2 WITH (NOLOCK) WHERE t1.MatchId != 0 AND  t1.matchid = t2.matchid AND t2.eventdate = @winlostdate);

END
GO
