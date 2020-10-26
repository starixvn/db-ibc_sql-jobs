/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="" viewers="" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_Sync_CustomerLog_Verify] @DateCheck DATETIME
	, @IsDebug BIT = 0
AS
/*   
 Task : Verify yesterday data
 DB: DB054.bodb_customerLog
 Revisions:
	- 20201022@Patrick: Change email to starixvn [Redmine: #143607]

*/  

BEGIN
	SET NOCOUNT ON
	DECLARE @LocalServer sysname, @RemoteServer SYSNAME
	
	SET @LocalServer = @@SERVERNAME
	SET @RemoteServer = (SELECT * FROM OPENQUERY (DBLOG, 'SELECT @@SERVERNAME'))
	
	-- invalid remote server
	IF @localServer = @remoteServer RETURN -- same server, do nothing.

	DECLARE @FromDate DATETIME, @ToDate DATETIME, @SqlQuery NVARCHAR(1024)
		, @MinDate DATETIME, @MaxDate DATETIME

	SELECT @DateCheck = CONVERT(VARCHAR(12), @DateCheck, 112)
	
	DECLARE @tblMissingDataSource TABLE (MinLogId BIGINT, MaxLogId BIGINT, MinLogDate DATETIME, MaxLogDate DATETIME, TableName VARCHAR(125), LogCount INT, DateCheck DATETIME)
	DECLARE @tblMissingDataTarget TABLE (MinLogId BIGINT, MaxLogId BIGINT, MinLogDate DATETIME, MaxLogDate DATETIME, TableName VARCHAR(125), LogCount INT, DateCheck DATETIME)

	--AppLog_Machine --> ignore
	--AppLog_Category --> ignore

	IF DATENAME(dw, @DateCheck) = 'Monday'
		SELECT @MinDate = DATEADD(DAY, -7, @DateCheck), @MaxDate = @DateCheck
	ELSE
		SELECT @MinDate = @DateCheck, @MaxDate = @DateCheck

	WHILE @MinDate <= @MaxDate
	BEGIN
		SELECT @DateCheck = @MinDate
		SELECT @MinDate = DATEADD(DAY, 1, @MinDate)
		SELECT @FromDate = @DateCheck, @ToDate = DATEADD(dd, 1, @DateCheck)

		BEGIN --UserLog_CasinoAPI
			INSERT INTO @tblMissingDataTarget(TableName, MinLogId, MaxLogId, MinLogDate, MaxLogDate, LogCount)
			SELECT 'UserLog_CasinoAPI' AS TableName
				, MIN(LogID) AS MinLogId
				, MAX(LogID) AS MaxLogId
				, MIN(LogDate) AS MinLogDate
				, MAX(LogDate) AS MaxLogDate
				, COUNT(1) AS LogCount
			FROM dbo.UserLog_CasinoAPI WITH(NOLOCK)
			WHERE LogDate >= @FromDate AND LogDate < @ToDate
			OPTION (RECOMPILE, MAXDOP 8)

			SELECT @SqlQuery = ''
			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT ''''UserLog_CasinoAPI'''' AS TableName, MIN(LogID) AS MinLogId, MAX(LogID) AS MaxLogId, MIN(LogDate) AS MinLogDate, MAX(LogDate) AS MaxLogDate, COUNT(1) AS LogCount 
							FROM bodb_CustomerLog.dbo.UserLog_CasinoAPI WITH (NOLOCK)
							WHERE LogDate >= ''''' + CONVERT(VARCHAR(50), @FromDate, 112) + ''''' AND LogDate < ''''' + CONVERT(VARCHAR(50), @ToDate, 112) + '''''
							OPTION (RECOMPILE, MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery

			INSERT INTO @tblMissingDataSource(TableName, MinLogId, MaxLogId, MinLogDate, MaxLogDate, LogCount)
			EXEC sp_executesql @SqlQuery

		END

		BEGIN --UserLog_Credit
			INSERT INTO @tblMissingDataTarget(TableName, MinLogId, MaxLogId, MinLogDate, MaxLogDate, LogCount)
			SELECT 'UserLog_Credit' AS TableName
				, MIN(LogID) AS MinLogId
				, MAX(LogID) AS MaxLogId
				, MIN(LogDate) AS MinLogDate
				, MAX(LogDate) AS MaxLogDate
				, COUNT(1) AS LogCount
			FROM dbo.UserLog_Credit WITH(NOLOCK)
			WHERE LogDate >= @FromDate AND LogDate < @ToDate
			OPTION (RECOMPILE, MAXDOP 8)

			SELECT @SqlQuery = ''
			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT ''''UserLog_Credit'''' AS TableName, MIN(LogID) AS MinLogId, MAX(LogID) AS MaxLogId, MIN(LogDate) AS MinLogDate, MAX(LogDate) AS MaxLogDate, COUNT(1) AS LogCount 
							FROM bodb_CustomerLog.dbo.UserLog_Credit WITH (NOLOCK)
							WHERE LogDate >= ''''' + CONVERT(VARCHAR(50), @FromDate, 112) + ''''' AND LogDate < ''''' + CONVERT(VARCHAR(50), @ToDate, 112) + '''''
							OPTION (RECOMPILE, MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery

			INSERT INTO @tblMissingDataSource(TableName, MinLogId, MaxLogId, MinLogDate, MaxLogDate, LogCount)
			EXEC sp_executesql @SqlQuery

		END

		BEGIN --UserLog_Exchange
			INSERT INTO @tblMissingDataTarget(TableName, MinLogId, MaxLogId, MinLogDate, MaxLogDate, LogCount)
			SELECT 'UserLog_Exchange' AS TableName
				, MIN(LogID) AS MinLogId
				, MAX(LogID) AS MaxLogId
				, MIN(LogDate) AS MinLogDate
				, MAX(LogDate) AS MaxLogDate
				, COUNT(1) AS LogCount
			FROM dbo.UserLog_Exchange WITH(NOLOCK)
			WHERE LogDate >= @FromDate AND LogDate < @ToDate
			OPTION (RECOMPILE, MAXDOP 8)

			SELECT @SqlQuery = ''
			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT ''''UserLog_Exchange'''' AS TableName, MIN(LogID) AS MinLogId, MAX(LogID) AS MaxLogId, MIN(LogDate) AS MinLogDate, MAX(LogDate) AS MaxLogDate, COUNT(1) AS LogCount 
							FROM bodb_CustomerLog.dbo.UserLog_Exchange WITH (NOLOCK)
							WHERE LogDate >= ''''' + CONVERT(VARCHAR(50), @FromDate, 112) + ''''' AND LogDate < ''''' + CONVERT(VARCHAR(50), @ToDate, 112) + '''''
							OPTION (RECOMPILE, MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery

			INSERT INTO @tblMissingDataSource(TableName, MinLogId, MaxLogId, MinLogDate, MaxLogDate, LogCount)
			EXEC sp_executesql @SqlQuery

		END

		BEGIN --UserLog_Login
			INSERT INTO @tblMissingDataTarget(TableName, MinLogId, MaxLogId, MinLogDate, MaxLogDate, LogCount)
			SELECT 'UserLog_Login' AS TableName
				, MIN(LogID) AS MinLogId
				, MAX(LogID) AS MaxLogId
				, MIN(LogDate) AS MinLogDate
				, MAX(LogDate) AS MaxLogDate
				, COUNT(1) AS LogCount
			FROM dbo.UserLog_Login WITH(NOLOCK)
			WHERE LogDate >= @FromDate AND LogDate < @ToDate
			OPTION (RECOMPILE, MAXDOP 8)

			SELECT @SqlQuery = ''
			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT ''''UserLog_Login'''' AS TableName, MIN(LogID) AS MinLogId, MAX(LogID) AS MaxLogId, MIN(LogDate) AS MinLogDate, MAX(LogDate) AS MaxLogDate, COUNT(1) AS LogCount 
							FROM bodb_CustomerLog.dbo.UserLog_Login WITH (NOLOCK)
							WHERE LogDate >= ''''' + CONVERT(VARCHAR(50), @FromDate, 112) + ''''' AND LogDate < ''''' + CONVERT(VARCHAR(50), @ToDate, 112) + '''''
							OPTION (RECOMPILE, MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery

			INSERT INTO @tblMissingDataSource(TableName, MinLogId, MaxLogId, MinLogDate, MaxLogDate, LogCount)
			EXEC sp_executesql @SqlQuery

		END

		BEGIN --UserLog_Login_Lrf
			INSERT INTO @tblMissingDataTarget(TableName, MinLogId, MaxLogId, MinLogDate, MaxLogDate, LogCount)
			SELECT 'UserLog_Login_Lrf' AS TableName
				, MIN(LogID) AS MinLogId
				, MAX(LogID) AS MaxLogId
				, MIN(LogDate) AS MinLogDate
				, MAX(LogDate) AS MaxLogDate
				, COUNT(1) AS LogCount
			FROM dbo.UserLog_Login_Lrf WITH(NOLOCK)
			WHERE LogDate >= @FromDate AND LogDate < @ToDate
			OPTION (RECOMPILE, MAXDOP 8)

			SELECT @SqlQuery = ''
			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT ''''UserLog_Login_Lrf'''' AS TableName, MIN(LogID) AS MinLogId, MAX(LogID) AS MaxLogId, MIN(LogDate) AS MinLogDate, MAX(LogDate) AS MaxLogDate, COUNT(1) AS LogCount 
							FROM bodb_CustomerLog.dbo.UserLog_Login_Lrf WITH (NOLOCK)
							WHERE LogDate >= ''''' + CONVERT(VARCHAR(50), @FromDate, 112) + ''''' AND LogDate < ''''' + CONVERT(VARCHAR(50), @ToDate, 112) + '''''
							OPTION (RECOMPILE, MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery

			INSERT INTO @tblMissingDataSource(TableName, MinLogId, MaxLogId, MinLogDate, MaxLogDate, LogCount)
			EXEC sp_executesql @SqlQuery

		END

		BEGIN --UserLog_RunSP
			DECLARE @MinLogId BIGINT, @MaxLogId BIGINT
			DECLARE @tmp1 TABLE(MinLogId BIGINT)
			INSERT INTO @tmp1(MinLogId)
			SELECT MIN(LogId) FROM dbo.UserLog_RunSP WITH(NOLOCK) WHERE LogDate >= @FromDate OPTION (RECOMPILE, MAXDOP 8)

			SELECT @MinLogId = MinLogId FROM @tmp1

			INSERT INTO @tblMissingDataTarget(TableName, MinLogId, MaxLogId, MinLogDate, MaxLogDate, LogCount)
			SELECT 'UserLog_RunSP' AS TableName
				, MIN(LogID) AS MinLogId
				, MAX(LogID) AS MaxLogId
				, MIN(LogDate) AS MinLogDate
				, MAX(LogDate) AS MaxLogDate
				, COUNT(1) AS LogCount
			FROM dbo.UserLog_RunSP WITH(NOLOCK)
			WHERE LogDate >= @FromDate AND LogDate < @ToDate AND LogId >= @MinLogId
			OPTION (RECOMPILE, MAXDOP 8)

			SELECT @MinLogId = MinLogId, @MaxLogId = MaxLogId
			FROM @tblMissingDataTarget WHERE TableName = 'UserLog_RunSP'

			SELECT @SqlQuery = ''
			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT ''''UserLog_RunSP'''' AS TableName, MIN(LogID) AS MinLogId, MAX(LogID) AS MaxLogId, MIN(LogDate) AS MinLogDate, MAX(LogDate) AS MaxLogDate, COUNT(1) AS LogCount 
							FROM bodb_CustomerLog.dbo.UserLog_RunSP WITH (NOLOCK)
							WHERE LogDate >= ''''' + CONVERT(VARCHAR(50), @FromDate, 112) + ''''' AND LogDate < ''''' + CONVERT(VARCHAR(50), @ToDate, 112) + '''''
								AND LogId BETWEEN ' + CAST(@MinLogId AS VARCHAR(50)) + ' AND ' + CAST(@MaxLogId AS VARCHAR(50)) + '  
							OPTION (RECOMPILE, MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery

			INSERT INTO @tblMissingDataSource(TableName, MinLogId, MaxLogId, MinLogDate, MaxLogDate, LogCount)
			EXEC sp_executesql @SqlQuery

		END

		BEGIN --UserLog_Settle
			INSERT INTO @tblMissingDataTarget(TableName, MinLogId, MaxLogId, MinLogDate, MaxLogDate, LogCount)
			SELECT 'UserLog_Settle' AS TableName
				, MIN(LogID) AS MinLogId
				, MAX(LogID) AS MaxLogId
				, MIN(LogDate) AS MinLogDate
				, MAX(LogDate) AS MaxLogDate
				, COUNT(1) AS LogCount
			FROM dbo.UserLog_Settle WITH(NOLOCK)
			WHERE LogDate >= @FromDate AND LogDate < @ToDate
			OPTION (RECOMPILE, MAXDOP 8)

			SELECT @SqlQuery = ''
			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT ''''UserLog_Settle'''' AS TableName, MIN(LogID) AS MinLogId, MAX(LogID) AS MaxLogId, MIN(LogDate) AS MinLogDate, MAX(LogDate) AS MaxLogDate, COUNT(1) AS LogCount 
							FROM bodb_CustomerLog.dbo.UserLog_Settle WITH (NOLOCK)
							WHERE LogDate >= ''''' + CONVERT(VARCHAR(50), @FromDate, 112) + ''''' AND LogDate < ''''' + CONVERT(VARCHAR(50), @ToDate, 112) + '''''
							OPTION (RECOMPILE, MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery

			INSERT INTO @tblMissingDataSource(TableName, MinLogId, MaxLogId, MinLogDate, MaxLogDate, LogCount)
			EXEC sp_executesql @SqlQuery

		END

		BEGIN --UserLog_Settle_Checking
			INSERT INTO @tblMissingDataTarget(TableName, MinLogId, MaxLogId, MinLogDate, MaxLogDate, LogCount)
			SELECT 'UserLog_Settle_Checking' AS TableName
				, MIN(LogID) AS MinLogId
				, MAX(LogID) AS MaxLogId
				, MIN(LogDate) AS MinLogDate
				, MAX(LogDate) AS MaxLogDate
				, COUNT(1) AS LogCount
			FROM dbo.UserLog_Settle_Checking WITH(NOLOCK)
			WHERE LogDate >= @FromDate AND LogDate < @ToDate
			OPTION (RECOMPILE, MAXDOP 8)

			SELECT @SqlQuery = ''
			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT ''''UserLog_Settle_Checking'''' AS TableName, MIN(LogID) AS MinLogId, MAX(LogID) AS MaxLogId, MIN(LogDate) AS MinLogDate, MAX(LogDate) AS MaxLogDate, COUNT(1) AS LogCount 
							FROM bodb_CustomerLog.dbo.UserLog_Settle_Checking WITH (NOLOCK)
							WHERE LogDate >= ''''' + CONVERT(VARCHAR(50), @FromDate, 112) + ''''' AND LogDate < ''''' + CONVERT(VARCHAR(50), @ToDate, 112) + '''''
							OPTION (RECOMPILE, MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery

			INSERT INTO @tblMissingDataSource(TableName, MinLogId, MaxLogId, MinLogDate, MaxLogDate, LogCount)
			EXEC sp_executesql @SqlQuery

		END

		BEGIN --UserLog_Transaction
			INSERT INTO @tblMissingDataTarget(TableName, MinLogId, MaxLogId, MinLogDate, MaxLogDate, LogCount)
			SELECT 'UserLog_Transaction' AS TableName
				, MIN(LogID) AS MinLogId
				, MAX(LogID) AS MaxLogId
				, MIN(LogDate) AS MinLogDate
				, MAX(LogDate) AS MaxLogDate
				, COUNT(1) AS LogCount
			FROM dbo.UserLog_Transaction WITH(NOLOCK)
			WHERE LogDate >= @FromDate AND LogDate < @ToDate
			OPTION (RECOMPILE, MAXDOP 8)

			SELECT @SqlQuery = ''
			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT ''''UserLog_Transaction'''' AS TableName, MIN(LogID) AS MinLogId, MAX(LogID) AS MaxLogId, MIN(LogDate) AS MinLogDate, MAX(LogDate) AS MaxLogDate, COUNT(1) AS LogCount 
							FROM bodb_CustomerLog.dbo.UserLog_Transaction WITH (NOLOCK)
							WHERE LogDate >= ''''' + CONVERT(VARCHAR(50), @FromDate, 112) + ''''' AND LogDate < ''''' + CONVERT(VARCHAR(50), @ToDate, 112) + '''''
							OPTION (RECOMPILE, MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery

			INSERT INTO @tblMissingDataSource(TableName, MinLogId, MaxLogId, MinLogDate, MaxLogDate, LogCount)
			EXEC sp_executesql @SqlQuery

		END

		BEGIN --UserLog_Transfer
			INSERT INTO @tblMissingDataTarget(TableName, MinLogId, MaxLogId, MinLogDate, MaxLogDate, LogCount)
			SELECT 'UserLog_Transfer' AS TableName
				, MIN(LogID) AS MinLogId
				, MAX(LogID) AS MaxLogId
				, MIN(LogDate) AS MinLogDate
				, MAX(LogDate) AS MaxLogDate
				, COUNT(1) AS LogCount
			FROM dbo.UserLog_Transfer WITH(NOLOCK)
			WHERE LogDate >= @FromDate AND LogDate < @ToDate
			OPTION (RECOMPILE, MAXDOP 8)

			SELECT @SqlQuery = ''
			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT ''''UserLog_Transfer'''' AS TableName, MIN(LogID) AS MinLogId, MAX(LogID) AS MaxLogId, MIN(LogDate) AS MinLogDate, MAX(LogDate) AS MaxLogDate, COUNT(1) AS LogCount 
							FROM bodb_CustomerLog.dbo.UserLog_Transfer WITH (NOLOCK)
							WHERE LogDate >= ''''' + CONVERT(VARCHAR(50), @FromDate, 112) + ''''' AND LogDate < ''''' + CONVERT(VARCHAR(50), @ToDate, 112) + '''''
							OPTION (RECOMPILE, MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery

			INSERT INTO @tblMissingDataSource(TableName, MinLogId, MaxLogId, MinLogDate, MaxLogDate, LogCount)
			EXEC sp_executesql @SqlQuery

		END

		BEGIN --UserLog_UserControl
			INSERT INTO @tblMissingDataTarget(TableName, MinLogId, MaxLogId, MinLogDate, MaxLogDate, LogCount)
			SELECT 'UserLog_UserControl' AS TableName
				, MIN(LogID) AS MinLogId
				, MAX(LogID) AS MaxLogId
				, MIN(LogDate) AS MinLogDate
				, MAX(LogDate) AS MaxLogDate
				, COUNT(1) AS LogCount
			FROM dbo.UserLog_UserControl WITH(NOLOCK)
			WHERE LogDate >= @FromDate AND LogDate < @ToDate
			OPTION (RECOMPILE, MAXDOP 8)

			SELECT @SqlQuery = ''
			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT ''''UserLog_UserControl'''' AS TableName, MIN(LogID) AS MinLogId, MAX(LogID) AS MaxLogId, MIN(LogDate) AS MinLogDate, MAX(LogDate) AS MaxLogDate, COUNT(1) AS LogCount 
							FROM bodb_CustomerLog.dbo.UserLog_UserControl WITH (NOLOCK)
							WHERE LogDate >= ''''' + CONVERT(VARCHAR(50), @FromDate, 112) + ''''' AND LogDate < ''''' + CONVERT(VARCHAR(50), @ToDate, 112) + '''''
							OPTION (RECOMPILE, MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery

			INSERT INTO @tblMissingDataSource(TableName, MinLogId, MaxLogId, MinLogDate, MaxLogDate, LogCount)
			EXEC sp_executesql @SqlQuery

		END

		--
		UPDATE @tblMissingDataTarget
		SET DateCheck = @FromDate
		WHERE DateCheck IS NULL

		UPDATE @tblMissingDataSource
		SET DateCheck = @FromDate
		WHERE DateCheck IS NULL

		WAITFOR DELAY '00:00:01:000'

	END
	
	--final step
	SELECT *
	FROM @tblMissingDataSource s
		LEFT JOIN @tblMissingDataTarget t ON s.TableName = t.TableName AND s.DateCheck = t.DateCheck
	WHERE ISNULL(s.LogCount, 0) <> ISNULL(t.LogCount, 0)
		OR ISNULL(s.MaxLogId, 0) <> ISNULL(t.MaxLogId, 0)
		OR ISNULL(s.MinLogId, 0) <> ISNULL(t.MinLogId, 0)

	IF @@ROWCOUNT > 0
	BEGIN
		--send out the mail to notify
		DECLARE @email_body NVARCHAR(MAX), @subject NVARCHAR(200), @RowData VARCHAR(MAX)
		SET @email_body = '
		   <html>
			  <body>
  				<style>
				  table {border-collapse: collapse;}
				  table, td, th {border: 1px solid black;}
				  th {text-align: left; padding: 8px;}
				</style>
				<h1>Syncing CustomerLog To Standby Server Check!</h1>
				<p><b>Check time: ' + CONVERT(VARCHAR(50), GETDATE(), 121) + '</p>
				<div style="background-color:red;color:white;text-align:center">Failure</div>
				<p></p>
				<table>
				  <tr>
					<th rowspan="2" style="text-align:center">Table Name</th>
					<th colspan="5" style="text-align:center">Source</th>
					<th colspan="5" style="text-align:center">Target</th>
				  </tr>
				  <tr>
					<th style="text-align:center">Row Count</th>
					<th style="text-align:center">Min LogId</th>
					<th style="text-align:center">Max LogId</th>
					<th style="text-align:center">Min LogDate</th>
					<th style="text-align:center">Max LogDate</th>
					<th style="text-align:center">Row Count</th>
					<th style="text-align:center">Min LogId</th>
					<th style="text-align:center">Max LogId</th>
					<th style="text-align:center">Min LogDate</th>
					<th style="text-align:center">Max LogDate</th>
				  </tr>
				  {<row>}
			  </table>
			  </body>
			</html>'

		SET @RowData = CONVERT(VARCHAR(MAX), (SELECT s.TableName AS 'td1'
													, ISNULL(s.LogCount, 0) AS 'td2'
													, ISNULL(s.MinLogId, 0) AS 'td1'
													, ISNULL(s.MaxLogId, 0) AS 'td2'
													, CONVERT(VARCHAR(50), ISNULL(s.MinLogDate, '1900-01-01'), 121) AS 'td1'
													, CONVERT(VARCHAR(50), ISNULL(s.MaxLogDate, '1900-01-01'), 121) AS 'td2'
													, ISNULL(t.LogCount, 0) AS 'td1'
													, ISNULL(t.MinLogId, 0) AS 'td2'
													, ISNULL(t.MaxLogId, 0) AS 'td1'
													, CONVERT(VARCHAR(50), ISNULL(t.MinLogDate, '1900-01-01'), 121) AS 'td2'
													, CONVERT(VARCHAR(50), ISNULL(t.MaxLogDate, '1900-01-01'), 121) AS 'td1'
												FROM @tblMissingDataSource s
													INNER JOIN @tblMissingDataTarget t ON s.TableName = t.TableName AND s.DateCheck = t.DateCheck
												WHERE ISNULL(s.LogCount, 0) <> ISNULL(t.LogCount, 0)
													OR ISNULL(s.MaxLogId, 0) <> ISNULL(t.MaxLogId, 0)
													OR ISNULL(s.MinLogId, 0) <> ISNULL(t.MinLogId, 0)
												ORDER BY s.TableName, s.DateCheck 
											   FOR XML PATH('tr'), TYPE
											  ))    
		SET  @RowData = REPLACE(REPLACE(@RowData, 'td1>', 'td>'), 'td2>', 'td>')
		SET @email_body = REPLACE(@email_body, '{<row>}', @RowData)
		SELECT @subject	= N'Syncing CustomerLog To Standby Server Check - KBT@' + @@SERVERNAME
		
		IF @IsDebug = 0
		BEGIN
			EXECUTE msdb.dbo.sp_send_dbmail @profile_name	= DEFAULT
			   , @recipients			 = 'pontus@starixvn.com'
			   , @copy_recipients		 = ''
			   , @blind_copy_recipients	 = ''
			   , @subject				 = @subject
			   , @body					 = @email_body
			   , @body_format			 = 'HTML';
		END
	END
END
GO


