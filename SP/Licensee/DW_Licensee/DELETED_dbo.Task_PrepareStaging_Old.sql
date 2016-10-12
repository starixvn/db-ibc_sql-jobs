 set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

ALTER PROC [dbo].[Task_PrepareStaging_Old]
AS
/*
Created: 
Task : copy & transform data from IBC to staging DB for generating cubes

DB: bodb_Staging
Original:

Revisions:
	20110223@Daniel: Change condition for new bet type range
    20110324@Daniel: Fix bug status Half-refund quen converting status
	20110726@Daniel: Get data for column outright.programdate 
	20110823@Daniel: Treat negative stake as positive in Turnover (data affect from Sept 1st 2011) 
	20110824@Daniel: Update BA status for tickets belonged to BA (Bet Aggregator)
    20110915@Daniel: Support bettype 1st Correct Score (bettype=30)
    20111227@Don: Add two columns 'livehomescore' and 'liveawayscore' to support Live/Non-Live Mix Parlay
    20120119@Don: Support extra two bettypes Handicap 1x2 (124,125) (column [status])
	20120207@Dom: New bettype Kick Off: Change typeid value of kick-off bettype from 1001 to 18999  
	20120423@Jim: Add more information for BARM Agent
	
Param's Explanation:

*/
TRUNCATE TABLE bodb_Staging.dbo.bettransm
INSERT INTO bodb_Staging.dbo.bettransm
(transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, apositiontaking, mpositiontaking, tpositiontaking, awinlost, mwinlost, playerdiscount, discount, adiscount, playercomm, comm, acomm, actualrate, matchid, matchdate, finalodds, isfinish, statuswinlost, ruben, bettype)
select transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, apositiontaking, mpositiontaking, tpositiontaking, awinlost, mwinlost, playerdiscount, discount, adiscount, playercomm, comm, acomm, actualrate, matchid, matchdate, finalodds, isfinish, statuswinlost, ruben, bettype
from bodb02.dbo.bettransm with (nolock)
UNION
select transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, apositiontaking, mpositiontaking, tpositiontaking, awinlost, mwinlost, playerdiscount, discount, adiscount, playercomm, comm, acomm, actualrate, matchid, matchdate, finalodds, isfinish, statuswinlost, ruben, bettype
from bodb02.dbo.bettransm14 with (nolock)


TRUNCATE TABLE bodb_Staging.dbo.outright
insert into bodb_Staging.dbo.outright
(matchid, leagueid, groupmatch, homeid, awayid, eventdate, kickofftime, oddsstatus, odds, [status], risk, programdate)
select matchid, leagueid, groupmatch, homeid, awayid, eventdate, kickofftime, oddsstatus, odds, [status], risk, programdate
from bodb_Account.dbo.outright with (nolock)
delete m
from [bodb_Staging].[dbo].[match] m
inner join bodb_account.dbo.match a with (nolock) on a.matchid=m.matchid
where m.[leagueid]<>a.[leagueid]
or m.[homeid]<>a.[homeid]
or m.[awayid]<>a.[awayid]
or m.[eventdate]<>a.[eventdate]
or m.[finalhomescore]<>a.[finalhomescore]
or m.[finalawayscore]<>a.[finalawayscore]
or m.[exrisk]<>a.[exrisk]
or m.[sporttype]<>a.[sporttype]
or m.matchcode<>a.matchcode
or m.hthomescore<>a.hthomescore
or m.htawayscore<>a.htawayscore
or m.kickofftime<>a.kickofftime
INSERT INTO [bodb_Staging].[dbo].[match]
           ([matchid]
           ,[leagueid]
           ,[homeid]
           ,[awayid]
           ,[eventdate]
           ,[finalhomescore]
           ,[finalawayscore]
           ,[exrisk]
           ,[sporttype],matchcode,
	hthomescore,htawayscore,kickofftime)
select  m.[matchid] ,m.[leagueid] ,m.[homeid] ,m.[awayid] ,m.[eventdate],m.[finalhomescore],m.[finalawayscore],m.[exrisk],m.[sporttype],
m.matchcode,m.hthomescore,m.htawayscore,m.kickofftime
from bodb_Account.dbo.match  m with (nolock)
left join bodb_staging.dbo.match a on a.matchid=m.matchid
where a.matchid is null


INSERT INTO [bodb_Staging].[dbo].[match]
           ([matchid]
           ,[leagueid]
           ,[homeid]
           ,[awayid]
           ,[eventdate]
           ,[finalhomescore]
           ,[finalawayscore]
           ,[exrisk]
           ,[sporttype],matchcode,
	hthomescore,htawayscore,kickofftime)
select  m.[matchid] ,m.[leagueid] ,m.[homeid] ,m.[awayid] ,m.[eventdate],m.[finalhomescore],m.[finalawayscore],m.[exrisk],m.[sporttype],
m.matchcode,m.hthomescore,m.htawayscore,m.kickofftime
from db06.bodb_Archive.dbo.match_bk m with (nolock)
left join bodb_staging.dbo.match a on a.matchid=m.matchid
where a.matchid is null

