/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Archive_CustomerLog_CS_UserLog_RunSP_LogTarget]
	@FromDateTime DATETIME,
	@ToDateTime DATETIME,
	@Mode VARCHAR(20) = 'copy',
	@RowInBatch INT = 2000,
	@ErrorCode INT = 0 OUTPUT
AS
/*
	Created: 20190620@Elodie
	Task : Implement archiving data for customer log
	DB: DBLog.bodb_CustomerLog
	Original: Task_Archive_CustomerLog_UserLog_RunSP

	Revisions: 
		- 20190620@Elodie: Apply new structure for CN88's log [Redmine: #113198]
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @__dateFrom DATETIME, @__dateTo DATETIME
	DECLARE @rowId INT = 1, @delayTimeValue VARCHAR(50)

	SELECT @__dateFrom = @FromDateTime, @__dateTo = @ToDateTime, @delayTimeValue = '00:00:00:100', @ErrorCode = 1
	SELECT @delayTimeValue = dbo.f_Archive_CustomerLog_GetDelayTime('Key1')
	
	IF @Mode = 'copy'
	BEGIN
		IF EXISTS (
			SELECT TOP 1 1
			FROM dbo.Task_ArchiveData_Transition WITH(NOLOCK)
		)
		BEGIN
			IF EXISTS (
				SELECT TOP 1 1
				FROM dbo.Task_ArchiveData_Transition WITH(NOLOCK)
				WHERE TableName <> 'CS_UserLog_RunSP_LogTarget'
			)
			BEGIN
				RAISERROR('^^^ Can not resume the job. Please check!!!^^^', 16, 1)
				RETURN
			END
			
			--resume case
			SELECT @rowId = MIN(RowId) FROM dbo.Task_ArchiveData_Transition WITH(NOLOCK)
			WHILE 1 = 1
			BEGIN
		
				DELETE
				FROM dbo.Task_ArchiveData_Transition WITH(ROWLOCK)
				WHERE rowId >= @rowId AND rowId < @rowId + @RowInBatch
			
				IF @@ROWCOUNT = 0
					BREAK

				SET @rowId = @rowId + @RowInBatch
				WAITFOR DELAY @delayTimeValue
			END
		END
		ELSE
		BEGIN
		
			--reset identity purpose
			TRUNCATE TABLE Task_ArchiveData_Transition

			INSERT INTO dbo.Task_ArchiveData_Transition(LogId, Logdate, custid, TableName)
			SELECT lt.logid, lt.LogDate, lt.CustID, 'CS_UserLog_RunSP_LogTarget' AS TableName
			FROM dbo.CS_UserLog_RunSP_LogTarget lt WITH(NOLOCK)
			WHERE lt.logdate >= @__dateFrom AND lt.logdate < @__dateTo		

			SET @rowId = 1
			WHILE 1 = 1
			BEGIN
		
				DELETE
				FROM dbo.Task_ArchiveData_Transition WITH(ROWLOCK)
				WHERE rowId >= @rowId AND rowId < @rowId + @RowInBatch
			
				IF @@ROWCOUNT = 0
					BREAK

				SET @rowId = @rowId + @RowInBatch
				WAITFOR DELAY @delayTimeValue
			END			
		END
	END
	ELSE IF @Mode = 'delete'
	BEGIN
		CREATE TABLE #__logIds (rowId INT IDENTITY(1,1) PRIMARY KEY, logid BIGINT, logdate DATETIME)
		
		INSERT INTO #__logIds(logid, logdate)
		SELECT logid, logdate
		FROM dbo.CS_UserLog_RunSP_LogTarget WITH(NOLOCK)
		WHERE logdate >= @__dateFrom AND logdate < @__dateTo

		DECLARE @__tmpId TABLE(logId BIGINT, logdate DATETIME, custid INT)
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
			FROM dbo.CS_UserLog_RunSP_LogTarget l WITH(ROWLOCK)
			WHERE EXISTS (SELECT TOP 1 1 FROM @__tmpId t WHERE l.logid = t.logId AND l.CustID = t.custid)

			WAITFOR DELAY @delayTimeValue

		END

		DROP TABLE #__logIds
	END

	--//complete without error
	SET @ErrorCode = 0
END
GO
