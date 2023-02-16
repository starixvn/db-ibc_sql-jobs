/*<info serverAlias="DBCTG-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_TicketVoiding_RequestDetailTicket_Single_Export]
	@winlostdate smalldatetime=null
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]	
	Database: DBTXN.bodb02
	Original: DB06x.bodb_archive.Task_Archive_Copy 
	
	Revisions:
		- 20130831@Bobby: Init
		- 20220315@Kathy: Change to use STRING_SPLIT [Redmine:#166457]
		- 20220603@July: Get column CustId from active table [Redmine:#172634]
		- 20221003@Max: [TVS] Enhance archive process of TVS data regarding the Scale Out DB project - [Redmine: #178234]
		
 */
 BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	declare @tmpRequest table(RequestId INT);
	declare @RequestIds nvarchar(max);

	INSERT INTO @tmpRequest(RequestId)
	SELECT RequestID
	FROM dbo.Task_Archive_TVS tvs with(nolock)
	WHERE tvs.Winlostdate=@winlostdate

	SET @RequestIds = STUFF((SELECT ',' + CAST(RequestId AS VARCHAR(50)) FROM @tmpRequest FOR XML PATH('')),1,1,'')

	SELECT	t1.Id, t1.RequestId, t1.IssueTypeId, t1.SubIssueTypeId,t1.TransId, t1.MatchId,t1.RequestDetailId
		,t1.Bettype, t1.BetId, t1.CustId, t1.SiteDBGroupID, t1.IsProcessed
	FROM	dbo.TicketVoiding_RequestDetailTicket_Single AS t1 WITH (NOLOCK)
	CROSS APPLY (
		SELECT	cast(value as int) AS RequestId
		FROM	STRING_SPLIT(@RequestIds, ',')
		WHERE value = t1.RequestId
	) r;

END
GO

