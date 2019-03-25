/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="" viewers="" isFunction="0" isNested="0"></info>*/
USE bodb_CustomerLog
GO

ALTER PROCEDURE [dbo].[Task_Archive_CustomerLog_UserLog_ExternalAPI]
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

		INSERT INTO dbo.Task_ArchiveData_Transition(LogId, Logdate)
		SELECT logid, logdate
		FROM dbo.UserLog_ExternalAPI WITH(NOLOCK)
		WHERE logdate >= @FromDateTime AND logdate < @ToDateTime

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
		SELECT logid, logdate INTO #__logIds
		FROM dbo.UserLog_ExternalAPI WITH(NOLOCK)
		WHERE logdate >= @FromDateTime AND logdate < @ToDateTime

		DECLARE @__tmpId TABLE(logId BIGINT, logdate DATETIME)

		WHILE 1 = 1
		BEGIN
			DELETE FROM @__tmpId

			DELETE TOP(@RowInBatch) 
			FROM #__logIds OUTPUT deleted.logid, deleted.logdate INTO @__tmpId(logId, logdate)
			
			IF @@ROWCOUNT = 0
				BREAK

			DELETE TOP(@RowInBatch) l
			FROM dbo.UserLog_ExternalAPI l WITH(ROWLOCK)
			WHERE EXISTS (SELECT TOP 1 1 FROM @__tmpId t WHERE l.logid = t.logId AND l.logdate = t.logdate)

		END

		DROP TABLE #__logIds
	END
END
GO
