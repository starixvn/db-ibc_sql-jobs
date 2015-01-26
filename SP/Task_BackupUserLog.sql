USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Task_BackupUserLog]    Script Date: 01/26/2015 05:13:29 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_BackupUserLog]
	@Mode int = 0
AS

IF @Mode NOT IN (1,2,3) Return
-- @Mode
-- 1 = get scope/record into (create) table
-- 2 = select
-- 3 = delete

SET NOCOUNT ON

Declare @tmpdate datetime, @maxLogID bigint
SET @tmpdate = CONVERT(nvarchar(10), DATEADD(day, -0, CURRENT_TIMESTAMP), 120)

-- delete new table
IF @Mode = 1
BEGIN
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tmp_backupUserLog]') AND type in (N'U'))
	BEGIN
		CREATE TABLE dbo.tmp_backupUserLog ( LogID bigint PRIMARY KEY )	
	END
	
	SELECT @MaxLogID = isnull(Max(LogID),0)
	FROM dbo.UserLog (nolock)
	WHERE LogDate < @tmpDate
	
	DELETE FROM dbo.tmp_backupUserLog
	INSERT INTO dbo.tmp_backupUserLog (LogID) values (@maxLogID)
END
ELSE IF @Mode = 2
BEGIN
	SELECT @maxLogID = LogID FROM dbo.tmp_backupUserLog
	
	SELECT logid, userid, doing, logdate
	FROM dbo.UserLog with (nolock)
	WHERE LogID <= @MaxLogID
END
ELSE IF @Mode = 3
BEGIN
	SELECT @maxLogID = LogID FROM dbo.tmp_backupUserLog

	DELETE TOP (10000) FROM dbo.UserLog
	WHERE LogID <= @MaxLogID

	IF @@ROWCOUNT = 0
	BEGIN
		DROP TABLE tmp_backupUserLog
		
		-- raiserror here to continue to next step of jobs
		RAISERROR ('* no more data *', -- Message text.
				   16, -- Severity.
				   1 -- State.
				   );
	END			

END

GO

GRANT VIEW DEFINITION ON [dbo].[Task_BackupUserLog] TO [vnteam] AS [dbo]
GO


