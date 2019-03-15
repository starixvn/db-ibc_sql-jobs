/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="" viewers="" isFunction="0" isNested="0"></info>*/
USE bodb_CustomerLog
GO

ALTER PROCEDURE [dbo].[Task_Archive_CustomerLog_UserLog_Transaction]
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
			FROM bodb_CustomerLog_Archive.dbo.UserLog_Transaction WITH(NOLOCK)
			WHERE logdate >= @FromDateTime AND logdate < @ToDateTime
		)
		BEGIN
			--//for case resume data
			WHILE 1 = 1
			BEGIN
				DELETE TOP(@RowInBatch)
				FROM bodb_CustomerLog_Archive.dbo.UserLog_Transaction WITH(ROWLOCK)
				WHERE logdate >= @FromDateTime AND logdate < @ToDateTime

				IF @@ROWCOUNT = 0
					BREAK
			END
		END

		SELECT logid INTO #__logIds 
		FROM dbo.UserLog_Transaction WITH(NOLOCK)
		WHERE logdate >= @FromDateTime AND logdate < @ToDateTime

		DECLARE @__tmpId TABLE(logId BIGINT)

		WHILE 1 = 1
		BEGIN
			DELETE FROM @__tmpId

			DELETE TOP(@RowInBatch) 
			FROM #__logIds OUTPUT deleted.logid INTO @__tmpId(logId)
			
			IF @@ROWCOUNT = 0
				BREAK

			INSERT INTO bodb_CustomerLog_Archive.dbo.UserLog_Transaction([LogID], [LogDate], [ActionID], [Refno], [UserID], [IP], [Doing])
			SELECT [LogID], [LogDate], [ActionID], [Refno], [UserID], [IP], [Doing]
			FROM dbo.UserLog_Transaction l WITH(NOLOCK)
			WHERE EXISTS (SELECT TOP 1 1 FROM @__tmpId t WHERE l.logid = t.logId)
				AND logdate >= @FromDateTime AND logdate < @ToDateTime

		END

		DROP TABLE #__logIds

	END
	ELSE IF @Mode = 'delete'
	BEGIN
		SELECT logid INTO #__logIds2
		FROM dbo.UserLog_Transaction WITH(NOLOCK)
		WHERE logdate >= @FromDateTime AND logdate < @ToDateTime

		DECLARE @__tmpId2 TABLE(logId BIGINT)

		WHILE 1 = 1
		BEGIN
			DELETE FROM @__tmpId2

			DELETE TOP(@RowInBatch) 
			FROM #__logIds2 OUTPUT deleted.logid INTO @__tmpId2(logId)
			
			IF @@ROWCOUNT = 0
				BREAK

			DELETE TOP(@RowInBatch) l
			FROM dbo.UserLog_Transaction l WITH(ROWLOCK)
			WHERE EXISTS (SELECT TOP 1 1 FROM @__tmpId2 t WHERE l.logid = t.logId)
				AND logdate >= @FromDateTime AND logdate < @ToDateTime

		END

		DROP TABLE #__logIds2
	END
END
GO