-----------------------------------------------------------------------------------------------------
TRUNCATE TABLE [bettrans]

declare @firstevent datetime --used to define the first date of the event span, in case movebet process was done wrong and bettrans still has old data
select @firstevent = min(eventdate) from bodb02.dbo.match14 m with (nolock)

ALTER INDEX [IX_winlostdate_bettype] ON bettrans DISABLE

--Copy LIVE data (bettrans)
INSERT INTO [bettrans]
           (customercategory,[transid],winlostdate,betfrom,liveindicator,bettype,[custid],betteam,[stake],actual_stake,odds,[winlost],
			[awinlost],[mwinlost],swinlost,acomm,scomm,playercomm,comm,[tpositiontaking],spositiontaking,[mpositiontaking],[apositiontaking],
           matchid,[status],[srecommend],actualrate,currency,externalbet,recommend,mrecommend,transdaterate,refno,virtualrate,transdate,isBA,
           livehomescore,liveawayscore)
SELECT null CustomerCategory,b.transid,b.winlostdate,b.betfrom,b.liveindicator,b.bettype,b.custid,b.betteam,
	b.stake,b.actual_stake,b.odds,b.winlost, 
	b.awinlost,
	b.mwinlost+case when b.bettype>30 and b.bettype<50 then b.swinlost else 0 end mwinlost,                     
	case when b.bettype>30 and b.bettype<50 then (winlost-stake)*(1-tpositiontaking-isnull(oddsspread,0)) else b.swinlost end swinlost, 
	acomm, scomm, playercomm, comm, case when b.bettype>30 and b.bettype<50 then 1-isnull(oddsspread,0) else b.tpositiontaking end tpositiontaking, 
	b.spositiontaking,b.mpositiontaking,b.apositiontaking,b.matchid,
	CASE WHEN (b.bettype IN (1, 3, 7, 8, 17, 18, 124, 125) AND abs(b.modds) = 0.25 AND [status] IN('WON','LOSE')) or (b.bettype in (33,43) and [status] <> 'refund' and b.liveawayscore=0) THEN 'HALF ' ELSE '' END + b.status AS [status], 
	srecommend, null actualrate, b.currency, 0 ExternalBet,b.recommend,mrecommend,b.actualrate AS transdaterate,b.refno,b.virtualrate,b.transdate,0,
	livehomescore,liveawayscore
FROM         bodb02.dbo.bettrans AS b WITH (nolock)
WHERE     (b.custid <> 0) AND (b.bettype < 19999) AND (b.status NOT IN ('VOID', 'REJECT', 'running','DONE'))
and not (currency=20 and b.bettype>30 and b.bettype<=50) and winlostdate>=@firstevent

--Copy archived data (bettans14)
INSERT INTO [bettrans]
           (customercategory,[transid],winlostdate,betfrom,liveindicator,bettype,[custid],betteam,[stake],actual_stake,odds,[winlost],
			[awinlost],[mwinlost],swinlost,acomm,scomm,playercomm,comm,[tpositiontaking],spositiontaking,[mpositiontaking],[apositiontaking],
           matchid,[status],[srecommend],actualrate,currency,externalbet,recommend,mrecommend,transdaterate,refno,virtualrate,transdate,isBA,
           livehomescore,liveawayscore)
SELECT     null CustomerCategory,b.transid, b.winlostdate, b.betfrom, b.liveindicator, b.bettype, b.custid, b.betteam, 
	b.stake,b.actual_stake, b.odds, b.winlost, 
	b.awinlost, 
	b.mwinlost+case when(b.bettype>30 and b.bettype<50) then b.swinlost else 0 end, 
	case when(b.bettype>30 and b.bettype<50) then (winlost-stake)*(1-tpositiontaking-isnull(oddsspread,0)) else b.swinlost end swinlost, 
	acomm,scomm,playercomm,comm, 
	case when(b.bettype>30 and b.bettype<50) then 1-isnull(oddsspread,0) else b.tpositiontaking end tpositiontaking,b.spositiontaking,b.mpositiontaking,b.apositiontaking,b.matchid, 
	CASE WHEN (b.bettype IN (1, 3, 7, 8, 17, 18, 124, 125) AND abs(b.modds) = 0.25 AND  [status] IN('WON','LOSE')) or (b.bettype in (33,43) and [status] <> 'refund' and b.liveawayscore=0) THEN 'HALF ' ELSE '' END + b.status AS status, 
	srecommend, null actualRate, b.currency, 0 AS ExternalBet, b.recommend, mrecommend, b.actualrate AS transdaterate, b.refno,b.virtualrate,b.transdate,0,
	livehomescore,liveawayscore
FROM         bodb02.dbo.bettrans14 AS b WITH (nolock)
WHERE     (b.custid <> 0) AND (b.bettype < 19999)  AND (b.status NOT IN ('VOID', 'REJECT', 'running','DONE'))
and not (currency=20 and b.bettype>30 and b.bettype<=50) and winlostdate>=@firstevent

