alter procedure [dbo].[ExecRep_APL_09] @eventIds varchar(max)
as
/*
	Task - Manual remove data on VSRaceInfo
	DB02.bodb02
	Revisions:
		- 20200625@patrick:	Prepare script to remove data on VSRaceInfo - [Redmine: #135963]
*/

begin
	set nocount on
	-- check existing table
	if not exists (
		select 1 from sys.objects where name = 'VSRaceInfo' AND type = 'U'
	)
	begin
		return
	end
		
	declare @xml xml = convert(xml, replace('<root><r t="' + @eventIds + '"/></root>', '^', '"/><r t="'))

	declare @__tblEventIds TABLE (eventId int primary key)
	insert @__tblEventIds(eventId)
	select T.C.value('./@t', 'int') as id
	from @xml.nodes('//r') AS T(C)
	option (OPTIMIZE for (@xml = NULL))

	if @@rowcount = 0
		return

	delete r
	from dbo.VSRaceInfo r with(rowlock)
	where exists (
		select top 1 1
		from @__tblEventIds t where r.EventID = t.eventId
	)
end
go
/*<info serverAlias="DBPRO-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/