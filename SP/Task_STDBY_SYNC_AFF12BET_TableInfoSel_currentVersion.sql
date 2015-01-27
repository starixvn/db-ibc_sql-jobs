USE [Affiliate_12bet]
GO

/****** Object:  StoredProcedure [dbo].[Task_STDBY_SYNC_AFF12BET_TableInfoSel_currentVersion]    Script Date: 01/27/2015 04:37:42 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_STDBY_SYNC_AFF12BET_TableInfoSel_currentVersion]
@ctCurrentVersion	BIGINT = 0 OUTPUT 
AS
/*
	Created by: Jamie
	Task: Get current version at Primary server
	DB: DBAFF12BET/Affiliate_12BET
	
*/
BEGIN
	SET NOCOUNT ON 
	SELECT @ctCurrentVersion = CHANGE_TRACKING_CURRENT_VERSION()
END
GO


