/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb_CustomerLog]
GO
ALTER PROCEDURE [dbo].[Task_Sync_CustomerLog] @IsDebug BIT = 0
AS
/*   
 Task : copy CustomerLog data from active server to standby server
 DB: DB054.bodb_customerLog, DB052.bodb_customerLog  
 Revisions:   
	- 20130408@viet: create SP   
	- 20140526@Jamie: Add App Machine, App Category
	- 20170223@Patrick: Optimize code to enhance perf
	- 20181003@Patrick: Add more table UserLog_Dep_CustSetting 
	- 201903-07@Patick: Remove syn data for UserLog_Credit
	- 201903-07@Patick: Add back syn data for UserLog_Credit [Redmine: #113381]
	- 20190709@Patrick: Add more table UserLog_ExternalAPI
	- 20201002@Patrick: Add CreatedDate to UserLog_RunSP
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
		, @MaxCurrLogDate DATETIME, @CurrentDate DATETIME, @ToLogDate DATETIME

	DECLARE @TblTmpData TABLE (MaxCurrLogDate DATETIME, MaxCurrLogId BIGINT, TableName VARCHAR(125))

	SELECT @LastWeek = DATEADD(DAY, -7, GETDATE())
		, @CurrentDate = DATEADD(MINUTE, -3, GETDATE())
		, @ToLogDate = DATEADD(MINUTE, -3, GETDATE())
		, @3MonthsAgo = DATEADD(MONTH, -3, GETDATE())

	IF @IsDebug IS NULL
		SET @IsDebug = 0
	
	BEGIN --AppLog_Machine
		SELECT @SqlQuery = '', @MaxCurrLogId = 0
		SELECT @MaxCurrLogId = MAX(MachineId)
		FROM dbo.AppLog_Machine WITH (NOLOCK)

		IF @MaxCurrLogId = 0
		BEGIN
			PRINT 'Some things wrong for [AppLog_Machine]. Please check!!!'
			SELECT @MaxCurrLogId = 0
		END

		SET @SqlQuery = 'SELECT *
						FROM OPENQUERY(DBLOG, ''SELECT MachineId, MachineName, IsProduction, TimeZone, MachineIP
						FROM bodb_CustomerLog.dbo.AppLog_Machine WITH (NOLOCK)
						WHERE MachineId > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' 
						OPTION (MAXDOP 8)'')'

		IF @IsDebug = 1 
			PRINT @SqlQuery
		ELSE
		BEGIN
			SET IDENTITY_INSERT dbo.AppLog_Machine ON
			BEGIN TRY
				INSERT INTO dbo.AppLog_Machine(MachineId, MachineName, IsProduction, TimeZone, MachineIP)
				EXEC sp_executesql @SqlQuery
			END TRY
			BEGIN CATCH
				
				--manual rollback
				DELETE dbo.AppLog_Machine WITH(ROWLOCK)
				WHERE MachineId > @MaxCurrLogId
				
				--retry
				INSERT INTO dbo.AppLog_Machine(MachineId, MachineName, IsProduction, TimeZone, MachineIP)
				EXEC sp_executesql @SqlQuery

			END CATCH
			SET IDENTITY_INSERT dbo.AppLog_Machine OFF
		END
	END

	BEGIN --AppLog_Category
		SELECT @SqlQuery = '', @MaxCurrLogId = 0
		SELECT @MaxCurrLogId = MAX(CategoryID)
		FROM dbo.AppLog_Category WITH (NOLOCK)

		IF @MaxCurrLogId = 0
		BEGIN
			PRINT 'Some things wrong for [AppLog_Category]. Please check!!!'
			SELECT @MaxCurrLogId = 0
		END

		SET @SqlQuery = 'SELECT *
						FROM OPENQUERY(DBLOG, ''SELECT CategoryID, CategoryName 
						FROM bodb_CustomerLog.dbo.AppLog_Category WITH (NOLOCK)
						WHERE CategoryID > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' 
						OPTION (MAXDOP 8)'')'

		IF @IsDebug = 1
			PRINT @SqlQuery
		ELSE
		BEGIN
			SET IDENTITY_INSERT dbo.AppLog_Category ON

			BEGIN TRY
				INSERT INTO dbo.AppLog_Category(CategoryID, CategoryName)
				EXEC sp_executesql @SqlQuery
			END TRY
			BEGIN CATCH
				--manual rollback
				DELETE dbo.AppLog_Category WITH(ROWLOCK)
				WHERE CategoryID > @MaxCurrLogId
				
				--retry
				INSERT INTO dbo.AppLog_Category(CategoryID, CategoryName)
				EXEC sp_executesql @SqlQuery

			END CATCH
			SET IDENTITY_INSERT dbo.AppLog_Category OFF
		END
	END

	BEGIN --UserLog_CasinoAPI
		SELECT @MaxCurrLogId = KeyValue2, @MaxCurrLogDate = KeyValue
		FROM dbo.SyncingLog_Setting WITH(NOLOCK)
		WHERE KeyId = 'UserLog_CasinoAPI'

		IF @MaxCurrLogId IS NULL OR @MaxCurrLogDate IS NULL
		BEGIN
			SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate
			SELECT @MaxCurrLogId = MAX(LogID), @MaxCurrLogDate = MAX(LogDate)
			FROM dbo.UserLog_CasinoAPI WITH (NOLOCK)
			WHERE LogDate > @LastWeek
		END

		IF @MaxCurrLogId = 0 OR @MaxCurrLogDate IS NULL
		BEGIN
			PRINT 'Some things wrong for [UserLog_CasinoAPI]. Please check!!!'
			--SELECT @MaxCurrLogId = 0, @MaxCurrLogDate = @LastWeek
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [UserLog_CasinoAPI]. Please check!!!'
		END
		ELSE
		BEGIN
			CREATE TABLE #__UserLog_CasinoAPI_Temp (LogID bigint, SystemID tinyint, UserID int, FuncName varchar(200), LogDate datetime, CustID int, ActionID int
				, ReturnValue nvarchar(max), ReturnCode int, TrackingValue xml)

			UserLog_CasinoAPI_OneMore:
			IF @MaxCurrLogDate < DATEADD(DAY, -1, @CurrentDate)
				SET @ToLogDate = DATEADD(DAY, 1, @MaxCurrLogDate)
			ELSE
				SET @ToLogDate = @CurrentDate

			
			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT LogID, SystemID, UserID, FuncName, LogDate, CustID, ActionID, ReturnValue, ReturnCode, CAST(TrackingValue AS NVARCHAR(MAX)) AS TrackingValue 
							FROM bodb_CustomerLog.dbo.UserLog_CasinoAPI WITH (NOLOCK)
							WHERE LogID > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate >= ''''' + CONVERT(VARCHAR(50), @MaxCurrLogDate, 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(50), @ToLogDate, 121) + '''''
							OPTION (MAXDOP 8)'')'
		
			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				SET IDENTITY_INSERT dbo.UserLog_CasinoAPI ON
				BEGIN TRY
					--select @ToLogDate as '@ToLogDate', @MaxCurrLogDate as '@MaxCurrLogDate', @CurrentDate as '@CurrentDate'
					INSERT INTO #__UserLog_CasinoAPI_Temp(LogID, SystemID, UserID, FuncName, LogDate, CustID, ActionID, ReturnValue, ReturnCode, TrackingValue)
					EXEC sp_executesql @SqlQuery
									
					INSERT INTO dbo.UserLog_CasinoAPI(LogID, SystemID, UserID, FuncName, LogDate, CustID, ActionID, ReturnValue, ReturnCode, TrackingValue)
					SELECT LogID, SystemID, UserID, FuncName, LogDate, CustID, ActionID, ReturnValue, ReturnCode, TrackingValue
					FROM #__UserLog_CasinoAPI_Temp

					IF @@ROWCOUNT = 0 AND @ToLogDate < @CurrentDate
					BEGIN
						SET @MaxCurrLogDate = DATEADD(DAY, 1, @MaxCurrLogDate)
						DELETE FROM #__UserLog_CasinoAPI_Temp
						GOTO UserLog_CasinoAPI_OneMore
					END
				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.UserLog_CasinoAPI WITH(ROWLOCK)
					WHERE LogID > @MaxCurrLogId AND LogDate >= @MaxCurrLogDate

					DELETE FROM #__UserLog_CasinoAPI_Temp
				
					--retry
					INSERT INTO #__UserLog_CasinoAPI_Temp(LogID, SystemID, UserID, FuncName, LogDate, CustID, ActionID, ReturnValue, ReturnCode, TrackingValue)
					EXEC sp_executesql @SqlQuery
									
					INSERT INTO dbo.UserLog_CasinoAPI(LogID, SystemID, UserID, FuncName, LogDate, CustID, ActionID, ReturnValue, ReturnCode, TrackingValue)
					SELECT LogID, SystemID, UserID, FuncName, LogDate, CustID, ActionID, ReturnValue, ReturnCode, TrackingValue
					FROM #__UserLog_CasinoAPI_Temp

				END CATCH

				SELECT @MaxCurrLogId = MAX(LogId), @MaxCurrLogDate = MAX(LogDate)
				FROM #__UserLog_CasinoAPI_Temp

				UPDATE dbo.SyncingLog_Setting WITH(UPDLOCK, ROWLOCK)
				SET KeyValue = CONVERT(VARCHAR(50), @MaxCurrLogDate, 121)
					, KeyValue2 = CAST(@MaxCurrLogId AS VARCHAR(50))
				WHERE KeyId = 'UserLog_CasinoAPI'

				DROP TABLE #__UserLog_CasinoAPI_Temp

				SET IDENTITY_INSERT dbo.UserLog_CasinoAPI OFF
			END
		END
	END
	
	BEGIN --UserLog_Credit
		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate
		SELECT @MaxCurrLogId = MAX(LogID), @MaxCurrLogDate = MAX(LogDate)
		FROM dbo.UserLog_Credit WITH (NOLOCK)
		WHERE LogDate > @LastWeek

		IF @MaxCurrLogId = 0 OR @MaxCurrLogDate IS NULL
		BEGIN
			PRINT 'Some things wrong for [UserLog_Credit]. Please check!!!'
			--SELECT @MaxCurrLogId = 0, @MaxCurrLogDate = @LastWeek
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [UserLog_Credit]. Please check!!!'
		END
		ELSE
		BEGIN
			UserLog_Credit_OneMore:
			IF @MaxCurrLogDate < DATEADD(DAY, -1, @CurrentDate)
				SET @ToLogDate = DATEADD(DAY, 1, @MaxCurrLogDate)
			ELSE
				SET @ToLogDate = @CurrentDate

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''
							SELECT logid, userid, custid, logdate, spname, OldValue, NewValue, ip, doing, ActionID, ActualRate, CreatedDate 
							FROM bodb_CustomerLog.dbo.UserLog_Credit WITH (NOLOCK)
							WHERE LogID > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate >= ''''' + CONVERT(VARCHAR(50), DATEADD(MINUTE, -3, @MaxCurrLogDate), 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(16), @ToLogDate, 121) + '''''
							
							UNION ALL
							SELECT logid, userid, custid, logdate, spname, OldValue, NewValue, ip, doing, ActionID, ActualRate, CreatedDate 
							FROM bodb_CustomerLog.dbo.UserLog_Credit WITH (NOLOCK)
							WHERE LogID < ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate > ''''' + CONVERT(VARCHAR(50), @MaxCurrLogDate, 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(16), @ToLogDate, 121) + '''''
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				SET IDENTITY_INSERT dbo.UserLog_Credit ON
				BEGIN TRY
					INSERT INTO dbo.UserLog_Credit(logid, userid, custid, logdate, spname, OldValue, NewValue, ip, doing, ActionID, ActualRate, CreatedDate)
					EXEC sp_executesql @SqlQuery

					IF @@ROWCOUNT = 0 AND @ToLogDate < @CurrentDate
					BEGIN
						SET @MaxCurrLogDate = DATEADD(DAY, 1, @MaxCurrLogDate)
						GOTO UserLog_Credit_OneMore
					END

				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.UserLog_Credit WITH(ROWLOCK)
					WHERE LogID > @MaxCurrLogId AND LogDate >= @MaxCurrLogDate
				
					--retry
					INSERT INTO dbo.UserLog_Credit(logid, userid, custid, logdate, spname, OldValue, NewValue, ip, doing, ActionID, ActualRate, CreatedDate)
					EXEC sp_executesql @SqlQuery

				END CATCH
				SET IDENTITY_INSERT dbo.UserLog_Credit OFF
			END
		END
	END

	BEGIN --UserLog_Exchange
		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate
		SELECT @MaxCurrLogId = MAX(LogID), @MaxCurrLogDate = MAX(LogDate)
		FROM dbo.UserLog_Exchange WITH (NOLOCK)
		WHERE LogDate > @3MonthsAgo

		IF @MaxCurrLogId = 0 OR @MaxCurrLogDate IS NULL
		BEGIN
			PRINT 'Some things wrong for [UserLog_Exchange]. Please check!!!'
			--SELECT @MaxCurrLogId = 0, @MaxCurrLogDate = @LastWeek
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [UserLog_Exchange]. Please check!!!'
		END
		ELSE
		BEGIN
			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT LogID, UserID, ExchangeID, actualrate, doing, IP, LogDate
							FROM bodb_CustomerLog.dbo.UserLog_Exchange WITH (NOLOCK)
							WHERE LogID > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate >= ''''' + CONVERT(VARCHAR(50), @MaxCurrLogDate, 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(50), @ToLogDate, 121) + '''''
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				SET IDENTITY_INSERT dbo.UserLog_Exchange ON
				BEGIN TRY
					INSERT INTO dbo.UserLog_Exchange(LogID, UserID, ExchangeID, actualrate, doing, IP, LogDate)
					EXEC sp_executesql @SqlQuery
				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.UserLog_Exchange WITH(ROWLOCK)
					WHERE LogID > @MaxCurrLogId AND LogDate >= @MaxCurrLogDate
				
					--retry
					INSERT INTO dbo.UserLog_Exchange(LogID, UserID, ExchangeID, actualrate, doing, IP, LogDate)
					EXEC sp_executesql @SqlQuery

				END CATCH

				SET IDENTITY_INSERT dbo.UserLog_Exchange OFF
			END
		END

	END

	BEGIN --UserLog_Login
		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate
		
		SELECT @MaxCurrLogId = KeyValue2, @MaxCurrLogDate = KeyValue
		FROM dbo.SyncingLog_Setting WITH(NOLOCK)
		WHERE KeyId = 'UserLog_Login'

		IF @MaxCurrLogId IS NULL OR @MaxCurrLogDate IS NULL
		BEGIN
			INSERT INTO @TblTmpData(MaxCurrLogId, MaxCurrLogDate, TableName)
			SELECT MAX(LogId), MAX(LogDate), 'UserLog_Login' AS TableName
			FROM dbo.UserLog_Login WITH(NOLOCK)
			WHERE LogDate > @LastWeek
			OPTION(RECOMPILE)

			SELECT @MaxCurrLogId = MaxCurrLogId, @MaxCurrLogDate = MaxCurrLogDate
			FROM @TblTmpData WHERE TableName = 'UserLog_Login'
		END

		IF @MaxCurrLogId = 0 OR @MaxCurrLogDate IS NULL
		BEGIN
			PRINT 'Some things wrong for [UserLog_Login]. Please check!!!'
			SELECT @MaxCurrLogId = 0, @MaxCurrLogDate = @LastWeek
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [UserLog_Login]. Please check!!!'
		END
		ELSE
		BEGIN
			CREATE TABLE #__TmpLoginData (LogID bigint, UserID int, RoleID tinyint, SubAccID int, ServerID int, IP varchar(20), LogDate datetime, ActionID int, Doing varchar(300)
				, DomainName nvarchar(253), BrowserName nvarchar(255), Platform nvarchar(255), CountryCode varchar(64), Duration int, username2 varchar(50), CreatedDate datetime)

			UserLog_Login_OneMore:
			IF @MaxCurrLogDate < DATEADD(HOUR, -3, @CurrentDate)
				SET @ToLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
			ELSE
				SET @ToLogDate = @CurrentDate
			
			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''
							SELECT LogID, UserID, RoleID, SubAccID, ServerID, IP, LogDate, ActionID, Doing, DomainName, BrowserName, Platform, CountryCode, Duration, username2, CreatedDate
							FROM bodb_CustomerLog.dbo.UserLog_Login WITH (NOLOCK)
							WHERE LogID > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate >= ''''' + CONVERT(VARCHAR(50), DATEADD(MINUTE, -3, @MaxCurrLogDate), 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(16), @ToLogDate, 121) + '''''

							UNION ALL
							SELECT LogID, UserID, RoleID, SubAccID, ServerID, IP, LogDate, ActionID, Doing, DomainName, BrowserName, Platform, CountryCode, Duration, username2, CreatedDate
							FROM bodb_CustomerLog.dbo.UserLog_Login WITH (NOLOCK)
							WHERE LogID < ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate >= ''''' + CONVERT(VARCHAR(50), @MaxCurrLogDate, 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(16), @ToLogDate, 121) + '''''

							OPTION (MAXDOP 8)'')'
		
			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				SET IDENTITY_INSERT dbo.UserLog_Login ON
				BEGIN TRY

					INSERT INTO #__TmpLoginData
					EXEC sp_executesql @SqlQuery

					DELETE dbo.UserLog_Login WITH(ROWLOCK)
					WHERE LogID IN (SELECT logid FROM #__TmpLoginData)
						AND LogDate >= CONVERT(VARCHAR(50), DATEADD(MINUTE, -10, @MaxCurrLogDate), 121)
					--OPTION(RECOMPILE, MAXDOP 8)

					INSERT INTO dbo.UserLog_Login(LogID, UserID, RoleID, SubAccID, ServerID, IP, LogDate, ActionID, Doing, DomainName, BrowserName
						, Platform, CountryCode, Duration, username2, CreatedDate)
					SELECT LogID, UserID, RoleID, SubAccID, ServerID, IP, LogDate, ActionID, Doing, DomainName, BrowserName
						, Platform, CountryCode, Duration, username2, CreatedDate
					FROM #__TmpLoginData 
					
					IF @@ROWCOUNT = 0 AND @ToLogDate < @CurrentDate
					BEGIN
						SET @MaxCurrLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
						DELETE FROM #__TmpLoginData
						GOTO UserLog_Login_OneMore
					END

				END TRY
				BEGIN CATCH
					
					DELETE dbo.UserLog_Login WITH(ROWLOCK)
					WHERE LogID IN (SELECT logid FROM #__TmpLoginData)
						AND LogDate >= CONVERT(VARCHAR(50), DATEADD(MINUTE, -10, @MaxCurrLogDate), 121)
					--OPTION(RECOMPILE, MAXDOP 8)

					INSERT INTO dbo.UserLog_Login(LogID, UserID, RoleID, SubAccID, ServerID, IP, LogDate, ActionID, Doing, DomainName, BrowserName
						, Platform, CountryCode, Duration, username2, CreatedDate)
					SELECT LogID, UserID, RoleID, SubAccID, ServerID, IP, LogDate, ActionID, Doing, DomainName, BrowserName
						, Platform, CountryCode, Duration, username2, CreatedDate
					FROM #__TmpLoginData

				END CATCH

				SELECT @MaxCurrLogId = MAX(LogId), @MaxCurrLogDate = MAX(LogDate)
				FROM #__TmpLoginData

				UPDATE dbo.SyncingLog_Setting WITH(UPDLOCK, ROWLOCK)
				SET KeyValue = CONVERT(VARCHAR(50), @MaxCurrLogDate, 121)
					, KeyValue2 = CAST(@MaxCurrLogId AS VARCHAR(50))
				WHERE KeyId = 'UserLog_Login'

				DROP TABLE #__TmpLoginData
				SET IDENTITY_INSERT dbo.UserLog_Login OFF
			END
		END
	END

	BEGIN --UserLog_Login_Lrf
		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate
		SELECT @MaxCurrLogId = MAX(LogID), @MaxCurrLogDate = MAX(LogDate)
		FROM dbo.UserLog_Login_Lrf WITH (NOLOCK)
		WHERE LogDate > @LastWeek

		IF @MaxCurrLogId = 0 OR @MaxCurrLogDate IS NULL
		BEGIN
			PRINT 'Some things wrong for [UserLog_Login_Lrf]. Please check!!!'
			--SELECT @MaxCurrLogId = 0, @MaxCurrLogDate = @LastWeek
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [UserLog_Login_Lrf]. Please check!!!'
		END
		ELSE
		BEGIN
			UserLog_Login_Lrf_OneMore:
			IF @MaxCurrLogDate < DATEADD(DAY, -1, @CurrentDate)
				SET @ToLogDate = DATEADD(DAY, 1, @MaxCurrLogDate)
			ELSE
				SET @ToLogDate = @CurrentDate

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT LogID, UserID, ServerID, IP, LogDate, ActionID, Doing, DomainName, BrowserName, Platform, CountryCode, Duration
							FROM bodb_CustomerLog.dbo.UserLog_Login_Lrf WITH (NOLOCK)
							WHERE LogID > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate >= ''''' + CONVERT(VARCHAR(50), @MaxCurrLogDate, 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(50), @ToLogDate, 121) + '''''
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				SET IDENTITY_INSERT dbo.UserLog_Login_Lrf ON
				BEGIN TRY
					INSERT INTO dbo.UserLog_Login_Lrf(LogID, UserID, ServerID, IP, LogDate, ActionID, Doing, DomainName, BrowserName, Platform, CountryCode, Duration)
					EXEC sp_executesql @SqlQuery

					IF @@ROWCOUNT = 0 AND @ToLogDate < @CurrentDate
					BEGIN
						SET @MaxCurrLogDate = DATEADD(DAY, 1, @MaxCurrLogDate)
						GOTO UserLog_Login_Lrf_OneMore
					END

				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.UserLog_Login_Lrf WITH(ROWLOCK)
					WHERE LogID > @MaxCurrLogId AND LogDate >= @MaxCurrLogDate
				
					--retry
					INSERT INTO dbo.UserLog_Login_Lrf(LogID, UserID, ServerID, IP, LogDate, ActionID, Doing, DomainName, BrowserName, Platform, CountryCode, Duration)
					EXEC sp_executesql @SqlQuery

				END CATCH
				SET IDENTITY_INSERT dbo.UserLog_Login_Lrf OFF
			END
		END
	END

	BEGIN --UserLog_RunSP
		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate
		
		SELECT @MaxCurrLogId = KeyValue2, @MaxCurrLogDate = KeyValue
		FROM dbo.SyncingLog_Setting WITH(NOLOCK)
		WHERE KeyId = 'UserLog_RunSP'

		IF @MaxCurrLogId IS NULL OR @MaxCurrLogDate IS NULL
		BEGIN
			INSERT INTO @TblTmpData(MaxCurrLogId, MaxCurrLogDate, TableName)
			SELECT MAX(LogId), MAX(LogDate), 'UserLog_RunSP' AS TableName
			FROM dbo.UserLog_RunSP WITH(NOLOCK)
			WHERE LogDate > @LastWeek
			OPTION(RECOMPILE)

			SELECT @MaxCurrLogId = MaxCurrLogId, @MaxCurrLogDate = MaxCurrLogDate
			FROM @TblTmpData WHERE TableName = 'UserLog_RunSP'
		END
		IF @MaxCurrLogId = 0 OR @MaxCurrLogDate IS NULL
		BEGIN
			PRINT 'Some things wrong for [UserLog_RunSP]. Please check!!!'
			SELECT @MaxCurrLogId = 0, @MaxCurrLogDate = @LastWeek
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [UserLog_RunSP]. Please check!!!'
		END
		ELSE
		BEGIN
			CREATE TABLE #__UserLog_RunSP_Tmp(logid bigint, userid int, spname varchar(50), doing varchar(4000), logdate datetime, custid int, ActionID int, TrackingValue nvarchar(max)
				, Duration int, TrackingValue2 nvarchar(max), CreatedDate datetime)

			UserLog_RunSP_OneMore:
			IF @MaxCurrLogDate < DATEADD(HOUR, -3, @CurrentDate)
				SET @ToLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
			ELSE
				SET @ToLogDate = @CurrentDate

			IF @ToLogDate > @CurrentDate
				SET @ToLogDate = @CurrentDate
			
			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT logid, userid, spname, doing, logdate, custid, ActionID, TrackingValue, Duration, TrackingValue2, CreatedDate
							FROM bodb_CustomerLog.dbo.UserLog_RunSP WITH (NOLOCK)
							WHERE LogID > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate >= ''''' + CONVERT(VARCHAR(50), @MaxCurrLogDate, 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(50), @ToLogDate, 121) + '''''
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				SET IDENTITY_INSERT dbo.UserLog_RunSP ON
				BEGIN TRY
					INSERT INTO #__UserLog_RunSP_Tmp(logid, userid, spname, doing, logdate, custid, ActionID, TrackingValue, Duration, TrackingValue2, CreatedDate)
					EXEC sp_executesql @SqlQuery
					
					INSERT INTO dbo.UserLog_RunSP(logid, userid, spname, doing, logdate, custid, ActionID, TrackingValue, Duration, TrackingValue2, CreatedDate)
					SELECT logid, userid, spname, doing, logdate, custid, ActionID, TrackingValue, Duration, TrackingValue2, CreatedDate
					FROM #__UserLog_RunSP_Tmp

					IF @@ROWCOUNT = 0 AND @ToLogDate < @CurrentDate
					BEGIN
						SET @MaxCurrLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
						DELETE FROM #__UserLog_RunSP_Tmp
						GOTO UserLog_RunSP_OneMore
					END

				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.UserLog_RunSP WITH(ROWLOCK)
					WHERE LogID > @MaxCurrLogId AND LogDate >= @MaxCurrLogDate
					
					DELETE FROM #__UserLog_RunSP_Tmp
				
					--retry
					INSERT INTO #__UserLog_RunSP_Tmp(logid, userid, spname, doing, logdate, custid, ActionID, TrackingValue, Duration, TrackingValue2, CreatedDate)
					EXEC sp_executesql @SqlQuery
					
					INSERT INTO dbo.UserLog_RunSP(logid, userid, spname, doing, logdate, custid, ActionID, TrackingValue, Duration, TrackingValue2, CreatedDate)
					SELECT logid, userid, spname, doing, logdate, custid, ActionID, TrackingValue, Duration, TrackingValue2, CreatedDate
					FROM #__UserLog_RunSP_Tmp

				END CATCH
				
				SELECT @MaxCurrLogId = MAX(LogId), @MaxCurrLogDate = MAX(LogDate)
				FROM #__UserLog_RunSP_Tmp

				UPDATE dbo.SyncingLog_Setting WITH(UPDLOCK, ROWLOCK)
				SET KeyValue = CONVERT(VARCHAR(50), @MaxCurrLogDate, 121)
					, KeyValue2 = CAST(@MaxCurrLogId AS VARCHAR(50))
				WHERE KeyId = 'UserLog_RunSP'

				DROP TABLE #__UserLog_RunSP_Tmp

				SET IDENTITY_INSERT dbo.UserLog_RunSP OFF
			END
		END
	END

	BEGIN --UserLog_Dep_CustSetting
		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate
		
		SELECT @MaxCurrLogId = KeyValue2, @MaxCurrLogDate = KeyValue
		FROM dbo.SyncingLog_Setting WITH(NOLOCK)
		WHERE KeyId = 'UserLog_Dep_CustSetting'

		IF @MaxCurrLogId IS NULL OR @MaxCurrLogDate IS NULL
		BEGIN
			INSERT INTO @TblTmpData(MaxCurrLogId, MaxCurrLogDate, TableName)
			SELECT MAX(LogId), MAX(LogDate), 'UserLog_Dep_CustSetting' AS TableName
			FROM dbo.UserLog_Dep_CustSetting WITH(NOLOCK)
			WHERE LogDate > @LastWeek
			OPTION(RECOMPILE)

			SELECT @MaxCurrLogId = MaxCurrLogId, @MaxCurrLogDate = MaxCurrLogDate
			FROM @TblTmpData WHERE TableName = 'UserLog_Dep_CustSetting'
		END
		IF @MaxCurrLogId = 0 OR @MaxCurrLogDate IS NULL
		BEGIN
			PRINT 'Some things wrong for [UserLog_Dep_CustSetting]. Please check!!!'
			SELECT @MaxCurrLogId = 0, @MaxCurrLogDate = @LastWeek
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [UserLog_Dep_CustSetting]. Please check!!!'
		END
		ELSE
		BEGIN

			CREATE TABLE #__UserLog_Dep_CustSetting_Tmp(LogID bigint, UserID int, CustID int, logDate datetime, ActionID int, TrackingValue varchar(max), TrackingValue2 varchar(max), Duration int, Language varchar(3), IP varchar(15))

			UserLog_Dep_CustSetting_OneMore:
			IF @MaxCurrLogDate < DATEADD(HOUR, -3, @CurrentDate)
				SET @ToLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
			ELSE
				SET @ToLogDate = @CurrentDate
			
			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT LogID, UserID, CustID, logDate, ActionID, TrackingValue, TrackingValue2, Duration, Language, IP
							FROM bodb_CustomerLog.dbo.UserLog_Dep_CustSetting WITH (NOLOCK)
							WHERE LogID > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate >= ''''' + CONVERT(VARCHAR(50), @MaxCurrLogDate, 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(50), @ToLogDate, 121) + '''''
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				SET IDENTITY_INSERT dbo.UserLog_Dep_CustSetting ON
				BEGIN TRY
					INSERT INTO #__UserLog_Dep_CustSetting_Tmp(LogID, UserID, CustID, logDate, ActionID, TrackingValue, TrackingValue2, Duration, Language, IP)
					EXEC sp_executesql @SqlQuery
					
					INSERT INTO dbo.UserLog_Dep_CustSetting(LogID, UserID, CustID, logDate, ActionID, TrackingValue, TrackingValue2, Duration, Language, IP)
					SELECT LogID, UserID, CustID, logDate, ActionID, TrackingValue, TrackingValue2, Duration, Language, IP
					FROM #__UserLog_Dep_CustSetting_Tmp

					IF @@ROWCOUNT = 0 AND @ToLogDate < @CurrentDate
					BEGIN
						SET @MaxCurrLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
						DELETE FROM #__UserLog_Dep_CustSetting_Tmp
						GOTO UserLog_Dep_CustSetting_OneMore
					END

				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.UserLog_Dep_CustSetting WITH(ROWLOCK)
					WHERE LogID > @MaxCurrLogId AND LogDate >= @MaxCurrLogDate
					
					DELETE FROM #__UserLog_Dep_CustSetting_Tmp
				
					--retry
					INSERT INTO #__UserLog_Dep_CustSetting_Tmp(LogID, UserID, CustID, logDate, ActionID, TrackingValue, TrackingValue2, Duration, Language, IP)
					EXEC sp_executesql @SqlQuery
					
					INSERT INTO dbo.UserLog_Dep_CustSetting(LogID, UserID, CustID, logDate, ActionID, TrackingValue, TrackingValue2, Duration, Language, IP)
					SELECT LogID, UserID, CustID, logDate, ActionID, TrackingValue, TrackingValue2, Duration, Language, IP
					FROM #__UserLog_Dep_CustSetting_Tmp

				END CATCH
				
				SELECT @MaxCurrLogId = MAX(LogId), @MaxCurrLogDate = MAX(LogDate)
				FROM #__UserLog_Dep_CustSetting_Tmp

				UPDATE dbo.SyncingLog_Setting WITH(UPDLOCK, ROWLOCK)
				SET KeyValue = CONVERT(VARCHAR(50), @MaxCurrLogDate, 121)
					, KeyValue2 = CAST(@MaxCurrLogId AS VARCHAR(50))
				WHERE KeyId = 'UserLog_Dep_CustSetting'

				DROP TABLE #__UserLog_Dep_CustSetting_Tmp

				SET IDENTITY_INSERT dbo.UserLog_Dep_CustSetting OFF
			END
		END
	END

	BEGIN --UserLog_Settle
		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate
		SELECT @MaxCurrLogId = MAX(LogID), @MaxCurrLogDate = MAX(LogDate)
		FROM dbo.UserLog_Settle WITH (NOLOCK)
		WHERE LogDate > @LastWeek

		IF @MaxCurrLogId = 0 OR @MaxCurrLogDate IS NULL
		BEGIN
			PRINT 'Some things wrong for [UserLog_Settle]. Please check!!!'
			SELECT @MaxCurrLogId = 0, @MaxCurrLogDate = @LastWeek
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [UserLog_Settle]. Please check!!!'
		END
		ELSE
		BEGIN
			UserLog_Settle_OneMore:
			IF @MaxCurrLogDate < DATEADD(HOUR, -3, @CurrentDate)
				SET @ToLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
			ELSE
				SET @ToLogDate = @CurrentDate

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT LogID, LogDate, UserID, MatchID, ActionID, finalhomescore, finalawayscore, hthomescore, htawayscore, GoalRecord, betstatus, Remark, IP
							FROM bodb_CustomerLog.dbo.UserLog_Settle WITH (NOLOCK)
							WHERE LogID > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate >= ''''' + CONVERT(VARCHAR(50), @MaxCurrLogDate, 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(50), @ToLogDate, 121) + '''''
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				SET IDENTITY_INSERT dbo.UserLog_Settle ON
				BEGIN TRY
					INSERT INTO dbo.UserLog_Settle(LogID, LogDate, UserID, MatchID, ActionID, finalhomescore, finalawayscore, hthomescore, htawayscore, GoalRecord, betstatus, Remark, IP)
					EXEC sp_executesql @SqlQuery

					IF @@ROWCOUNT = 0 AND @ToLogDate < @CurrentDate
					BEGIN
						SET @MaxCurrLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
						GOTO UserLog_Settle_OneMore
					END

				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.UserLog_Settle WITH(ROWLOCK)
					WHERE LogID > @MaxCurrLogId AND LogDate >= @MaxCurrLogDate
				
					--retry
					INSERT INTO dbo.UserLog_Settle(LogID, LogDate, UserID, MatchID, ActionID, finalhomescore, finalawayscore, hthomescore, htawayscore, GoalRecord, betstatus, Remark, IP)
					EXEC sp_executesql @SqlQuery

				END CATCH
				SET IDENTITY_INSERT dbo.UserLog_Settle OFF
			END
		END
	END

	BEGIN --UserLog_Settle_Checking
		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate
		SELECT @MaxCurrLogId = MAX(LogID), @MaxCurrLogDate = MAX(LogDate)
		FROM dbo.UserLog_Settle_Checking WITH (NOLOCK)
		WHERE LogDate > @LastWeek

		IF @MaxCurrLogId = 0 OR @MaxCurrLogDate IS NULL
		BEGIN
			PRINT 'Some things wrong for [UserLog_Settle_Checking]. Please check!!!'
			SELECT @MaxCurrLogId = 0, @MaxCurrLogDate = @LastWeek
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [UserLog_Settle_Checking]. Please check!!!'
		END
		ELSE
		BEGIN
			UserLog_Settle_Checking_OneMore:
			IF @MaxCurrLogDate < DATEADD(HOUR, -3, @CurrentDate)
				SET @ToLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
			ELSE
				SET @ToLogDate = @CurrentDate

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT LogID, LogDate, UserID, MatchID, KeyID, ActionID, Remark
							FROM bodb_CustomerLog.dbo.UserLog_Settle_Checking WITH (NOLOCK)
							WHERE LogID > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate >= ''''' + CONVERT(VARCHAR(50), @MaxCurrLogDate, 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(50), @ToLogDate, 121) + '''''
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			BEGIN
				SET IDENTITY_INSERT dbo.UserLog_Settle_Checking ON
				BEGIN TRY
					INSERT INTO dbo.UserLog_Settle_Checking(LogID, LogDate, UserID, MatchID, KeyID, ActionID, Remark)
					EXEC sp_executesql @SqlQuery

					IF @@ROWCOUNT = 0 AND @ToLogDate < @CurrentDate
					BEGIN
						SET @MaxCurrLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
						GOTO UserLog_Settle_Checking_OneMore
					END

				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.UserLog_Settle_Checking WITH(ROWLOCK)
					WHERE LogID > @MaxCurrLogId AND LogDate >= @MaxCurrLogDate
				
					--retry
					INSERT INTO dbo.UserLog_Settle_Checking(LogID, LogDate, UserID, MatchID, KeyID, ActionID, Remark)
					EXEC sp_executesql @SqlQuery

				END CATCH
				SET IDENTITY_INSERT dbo.UserLog_Settle_Checking OFF
			END

		END

	END
	
	BEGIN --UserLog_Transaction
		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate
		
		SELECT @MaxCurrLogId = KeyValue2, @MaxCurrLogDate = KeyValue
		FROM dbo.SyncingLog_Setting WITH(NOLOCK)
		WHERE KeyId = 'UserLog_Transaction'

		IF @MaxCurrLogId IS NULL OR @MaxCurrLogDate IS NULL
		BEGIN
			INSERT INTO @TblTmpData(MaxCurrLogId, MaxCurrLogDate, TableName)
			SELECT MAX(LogId), MAX(LogDate), 'UserLog_Transaction' AS TableName
			FROM dbo.UserLog_Transaction WITH(NOLOCK)
			WHERE LogDate > @LastWeek
			--OPTION(RECOMPILE, MAXDOP 8)

			SELECT @MaxCurrLogId = MaxCurrLogId, @MaxCurrLogDate = MaxCurrLogDate
			FROM @TblTmpData WHERE TableName = 'UserLog_Transaction'
		END

		IF @MaxCurrLogId = 0 OR @MaxCurrLogDate IS NULL
		BEGIN
			PRINT 'Some things wrong for [UserLog_Transaction]. Please check!!!'
			--SELECT @MaxCurrLogId = 0, @MaxCurrLogDate = @LastWeek
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [UserLog_Transaction]. Please check!!!'
		END
		ELSE
		BEGIN
			CREATE TABLE #__UserLog_Transaction_Temp (LogID bigint, LogDate datetime, ActionID int, Refno bigint, UserID int, IP varchar(15), Doing varchar(1000))
			UserLog_Transaction_OneMore:
			IF @MaxCurrLogDate < DATEADD(HOUR, -3, @CurrentDate)
				SET @ToLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
			ELSE
				SET @ToLogDate = @CurrentDate
				
			
			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT LogID, LogDate, ActionID, Refno, UserID, IP, Doing
							FROM bodb_CustomerLog.dbo.UserLog_Transaction WITH (NOLOCK)
							WHERE LogID > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate >= ''''' + CONVERT(VARCHAR(50), DATEADD(MINUTE, -3, @MaxCurrLogDate), 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(50), @ToLogDate, 121) + '''''
							OPTION (MAXDOP 8)'')'
		
			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				SET IDENTITY_INSERT dbo.UserLog_Transaction ON
				BEGIN TRY
					DELETE FROM #__UserLog_Transaction_Temp
					INSERT INTO #__UserLog_Transaction_Temp(LogID, LogDate, ActionID, Refno, UserID, IP, Doing)
					EXEC sp_executesql @SqlQuery

					INSERT INTO dbo.UserLog_Transaction(LogID, LogDate, ActionID, Refno, UserID, IP, Doing)
					SELECT LogID, LogDate, ActionID, Refno, UserID, IP, Doing
					FROM #__UserLog_Transaction_Temp

					IF @@ROWCOUNT = 0 AND @ToLogDate < @CurrentDate
					BEGIN
						SET @MaxCurrLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
						GOTO UserLog_Transaction_OneMore
					END

				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.UserLog_Transaction WITH(ROWLOCK)
					WHERE LogID > @MaxCurrLogId AND LogDate >= @MaxCurrLogDate
					
					DELETE FROM #__UserLog_Transaction_Temp

					--retry
					INSERT INTO #__UserLog_Transaction_Temp(LogID, LogDate, ActionID, Refno, UserID, IP, Doing)
					EXEC sp_executesql @SqlQuery

					INSERT INTO dbo.UserLog_Transaction(LogID, LogDate, ActionID, Refno, UserID, IP, Doing)
					SELECT LogID, LogDate, ActionID, Refno, UserID, IP, Doing
					FROM #__UserLog_Transaction_Temp

				END CATCH

				SELECT @MaxCurrLogId = MAX(LogId), @MaxCurrLogDate = MAX(LogDate)
				FROM #__UserLog_Transaction_Temp

				UPDATE dbo.SyncingLog_Setting WITH(UPDLOCK, ROWLOCK)
				SET KeyValue = CONVERT(VARCHAR(50), @MaxCurrLogDate, 121)
					, KeyValue2 = CAST(@MaxCurrLogId AS VARCHAR(50))
				WHERE KeyId = 'UserLog_Transaction'

				DROP TABLE #__UserLog_Transaction_Temp

				SET IDENTITY_INSERT dbo.UserLog_Transaction OFF
			END

		END

	END

	BEGIN --UserLog_Transfer
		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate
		SELECT @MaxCurrLogId = MAX(LogID), @MaxCurrLogDate = MAX(LogDate)
		FROM dbo.UserLog_Transfer WITH (NOLOCK)
		WHERE LogDate > @LastWeek
		
		IF @MaxCurrLogId = 0 OR @MaxCurrLogDate IS NULL
		BEGIN
			PRINT 'Some things wrong for [UserLog_Transfer]. Please check!!!'
			SELECT @MaxCurrLogId = 0, @MaxCurrLogDate = @LastWeek
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [UserLog_Transfer]. Please check!!!'
		END
		ELSE
		BEGIN
			UserLog_Transfer_OneMore:
			IF @MaxCurrLogDate < DATEADD(DAY, -1, @CurrentDate)
				SET @ToLogDate = DATEADD(DAY, 1, @MaxCurrLogDate)
			ELSE
				SET @ToLogDate = @CurrentDate

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT LogID, LogDate, UserID, FromCustID, ToCustID, IP, Doing
							FROM bodb_CustomerLog.dbo.UserLog_Transfer WITH (NOLOCK)
							WHERE LogID > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate >= ''''' + CONVERT(VARCHAR(50), @MaxCurrLogDate, 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(50), @ToLogDate, 121) + '''''
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				SET IDENTITY_INSERT dbo.UserLog_Transfer ON
				BEGIN TRY
					INSERT INTO dbo.UserLog_Transfer(LogID, LogDate, UserID, FromCustID, ToCustID, IP, Doing)
					EXEC sp_executesql @SqlQuery

					IF @@ROWCOUNT = 0 AND @ToLogDate < @CurrentDate
					BEGIN
						SET @MaxCurrLogDate = DATEADD(DAY, 1, @MaxCurrLogDate)
						GOTO UserLog_Transfer_OneMore
					END

				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.UserLog_Transfer WITH(ROWLOCK)
					WHERE LogID > @MaxCurrLogId AND LogDate >= @MaxCurrLogDate
				
					--retry
					INSERT INTO dbo.UserLog_Transfer(LogID, LogDate, UserID, FromCustID, ToCustID, IP, Doing)
					EXEC sp_executesql @SqlQuery

				END CATCH

				SET IDENTITY_INSERT dbo.UserLog_Transfer OFF
			END

		END

	END

	BEGIN --UserLog_UserControl
		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate
		SELECT @MaxCurrLogId = MAX(LogID), @MaxCurrLogDate = MAX(LogDate)
		FROM dbo.UserLog_UserControl WITH (NOLOCK)
		WHERE LogDate > @3MonthsAgo
		
		IF @MaxCurrLogId = 0 OR @MaxCurrLogDate IS NULL
		BEGIN
			PRINT 'Some things wrong for [UserLog_UserControl]. Please check!!!'
			--SELECT @MaxCurrLogId = 0, @MaxCurrLogDate = @LastWeek
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [UserLog_UserControl]. Please check!!!'
		END
		ELSE
		BEGIN
			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''SELECT LogID, CustID, LogDate, UserID, TypeID, ActionID, Duration, Doing
							FROM bodb_CustomerLog.dbo.UserLog_UserControl WITH (NOLOCK)
							WHERE LogID > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate >= ''''' + CONVERT(VARCHAR(50), @MaxCurrLogDate, 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(50), @ToLogDate, 121) + '''''
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				SET IDENTITY_INSERT dbo.UserLog_UserControl ON
				BEGIN TRY
					INSERT INTO dbo.UserLog_UserControl(LogID, CustID, LogDate, UserID, TypeID, ActionID, Duration, Doing)
					EXEC sp_executesql @SqlQuery
				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.UserLog_UserControl WITH(ROWLOCK)
					WHERE LogID > @MaxCurrLogId AND LogDate >= @MaxCurrLogDate
				
					--retry
					INSERT INTO dbo.UserLog_UserControl(LogID, CustID, LogDate, UserID, TypeID, ActionID, Duration, Doing)
					EXEC sp_executesql @SqlQuery

				END CATCH
				SET IDENTITY_INSERT dbo.UserLog_UserControl OFF
			END
		END

	END

	BEGIN --UserLog_ExternalAPI
		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate
		
		SELECT @MaxCurrLogId = KeyValue2, @MaxCurrLogDate = KeyValue
		FROM dbo.SyncingLog_Setting WITH(NOLOCK)
		WHERE KeyId = 'UserLog_ExternalAPI'

		IF @MaxCurrLogId IS NULL OR @MaxCurrLogDate IS NULL
		BEGIN
			INSERT INTO @TblTmpData(MaxCurrLogId, MaxCurrLogDate, TableName)
			SELECT MAX(LogId), MAX(LogDate), 'UserLog_ExternalAPI' AS TableName
			FROM dbo.UserLog_ExternalAPI WITH(NOLOCK)
			WHERE LogDate > @LastWeek
			OPTION(RECOMPILE)

			SELECT @MaxCurrLogId = MaxCurrLogId, @MaxCurrLogDate = MaxCurrLogDate
			FROM @TblTmpData WHERE TableName = 'UserLog_ExternalAPI'
		END

		IF @MaxCurrLogId = 0 OR @MaxCurrLogDate IS NULL
		BEGIN
			PRINT 'Some things wrong for [UserLog_ExternalAPI]. Please check!!!'
			SELECT @MaxCurrLogId = 0, @MaxCurrLogDate = @LastWeek
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [UserLog_ExternalAPI]. Please check!!!'
		END
		ELSE
		BEGIN
			CREATE TABLE #__TmpExternalAPIData (LogID bigint, LogDate datetime, SystemID smallint, ProductID smallint, UserID int, FuncName varchar(200), CustID int, ActionID int, TrackingValue xml, ModifiedDate datetime, StatusID tinyint, isNotified bit, ReturnCode int, ReturnValue nvarchar(max))

			UserLog_ExternalAPI_OneMore:
			IF @MaxCurrLogDate < DATEADD(HOUR, -3, @CurrentDate)
				SET @ToLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
			ELSE
				SET @ToLogDate = @CurrentDate

			DELETE FROM #__TmpExternalAPIData
			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''
							SELECT LogID, LogDate, SystemID, ProductID, UserID, FuncName, CustID, ActionID, CAST(TrackingValue AS NVARCHAR(MAX)), ModifiedDate, StatusID, isNotified, ReturnCode, ReturnValue
							FROM bodb_CustomerLog.dbo.UserLog_ExternalAPI WITH (NOLOCK)
							WHERE LogID > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate >= ''''' + CONVERT(VARCHAR(50), DATEADD(MINUTE, -3, @MaxCurrLogDate), 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(16), @ToLogDate, 121) + '''''

							UNION ALL
							SELECT LogID, LogDate, SystemID, ProductID, UserID, FuncName, CustID, ActionID, CAST(TrackingValue AS NVARCHAR(MAX)), ModifiedDate, StatusID, isNotified, ReturnCode, ReturnValue
							FROM bodb_CustomerLog.dbo.UserLog_ExternalAPI WITH (NOLOCK)
							WHERE LogID < ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate >= ''''' + CONVERT(VARCHAR(50), @MaxCurrLogDate, 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(16), @ToLogDate, 121) + '''''

							OPTION (MAXDOP 8)'')'
		
			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				SET IDENTITY_INSERT dbo.UserLog_ExternalAPI ON
				BEGIN TRY

					INSERT INTO #__TmpExternalAPIData
					EXEC sp_executesql @SqlQuery

					DELETE dbo.UserLog_ExternalAPI WITH(ROWLOCK)
					WHERE LogID IN (SELECT logid FROM #__TmpExternalAPIData)
						AND LogDate >= CONVERT(VARCHAR(50), DATEADD(MINUTE, -10, @MaxCurrLogDate), 121)
					--OPTION(RECOMPILE, MAXDOP 8)

					INSERT INTO dbo.UserLog_ExternalAPI(LogID, LogDate, SystemID, ProductID, UserID, FuncName, CustID, ActionID, TrackingValue, ModifiedDate, StatusID, isNotified, ReturnCode, ReturnValue)
					SELECT LogID, LogDate, SystemID, ProductID, UserID, FuncName, CustID, ActionID, TrackingValue, ModifiedDate, StatusID, isNotified, ReturnCode, ReturnValue
					FROM #__TmpExternalAPIData 
					
					IF @@ROWCOUNT = 0 AND @ToLogDate < @CurrentDate
					BEGIN
						SET @MaxCurrLogDate = DATEADD(HOUR, 3, @MaxCurrLogDate)
						GOTO UserLog_ExternalAPI_OneMore
					END

				END TRY
				BEGIN CATCH
					
					DELETE dbo.UserLog_ExternalAPI WITH(ROWLOCK)
					WHERE LogID IN (SELECT logid FROM #__TmpExternalAPIData)
						AND LogDate >= CONVERT(VARCHAR(50), DATEADD(MINUTE, -10, @MaxCurrLogDate), 121)
					--OPTION(RECOMPILE, MAXDOP 8)

					INSERT INTO dbo.UserLog_ExternalAPI(LogID, LogDate, SystemID, ProductID, UserID, FuncName, CustID, ActionID, TrackingValue, ModifiedDate, StatusID, isNotified, ReturnCode, ReturnValue)
					SELECT LogID, LogDate, SystemID, ProductID, UserID, FuncName, CustID, ActionID, TrackingValue, ModifiedDate, StatusID, isNotified, ReturnCode, ReturnValue
					FROM #__TmpExternalAPIData

				END CATCH

				SELECT @MaxCurrLogId = MAX(LogId), @MaxCurrLogDate = MAX(LogDate)
				FROM #__TmpExternalAPIData

				UPDATE dbo.SyncingLog_Setting WITH(UPDLOCK, ROWLOCK)
				SET KeyValue = CONVERT(VARCHAR(50), @MaxCurrLogDate, 121)
					, KeyValue2 = CAST(@MaxCurrLogId AS VARCHAR(50))
				WHERE KeyId = 'UserLog_ExternalAPI'

				DROP TABLE #__TmpExternalAPIData
				SET IDENTITY_INSERT dbo.UserLog_ExternalAPI OFF
			END
		END
	END
	
END
