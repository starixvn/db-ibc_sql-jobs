/*<info serverAlias="DBSSIS-SSISDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_Package_Report_Status]
	@processID int=0
	,@status varchar(10)='SUCCESS'
	,@runEvent bit=null
	,@runTVS bit=null
	,@runTransfer bit=null
	,@runBet14 bit=null
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]				
	Database:	DBSSIS.SSISDB
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
	SET [Status] = case when @cntTask =  2 then 'Closed' else  [Status] end
		, EndTime = case when @cntTask =  2 then GETDATE() end
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
		('Process Transfer', @runTransfer),
		('Process Bet14', @runBet14)
	) as t (item, val)
	WHERE t.val = CASE WHEN @status = 'SUCCESS' THEN 1 ELSE 0 END
	
	IF (@cntTask = 2 AND @@SERVERNAME LIKE 'DBDW%')
	BEGIN
		DECLARE @Notify	NVARCHAR(4000);
		WITH cte_stats
		AS (
			SELECT MIN(StartTime) AS StartTime
				,MAX(EndTime) AS EndTime
				,datediff(MINUTE, MIN(StartTime), MAX(EndTime)) AS duration_MIN
				,SUM(CASE WHEN DynamicMappingID > 0 AND Error = 0 THEN 1 ELSE 0 END) AS SuccessCnt
				,SUM(CASE WHEN DynamicMappingID > 0 AND Error > 0 THEN 1 ELSE 0 END) AS FailedCnt
			FROM SSIS_PackageRuntime rt WITH (NOLOCK)
			WHERE rt.RuntimeID >= @processID AND rt.SessionID = @processID
		)
		,cte_report
		AS (
			SELECT StartTime
				,EndTime
				,duration_MIN / 60 AS [Hours]
				,duration_MIN % 60 AS [Minutes]
				,SuccessCnt
				,FailedCnt
			FROM cte_stats
		)
		SELECT @Notify = N'[' + @@SERVERNAME + ']@[DBA : SSIS Thursday-routine] completed. ' + 
						'Durations in [Hours: ' + cast([Hours] AS VARCHAR(10)) + '/Minutes: ' + cast([Minutes] AS VARCHAR(10)) + ']. ' +
						'Status in [Success: ' + cast([SuccessCnt] AS VARCHAR(10)) + '/Failed: ' + cast([FailedCnt] AS VARCHAR(10)) + '].'
		FROM cte_report

		BEGIN TRY
			EXEC DBNOTI.NotificationDB.[dbo].[DBA_Skype_NewMessage]
						@ServerName			= 'PONTUS'
					,	@JobName			= N'Custom Message'
					,	@Message			= @Notify
		END TRY
		BEGIN CATCH
			--TODO:
		END CATCH

	END
END
GO
