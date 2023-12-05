
create proc [dbo].[cdc_pull_data_bettrans]
as
/*
	task: pull cdc data to another place
*/
begin
	set nocount on
	declare @__tableName varchar(200) = 'bettrans',
		@__from_lsn binary(10),
		@__to_lsn binary(10),
		@__pageIndex int = 1,
		@__pageSize int = 5000,
		@__loop bit = 0,
		@__from_lsn_out binary(10),
		@__to_lsn_out binary(10),
		@__totalRows bigint = 0,
		@__totalRows_out bigint = 0,
		@__sqlCommand nvarchar(max) = '',
		@__waitfordelay varchar(50),
		@__rowCount int = 0

	select @__from_lsn = fromLSN
		, @__to_lsn = toLSN
		, @__pageIndex = isnull(pageIndex, 1)
		, @__totalRows = isnull(totalRows, 0)
	from dbo.cdc_pull_data_batching with(nolock) 
	where tableName = @__tableName

	if ((@__pageIndex - 1) * @__pageSize) >= @__totalRows
	begin
		set @__pageIndex = 1
	end
	
	set @__sqlCommand = '
set nocount on
	
if @__from_lsn is null
begin
	set @__from_lsn = sys.fn_cdc_get_min_lsn(''{{tabName}}'')
end
else if @__pageIndex = 1 and @__to_lsn is not null -- new round
begin
	set @__from_lsn = sys.fn_cdc_increment_lsn(@__to_lsn)
	set @__to_lsn = sys.fn_cdc_get_max_lsn()
end

if @__to_lsn is null
begin
	set @__to_lsn = sys.fn_cdc_get_max_lsn()
end

if @__pageIndex = 1 -- start new round
begin
	select @__totalRows_out = count_big(1)
	from cdc.cdc_{{tabName}}_CT with(nolock)
	where __$start_lsn >= @__from_lsn
		and __$start_lsn <= @__to_lsn

	if @__totalRows_out > 1000000
	begin
		create table #__batch(batchNo int, minId binary(10), maxId binary(10))

		insert into #__batch(batchNo, minId, maxId)
		select batchNo
			, min(__$start_lsn) as minId	
			, max(__$start_lsn) as maxId			
		from (
			select n.batchNo, b.__$start_lsn
			from (
				select __$start_lsn, row_number() over (order by __$start_lsn, __$command_id, __$seqval, __$operation) as rn
				from cdc.dbo_{{tabName}}_CT with(nolock)
				where  __$start_lsn >= @__from_lsn
					and __$start_lsn <= @__to_lsn
			)b
			cross apply (	
				select ((b.rn - 1) /1000000) + 1 AS batchNo
			)n
		)b
		group by batchNo
		order by batchNo

		select top(1) @__from_lsn = minId, @__to_lsn = maxId
		from #__batch order by batchNo

		select @__totalRows_out = count_big(1)
		from cdc.cdc_{{tabName}}_CT with(nolock)
		where __$start_lsn >= @__from_lsn
			and __$start_lsn <= @__to_lsn
		
	end
	
end
else -- continue ...
begin
	set @__totalRows_out = @__totalRows
end

select @__from_lsn_out = @__from_lsn, @__to_lsn_out = @__to_lsn

if @__totalRows_out > @__pageSize --reads data by offset
begin
	set @__loop = 1
	select [__$start_lsn],[__$end_lsn],[__$seqval],[__$operation],[__$update_mask],[transid],[custid],[transdate],[odds],[stake],[status],[winlost],[awinlost],[mwinlost],[playercomm],[comm],[acomm],[apositiontaking],[mpositiontaking],[tpositiontaking],[playerdiscount],[discount],[adiscount],[liveindicator],[betteam],[refno],[winlostdate],[oddsspread],[actualrate],[matchid],[recommend],[mrecommend],[betid],[modds],[bettype],[betdaqid],[actual_stake],[currency],[sdiscount],[scomm],[spositiontaking],[swinlost],[srecommend],[statusID],[SettlementTime],[epositiontaking],[__$command_id]
		, sys.fn_cdc_map_lsn_to_time(__$start_lsn) ActionDate
	from cdc.cdc_{{tabName}}_CT with(nolock)
	where __$start_lsn >= @__from_lsn
		and __$start_lsn <= @__to_lsn
	order by __$start_lsn, __$command_id, __$seqval, __$operation
	offset (@__pageIndex - 1) * @__pageSize rows fetch next @__pageSize rows only
