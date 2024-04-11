/*<info serverAlias="DBTXN-bodb02,SBSETTLE-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/
alter procedure [dbo].[Task_DBA_Settlement_Stats_Pull]
as
/*
	Created: Patrick@20240403	
	Task: Pull settlement stats
	DB: DBTXN-bodb02,SBSETTLE-bodb02
		
	Revisions:
		- 20240403@Patrick: Init [Redmine: #203132]

	Parameters Explanation:	
*/
begin
	set nocount on
	declare @__lastValue datetime2, @__maxValue datetime2, @__interval int = 1, @__siteDBGroupId smallint = 0
	declare @__temp table (matchid int, eventTable tinyint, tableType tinyint
		, logdate datetime2, matchCount int, affectedTicket int
		, siteDBGroupId smallint, sportName varchar(200), groupName varchar(200))

	set @__siteDBGroupId = 0
	if object_id('dbo.f_Get_SiteDBGroupID') is not null
	begin
		select @__siteDBGroupId = dbo.f_Get_SiteDBGroupID()
	end

	loop_pick_more:
	select @__lastValue = max(LogDate), @__maxValue = dateadd(second, -1, sysdatetime())
	from MonDB.dbo.Mon_Settlement_Stats with(nolock)

	if @__lastValue is null
		set @__lastValue = dateadd(hour, -1, sysdatetime())

	if datediff(minute, @__lastValue, @__maxValue) > @__interval
		set @__maxValue = dateadd(minute, 1, @__lastValue)
	else if datediff(minute, @__lastValue, @__maxValue) < @__interval
		return

	insert into @__temp(matchid, eventTable, tableType, siteDBGroupId
		, logdate, matchCount, affectedTicket)
	select MatchId, EventTable, TableType, SiteDBGroupId
		, max(StartTime) LogDate, count(distinct MatchId) MatchCount, sum(isnull(AffectedTicket, 0)) AffectedTicket
	from dbo.SSB_SettlementLogs l with(nolock)
	where StartTime > @__lastValue and StartTime <= @__maxValue
		and TableType in (1,2) --bettrans | bettransm
	group by MatchId, EventTable, TableType, siteDBGroupId

	if @@rowcount = 0 --no data in this interval
	begin
		insert into MonDB.dbo.Mon_Settlement_Stats([CaptureDate], [LogDate], [SportName], [GroupName], [TableType], [SiteDBGroupId], [AffectedTicket], [MatchCount])
		select getdate(), @__maxValue, null, null, null, null, null, null
		goto loop_pick_more
	end
		
	--match
	update t set sportName = s.SportName
		, groupName = iif(sm.productId = 1, 'Sports', 'Non Sports')
		, siteDBGroupId = iif(@__siteDBGroupId < 100 and @@servername != 'dbtrans', @__siteDBGroupId, siteDBGroupId)
	from @__temp t 
		inner join dbo.match m with(nolock) on t.matchid = m.matchid
		inner join dbo.Sports s with(nolock) on m.sporttype = s.SportType
		cross apply(
			select top 1 productId
			from dbo.SportBettypeMatrix sm with(nolock) where m.sporttype = sm.SportType
		)sm
	where t.eventTable = 1

	--match3rd
	update t set sportName = s.SportName
		, groupName = iif(sm.productId = 1, 'Sports', 'NonSports')
		, siteDBGroupId = iif(@__siteDBGroupId < 100 and @@servername != 'dbtrans', @__siteDBGroupId, siteDBGroupId)
	from @__temp t 
		inner join dbo.Match3rd m with(nolock) on t.matchid = m.Match3rdId
		inner join dbo.Sports s with(nolock) on m.sporttype = s.SportType
		cross apply(
			select top 1 productId
			from dbo.SportBettypeMatrix sm with(nolock) where m.sporttype = sm.SportType
		)sm
	where t.eventTable = 3

	--outright
	update t set sportName = s.SportName
		, groupName = iif(sm.productId = 1, 'Sports', 'NonSports')
		, siteDBGroupId = iif(@__siteDBGroupId < 100 and @@servername != 'dbtrans', @__siteDBGroupId, siteDBGroupId)
	from @__temp t 
		inner join dbo.outright m with(nolock) on t.matchid = m.orid
		inner join dbo.League l with(nolock) on m.leagueid = l.leagueid
		inner join dbo.Sports s with(nolock) on l.sporttype = s.SportType
		cross apply(
			select top 1 productId
			from dbo.SportBettypeMatrix sm with(nolock) where l.sporttype = sm.SportType
		)sm
	where t.eventTable = 2

	insert into MonDB.dbo.Mon_Settlement_Stats([CaptureDate], [LogDate], [SportName], [GroupName], [TableType], [SiteDBGroupId], [AffectedTicket], [MatchCount])
	select getdate(), max(logdate), sportName, groupName, tableType, siteDBGroupId, sum(affectedTicket), sum(matchCount)
	from @__temp
	group by sportName, groupName, tableType, siteDBGroupId

	delete from @__temp
	goto loop_pick_more
end
go
