USE [bodb_CRM]
GO

/****** Object:  StoredProcedure [dbo].[Task_STDBY_SYNC_CRM_currentVersion]    Script Date: 01/27/2015 04:43:47 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_STDBY_SYNC_CRM_currentVersion]
@ctCurrentVersion	BIGINT = 0 OUTPUT 
AS
/*
	Created by: Jamie
	Task: Get current version at Primary server
	DB: DBCRM/bodb_CRM
	
*/
BEGIN
	SET NOCOUNT ON 
	SELECT @ctCurrentVersion = CHANGE_TRACKING_CURRENT_VERSION()
END
GO


