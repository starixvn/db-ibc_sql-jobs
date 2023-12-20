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
		, @__rowcount int = 0, @__readBatch int = 100000

	while 1 = 1
	begin
		truncate table #__transIds

		if @TableName = 'bettrans'
		begin
			insert into #__transIds(transid)
			select top(@__readBatch) transid 
			from dbo.bettrans with(nolock) where SiteDBGroupID <> @NewSiteDBGroupId

			set @__rowcount = @@rowcount
		end
		else if @TableName = 'bettransm'
		begin
			insert into #__transIds(transid)
			select top(@__readBatch) transid 
			from dbo.bettransm with(nolock) where SiteDBGroupID <> @NewSiteDBGroupId

			set @__rowcount = @@rowcount
		end
		else if @TableName = 'bettransG'
		begin
			insert into #__transIds(transid)
			select top(@__readBatch) transid 
			from dbo.bettransG with(nolock) where SiteDBGroupID <> @NewSiteDBGroupId

			set @__rowcount = @@rowcount
		end
		else if @TableName = 'bettransLC'
		begin
			insert into #__transIds(transid)
			select top(@__readBatch) transid 
			from dbo.bettransLC with(nolock) where SiteDBGroupID <> @NewSiteDBGroupId

			set @__rowcount = @@rowcount
		end
		else if @TableName = 'bettransRnG'
		begin
			insert into #__transIds(transid)
			select top(@__readBatch) transid 
			from dbo.bettransRnG with(nolock) where SiteDBGroupID <> @NewSiteDBGroupId

			set @__rowcount = @@rowcount
		end
		else if @TableName = 'translog'
		begin
			insert into #__transIds(transid)
			select top(@__readBatch) translogid 
			from dbo.translog with(nolock) where SiteDBGroupID <> @NewSiteDBGroupId

			set @__rowcount = @@rowcount
		end
		else if @TableName = 'bettrans14'
		begin
			insert into #__transIds(transid)
			select top(@__readBatch) transid 
			from dbo.bettrans14 with(nolock) where SiteDBGroupID <> @NewSiteDBGroupId

			set @__rowcount = @@rowcount
		end
		else if @TableName = 'bettransm14'
		begin
			insert into #__transIds(transid)
			select top(@__readBatch) transid 
			from dbo.bettransm14 with(nolock) where SiteDBGroupID <> @NewSiteDBGroupId

			set @__rowcount = @@rowcount
		end
		else if @TableName = 'bettransG14'
		begin
			insert into #__transIds(transid)
			select top(@__readBatch) transid 
			from dbo.bettransG14 with(nolock) where SiteDBGroupID <> @NewSiteDBGroupId

			set @__rowcount = @@rowcount
		end
		else if @TableName = 'bettransLC14'
		begin
			insert into #__transIds(transid)
			select top(@__readBatch) transid 
			from dbo.bettransLC14 with(nolock) where SiteDBGroupID <> @NewSiteDBGroupId

			set @__rowcount = @@rowcount
		end
		else if @TableName = 'bettransRnG14'
		begin
			insert into #__transIds(transid)
			select top(@__readBatch) transid 
			from dbo.bettransRnG14 with(nolock) where SiteDBGroupID <> @NewSiteDBGroupId

			set @__rowcount = @@rowcount
		end
		else if @TableName = 'translog14'
		begin
			insert into #__transIds(transid)
			select top(@__readBatch) translogid 
			from dbo.translog14 with(nolock) where SiteDBGroupID <> @NewSiteDBGroupId

			set @__rowcount = @@rowcount
		end
		else if @TableName = 'zzbettrans'
		begin
			insert into #__transIds(transid)
			select top(@__readBatch) transid 
			from dbo.zzbettrans with(nolock) where SiteDBGroupID <> @NewSiteDBGroupId

			set @__rowcount = @@rowcount
		end
		else if @TableName = 'zzzbettransm'
		begin
			insert into #__transIds(transid)
			select top(@__readBatch) transid 
			from dbo.zzzbettransm with(nolock) where SiteDBGroupID <> @NewSiteDBGroupId

			set @__rowcount = @@rowcount
		end
		else if @TableName = 'TicketVoiding_RequestDetailTicket_Single'
		begin
			insert into #__transIds(transid)
			select top(@__readBatch) transid 
			from dbo.TicketVoiding_RequestDetailTicket_Single with(nolock) where SiteDBGroupID <> @NewSiteDBGroupId

			set @__rowcount = @@rowcount
		end
		else if @TableName = 'TicketVoiding_RequestDetailTicket_SubParlay'
		begin
			insert into #__transIds(transid)
			select top(@__readBatch) transid 
			from dbo.TicketVoiding_RequestDetailTicket_SubParlay with(nolock) where SiteDBGroupID <> @NewSiteDBGroupId

			set @__rowcount = @@rowcount
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