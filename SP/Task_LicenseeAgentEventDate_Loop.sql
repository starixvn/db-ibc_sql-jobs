USE [LASDB]
GO

/****** Object:  StoredProcedure [dbo].[Task_LicenseeAgentEventDate_Loop]    Script Date: 01/20/2015 03:31:20 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Task_LicenseeAgentEventDate_Loop]
AS
/*
Created		: 20140326@Don
Task		: Control changing event date loop
DB			: DBLAS.lasdb
	
Revisions:

*/
BEGIN
	SET NOCOUNT ON

	DECLARE @start DATETIME
	SELECT @start = CURRENT_TIMESTAMP

	WHILE (1=1) AND (DATEDIFF(minute,@start, CURRENT_TIMESTAMP) < 30)
	BEGIN
		EXEC dbo.Task_LicenseeAgentEventDate 
		WAITFOR DELAY '00:00:01'
	END
END




GO

GRANT VIEW DEFINITION ON [dbo].[Task_LicenseeAgentEventDate_Loop] TO [vnteam] AS [dbo]
GO


