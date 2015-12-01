
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.GEN_rptKPI_Account    Script Date: 12/1/2015 2:38:01 AM ******/


CREATE PROCEDURE [dbo].[GEN_rptKPI_Account]
    @datefrom datetime, 
    @dateto datetime = null
AS
/*
Created: 20110517@Daniel
Task: Generate data into rptKPI_Account from Staging and DB03.ON_USER.dbo.TotalOnline (refer to SP [Dot_Admin_GetTotalOnline_Report] for more detail)
DB: DB052.bodb_Licensee

Revisions:
    20110526@Don: Generate number of unique members that place bets and concurrent online members
    20111128@Don: New way to get Peak concurrent bettors
    20120425@Don: Add more licensees Tycoon,SG8 (SilverGoose8),Vwin and rename Suncity to Sungame
    20121128@Don: Get 'Peak concurrent bettors' from DB05.ON_USER
    20121204@Don: Just generate data for one day
    20130109@Daniel: Add Bwinning, ITCbet, LiveBet365
    20130523@Don: Add 'i668bet', 'i228bet', 'yq355', 'bcr999', 'lebao8888', 'wplace', 'mymbet'
	20130814@Don: Add 'Avia', '9Bet'
	20130903@Don: Add 'bet2day', 'W88'
	20131108@Don: Add '3star88', '67Bet' and 'SLC88'
	20131113@Don: Add 'JIBC'
	20131128@Don: Add livebetIDR
	20140114@Don:	(DB05.ON_USER)
					1. Add K8, 88Macao, Boma365, XTD1, Ole777, Salon365, Saloncs
					2. Remove i228bet, wplace (make mark)
	20140213@Don: (DB05.ON_USER) Add Wawabet, 368Cash
	20140331@Don: (DB05.ON_USER):	1. Add 88Macao,XTD2,Mgm88,Hbobet,Winner99,Ae88,HengCai88,Happy1668,Senibet,Royalebet,UUSS
									2. Change Wawabet id
	20140331@Don: (DB05.ON_USER) Add 18bbSmart and modify IBCSmart range
	20140501@Don: (DB05.ON_USER) Add BlueOcean,Allbetclub,Royal,AG,M8Bola
	20140523@Don: (DB05.ON_USER) Add THBET,Livv88(KeenOcean),9Club,XTD3,28bet
	20140606@Don: (DB05.ON_USER): Add LivebetKR,HONBET,Q8Bola,BE7,iBET
	20140611@Don: (DB05.ON_USER): Add IIBC
    
Param's Explanation:

*/

declare @date smalldatetime, @date2 smalldatetime

select @date = @datefrom, @date2 = @dateto
if @date2 is null select @date2 = @date
--select @date = CONVERT(varchar(10),@date,120), @date2 = CONVERT(varchar(10),@date2,120) 
select @date = CONVERT(varchar(10),@date2,120), @date2 = CONVERT(varchar(10),@date2,120) 
select @date2 = DATEADD(day,1,@date2)


delete dbo.rptKPI_Account where rptDate >= @date and rptDate < @date2


insert into dbo.rptKPI_Account(rptDate,[hour],siteid,UniqueBettorCount)
    select 
        convert(varchar(10),transdate,120) rptDate,
        datepart(hour,transdate) [hour],
        isnull(s.SiteID,-1) siteid,
        
        count(distinct bet.custid) UniqueBettorCount
    from dbo.bettrans bet (nolock)
        inner join bodb02.dbo.Customer cust (nolock) on bet.custid = cust.custid
        inner join bodb02.dbo.Customer cust_a (nolock) on cust.recommend = cust_a.custid
        left join bodb02.dbo.Site ibcsite with (nolock) on cust_a.site=ibcsite.site
	    left join dbo.view_site_list s with (nolock) on ibcsite.siteid=s.IbcSiteID
    where 
        transdate >= @date and transdate < @date2
        and bettype not between 31 and 120
        AND isBA = 0
    group by 
        convert(varchar(10),transdate,120),
        datepart(hour,transdate),
        isnull(s.SiteID,-1)


