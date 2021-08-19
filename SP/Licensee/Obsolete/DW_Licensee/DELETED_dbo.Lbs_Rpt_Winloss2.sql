 ALTER PROCEDURE DELETED_Lbs_Rpt_Winloss2
	@LicenseeID int,
	@Currency int = 0,
	@FromDate smalldatetime,
	@ToDate smalldatetime,
	@ShowSB bit = 1,  
	@ShowRB	bit = 0,  
	@ShowNG	bit = 0, 
	@ShowBA	bit = 0,
	@SportType tinyint=0,
	@BetType tinyint=0,
	@IsLive bit,
	@drawfilter SMALLINT = 1,
	@excludeTest BIT = 0,
	@ReportType tinyint = 1,
	@MoveBetsDay smalldatetime,
	@Debug bit =0
AS
/*
Created: Daniel
Task : Get winloss for a licensee

DB: DB052.bodb02  
Original:

Revisions:	
	
Param's Explanation:
	*@Currency
		-3: All - base MYR
		-2: All - base EURO
		-1: All - base USD
		>0: filter by a specific CurrencyID
	*@IsLive
		0: non live bet
		1: live bet
		NULL: all
	*@SportType
		0: all sport type
		>0: a specific sport type
	*@BetType
		0: all bet type
		>0: a particular bet type			
	*@ReportType
		1: Daily
		2: Weekly
		3: Monthly

	*@drawfilter: 'No Draw' filter is supportted (1:Normal 2:No Draw 3:No Draw for Turnover only)
	*@IsOld: 0 - query in table rptLicWinloss, 1 - query in table rptLicWinloss_old. 
	*@excludeTest: remove currency UUS
	*@showSB: Show SportsBook bets
	*@ShowRB: Show RB bets
	*@ShowNG: Show Number game bets
	*@ShowBA: Show Bet Aggregator bets (combined with Sportsbook or Number Game)
	*@MoveBetsDay: The day we move tickets to bettrans14

*/


select
	b.winlostdate,  
	b.currency,
	0 as sporttype,   
	--@turnover turnover, 
	SUM(winlost-actual_stake) Winlost,  
	-SUM(CASE WHEN ((bettype NOT BETWEEN 31 AND 120 ) AND bettype <=999 ) OR bettype BETWEEN 81 AND 120 THEN (winlost-actual_stake) ELSE 0 END) LicenseeWL,
	SUM(CASE WHEN bettype IN(31,32,33) THEN awinlost ELSE 0 END) WinlossRB,
	-SUM(winlost-actual_stake+awinlost+comm) AmountDueToBA,
	-SUM(CASE WHEN bettype IN(31,32,33) THEN (winlost-actual_stake+awinlost+comm) ELSE 0 END) AmountDueToRB,
	SUM(comm-playercomm) CommBA,
	SUM(CASE WHEN bettype IN(31,32,33) THEN (comm-playercomm) ELSE 0 END) CommRB
	--@BetCount BetCount	
FROM dbo.bettrans b WITH (NOLOCK)
	LEFT JOIN match m with (nolock) on b.matchid = m.matchid
	INNER JOIN bodb_Licensee.dbo.LicenseeCust l with (nolock) on b.recommend = l.custid and l.roleid = 2
	LEFT join dbo.exchangedaily e with (nolock) on b.winlostdate = e.exchangedate and b.currency = e.exchangeid
	LEFT JOIN bodb_Licensee.dbo.LicenseeBATransaction BA WITH (NOLOCK) ON b.transid = BA.transid
WHERE 
	b.bettype < 19000
	and b.ruben = 1
	and statusid NOT IN(101,102,103)
	--filters:
	AND winlostdate between '2011-7-1' AND '2011-7-26'
	and LicenseeID = 1
	and b.currency = 2--currency filter
	and ((bettype not BETWEEN 31 and 120) AND bettype<=999)--SB filter
	--and bettype between 31 and 33--Racing filter
	--and bettype between 81 and 120--Number Game filter
	and BA.transid IS NOT NULL --BA filter
	and sporttype = 1--sport filter (SB only)
	and bettype = 1--bettype filter
	and liveindicator = 0--live status filter
	and b.currency <> 20 --test data filter
GROUP BY winlostdate, b.currency, b.bettype

-------------------------------------
select
	winlostdate,  
	currency,
	--@turnover turnover, 
	SUM(Winlost) Winlost,  
	SUM(LicenseeWL) LicenseeWL,
	SUM(WinlossRB) WinlossRB,
	SUM(AmountDueToBA) AmountDueToBA,
	SUM(AmountDueToRB) AmountDueToRB,
	SUM(CommBA) CommBA,
	SUM(CommRB) CommRB
