USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[logfile]    Script Date: 01/27/2015 03:50:42 ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[logfile]
	@userid int,
	@doing nvarchar(300)
AS
BEGIN
	--20110607@Vivi: comment out begin tran and commit tran
	--begin tran
	insert into dbo.userlog (userid,doing) values (@userid,@doing)
	--commit tran
END


GO

GRANT EXECUTE ON [dbo].[logfile] TO [bodbAdminNet] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[logfile] TO [bodbDownlineNet] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[logfile] TO [Dot_Admin] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[logfile] TO [ibc_admin] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[logfile] TO [ibc_agent] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[logfile] TO [ibc_member] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[logfile] TO [vnteam] AS [dbo]
GO


