USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Task_ExternalSettlement_Loop]    Script Date: 01/19/2015 05:46:53 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_ExternalSettlement_Loop]
AS
/*
	Created by:Lukas
	Date:20110112
	Task: execute Settlement (job)
	DB: DBO2.BODB02
	
	Revisions:
	
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @start DATETIME
	SELECT @start = CURRENT_TIMESTAMP

	WHILE (1=1) AND (DATEDIFF(minute,@start, CURRENT_TIMESTAMP) < 30)
	BEGIN
		EXEC [Task_ExternalSettlement]
		WAITFOR DELAY '00:00:01'
	END
END

GO

GRANT VIEW DEFINITION ON [dbo].[Task_ExternalSettlement_Loop] TO [vnteam] AS [dbo]
GO


