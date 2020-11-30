declare @winlostdate smalldatetime =''
declare @row int=0, @id int =1

create table #date(id int identity(1,1), winlostdate smalldatetime)
insert into #date(winlostdate) values ('2019-08-23'),
('2020-06-10'),
('2017-01-03'),
('2017-06-12'),
('2017-06-13');

create table #SportBettypeMatrix(bettype smallint, ProductID tinyint)
insert into #SportBettypeMatrix(bettype,ProductID) select bettype,ProductID from bodb02.dbo.SportBettypeMatrix WITH (NOLOCK) where ProductID IN (1,3,5,25,27,37)

create table #bettransM_bk(transid bigint,matchid int)
create table #bettrans_bk(transid bigint)
select @winlostdate = winlostdate from #date where @id=id

while @winlostdate is not null
begin	
	insert into #bettransM_bk(transid,matchid) select distinct b.transid,b.matchid from bettransM b WITH (NOLOCK) where b.statusID=102 and b.winlostdate = @winlostdate 
	insert into #bettrans_bk(transid) select distinct b.transid from bettrans_bk b WITH (NOLOCK) join #SportBettypeMatrix s on b.bettype=s.bettype where b.statusID=102 and b.winlostdate = @winlostdate
	delete from zzzbettrans_bk
	where keyid in
	(
	SELECT keyid
	FROM	bodb02.dbo.zzzbettrans AS t1 WITH (NOLOCK)
		WHERE	EXISTS (SELECT 1 FROM #bettrans_bk AS t2 WITH (NOLOCK) WHERE t1.transid = t2.transid)
				OR EXISTS (SELECT 1 FROM #bettransm_bk AS t2 WITH (NOLOCK) WHERE t1.transid = t2.transid and t1.matchid=t2.matchid);
	);

	print(cast(@winlostdate as varchar)+' deleted '+ cast(@@rowcount as varchar))

	INSERT INTO	dbo.zzzbettrans_bk
			(	transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, STATUS, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, matchid, bettype, keyid, VoidingHistoryId)
		SELECT	transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, STATUS, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, matchid, bettype, keyid, VoidingHistoryId
		FROM	bodb02.dbo.zzzbettrans AS t1 WITH (NOLOCK)
		WHERE	EXISTS (SELECT 1 FROM #bettrans_bk AS t2 WITH (NOLOCK) WHERE t1.transid = t2.transid)
				OR EXISTS (SELECT 1 FROM #bettransm_bk AS t2 WITH (NOLOCK) WHERE t1.transid = t2.transid and t1.matchid=t2.matchid);


	print(cast(@winlostdate as varchar)+' inserted '+ cast(@@rowcount as varchar))

	set @id = @id+1
	select @winlostdate = winlostdate from #date where @id=id
	if @@rowcount=0
	begin
		break
	end
	truncate table #bettrans_bk
	truncate table #bettransM_bk
end

/*<info serverAlias="DB06-bodb_archive"></info>*/