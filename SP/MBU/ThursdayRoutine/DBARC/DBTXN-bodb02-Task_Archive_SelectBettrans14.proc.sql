SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE	dbo.Task_Archive_SelectBettrans14
AS
/*
	Creator:	20190426@Billy
	Task:		Select data of bettrans14 for Thursday Routine - [Redmine: #000000]
	Database:	DBTXN.bodb02

	Revisions:
		- 20190426@Billy:	Initial - [Redmine: #000000]
		- 20190426@Billy:	Add column [SettlementTime] of [bettrans] - [Redmine: #122464]

	Developer's Notes:
		- This SP belongs to bettrans14 set for Thursday Routine:
			- Task_Archive_SelectBettrans14_Init
			- Task_Archive_SelectBettrans14
			- Task_Archive_SelectBettrans14_Done
*/
BEGIN;
	SET NOCOUNT ON;

	DECLARE @rn INT
	DECLARE @wldate DATETIME, @c1 BIGINT, @c2 BIGINT

	SELECT	TOP(1)
			@rn = rn
		,	@wldate = wldate
		,	@c1 = c1
		,	@c2 = c2
	FROM	dbo.tmp_Task_Archive_Bettrans14 WITH (NOLOCK)
	ORDER BY rn;

	--	Select data for copying to DBARC.bodb_Archive.dbo.bettrans_bk
	--	Note:	Exclude columns: [recommdate]
	--			Convert [status], [betteam], [betfrom], [betcheck], [ip] to VARCHAR to match with [bettrans_bk] schema
	SELECT	b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, b.actual_stake
		,	[status] = CONVERT(VARCHAR(10), b.status)
		,	b.winlost, b.awinlost, b.mwinlost, b.swinlost
		,	b.playercomm, b.comm, b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking
		,	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator
		,	[betteam] = CONVERT(VARCHAR(10), b.betteam)
		,	b.creator, b.refno, b.winlostdate
		,	[betfrom] = CONVERT(VARCHAR(1), b.betfrom)
		,	[betcheck] = CONVERT(VARCHAR(50), b.betcheck)
		,	b.checktime, b.oddsspread, b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend
		,	b.ruben, b.betid, b.statuswinlost, b.modds, b.betdaqid, b.tstamp, b.currency
		,	[ip] = CONVERT(VARCHAR(15), b.ip)
		,	b.transdesc, b.virtualrate, b.oddstype, b.statusID
		,	b.currency2, b.transid, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.comstatus
		,	[CountryCode] = ip.countryShort
		,	b.ExtraInfo, b.WalletType, b.BonusID, b.RefCode, b.SettlementTime
	FROM		dbo.bettrans14 AS b WITH (NOLOCK)
	INNER JOIN	dbo.Task_bettrans14_IP2Country AS ip WITH (NOLOCK)
			ON	b.transid = ip.transid
			AND	ip.winlostdate = @wldate
	WHERE	b.winlostdate = @wldate;
END;
GO
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/