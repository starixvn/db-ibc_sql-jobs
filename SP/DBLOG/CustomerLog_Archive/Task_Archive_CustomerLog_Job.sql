/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="" viewers="" isFunction="0" isNested="0"></info>*/
USE bodb_CustomerLog
GO

ALTER PROCEDURE [dbo].[Task_Archive_CustomerLog_Job]
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

	DECLARE @tableName VARCHAR(200), @archiveDate DATETIME
	DECLARE @__dateTimeFrom DATETIME, @__dateTimeTo DATETIME

	SELECT TOP (1) @tableName = TableName, @archiveDate = ArchiveDate
	FROM dbo.Task_ArchiveData_List_Processing WITH(NOLOCK)
	ORDER BY ArchiveDate

	IF @@ROWCOUNT = 0
	BEGIN
		PRINT 'job done!!!'
		RAISERROR('* no more data *', 16, 1)
	END

	SELECT @__dateTimeFrom = CAST(@archiveDate AS DATE)
		, @__dateTimeTo = DATEADD(DAY, 1, CAST(@archiveDate AS DATE))

	IF @tableName = 'UserLog_RunSP'
	BEGIN
		EXEC dbo.Task_Archive_CustomerLog_UserLog_RunSP
				@FromDateTime = @__dateTimeFrom,
				@ToDateTime = @__dateTimeTo,
				@Mode = @Mode,
				@RowInBatch = @RowInBatch
	END
	ELSE IF @tableName = 'UserLog_Login'
	BEGIN
		EXEC dbo.Task_Archive_CustomerLog_UserLog_Login
				@FromDateTime = @__dateTimeFrom,
				@ToDateTime = @__dateTimeTo,
				@Mode = @Mode,
				@RowInBatch = @RowInBatch
	END	
	ELSE IF @tableName = 'UserLog_Settle'
	BEGIN
		EXEC dbo.Task_Archive_CustomerLog_UserLog_Settle
				@FromDateTime = @__dateTimeFrom,
				@ToDateTime = @__dateTimeTo,
				@Mode = @Mode,
				@RowInBatch = @RowInBatch
	END	
	ELSE IF @tableName = 'UserLog_Transaction'
	BEGIN
		EXEC dbo.Task_Archive_CustomerLog_UserLog_Transaction
				@FromDateTime = @__dateTimeFrom,
				@ToDateTime = @__dateTimeTo,
				@Mode = @Mode,
				@RowInBatch = @RowInBatch
	END	
	ELSE IF @tableName = 'UserLog_Transfer'
	BEGIN
		EXEC dbo.Task_Archive_CustomerLog_UserLog_Transfer
				@FromDateTime = @__dateTimeFrom,
				@ToDateTime = @__dateTimeTo,
				@Mode = @Mode,
				@RowInBatch = @RowInBatch
	END	
	ELSE IF @tableName = 'UserLog_CasinoAPI'
	BEGIN
		EXEC dbo.Task_Archive_CustomerLog_UserLog_CasinoAPI
				@FromDateTime = @__dateTimeFrom,
				@ToDateTime = @__dateTimeTo,
				@Mode = @Mode,
				@RowInBatch = @RowInBatch
	END	
	ELSE IF @tableName = 'UserLog_Credit'
	BEGIN
		EXEC dbo.Task_Archive_CustomerLog_UserLog_Credit
				@FromDateTime = @__dateTimeFrom,
				@ToDateTime = @__dateTimeTo,
				@Mode = @Mode,
				@RowInBatch = @RowInBatch
	END	
	ELSE IF @tableName = 'UserLog_Dep_CustSetting'
	BEGIN
		EXEC dbo.Task_Archive_CustomerLog_UserLog_Dep_CustSetting
				@FromDateTime = @__dateTimeFrom,
				@ToDateTime = @__dateTimeTo,
				@Mode = @Mode,
				@RowInBatch = @RowInBatch
	END	
	ELSE IF @tableName = 'UserLog_ExternalAPI'
	BEGIN
		EXEC dbo.Task_Archive_CustomerLog_UserLog_ExternalAPI
				@FromDateTime = @__dateTimeFrom,
				@ToDateTime = @__dateTimeTo,
				@Mode = @Mode,
				@RowInBatch = @RowInBatch
	END	
	ELSE
	BEGIN
		PRINT @tableName
		RAISERROR('^^^Does not support^^^', 16, 1)
	END
	--//remove when it done
	DELETE 
	FROM dbo.Task_ArchiveData_List_Processing WITH(ROWLOCK)
	WHERE TableName = @tableName AND ArchiveDate = @archiveDate
END
GO
