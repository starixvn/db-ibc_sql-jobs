USE [BetBackup]
GO

/****** Object:  StoredProcedure [dbo].[Task_ClearOldBet_SingleMatch]    Script Date: 02/04/2015 23:24:14 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_ClearOldBet_SingleMatch]
AS
SET NOCOUNT ON

Declare @rn int, @matchid int
SELECT TOP 1 @rn = rn, @matchid = matchid
FROM dbo.Task_ClearOldBet_Match with (nolock)

DELETE FROM dbo.bettrans
WHERE matchid = @matchid

DELETE FROM dbo.bettransm
WHERE matchid = @matchid

DELETE FROM dbo.Task_ClearOldBet_Match
WHERE matchid = @matchid

GO

GRANT VIEW DEFINITION ON [dbo].[Task_ClearOldBet_SingleMatch] TO [vnteam] AS [dbo]
GO


