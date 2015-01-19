USE [bodb_OddsFeed]
GO

/****** Object:  StoredProcedure [dbo].[Task_Odds_ClearLogin]    Script Date: 01/19/2015 04:14:25 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


Create Procedure [dbo].[Task_Odds_ClearLogin]
	
AS

/*
	Created:  20110221@Peter
	Task: Clear Login
	DB: DB054.bodb_oddsfeed
	Original SP:
	
	Revisions:
		
*/
SET NOCOUNT ON
DELETE FROM On_User with (updlock)
WHERE        
ReloadTime is null or ReloadTime < dateadd(minute,-5,CURRENT_TIMESTAMP)



GO


