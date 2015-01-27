USE [bodb_Maintenance]
GO

/****** Object:  StoredProcedure [dbo].[Task_STDBY_SYNC_DBMA_currentVersion]    Script Date: 01/27/2015 04:54:37 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_STDBY_SYNC_DBMA_currentVersion]
@ctCurrentVersion	BIGINT = 0 OUTPUT 
AS
/*
	Created by: Jamie
	Date: 20140602
	Task: Mail sync (RUN ONLY ON PRIMARY SERVER)
	DB: DBMA/bodb_Maintenance 
	
*/
BEGIN
	SET NOCOUNT ON 
	SELECT @ctCurrentVersion = CHANGE_TRACKING_CURRENT_VERSION()
END
GO


