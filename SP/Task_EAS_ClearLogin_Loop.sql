USE [bodb_EAS]
GO

/****** Object:  StoredProcedure [dbo].[Task_EAS_ClearLogin_Loop]    Script Date: 01/19/2015 02:46:00 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/****** Object:  Stored Procedure dbo.Lrf_CheckIn    Script Date: 6/15/2011 3:52:40 PM ******/
CREATE PROCEDURE [dbo].[Task_EAS_ClearLogin_Loop]   
AS  
/*
	Created:  20131324
	Task: Clear Login
	DB: DBEAS/bodb_EAS
	Original SP:
	
	Revisions:
		
*/
BEGIN
	SET NOCOUNT ON
	
	Declare @start datetime  
	SELECT @start = CURRENT_TIMESTAMP  

	WHILE (1=1) AND (DATEDIFF(minute,@start, CURRENT_TIMESTAMP) < 20)  
	BEGIN  
		EXEC [Task_EAS_ClearLogin]  
		WAITFOR DELAY '00:00:30'  
	END
END

GO

GRANT VIEW DEFINITION ON [dbo].[Task_EAS_ClearLogin_Loop] TO [vnteam] AS [dbo]
GO


