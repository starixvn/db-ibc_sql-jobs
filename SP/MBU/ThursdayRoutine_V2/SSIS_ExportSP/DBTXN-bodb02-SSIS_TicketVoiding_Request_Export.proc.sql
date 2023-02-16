/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_TicketVoiding_Request_Export]
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

    SELECT	t1.RequestId, Sporttype, ActionId, Provider, Source, DecidedBy, MistakenBy, Remark, CheckedBy, UserId, CreatedDate, LastModifiedBy, LastModifiedDate, IssueTypeId, IsTest
	FROM	dbo.TicketVoiding_Request AS t1 WITH (NOLOCK)
	INNER JOIN dbo.Task_Archive_TVS tvs with(nolock) on tvs.RequestID = t1.RequestID
	WHERE  tvs.Winlostdate = @winlostdate

END
GO

