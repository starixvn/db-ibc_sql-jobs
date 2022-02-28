/*<info serverAlias="DBWH-SSISDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_Package_Report_Status]
	@processID int=0
	,@status varchar(10)='SUCCESS'
	,@runEvent bit=null
	,@runTVS bit=null
	,@runTransfer bit=null
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]				
	Database:	DBTP.SSISDB
	Revisions:
		- 20130831@Bobby: Init
*/
BEGIN
	SET NOCOUNT ON;
	declare @message varchar(250), @cntTask INT;

	select @message = ISNULL([Message],'')
	FROM dbo.SSIS_PackageRuntime p WITH(NOLOCK)
	WHERE p.RuntimeID=@processID

	SELECT @cntTask = LEN(@message) - LEN(REPLACE(@message, '#', ''))

	UPDATE p WITH(rowlock,updlock)
	SET [Status] = case when @cntTask =  1 then 'Closed' else  [Status] end
		, EndTime = case when @cntTask =  1 then GETDATE() end
		, SessionID=@processID
		, [Message] = @message + case when LEN(@message) = 0 then '' else '#' end + @status
	FROM dbo.SSIS_PackageRuntime p
	WHERE p.RuntimeID=@processID

	-- report status
	SELECT @status AS [status],t.item
	FROM (
		values
		('Process Event', @runEvent),
		('Process TVS', @runTVS),
		('Process Transfer', @runTransfer)
	) as t (item, val)
	WHERE t.val = CASE WHEN @status = 'SUCCESS' THEN 1 ELSE 0 END
END
GO
