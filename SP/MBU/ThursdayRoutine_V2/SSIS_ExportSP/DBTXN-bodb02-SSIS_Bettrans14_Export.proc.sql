/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_bettrans14_Export]
	@winlostdate smalldatetime=null
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]	
	Database: DBTXN.bodb02
	Original: Task_Archive_SelectBettrans
	
	Revisions:
		- 20130831@Bobby: Init
*/
BEGIN
	SET NOCOUNT ON;
	
	SELECT	b.custid, b.transdate, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, b.actual_stake
			,	[status] = CONVERT(VARCHAR(10), b.status)
			,	b.winlost, b.awinlost, b.mwinlost, b.swinlost
			,	b.playercomm, b.comm, b.acomm, b.scomm, b.apositiontaking, b.mpositiontaking, b.spositiontaking, b.tpositiontaking
			,	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.livehomescore, b.liveawayscore, b.liveindicator
			,	[betteam] = CONVERT(VARCHAR(10), b.betteam)
			,	b.creator, b.refno, b.winlostdate
			,	[betfrom] = CONVERT(VARCHAR(4), b.betfrom)
			,	[betcheck] = CONVERT(VARCHAR(50), b.betcheck)
			,	b.checktime, b.oddsspread, b.actualrate, b.matchid, b.recommend, b.mrecommend, b.srecommend
			,	b.ruben, b.betid, b.statuswinlost, b.modds, b.betdaqid, b.tstamp, b.currency
			,	[ip] = ISNULL(ip.IPArchive, b.ip)
			,	b.transdesc, b.virtualrate, b.oddstype, b.statusID
			,	b.currency2, b.transid, b.bettype, b.balance, b.transid2, b.SecAcceptFlag, b.comstatus
			,	[CountryCode] = ip.countryShort
			,	b.ExtraInfo, b.WalletType, b.BonusID, b.RefCode, b.SettlementTime, b.epositiontaking, b.ReasonID, b.sort
		FROM		dbo.bettrans14 AS b WITH (NOLOCK)
		INNER JOIN	dbo.Task_bettrans14_IP2Country AS ip WITH (NOLOCK)
				ON	b.transid = ip.transid
				AND	ip.winlostdate = b.winlostdate
		WHERE b.winlostdate = @winlostdate
END
GO
