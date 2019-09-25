SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE [dbo].[Task_Archive_BetParlayResult]
AS

INSERT INTO dbo.betParlayResult (
	rID, RefNo, Serial, transid, winlostdate, statusid, stake, Odds, mOdds,
	winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm	)
SELECT 
	rID, RefNo, Serial, transid, winlostdate, statusid, stake, Odds, mOdds,
	winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm
FROM
	OPENQUERY(DBTRANS,'EXEC bodb02.dbo.Task_Archive_SelectBetParlayResult')


-- NOTE
-- archive to betParlayResult_Archive done by Trigger
GO
/*<info serverAlias="DBARC-bodb_Archive" executers="" viewers="" isFunction="0" isNested="0"></info>*/