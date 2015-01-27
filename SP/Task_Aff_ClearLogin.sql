USE [Affiliate_12BET]
GO

/****** Object:  StoredProcedure [dbo].[Task_Aff_ClearLogin]    Script Date: 01/27/2015 00:17:04 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.Task_Aff_ClearLogin    Script Date: 6/14/2011 10:18:14 AM ******/
CREATE PROCEDURE [dbo].[Task_Aff_ClearLogin]
	
AS

/*
	Created:  20110221@Johnny
	Task: Clear Login
	DB: DB052.Affiliate_12BET
	Original SP:
	
	Revisions:
		
*/
SET NOCOUNT ON
DELETE FROM On_User with (updlock)
WHERE        
reload_time < dateadd(minute,-30,CURRENT_TIMESTAMP)
GO

GRANT VIEW DEFINITION ON [dbo].[Task_Aff_ClearLogin] TO [vnAffiliate] AS [dbo]
GO