--
create table #PeakConcurrentBettors (KeyID int, LogHour tinyint PRIMARY KEY, TimeRange nvarchar(20), LocalTimeRange nvarchar(20), 
	IBC int NOT NULL default 0, 
	INDO int NOT NULL default 0, 
	[789y] int NOT NULL default 0, 
	XYZ int NOT NULL default 0,
	king int NOT NULL default 0, --king and 933
	trojan int NOT NULL default 0,
	[611] int NOT NULL default 0, 
	[822] int NOT NULL default 0, 
	[722] int NOT NULL default 0, 
	[733] int NOT NULL default 0, 
	[755] int NOT NULL default 0,
	[12Bet] int NOT NULL default 0,
	[A88] int NOT NULL default 0, 
	[IBCWAP] int NOT NULL default 0,
	[IBCMobile] int NOT NULL default 0, 
	[IBCSmart] int NOT NULL default 0, 
	[18bbSmart] int NOT NULL default 0, --101107,101108,101110
	Total int NOT NULL default 0, 
	others int NOT NULL default 0,
	[Admin] int NOT NULL default 0, 
	Agent int NOT NULL default 0,
	TotalGames int NOT NULL default 0, 
	TodayGames int NOT NULL default 0,
	LiveGames int NOT NULL default 0,
	MaxTotal int NOT NULL default 0,
	[M88] int NOT NULL default 0,
	[ALog] int NOT NULL default 0,
	[KORIBC] int NOT NULL default 0,	--serverid=121000
	[TLC] int NOT NULL default 0,
	[spondemo] int NOT NULL default 0,	--serverid=204000 - 204101
	[Dela] int NOT NULL default 0,		--serverid=206000 - 206103
	[Sungame] int NOT NULL default 0,	--serverid=207000 - 207103
	[Mayfair] int NOT NULL default 0,	--serverid=208000 - 208103
	[Zzun88] int NOT NULL default 0,	--serverid=209000 - 209103
	[Haifa] int NOT NULL default 0,		--serverid=211001 
	[bodog] int NOT NULL default 0,		--serverid=212000 - 212103
	[Tycoon] int NOT NULL default 0,	--serverid=215001 - 215103
	[SG8] int NOT NULL default 0,		--serverid=214001 - 214103
	[Vwin] int NOT NULL default 0,      --serverid=213001 
	[Macaubet] int NOT NULL default 0,  --serverid=217001 - 217103
	[IBOBet] int NOT NULL default 0,	--serverid=216001 - 216101
    [VCBET] int NOT NULL default 0,		--serverid=218001 - 218003
    [AonCash] int NOT NULL default 0,	--serverid=219001
   	[Bwinning] int NOT NULL default 0,	--serverid=220001 - 220103
	[ITCbet] int NOT NULL default 0,	--serverid=221001 - 221103
	[LiveBet365] int NOT NULL default 0, --serverid=222001 - 222103
	[i668bet] int NOT NULL default 0,	--serverid=228001
	[i228bet] int NOT NULL default 0,	--serverid=229001
	[yq355] int NOT NULL default 0,		--serverid=225001
	[bcr999] int NOT NULL default 0,	--serverid=226001
	[lebao8888] int NOT NULL default 0,	--serverid=227001
	[wplace] int NOT NULL default 0,	--serverid=223001
	[mymbet] int NOT NULL default 0,		--serverid=258001
	[Avia] int NOT NULL default 0,		--serverid=256001
	[9Bet] int NOT NULL default 0,		--serverid=260001 - 260103
	[bet2day] int NOT NULL default 0,	--serverid=265001 - 265103
	[W88] int NOT NULL default 0,		--serverid=257001
	[3star88] int NOT NULL default 0,	--serverid=263001
	[67Bet] int NOT NULL default 0,		--serverid=262001
	[SLC88] int NOT NULL default 0,		--serverid=264001
	[JIBC] int NOT NULL default 0,		--serverid=133000 
	[livebetIDR] int NOT NULL default 0,		--serverid=270001 - 270103
	[K8] int NOT NULL default 0,		--serverid=273001  
	[88Macao] int NOT NULL default 0,	--serverid=272001
	[Boma365] int NOT NULL default 0,	--serverid=271001
	[XTD1] int NOT NULL default 0,		--serverid=267001
	[Ole777] int NOT NULL default 0,	--serverid=266001
	[Salon365] int NOT NULL default 0,	--serverid=276001
	[Saloncs] int NOT NULL default 0,	--serverid=277001
	[Wawabet] int NOT NULL default 0,	--serverid=268001 - 268103
	[368Cash] int NOT NULL default 0,	--serverid=283001 - 283103 

	[XTD2] int NOT NULL default 0,		--269001 - 269103
	[Mgm88] int NOT NULL default 0,		--279001 - 279103
	[Hbobet] int NOT NULL default 0,	--280001 - 280103
	[Winner99] int NOT NULL default 0,	--268001 - 268103
	[Ae88] int NOT NULL default 0,		--281001 - 281103
	[HengCai88] int NOT NULL default 0,	--282001 - 282103
	[Happy1668] int NOT NULL default 0,	--284001 - 284103
	[Senibet] int NOT NULL default 0,	--286001 - 286103
	[Royalebet] int NOT NULL default 0,	--285001 - 285103
	[UUSS] int NOT NULL default 0,		--287001 - 287103
	[BlueOcean] int NOT NULL default 0, --288001 
	[Allbetclub] int NOT NULL default 0,--289001
	[Royal] int NOT NULL default 0,		--290001
	[AG] int NOT NULL default 0,		--291001
	[M8Bola] int NOT NULL default 0,		--292001
	[THBET] int NOT NULL default 0,		--293
	[Livv88] int NOT NULL default 0,	--294	rename :KeenOcean
	[9Club] int NOT NULL default 0,		--295
	[XTD3] int NOT NULL default 0,		--296
	[28bet] int NOT NULL default 0,		--297
	[LivebetKR] int NOT NULL default 0,	--298
	[HONBET] int NOT NULL default 0,	--299
	[Q8Bola] int NOT NULL default 0,	--300
	[BE7] int NOT NULL default 0,		--301
	[iBET] int NOT NULL default 0,		--302
	[IIBC] int NOT NULL default 0		--134
	)
