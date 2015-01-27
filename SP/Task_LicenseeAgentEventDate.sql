USE [LASDB]
GO

/****** Object:  StoredProcedure [dbo].[Task_LicenseeAgentEventDate]    Script Date: 01/27/2015 04:06:44 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Task_LicenseeAgentEventDate]
AS
/*
Created		: 20140326@Don
Task		: Executing changing event date command
DB			: DBLAS.lasdb
	
	Revisions:

	Param explanation:				
		StatusID & Status
			+ 0		Waiting	
			+ 1		Running
				
			+ 98	Failed & waiting for notification
			+ 99	Failed & notified
			+ 100	Completed (successful)
*/
SET NOCOUNT ON

DECLARE @sql			NVARCHAR(4000),
		@execID			INT,
		@startTime		DATETIME,
		@endTime		DATETIME,
		@statusID		INT,
		@matchID		INT,
		@errMesg		VARCHAR(1000)

SELECT TOP 1	
		@sql			= SQLCommand 
		,@execID		= execID 
		,@statusID		= statusID
		,@matchID		= MatchID
FROM	dbo.LicenseeAgentEventDate WITH(NOLOCK)
WHERE	StatusID < 100
ORDER BY execID ASC

IF @sql IS NULL
BEGIN
	UPDATE dbo.LicenseeAgentEventDate WITH(ROWLOCK, UPDLOCK)
	SET StatusID	= 100
		,Status		= 'Completed'
		,Note		= 'SQL Command IS NULL'
	WHERE 
		execID = @execID

	RETURN 
END

/*
	Make sure that there is one command in running
	Make sure that there is no [Failed & waiting for notification] or [Failed & notified] command
*/
IF (@statusID IN (1, 98, 99))
	RETURN

/* Execute settlement command */
UPDATE dbo.LicenseeAgentEventDate WITH(ROWLOCK, UPDLOCK)
SET StatusID		= 1
	,ExecutedDate	= GETDATE()
	,Status			= 'Running'
WHERE execID = @execID

BEGIN TRY
	EXEC sp_executesql @sql

	IF @@ERROR = 0
	BEGIN
		UPDATE dbo.LicenseeAgentEventDate WITH(ROWLOCK, UPDLOCK)
		SET StatusID	= 100
			,Duration	= DATEDIFF(ms, ExecutedDate, GETDATE())
			,Status		= 'Completed'
		WHERE 
			execID = @execID
	END
END TRY

BEGIN CATCH
	SELECT @errMesg = ERROR_MESSAGE()
	
	UPDATE dbo.LicenseeAgentEventDate WITH(ROWLOCK, UPDLOCK)
	SET	StatusID		= 98
		,Duration		= DATEDIFF(ms, ExecutedDate, GETDATE())
		,Status			= 'Failed & waiting for notification'
		,Note			= SUBSTRING(@errMesg, 1, 500)
	WHERE 
		execID = @execID
END CATCH




GO

GRANT VIEW DEFINITION ON [dbo].[Task_LicenseeAgentEventDate] TO [vnteam] AS [dbo]
GO


