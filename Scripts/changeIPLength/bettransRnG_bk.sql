/*<info serverAlias="DBARC-bodb_Archive" executers="" selecters="" viewers="" isFunction="0" isNested="0"></info>*/
---bettransRnG_bk
--++add new column
alter table bettransRnG_bk add ip_new varchar(45)

select min(winlostdate) '@__datefrom' from dbo.bettransRnG_bk

begin --update data
	set nocount on
	declare @__winlostdate smalldatetime, @__minWinlostdate smalldatetime, @__message varchar(200)
	select @__winlostdate = '2021-09-23', @__minWinlostdate = '2018-01-01'
	while @__winlostdate >= @__minWinlostdate
	begin
		set @__message = '-- start currentdt: ' + convert(varchar(50), getdate(), 121) + ' --++@__winlostdate: ' + convert(varchar(50), @__winlostdate, 121)
		raiserror(@__message, 0, 1) with nowait

		while 1 = 1
		begin
			update top(5000) b set ip_new = [ip] 
			from dbo.bettransRnG_bk b with(rowlock)
			where winlostdate = @__datefrom 
				and ip_new is null
				and [ip] is not null

			if @@rowcount = 0
				break
		
			set @__message = '--===== currentdt: ' + convert(varchar(50), getdate(), 121)
			raiserror(@__message, 0, 1) with nowait
		end
	
		set @__message = '-- end currentdt: ' + convert(varchar(50), getdate(), 121) + ' --++@__winlostdate: ' + convert(varchar(50), @__winlostdate, 121)
		raiserror(@__message, 0, 1) with nowait
		set @__winlostdate = dateadd(day, -1, @__winlostdate)
	end
end
go

go
