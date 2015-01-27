USE [LASDB]
GO

/****** Object:  StoredProcedure [dbo].[Task_Las_ClearLogin]    Script Date: 01/27/2015 04:05:35 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/****** Object:  Stored Procedure dbo.Lrf_CheckIn    Script Date: 6/15/2011 3:52:40 PM ******/
CREATE PROCEDURE [dbo].[Task_Las_ClearLogin] 
	
AS

/*
	Created:  20131224
	Task: Clear Login
	DB: DBLas.LasDB
	Original SP:
	
	Revisions:
		
*/
SET NOCOUNT ON
DELETE FROM On_User with (updlock)
WHERE        
reload_time < dateadd(minute,-30,CURRENT_TIMESTAMP) 

DELETE FROM On_Admin with (updlock)
WHERE        
reload_time < dateadd(minute,-30,CURRENT_TIMESTAMP) 

GO


