create proc DBA_Task_DR_Reset_SiteDBGroupId @NewSiteDBGroupId smallint = 0
	, @TableName varchar(200)
	, @Debug bit = 1
as
/*
	Task: Reset sitedbgroupid at DR site
*/
begin
	set nocount on
	drop table if exists #__transIds

	create table #__transIds(transid bigint, rowId int identity(1,1) primary key)
	declare @__rowId int, @__strTransIds varchar(max), @__message varchar(300)
		, @__rowcount int = 0, @__readBatch int = 500000

	while 1 = 1
	begin
		truncate table #__transIds

		if @TableName = 'bettrans' and object_id('bettrans') is not null
		begin
			insert into #__transIds(transid)
			select top(@__readBatch) transid 
			from dbo.bettrans with(nolock) where SiteDBGroupID <> @NewSiteDBGroupId

			set @__rowcount = @@rowcount
		end
		else if @TableName = 'bettransm' and object_id('bettransm') is not null
		begin
			insert into #__transIds(transid)
			select top(@__readBatch) transid 
			from dbo.bettransm with(nolock) where SiteDBGroupID <> @NewSiteDBGroupId

			set @__rowcount = @@rowcount
		end
		else if @TableName = 'bettransG' and object_id('bettransG') is not null
		begin
			insert into #__transIds(transid)
			select top(@__readBatch) transid 
			from dbo.bettransG with(nolock) where SiteDBGroupID <> @NewSiteDBGroupId

			set @__rowcount = @@rowcount
		end
		else if @TableName = 'bettransLC' and object_id('bettransLC') is not null
		begin
			insert into #__transIds(transid)
			select top(@__readBatch) transid 
			from dbo.bettransLC with(nolock) where SiteDBGroupID <> @NewSiteDBGroupId

			set @__rowcount = @@rowcount
		end
		else if @TableName = 'bettransRnG' and object_id('bettransRnG') is not null
		begin
			insert into #__transIds(transid)
			select top(@__readBatch) transid 
			from dbo.bettransRnG with(nolock) where SiteDBGroupID <> @NewSiteDBGroupId

			set @__rowcount = @@rowcount
		end
		else if @TableName = 'translog' and object_id('translog') is not null
		begin
			insert into #__transIds(transid)
			select top(@__readBatch) translogid 
			from dbo.translog with(nolock) where SiteDBGroupID <> @NewSiteDBGroupId

			set @__rowcount = @@rowcount
		end
		else if @TableName = 'bettrans14' and object_id('bettrans14') is not null
		begin
			insert into #__transIds(transid)
			select top(@__readBatch) transid 
			from dbo.bettrans14 with(nolock) where SiteDBGroupID <> @NewSiteDBGroupId

			set @__rowcount = @@rowcount
		end
		else if @TableName = 'bettransm14' and object_id('bettransm14') is not null
		begin
			insert into #__transIds(transid)
			select top(@__readBatch) transid 
			from dbo.bettransm14 with(nolock) where SiteDBGroupID <> @NewSiteDBGroupId

			set @__rowcount = @@rowcount
		end
		else if @TableName = 'bettransG14' and object_id('bettransG14') is not null
		begin
			insert into #__transIds(transid)
			select top(@__readBatch) transid 
			from dbo.bettransG14 with(nolock) where SiteDBGroupID <> @NewSiteDBGroupId

			set @__rowcount = @@rowcount
		end
		else if @TableName = 'bettransLC14' and object_id('bettransLC14') is not null
		begin
			insert into #__transIds(transid)
			select top(@__readBatch) transid 
			from dbo.bettransLC14 with(nolock) where SiteDBGroupID <> @NewSiteDBGroupId

			set @__rowcount = @@rowcount
		end
		else if @TableName = 'bettransRnG14' and object_id('bettransRnG14') is not null
		begin
			insert into #__transIds(transid)
			select top(@__readBatch) transid 
			from dbo.bettransRnG14 with(nolock) where SiteDBGroupID <> @NewSiteDBGroupId

			set @__rowcount = @@rowcount
		end
		else if @TableName = 'translog14' and object_id('translog14') is not null
		begin
			insert into #__transIds(transid)
			select top(@__readBatch) translogid 
			from dbo.translog14 with(nolock) where SiteDBGroupID <> @NewSiteDBGroupId

			set @__rowcount = @@rowcount
		end
		else if @TableName = 'zzzbettrans' and object_id('zzzbettrans') is not null
		begin
			insert into #__transIds(transid)
			select top(@__readBatch) transid 
			from dbo.zzzbettrans with(nolock) where SiteDBGroupID <> @NewSiteDBGroupId
			group by transid

			set @__rowcount = @@rowcount
		end
		else if @TableName = 'zzzbettransm' and object_id('zzzbettransm') is not null
		begin
			insert into #__transIds(transid)
			select top(@__readBatch) transid 
			from dbo.zzzbettransm with(nolock) where SiteDBGroupID <> @NewSiteDBGroupId
			group by transid

			set @__rowcount = @@rowcount
		end
		else if @TableName = 'TicketVoiding_RequestDetailTicket_Single' and object_id('TicketVoiding_RequestDetailTicket_Single') is not null
		begin
			insert into #__transIds(transid)
			select top(@__readBatch) transid 
			from dbo.TicketVoiding_RequestDetailTicket_Single with(nolock) where SiteDBGroupID <> @NewSiteDBGroupId
			group by TransId

			set @__rowcount = @@rowcount
		end
		else if @TableName = 'TicketVoiding_RequestDetailTicket_SubParlay' and object_id('TicketVoiding_RequestDetailTicket_SubParlay') is not null
		begin
			insert into #__transIds(transid)
			select top(@__readBatch) transid 
			from dbo.TicketVoiding_RequestDetailTicket_SubParlay with(nolock) where SiteDBGroupID <> @NewSiteDBGroupId
			group by TransId

			set @__rowcount = @@rowcount
		end
		else
		begin
			select 'this table ['+@TableName+'] does not exist.!' as 'MessageInfo'
		end

		if @__rowcount = 0
			return

		select @__rowId = 1
		while 1 = 1
		begin
				
			set @__strTransIds = null
			set @__strTransIds = (
				select transid as t
				from #__transIds 
				where rowId >= @__rowId AND rowId < @__rowId + 2000
				for xml raw ('r'), root ('root')
			)

			if isnull(@__strTransIds, '') = ''
				break

			--call sp except here
			--todo: please double check content of SP before run
			if @TableName in ('bettrans', 'bettransLC', 'bettransRnG', 'bettransM', 'bettransG', 'translog')
			begin
				exec dbo.ExecRep_NAP_Admin_09 @transIds = @__strTransIds
					, @SiteDBGroupID = @NewSiteDBGroupId
					, @tablename = @TableName
			end
			else
			begin
				exec dbo.Bet_ExecRep14_00 @transIds = @__strTransIds
					, @SiteDBGroupID = @NewSiteDBGroupId
					, @tablename = @TableName
			end
			select @__rowId += 2000
			
		end
		select @__message = 'table: ' + @TableName + ' - dt: ' + convert(varchar(50), getdate(), 121)
		if @Debug = 1
		begin
			raiserror(@__message, 0, 1) with nowait
		end
		waitfor delay '00:00:00:020' --waitfor update bet sitedb groupid

	end
end