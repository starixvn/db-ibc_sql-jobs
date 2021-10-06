/*<info serverAlias="DBARC-bodb_Archive" executers="" selecters="" viewers="" isFunction="0" isNested="0"></info>*/
-- check space
use bodb_Archive

ALTER TABLE bettransLC_bk
ADD IP_new varchar(45);


declare @rowcount int = 1, @msg varchar(500)
	, @begindate smalldatetime = '2021-09-23', @enddate smalldatetime =(select min(winlostdate) from bettransLC_bk (nolock))

while @begindate >= @enddate
begin
	set @rowcount = 1
	while @rowcount != 0
	begin
		update top(5000) bettransLC_bk set IP_new = IP where IP_new is null and IP is not null and winlostdate = @begindate
		set @rowcount = @@ROWCOUNT
	end
	set @msg = convert(varchar(50), @begindate, 121)
	raiserror (@msg,0,1,@rowcount) with nowait
	set @begindate = dateadd(d,-1,@begindate)
end

select top 100 * from bettransLC_bk
-------------------------------------------------------------------------------------------------
go

declare @rowcount int = 1, @msg varchar(500)
, @begindate smalldatetime = xxx, @enddate smalldatetime =yyy
while @begindate <= @enddate
begin
	set @rowcount = 1
	while @rowcount != 0
	begin
		update top(5000) bettransLC_bk set IP_new = IP where IP_new is null and IP is not null and winlostdate = @begindate
		set @rowcount = @@ROWCOUNT
	end
	set @msg = convert(varchar(50), @begindate, 121)
	raiserror (@msg,0,1,@rowcount) with nowait
	set @begindate = dateadd(d,1,@begindate)
end
begin transaction
	exec sp_rename 'bettransLC_bk.IP','IP_tmp', 'COLUMN';  
	exec sp_rename 'bettransLC_bk.IP_new','IP', 'COLUMN';  
commit

ALTER TABLE bettransLC_bk
drop column IP_tmp