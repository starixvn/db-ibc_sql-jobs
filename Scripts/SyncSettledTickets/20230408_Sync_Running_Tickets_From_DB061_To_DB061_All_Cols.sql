/*<info serverAlias = "DB061-bodb02"></info>*/
/*
Task - update running tickets to settle in DB061 from DB062
https://nexdev.net/issues/181387
*/

USE bodb02

GO

--get tickets from DB062 to temp table

select 
	* 
	into #tmp_tickets_need_synced
from DB06.bodb02.dbo.bettrans b with (nolock)
where 
	transid in 
	(
		103272952488787988,103272952488787975,103273038388133908,103272978258591759,103273029798199378,103273128582447119,103272978258591775
		,103273016913297432,103273016913297415,103273072747872312,103273004028395524,103272973963624470,103273283201269764,103273055568003072
		,103273266021400580,103273004028395528,103273291791204380,103273012618330119,103273304676106266,103273270316367895,103273330445910020
		,103273304676106258,103273317561008166,103273257431465986,103273270316367912,103273287496237063,103273330445910035,103273308971073554,103273162946379853,103273227370889226,103273287500431398,103273184421216305,103273175831281666,103273180126249002,103273210191020072
		,103273257435660324,103273231665856525,103273240255791123,103273244550758427,103273270320562205,103273261730627605
		,103273257435660314,103273278910496801,103273291795398665,103273227370889270,103273257435660308,103273296090365971,103273180126248995
		,103273197306118167,103273214485987334,103273317569396755,103273334749265935,103273339044233263,103273296094560275,103273287504625697
		,103273317569396767,103273274619723811,103273334749265922,103273266029789211,103273300389527576
	)
	and currency<>20
	and winlostdate< = '20230407'
order by SiteDBGroupID


--update to DB061
---## 60 rows affected
update b with(rowlock, updlock)
set 
	b.custid = source_ticket.custid
	,b.transdate = source_ticket.transdate
	,b.oddsid = source_ticket.oddsid
	,b.hdp1 = source_ticket.hdp1
	,b.hdp2 = source_ticket.hdp2
	,b.odds = source_ticket.odds
	,b.stake = source_ticket.stake
	,b.status = source_ticket.status
	,b.winlost = source_ticket.winlost
	,b.awinlost = source_ticket.awinlost
	,b.mwinlost = source_ticket.mwinlost
	,b.playercomm = source_ticket.playercomm
	,b.comm = source_ticket.comm
	,b.acomm = source_ticket.acomm
	,b.apositiontaking = source_ticket.apositiontaking
	,b.mpositiontaking = source_ticket.mpositiontaking
	,b.tpositiontaking = source_ticket.tpositiontaking
	,b.playerdiscount = source_ticket.playerdiscount
	,b.discount = source_ticket.discount
	,b.adiscount = source_ticket.adiscount
	,b.livehomescore = source_ticket.livehomescore
	,b.liveawayscore = source_ticket.liveawayscore
	,b.liveindicator = source_ticket.liveindicator
	,b.betteam = source_ticket.betteam
	,b.creator = source_ticket.creator
	,b.refno = source_ticket.refno
	,b.comstatus = source_ticket.comstatus
	,b.winlostdate = source_ticket.winlostdate
	,b.betfrom = source_ticket.betfrom
	,b.betcheck = source_ticket.betcheck
	,b.checktime = source_ticket.checktime
	,b.oddsspread = source_ticket.oddsspread
	,b.actualrate = source_ticket.actualrate
	,b.matchid = source_ticket.matchid
	,b.recommend = source_ticket.recommend
	,b.mrecommend = source_ticket.mrecommend
	,b.ruben = source_ticket.ruben
	,b.betid = source_ticket.betid
	,b.statuswinlost = source_ticket.statuswinlost
	,b.modds = source_ticket.modds
	,b.bettype = source_ticket.bettype
	,b.betdaqid = source_ticket.betdaqid
	,b.actual_stake = source_ticket.actual_stake
	,b.currency = source_ticket.currency
	,b.ip = source_ticket.ip
	,b.transdesc = source_ticket.transdesc
	,b.sdiscount = source_ticket.sdiscount
	,b.scomm = source_ticket.scomm
	,b.spositiontaking = source_ticket.spositiontaking
	,b.swinlost = source_ticket.swinlost
	,b.srecommend = source_ticket.srecommend
	,b.Username = source_ticket.Username
	,b.CurrencyName = source_ticket.CurrencyName
	,b.virtualrate = source_ticket.virtualrate
	,b.oddstype = source_ticket.oddstype
	,b.statusID = source_ticket.statusID
	,b.currency2 = source_ticket.currency2
	,b.balance = source_ticket.balance
	,b.SecAcceptFlag = source_ticket.SecAcceptFlag
	,b.transid2 = source_ticket.transid2
	,b.recommdate = source_ticket.recommdate
	,b.ExtraInfo = source_ticket.ExtraInfo
	,b.WalletType = source_ticket.WalletType
	,b.BonusID = source_ticket.BonusID
	,b.RefCode = source_ticket.RefCode
	,b.SettlementTime = source_ticket.SettlementTime
	,b.epositiontaking = source_ticket.epositiontaking
	,b.ReasonID = source_ticket.ReasonID
	,b.sort = source_ticket.sort
	,b.BetSiteID = source_ticket.BetSiteID
	,b.RepUpdateTime = source_ticket.RepUpdateTime
	,b.RepDstUpdateTime = source_ticket.RepDstUpdateTime
	,b.SiteDBGroupID = source_ticket.SiteDBGroupID
	,b.FcUpdateTime = source_ticket.FcUpdateTime

from 
	bettrans as b
		inner join #tmp_tickets_need_synced source_ticket
			on b.TransId = source_ticket.TransId
where 
	b.TransId IN 
	(
		103272952488787988,103272952488787975,103273038388133908,103272978258591759,103273029798199378,103273128582447119,103272978258591775
		,103273016913297432,103273016913297415,103273072747872312,103273004028395524,103272973963624470,103273283201269764,103273055568003072
		,103273266021400580,103273004028395528,103273291791204380,103273012618330119,103273304676106266,103273270316367895,103273330445910020,
		103273304676106258,103273317561008166,103273257431465986,103273270316367912,103273287496237063,103273330445910035,103273308971073554,
		103273162946379853,103273227370889226,103273287500431398,103273184421216305,103273175831281666,103273180126249002,103273210191020072
		,103273257435660324,103273231665856525,103273240255791123,103273244550758427,103273270320562205,103273261730627605
		,103273257435660314,103273278910496801,103273291795398665,103273227370889270,103273257435660308,103273296090365971,103273180126248995
		,103273197306118167,103273214485987334,103273317569396755,103273334749265935,103273339044233263,103273296094560275,103273287504625697
		,103273317569396767,103273274619723811,103273334749265922,103273266029789211,103273300389527576
	)