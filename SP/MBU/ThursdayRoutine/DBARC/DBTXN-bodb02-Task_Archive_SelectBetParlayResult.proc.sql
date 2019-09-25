SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE [dbo].[Task_Archive_SelectBetParlayResult]
AS
/*
Set of SP
	Task_Archive_SelectBettrans14_Init 
	Task_Archive_SelectBettrans14      : read data
	Task_Archive_SelectBettrans14_Done
*/
SET NOCOUNT ON

DECLARE @winlostdate DATETIME

SELECT @winlostdate = MAX(winlostdate)
FROM dbo.Task_ArchiveDate WITH (NOLOCK)

--to DBARC.[bodb_Archive].dbo.[betParlayResult] & [betParlayResult_Archive]
	Declare @refNos TABLE (refno bigint PRIMARY KEY)
	INSERT INTO @refNos
	SELECT refno
	FROM dbo.bettrans14 with (nolock)
	WHERE winlostdate <= @winlostdate AND bettype = 29

	SELECT
		rID, b.RefNo, Serial, transid, winlostdate, statusid, stake, Odds, mOdds,
		winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm
	FROM
		dbo.betParlayResult b WITH (NOLOCK)
		INNER JOIN @refNos r ON b.refno = r.refno
GO
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/