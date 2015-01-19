USE [bodb_RMS]
GO

/****** Object:  StoredProcedure [dbo].[Task_RMS_ClearLogin]    Script Date: 01/19/2015 04:34:52 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_RMS_ClearLogin]
	
AS

/*
	Created:  20120704@Jamie
	Task: RMS - Clear Login
	DB: DB054.bodb_RMS 
	Original SP:
	
	Revisions:
		
*/
SET NOCOUNT ON
DELETE FROM rmOn_User WITH (UPDLOCK,ROWLOCK)
WHERE	reload_time < dateadd(minute,-30,CURRENT_TIMESTAMP) 


GO

GRANT VIEW DEFINITION ON [dbo].[Task_RMS_ClearLogin] TO [vnteam] AS [dbo]
GO


