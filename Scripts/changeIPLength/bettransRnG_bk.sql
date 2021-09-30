/*<info serverAlias="DBARC-bodb_Archive" executers="" selecters="" viewers="" isFunction="0" isNested="0"></info>*/
---bettransRnG_bk
--++add new column
alter table bettransRnG_bk add ip_new varchar(45)

select min(winlostdate) from dbo.bettransRnG_bk

begin --update data
	set nocount on
	declare @__datefrom smalldatetime, @__dateto smalldatetime, @__message varchar(200)
	select @__datefrom = '??', @__dateto = '??'
	while @__datefrom <= @__dateto
	begin
		set @__message = '-- start currentdt: ' + convert(varchar(50), getdate(), 121) + ' --++@__datefrom: ' + convert(varchar(50), @__datefrom, 121)
		raiserror(@__message, 0, 1) with nowait

		while 1 = 1
		begin
			update top(3000) b set ip_new = [ip] 
			from dbo.bettransRnG_bk b with(rowlock)
			where winlostdate = @__datefrom 
				and ip_new is null
				and [ip] is not null

			if @@rowcount = 0
				break
		
			set @__message = '--===== currentdt: ' + convert(varchar(50), getdate(), 121)
			raiserror(@__message, 0, 1) with nowait
		end
	
		set @__message = '-- end currentdt: ' + convert(varchar(50), getdate(), 121) + ' --++@__datefrom: ' + convert(varchar(50), @__datefrom, 121)
		raiserror(@__message, 0, 1) with nowait
		set @__datefrom = dateadd(day, 1, @__datefrom)
	end
end
go

--UM
--exec sp_rename 'bettransRnG_bk.ip','ip_tmp', 'COLUMN'  
--exec sp_rename 'bettransRnG_bk.ip_new','ip', 'COLUMN'

go
