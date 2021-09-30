-- check space


use bodb_Archive

ALTER TABLE translog_bk
ADD IP_new varchar(45);

create table #tmp (translogId bigint)

declare @rowcount int = 1, @i bigint = 0
declare @maxTranslogId bigint = (select max(translogId) from translog_bk with(nolock) where winlostdate ='2021-08-31')
print @maxTranslogId
while @rowcount != 0
begin
	truncate table #tmp
	insert into #tmp select top 5000 translogId from translog_bk with(nolock) where translogid> @i
	set @i = (select max(translogId) from #tmp)
	update translog_bk
	set IP_new = IP where translogId in (select translogId from #tmp)
	set @rowcount = @@ROWCOUNT
	raiserror ('%d',0,1,@i) with nowait
end
print @i --need to save for next run
drop table #tmp
select top 100 * from translog_bk
-------------------------------------------------------------------------------------------------
go
begin transaction
	create table #tmp (translogId bigint)
	declare @rowcount int = 1, @i bigint = xxx
	while @rowcount != 0
	begin
		truncate table #tmp
		insert into #tmp select top 5000 translogId from translog_bk with(nolock) where translogid> @i
		set @i = (select max(translogId) from #tmp)
		update translog_bk
		set IP_new = IP where translogId in (select translogId from #tmp)
		set @rowcount = @@ROWCOUNT
	end

	exec sp_rename 'translog_bk.IP','IP_tmp', 'COLUMN';  
	exec sp_rename 'translog_bk.IP_new','IP', 'COLUMN';  
commit

ALTER TABLE translog_bk
drop IP_tmp