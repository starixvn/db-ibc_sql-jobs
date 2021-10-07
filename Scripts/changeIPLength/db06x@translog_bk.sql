/*<info serverAlias="DBARC-bodb_Archive" executers="" selecters="" viewers="" isFunction="0" isNested="0"></info>*/
-- check space
use bodb_Archive

ALTER TABLE translog_bk
ADD IP_new varchar(45);

declare @msg varchar(100)
declare @rowcount int = 1, @i bigint = 0
declare @maxTranslogId bigint = (select max(translogId) from translog_bk with(nolock) where winlostdate ='2021-09-23')
declare @minTranslogId bigint = (select min(translogId) from translog_bk with(nolock))
print @maxTranslogId
set @i = @maxTranslogId -5000
while @maxTranslogId >= @minTranslogId
begin
	update translog_bk
	set IP_new = IP where translogId >= @i and translogId <= @maxTranslogId
	set @msg = CAST(@maxTranslogId as varchar) + ' - '+ CAST(@i as varchar)
	raiserror (@msg,0,1) with nowait
	set @maxTranslogId = @i
	set  @i = @maxTranslogId -5000
end

select top 100 * from translog_bk
-------------------------------------------------------------------------------------------------
go
