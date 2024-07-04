use bodb_archive
go

DECLARE @batchNo INT = 10000DECLARE @todate SMALLDATETIME = DATEADD(month, 6, GETDATE())
select count(1), min(eventdate), max(eventdate) from match_bk
select count(1) from odds_bk
select count(1) from bettrans_bk
select count(1) from bettransm
select count(1) from transfer_bk
select count(1) from match_remark


-- match_bk
BEGIN	 while (1=1)	 begin		 DELETE top (@batchNo)FROM match_bk WHERE eventdate < @todate		 if @@rowcount <> @batchNo			break	endEND-- odds_bk
BEGIN	 while (1=1)	 begin		 DELETE top (@batchNo)FROM odds_bk WHERE changetime < @todate		 if @@rowcount <> @batchNo			break	endEND-- bettrans_bk
BEGIN	 while (1=1)	 begin		 DELETE top (@batchNo)FROM bettrans_bk WHERE winlostdate < @todate		 if @@rowcount <> @batchNo			break	endEND-- bettransm
BEGIN	 while (1=1)	 begin		 DELETE top (@batchNo)FROM bettransm WHERE winlostdate < @todate		 if @@rowcount <> @batchNo			break	endEND-- transfer_bk
BEGIN	 while (1=1)	 begin		 DELETE top (@batchNo)FROM transfer_bk WHERE winlostdate < @todate		 if @@rowcount <> @batchNo			break	endEND-- match_remark
BEGIN	select matchid	into #tmpdeletedmatchid	from match_remark r	where not exists (select top 1 1 from match_bk m where m.matchid = r.matchid )	 while (1=1)	 begin		 DELETE top (@batchNo) r		 FROM match_remark r			inner join #tmpdeletedmatchid t				on r.matchid = t.matchid		 if @@rowcount <> @batchNo			break	end	drop table #tmpdeletedmatchidEND