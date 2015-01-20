USE [bodb_Licensee]
GO

/****** Object:  StoredProcedure [dbo].[Task_Licensee_ClearLogin]    Script Date: 01/19/2015 06:39:03 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_Licensee_ClearLogin]
	
AS

/*
	Created:  20101209@Henry
	Task: Clear Login
	DB: DB052.bodb_Licensee
	Original SP:
	
	Revisions:
		
*/
SET NOCOUNT ON
DELETE FROM On_User with (updlock)
WHERE        
reload_time < dateadd(minute,-30,CURRENT_TIMESTAMP) AND (ServerID IN (200,201))


GO


