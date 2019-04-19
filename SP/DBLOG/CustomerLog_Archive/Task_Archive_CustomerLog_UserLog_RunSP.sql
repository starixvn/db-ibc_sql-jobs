/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="" viewers="" isFunction="0" isNested="0"></info>*/
USE bodb_CustomerLog
GO

ALTER PROCEDURE [dbo].[Task_Archive_CustomerLog_UserLog_RunSP]
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
	DECLARE @rowId INT
	
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

		--reset identity purpose
		TRUNCATE TABLE Task_ArchiveData_Transition

		INSERT INTO dbo.Task_ArchiveData_Transition(LogId, Logdate, custid, TableName)
		SELECT logid, logdate, custid, 'UserLog_RunSP' AS TableName
		FROM dbo.UserLog_RunSP WITH(NOLOCK)
		WHERE logdate >= @__dateFrom AND logdate < @__dateTo

		SET @rowId = 1
		WHILE 1 = 1
		BEGIN
		
			DELETE
			FROM dbo.Task_ArchiveData_Transition WITH(ROWLOCK)
			WHERE rowId >= @rowId AND rowId < @rowId + @RowInBatch
			
			IF @@ROWCOUNT = 0
				BREAK

			SET @rowId = @rowId + @RowInBatch
		END

	END
	ELSE IF @Mode = 'delete'
	BEGIN
		CREATE TABLE #__logIds (rowId INT IDENTITY(1,1) PRIMARY KEY, logid BIGINT, logdate DATETIME, custid INT)
		
		INSERT INTO #__logIds(logid, logdate)
		SELECT logid, logdate
		FROM dbo.UserLog_RunSP WITH(NOLOCK)
		WHERE logdate >= @__dateFrom AND logdate < @__dateTo AND custid IS NULL

		DECLARE @__tmpId TABLE(logId BIGINT, logdate DATETIME, custid INT)
		SET @rowId = 1

		WHILE 1 = 1
		BEGIN
			DELETE FROM @__tmpId

			DELETE 
			FROM #__logIds OUTPUT deleted.logid, deleted.logdate INTO @__tmpId(logId, logdate)
			WHERE rowId >= @rowId AND rowId < @rowId + @RowInBatch
			
			IF @@ROWCOUNT = 0
				BREAK

			SET @rowId = @rowId + @RowInBatch

			DELETE l
			FROM dbo.UserLog_RunSP l WITH(ROWLOCK)
			WHERE EXISTS (SELECT TOP 1 1 FROM @__tmpId t WHERE l.logid = t.logId AND l.logdate = t.logdate AND l.custid IS NULL)

		END

		--for case custid is not null
		TRUNCATE TABLE #__logIds
		INSERT INTO #__logIds(logid, logdate, custid)
		SELECT logid, logdate, custid
		FROM dbo.UserLog_RunSP WITH(NOLOCK)
		WHERE logdate >= @__dateFrom AND logdate < @__dateTo AND custid IS NOT NULL

		SET @rowId = 1
		WHILE 1 = 1
		BEGIN
			DELETE FROM @__tmpId

			DELETE 
			FROM #__logIds OUTPUT deleted.logid, deleted.logdate, deleted.custid INTO @__tmpId(logId, logdate, custid)
			WHERE rowId >= @rowId AND rowId < @rowId + @RowInBatch
			
			IF @@ROWCOUNT = 0
				BREAK

			SET @rowId = @rowId + @RowInBatch

			DELETE l
			FROM dbo.UserLog_RunSP l WITH(ROWLOCK)
			WHERE EXISTS (SELECT TOP 1 1 FROM @__tmpId t WHERE l.logid = t.logId AND l.logdate = t.logdate AND l.custid = t.custid)

		END

		DROP TABLE #__logIds
	END
END
GO
