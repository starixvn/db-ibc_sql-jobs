USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Task_DB06_Userlog_P_CleanUp]    Script Date: 01/21/2015 02:08:50 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_DB06_Userlog_P_CleanUp]
AS
BEGIN
	SET NOCOUNT ON
	Declare @StartTime datetime
	SET @StartTime = CURRENT_TIMESTAMP

	Declare @tmpdate nvarchar(50)
	SET @tmpdate = CONVERT(nvarchar(10), DATEADD(day, -10, CURRENT_TIMESTAMP), 120)

	------------ delete new table -----------
	-- search the last LogID to delete
	Declare @MaxID bigint, @MinID bigint, @LogID bigint
	Declare @RC int

	SELECT @MaxID = isnull(MAX(logid),0)
	FROM dbo.userlog_P WITH (nolock, INDEX = IX_logdate)
	WHERE logdate BETWEEN DATEADD(minute, -10, @tmpdate) AND @tmpdate

	SELECT TOP 1 @MinID = logid
	FROM dbo.userlog_P with (nolock)
	WHERE logid < @MaxID
	ORDER BY logid

	SET @LogID = @MinID
	SET @RC = 0

	WHILE @LogID <= @MaxID
	BEGIN
		DELETE dbo.userlog_P
		FROM dbo.userlog_P WITH (ROWLOCK, INDEX = PK_userlog_P)
		WHERE LogID = @LogID

		SET @LogID = @LogID + 1
		SET @RC = @RC + 1
	END

	Declare @TimeTaken int
	SET @TimeTaken = DATEDIFF(second, @StartTime, CURRENT_TIMESTAMP)

	PRINT 'Deleted USERLOG_P: ' + CAST(@RC as varchar(20)) + ' rows in ' + CAST(@TimeTaken as varchar(20)) + ' seconds'
END
GO


