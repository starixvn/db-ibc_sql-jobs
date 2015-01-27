USE [bodb_OddsFeed]
GO

/****** Object:  StoredProcedure [dbo].[Odds_WriteLog]    Script Date: 01/27/2015 04:09:58 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Odds_WriteLog]
	@Creator int,
	@PartnerId int =0,
	@Typename varchar(50),	
	@SPName varchar(50),
	@IP varchar(20) =NULL,
	@Detail nvarchar(4000)
AS
/*
Created: 20100202@Johnny
Task : Write Log for Odds feed
DB: bodb_oddsfeed
Original:

Revisions:
*/
SET NOCOUNT ON
begin transaction
	begin try
		INSERT INTO dbo.UserLog (TypeID, Creator, PartnerId, LoggedDate, SPName, IP, Detail)
		VALUES (dbo.Odds_GetLogType(@Typename) , @Creator, @PartnerId, CURRENT_TIMESTAMP, @SPName, @IP, @Detail)	
	end try
	begin catch
		rollback transaction
		return
	end catch 
commit transaction



GO

GRANT EXECUTE ON [dbo].[Odds_WriteLog] TO [bodbAdminNet] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[Odds_WriteLog] TO [VNTeam] AS [dbo]
GO