end
else
begin
	select [__$start_lsn],[__$end_lsn],[__$seqval],[__$operation],[__$update_mask],[transid],[custid],[transdate],[odds],[stake],[status],[winlost],[awinlost],[mwinlost],[playercomm],[comm],[acomm],[apositiontaking],[mpositiontaking],[tpositiontaking],[playerdiscount],[discount],[adiscount],[liveindicator],[betteam],[refno],[winlostdate],[oddsspread],[actualrate],[matchid],[recommend],[mrecommend],[betid],[modds],[bettype],[betdaqid],[actual_stake],[currency],[sdiscount],[scomm],[spositiontaking],[swinlost],[srecommend],[statusID],[SettlementTime],[epositiontaking],[__$command_id]
		, sys.fn_cdc_map_lsn_to_time(__$start_lsn) ActionDate
	from cdc.cdc_{{tabName}}_CT with(nolock)
	where __$start_lsn >= @__from_lsn
		and __$start_lsn <= @__to_lsn
	order by __$start_lsn, __$command_id, __$seqval, __$operation
end'

	set @__sqlCommand = replace(@__sqlCommand, '{{tabName}}', @__tableName)

	begin try
	insert into dbo.cdc_bettrans([__$start_lsn],[__$end_lsn],[__$seqval],[__$operation],[__$update_mask],[transid],[custid],[transdate],[odds],[stake],[status],[winlost],[awinlost],[mwinlost],[playercomm],[comm],[acomm],[apositiontaking],[mpositiontaking],[tpositiontaking],[playerdiscount],[discount],[adiscount],[liveindicator],[betteam],[refno],[winlostdate],[oddsspread],[actualrate],[matchid],[recommend],[mrecommend],[betid],[modds],[bettype],[betdaqid],[actual_stake],[currency],[sdiscount],[scomm],[spositiontaking],[swinlost],[srecommend],[statusID],[SettlementTime],[epositiontaking],[__$command_id], [ActionDate])
	execute bodb02.dbo.sp_executesql @__sqlCommand
		, N'@__from_lsn binary(10), @__to_lsn binary(10), @__pageSize int, @__pageIndex int, @__loop bit output, @__from_lsn_out binary(10) output, @__to_lsn_out binary(10) output, @__totalRows bigint, @__totalRows_out bigint output'
		, @__from_lsn = @__from_lsn, @__to_lsn = @__to_lsn
		, @__pageSize = @__pageSize, @__pageIndex = @__pageIndex
		, @__loop = @__loop output, @__from_lsn_out = @__from_lsn_out output, @__to_lsn_out = @__to_lsn_out output, @__totalRows = @__totalRows, @__totalRows_out = @__totalRows_out output
	
	set @__rowCount = @@rowcount
	end try
	begin catch
		print error_message()
		raiserror('having an issue. please check.', 16, 1)
		return
	end catch

	if @__loop = 0
	begin
		update dbo.cdc_pull_data_batching
		set fromLSN = @__from_lsn_out, toLSN = @__to_lsn_out, totalRows = @__totalRows_out
			, [loop] = @__loop, pageIndex = 1
		where tableName = @__tableName
	end
	else
	begin
		update dbo.cdc_pull_data_batching
		set [loop] = @__loop, pageIndex = @__pageIndex + 1, totalRows = @__totalRows_out
			, fromLSN = @__from_lsn_out, toLSN = @__to_lsn_out
		where tableName = @__tableName
	end

	if @__rowCount = 0
	begin
		select @__waitfordelay = dbo.f_dba_GetDelayTime('nodata')
		waitfor delay @__waitfordelay --cdc pull nodata@bettrans (2)
		return
	end
end
GO