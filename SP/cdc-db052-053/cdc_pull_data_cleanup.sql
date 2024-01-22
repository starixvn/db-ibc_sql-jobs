/*<info serverAlias="DBAGE-bodb_age" executers="" isFunction="0" isNested="0"></info>*/
alter proc [dbo].[cdc_pull_data_cleanup]
as
/*
	Task: implement cdc for sum winloss
	DB: DBAGE-bodb_age
	Revision:
		20231201@Patrick: implement cdc for sum winloss [Redmine: #195357]
*/
begin
	set nocount on
	declare @__logdate datetime2, @__lsn binary(10)

	select @__logdate = dateadd(day, cast(isnull(VValue, '') as int) * -1, getdate())
	from dbo.SystemSettings with(nolock)
	where VName = 'cdc-retention-value'

	if @__logdate is null
		set @__logdate = dateadd(day, -14, sysdatetime())

	select @__lsn = max(fromLSN)
	from dbo.cdc_pull_data_batching_history with(nolock)
	where logdate < @__logdate

	if @__lsn is null
		return

	declare @__delaytime varchar(50) = '00:00:00:100'

	while 1 = 1 --bettrans
	begin
		delete top (3000)
		from dbo.cdc_bettrans with(rowlock)
		where __$start_lsn < @__lsn

		if @@rowcount = 0
			break
		select @__delaytime = dbo.f_dba_GetDelayTime('removeold')
		waitfor delay @__delaytime --cleanup@bettrans
	end


	while 1 = 1 --cdc_pull_data_batching_history
	begin
		delete top (3000)
		from dbo.cdc_pull_data_batching_history
		where logdate < @__logdate

		if @@rowcount = 0
			break

		select @__delaytime = dbo.f_dba_GetDelayTime('removeold')
		waitfor delay @__delaytime--cleanup@cdc_pull_data_batching_history

	end

end