from
(
select
	b.winlostdate,  
	b.currency,
	LicenseeID,
	bettype,
	sporttype,
	liveindicator,
	BA.transid,
	--@turnover turnover, 
	winlost-actual_stake Winlost,  
	CASE WHEN ((bettype not BETWEEN 31 and 120 )and bettype <=999) OR bettype BETWEEN 81 AND 120 THEN (winlost-actual_stake) ELSE 0 END LicenseeWL,
	CASE WHEN bettype IN(31,32,33) THEN awinlost ELSE 0 END WinlossRB,
	-(winlost-actual_stake+awinlost+comm) AmountDueToBA,
	-(CASE WHEN bettype IN(31,32,33) THEN (winlost-actual_stake+awinlost+comm) ELSE 0 END) AmountDueToRB,
	comm-playercomm CommBA,
	CASE WHEN bettype IN(31,32,33) THEN (comm-playercomm) ELSE 0 END CommRB
	--@BetCount BetCount	
FROM dbo.bettrans b WITH (NOLOCK)
	LEFT JOIN match m with (nolock) on b.matchid = m.matchid
	INNER JOIN bodb_Licensee.dbo.LicenseeCust l with (nolock) on b.recommend = l.custid and l.roleid = 2
	LEFT join dbo.exchangedaily e with (nolock) on b.winlostdate = e.exchangedate and b.currency = e.exchangeid
	LEFT JOIN bodb_Licensee.dbo.LicenseeBATransaction BA WITH (NOLOCK) ON b.transid = BA.transid
WHERE
	b.bettype < 19000
	and b.ruben = 1
	and statusid NOT IN(101,102,103)
) b
WHERE 
	winlostdate between '2011-7-1' AND '2011-7-26'
	and LicenseeID = 1
	and b.currency = 2--currency filter
	and ((bettype not BETWEEN 31 and 120 ) and bettype <=999)--SB filter
	--and bettype between 31 and 33--Racing filter
	--and bettype between 81 and 120--Number Game filter
	and transid IS NOT NULL --BA filter
	and sporttype = 1--sport filter (SB only)
	and bettype = 1--bettype filter
	and liveindicator = 0--live status filter
	and b.currency <> 20 --test data filter
GROUP BY winlostdate, b.currency, b.bettype



-------------------
select
	rptdate winlostdate,  
	currency b.currency,
	LicenseeID,
	bettype,
	sporttype,
	liveindicator,
	BA.transid,
	--@turnover turnover, 
	winlost-actual_stake Winlost,  
	CASE WHEN ((bettype not between 31 and 120 ) and bettype <=999) OR bettype BETWEEN 81 AND 120 THEN (winlost-actual_stake) ELSE 0 END LicenseeWL,
	CASE WHEN bettype IN(31,32,33) THEN awinlost ELSE 0 END WinlossRB,
	-(winlost-actual_stake+awinlost+comm) AmountDueToBA,
	-(CASE WHEN bettype IN(31,32,33) THEN (winlost-actual_stake+awinlost+comm) ELSE 0 END) AmountDueToRB,
	comm-playercomm CommBA,
	CASE WHEN bettype IN(31,32,33) THEN (comm-playercomm) ELSE 0 END CommRB
	--@BetCount BetCount	
FROM dbo.bettrans b WITH (NOLOCK)
	LEFT JOIN match m with (nolock) on b.matchid = m.matchid
	INNER JOIN bodb_Licensee.dbo.LicenseeCust l with (nolock) on b.recommend = l.custid and l.roleid = 2
	LEFT join dbo.exchangedaily e with (nolock) on b.winlostdate = e.exchangedate and b.currency = e.exchangeid
	LEFT JOIN bodb_Licensee.dbo.LicenseeBATransaction BA WITH (NOLOCK) ON b.transid = BA.transid
WHERE
	b.bettype < 19000
	and b.ruben = 1
	and statusid NOT IN(101,102,103)











SET NOCOUNT ON  

DECLARE @sql nvarchar(max)

select @sql = 
'select 
	b.winlostdate,  
	b.srecommend,   
	b.currency,
	0 as sporttype,   
	--@turnover turnover, 
	SUM(winlost-actual_stake) Winlost,  
	-SUM(CASE WHEN ((bettype not between 31 and 120) and bettype<=999 ) OR bettype BETWEEN 81 AND 120 THEN (winlost-actual_stake) ELSE 0 END) LicenseeWL,
	SUM(CASE WHEN bettype IN(31,32,33) THEN awinlost ELSE 0 END) WinlossRB,
	-SUM(winlost-actual_stake+awinlost+comm) AmountDueToBA,
	-SUM(CASE WHEN bettype IN(31,32,33) THEN (winlost-actual_stake+awinlost+comm) ELSE 0 END) AmountDueToRB,
	SUM(comm-playercomm) CommBA,
	SUM(CASE WHEN bettype IN(31,32,33) THEN (comm-playercomm) ELSE 0 END) CommRB,
	@BetCount BetCount	
FROM dbo.bettrans b WITH (NOLOCK)
	LEFT JOIN match m with (nolock) on b.matchid = m.matchid
	INNER JOIN bodb_Licensee.dbo.LicenseeCust l with (nolock) on b.recommend = l.custid and l.roleid = 2
	LEFT join dbo.exchangedaily e with (nolock) on b.winlostdate = e.exchangedate and b.currency = e.exchangeid
	LEFT JOIN bodb_Licensee.dbo.LicenseeBATransaction BA WITH (NOLOCK) ON b.transid = BA.transid
where 
	winlostdate between @FromDate AND @ToDate
	and LicenseeID = @LicenseeID
	and b.bettype < 19000
	and ruben = 1
	and statusID NOT IN(101,102,103)
GROUP BY winlostdate, b.currency, b.bettype'

if (@debug = 1) 
	PRINT @sql
	
exec sp_executesql @sql





/*

exec [Acc_Rpt_NumberGameMemberWinlossByMatch]
	@date = '2011-7-5',
    @SiteID	= -1,
    @Currency = 0,
	@debug = 1

*/