SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE	dbo.Task_Archive_SelectBettransRNG
AS
/*
	Creator:	20151013@Sophia
	Task:		Insert data from bettransRNG14 to bettransRNG_BK at bodb_Archive
	Database:	DBTXN.bodb02

	Revisions:
		- 20160519@Joy:		remove NetStake /  Add  Additional    
		- 20180405@Billy:	Add [JackpotInfo], [RefNo2], [ContributionRate], [BetStake], [ContributionStake3rd] columns - [Redmine: #93177]
*/
BEGIN;
	SET NOCOUNT ON;

	DECLARE	@max_winlostdate	SMALLDATETIME;

	SELECT	@max_winlostdate = MAX(winlostdate)
	FROM	dbo.Task_ArchiveDate WITH (NOLOCK);

	-- to DB06.bodb_Archive.dbo.bettransRNG_BK
	SELECT	b.transid, custid, transdate, odds, stake, status, apositiontaking, mpositiontaking, tpositiontaking, spositiontaking, 
			playerdiscount, discount, adiscount, sdiscount, creator, b.winlostdate, betfrom, virtualrate, actualrate, actual_stake, 
			currency, CurrencyName, recommend, mrecommend, srecommend, ip, statusID, balance, Username, transdesc, productID, gameID, 
			vendorID, GameId3rd, TranId3rd, RefNo, IsSum, winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, Transdate3rd,
			ip.countryShort countryCode ,Additional
		,	b.JackpotInfo, b.RefNo2, b.ContributionRate, b.BetStake, b.ContributionStake3rd
	FROM		dbo.bettransRnG14 AS b WITH (NOLOCK)
	INNER JOIN	dbo.Task_bettransRNG14_IP2Country AS ip WITH (NOLOCK)
			ON	b.transid = ip.transid
	WHERE	b.winlostdate <= @max_winlostdate;
END;
GO
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/