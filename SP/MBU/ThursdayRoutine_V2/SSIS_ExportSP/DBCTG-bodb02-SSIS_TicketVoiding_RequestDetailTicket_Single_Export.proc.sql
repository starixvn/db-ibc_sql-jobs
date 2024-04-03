/*<info serverAlias="DBCTG-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_TicketVoiding_RequestDetailTicket_Single_Export]
	@winlostdate smalldatetime=null
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]	
	Database: DBCTG.bodb02
	Original: DB06x.bodb_archive.Task_Archive_Copy 
	
	Revisions:
		- 20130831@Bobby: Init
		- 20220315@Kathy: Change to use STRING_SPLIT [Redmine:#166457]
		- 20220603@July: Get column CustId from active table [Redmine:#172634]
		- 20221003@Max: [TVS] Enhance archive process of TVS data regarding the Scale Out DB project - [Redmine: #178234]
		- 20230329@Max: [TVS] Cancel Cash-Out if action CO in danger time range [Redmine: #176998]
		- 20240403@July: [TVS] SP tuning for EC2024 [Redmine: #200840]
		
 */
 BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @tmpRequest TABLE (RequestId INT);

	INSERT INTO @tmpRequest(RequestId)
	SELECT RequestID
	FROM dbo.Task_Archive_TVS tvs WITH (NOLOCK)
	WHERE tvs.Winlostdate = @winlostdate

	SELECT	t1.Id, t1.RequestId, t1.IssueTypeId, t1.SubIssueTypeId, t1.TransId, t1.MatchId, t1.RequestDetailId
		,t1.Bettype, t1.BetId, t1.CustId, t1.SiteDBGroupID, t1.IsProcessed, t1.IsCancelCO
		,NULL AS Winlostdate
	FROM @tmpRequest r
		INNER JOIN dbo.TicketVoiding_RequestDetailTicket_Single AS t1 WITH (NOLOCK) ON r.RequestId = t1.RequestId
	WHERE t1.MatchId NOT IN (9, 29, 2799, 10449)
	
	UNION
	---------bettrans--------------------
	SELECT	t1.Id, t1.RequestId, t1.IssueTypeId, t1.SubIssueTypeId, t1.TransId, t1.MatchId, t1.RequestDetailId
		,t1.Bettype, t1.BetId, t1.CustId, t1.SiteDBGroupID, t1.IsProcessed, t1.IsCancelCO
		,b.winlostdate AS Winlostdate
	FROM @tmpRequest r
		INNER JOIN dbo.TicketVoiding_RequestDetailTicket_Single AS t1 WITH (NOLOCK) ON r.RequestId = t1.RequestId
		INNER JOIN dbo.bettrans b WITH (NOLOCK) ON b.transid = t1.TransId
	WHERE t1.MatchId IN (9, 29, 2799, 10449)
	
	---------bettrans14--------------------
	UNION
	SELECT	t1.Id, t1.RequestId, t1.IssueTypeId, t1.SubIssueTypeId, t1.TransId, t1.MatchId, t1.RequestDetailId
		,t1.Bettype, t1.BetId, t1.CustId, t1.SiteDBGroupID, t1.IsProcessed, t1.IsCancelCO
		,b.winlostdate AS Winlostdate
	FROM @tmpRequest r
		INNER JOIN dbo.TicketVoiding_RequestDetailTicket_Single AS t1 WITH (NOLOCK) ON r.RequestId = t1.RequestId
		INNER JOIN dbo.bettrans14 b WITH (NOLOCK) ON b.transid = t1.TransId
	WHERE t1.MatchId IN (9, 29, 2799, 10449)

END
GO

