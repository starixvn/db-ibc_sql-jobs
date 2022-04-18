/*<info serverAlias="DBSSIS-SSISDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_DR_Package_Report_Status]
	@SessionID int=0
AS
/*
	Created by:	20220415@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]				
	Database:	DBSSIS.SSISDB
	Revisions:
		- 20220415@Bobby: Init
*/
BEGIN
	SET NOCOUNT ON;
	declare @endTask BIT = 0, @environment varchar(15);

	select @environment = ISNULL(p.Environment,'NA')
	FROM dbo.SSIS_PackageRuntime p WITH(NOLOCK)
	WHERE p.RuntimeID=@SessionID
	
	WHILE 1 = 1
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.SSIS_PackageRuntime WITH(NOLOCK) WHERE SessionID=@SessionID AND [Status] ='Running')
		BEGIN
			SET @endTask = 1;
			BREAK;
		END
		ELSE
			WAITFOR DELAY '00:01:00'

	END

	UPDATE p WITH(rowlock,updlock)
	SET [Status] = case when @endTask =  1 then 'Closed' else  [Status] end
		, EndTime = case when @endTask =  1 then GETDATE() end
		, SessionID=@SessionID
	FROM dbo.SSIS_PackageRuntime p
	WHERE p.RuntimeID=@SessionID
	
	IF (@endTask = 1 AND @@SERVERNAME LIKE 'DBDW%')
	BEGIN
		DECLARE @Notify	NVARCHAR(4000);
		WITH cte_stats
		AS (
			SELECT MIN(StartTime) AS StartTime
				,MAX(EndTime) AS EndTime
				,datediff(MINUTE, MIN(StartTime), MAX(EndTime)) AS duration_MIN
				,SUM(CASE WHEN DynamicMappingID > 0 AND Error = 0 THEN 1 ELSE 0 END) AS SuccessCnt
				,SUM(CASE WHEN DynamicMappingID > 0 AND Error > 0 THEN 1 ELSE 0 END) AS FailedCnt
			FROM dbo.SSIS_PackageRuntime rt WITH (NOLOCK)
			WHERE rt.RuntimeID >= @SessionID AND rt.SessionID = @SessionID
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
		SELECT @Notify = N'[' + @environment + '-' + @@SERVERNAME + ']@[DBA : SSIS Thursday-routine] completed. ' + 
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