/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="" viewers="" isFunction="0" isNested="0"></info>*/
USE bodb_CustomerLog
GO

ALTER PROCEDURE [dbo].[Task_Archive_CustomerLog_UserLog_Login]
	@FromDateTime DATETIME,
	@ToDateTime DATETIME,
	@Mode VARCHAR(20) = 'copy',
	@RowInBatch INT = 2000
AS
/*
	Created: 20190227@Patrick
	Task : Implement archiving data for customer log
	DB: DBLog.bodb_CustomerLog

	Revisions: 
		- 20190227@Patrick: Initalize [RedmineId: #110208] 	
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @__dateFrom DATETIME, @__dateTo DATETIME
	SELECT @__dateFrom = @FromDateTime, @__dateTo = @ToDateTime
	
	IF @Mode = 'copy'
	BEGIN
		IF EXISTS (
			SELECT TOP 1 1
			FROM dbo.Task_ArchiveData_Transition WITH(NOLOCK)
		)
		BEGIN
			RAISERROR('^^^Having data on table [Task_ArchiveData_Transition]. Please check!!!^^^', 16, 1)
			RETURN
		END

		INSERT INTO dbo.Task_ArchiveData_Transition(LogId, Logdate, custid)
		SELECT logid, logdate, UserID
		FROM dbo.UserLog_Login WITH(NOLOCK)
		WHERE logdate >= @__dateFrom AND logdate < @__dateTo

		WHILE 1 = 1
		BEGIN
		
			DELETE TOP(@RowInBatch)
			FROM dbo.Task_ArchiveData_Transition WITH(ROWLOCK)
			
			IF @@ROWCOUNT = 0
				BREAK
		END

	END
	ELSE IF @Mode = 'delete'
	BEGIN
		
		CREATE TABLE #__logIds (rowId INT IDENTITY(1,1) PRIMARY KEY, logid BIGINT, logdate DATETIME, userId INT)
		
		INSERT INTO #__logIds(logid, logdate, userId)
		SELECT logid, logdate, UserID
		FROM dbo.UserLog_Login WITH(NOLOCK)
		WHERE logdate >= @__dateFrom AND logdate < @__dateTo

		DECLARE @__tmpId TABLE(logId BIGINT, logdate DATETIME, userId INT)
		DECLARE @rowId INT = 1

		WHILE 1 = 1
		BEGIN
			DELETE FROM @__tmpId

			DELETE 
			FROM #__logIds OUTPUT deleted.logid, deleted.logdate, deleted.userId INTO @__tmpId(logId, logdate, userId)
			WHERE rowId >= @rowId AND rowId < @rowId + @RowInBatch
			
			IF @@ROWCOUNT = 0
				BREAK

			SET @rowId = @rowId + @RowInBatch

			DELETE l
			FROM dbo.UserLog_Login l WITH(ROWLOCK)
			WHERE EXISTS (SELECT TOP 1 1 FROM @__tmpId t WHERE l.logid = t.logId AND l.logdate = t.logdate AND l.UserID = t.userId)

		END

		DROP TABLE #__logIds
	END
END
GO
