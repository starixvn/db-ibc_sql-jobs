SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE	dbo.Task_Archive_SelectBetLucky3Result
AS
/*
	Creator:	20171009@Lukas
	Task:		Get data from BetLucky3Result14 for archiving
	Database:	DBTXN.bodb02

	Revisions:
		- 20171009@Lukas:	Initial - [Redmine: #000000]
*/
BEGIN 
	SET NOCOUNT ON

	DECLARE  @max_winlostdate SMALLDATETIME

	SELECT	 @max_winlostdate = MAX(winlostdate)
	FROM	dbo.Task_ArchiveDate

	-- to DB06.bodb_Archive.dbo.BetLucky3Result_bk
	SELECT 	MatchId, TransId, CustId, Bettype, Currency, Hdp1, Odds, StatusId, Hits, Prize, PrizeAmount, Winlost, aWinlost, mWinlost, sWinlost, 
			PlayerComm, Comm, aComm, sComm, aPositionTaking, mPositionTaking, sPositionTaking, PlayerDiscount, Discount, aDiscount, sDiscount, 
			TransDesc, WinlostDate		 
	FROM dbo.BetLucky3Result14 B  with(nolocK)
	WHERE
		b.winlostdate <= @max_winlostdate
END
GO
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/