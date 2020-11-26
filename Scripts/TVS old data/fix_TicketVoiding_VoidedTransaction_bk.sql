declare @winlostdate smalldatetime =''
declare @row int=0, @id int =1

create table #date(id int identity(1,1), winlostdate smalldatetime)
insert into #date(winlostdate) values ('2019-02-12'),
('2019-02-25'),
('2019-03-05'),
('2019-03-07'),
('2019-03-22'),
('2019-03-28'),
('2019-04-10'),
('2019-04-12'),
('2019-04-22'),
('2019-05-07'),
('2019-05-27'),
('2019-09-03'),
('2019-10-27'),
('2019-10-31'),
('2019-11-02'),
('2019-11-03'),
('2019-11-10'),
('2019-11-12'),
('2019-11-13'),
('2019-11-30'),
('2019-12-03'),
('2019-12-16'),
('2019-12-19'),
('2019-12-31'),
('2020-02-25'),
('2020-05-14'),
('2020-06-11'),
('2020-06-16'),
('2020-06-23'),
('2020-07-17'),
('2020-07-21'),
('2020-08-27'),
('2020-09-17'),
('2020-10-04'),
('2020-10-05'),
('2020-10-06'),
('2020-10-20');

create table #SportBettypeMatrix(bettype smallint, ProductID tinyint)
insert into #SportBettypeMatrix(bettype,ProductID) select bettype,ProductID from bodb02.dbo.SportBettypeMatrix WITH (NOLOCK) where ProductID IN (1,3,5,25,27,37)

create table #bettrans_bk(transid bigint)
create table #bettrans_bk2(transid bigint)
create table #bettrans_bk3(transid bigint,matchid int)

select @winlostdate = winlostdate from #date where @id=id

while @winlostdate is not null
begin
	insert into #bettrans_bk(transid) select distinct b.transid from bettrans_bk b WITH (NOLOCK) join #SportBettypeMatrix s on b.bettype=s.bettype where b.statusID=102 and b.winlostdate = @winlostdate
		
	insert into #bettrans_bk2(transid) select distinct b.refno from bettrans_bk b WITH (NOLOCK) join #SportBettypeMatrix s on b.bettype=s.bettype where b.statusID=102 and s.bettype not in (29,9) and s.ProductID =1 and b.winlostdate = @winlostdate
				
	insert into #bettrans_bk3(transid,matchid) select distinct b.transid,b.matchid from mondb.dbo.brice_bettrans_bk b WITH (NOLOCK) where b.winlostdate = @winlostdate

	delete from TicketVoiding_VoidedTransaction_bk
	where id in
	(
	select Id
	FROM bodb02.dbo.TicketVoiding_VoidedTransaction AS t1 WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM #bettrans_bk AS t2 WITH (NOLOCK) WHERE t1.transid = t2.transid and t1.matchid=0)
			OR EXISTS (SELECT 1 FROM #bettrans_bk2 AS t2 WITH (NOLOCK) WHERE t1.transid = t2.transid)
			OR EXISTS (SELECT 1 FROM #bettrans_bk3 AS t2 WITH (NOLOCK) WHERE t1.transid = t2.transid AND t1.MatchId=t2.MatchId)
	);

	print('deleted '+ cast(@@rowcount as varchar))

	INSERT INTO	dbo.TicketVoiding_VoidedTransaction_bk
		(	TransId, MessageId, ReasonId, MatchId, CreatedDate, Id, IssueTypeID, SubIssueTypeID, CustID)
	SELECT	TransId, MessageId, ReasonId, MatchId, CreatedDate, Id, IssueTypeID, SubIssueTypeID, CustID
	FROM	bodb02.dbo.TicketVoiding_VoidedTransaction AS t1 WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM #bettrans_bk AS t2 WITH (NOLOCK) WHERE t1.transid = t2.transid and t1.matchid=0)
			OR EXISTS (SELECT 1 FROM #bettrans_bk2 AS t2 WITH (NOLOCK) WHERE t1.transid = t2.transid);

	set @row=@@ROWCOUNT

	--process for ticket sub parlay (sportbook and virtual sport)
	INSERT INTO	dbo.TicketVoiding_VoidedTransaction_bk
		(	TransId, MessageId, ReasonId, MatchId, CreatedDate, Id, IssueTypeID, SubIssueTypeID, CustID)
	SELECT	TransId, MessageId, ReasonId, MatchId, CreatedDate, Id, IssueTypeID, SubIssueTypeID, CustID
	FROM	bodb02.dbo.TicketVoiding_VoidedTransaction AS t1 WITH (NOLOCK)
	WHERE	EXISTS (SELECT 1 FROM #bettrans_bk3 AS t2 WITH (NOLOCK) WHERE t1.transid = t2.transid AND t1.MatchId=t2.MatchId);

	set @row=@row+@@ROWCOUNT

	print('inserted '+ cast(@row as varchar))

	set @id = @id+1
	select @winlostdate = winlostdate from #date where @id=id
	truncate table #bettrans_bk
	truncate table #bettrans_bk2
	truncate table #bettrans_bk3
end

/*<info serverAlias="DB06-bodb_archive"></info>*/