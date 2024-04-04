/*<info serverAlias="DBTXN-bodb02,SBSETTLE-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/
create procedure [dbo].[Task_DBA_Settlement_Stats_Remove]
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

	declare @__retention datetime2
	set @__retention = dateadd(day, -3, sysdatetime())

	while 1 = 1
	begin
		delete top(2000)
		from MonDB.dbo.Mon_Settlement_Stats with(rowlock)
		where LogDate < @__retention

		if @@rowcount = 0
			break
	end
end