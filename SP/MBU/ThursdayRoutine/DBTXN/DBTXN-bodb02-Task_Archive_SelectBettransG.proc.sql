SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE	dbo.Task_Archive_SelectBettransG
AS
/*
	Creator:	20150720@Sophia
	Task:		Insert data from bettransG14 to bettransG at bodb_Archive
	Database:	DBTXN.bodb02

	Revisions:
		- 20150720@Sophia:	Add column TransDesc
		- 20180320@Billy:	Add missing column SiteID - [Redmine: #92283]
		- 20200311@Billy:	Add [epositiontaking], [actual_stake] of [bettransG] - [Redmine: #130201]
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE	@max_winlostdate	SMALLDATETIME
		;

	SELECT	@max_winlostdate = MAX(winlostdate)
	FROM	dbo.Task_ArchiveDate WITH (NOLOCK);

	-- to DB06.bodb_Archive.dbo.bettransG
	SELECT	transid, custid, transdate, oddsid, odds, stake, status, winlost, betteam, creator, refno, winlostdate, betfrom
		,	checktime, apositiontaking, mpositiontaking, tpositiontaking, awinlost, mwinlost, playerdiscount, discount, adiscount
		,	playercomm, comm, acomm, actualrate, matchid, matchdate, statuswinlost, ruben, bettype, spositiontaking, swinlost
		,	sdiscount, scomm, statusID, virtualrate, SiteID, transdesc, BetID3rd, epositiontaking, actual_stake
	FROM	dbo.bettransG14 WITH (NOLOCK)
	WHERE	winlostdate <= @max_winlostdate;
END;
GO
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/