--Assign customer category to each record
update b
set customercategory=case WHEN b.currency=20 or b.bettype>30 then 30 else cat.CategoryID end
from bettrans b with (nolock)
left join bodb_Account.dbo.view_Customer_Exclusion cat with (nolock) on (b.custid = cat.custid and cat.roleid = 1) or (b.mrecommend= cat.custid and cat.roleid = 3) or (b.recommend= cat.custid and cat.roleid = 2)

--Override commission setting to zero for 8RM
update bettrans
set acomm=0,comm=0,scomm=0,playercomm=0
where recommend IN (52466,5707545)

--override negative stake for external bets, identify external bets (discontinued)
update bettrans set externalbet = 1 where stake < 0

--Assign daily rates to each record
update b
set actualrate=e.rate
from bettrans b with (nolock)
INNER JOIN  bodb_account.dbo.tbl_Currency_Daily AS e WITH (nolock) ON e.Currency = b.currency AND b.winlostdate = e.ExchangeDate 

--Change bettypeid for kickoff product
update b
set bettype=18999 --kick-off
from bettrans b with (nolock)
inner join match match with (nolock) on b.matchid=match.matchid 
inner join bodb_account.dbo.team h on h.teamid=match.homeid
where b.bettype not in (9,10,18999,31,32,33,41,42,43) and (h.teamname like '%to kick off%' or match.leagueid=1016) --kick-off

--///// PROCESS UPDATE BA STATUS FOR TICKETS ///////////////////
DECLARE @BATransids AS TABLE (transID bigint)
declare @currentDate datetime

set @currentDate = current_timestamp

INSERT @BATransids
SELECT distinct transid
from bodb_staging.dbo.bettrans b WITH (NOLOCK)
	inner join DB052.bodb_Licensee.dbo.LicenseeBAHistory h WITH (NOLOCK) 
		on b.custid = h.custid and transdate between OnDate and ISNULL(OffDate, @currentDate)
where Bettype NOT BETWEEN 31 AND 120
	and tpositiontaking = 0
	and SRecommend in (select custid from bodb02.dbo.f_DepSuper_1('ALL'))

update bodb_staging.dbo.bettrans set IsBA = 1
where transid IN(select transid from @BATransids)

/*DECLARE @TempBACustID AS TABLE (CustID INT)

--Insert current running BA Customer
INSERT INTO @TempBACustID (CustID)
SELECT CustID FROM DB052.bodb_Licensee.dbo.LicenseeBAHistory WITH (NOLOCK) 
WHERE Status = 'Running'

--Insert last 2 minutes BA Customer which is set to DONE
INSERT INTO @TempBACustID (CustID)
SELECT CustID 
FROM DB052.bodb_Licensee.dbo.LicenseeBAHistory WITH (NOLOCK) 
WHERE CustID NOT IN (SELECT CustID FROM @TempBACustID)
	AND Status = 'Done'
	AND DATEDIFF(MINUTE,OffDate,CURRENT_TIMESTAMP)<=2

--Update BA status for Licensee tickets
update bettrans 
set IsBA = 1
where Bettype NOT BETWEEN 31 AND 120
	and tpositiontaking = 0
	and SRecommend in (select custid from bodb02.dbo.f_DepSuper_1('ALL'))
	and CustID IN (SELECT CustID FROM @TempBACustID)*/
--////////END UPDATE BA STATUS/////////////////////////////////

ALTER INDEX [IX_winlostdate_bettype] ON bettrans REBUILD

--Record the status of latest table date ranges
INSERT INTO [bodb_Account].[dbo].[tbl_table_status]
           ([processdate]
           ,[bettrans_start]
           ,[bettrans_end]
           ,[bettrans14_start]
           ,[bettrans14_end]
           ,[staging_start]
           ,[staging_end])
SELECT        CURRENT_TIMESTAMP [processdate],
(SELECT min(winlostdate) a from bodb02.dbo.bettrans b with (nolock) where custid<>0 and status not in ('void','reject','running') and bettype<19999) a,
(SELECT max(winlostdate) a from bodb02.dbo.bettrans b with (nolock) where custid<>0 and status not in ('void','reject','running') and bettype<19999) b,
(SELECT min(winlostdate) a from bodb02.dbo.bettrans14 b with (nolock) where custid<>0 and status not in ('void','reject','running') and bettype<19999) c,
(SELECT max(winlostdate) a from bodb02.dbo.bettrans14 b with (nolock) where custid<>0 and status not in ('void','reject','running') and bettype<19999) d,
(SELECT min(winlostdate) a from bodb_Staging.dbo.bettrans b with (nolock) where custid<>0) e,
(SELECT max(winlostdate) a from bodb_Staging.dbo.bettrans b with (nolock) where custid<>0) f

GO
GRANT EXECUTE ON [dbo].[Task_PrepareStaging_Old] TO [VNTeam]
GO
GRANT VIEW DEFINITION ON [dbo].[Task_PrepareStaging_Old] TO [VNTeam]
