USE [LASDB]
GO

/****** Object:  StoredProcedure [dbo].[Task_LicenseeAgentSettlement]    Script Date: 01/27/2015 04:08:16 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[Task_LicenseeAgentSettlement]
AS
/*
Created		: 20140113@Don
Task		: Executing settlement command
DB			: DBLAS.lasdb
	
	Revisions:

	Param explanation:				
		StatusID & Status
			+ 0		Waiting	
			+ 1		Running
			+ 2		Failed & retry 1
			+ 3		Failed & retry 2
			+ 4		Failed & retry 3
				
			+ 98	Failed & waiting for notification
			+ 99	Failed & notified
			+ 100	Completed (successful)
*/
SET NOCOUNT ON

DECLARE @sql			NVARCHAR(4000),
		@execID			INT,
		@startTime		DATETIME,
		@endTime		DATETIME,
		@allowedDate	DATETIME,
		@statusID		INT,
		@matchID		INT,
		@bettype		INT,
		@betCount		INT,
		@betCount_DB	INT,
		@errMesg		VARCHAR(1000)

SELECT TOP 1	
		@sql			= SQLCommand 
		,@execID		= execID 
		,@statusID		= statusID
		,@matchID		= MatchID
		,@bettype		= Bettype
		,@betCount		= BetCount 
		,@allowedDate	= AllowedDate
FROM	dbo.LicenseeAgentSettlement WITH(NOLOCK)
WHERE	StatusID < 100
ORDER BY execID ASC

IF (@sql IS NULL)
BEGIN
	UPDATE dbo.LicenseeAgentSettlement WITH(ROWLOCK, UPDLOCK)
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


-- Check if conditions for command are satisfied to execute
IF ((@allowedDate IS NOT NULL) AND (@allowedDate > GETDATE()))
BEGIN
	RETURN
END

/* Execute settlement command */
UPDATE dbo.LicenseeAgentSettlement WITH(ROWLOCK, UPDLOCK)
SET StatusID		= 1
	,ExecutedDate	= GETDATE()
	,Status			= 'Running'
WHERE execID = @execID

BEGIN TRY
	EXEC sp_executesql @sql

	IF @@ERROR = 0
	BEGIN
		UPDATE dbo.LicenseeAgentSettlement WITH(ROWLOCK, UPDLOCK)
		SET StatusID	= 100
			,Duration	= DATEDIFF(ms, ExecutedDate, GETDATE())
			,Status		= 'Completed'
		WHERE 
			execID = @execID
	END
END TRY

BEGIN CATCH
	SELECT @errMesg = ERROR_MESSAGE()
	
	UPDATE dbo.LicenseeAgentSettlement WITH(ROWLOCK, UPDLOCK)
	SET	StatusID		=	CASE 
								WHEN @statusID = 0 THEN 2	-- Failed & retry 1
								WHEN @statusID = 2 THEN 3	-- Failed & retry 2
								WHEN @statusID = 3 THEN 4	-- Failed & retry 3
								ELSE 98						-- Failed & waiting for notification
							END
		,Duration		=	DATEDIFF(ms, ExecutedDate, GETDATE())
		,Status			=	CASE 
								WHEN @statusID = 0 THEN 'Failed & retry 1'	-- put to retry 1
								WHEN @statusID = 2 THEN 'Failed & retry 2'	-- put to retry 2
								WHEN @statusID = 3 THEN 'Failed & retry 3'	-- put to retry 3						
								ELSE 'Failed & waiting for notification' 
							END
		,AllowedDate	=	CASE 
								WHEN @statusID = 0 THEN DATEADD(MINUTE,1,GETDATE())
								WHEN @statusID = 2 THEN DATEADD(MINUTE,3,GETDATE())
								WHEN @statusID = 3 THEN DATEADD(MINUTE,5,GETDATE())
								ELSE AllowedDate 
							END
		,Note			=	SUBSTRING(@errMesg, 1, 500)
	WHERE 
		execID = @execID
END CATCH


GO

GRANT VIEW DEFINITION ON [dbo].[Task_LicenseeAgentSettlement] TO [vnteam] AS [dbo]
GO


