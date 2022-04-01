/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_TicketVoiding_Reason_Export]
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
 */
 BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	declare @tmpRequest table(RequestId INT);
	declare @RequestIds nvarchar(max);

	-- GET TVS RequestId from [SSIS_Archive_TVS_PreInit]
	insert into @tmpRequest(RequestId)
	select requestid
	from dbo.Task_Archive_TVS tvs with(nolock)
	where tvs.Winlostdate=@winlostdate

	SET @RequestIds = STUFF((SELECT ',' + CAST(RequestId AS VARCHAR(50)) FROM @tmpRequest FOR XML PATH('')),1,1,'')

	SELECT	t1.ReasonId, ReasonEnglish, ReasonChineseSimplified
	FROM	dbo.TicketVoiding_Reason AS t1 WITH (NOLOCK)
	INNER JOIN dbo.TicketVoiding_VoidingHistory v WITH (NOLOCK) ON v.ReasonId = t1.ReasonId
		CROSS APPLY (
					SELECT	value AS RequestId
					FROM	STRING_SPLIT(@RequestIds, ',')
					WHERE value = v.RequestId
			) r
	WHERE	r.RequestId IS NOT NULL;

END
GO

