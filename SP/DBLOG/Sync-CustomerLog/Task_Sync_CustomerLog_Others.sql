/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb_CustomerLog]
GO
ALTER PROCEDURE [dbo].[Task_Sync_CustomerLog_Others] @IsDebug BIT = 0
AS
/*   
 Task : copy CustomerLog data from active server to standby server
 DB: DB054.bodb_customerLog
 Revisions:   
	- 20190624@Patrick: Add more table TicketVoiding_Log
	
*/  

BEGIN
	SET NOCOUNT ON
	
	DECLARE @LocalServer SYSNAME, @RemoteServer SYSNAME
	
	SET @LocalServer = @@SERVERNAME
	SET @RemoteServer = (SELECT * FROM OPENQUERY (DBLOG, 'SELECT @@SERVERNAME'))
	--SELECT @localServer, @remoteServer
	
	-- invalid remote server
	IF @localServer = @remoteServer RETURN -- same server, do nothing.
	
	DECLARE @MaxCurrLogId BIGINT, @SqlQuery NVARCHAR(1024), @LastWeek DATETIME, @3MonthsAgo DATETIME
		, @MaxCurrLogDate DATETIME, @CurrentDate DATETIME, @ToLogDate DATETIME, @ScheduleTime DATETIME

	DECLARE @TblTmpData TABLE (MaxCurrLogDate DATETIME, MaxCurrLogId BIGINT, TableName VARCHAR(125))

	SELECT @LastWeek = DATEADD(DAY, -7, GETDATE())
		, @CurrentDate = DATEADD(MINUTE, -3, GETDATE())
		, @ToLogDate = DATEADD(MINUTE, -3, GETDATE())
		, @3MonthsAgo = DATEADD(MONTH, -3, GETDATE())

	IF @IsDebug IS NULL
		SET @IsDebug = 0
	
	BEGIN --Age_PageVisit
		SELECT @ScheduleTime = KeyValue FROM dbo.SyncingLog_Setting WITH(NOLOCK) WHERE KeyId = 'Age_PageVisit'
		IF DATEDIFF(MINUTE, @ScheduleTime, @CurrentDate) > 30
		BEGIN
			CREATE TABLE #TmpDataSync (PageUrl VARCHAR(50), AgVisits INT, MAgVisits INT, SAgVisits INT)

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT PageUrl, AgVisits, MAgVisits, SAgVisits
							FROM bodb_CustomerLog.dbo.Age_PageVisit WITH (NOLOCK)
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1 
				PRINT @SqlQuery
			ELSE
			BEGIN
			
				INSERT INTO #TmpDataSync(PageUrl, AgVisits, MAgVisits, SAgVisits)
				EXEC sp_executesql @SqlQuery

				IF @@ROWCOUNT > 0
				BEGIN
					--SET IDENTITY_INSERT dbo.Age_PageVisit ON

					;MERGE dbo.Age_PageVisit t
					USING #TmpDataSync s ON t.PageUrl = s.PageUrl
					WHEN MATCHED THEN 
						UPDATE SET AgVisits = s.AgVisits, MAgVisits = s.MAgVisits, SAgVisits = s.SAgVisits
					WHEN NOT MATCHED BY TARGET THEN
						INSERT (PageUrl, AgVisits, MAgVisits, SAgVisits)
						VALUES(s.PageUrl, s.AgVisits, s.MAgVisits, s.SAgVisits)
					WHEN NOT MATCHED BY SOURCE THEN
						DELETE;

					--SET IDENTITY_INSERT dbo.Age_PageVisit OFF
				END

			END

			UPDATE dbo.SyncingLog_Setting WITH(ROWLOCK)
			SET KeyValue = CONVERT(VARCHAR(50), @CurrentDate, 121)
			WHERE KeyId = 'Age_PageVisit'
			
			DROP TABLE #TmpDataSync
		END
	END

	BEGIN --AgentFunctionUsage
		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate
		SELECT @MaxCurrLogId = MAX(Id), @MaxCurrLogDate = MAX(LogDate)
		FROM dbo.AgentFunctionUsage WITH (NOLOCK)
		WHERE LogDate > @3MonthsAgo
		
		IF @MaxCurrLogId = 0 OR @MaxCurrLogDate IS NULL
		BEGIN
			PRINT 'Some things wrong for [AgentFunctionUsage]. Please check!!!'
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [AgentFunctionUsage]. Please check!!!'
		END
		ELSE
		BEGIN

			AgentFunctionUsage_OneMore:
			IF @MaxCurrLogDate < DATEADD(HOUR, -3, @CurrentDate)
				SET @ToLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
			ELSE
				SET @ToLogDate = @CurrentDate

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT Id, ServerId, [Function], SubFunction, Lang, Count, LogDate
							FROM bodb_CustomerLog.dbo.AgentFunctionUsage WITH (NOLOCK)
							WHERE ID > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate >= ''''' + CONVERT(VARCHAR(50), @MaxCurrLogDate, 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(50), @ToLogDate, 121) + '''''
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				SET IDENTITY_INSERT dbo.AgentFunctionUsage ON
				BEGIN TRY
					INSERT INTO dbo.AgentFunctionUsage(Id, ServerId, [Function], SubFunction, Lang, Count, LogDate)
					EXEC sp_executesql @SqlQuery

					IF @@ROWCOUNT = 0 AND @ToLogDate < @CurrentDate
					BEGIN
						SET @MaxCurrLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
						GOTO AgentFunctionUsage_OneMore
					END

				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.AgentFunctionUsage WITH(ROWLOCK)
					WHERE Id > @MaxCurrLogId AND LogDate >= @MaxCurrLogDate
				
					--retry
					INSERT INTO dbo.AgentFunctionUsage(Id, ServerId, [Function], SubFunction, Lang, Count, LogDate)
					EXEC sp_executesql @SqlQuery

				END CATCH
				SET IDENTITY_INSERT dbo.AgentFunctionUsage OFF
			END
		END
	END

	BEGIN --AppLog_CategoryLog

		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate

		SELECT @MaxCurrLogId = MAX(CategoryLogID)
		FROM dbo.AppLog_CategoryLog t WITH (NOLOCK)
			INNER JOIN dbo.AppLog_Log tt WITH(NOLOCK) ON t.LogID = tt.LogID
		WHERE Timestamp > @3MonthsAgo
		
		IF @MaxCurrLogId = 0
		BEGIN
			PRINT 'Some things wrong for [AppLog_CategoryLog]. Please check!!!'
		END
		ELSE
		BEGIN
			
			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT TOP(1024) CategoryLogID, CategoryID, LogID
							FROM bodb_CustomerLog.dbo.AppLog_CategoryLog WITH (NOLOCK)
							WHERE CategoryLogID > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + '''''
							ORDER BY CategoryLogID
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				SET IDENTITY_INSERT dbo.AppLog_CategoryLog ON
				BEGIN TRY
					INSERT INTO dbo.AppLog_CategoryLog(CategoryLogID, CategoryID, LogID)
					EXEC sp_executesql @SqlQuery

				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.AppLog_CategoryLog WITH(ROWLOCK)
					WHERE CategoryLogID > @MaxCurrLogId
				
					--retry
					INSERT INTO dbo.AppLog_CategoryLog(CategoryLogID, CategoryID, LogID)
					EXEC sp_executesql @SqlQuery

				END CATCH
				SET IDENTITY_INSERT dbo.AppLog_CategoryLog OFF
			END
		END
	END

	BEGIN --AppLog_Log

		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate

		SELECT @MaxCurrLogId = MAX(LogID)
		FROM dbo.AppLog_Log t WITH (NOLOCK)
		WHERE Timestamp > @3MonthsAgo
		
		IF @MaxCurrLogId = 0
		BEGIN
			PRINT 'Some things wrong for [AppLog_Log]. Please check!!!'
		END
		ELSE
		BEGIN
			
			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT TOP(1024) LogID, EventID, Priority, Severity, Title, Timestamp, MachineName, AppDomainName, ProcessID, ProcessName, ThreadName, Win32ThreadId, Message, FormattedMessage, MachineId, IsMonitored, MonitoringUserId
							FROM bodb_CustomerLog.dbo.AppLog_Log WITH (NOLOCK)
							WHERE LogID > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + '''''
							ORDER BY LogID
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				SET IDENTITY_INSERT dbo.AppLog_Log ON
				BEGIN TRY
					INSERT INTO dbo.AppLog_Log(LogID, EventID, Priority, Severity, Title, Timestamp, MachineName, AppDomainName, ProcessID, ProcessName, ThreadName, Win32ThreadId, Message, FormattedMessage, MachineId, IsMonitored, MonitoringUserId)
					EXEC sp_executesql @SqlQuery
				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.AppLog_Log WITH(ROWLOCK)
					WHERE LogID > @MaxCurrLogId
				
					--retry
					INSERT INTO dbo.AppLog_Log (LogID, EventID, Priority, Severity, Title, Timestamp, MachineName, AppDomainName, ProcessID, ProcessName, ThreadName, Win32ThreadId, Message, FormattedMessage, MachineId, IsMonitored, MonitoringUserId)
					EXEC sp_executesql @SqlQuery

				END CATCH
				SET IDENTITY_INSERT dbo.AppLog_Log OFF
			END
		END
	END

	BEGIN --eaUserLog_Login

		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate

		SELECT @MaxCurrLogId = MAX(LogID), @MaxCurrLogDate = MAX(LogDate)
		FROM dbo.eaUserLog_Login t WITH (NOLOCK)
		WHERE LogDate > @3MonthsAgo
		
		IF @MaxCurrLogId = 0
		BEGIN
			PRINT 'Some things wrong for [eaUserLog_Login]. Please check!!!'
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [UserLog_Login]. Please check!!!'
		END
		ELSE
		BEGIN
			
			eaUserLog_Login_OneMore:
			IF @MaxCurrLogDate < DATEADD(HOUR, -3, @CurrentDate)
				SET @ToLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
			ELSE
				SET @ToLogDate = @CurrentDate

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT LogID, UserID, IP, LogDate, ActionID, TrackingValue, DomainName, BrowserName, Platform, CountryCode, Duration, CreatedDate
							FROM bodb_CustomerLog.dbo.eaUserLog_Login WITH (NOLOCK)
							WHERE LogID > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate >= ''''' + CONVERT(VARCHAR(50), @MaxCurrLogDate, 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(50), @ToLogDate, 121) + '''''
							ORDER BY LogID
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				SET IDENTITY_INSERT dbo.eaUserLog_Login ON
				BEGIN TRY
					INSERT INTO dbo.eaUserLog_Login(LogID, UserID, IP, LogDate, ActionID, TrackingValue, DomainName, BrowserName, Platform, CountryCode, Duration, CreatedDate)
					EXEC sp_executesql @SqlQuery

					IF @@ROWCOUNT = 0 AND @ToLogDate < @CurrentDate
					BEGIN
						SET @MaxCurrLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
						GOTO eaUserLog_Login_OneMore
					END

				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.eaUserLog_Login WITH(ROWLOCK)
					WHERE LogID > @MaxCurrLogId AND LogDate >= @MaxCurrLogDate
				
					--retry
					INSERT INTO dbo.eaUserLog_Login (LogID, UserID, IP, LogDate, ActionID, TrackingValue, DomainName, BrowserName, Platform, CountryCode, Duration, CreatedDate)
					EXEC sp_executesql @SqlQuery

				END CATCH
				SET IDENTITY_INSERT dbo.eaUserLog_Login OFF
			END
		END
	END

	BEGIN --eaUserLog_RunSP

		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate

		SELECT @MaxCurrLogId = MAX(LogID), @MaxCurrLogDate = MAX(LogDate)
		FROM dbo.eaUserLog_RunSP t WITH (NOLOCK)
		WHERE LogDate > @3MonthsAgo
		
		IF @MaxCurrLogId = 0
		BEGIN
			PRINT 'Some things wrong for [eaUserLog_RunSP]. Please check!!!'
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [UserLog_Login]. Please check!!!'
		END
		ELSE
		BEGIN
			
			eaUserLog_RunSP_OneMore:
			IF @MaxCurrLogDate < DATEADD(HOUR, -3, @CurrentDate)
				SET @ToLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
			ELSE
				SET @ToLogDate = @CurrentDate

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT LogID, UserID, Logdate, CustID, ActionID, TrackingValue, Duration, TrackingValue2
							FROM bodb_CustomerLog.dbo.eaUserLog_RunSP WITH (NOLOCK)
							WHERE LogID > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate >= ''''' + CONVERT(VARCHAR(50), @MaxCurrLogDate, 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(50), @ToLogDate, 121) + '''''
							ORDER BY LogID
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				SET IDENTITY_INSERT dbo.eaUserLog_RunSP ON
				BEGIN TRY
					INSERT INTO dbo.eaUserLog_RunSP(LogID, UserID, Logdate, CustID, ActionID, TrackingValue, Duration, TrackingValue2)
					EXEC sp_executesql @SqlQuery

					IF @@ROWCOUNT = 0 AND @ToLogDate < @CurrentDate
					BEGIN
						SET @MaxCurrLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
						GOTO eaUserLog_RunSP_OneMore
					END

				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.eaUserLog_RunSP WITH(ROWLOCK)
					WHERE LogID > @MaxCurrLogId AND LogDate >= @MaxCurrLogDate
				
					--retry
					INSERT INTO dbo.eaUserLog_RunSP (LogID, UserID, Logdate, CustID, ActionID, TrackingValue, Duration, TrackingValue2)
					EXEC sp_executesql @SqlQuery

				END CATCH
				SET IDENTITY_INSERT dbo.eaUserLog_RunSP OFF
			END
		END
	END

	BEGIN --eaUserLog_UserControl

		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate

		SELECT @MaxCurrLogId = MAX(LogID), @MaxCurrLogDate = MAX(LogDate)
		FROM dbo.eaUserLog_UserControl t WITH (NOLOCK)
		WHERE LogDate > @3MonthsAgo
		
		IF @MaxCurrLogId = 0
		BEGIN
			PRINT 'Some things wrong for [eaUserLog_UserControl]. Please check!!!'
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [UserLog_Login]. Please check!!!'
		END
		ELSE
		BEGIN
			
			eaUserLog_UserControl_OneMore:
			IF @MaxCurrLogDate < DATEADD(HOUR, -3, @CurrentDate)
				SET @ToLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
			ELSE
				SET @ToLogDate = @CurrentDate

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT LogID, CustID, LogDate, UserID, TypeID, ActionID, Duration, TrackingValue
							FROM bodb_CustomerLog.dbo.eaUserLog_UserControl WITH (NOLOCK)
							WHERE LogID > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate >= ''''' + CONVERT(VARCHAR(50), @MaxCurrLogDate, 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(50), @ToLogDate, 121) + '''''
							ORDER BY LogID
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				SET IDENTITY_INSERT dbo.eaUserLog_UserControl ON
				BEGIN TRY
					INSERT INTO dbo.eaUserLog_UserControl(LogID, CustID, LogDate, UserID, TypeID, ActionID, Duration, TrackingValue)
					EXEC sp_executesql @SqlQuery

					IF @@ROWCOUNT = 0 AND @ToLogDate < @CurrentDate
					BEGIN
						SET @MaxCurrLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
						GOTO eaUserLog_UserControl_OneMore
					END

				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.eaUserLog_UserControl WITH(ROWLOCK)
					WHERE LogID > @MaxCurrLogId AND LogDate >= @MaxCurrLogDate
				
					--retry
					INSERT INTO dbo.eaUserLog_UserControl (LogID, CustID, LogDate, UserID, TypeID, ActionID, Duration, TrackingValue)
					EXEC sp_executesql @SqlQuery

				END CATCH
				SET IDENTITY_INSERT dbo.eaUserLog_UserControl OFF
			END
		END
	END

	BEGIN --Userlog_LicenseeSetting

		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate

		SELECT @MaxCurrLogId = MAX(LogID), @MaxCurrLogDate = MAX(LogDate)
		FROM dbo.Userlog_LicenseeSetting t WITH (NOLOCK)
		WHERE LogDate > @3MonthsAgo
		
		IF @MaxCurrLogId = 0
		BEGIN
			PRINT 'Some things wrong for [Userlog_LicenseeSetting]. Please check!!!'
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [UserLog_Login]. Please check!!!'
		END
		ELSE
		BEGIN
			
			Userlog_LicenseeSetting_OneMore:
			IF @MaxCurrLogDate < DATEADD(HOUR, -3, @CurrentDate)
				SET @ToLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
			ELSE
				SET @ToLogDate = @CurrentDate

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT LogId, UserId, IP, LicenseeID, CurrencyID, SPName, LogDate, CustId, ActionId, Duration, CAST(Data AS NVARCHAR(MAX)) AS Data, CAST(OldData AS NVARCHAR(MAX)) AS OldData
							FROM bodb_CustomerLog.dbo.Userlog_LicenseeSetting WITH (NOLOCK)
							WHERE LogID > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate >= ''''' + CONVERT(VARCHAR(50), @MaxCurrLogDate, 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(50), @ToLogDate, 121) + '''''
							ORDER BY LogID
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				SET IDENTITY_INSERT dbo.Userlog_LicenseeSetting ON
				BEGIN TRY
					INSERT INTO dbo.Userlog_LicenseeSetting(LogId, UserId, IP, LicenseeID, CurrencyID, SPName, LogDate, CustId, ActionId, Duration, Data, OldData)
					EXEC sp_executesql @SqlQuery

					IF @@ROWCOUNT = 0 AND @ToLogDate < @CurrentDate
					BEGIN
						SET @MaxCurrLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
						GOTO Userlog_LicenseeSetting_OneMore
					END

				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.Userlog_LicenseeSetting WITH(ROWLOCK)
					WHERE LogID > @MaxCurrLogId AND LogDate >= @MaxCurrLogDate
				
					--retry
					INSERT INTO dbo.Userlog_LicenseeSetting (LogId, UserId, IP, LicenseeID, CurrencyID, SPName, LogDate, CustId, ActionId, Duration, Data, OldData)
					EXEC sp_executesql @SqlQuery

				END CATCH
				SET IDENTITY_INSERT dbo.Userlog_LicenseeSetting OFF
			END
		END
	END

	BEGIN --UserLog_Login_Aff

		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate

		SELECT @MaxCurrLogId = MAX(LogID), @MaxCurrLogDate = MAX(LogDate)
		FROM dbo.UserLog_Login_Aff t WITH (NOLOCK)
		WHERE LogDate > @3MonthsAgo
		
		IF @MaxCurrLogId = 0
		BEGIN
			PRINT 'Some things wrong for [UserLog_Login_Aff]. Please check!!!'
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [UserLog_Login]. Please check!!!'
		END
		ELSE
		BEGIN

			UserLog_Login_Aff_OneMore:
			IF @MaxCurrLogDate < DATEADD(HOUR, -3, @CurrentDate)
				SET @ToLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
			ELSE
				SET @ToLogDate = @CurrentDate

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT LogID, UserID, ServerID, IP, LogDate, ActionID, Doing, DomainName, BrowserName, Platform, CountryCode, Duration
							FROM bodb_CustomerLog.dbo.UserLog_Login_Aff WITH (NOLOCK)
							WHERE LogID > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate >= ''''' + CONVERT(VARCHAR(50), @MaxCurrLogDate, 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(50), @ToLogDate, 121) + '''''
							ORDER BY LogID
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				SET IDENTITY_INSERT dbo.UserLog_Login_Aff ON
				BEGIN TRY
					INSERT INTO dbo.UserLog_Login_Aff(LogID, UserID, ServerID, IP, LogDate, ActionID, Doing, DomainName, BrowserName, Platform, CountryCode, Duration)
					EXEC sp_executesql @SqlQuery

					IF @@ROWCOUNT = 0 AND @ToLogDate < @CurrentDate
					BEGIN
						SET @MaxCurrLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
						GOTO UserLog_Login_Aff_OneMore
					END

				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.UserLog_Login_Aff WITH(ROWLOCK)
					WHERE LogID > @MaxCurrLogId AND LogDate >= @MaxCurrLogDate
				
					--retry
					INSERT INTO dbo.UserLog_Login_Aff (LogID, UserID, ServerID, IP, LogDate, ActionID, Doing, DomainName, BrowserName, Platform, CountryCode, Duration)
					EXEC sp_executesql @SqlQuery

				END CATCH
				SET IDENTITY_INSERT dbo.UserLog_Login_Aff OFF
			END
		END
	END

	BEGIN --UserLog_Settle3rd

		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate

		SELECT @MaxCurrLogId = MAX(LogID), @MaxCurrLogDate = MAX(LogDate)
		FROM dbo.UserLog_Settle3rd t WITH (NOLOCK)
		WHERE LogDate > @3MonthsAgo
		
		IF @MaxCurrLogId = 0
		BEGIN
			PRINT 'Some things wrong for [UserLog_Settle3rd]. Please check!!!'
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [UserLog_Login]. Please check!!!'
		END
		ELSE
		BEGIN

			UserLog_Settle3rd_OneMore:
			IF @MaxCurrLogDate < DATEADD(HOUR, -3, @CurrentDate)
				SET @ToLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
			ELSE
				SET @ToLogDate = @CurrentDate

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT LogId, LogDate, UserID, IP, Matchid, ResultID, VendorID, ActionID, Detail
							FROM bodb_CustomerLog.dbo.UserLog_Settle3rd WITH (NOLOCK)
							WHERE LogID > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate >= ''''' + CONVERT(VARCHAR(50), @MaxCurrLogDate, 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(50), @ToLogDate, 121) + '''''
							ORDER BY LogID
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				SET IDENTITY_INSERT dbo.UserLog_Settle3rd ON
				BEGIN TRY
					INSERT INTO dbo.UserLog_Settle3rd(LogId, LogDate, UserID, IP, Matchid, ResultID, VendorID, ActionID, Detail)
					EXEC sp_executesql @SqlQuery

					IF @@ROWCOUNT = 0 AND @ToLogDate < @CurrentDate
					BEGIN
						SET @MaxCurrLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
						GOTO UserLog_Settle3rd_OneMore
					END

				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.UserLog_Settle3rd WITH(ROWLOCK)
					WHERE LogID > @MaxCurrLogId AND LogDate >= @MaxCurrLogDate
				
					--retry
					INSERT INTO dbo.UserLog_Settle3rd (LogId, LogDate, UserID, IP, Matchid, ResultID, VendorID, ActionID, Detail)
					EXEC sp_executesql @SqlQuery

				END CATCH
				SET IDENTITY_INSERT dbo.UserLog_Settle3rd OFF
			END
		END
	END

	BEGIN --UserLog_SettleOutright

		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate

		SELECT @MaxCurrLogId = MAX(LogID), @MaxCurrLogDate = MAX(LogDate)
		FROM dbo.UserLog_SettleOutright t WITH (NOLOCK)
		WHERE LogDate > @3MonthsAgo
		
		IF @MaxCurrLogId = 0
		BEGIN
			PRINT 'Some things wrong for [UserLog_SettleOutright]. Please check!!!'
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [UserLog_Login]. Please check!!!'
		END
		ELSE
		BEGIN
			
			UserLog_SettleOutright_OneMore:
			IF @MaxCurrLogDate < DATEADD(HOUR, -3, @CurrentDate)
				SET @ToLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
			ELSE
				SET @ToLogDate = @CurrentDate

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT LogID, LogDate, UserID, ActionID, LeagueID, MatchID, EventDate, Result, Remark
							FROM bodb_CustomerLog.dbo.UserLog_SettleOutright WITH (NOLOCK)
							WHERE LogID > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate >= ''''' + CONVERT(VARCHAR(50), @MaxCurrLogDate, 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(50), @ToLogDate, 121) + '''''
							ORDER BY LogID
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				SET IDENTITY_INSERT dbo.UserLog_SettleOutright ON
				BEGIN TRY
					INSERT INTO dbo.UserLog_SettleOutright(LogID, LogDate, UserID, ActionID, LeagueID, MatchID, EventDate, Result, Remark)
					EXEC sp_executesql @SqlQuery
					
					IF @@ROWCOUNT = 0 AND @ToLogDate < @CurrentDate
					BEGIN
						SET @MaxCurrLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
						GOTO UserLog_SettleOutright_OneMore
					END

				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.UserLog_SettleOutright WITH(ROWLOCK)
					WHERE LogID > @MaxCurrLogId AND LogDate >= @MaxCurrLogDate
				
					--retry
					INSERT INTO dbo.UserLog_SettleOutright (LogID, LogDate, UserID, ActionID, LeagueID, MatchID, EventDate, Result, Remark)
					EXEC sp_executesql @SqlQuery

				END CATCH
				SET IDENTITY_INSERT dbo.UserLog_SettleOutright OFF
			END
		END
	END

	BEGIN --LogAction
		
		SELECT @ScheduleTime = KeyValue FROM dbo.SyncingLog_Setting WITH(NOLOCK) WHERE KeyId = 'LogAction'
		IF DATEDIFF(MINUTE, @ScheduleTime, @CurrentDate) > 30
		BEGIN
			CREATE TABLE #TmpDataSync2 (ActionID INT, ActionTypeID INT, SPName VARCHAR(50), ActionNameEN NVARCHAR(256), ActionNameCH NVARCHAR(256), ActionNameCS NVARCHAR(256), ActionNameJP NVARCHAR(256), ActionNameIT NVARCHAR(256), ActionNameTH NVARCHAR(256), ActionNameKO NVARCHAR(256), XsltContent VARCHAR(MAX), IsInternal TINYINT, ActionNameVI NVARCHAR(256))

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT ActionID, ActionTypeID, SPName, ActionNameEN, ActionNameCH, ActionNameCS, ActionNameJP, ActionNameIT, ActionNameTH, ActionNameKO, XsltContent, IsInternal, ActionNameVI
							FROM bodb_CustomerLog.dbo.LogAction WITH (NOLOCK)
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1 
				PRINT @SqlQuery
			ELSE
			BEGIN
			
				INSERT INTO #TmpDataSync2(ActionID, ActionTypeID, SPName, ActionNameEN, ActionNameCH, ActionNameCS, ActionNameJP, ActionNameIT, ActionNameTH, ActionNameKO, XsltContent, IsInternal, ActionNameVI)
				EXEC sp_executesql @SqlQuery

				IF @@ROWCOUNT > 0
				BEGIN
					--SET IDENTITY_INSERT dbo.LogAction ON

					;MERGE dbo.LogAction t
					USING #TmpDataSync2 s ON t.ActionID = s.ActionID
					WHEN MATCHED THEN 
						UPDATE SET ActionTypeID = s.ActionTypeID, SPName = s.SPName, ActionNameEN = s.ActionNameEN, ActionNameCH = s.ActionNameCH, ActionNameCS = s.ActionNameCS, ActionNameJP = s.ActionNameJP, ActionNameIT = s.ActionNameIT, ActionNameTH = s.ActionNameTH, ActionNameKO = s.ActionNameKO, XsltContent = s.XsltContent, IsInternal = s.IsInternal, ActionNameVI = s.ActionNameVI
					WHEN NOT MATCHED BY TARGET THEN
						INSERT (ActionID, ActionTypeID, SPName, ActionNameEN, ActionNameCH, ActionNameCS, ActionNameJP, ActionNameIT, ActionNameTH, ActionNameKO, XsltContent, IsInternal, ActionNameVI)
						VALUES(s.ActionID, s.ActionTypeID, s.SPName, s.ActionNameEN, s.ActionNameCH, s.ActionNameCS, s.ActionNameJP, s.ActionNameIT, s.ActionNameTH, s.ActionNameKO, s.XsltContent, s.IsInternal, s.ActionNameVI) 
					WHEN NOT MATCHED BY SOURCE THEN
						DELETE;

					--SET IDENTITY_INSERT dbo.LogAction OFF
				END

			END
			UPDATE dbo.SyncingLog_Setting WITH(ROWLOCK)
			SET KeyValue = CONVERT(VARCHAR(50), @CurrentDate, 121)
			WHERE KeyId = 'LogAction'

			DROP TABLE #TmpDataSync2
		END
	END

	BEGIN --LogAction_Lic
		
		SELECT @ScheduleTime = KeyValue FROM dbo.SyncingLog_Setting WITH(NOLOCK) WHERE KeyId = 'LogAction_Lic'
		IF DATEDIFF(MINUTE, @ScheduleTime, @CurrentDate) > 30
		BEGIN
			CREATE TABLE #TmpDataSync3 (ActionID INT, ActionTypeID INT, SPName VARCHAR(50), ActionName NVARCHAR(256), ActionNameEN NVARCHAR(256), ActionNameCT NVARCHAR(256), ActionNameCS NVARCHAR(256), ActionNameJP NVARCHAR(256), ActionNameTH NVARCHAR(256), ActionNameKO NVARCHAR(256), ActionNameES NVARCHAR(256), ActionNameVI NVARCHAR(256), Items NVARCHAR(MAX), SubItem1 NVARCHAR(MAX), IsInternal TINYINT, SubItem2 NVARCHAR(MAX), SubItem3 NVARCHAR(MAX), ApiMethod VARCHAR(125))

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT ActionId, ActionTypeId, SPName, ActionName, ActionNameEN, ActionNameCT, ActionNameCS, ActionNameJP, ActionNameTH, ActionNameKO, ActionNameES, ActionNameVI, CAST(Items AS NVARCHAR(MAX)) AS Items, CAST(SubItem1 AS NVARCHAR(MAX)) AS SubItem1, IsInternal, CAST(SubItem2 AS NVARCHAR(MAX)) AS SubItem2, CAST(SubItem3 AS NVARCHAR(MAX)) AS SubItem3, ApiMethod
							FROM bodb_CustomerLog.dbo.LogAction_Lic WITH (NOLOCK)
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1 
				PRINT @SqlQuery
			ELSE
			BEGIN
			
				INSERT INTO #TmpDataSync3(ActionId, ActionTypeId, SPName, ActionName, ActionNameEN, ActionNameCT, ActionNameCS, ActionNameJP, ActionNameTH, ActionNameKO, ActionNameES, ActionNameVI, Items, SubItem1, IsInternal, SubItem2, SubItem3, ApiMethod)
				EXEC sp_executesql @SqlQuery

				IF @@ROWCOUNT > 0
				BEGIN
					--SET IDENTITY_INSERT dbo.LogAction_Lic ON

					;MERGE dbo.LogAction_Lic t
					USING #TmpDataSync3 s ON t.ActionID = s.ActionID
					WHEN MATCHED THEN 
						UPDATE SET ActionTypeID = s.ActionTypeID, SPName = s.SPName, ActionName = s.ActionName, ActionNameEN = s.ActionNameEN, ActionNameCT = s.ActionNameCT, ActionNameCS = s.ActionNameCS, ActionNameJP = s.ActionNameJP, ActionNameTH = s.ActionNameTH, ActionNameKO = s.ActionNameKO, ActionNameES = s.ActionNameES, ActionNameVI = s.ActionNameVI, Items = s.Items, SubItem1 = s.SubItem1, IsInternal = s.IsInternal, SubItem2 = s.SubItem2, SubItem3 = s.SubItem3, ApiMethod = s.ApiMethod
					WHEN NOT MATCHED BY TARGET THEN
						INSERT (ActionId, ActionTypeId, SPName, ActionName, ActionNameEN, ActionNameCT, ActionNameCS, ActionNameJP, ActionNameTH, ActionNameKO, ActionNameES, ActionNameVI, Items, SubItem1, IsInternal, SubItem2, SubItem3, ApiMethod)
						VALUES(s.ActionId, s.ActionTypeId, s.SPName, s.ActionName, s.ActionNameEN, s.ActionNameCT, s.ActionNameCS, s.ActionNameJP, s.ActionNameTH, s.ActionNameKO, s.ActionNameES, s.ActionNameVI, s.Items, s.SubItem1, s.IsInternal, s.SubItem2, s.SubItem3, s.ApiMethod)
					WHEN NOT MATCHED BY SOURCE THEN
						DELETE;

					--SET IDENTITY_INSERT dbo.LogAction_Lic OFF
				END

			END
			UPDATE dbo.SyncingLog_Setting WITH(ROWLOCK)
			SET KeyValue = CONVERT(VARCHAR(50), @CurrentDate, 121)
			WHERE KeyId = 'LogAction_Lic'

			DROP TABLE #TmpDataSync3
		END
	END

	BEGIN --LogActionType
		SELECT @ScheduleTime = KeyValue FROM dbo.SyncingLog_Setting WITH(NOLOCK) WHERE KeyId = 'LogActionType'
		IF DATEDIFF(MINUTE, @ScheduleTime, @CurrentDate) > 30
		BEGIN
			CREATE TABLE #TmpDataSync4 (ActionTypeID INT, ActionTypeNameEN NVARCHAR(50), ActionTypeNameCH NVARCHAR(50), ActionTypeNameCS NVARCHAR(50), ActionTypeNameJP NVARCHAR(50), ActionTypeNameIT NVARCHAR(50), ActionTypeNameTH NVARCHAR(50), ActionTypeNameKO NVARCHAR(50), ActionTypeNameVI NVARCHAR(50))

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT ActionTypeID, ActionTypeNameEN, ActionTypeNameCH, ActionTypeNameCS, ActionTypeNameJP, ActionTypeNameIT, ActionTypeNameTH, ActionTypeNameKO, ActionTypeNameVI
							FROM bodb_CustomerLog.dbo.LogActionType WITH (NOLOCK)
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1 
				PRINT @SqlQuery
			ELSE
			BEGIN
			
				INSERT INTO #TmpDataSync4(ActionTypeID, ActionTypeNameEN, ActionTypeNameCH, ActionTypeNameCS, ActionTypeNameJP, ActionTypeNameIT, ActionTypeNameTH, ActionTypeNameKO, ActionTypeNameVI)
				EXEC sp_executesql @SqlQuery

				IF @@ROWCOUNT > 0
				BEGIN
					--SET IDENTITY_INSERT dbo.LogActionType ON

					;MERGE dbo.LogActionType t
					USING #TmpDataSync4 s ON t.ActionTypeID = s.ActionTypeID
					WHEN MATCHED THEN 
						UPDATE SET ActionTypeNameEN = s.ActionTypeNameEN, ActionTypeNameCH = s.ActionTypeNameCH, ActionTypeNameCS = s.ActionTypeNameCS, ActionTypeNameJP = s.ActionTypeNameJP, ActionTypeNameIT = s.ActionTypeNameIT, ActionTypeNameTH = s.ActionTypeNameTH, ActionTypeNameKO = s.ActionTypeNameKO, ActionTypeNameVI = s.ActionTypeNameVI
					WHEN NOT MATCHED BY TARGET THEN
						INSERT (ActionTypeID, ActionTypeNameEN, ActionTypeNameCH, ActionTypeNameCS, ActionTypeNameJP, ActionTypeNameIT, ActionTypeNameTH, ActionTypeNameKO, ActionTypeNameVI)
						VALUES(s.ActionTypeID, s.ActionTypeNameEN, s.ActionTypeNameCH, s.ActionTypeNameCS, s.ActionTypeNameJP, s.ActionTypeNameIT, s.ActionTypeNameTH, s.ActionTypeNameKO, s.ActionTypeNameVI)
					WHEN NOT MATCHED BY SOURCE THEN
						DELETE;

					--SET IDENTITY_INSERT dbo.LogActionType OFF
				END

			END
			UPDATE dbo.SyncingLog_Setting WITH(ROWLOCK)
			SET KeyValue = CONVERT(VARCHAR(50), @CurrentDate, 121)
			WHERE KeyId = 'LogActionType'

			DROP TABLE #TmpDataSync4
		END
	END

	BEGIN --LogActionType_Lic
		SELECT @ScheduleTime = KeyValue FROM dbo.SyncingLog_Setting WITH(NOLOCK) WHERE KeyId = 'LogActionType_Lic'
		IF DATEDIFF(MINUTE, @ScheduleTime, @CurrentDate) > 30
		BEGIN
			CREATE TABLE #TmpDataSync5 (ActionTypeId INT, ActionTypeName NVARCHAR(50))

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT ActionTypeId, ActionTypeName
							FROM bodb_CustomerLog.dbo.LogActionType_Lic WITH (NOLOCK)
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1 
				PRINT @SqlQuery
			ELSE
			BEGIN
			
				INSERT INTO #TmpDataSync5(ActionTypeId, ActionTypeName)
				EXEC sp_executesql @SqlQuery

				IF @@ROWCOUNT > 0
				BEGIN
					--SET IDENTITY_INSERT dbo.LogActionType_Lic ON

					;MERGE dbo.LogActionType_Lic t
					USING #TmpDataSync5 s ON t.ActionTypeID = s.ActionTypeID
					WHEN MATCHED THEN 
						UPDATE SET ActionTypeName = s.ActionTypeName
					WHEN NOT MATCHED BY TARGET THEN
						INSERT (ActionTypeId, ActionTypeName)
						VALUES(s.ActionTypeId, s.ActionTypeName)
					WHEN NOT MATCHED BY SOURCE THEN
						DELETE;

					--SET IDENTITY_INSERT dbo.LogActionType_Lic OFF
				END

			END
			UPDATE dbo.SyncingLog_Setting WITH(ROWLOCK)
			SET KeyValue = CONVERT(VARCHAR(50), @CurrentDate, 121)
			WHERE KeyId = 'LogActionType_Lic'

			DROP TABLE #TmpDataSync5
		END
	END

	BEGIN --MsgError
		SELECT @ScheduleTime = KeyValue FROM dbo.SyncingLog_Setting WITH(NOLOCK) WHERE KeyId = 'MsgError'
		IF DATEDIFF(MINUTE, @ScheduleTime, @CurrentDate) > 30
		BEGIN
			CREATE TABLE #TmpDataSync6 (MsgID INT, MsgGroupID INT, MsgNameEN NVARCHAR(500), MsgNameCT NVARCHAR(500), MsgNameCS NVARCHAR(500), MsgNameJP NVARCHAR(500), MsgNameTH NVARCHAR(500), MsgNameKO NVARCHAR(500), MsgNameES NVARCHAR(500), MsgNameVI NVARCHAR(500), IsActive BIT)

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT MsgID, MsgGroupID, MsgNameEN, MsgNameCT, MsgNameCS, MsgNameJP, MsgNameTH, MsgNameKO, MsgNameES, MsgNameVI, IsActive
							FROM bodb_CustomerLog.dbo.MsgError WITH (NOLOCK)
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1 
				PRINT @SqlQuery
			ELSE
			BEGIN
			
				INSERT INTO #TmpDataSync6(MsgID, MsgGroupID, MsgNameEN, MsgNameCT, MsgNameCS, MsgNameJP, MsgNameTH, MsgNameKO, MsgNameES, MsgNameVI, IsActive)
				EXEC sp_executesql @SqlQuery

				IF @@ROWCOUNT > 0
				BEGIN
					--SET IDENTITY_INSERT dbo.MsgError ON

					;MERGE dbo.MsgError t
					USING #TmpDataSync6 s ON t.MsgID = s.MsgID
					WHEN MATCHED THEN 
						UPDATE SET MsgGroupID = s.MsgGroupID, MsgNameEN = s.MsgNameEN, MsgNameCT = s.MsgNameCT, MsgNameCS = s.MsgNameCS, MsgNameJP = s.MsgNameJP, MsgNameTH = s.MsgNameTH, MsgNameKO = s.MsgNameKO, MsgNameES = s.MsgNameES, MsgNameVI = s.MsgNameVI, IsActive = s.IsActive
					WHEN NOT MATCHED BY TARGET THEN
						INSERT (MsgID, MsgGroupID, MsgNameEN, MsgNameCT, MsgNameCS, MsgNameJP, MsgNameTH, MsgNameKO, MsgNameES, MsgNameVI, IsActive)
						VALUES(s.MsgID, s.MsgGroupID, s.MsgNameEN, s.MsgNameCT, s.MsgNameCS, s.MsgNameJP, s.MsgNameTH, s.MsgNameKO, s.MsgNameES, s.MsgNameVI, s.IsActive)
					WHEN NOT MATCHED BY SOURCE THEN
						DELETE;

					--SET IDENTITY_INSERT dbo.MsgError OFF
				END

			END
			UPDATE dbo.SyncingLog_Setting WITH(ROWLOCK)
			SET KeyValue = CONVERT(VARCHAR(50), @CurrentDate, 121)
			WHERE KeyId = 'MsgError'

			DROP TABLE #TmpDataSync6
		END
	END

	BEGIN --MsgErrorGroup
		SELECT @ScheduleTime = KeyValue FROM dbo.SyncingLog_Setting WITH(NOLOCK) WHERE KeyId = 'MsgErrorGroup'
		IF DATEDIFF(MINUTE, @ScheduleTime, @CurrentDate) > 30
		BEGIN
			CREATE TABLE #TmpDataSync7 (MsgGroupID INT, MsgGroupName NVARCHAR(100))

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT MsgGroupID, MsgGroupName
							FROM bodb_CustomerLog.dbo.MsgErrorGroup WITH (NOLOCK)
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1 
				PRINT @SqlQuery
			ELSE
			BEGIN
			
				INSERT INTO #TmpDataSync7(MsgGroupID, MsgGroupName)
				EXEC sp_executesql @SqlQuery

				IF @@ROWCOUNT > 0
				BEGIN
					--SET IDENTITY_INSERT dbo.MsgErrorGroup ON

					;MERGE dbo.MsgErrorGroup t
					USING #TmpDataSync7 s ON t.MsgGroupID = s.MsgGroupID
					WHEN MATCHED THEN 
						UPDATE SET MsgGroupName = s.MsgGroupName
					WHEN NOT MATCHED BY TARGET THEN
						INSERT (MsgGroupID, MsgGroupName)
						VALUES(s.MsgGroupID, s.MsgGroupName)
					WHEN NOT MATCHED BY SOURCE THEN
						DELETE;

					--SET IDENTITY_INSERT dbo.MsgErrorGroup OFF
				END

			END
			UPDATE dbo.SyncingLog_Setting WITH(ROWLOCK)
			SET KeyValue = CONVERT(VARCHAR(50), @CurrentDate, 121)
			WHERE KeyId = 'MsgErrorGroup'

			DROP TABLE #TmpDataSync7
		END
	END

	DECLARE @MaxAdjustDate datetime
	BEGIN --UserLog_VirtualRateSettings
		SELECT @SqlQuery = '', @MaxAdjustDate = NULL, @ToLogDate = @CurrentDate

		SELECT @MaxAdjustDate = MAX(AdjustDate)
		FROM dbo.UserLog_VirtualRateSettings t WITH (NOLOCK)
		WHERE AdjustDate > @3MonthsAgo
		
		IF @MaxAdjustDate > @ToLogDate
		BEGIN
			PRINT '@MaxAdjustDate > @ToLogDate for [UserLog_VirtualRateSettings]. Please check!!!'
		END
		ELSE
		BEGIN
			IF @MaxAdjustDate < DATEADD(HOUR, -3, @CurrentDate)
				SET @ToLogDate = DATEADD(HOUR, 3, @MaxAdjustDate)
			ELSE
				SET @ToLogDate = @CurrentDate

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT CreatorID, CustID, AdjustDate, ReportDate, SiteID, SRecommend, MRecommend, Recommend, OldVirtualRate, NewVirtualRate, IsBA, ServiceName
							FROM bodb_CustomerLog.dbo.UserLog_VirtualRateSettings WITH (NOLOCK)
							WHERE AdjustDate > ''''' + CONVERT(VARCHAR(50), @MaxAdjustDate, 121) + '''''
							ORDER BY AdjustDate
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				BEGIN TRY
					DELETE dbo.UserLog_VirtualRateSettings WITH(ROWLOCK)
					WHERE AdjustDate > @MaxAdjustDate

					INSERT INTO dbo.UserLog_VirtualRateSettings(CreatorID, CustID, AdjustDate, ReportDate, SiteID, SRecommend, MRecommend, Recommend, OldVirtualRate, NewVirtualRate, IsBA, ServiceName)
					EXEC sp_executesql @SqlQuery

				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.UserLog_VirtualRateSettings WITH(ROWLOCK)
					WHERE AdjustDate > @MaxAdjustDate
				
					--retry
					INSERT INTO dbo.UserLog_VirtualRateSettings(CreatorID, CustID, AdjustDate, ReportDate, SiteID, SRecommend, MRecommend, Recommend, OldVirtualRate, NewVirtualRate, IsBA, ServiceName)
					EXEC sp_executesql @SqlQuery

				END CATCH
			END
		END
	END

	BEGIN --UserLog_VirtualRateSettings_History
		SELECT @SqlQuery = '', @MaxAdjustDate = NULL, @ToLogDate = @CurrentDate

		SELECT @MaxAdjustDate = MAX(AdjustDate)
		FROM dbo.UserLog_VirtualRateSettings_History t WITH (NOLOCK)
		WHERE AdjustDate > @3MonthsAgo
		
		IF @MaxAdjustDate > @ToLogDate
		BEGIN
			PRINT '@MaxAdjustDate > @ToLogDate for [UserLog_VirtualRateSettings_History]. Please check!!!'
		END
		ELSE
		BEGIN
			IF @MaxAdjustDate < DATEADD(HOUR, -3, @CurrentDate)
				SET @ToLogDate = DATEADD(HOUR, 3, @MaxAdjustDate)
			ELSE
				SET @ToLogDate = @CurrentDate

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT AdjustDate, CustId, ReportMonth, ReportYear, Turnover, Winloss, BetCount, ServiceName
							FROM bodb_CustomerLog.dbo.UserLog_VirtualRateSettings_History WITH (NOLOCK)
							WHERE AdjustDate > ''''' + CONVERT(VARCHAR(50), @MaxAdjustDate, 121) + '''''
							ORDER BY AdjustDate
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				BEGIN TRY
					DELETE dbo.UserLog_VirtualRateSettings_History WITH(ROWLOCK)
					WHERE AdjustDate > @MaxAdjustDate

					INSERT INTO dbo.UserLog_VirtualRateSettings_History(AdjustDate, CustId, ReportMonth, ReportYear, Turnover, Winloss, BetCount, ServiceName)
					EXEC sp_executesql @SqlQuery

				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.UserLog_VirtualRateSettings_History WITH(ROWLOCK)
					WHERE AdjustDate > @MaxAdjustDate
				
					--retry
					INSERT INTO dbo.UserLog_VirtualRateSettings_History(AdjustDate, CustId, ReportMonth, ReportYear, Turnover, Winloss, BetCount, ServiceName)
					EXEC sp_executesql @SqlQuery

				END CATCH
			END
		END
	END

	BEGIN --TicketVoiding_Log

		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate

		SELECT @MaxCurrLogId = MAX(LogID), @MaxCurrLogDate = MAX(CreatedDate)
		FROM dbo.TicketVoiding_Log t WITH (NOLOCK)
		WHERE CreatedDate > @3MonthsAgo
		
		IF @MaxCurrLogId = 0
		BEGIN
			PRINT 'Some things wrong for [TicketVoiding_Log]. Please check!!!'
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [TicketVoiding_Log]. Please check!!!'
		END
		ELSE
		BEGIN
			
			TicketVoiding_Log_OneMore:
			IF @MaxCurrLogDate < DATEADD(HOUR, -3, @CurrentDate)
				SET @ToLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
			ELSE
				SET @ToLogDate = @CurrentDate

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT LogId, LogActionId, RequestId, LogData, CreatedDate, UserId, IP, SessionId, MatchId
							FROM bodb_CustomerLog.dbo.TicketVoiding_Log WITH (NOLOCK)
							WHERE LogID > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND CreatedDate >= ''''' + CONVERT(VARCHAR(50), @MaxCurrLogDate, 121) + '''''
								AND CreatedDate < ''''' + CONVERT(VARCHAR(50), @ToLogDate, 121) + '''''
							ORDER BY LogID
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				SET IDENTITY_INSERT dbo.TicketVoiding_Log ON
				BEGIN TRY
					INSERT INTO dbo.TicketVoiding_Log(LogId, LogActionId, RequestId, LogData, CreatedDate, UserId, IP, SessionId, MatchId)
					EXEC sp_executesql @SqlQuery

					IF @@ROWCOUNT = 0 AND @ToLogDate < @CurrentDate
					BEGIN
						SET @MaxCurrLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
						GOTO TicketVoiding_Log_OneMore
					END

				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.TicketVoiding_Log WITH(ROWLOCK)
					WHERE LogID > @MaxCurrLogId AND CreatedDate >= @MaxCurrLogDate
				
					--retry
					INSERT INTO dbo.TicketVoiding_Log (LogId, LogActionId, RequestId, LogData, CreatedDate, UserId, IP, SessionId, MatchId)
					EXEC sp_executesql @SqlQuery

				END CATCH
				SET IDENTITY_INSERT dbo.TicketVoiding_Log OFF
			END
		END
	END

	BEGIN --DBALog_Archive_Dep_Cust_Process

		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate

		SELECT @MaxCurrLogId = MAX(LogId), @MaxCurrLogDate = MAX(LogTime)
		FROM dbo.DBALog_Archive_Dep_Cust_Process t WITH (NOLOCK)
		WHERE LogTime > @3MonthsAgo
		
		IF @MaxCurrLogId = 0
		BEGIN
			PRINT 'Some things wrong for [DBALog_Archive_Dep_Cust_Process]. Please check!!!'
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [DBALog_Archive_Dep_Cust_Process]. Please check!!!'
		END
		ELSE
		BEGIN
			
			DBALog_Archive_Dep_Cust_Process_OneMore:
			IF @MaxCurrLogDate < DATEADD(HOUR, -3, @CurrentDate)
				SET @ToLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
			ELSE
				SET @ToLogDate = @CurrentDate

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT [LogId], [CustID], [Action], [Status], [Message], [LogTime]
							FROM bodb_CustomerLog.dbo.DBALog_Archive_Dep_Cust_Process WITH (NOLOCK)
							WHERE LogId > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogTime >= ''''' + CONVERT(VARCHAR(50), @MaxCurrLogDate, 121) + '''''
								AND LogTime < ''''' + CONVERT(VARCHAR(50), @ToLogDate, 121) + '''''
							ORDER BY LogId
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				SET IDENTITY_INSERT dbo.DBALog_Archive_Dep_Cust_Process ON
				BEGIN TRY
					INSERT INTO dbo.DBALog_Archive_Dep_Cust_Process([LogId], [CustID], [Action], [Status], [Message], [LogTime])
					EXEC sp_executesql @SqlQuery

					IF @@ROWCOUNT = 0 AND @ToLogDate < @CurrentDate
					BEGIN
						SET @MaxCurrLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
						GOTO DBALog_Archive_Dep_Cust_Process_OneMore
					END

				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.DBALog_Archive_Dep_Cust_Process WITH(ROWLOCK)
					WHERE LogID > @MaxCurrLogId AND LogTime >= @MaxCurrLogDate
				
					--retry
					INSERT INTO dbo.DBALog_Archive_Dep_Cust_Process ([LogId], [CustID], [Action], [Status], [Message], [LogTime])
					EXEC sp_executesql @SqlQuery

				END CATCH
				SET IDENTITY_INSERT dbo.DBALog_Archive_Dep_Cust_Process OFF
			END
		END
	END

	BEGIN --LA_UserLog_RunSP

		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate

		SELECT @MaxCurrLogId = MAX(LogId), @MaxCurrLogDate = MAX(LogDate)
		FROM dbo.LA_UserLog_RunSP t WITH (NOLOCK)
		WHERE LogDate > @3MonthsAgo
		
		IF @MaxCurrLogId = 0
		BEGIN
			PRINT 'Some things wrong for [LA_UserLog_RunSP]. Please check!!!'
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [LA_UserLog_RunSP]. Please check!!!'
		END
		ELSE
		BEGIN
			
			LA_UserLog_RunSP_OneMore:
			IF @MaxCurrLogDate < DATEADD(HOUR, -3, @CurrentDate)
				SET @ToLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
			ELSE
				SET @ToLogDate = @CurrentDate

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT [LogID], [UserID], [SPName], [Doing], [LogDate], [CustID], [ActionID], [TrackingValue], [Duration], [TrackingValue2]
							FROM bodb_CustomerLog.dbo.LA_UserLog_RunSP WITH (NOLOCK)
							WHERE LogId > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate >= ''''' + CONVERT(VARCHAR(50), @MaxCurrLogDate, 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(50), @ToLogDate, 121) + '''''
							ORDER BY LogId
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				SET IDENTITY_INSERT dbo.LA_UserLog_RunSP ON
				BEGIN TRY
					INSERT INTO dbo.LA_UserLog_RunSP([LogID], [UserID], [SPName], [Doing], [LogDate], [CustID], [ActionID], [TrackingValue], [Duration], [TrackingValue2])
					EXEC sp_executesql @SqlQuery

					IF @@ROWCOUNT = 0 AND @ToLogDate < @CurrentDate
					BEGIN
						SET @MaxCurrLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
						GOTO LA_UserLog_RunSP_OneMore
					END

				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.LA_UserLog_RunSP WITH(ROWLOCK)
					WHERE LogID > @MaxCurrLogId AND LogDate >= @MaxCurrLogDate
				
					--retry
					INSERT INTO dbo.LA_UserLog_RunSP ([LogID], [UserID], [SPName], [Doing], [LogDate], [CustID], [ActionID], [TrackingValue], [Duration], [TrackingValue2])
					EXEC sp_executesql @SqlQuery

				END CATCH
				SET IDENTITY_INSERT dbo.LA_UserLog_RunSP OFF
			END
		END
	END

	BEGIN --rmUserLog_Login

		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate

		SELECT @MaxCurrLogId = MAX(LogId), @MaxCurrLogDate = MAX(LogDate)
		FROM dbo.rmUserLog_Login t WITH (NOLOCK)
		WHERE LogDate > @3MonthsAgo
		
		IF @MaxCurrLogId = 0
		BEGIN
			PRINT 'Some things wrong for [rmUserLog_Login]. Please check!!!'
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [rmUserLog_Login]. Please check!!!'
		END
		ELSE
		BEGIN
			
			rmUserLog_Login_OneMore:
			IF @MaxCurrLogDate < DATEADD(HOUR, -3, @CurrentDate)
				SET @ToLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
			ELSE
				SET @ToLogDate = @CurrentDate

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT [LogID], [UserID], [IP], [LogDate], [ActionID], [Doing], [DomainName], [BrowserName], [Platform], [CountryCode], [Duration]
							FROM bodb_CustomerLog.dbo.rmUserLog_Login WITH (NOLOCK)
							WHERE LogId > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate >= ''''' + CONVERT(VARCHAR(50), @MaxCurrLogDate, 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(50), @ToLogDate, 121) + '''''
							ORDER BY LogId
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				SET IDENTITY_INSERT dbo.rmUserLog_Login ON
				BEGIN TRY
					INSERT INTO dbo.rmUserLog_Login([LogID], [UserID], [IP], [LogDate], [ActionID], [Doing], [DomainName], [BrowserName], [Platform], [CountryCode], [Duration])
					EXEC sp_executesql @SqlQuery

					IF @@ROWCOUNT = 0 AND @ToLogDate < @CurrentDate
					BEGIN
						SET @MaxCurrLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
						GOTO rmUserLog_Login_OneMore
					END

				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.rmUserLog_Login WITH(ROWLOCK)
					WHERE LogID > @MaxCurrLogId AND LogDate >= @MaxCurrLogDate
				
					--retry
					INSERT INTO dbo.rmUserLog_Login ([LogID], [UserID], [IP], [LogDate], [ActionID], [Doing], [DomainName], [BrowserName], [Platform], [CountryCode], [Duration])
					EXEC sp_executesql @SqlQuery

				END CATCH
				SET IDENTITY_INSERT dbo.rmUserLog_Login OFF
			END
		END
	END

	BEGIN --rmUserLog_RunSP

		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate

		SELECT @MaxCurrLogId = MAX(LogId), @MaxCurrLogDate = MAX(LogDate)
		FROM dbo.rmUserLog_RunSP t WITH (NOLOCK)
		WHERE LogDate > @3MonthsAgo
		
		IF @MaxCurrLogId = 0
		BEGIN
			PRINT 'Some things wrong for [rmUserLog_RunSP]. Please check!!!'
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [rmUserLog_RunSP]. Please check!!!'
		END
		ELSE
		BEGIN
			
			rmUserLog_RunSP_OneMore:
			IF @MaxCurrLogDate < DATEADD(HOUR, -3, @CurrentDate)
				SET @ToLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
			ELSE
				SET @ToLogDate = @CurrentDate

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT [LogID], [UserID], [Logdate], [CustID], [ActionID], [TrackingValue], [Duration], [TrackingValue2]
							FROM bodb_CustomerLog.dbo.rmUserLog_RunSP WITH (NOLOCK)
							WHERE LogId > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate >= ''''' + CONVERT(VARCHAR(50), @MaxCurrLogDate, 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(50), @ToLogDate, 121) + '''''
							ORDER BY LogId
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				SET IDENTITY_INSERT dbo.rmUserLog_RunSP ON
				BEGIN TRY
					INSERT INTO dbo.rmUserLog_RunSP([LogID], [UserID], [Logdate], [CustID], [ActionID], [TrackingValue], [Duration], [TrackingValue2])
					EXEC sp_executesql @SqlQuery

					IF @@ROWCOUNT = 0 AND @ToLogDate < @CurrentDate
					BEGIN
						SET @MaxCurrLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
						GOTO rmUserLog_RunSP_OneMore
					END

				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.rmUserLog_RunSP WITH(ROWLOCK)
					WHERE LogID > @MaxCurrLogId AND LogDate >= @MaxCurrLogDate
				
					--retry
					INSERT INTO dbo.rmUserLog_RunSP ([LogID], [UserID], [Logdate], [CustID], [ActionID], [TrackingValue], [Duration], [TrackingValue2])
					EXEC sp_executesql @SqlQuery

				END CATCH
				SET IDENTITY_INSERT dbo.rmUserLog_RunSP OFF
			END
		END
	END

	BEGIN --rmUserLog_UserControl

		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate

		SELECT @MaxCurrLogId = MAX(LogId), @MaxCurrLogDate = MAX(LogDate)
		FROM dbo.rmUserLog_UserControl t WITH (NOLOCK)
		WHERE LogDate > @3MonthsAgo
		
		IF @MaxCurrLogId = 0
		BEGIN
			PRINT 'Some things wrong for [rmUserLog_UserControl]. Please check!!!'
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [rmUserLog_UserControl]. Please check!!!'
		END
		ELSE
		BEGIN
			
			rmUserLog_UserControl_OneMore:
			IF @MaxCurrLogDate < DATEADD(HOUR, -3, @CurrentDate)
				SET @ToLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
			ELSE
				SET @ToLogDate = @CurrentDate

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT [LogID], [CustID], [LogDate], [UserID], [TypeID], [ActionID], [Duration], [Doing]
							FROM bodb_CustomerLog.dbo.rmUserLog_UserControl WITH (NOLOCK)
							WHERE LogId > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate >= ''''' + CONVERT(VARCHAR(50), @MaxCurrLogDate, 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(50), @ToLogDate, 121) + '''''
							ORDER BY LogId
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				SET IDENTITY_INSERT dbo.rmUserLog_UserControl ON
				BEGIN TRY
					INSERT INTO dbo.rmUserLog_UserControl([LogID], [CustID], [LogDate], [UserID], [TypeID], [ActionID], [Duration], [Doing])
					EXEC sp_executesql @SqlQuery

					IF @@ROWCOUNT = 0 AND @ToLogDate < @CurrentDate
					BEGIN
						SET @MaxCurrLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
						GOTO rmUserLog_UserControl_OneMore
					END

				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.rmUserLog_UserControl WITH(ROWLOCK)
					WHERE LogID > @MaxCurrLogId AND LogDate >= @MaxCurrLogDate
				
					--retry
					INSERT INTO dbo.rmUserLog_UserControl ([LogID], [CustID], [LogDate], [UserID], [TypeID], [ActionID], [Duration], [Doing])
					EXEC sp_executesql @SqlQuery

				END CATCH
				SET IDENTITY_INSERT dbo.rmUserLog_UserControl OFF
			END
		END
	END

	BEGIN --UserLog_LicenseeBAConfig

		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate

		SELECT @MaxCurrLogId = MAX(LogId), @MaxCurrLogDate = MAX(ModifyDate)
		FROM dbo.UserLog_LicenseeBAConfig t WITH (NOLOCK)
		WHERE ModifyDate > @3MonthsAgo
		
		IF @MaxCurrLogId = 0
		BEGIN
			PRINT 'Some things wrong for [UserLog_LicenseeBAConfig]. Please check!!!'
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [UserLog_LicenseeBAConfig]. Please check!!!'
		END
		ELSE
		BEGIN
			
			UserLog_LicenseeBAConfig_OneMore:
			IF @MaxCurrLogDate < DATEADD(HOUR, -3, @CurrentDate)
				SET @ToLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
			ELSE
				SET @ToLogDate = @CurrentDate

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT [LogID], [LicenseeID], [1x2Comm], [OtherComm], [EnableBA], [IP], [ActionID], [ModifyBy], [ModifyDate], [groupa], [groupb], [groupc], [groupd]
							FROM bodb_CustomerLog.dbo.UserLog_LicenseeBAConfig WITH (NOLOCK)
							WHERE LogId > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND ModifyDate >= ''''' + CONVERT(VARCHAR(50), @MaxCurrLogDate, 121) + '''''
								AND ModifyDate < ''''' + CONVERT(VARCHAR(50), @ToLogDate, 121) + '''''
							ORDER BY LogId
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				SET IDENTITY_INSERT dbo.UserLog_LicenseeBAConfig ON
				BEGIN TRY
					INSERT INTO dbo.UserLog_LicenseeBAConfig([LogID], [LicenseeID], [1x2Comm], [OtherComm], [EnableBA], [IP], [ActionID], [ModifyBy], [ModifyDate], [groupa], [groupb], [groupc], [groupd])
					EXEC sp_executesql @SqlQuery

					IF @@ROWCOUNT = 0 AND @ToLogDate < @CurrentDate
					BEGIN
						SET @MaxCurrLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
						GOTO UserLog_LicenseeBAConfig_OneMore
					END

				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.UserLog_LicenseeBAConfig WITH(ROWLOCK)
					WHERE LogID > @MaxCurrLogId AND ModifyDate >= @MaxCurrLogDate
				
					--retry
					INSERT INTO dbo.UserLog_LicenseeBAConfig ([LogID], [LicenseeID], [1x2Comm], [OtherComm], [EnableBA], [IP], [ActionID], [ModifyBy], [ModifyDate], [groupa], [groupb], [groupc], [groupd])
					EXEC sp_executesql @SqlQuery

				END CATCH
				SET IDENTITY_INSERT dbo.UserLog_LicenseeBAConfig OFF
			END
		END
	END

	BEGIN --UserLog_LicenseeCurrencyBAGroup

		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate

		SELECT @MaxCurrLogId = MAX(LogId), @MaxCurrLogDate = MAX(ModifyDate)
		FROM dbo.UserLog_LicenseeCurrencyBAGroup t WITH (NOLOCK)
		WHERE ModifyDate > @3MonthsAgo
		
		IF @MaxCurrLogId = 0
		BEGIN
			PRINT 'Some things wrong for [UserLog_LicenseeCurrencyBAGroup]. Please check!!!'
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [UserLog_LicenseeCurrencyBAGroup]. Please check!!!'
		END
		ELSE
		BEGIN
			
			UserLog_LicenseeCurrencyBAGroup_OneMore:
			IF @MaxCurrLogDate < DATEADD(HOUR, -3, @CurrentDate)
				SET @ToLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
			ELSE
				SET @ToLogDate = @CurrentDate

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT [LogID], [LicenseeID], [Currency], [ugroup], [ModifyBy], [ModifyDate], [IP]
							FROM bodb_CustomerLog.dbo.UserLog_LicenseeCurrencyBAGroup WITH (NOLOCK)
							WHERE LogId > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND ModifyDate >= ''''' + CONVERT(VARCHAR(50), @MaxCurrLogDate, 121) + '''''
								AND ModifyDate < ''''' + CONVERT(VARCHAR(50), @ToLogDate, 121) + '''''
							ORDER BY LogId
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				SET IDENTITY_INSERT dbo.UserLog_LicenseeCurrencyBAGroup ON
				BEGIN TRY
					INSERT INTO dbo.UserLog_LicenseeCurrencyBAGroup([LogID], [LicenseeID], [Currency], [ugroup], [ModifyBy], [ModifyDate], [IP])
					EXEC sp_executesql @SqlQuery

					IF @@ROWCOUNT = 0 AND @ToLogDate < @CurrentDate
					BEGIN
						SET @MaxCurrLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
						GOTO UserLog_LicenseeCurrencyBAGroup_OneMore
					END

				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.UserLog_LicenseeCurrencyBAGroup WITH(ROWLOCK)
					WHERE LogID > @MaxCurrLogId AND ModifyDate >= @MaxCurrLogDate
				
					--retry
					INSERT INTO dbo.UserLog_LicenseeCurrencyBAGroup ([LogID], [LicenseeID], [Currency], [ugroup], [ModifyBy], [ModifyDate], [IP])
					EXEC sp_executesql @SqlQuery

				END CATCH
				SET IDENTITY_INSERT dbo.UserLog_LicenseeCurrencyBAGroup OFF
			END
		END
	END
 
	BEGIN --UserLog_RunSP_LogTarget

		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate

		SELECT @MaxCurrLogId = MAX(LogId), @MaxCurrLogDate = MAX(LogDate)
		FROM dbo.UserLog_RunSP_LogTarget t WITH (NOLOCK)
		WHERE LogDate > @3MonthsAgo
		
		IF @MaxCurrLogId = 0
		BEGIN
			PRINT 'Some things wrong for [UserLog_RunSP_LogTarget]. Please check!!!'
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [UserLog_RunSP_LogTarget]. Please check!!!'
		END
		ELSE
		BEGIN
			
			UserLog_RunSP_LogTarget_OneMore:
			IF @MaxCurrLogDate < DATEADD(HOUR, -3, @CurrentDate)
				SET @ToLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
			ELSE
				SET @ToLogDate = @CurrentDate

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT [LogID], [CustID], [LogDate]
							FROM bodb_CustomerLog.dbo.UserLog_RunSP_LogTarget WITH (NOLOCK)
							WHERE LogId > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate >= ''''' + CONVERT(VARCHAR(50), @MaxCurrLogDate, 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(50), @ToLogDate, 121) + '''''
							ORDER BY LogId
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				--SET IDENTITY_INSERT dbo.UserLog_RunSP_LogTarget ON
				BEGIN TRY
					INSERT INTO dbo.UserLog_RunSP_LogTarget([LogID], [CustID], [LogDate])
					EXEC sp_executesql @SqlQuery

					IF @@ROWCOUNT = 0 AND @ToLogDate < @CurrentDate
					BEGIN
						SET @MaxCurrLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
						GOTO UserLog_RunSP_LogTarget_OneMore
					END

				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.UserLog_RunSP_LogTarget WITH(ROWLOCK)
					WHERE LogID > @MaxCurrLogId AND LogDate >= @MaxCurrLogDate
				
					--retry
					INSERT INTO dbo.UserLog_RunSP_LogTarget ([LogID], [CustID], [LogDate])
					EXEC sp_executesql @SqlQuery

				END CATCH
				--SET IDENTITY_INSERT dbo.UserLog_RunSP_LogTarget OFF
			END
		END
	END

	BEGIN --UserLog_RunSP_MultiTarget

		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate

		SELECT @MaxCurrLogId = MAX(LogId), @MaxCurrLogDate = MAX(LogDate)
		FROM dbo.UserLog_RunSP_MultiTarget t WITH (NOLOCK)
		WHERE LogDate > @3MonthsAgo
		
		IF @MaxCurrLogId = 0
		BEGIN
			PRINT 'Some things wrong for [UserLog_RunSP_MultiTarget]. Please check!!!'
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [UserLog_RunSP_MultiTarget]. Please check!!!'
		END
		ELSE
		BEGIN
			
			UserLog_RunSP_MultiTarget_OneMore:
			IF @MaxCurrLogDate < DATEADD(HOUR, -3, @CurrentDate)
				SET @ToLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
			ELSE
				SET @ToLogDate = @CurrentDate

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT [LogID], [UserID], [LogDate], [ActionID], [TrackingValue], [Duration], [TrackingValue2], [MainLogID]
							FROM bodb_CustomerLog.dbo.UserLog_RunSP_MultiTarget WITH (NOLOCK)
							WHERE LogId > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate >= ''''' + CONVERT(VARCHAR(50), @MaxCurrLogDate, 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(50), @ToLogDate, 121) + '''''
							ORDER BY LogId
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				SET IDENTITY_INSERT dbo.UserLog_RunSP_MultiTarget ON
				BEGIN TRY
					INSERT INTO dbo.UserLog_RunSP_MultiTarget([LogID], [UserID], [LogDate], [ActionID], [TrackingValue], [Duration], [TrackingValue2], [MainLogID])
					EXEC sp_executesql @SqlQuery

					IF @@ROWCOUNT = 0 AND @ToLogDate < @CurrentDate
					BEGIN
						SET @MaxCurrLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
						GOTO UserLog_RunSP_MultiTarget_OneMore
					END

				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.UserLog_RunSP_MultiTarget WITH(ROWLOCK)
					WHERE LogID > @MaxCurrLogId AND LogDate >= @MaxCurrLogDate
				
					--retry
					INSERT INTO dbo.UserLog_RunSP_MultiTarget ([LogID], [UserID], [LogDate], [ActionID], [TrackingValue], [Duration], [TrackingValue2], [MainLogID])
					EXEC sp_executesql @SqlQuery

				END CATCH
				SET IDENTITY_INSERT dbo.UserLog_RunSP_MultiTarget OFF
			END
		END
	END

	BEGIN --UserLog_SmartPunter

		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate

		SELECT @MaxCurrLogId = MAX(LogId), @MaxCurrLogDate = MAX(LogDate)
		FROM dbo.UserLog_SmartPunter t WITH (NOLOCK)
		WHERE LogDate > @3MonthsAgo
		
		IF @MaxCurrLogId = 0
		BEGIN
			PRINT 'Some things wrong for [UserLog_SmartPunter]. Please check!!!'
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [UserLog_SmartPunter]. Please check!!!'
		END
		ELSE
		BEGIN
			
			UserLog_SmartPunter_OneMore:
			IF @MaxCurrLogDate < DATEADD(HOUR, -3, @CurrentDate)
				SET @ToLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
			ELSE
				SET @ToLogDate = @CurrentDate

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT [Logid], [Logdate], [UserId], [CustId], [ActionID], [IP], [IsRestricted], [UplineId]
							FROM bodb_CustomerLog.dbo.UserLog_SmartPunter WITH (NOLOCK)
							WHERE LogId > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate >= ''''' + CONVERT(VARCHAR(50), @MaxCurrLogDate, 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(50), @ToLogDate, 121) + '''''
							ORDER BY LogId
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				SET IDENTITY_INSERT dbo.UserLog_SmartPunter ON
				BEGIN TRY
					INSERT INTO dbo.UserLog_SmartPunter([Logid], [Logdate], [UserId], [CustId], [ActionID], [IP], [IsRestricted], [UplineId])
					EXEC sp_executesql @SqlQuery

					IF @@ROWCOUNT = 0 AND @ToLogDate < @CurrentDate
					BEGIN
						SET @MaxCurrLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
						GOTO UserLog_SmartPunter_OneMore
					END

				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.UserLog_SmartPunter WITH(ROWLOCK)
					WHERE LogID > @MaxCurrLogId AND LogDate >= @MaxCurrLogDate
				
					--retry
					INSERT INTO dbo.UserLog_SmartPunter ([Logid], [Logdate], [UserId], [CustId], [ActionID], [IP], [IsRestricted], [UplineId])
					EXEC sp_executesql @SqlQuery

				END CATCH
				SET IDENTITY_INSERT dbo.UserLog_SmartPunter OFF
			END
		END
	END

	BEGIN --VRCustLog

		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate

		SELECT @MaxCurrLogId = MAX(LogId), @MaxCurrLogDate = MAX(LogTime)
		FROM dbo.VRCustLog t WITH (NOLOCK)
		WHERE LogTime > @3MonthsAgo
		
		IF @MaxCurrLogId = 0
		BEGIN
			PRINT 'Some things wrong for [VRCustLog]. Please check!!!'
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [VRCustLog]. Please check!!!'
		END
		ELSE
		BEGIN
			
			VRCustLog_OneMore:
			IF @MaxCurrLogDate < DATEADD(HOUR, -3, @CurrentDate)
				SET @ToLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
			ELSE
				SET @ToLogDate = @CurrentDate

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT [LogId], [SportType], [CustID], [ActionID], [TrackingValue1], [TrackingValue2], [UserID], [LogTime], [Duration], [IP]
							FROM bodb_CustomerLog.dbo.VRCustLog WITH (NOLOCK)
							WHERE LogId > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogTime >= ''''' + CONVERT(VARCHAR(50), @MaxCurrLogDate, 121) + '''''
								AND LogTime < ''''' + CONVERT(VARCHAR(50), @ToLogDate, 121) + '''''
							ORDER BY LogId
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				SET IDENTITY_INSERT dbo.VRCustLog ON
				BEGIN TRY
					INSERT INTO dbo.VRCustLog([LogId], [SportType], [CustID], [ActionID], [TrackingValue1], [TrackingValue2], [UserID], [LogTime], [Duration], [IP])
					EXEC sp_executesql @SqlQuery

					IF @@ROWCOUNT = 0 AND @ToLogDate < @CurrentDate
					BEGIN
						SET @MaxCurrLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
						GOTO VRCustLog_OneMore
					END

				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.VRCustLog WITH(ROWLOCK)
					WHERE LogID > @MaxCurrLogId AND LogTime >= @MaxCurrLogDate
				
					--retry
					INSERT INTO dbo.VRCustLog ([LogId], [SportType], [CustID], [ActionID], [TrackingValue1], [TrackingValue2], [UserID], [LogTime], [Duration], [IP])
					EXEC sp_executesql @SqlQuery

				END CATCH
				SET IDENTITY_INSERT dbo.VRCustLog OFF
			END
		END
	END

	BEGIN --Parlay_Calculate_Queue_bk

		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate

		SELECT @MaxCurrLogId = MAX(KeyId), @MaxCurrLogDate = MAX(Starttime)
		FROM bodb_CustomerLog_Archive.dbo.Parlay_Calculate_Queue_bk t WITH (NOLOCK)
		WHERE Starttime > @3MonthsAgo
		
		IF @MaxCurrLogId = -1
		BEGIN
			PRINT 'Some things wrong for [Parlay_Calculate_Queue_bk]. Please check!!!'
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [Parlay_Calculate_Queue_bk]. Please check!!!'
		END
		ELSE
		BEGIN
			
			Parlay_Calculate_Queue_bk_OneMore:
			IF @MaxCurrLogDate < DATEADD(HOUR, -3, @CurrentDate)
				SET @ToLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
			ELSE
				SET @ToLogDate = @CurrentDate

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT [matchid], [eventdate], [IsCalculating], [Creator], [IP], [Starttime], [Action], [TryCount], [execTime], [duration], [KeyId]
							FROM bodb_CustomerLog_Archive.dbo.Parlay_Calculate_Queue_bk WITH (NOLOCK)
							WHERE KeyId > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND Starttime >= ''''' + CONVERT(VARCHAR(50), @MaxCurrLogDate, 121) + '''''
								AND Starttime < ''''' + CONVERT(VARCHAR(50), @ToLogDate, 121) + '''''
							ORDER BY KeyId
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				--SET IDENTITY_INSERT dbo.Parlay_Calculate_Queue_bk ON
				BEGIN TRY
					INSERT INTO bodb_CustomerLog_Archive.dbo.Parlay_Calculate_Queue_bk([matchid], [eventdate], [IsCalculating], [Creator], [IP], [Starttime], [Action], [TryCount], [execTime], [duration], [KeyId])
					EXEC sp_executesql @SqlQuery

					IF @@ROWCOUNT = 0 AND @ToLogDate < @CurrentDate
					BEGIN
						SET @MaxCurrLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
						GOTO Parlay_Calculate_Queue_bk_OneMore
					END

				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE bodb_CustomerLog_Archive.dbo.Parlay_Calculate_Queue_bk WITH(ROWLOCK)
					WHERE keyId > @MaxCurrLogId AND Starttime >= @MaxCurrLogDate
				
					--retry
					INSERT INTO bodb_CustomerLog_Archive.dbo.Parlay_Calculate_Queue_bk ([matchid], [eventdate], [IsCalculating], [Creator], [IP], [Starttime], [Action], [TryCount], [execTime], [duration], [KeyId])
					EXEC sp_executesql @SqlQuery

				END CATCH
				--SET IDENTITY_INSERT dbo.Parlay_Calculate_Queue_bk OFF
			END
		END
	END

	BEGIN --Single_Calculate_Queue_bk

		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate

		SELECT @MaxCurrLogId = MAX(KeyId), @MaxCurrLogDate = MAX(Starttime)
		FROM bodb_CustomerLog_Archive.dbo.Single_Calculate_Queue_bk t WITH (NOLOCK)
		WHERE Starttime > @3MonthsAgo
		
		IF @MaxCurrLogId = -1
		BEGIN
			PRINT 'Some things wrong for [Single_Calculate_Queue_bk]. Please check!!!'
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [Single_Calculate_Queue_bk]. Please check!!!'
		END
		ELSE
		BEGIN
			
			Single_Calculate_Queue_bk_OneMore:
			IF @MaxCurrLogDate < DATEADD(HOUR, -3, @CurrentDate)
				SET @ToLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
			ELSE
				SET @ToLogDate = @CurrentDate

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT [matchid], [eventdate], [IsCalculating], [AdminId], [IP], [Starttime], [Action], [sqlCommand], [TryCount], [execTime], [duration], [KeyId]
							FROM bodb_CustomerLog_Archive.dbo.Single_Calculate_Queue_bk WITH (NOLOCK)
							WHERE KeyId > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND Starttime >= ''''' + CONVERT(VARCHAR(50), @MaxCurrLogDate, 121) + '''''
								AND Starttime < ''''' + CONVERT(VARCHAR(50), @ToLogDate, 121) + '''''
							ORDER BY KeyId
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				--SET IDENTITY_INSERT dbo.Single_Calculate_Queue_bk ON
				BEGIN TRY
					INSERT INTO bodb_CustomerLog_Archive.dbo.Single_Calculate_Queue_bk([matchid], [eventdate], [IsCalculating], [AdminId], [IP], [Starttime], [Action], [sqlCommand], [TryCount], [execTime], [duration], [KeyId])
					EXEC sp_executesql @SqlQuery

					IF @@ROWCOUNT = 0 AND @ToLogDate < @CurrentDate
					BEGIN
						SET @MaxCurrLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
						GOTO Single_Calculate_Queue_bk_OneMore
					END

				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE bodb_CustomerLog_Archive.dbo.Single_Calculate_Queue_bk WITH(ROWLOCK)
					WHERE keyId > @MaxCurrLogId AND Starttime >= @MaxCurrLogDate
				
					--retry
					INSERT INTO bodb_CustomerLog_Archive.dbo.Single_Calculate_Queue_bk ([matchid], [eventdate], [IsCalculating], [AdminId], [IP], [Starttime], [Action], [sqlCommand], [TryCount], [execTime], [duration], [KeyId])
					EXEC sp_executesql @SqlQuery

				END CATCH
				--SET IDENTITY_INSERT dbo.Single_Calculate_Queue_bk OFF
			END
		END
	END

END

