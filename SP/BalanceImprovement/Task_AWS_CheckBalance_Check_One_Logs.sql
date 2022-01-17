/*<info serverAlias="DBTP-bodb02" executers="" viewers="" isNested="0"></info>*/
CREATE PROC [dbo].[Task_AWS_CheckBalance_Check_One_Logs] @custid int
/*
	Task: Check balance between DBTP & DBBAL
	Location: DBTP.bodb02
	Revision:
		- 20211231@Patrick: Split bettype >= 19999 out bettrans Redmine: [#164197]
*/
as
begin
	set nocount on
	declare @__maxtransid bigint
	create table #__temp1 (transid bigint, custid int, winlost money, actual_stake money, stake money, playercomm money, status varchar(50))
	create table #__temp2 (transid bigint, custid int, winlost money, actual_stake money, stake money, playercomm money, status varchar(50))

	--++bettrans
	select @__maxtransid = max(transid) from dbo.bettrans with(nolock)

	--get data from dbtp
	insert into #__temp1(transid, custid, winlost, actual_stake, stake, playercomm, status)
	select transid, custid, winlost, actual_stake, stake, playercomm, status 
	from bodb02.dbo.bettrans with(nolock) where custid = @custid and transid <= @__maxtransid and bettype < 19999
	
	--get data from dbbal
	insert into #__temp2(transid, custid, winlost, actual_stake, stake, playercomm, status)
	select transid, custid, winlost, actual_stake, stake, playercomm, status
	from DBAWS.bodb02.dbo.bettrans with(nolock) where custid = @custid and transid <= @__maxtransid and bettype < 19999

	insert into dbo.Task_AWS_Logs_Result(tableName, transid_tp, transid_bal, custid_tp, custid_bal, status_tp, status_bal, balance_tp, balance_bal)
	select 'bettrans', t1.transid, t2.transid, t1.custid, t2.custid, t1.status, t2.status
		, isnull(t1.winlost, 0) - isnull(t1.actual_stake, 0) + isnull(t1.playercomm, 0)
		, isnull(t2.winlost, 0) - isnull(t2.actual_stake, 0) + isnull(t2.playercomm, 0)
	from #__temp1 t1
	full outer join #__temp2 t2 on t1.transid = t2.transid
	where isnull(t1.winlost, 0) - isnull(t1.actual_stake, 0) + isnull(t1.playercomm, 0) <> isnull(t2.winlost, 0) - isnull(t2.actual_stake, 0) + isnull(t2.playercomm, 0)

	--++bettransLC
	set @__maxtransid = 0
	select @__maxtransid = max(transid) from dbo.bettransLC with(nolock)

	--get data from dbtp
	truncate table #__temp1
	insert into #__temp1(transid, custid, winlost, actual_stake, stake, playercomm, status)
	select transid, custid, winlost, actual_stake, stake, playercomm, status
	from bodb02.dbo.bettransLC with(nolock) where custid = @custid and transid <= @__maxtransid and IsSum = 0
	
	--get data from dbbal
	truncate table #__temp2
	insert into #__temp2(transid, custid, winlost, actual_stake, stake, playercomm, status)
	select transid, custid, winlost, actual_stake, stake, playercomm, status
	from DBAWS.bodb02.dbo.bettransLC with(nolock) where custid = @custid and transid <= @__maxtransid and IsSum = 0

	insert into dbo.Task_AWS_Logs_Result(tableName, transid_tp, transid_bal, custid_tp, custid_bal, status_tp, status_bal, balance_tp, balance_bal)
	select 'bettransLC', t1.transid, t2.transid, t1.custid, t2.custid, t1.status, t2.status
		, isnull(t1.winlost, 0) - isnull(t1.actual_stake, 0) + isnull(t1.playercomm, 0)
		, isnull(t2.winlost, 0) - isnull(t2.actual_stake, 0) + isnull(t2.playercomm, 0)
	from #__temp1 t1
	full outer join #__temp2 t2 on t1.transid = t2.transid
	where isnull(t1.winlost, 0) - isnull(t1.actual_stake, 0) + isnull(t1.playercomm, 0) <> isnull(t2.winlost, 0) - isnull(t2.actual_stake, 0) + isnull(t2.playercomm, 0)

	--++bettransRnG
	set @__maxtransid = 0
	select @__maxtransid = max(transid) from dbo.bettransRnG with(nolock)

	--get data from dbtp
	truncate table #__temp1
	insert into #__temp1(transid, custid, winlost, actual_stake, stake, playercomm, status)
	select transid, custid, winlost, actual_stake, stake, playercomm, status
	from bodb02.dbo.bettransRnG with(nolock) where custid = @custid and transid <= @__maxtransid and IsSum = 0
	
	--get data from dbbal
	truncate table #__temp2
	insert into #__temp2(transid, custid, winlost, actual_stake, stake, playercomm, status)
	select transid, custid, winlost, actual_stake, stake, playercomm, status
	from DBAWS.bodb02.dbo.bettransRnG with(nolock) where custid = @custid and transid <= @__maxtransid and IsSum = 0

	insert into dbo.Task_AWS_Logs_Result(tableName, transid_tp, transid_bal, custid_tp, custid_bal, status_tp, status_bal, balance_tp, balance_bal)
	select 'bettransRnG', t1.transid, t2.transid, t1.custid, t2.custid, t1.status, t2.status
		, isnull(t1.winlost, 0) - isnull(t1.actual_stake, 0) + isnull(t1.playercomm, 0)
		, isnull(t2.winlost, 0) - isnull(t2.actual_stake, 0) + isnull(t2.playercomm, 0)
	from #__temp1 t1
	full outer join #__temp2 t2 on t1.transid = t2.transid
	where isnull(t1.winlost, 0) - isnull(t1.actual_stake, 0) + isnull(t1.playercomm, 0) <> isnull(t2.winlost, 0) - isnull(t2.actual_stake, 0) + isnull(t2.playercomm, 0)

	--++translog
	set @__maxtransid = 0
	select @__maxtransid = max(translogid) from dbo.translog with(nolock)

	--get data from dbtp
	truncate table #__temp1
	insert into #__temp1(transid, custid, winlost, actual_stake, stake, playercomm, status)
	select translogid as transid, custid, 0 as winlost, actual_stake, stake, 0 as playercomm, status 
	from bodb02.dbo.translog with(nolock) where custid = @custid and translogid <= @__maxtransid and statusID in (0,1)
	
	--get data from dbbal
	truncate table #__temp2
	insert into #__temp2(transid, custid, winlost, actual_stake, stake, playercomm, status)
	select translogid as transid, custid, 0 as winlost, actual_stake, stake, 0 as playercomm, status
	from DBAWS.bodb02.dbo.translog with(nolock) where custid = @custid and translogid <= @__maxtransid and statusID in (0,1)

	insert into dbo.Task_AWS_Logs_Result(tableName, transid_tp, transid_bal, custid_tp, custid_bal, status_tp, status_bal, balance_tp, balance_bal)
	select 'translog', t1.transid, t2.transid, t1.custid, t2.custid, t1.status, t2.status
		, isnull(t1.winlost, 0) - isnull(t1.actual_stake, 0) + isnull(t1.playercomm, 0)
		, isnull(t2.winlost, 0) - isnull(t2.actual_stake, 0) + isnull(t2.playercomm, 0)
	from #__temp1 t1
	full outer join #__temp2 t2 on t1.transid = t2.transid
	where isnull(t1.winlost, 0) - isnull(t1.actual_stake, 0) + isnull(t1.playercomm, 0) <> isnull(t2.winlost, 0) - isnull(t2.actual_stake, 0) + isnull(t2.playercomm, 0)

	drop table #__temp1
	drop table #__temp2

end


