USE [bodb_CustomerLog]
GO

/****** Object:  StoredProcedure [dbo].[WriteLog_UserLog_Transfer]    Script Date: 01/27/2015 22:58:44 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.WriteLog_UserLog_Transfer    Script Date: 10/13/2009 2:31:17 PM ******/
CREATE PROCEDURE [dbo].[WriteLog_UserLog_Transfer]
	@UserID int, 
	@FromCustID INT, 
	@ToCustID INT, 
	@IP varchar(15)='',
	@Doing varchar(1000)=''
AS
/*
Creator: Kiwi
Date: 03/10/2009
DB: bodb_CustomerLog
Task: Insert LOGS for Trasfer function

*/

SET NOCOUNT ON;

INSERT INTO dbo.UserLog_Transfer(	UserID,
									FromCustID,
									ToCustID,
									IP,
									Doing) 
							VALUES(	@UserID,
									@FromCustID,
									@ToCustID,
									@IP,
									@Doing)

GO

GRANT EXECUTE ON [dbo].[WriteLog_UserLog_Transfer] TO [bodbAdminNet] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[WriteLog_UserLog_Transfer] TO [bodbDownlineNet] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[WriteLog_UserLog_Transfer] TO [bodbDownlineNetView] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[WriteLog_UserLog_Transfer] TO [bodbExtAccNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[WriteLog_UserLog_Transfer] TO [vnteam] AS [dbo]
GO


