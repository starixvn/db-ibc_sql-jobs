USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[WriteLog_UserLog]    Script Date: 01/26/2015 22:59:18 ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[WriteLog_UserLog]
@UserID int,
@Doing nvarchar(300)
 AS
insert into dbo.UserLog (UserID, Doing) values (@UserID, @Doing)


GO

GRANT EXECUTE ON [dbo].[WriteLog_UserLog] TO [bodbAdminNet] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[WriteLog_UserLog] TO [bodbDownlineNet] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[WriteLog_UserLog] TO [Dot_Member] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[WriteLog_UserLog] TO [Dot_P2P] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[WriteLog_UserLog] TO [vnteam] AS [dbo]
GO


