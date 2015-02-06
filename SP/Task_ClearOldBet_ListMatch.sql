USE [BetBackup]
GO

/****** Object:  StoredProcedure [dbo].[Task_ClearOldBet_ListMatch]    Script Date: 02/04/2015 23:24:08 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_ClearOldBet_ListMatch]
AS
SET NOCOUNT ON

Declare @match TABLE (matchid int)
INSERT INTO @match
SELECT distinct matchid FROM dbo.bettrans with (nolock)

INSERT INTO @match
SELECT distinct matchid FROM dbo.bettransm with (nolock)

DELETE mm
FROM bodb02.dbo.match m
	INNER JOIN @match mm ON m.matchid = mm.matchid

DELETE mm
FROM bodb02.dbo.match14 m
	INNER JOIN @match mm ON m.matchid = mm.matchid

INSERT INTO dbo.Task_ClearOldBet_match (matchid)
SELECT DISTINCT matchid
FROM @match
GO

GRANT VIEW DEFINITION ON [dbo].[Task_ClearOldBet_ListMatch] TO [vnteam] AS [dbo]
GO


