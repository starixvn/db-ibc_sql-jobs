/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb_CustomerLog]
GO
ALTER PROCEDURE [dbo].[Task_Sync_CustomerLog_For_CS_Part] @IsDebug BIT = 0	
AS
/*   
	Task : copy CustomerLog data from active server to standby server
	DB: DB054.bodb_customerLog, DB052.bodb_customerLog  
	Revisions:   
	- 20190729@Patrick: create SP   
*/  
SET NOCOUNT ON
BEGIN
	DECLARE @localServer sysname, @remoteServer sysname
	
	SET @localServer = @@servername
	SET @remoteServer = (SELECT * FROM OPENQUERY (DBLOG, 'select @@servername'))
	--SELECT @localServer, @remoteServer
	
	-- invalid remote server
	IF @localServer = @remoteServer RETURN -- same server, do nothing.

	DECLARE @MaxCurrLogId BIGINT, @SqlQuery NVARCHAR(1024), @LastWeek DATETIME
		, @MaxCurrLogDate DATETIME, @CurrentDate DATETIME, @ToLogDate DATETIME

	SELECT @LastWeek = DATEADD(DAY, -7, GETDATE())
		, @CurrentDate = DATEADD(MINUTE, -3, GETDATE())
		, @ToLogDate = DATEADD(MINUTE, -3, GETDATE())

	IF @IsDebug IS NULL
		SET @IsDebug = 0

	BEGIN --CS_UserLog_Credit
		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate
		SELECT @MaxCurrLogId = MAX(LogID), @MaxCurrLogDate = MAX(LogDate)
		FROM dbo.CS_UserLog_Credit WITH (NOLOCK)
		WHERE LogDate > @LastWeek

		IF @MaxCurrLogId = 0 OR @MaxCurrLogDate IS NULL
		BEGIN
			PRINT 'Some things wrong for [CS_UserLog_Credit]. Please check!!!'
			--SELECT @MaxCurrLogId = 0, @MaxCurrLogDate = @LastWeek
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [CS_UserLog_Credit]. Please check!!!'
		END
		ELSE
		BEGIN
			CS_UserLog_Credit_OneMore:
			IF @MaxCurrLogDate < DATEADD(HOUR, -2, @CurrentDate)
				SET @ToLogDate = DATEADD(HOUR, 2, @MaxCurrLogDate)
			ELSE
				SET @ToLogDate = @CurrentDate

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''
							SELECT [LogID], [UserID], [CustID], [SubAccID], [LogDate], [OldValue], [NewValue], [IP], [Doing], [ActionID], [ActualRate], [CreatedDate] 
							FROM bodb_CustomerLog.dbo.CS_UserLog_Credit WITH (NOLOCK)
							WHERE LogID > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate >= ''''' + CONVERT(VARCHAR(50), DATEADD(MINUTE, -3, @MaxCurrLogDate), 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(16), @ToLogDate, 121) + '''''
							
							UNION ALL
							SELECT [LogID], [UserID], [CustID], [SubAccID], [LogDate], [OldValue], [NewValue], [IP], [Doing], [ActionID], [ActualRate], [CreatedDate] 
							FROM bodb_CustomerLog.dbo.CS_UserLog_Credit WITH (NOLOCK)
							WHERE LogID < ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate > ''''' + CONVERT(VARCHAR(50), @MaxCurrLogDate, 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(16), @ToLogDate, 121) + '''''
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				SET IDENTITY_INSERT dbo.CS_UserLog_Credit ON
				BEGIN TRY
					INSERT INTO dbo.CS_UserLog_Credit([LogID], [UserID], [CustID], [SubAccID], [LogDate], [OldValue], [NewValue], [IP], [Doing], [ActionID], [ActualRate], [CreatedDate])
					EXEC sp_executesql @SqlQuery

					IF @@ROWCOUNT = 0 AND @ToLogDate < @CurrentDate
					BEGIN
						SET @MaxCurrLogDate = DATEADD(HOUR, 2, @MaxCurrLogDate)
						GOTO CS_UserLog_Credit_OneMore
					END

				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.CS_UserLog_Credit WITH(ROWLOCK)
					WHERE LogID > @MaxCurrLogId AND LogDate >= @MaxCurrLogDate
				
					--retry
					INSERT INTO dbo.CS_UserLog_Credit([LogID], [UserID], [CustID], [SubAccID], [LogDate], [OldValue], [NewValue], [IP], [Doing], [ActionID], [ActualRate], [CreatedDate])
					EXEC sp_executesql @SqlQuery

				END CATCH
				SET IDENTITY_INSERT dbo.CS_UserLog_Credit OFF
			END
		END
	END

	BEGIN --CS_UserLog_Login
		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate
		SELECT @MaxCurrLogId = MAX(LogID), @MaxCurrLogDate = MAX(LogDate)
		FROM dbo.CS_UserLog_Login WITH (NOLOCK)
		WHERE LogDate > @LastWeek

		IF @MaxCurrLogId = 0 OR @MaxCurrLogDate IS NULL
		BEGIN
			PRINT 'Some things wrong for [CS_UserLog_Login]. Please check!!!'
			--SELECT @MaxCurrLogId = 0, @MaxCurrLogDate = @LastWeek
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [CS_UserLog_Login]. Please check!!!'
		END
		ELSE
		BEGIN
			CS_UserLog_Login_OneMore:
			IF @MaxCurrLogDate < DATEADD(HOUR, -2, @CurrentDate)
				SET @ToLogDate = DATEADD(HOUR, 2, @MaxCurrLogDate)
			ELSE
				SET @ToLogDate = @CurrentDate

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''
							SELECT [LogID], [UserID], [RoleID], [SubAccID], [ServerID], [IP], [LogDate], [ActionID], [Doing], [DomainName], [BrowserName], [Platform], [CountryCode], [Duration], [username2], [CreatedDate]
							FROM bodb_CustomerLog.dbo.CS_UserLog_Login WITH (NOLOCK)
							WHERE LogID > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate >= ''''' + CONVERT(VARCHAR(50), DATEADD(MINUTE, -3, @MaxCurrLogDate), 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(16), @ToLogDate, 121) + '''''
							
							UNION ALL
							SELECT [LogID], [UserID], [RoleID], [SubAccID], [ServerID], [IP], [LogDate], [ActionID], [Doing], [DomainName], [BrowserName], [Platform], [CountryCode], [Duration], [username2], [CreatedDate]
							FROM bodb_CustomerLog.dbo.CS_UserLog_Login WITH (NOLOCK)
							WHERE LogID < ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate > ''''' + CONVERT(VARCHAR(50), @MaxCurrLogDate, 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(16), @ToLogDate, 121) + '''''
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				SET IDENTITY_INSERT dbo.CS_UserLog_Login ON
				BEGIN TRY
					INSERT INTO dbo.CS_UserLog_Login([LogID], [UserID], [RoleID], [SubAccID], [ServerID], [IP], [LogDate], [ActionID], [Doing], [DomainName], [BrowserName], [Platform], [CountryCode], [Duration], [username2], [CreatedDate])
					EXEC sp_executesql @SqlQuery

					IF @@ROWCOUNT = 0 AND @ToLogDate < @CurrentDate
					BEGIN
						SET @MaxCurrLogDate = DATEADD(HOUR, 2, @MaxCurrLogDate)
						GOTO CS_UserLog_Login_OneMore
					END

				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.CS_UserLog_Login WITH(ROWLOCK)
					WHERE LogID > @MaxCurrLogId AND LogDate >= @MaxCurrLogDate
				
					--retry
					INSERT INTO dbo.CS_UserLog_Login([LogID], [UserID], [RoleID], [SubAccID], [ServerID], [IP], [LogDate], [ActionID], [Doing], [DomainName], [BrowserName], [Platform], [CountryCode], [Duration], [username2], [CreatedDate])
					EXEC sp_executesql @SqlQuery

				END CATCH
				SET IDENTITY_INSERT dbo.CS_UserLog_Login OFF
			END
		END
	END

	BEGIN --CS_UserLog_RunSP
		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate
		SELECT @MaxCurrLogId = MAX(LogID), @MaxCurrLogDate = MAX(LogDate)
		FROM dbo.CS_UserLog_RunSP WITH (NOLOCK)
		WHERE LogDate > @LastWeek

		IF @MaxCurrLogId = 0 OR @MaxCurrLogDate IS NULL
		BEGIN
			PRINT 'Some things wrong for [CS_UserLog_RunSP]. Please check!!!'
			--SELECT @MaxCurrLogId = 0, @MaxCurrLogDate = @LastWeek
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [CS_UserLog_RunSP]. Please check!!!'
		END
		ELSE
		BEGIN
			CS_UserLog_RunSP_OneMore:
			IF @MaxCurrLogDate < DATEADD(HOUR, -2, @CurrentDate)
				SET @ToLogDate = DATEADD(HOUR, 2, @MaxCurrLogDate)
			ELSE
				SET @ToLogDate = @CurrentDate

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''
							SELECT [LogID], [UserID], [LogDate], [CustID], [SubAccID], [ActionID], [TrackingValue], [Duration], [TrackingValue2]
							FROM bodb_CustomerLog.dbo.CS_UserLog_RunSP WITH (NOLOCK)
							WHERE LogID > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate >= ''''' + CONVERT(VARCHAR(50), DATEADD(MINUTE, -3, @MaxCurrLogDate), 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(16), @ToLogDate, 121) + '''''
							
							UNION ALL
							SELECT [LogID], [UserID], [LogDate], [CustID], [SubAccID], [ActionID], [TrackingValue], [Duration], [TrackingValue2]
							FROM bodb_CustomerLog.dbo.CS_UserLog_RunSP WITH (NOLOCK)
							WHERE LogID < ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate > ''''' + CONVERT(VARCHAR(50), @MaxCurrLogDate, 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(16), @ToLogDate, 121) + '''''
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				SET IDENTITY_INSERT dbo.CS_UserLog_RunSP ON
				BEGIN TRY
					INSERT INTO dbo.CS_UserLog_RunSP([LogID], [UserID], [LogDate], [CustID], [SubAccID], [ActionID], [TrackingValue], [Duration], [TrackingValue2])
					EXEC sp_executesql @SqlQuery

					IF @@ROWCOUNT = 0 AND @ToLogDate < @CurrentDate
					BEGIN
						SET @MaxCurrLogDate = DATEADD(HOUR, 2, @MaxCurrLogDate)
						GOTO CS_UserLog_RunSP_OneMore
					END

				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.CS_UserLog_RunSP WITH(ROWLOCK)
					WHERE LogID > @MaxCurrLogId AND LogDate >= @MaxCurrLogDate
				
					--retry
					INSERT INTO dbo.CS_UserLog_RunSP([LogID], [UserID], [LogDate], [CustID], [SubAccID], [ActionID], [TrackingValue], [Duration], [TrackingValue2])
					EXEC sp_executesql @SqlQuery

				END CATCH
				SET IDENTITY_INSERT dbo.CS_UserLog_RunSP OFF
			END
		END
	END

	BEGIN --CS_UserLog_RunSP_LogTarget
		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate
		SELECT @MaxCurrLogId = MAX(LogID), @MaxCurrLogDate = MAX(LogDate)
		FROM dbo.CS_UserLog_RunSP_LogTarget WITH (NOLOCK)
		WHERE LogDate > @LastWeek

		IF @MaxCurrLogId = 0 OR @MaxCurrLogDate IS NULL
		BEGIN
			PRINT 'Some things wrong for [CS_UserLog_RunSP_LogTarget]. Please check!!!'
			--SELECT @MaxCurrLogId = 0, @MaxCurrLogDate = @LastWeek
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [CS_UserLog_RunSP_LogTarget]. Please check!!!'
		END
		ELSE
		BEGIN
			CS_UserLog_RunSP_LogTarget_OneMore:
			IF @MaxCurrLogDate < DATEADD(HOUR, -2, @CurrentDate)
				SET @ToLogDate = DATEADD(HOUR, 2, @MaxCurrLogDate)
			ELSE
				SET @ToLogDate = @CurrentDate

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''
							SELECT [LogID], [CustID], [LogDate]
							FROM bodb_CustomerLog.dbo.CS_UserLog_RunSP_LogTarget WITH (NOLOCK)
							WHERE LogID > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate >= ''''' + CONVERT(VARCHAR(50), DATEADD(MINUTE, -3, @MaxCurrLogDate), 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(16), @ToLogDate, 121) + '''''
							
							UNION ALL
							SELECT [LogID], [CustID], [LogDate]
							FROM bodb_CustomerLog.dbo.CS_UserLog_RunSP_LogTarget WITH (NOLOCK)
							WHERE LogID < ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate > ''''' + CONVERT(VARCHAR(50), @MaxCurrLogDate, 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(16), @ToLogDate, 121) + '''''
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				BEGIN TRY
					INSERT INTO dbo.CS_UserLog_RunSP_LogTarget([LogID], [CustID], [LogDate])
					EXEC sp_executesql @SqlQuery

					IF @@ROWCOUNT = 0 AND @ToLogDate < @CurrentDate
					BEGIN
						SET @MaxCurrLogDate = DATEADD(HOUR, 2, @MaxCurrLogDate)
						GOTO CS_UserLog_RunSP_LogTarget_OneMore
					END

				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.CS_UserLog_RunSP_LogTarget WITH(ROWLOCK)
					WHERE LogID > @MaxCurrLogId AND LogDate >= @MaxCurrLogDate
				
					--retry
					INSERT INTO dbo.CS_UserLog_RunSP_LogTarget([LogID], [CustID], [LogDate])
					EXEC sp_executesql @SqlQuery

				END CATCH
			END
		END
	END

	BEGIN --CS_UserLog_RunSP_MultiTarget
		SELECT @SqlQuery = '', @MaxCurrLogId = 0, @MaxCurrLogDate = NULL, @ToLogDate = @CurrentDate
		SELECT @MaxCurrLogId = MAX(LogID), @MaxCurrLogDate = MAX(LogDate)
		FROM dbo.CS_UserLog_RunSP_MultiTarget WITH (NOLOCK)
		WHERE LogDate > @LastWeek

		IF @MaxCurrLogId = 0 OR @MaxCurrLogDate IS NULL
		BEGIN
			PRINT 'Some things wrong for [CS_UserLog_RunSP_MultiTarget]. Please check!!!'
			--SELECT @MaxCurrLogId = 0, @MaxCurrLogDate = @LastWeek
		END
		ELSE IF @MaxCurrLogDate > @ToLogDate
		BEGIN
			PRINT '@MaxCurrLogDate > @ToLogDate for [CS_UserLog_RunSP_MultiTarget]. Please check!!!'
		END
		ELSE
		BEGIN
			CS_UserLog_RunSP_MultiTarget_OneMore:
			IF @MaxCurrLogDate < DATEADD(HOUR, -2, @CurrentDate)
				SET @ToLogDate = DATEADD(HOUR, 2, @MaxCurrLogDate)
			ELSE
				SET @ToLogDate = @CurrentDate

			SET @SqlQuery = 'SELECT *
							FROM OPENQUERY(DBLOG, ''
							SELECT [LogID], [UserID], [LogDate], [ActionID], [TrackingValue], [Duration], [TrackingValue2], [MainLogID]
							FROM bodb_CustomerLog.dbo.CS_UserLog_RunSP_MultiTarget WITH (NOLOCK)
							WHERE LogID > ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate >= ''''' + CONVERT(VARCHAR(50), DATEADD(MINUTE, -3, @MaxCurrLogDate), 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(16), @ToLogDate, 121) + '''''
							
							UNION ALL
							SELECT [LogID], [UserID], [LogDate], [ActionID], [TrackingValue], [Duration], [TrackingValue2], [MainLogID]
							FROM bodb_CustomerLog.dbo.CS_UserLog_RunSP_MultiTarget WITH (NOLOCK)
							WHERE LogID < ''''' + CAST(@MaxCurrLogId AS VARCHAR(50)) + ''''' AND LogDate > ''''' + CONVERT(VARCHAR(50), @MaxCurrLogDate, 121) + '''''
								AND LogDate < ''''' + CONVERT(VARCHAR(16), @ToLogDate, 121) + '''''
							OPTION (MAXDOP 8)'')'

			IF @IsDebug = 1
				PRINT @SqlQuery
			ELSE
			BEGIN
				SET IDENTITY_INSERT dbo.CS_UserLog_RunSP_MultiTarget ON
				BEGIN TRY
					INSERT INTO dbo.CS_UserLog_RunSP_MultiTarget([LogID], [UserID], [LogDate], [ActionID], [TrackingValue], [Duration], [TrackingValue2], [MainLogID])
					EXEC sp_executesql @SqlQuery

					IF @@ROWCOUNT = 0 AND @ToLogDate < @CurrentDate
					BEGIN
						SET @MaxCurrLogDate = DATEADD(HOUR, 2, @MaxCurrLogDate)
						GOTO CS_UserLog_RunSP_MultiTarget_OneMore
					END

				END TRY
				BEGIN CATCH
					--manual rollback
					DELETE dbo.CS_UserLog_RunSP_MultiTarget WITH(ROWLOCK)
					WHERE LogID > @MaxCurrLogId AND LogDate >= @MaxCurrLogDate
				
					--retry
					INSERT INTO dbo.CS_UserLog_RunSP_MultiTarget([LogID], [UserID], [LogDate], [ActionID], [TrackingValue], [Duration], [TrackingValue2], [MainLogID])
					EXEC sp_executesql @SqlQuery

				END CATCH
				SET IDENTITY_INSERT dbo.CS_UserLog_RunSP_MultiTarget OFF
			END
		END
	END

END