create table #temp(rptDate datetime,LogHour tinyint,SiteName varchar(50),FullSiteName varchar(50),PeakBettorCount int)
	
declare @Sql varchar(500)
set @Sql = 
    'insert into #PeakConcurrentBettors
    select *
    from openquery(db05,''set fmtonly off exec ON_USER.dbo.Dot_Admin_GetTotalOnline_Report ''''' + convert(varchar(10),dateadd(day,-1,@date2),120) + ''''''')'
exec(@Sql)

insert into #temp
    select dateadd(day,-1,@date2) rptDate, LogHour,
        f.SiteName,f.FullSiteName,cast(f.Amount as int) PeakBettorCount
    from #PeakConcurrentBettors
        cross apply (
            select 'IBC','[IBC]', IBC union all 
            select 'INDO','INDO', INDO union all
            select '[789y]','789y', [789y] union all
            select 'XYZ','XYZBET',XYZ union all
            select 'king','[king]', king union all
            select 'trojan','[trojan]',trojan union all
            select '[611]','611111', [611] union all
            select '[822]','[822]', [822] union all
            select '[722]','722222', [722] union all
            select '[733]','733333', [733] union all
            select '[755]','755555',[755] union all
            select '[12Bet]','12Bet',[12Bet] union all
            select '[A88]','asiabet88', [A88] union all
            select '[IBCWAP]','[IBCWAP]',[IBCWAP] union all
            select '[IBCMobile]','[IBCMobile]', [IBCMobile] union all
            select '[IBCSmart]','[IBCSmart]', [IBCSmart] union all
			
			select '[18bbSmart]','[18bbSmart]', [18bbSmart] union all
            select 'Total','[Total]', Total union all
            select 'others','[others]',others union all
            select '[Admin]','[Admin]', [Admin] union all
            select 'Agent','[Agent]',Agent union all
            select 'TotalGames','[TotalGames]', TotalGames union all
            select 'TodayGames','[TodayGames]',TodayGames union all
            select 'LiveGames','[LiveGames]',LiveGames union all
            select 'MaxTotal','[MaxTotal]',MaxTotal union all
            select '[M88]','mansion88',[M88] union all
            select '[ALog]','alog',[ALog] union all
            select '[KORIBC]','KORIBC',[KORIBC] union all
            select '[TLC]','TLC',[TLC] union all
            select '[spondemo]','[spondemo]',[spondemo] union all
            select '[Dela]','DELA',	[Dela] union all
            select '[Sungame]','SunGame',[Sungame] union all
            select '[Mayfair]','MayFair',[Mayfair] union all
            select '[Zzun88]','Zzun88',[Zzun88] union all
            select '[Haifa]','HAIFA',[Haifa] union all
            select '[bodog]','Bodog',[bodog] union all
            select '[Tycoon]','Tycoon',[Tycoon] union all
            select '[SG8]','SG8',[SG8] union all
            select '[Vwin]','[Vwin]',[Vwin] union all
            select '[Macaubet]','Macaubet',[Macaubet] union all
            select '[IBOBet]','Ibobet',[IBOBet] union all
            select '[VCBET]','VCasia',[VCBET] union all
            select '[AonCash]','Aoncash',[AonCash] union all
            select '[Bwinning]','Bwinning',[Bwinning] union all
            select '[ITCbet]','ITCbet',[ITCbet] union all
            select '[LiveBet365]','LiveBet365',[LiveBet365] union all
            select '[i668bet]','i668bet',[i668bet] union all
            select '[i228bet]','i228bet',[i228bet] union all
            select '[yq355]','yq355',[yq355] union all
            select '[bcr999]','bcr999',[bcr999] union all
            select '[lebao8888]','lebao8888',[lebao8888] union all
            select '[wplace]','wplace',[wplace] union all
            select '[mymbet]','mymbet',[mymbet] union all
			select '[Avia]','Avia',[Avia] union all
            select '[9Bet]','9Bet',[9Bet] union all
			select '[bet2day]','bet2day',[bet2day] union all
            select '[W88]','W88',[W88] union all
			select '[3star88]','3star88',[3star88] union all
			select '[67Bet]','67Bet',[67Bet] union all
            select '[SLC88]','SLC88',[SLC88] union all
			select '[JIBC]','JIBC',[JIBC] union all
			select '[livebetIDR]','livebetIDR',[livebetIDR] union all
			select '[K8]','K8',[K8] union all
			select '[88Macao]','88Macao',[88Macao] union all
			select '[Boma365]','Boma365',[Boma365] union all
			select '[XTD1]','XTD1',[XTD1] union all
			select '[Ole777]','Ole777',[Ole777] union all
			select '[Salon365]','Salon365',[Salon365] union all
			select '[Saloncs]','Saloncs',[Saloncs] union all
			select '[Wawabet]','Wawabet',[Wawabet] union all
			select '[368Cash]','368Cash',[368Cash] union all
			
			select '[XTD2]','XTD2',[XTD2] union all 
			select '[Mgm88]','Mgm88',[Mgm88] union all
			select '[Hbobet]','Hbobet',[Hbobet] union all
			select '[Winner99]','Winner99',[Winner99] union all
			select '[Ae88]','Ae88',[Ae88] union all
			select '[HengCai88]','HengCai88',[HengCai88] union all
			select '[Happy1668]','Happy1668',[Happy1668] union all
			select '[Senibet]','Senibet',[Senibet] union all
			select '[Royalebet]','Royalebet',[Royalebet] union all
			select '[UUSS]','UUSS',[UUSS] union all
			select '[BlueOcean]','BlueOcean',[BlueOcean] union all
			select '[Allbetclub]','Allbetclub',[Allbetclub] union all
			select '[Royal]','Royal',[Royal] union all
			select '[AG]','AG',[AG] union all
			select '[M8Bola]','M8Bola',[M8Bola] union all
			select '[THBET]','THBET',[THBET] union all
			select '[Livv88]','Livv88',[Livv88] union all
			select '[9Club]','9Club',[9Club] union all
			select '[XTD3]','XTD3',[XTD3] union all
			select '[28bet]','28bet',[28bet] union all
			select '[LivebetKR]','LivebetKR',[LivebetKR] union all
			select '[HONBET]','HONBET',[HONBET] union all
			select '[Q8Bola]','Q8Bola',[Q8Bola] union all
			select '[BE7]','BE7',[BE7] union all
			select '[iBET]','iBET',[iBET] union all
			select '[IIBC]','IIBC',[IIBC]

        )f(SiteName,FullSiteName,Amount)

update acc
set acc.PeakBettorCount = isnull(b.PeakBettorCount,0)
from #temp b
    left join dbo.view_kpi_labels lbl on b.FullSiteName = lbl.LabelName
    inner join dbo.rptKPI_Account acc 
        on lbl.LabelID = acc.SiteID and b.LogHour = acc.Hour and acc.rptDate = dateadd(day,-1,@date2)
where lbl.resellerid <> 3 
    and b.FullSiteName in (
        '12Bet','asiabet88','alog','TLC','Bodog','W88',
        'mansion88','DELA','SunGame','MayFair','Zzun88',
        'HAIFA',
        'SG8','Tycoon','Macaubet','Ibobet','Aoncash','Bwinning','ITCBet','LiveBet365','i668bet','i228bet','yq355','bcr999','lebao8888','wplace','mymbet',
			'9Bet','bet2day','3star88','67Bet','livebetIDR',
        'VCasia','Avia', 'SLC88',
        'BEST-ODDS','INDO','XYZBET','611111','722222','733333','755555','222223','222225','222227','spotico','KORIBC',
        '789y',
		'JIBC',
		'K8','88Macao','Boma365','XTD1','Ole777','Salon365','Saloncs','Wawabet','368Cash',
		'XTD2','Mgm88','Hbobet','Winner99','Ae88','HengCai88','Happy1668','Senibet','Royalebet','UUSS','BlueOcean','Allbetclub','Royal','AG','M8Bola',
		'THBET', 'Livv88', '9Club', 'XTD3', '28bet', 'LivebetKR', 'HONBET', 'Q8Bola', 'BE7', 'iBET', 'IIBC')

drop table #temp
drop table #PeakConcurrentBettors

--update MTD table
exec dbo.GEN_RptKPI_MTD_Account
    @date = @date, 
    @date2 = @date2,
    @isBA = 0
    
/*exec [dbo].[GEN_RptKPI_MTD]
    @date = @date, 
    @date2 = @date2,
    @stattype = 3,
    @isBA = 0*/







GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT EXECUTE ON [dbo].[GEN_rptKPI_Account] TO [vnteam]
GO 
 GRANT VIEW DEFINITION ON [dbo].[GEN_rptKPI_Account] TO [vnteam]
GO 
 GRANT EXECUTE ON [dbo].[GEN_rptKPI_Account] TO [bodbLicenseeNet]
GO 
