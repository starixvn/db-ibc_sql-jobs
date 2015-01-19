USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Task_Delete_bettrans_running]    Script Date: 01/19/2015 04:49:13 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_Delete_bettrans_running]
AS

DELETE TOP(500)
FROM bodb_AGE.dbo.bettrans_running_toDelete witH(rowlock,updlock)

/*
DELETE TOP(500)
FROM dbo.bettrans_running_toDelete
*/
IF @@ROWCOUNT = 0
	WAITFOR DELAY '00:00:15.000'
	
	
GO


