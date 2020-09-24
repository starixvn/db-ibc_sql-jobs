SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE	dbo.Task_Archive_SelectBettransm
AS
/*
	Creator:	20190213@Billy
	Task:		Select [bettransm] data for Thursday Routine - [Redmine: #000000]
	Database:	DBTXN.bodb02

	Revisions:
		- 20190213@Billy:	Initial - [Redmine: #000000]
		- 20190213@Billy:	Add column [SecAcceptFlag] of [bettransm] - [Redmine: #108780]
		- 20200923@Brice:	Add column [reasonIDm] of [bettransM] - [Redmine: #141650]

	Developer's Notes:
		- @Example:			NULL		- Explaination [DEFAULT]
		
*/
BEGIN;
	SET NOCOUNT ON;

	DECLARE	@max_winlostdate	SMALLDATETIME
		;

	SELECT	@max_winlostdate = MAX(winlostdate)
	FROM	dbo.Task_ArchiveDate;

	-- to DB06.bodb_Archive.dbo.bettransm
	SELECT	[BetCheck]	= CONVERT(VARCHAR(50), betcheck)
		,	[BetFrom]	= CONVERT(VARCHAR(1),  betfrom)
		,	[BetTeam]	= CONVERT(VARCHAR(10), betteam)
		,	[ComStatus]	= CONVERT(VARCHAR(20), comstatus)
		,	[Status]	= CONVERT(VARCHAR(10), status)

		,	transdate, transid, custid, matchid, oddsid, bettype, hdp1, hdp2, stake, odds, finalodds
		,	apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, awinlost, mwinlost, swinlost
		,	playerdiscount, discount, adiscount, sdiscount, playercomm, comm, acomm, scomm
		,	liveawayscore, livehomescore, liveindicator, matchdate, isfinish
		,	oddsspread, refno, ruben, statusID, statuswinlost, winlost
		,	actualrate, checktime, creator, winlostdate, recommdate, transdesc, SecAcceptFlag, reasonIDm
	FROM	dbo.bettransm14 WITH (NOLOCK)
	WHERE	winlostdate <= @max_winlostdate;
END;
GO
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/