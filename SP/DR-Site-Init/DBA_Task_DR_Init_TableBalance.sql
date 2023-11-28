create proc DBA_Task_DR_Init_TableBalance
as
/*
	Task: init data for 8 table balance at DR site
*/
begin
	set nocount on

	begin --get exception list
		--truncate table dbo.Task_Cust_CheckBalance_Exception

		insert into dbo.Task_Cust_CheckBalance_Exception
		select custid, 'DWLList'
		from DBCUST.CustDB.dbo.Acc_DWLList dw with(nolock)
		where custid not in (select custid from dbo.Task_Cust_CheckBalance_Exception ce with(nolock))
		group by custid
		union all
		SELECT custid, 'DWLList_ExtraPT'
		from DBCUST.CustDB.dbo.Acc_DWLList_ExtraPT dwe with (nolock)
		where custid not in (select custid from dbo.Task_Cust_CheckBalance_Exception ce with(nolock))
		group by custid
		union all
		select custid, 'BetTrade Dummy Accounts'
		from DBCUST.custDB.dbo.BetTradeCust bt with (nolock)
		where custid not in (select custid from dbo.Task_Cust_CheckBalance_Exception ce with(nolock))
		group by custid

		--for 8RM account
		insert into dbo.Task_Cust_CheckBalance_Exception(custid, Remark)
		select custid, '8RM'
		from CustDB.dbo.Customer c WITH(NOLOCK)
		where c.recommend in (select t.custid from CustDB.dbo.Customer t with(nolock) where t.username = '8RM' and roleid = 2)
			AND c.custid not in (select ce.custid from dbo.Task_Cust_CheckBalance_Exception ce with(nolock))
		group by c.custid

	end

	begin -- reset data
		
		truncate table dbo.BalanceCreditGame
		truncate table dbo.BalanceDebitGame
		truncate table dbo.BalancePendingCreditGame
		truncate table dbo.BalancePendingDebitGame
		truncate table dbo.BalancePendingProcessed
		truncate table dbo.balanceTable
		truncate table dbo.balanceTable_tmp
		--truncate table dbo.BalanceUpdateSetting ==> need to update
		--truncate table dbo.BalCasinoPendingProcessed ==> no longer used
		truncate table dbo.BalCreditCasino
		truncate table dbo.BalCreditCasinoPending
		truncate table dbo.BalCreditCasinoPending_Staging
		truncate table dbo.BalCreditOthers
		truncate table dbo.BalCreditOthersPending
		truncate table dbo.BalCreditOthersPending_Staging
		truncate table dbo.BalCreditSports
		truncate table dbo.BalCreditSportsPending
		truncate table dbo.BalCreditSportsPending_Staging
		truncate table dbo.BalCreditTransfer
		truncate table dbo.BalDebitCasino
		truncate table dbo.BalDebitCasinoPending
		truncate table dbo.BalDebitOthers
		truncate table dbo.BalDebitOthersPending
		truncate table dbo.BalDebitSports
		truncate table dbo.BalDebitSportsPending
		truncate table dbo.BalDebitTransfer
		--truncate table dbo.BalOthersPendingProcessed ==> no longer used
		--truncate table dbo.BalSportsPendingProcessed ==> no longer used

		select custid into #__member_all
		from CustDB.dbo.Customer c with(nolock)
		where roleid = 1
			and not exists (select 1 from dbo.Task_Cust_CheckBalance_Exception ex with(nolock) where c.custid = ex.custid)

		insert into dbo.BalCreditCasino(custid, Balance)
		select custid, 0 from #__member_all

		insert into dbo.BalCreditOthers(custid, Balance)
		select custid, 0 from #__member_all

		insert into dbo.BalCreditSports(custid, Balance)
		select custid, 0 from #__member_all

		insert into dbo.BalCreditTransfer(custid, Balance)
		select custid, 0 from #__member_all

		insert into dbo.BalDebitCasino(custid, Balance)
		select custid, 0 from #__member_all

		insert into dbo.BalDebitOthers(custid, Balance)
		select custid, 0 from #__member_all

		insert into dbo.BalDebitSports(custid, Balance)
		select custid, 0 from #__member_all

		insert into dbo.BalDebitTransfer(custid, Balance)
		select custid, 0 from #__member_all

	end

	begin --update table group
		declare @__now datetime
		set @__now = getdate()
		update dbo.BalanceUpdateSetting set VValue = @__now where VName like '%_CreatedDate'
		update dbo.BalanceUpdateSetting set VValue = 0 where VName like '%_rnMAX'
		update dbo.BalanceUpdateSetting set VValue = 0 where VName like '%_rnMIN'
		update dbo.BalanceUpdateSetting set VValue = 0 where VName like '%_State'
		update dbo.BalanceUpdateSetting set VValue = 0 where VName like '%_TotalCust'
		update dbo.BalanceUpdateSetting set VValue = @__now where VName like '%_tstamp'
		update dbo.BalanceUpdateSetting set VValue = 0 where VName like '%_updID'
		
	end

	begin --update member balance group
		
		drop table if exists #tmpCal
		create table #tmpCal (custid int, outstanding money, balRNG money, balLC money, adjustWinlostAmt money)
		;with q2 as (
			-- translog
			select tl.custid, sum(actual_stake) as Outstanding
			from dbo.translog tl with (nolock)
			where tl.statusID IN (0,1) --summary running tickets only
			group by tl.custid
		),
		q3 as (
			select custid, sum(case when statusid = 0 then -actual_stake else winlost-actual_stake+playercomm end) BalRNG
			from dbo.bettransRNG with(nolock)
			where IsSum = 0
			group by custid
		),
		q4 as (
			select custid, sum(case when statusid = 0 then -actual_stake else winlost-actual_stake+playercomm end) ballc
			from dbo.bettransLC with(nolock)
			where IsSum = 0
			group by custid
		), 
		t as (
			select custid, sum(Amount) as adjustWinlostAmt
			from dbo.BonusAdjustmentTransfer with(nolock)
			where isTransferred = 0
			group by custid
		) 

		insert into #tmpCal(custid, Outstanding, BalRNG, BalLC, adjustWinlostAmt)
		select isnull(q2.custid, isnull(q3.custid, isnull(q4.custid, t.CustId))) custid, sum(isnull(Outstanding, 0)) Outstanding
			, sum(isnull(BalRNG, 0)) BalRNG, sum(isnull(BalLC, 0)) BalLC, sum(isnull(adjustWinlostAmt, 0)) adjustWinlostAmt
		from q2 full outer join q3 on q2.custid = q3.custid
			full outer join q4 on q2.custid = q4.custid
			full outer join t on q2.custid = t.custid
		group by isnull(q2.custid, isnull(q3.custid, isnull(q4.custid, t.custid)))

		create clustered index cix_t on #tmpcal (custid)

		declare @__movebetdate smalldatetime
		exec dbo.NAP_Admin_GetMovebetDate @MovebetDate = @__movebetdate output

		declare @__balanceupdate smalldatetime
		exec dbo.NAP_Admin_GetBalanceUpDate @BalanceUpDate = @__balanceupdate output

		;with cb as (
			select b.custid, sum(winlost-actual_stake+playercomm) balance
			from dbo.bettrans b with (nolock)
			where 1 = case when bettype >= 19999 then 0 --> get from transfer table
					 when bettype < 19999 and winlostdate <= @__movebetdate then 0 --> old bet
					 else 1 end
			group by b.custid
		),
		ct as (
			select t.custid, sum(winlost-actual_stake+playercomm) as balance
			from dbo.transfer t with(nolock)
			where 1 = case when bettype = 19999 and winlostdate > @__movebetdate then 0 --> new sum
						   when bettype = 20000 and winlostdate > @__balanceupdate then 0 --> new balanceup record
						   when winlostdate < @__balanceupdate then 0 --> old data
					 else 1 end
			group by t.custid
		)

		select cb.custid, cb.balance - isnull(qq.outstanding,0) + isnull(qq.balrng, 0) + isnull(qq.ballc, 0) - isnull(adjustwinlostamt, 0) balanceAmt
		into #__balanceMemberTable
		from (
			select isnull(cb.custid, ct.custid) custid, sum(isnull(cb.balance, 0) + isnull(ct.balance, 0)) balance
			from cb full outer join ct on cb.custid = ct.custid
			group by isnull(cb.custid, ct.custid)
		)cb	left outer join #tmpcal qq on cb.custid = qq.custid
		where not exists (select top 1 1 from dbo.task_cust_checkbalance_exception ex with (nolock) where cb.custid = ex.custid)

		update s set s.Balance = bal.balanceAmt
		from #__balanceMemberTable bal
			inner join dbo.BalCreditSports s on bal.custid = s.custid
		where bal.balanceAmt > 0

		update s set s.Balance = abs(bal.balanceAmt)
		from #__balanceMemberTable bal
			inner join dbo.BalDebitSports s on bal.custid = s.custid
		where bal.balanceAmt < 0

	end

	begin --balance game group
		print 'todo: balance game'
	end

end