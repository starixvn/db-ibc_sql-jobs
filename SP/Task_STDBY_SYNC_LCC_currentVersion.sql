USE [bodb_LCC]
GO

/****** Object:  StoredProcedure [dbo].[Task_STDBY_SYNC_LCC_currentVersion]    Script Date: 01/27/2015 05:29:59 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_STDBY_SYNC_LCC_currentVersion]
@ctCurrentVersion	BIGINT = 0 OUTPUT 
AS
/*
	Created by: Jamie
	Task: Get current version at Primary server
	DB: DBLCC/DBLCC
	
*/
BEGIN
	SET NOCOUNT ON 
	SELECT @ctCurrentVersion = CHANGE_TRACKING_CURRENT_VERSION()
END
GO


