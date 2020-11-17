use bodb02
go
create table #odds(oddsid int)
insert into #odds (oddsid)
SELECT	oddsid
	FROM	[MonDB].dbo.[__odds_bk] AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match14 AS m WITH (NOLOCK) WHERE m.eventdate = '2020-11-12' AND tbl.matchid = m.matchid)
except
SELECT	oddsid
	FROM	dbo.odds14 AS tbl WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM dbo.match14 AS m WITH (NOLOCK) WHERE m.eventdate = '2020-11-12' AND tbl.matchid = m.matchid);

insert into odds14
	([oddsid], [matchid], [bettype], [switch], [hdp1], [hdp2],
		[odds1a], [odds2a], [odds1b], [odds2b], [odds1c], [odds2c], [odds1e], 
		[odds2e], [odds1f], [odds2f], [odds1d], [odds2d], [odds1hka], [odds2hka],
		[odds1hkb], [odds2hkb], [odds1hkc], [odds2hkc], [odds1hke], [odds2hke], [odds1hkf],
		[odds2hkf], [odds1hkd], [odds2hkd], [oddsspreada], [oddsspreadb], [oddsspreadd], 
		[oddsspreade], [oddsspreadf], [oddsspreadc], [autobookie], [gapodds1], [gapodds2],
		[maxstake1], [maxstake2], [minstake1], [minstake2], [diffbalance], [maxodds], 
		[minodds], [oddsstatus], [liveindicator], [changetime], [risk], [stakerange],
		[newoffersetup], [livehomescore], [liveawayscore], [creator], [com1], [comx],
		[com2], [cs00], [cs01], [cs10], [cs11], [cs02], [cs12], [cs22], [cs21], [cs20],
		[cs30], [cs31], [cs32], [cs33], [cs23], [cs13], [cs03], [cs43], [cs42], [cs41],
		[cs40], [cs44], [cs14], [cs24], [cs04], [cs34], [cs50], [cs05], [comstatus], 
		[csstatus], [commaxbet], [csmaxbet], [com1total], [comxtotal], [com2total],
		[bal00], [bal10], [bal11], [bal01], [bal20], [bal21], [bal22], [bal12], 
		[bal02], [bal30], [bal31], [bal32], [bal33], [bal23], [bal13], [bal03], 
		[bal40], [bal41], [bal42], [bal43], [bal44], [bal34], [bal24], [bal14],
		[bal04], [bal50], [bal05], [maxbet], [multiple], [allowance], [risk2], 
		[stakerange2], [allowance2], [hometotal], [awaytotal], sporttype, Resourceid, ResultKey,GapOddsCap1,GapOddsCap2,
		[cs99],[bal99])
select
	[oddsid], [matchid], [bettype], [switch], [hdp1], [hdp2],
	[odds1a], [odds2a], [odds1b], [odds2b], [odds1c], [odds2c], [odds1e], 
	[odds2e], [odds1f], [odds2f], [odds1d], [odds2d], [odds1hka], [odds2hka],
	[odds1hkb], [odds2hkb], [odds1hkc], [odds2hkc], [odds1hke], [odds2hke], [odds1hkf],
	[odds2hkf], [odds1hkd], [odds2hkd], [oddsspreada], [oddsspreadb], [oddsspreadd], 
	[oddsspreade], [oddsspreadf], [oddsspreadc], [autobookie], [gapodds1], [gapodds2],
	[maxstake1], [maxstake2], [minstake1], [minstake2], [diffbalance], [maxodds], 
	[minodds], [oddsstatus], [liveindicator], [changetime], [risk], [stakerange],
	[newoffersetup], [livehomescore], [liveawayscore], [creator], [com1], [comx],
	[com2], [cs00], [cs01], [cs10], [cs11], [cs02], [cs12], [cs22], [cs21], [cs20],
	[cs30], [cs31], [cs32], [cs33], [cs23], [cs13], [cs03], [cs43], [cs42], [cs41],
	[cs40], [cs44], [cs14], [cs24], [cs04], [cs34], [cs50], [cs05], [comstatus], 
	[csstatus], [commaxbet], [csmaxbet], [com1total], [comxtotal], [com2total],
	[bal00], [bal10], [bal11], [bal01], [bal20], [bal21], [bal22], [bal12], 
	[bal02], [bal30], [bal31], [bal32], [bal33], [bal23], [bal13], [bal03], 
	[bal40], [bal41], [bal42], [bal43], [bal44], [bal34], [bal24], [bal14],
	[bal04], [bal50], [bal05], [maxbet], [multiple], [allowance], [risk2], 
	[stakerange2], [allowance2], [hometotal], [awaytotal], sporttype, Resourceid, ResultKey,GapOddsCap1,GapOddsCap2,
	[cs99],[bal99]
from [MonDB].dbo.[__odds_bk] o with(nolock)
where o.oddsid in (select oddsid from #odds)

drop table #odds

/*<info serverAlias="DBPRO-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/