USE [bodb_EAS]
GO

/****** Object:  StoredProcedure [dbo].[Task_EAS_ClearLogin]    Script Date: 01/27/2015 03:26:38 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/****** Object:  Stored Procedure dbo.Task_EAS_ClearLogin    Script Date: 10/2/2013 9:18:44 AM ******/
CREATE PROCEDURE [dbo].[Task_EAS_ClearLogin]	
AS
/*
	Created:  20121116@Dan
	Task: EAS - Clear Login
	DB: DBEAS/bodb_EAS
	Original SP:
	
	Revisions:
		
*/
BEGIN
	SET NOCOUNT ON
	DELETE FROM eaOn_User WITH (UPDLOCK,ROWLOCK)
	WHERE	reload_time < dateadd(minute,-30,CURRENT_TIMESTAMP)
END


GO

GRANT VIEW DEFINITION ON [dbo].[Task_EAS_ClearLogin] TO [vnteam] AS [dbo]
GO


