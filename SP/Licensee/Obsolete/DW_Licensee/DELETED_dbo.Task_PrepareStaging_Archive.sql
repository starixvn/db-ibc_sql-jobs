ALTER PROC [dbo].[Task_PrepareStaging_Archive]  
    @datestart smalldatetime
    ,@dateend smalldatetime
AS  
/*
Created: 
Task : 
DB: DBLIC/bodb_Licensee
Original:
Revisions:
	- 20120423@Jim: Add more information for BARM Agent
	- 20130124@Daniel: Change link server alias
Param's Explanation:

*/
BEGIN

    declare @datefrom smalldatetime, @dateto smalldatetime
    select @datefrom = @datestart, @dateto = @dateend
    select @dateto = dateadd(day,1,@dateto)
	
	---------PROCESS OUTRIGHT DATA--------------------------------------------------------------------------------------------  
	TRUNCATE TABLE dbo.outright  
	
	INSERT INTO dbo.outright  
	(matchid, leagueid, groupmatch, homeid, awayid, eventdate, kickofftime, oddsstatus, odds, [status], risk, sporttype)  	
	SELECT     orid AS matchid, outright_bk.leagueid, groupmatch, teamid AS homeid, NULL AS awayid, eventdate, kickofftime, oddsstatus, odds, [status], risk, sporttype
	FROM         DBARC.bodb_Archive.dbo.outright_bk WITH(NOLOCK)
	    LEFT JOIN bodb02.dbo.league (NOLOCK) ON outright_bk.leagueid = league.leagueid
	WHERE eventdate >= @datefrom and eventdate < @dateto

	---------PROCESS MATCH DATA--------------------------------------------------------------------------------------------  
	TRUNCATE TABLE [dbo].[match]  
	
	INSERT INTO [dbo].[match]  
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
	from DBARC.bodb_Archive.dbo.match_bk m with (nolock)  
	where eventdate >= @datefrom and eventdate < @dateto
	  
	---------PROCESS BETTRANS DATA--------------------------------------------------------------------------------------------  
	TRUNCATE TABLE [bettrans]  
	  
	--ALTER INDEX [IX_winlostdate_bettype] ON bettrans DISABLE  
	  
	--Copy LIVE data (bettrans)  
	INSERT INTO dbo.bettrans
			   ([transid]
			   ,winlostdate
			   ,betfrom
			   ,liveindicator
			   ,bettype
			   ,[custid]
			   ,betteam
			   ,[stake]
			   ,actual_stake
			   ,[winlost],[awinlost],[mwinlost],swinlost
			   ,acomm,scomm,playercomm,comm
			   ,[tpositiontaking],spositiontaking,[mpositiontaking],[apositiontaking] 
			   ,matchid
			   ,[status]
			   ,[srecommend]
			   ,actualrate
			   ,currency
			   ,recommend,mrecommend
			   ,refno
			   ,transdate
			   ,statusid
			   ,virtualrate
			   ,isBA
			   ,discount
			   ,customercategory)  
	SELECT b.transid,b.winlostdate,b.betfrom,b.liveindicator,b.bettype,b.custid,b.betteam,  
	 case when winlostdate < '2011-09-01' then b.stake else abs(b.stake) end stake,
	 b.actual_stake,b.winlost,   
	 b.awinlost,  
	 b.mwinlost+case when b.bettype>30 and b.bettype<50 then b.swinlost else 0 end mwinlost,                       
	 case when b.bettype>30 and b.bettype<50 then (winlost-stake)*(1-tpositiontaking-isnull(oddsspread,0)) else b.swinlost end swinlost,   
	 acomm, scomm, playercomm, comm, case when b.bettype>30 and b.bettype<50 then 1-isnull(oddsspread,0) else b.tpositiontaking end tpositiontaking,   
	 b.spositiontaking,b.mpositiontaking,b.apositiontaking,b.matchid,  
	 CASE WHEN (b.bettype IN (1, 3, 7, 8, 17, 18) AND abs(b.modds) = 0.25 AND [status] IN('WON', 'LOSE')) or (b.bettype in (33,43) and [status] <> 'refund' and b.liveawayscore=0) THEN 'HALF ' ELSE '' END + b.status AS [status],   
	 srecommend, null actualrate, b.currency, b.recommend,mrecommend,b.refno,b.transdate  
	 ,statusid,virtualrate,convert(bit,0) isBA,discount,convert(int,-1) customercategory
	FROM         DBARC.bodb_Archive.dbo.bettrans_bk AS b WITH (NOLOCK)		
	WHERE     (b.custid <> 0) AND (b.status NOT IN ('VOID', 'REJECT', 'running','DONE'))  
		and not (currency=20 and b.bettype>30 and b.bettype<50) and winlostdate>=@datefrom and winlostdate<@dateto

	------PROCESS STATUS ID FOR HALF WON/LOSE
	UPDATE dbo.bettrans
	SET statusid=114
	WHERE [status] in ('half won')
	
	UPDATE dbo.bettrans
	SET statusid=115
	WHERE [status] in ('half lose')
	
	--Override commission setting to zero for 8RM AND BARM 
	update bettrans  
	set acomm=0,comm=0,scomm=0,playercomm=0,customercategory= CASE WHEN recommend= 52466 THEN 27 -- 8RM
											ELSE 28 END --BARM
	where recommend IN (52466, 5707545) 
	
	--///// PROCESS UPDATE BA STATUS FOR TICKETS ///////////////////
    DECLARE @BATransids AS TABLE (transID bigint)
    declare @currentDate datetime

    set @currentDate = current_timestamp

    INSERT @BATransids
        SELECT distinct transid
        from dbo.bettrans b WITH (NOLOCK)
	        inner join bodb_Licensee.dbo.LicenseeBAHistory h WITH (NOLOCK) 
		        on b.custid = h.custid and transdate between OnDate and ISNULL(OffDate, @currentDate)
        where Bettype NOT BETWEEN 31 AND 120
	        and tpositiontaking = 0
	        and SRecommend in (select custid from bodb02.dbo.f_DepSuper_1('ALL'))

    update dbo.bettrans set IsBA = 1
    where transid IN(select transid from @BATransids)
	
	--ALTER INDEX [IX_winlostdate_bettype] ON bettrans REBUILD  
	  
END
/*
select * from dbo.bettrans
where status in ('half won','half lose')
*/


GO
GRANT EXECUTE ON [dbo].[Task_PrepareStaging_Archive] TO [VNTeam] 
GO
GRANT VIEW DEFINITION ON [dbo].[Task_PrepareStaging_Archive] TO [VNTeam]