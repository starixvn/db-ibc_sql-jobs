USE [LASDB]
GO

/****** Object:  StoredProcedure [dbo].[Task_LicenseeAgentSettlement_Loop]    Script Date: 01/20/2015 03:34:07 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.Task_LicenseeAgentSettlement_Loop    Script Date: 2/28/2014 9:51:06 AM ******/

CREATE PROCEDURE [dbo].[Task_LicenseeAgentSettlement_Loop]
AS
/*
Created		: 20140122@Don
Task		: Control settlement loop
DB			: DBLAS.lasdb
	
Revisions:

*/
BEGIN
	SET NOCOUNT ON

	DECLARE @start DATETIME
	SELECT @start = CURRENT_TIMESTAMP

	WHILE (1=1) AND (DATEDIFF(minute,@start, CURRENT_TIMESTAMP) < 30)
	BEGIN
				EXEC dbo.Task_LicenseeAgentSettlement
		WAITFOR DELAY '00:00:01'
	END
END
GO

GRANT VIEW DEFINITION ON [dbo].[Task_LicenseeAgentSettlement_Loop] TO [vnteam] AS [dbo]
GO


