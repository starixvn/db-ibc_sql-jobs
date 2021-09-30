-- check space


use bodb_Archive

ALTER TABLE bettransLC_bk
ADD IP_new varchar(39);

declare @rowcount int = 1
while @rowcount != 0
begin
	update top(5000) bettransLC_bk set IP_new = IP where IP_new is null
	set @rowcount = @@ROWCOUNT
	--raiserror ('%d',0,1,@rowcount) with nowait
end


select top 100 * from bettransLC_bk
-------------------------------------------------------------------------------------------------
go
begin transaction
	declare @rowcount int = 1
	while @rowcount != 0
	begin
		update top(5000) bettransLC_bk set IP_new = IP where IP_new is null
		set @rowcount = @@ROWCOUNT
		--raiserror ('%d',0,1,@rowcount) with nowait
	end

	exec sp_rename 'bettransLC_bk.IP','IP_tmp', 'COLUMN';  
	exec sp_rename 'bettransLC_bk.IP_new','IP', 'COLUMN';  
commit

ALTER TABLE bettransLC_bk
drop IP_tmp