SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE	dbo.Task_Archive_bettrans14
AS
/*
	Creator:	yyyymmdd@Unknown
	Task:		Copy bettrans14 to bettrans_bk - [Redmine: #000000]
	Database:	DBARC.bodb_Archive

	Revisions:
		- 20190426@Billy:	Initial - [Redmine: #000000]
		- 20190426@Billy:	Add column [SettlementTime] of [bettrans] - [Redmine: #122464]
		- 20191104@Billy:	Add column [epositiontaking] of [bettrans] - [Redmine: #123267]
		- 20200311@Billy:	Add column [ReasonID] of [bettrans] - [Redmine: #130202]
		- 20200710@Brice:	Add column [sort] of [bettrans] - [Redmine: #137129]

	Developer's Notes:
		- @Example:			NULL		- Explaination [DEFAULT]

*/
BEGIN;
	SET NOCOUNT ON;

	-- Note: Exclude columns: [recommdate]
	INSERT INTO	dbo.bettrans_bk
		(	custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost
		,	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking
		,	playerdiscount, discount, adiscount, sdiscount, livehomescore, liveawayscore, liveindicator, betteam, creator
		,	refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, mrecommend, srecommend
		,	ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID
		,	currency2, transid, bettype, balance, transid2, SecAcceptFlag, comstatus, CountryCode, ExtraInfo, WalletType
		,	BonusID, RefCode, SettlementTime, epositiontaking, ReasonID, sort
		)
	SELECT	custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake, status, winlost, awinlost, mwinlost, swinlost
		,	playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking
		,	playerdiscount, discount, adiscount, sdiscount, livehomescore, liveawayscore, liveindicator, betteam, creator
		,	refno, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, mrecommend, srecommend
		,	ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency, ip, transdesc, virtualrate, oddstype, statusID
		,	currency2, transid, bettype, balance, transid2, SecAcceptFlag, comstatus, CountryCode, ExtraInfo, WalletType
		,	BonusID, RefCode, SettlementTime, epositiontaking, ReasonID, sort
	FROM	OPENQUERY(DBTXN, '\
EXECUTE	bodb02.dbo.Task_Archive_SelectBettrans14;
');

	IF	@@ROWCOUNT = 0
		RAISERROR(N'* no more data *', 16, 1) WITH NOWAIT;
END;
GO
/*<info serverAlias="DBARC-bodb_Archive" executers="" viewers="" isFunction="0" isNested="0"></info>*/