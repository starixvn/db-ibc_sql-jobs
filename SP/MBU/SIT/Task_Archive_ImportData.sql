/*<info serverAlias="DBARC-bodb_Archive" executers="" viewers="" isFunction="0"></info>*/
ALTER proc [dbo].[Task_Archive_ImportData] @SPName varchar(200)
as
/*
	Created by:[]
	Date:
	Task: Task_Archive_ImportData @ SIT
	DB: DBARC/bodb_Archive
	Revisions:
		- 20211214@Kathy: Separate Transfer Tickets[Redmine:#164197]
	
*/
begin
	set nocount on
	declare @__archiveDates table(rowId int identity(1,1), winlostdate smalldatetime)
	declare @__rowId int = 1, @__winlostdate smalldatetime
	insert into @__archiveDates(winlostdate)
	select winlostdate 
	from DBTXN.bodb02.dbo.Task_ArchiveDate order by winlostdate
	
	if @SPName = 'Task_Archive_SelectBetStatement'
	begin
		insert into bodb_Report.dbo.Statement(custid, accdate, totalamt, transtype, transdesc)
		exec DBTXN.bodb02.dbo.Task_Archive_SelectBetStatement
	end
	else if @SPName = 'Task_Archive_SelectStatement'
	begin
		select @__rowId = 1, @__winlostdate = null
		while exists (select top 1 1 from @__archiveDates where rowId = @__rowId)
		begin
			select @__winlostdate = winlostdate from @__archiveDates where rowId = @__rowId
			set @__rowId += 1
			
			insert into bodb_Report.dbo.Statement(custid, accdate, totalamt, transtype, transdesc)
			exec DBTXN.bodb02.dbo.Task_Archive_SelectStatement @WinlostDate = @__winlostdate
		end
	end
	else if @SPName = 'Task_Archive_SelectTransfer'
	begin
		select @__rowId = 1, @__winlostdate = null
		while exists (select top 1 1 from @__archiveDates where rowId = @__rowId)
		begin
			select @__winlostdate = winlostdate from @__archiveDates where rowId = @__rowId
			set @__rowId += 1
			
			insert into dbo.transfer_bk([transid], [custid], [transdate], [Debit], [Credit], [TransDesc], [winlostdate], [recommend], [mrecommend], [srecommend], [bettype], [currency], [refno], [creator], [balance])
			exec DBTXN.bodb02.dbo.Task_Archive_SelectTransfer @WinlostDate = @__winlostdate
		end		
	end
	else if @SPName = 'Task_Archive_SelectBettransLC'
	begin
		insert into dbo.bettransLC_bk(transid, custid, transdate, odds, stake, status, apositiontaking, mpositiontaking, tpositiontaking, spositiontaking
			,playerdiscount, discount, adiscount, sdiscount, creator, winlostdate, betfrom, virtualrate, actualrate, actual_stake
			,currency, CurrencyName, recommend, mrecommend, srecommend, ip, statusID, balance, Username, transdesc, productID, gameID
			,vendorID, GameId3rd, TranId3rd, RefNo, IsSum, winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm
			,Transdate3rd, NetStake,[countryCode],epositiontaking, siteID)
		exec DBTXN.bodb02.dbo.Task_Archive_SelectBettransLC
	end
	else if @SPName = 'Task_Archive_SelectBettransRnG'
	begin
		select @__rowId = 1, @__winlostdate = null
		while exists (select top 1 1 from @__archiveDates where rowId = @__rowId)
		begin
			select @__winlostdate = winlostdate from @__archiveDates where rowId = @__rowId
			set @__rowId += 1
			
			insert into dbo.bettransRnG_bk(transid, custid, transdate, odds, stake, status, apositiontaking, mpositiontaking, tpositiontaking, spositiontaking
				, playerdiscount, discount, adiscount, sdiscount, creator, winlostdate, betfrom, virtualrate, actualrate, actual_stake
				, currency, CurrencyName, recommend, mrecommend, srecommend, ip, statusID, balance, Username, transdesc, productID, gameID
				, vendorID, GameId3rd, TranId3rd, RefNo, IsSum, winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, Transdate3rd
				, [countryCode], Additional, JackpotInfo, RefNo2, ContributionRate, BetStake, ContributionStake3rd, epositiontaking, SiteId)
			exec DBTXN.bodb02.dbo.Task_Archive_SelectBettransRnG @winlostdate = @__winlostdate
		end
		
	end
	else if @SPName = 'Task_Archive_SelectTranslog'
	begin
		insert into dbo.translog_BK(translogid, custid, transdate, odds, stake, status, apositiontaking, mpositiontaking, tpositiontaking, spositiontaking, 
			playerdiscount, discount, adiscount, sdiscount, creator, winlostdate, betfrom, virtualrate, actualrate, actual_stake, currency, 
			CurrencyName, recommend, mrecommend, srecommend, ip, statusID, balance, Username, transdesc, productID, gameID, eventID, vendorID, 
			GameId3rd, TranId3rd, custom1, custom2, custom3, LiveIndicator)
		exec DBTXN.bodb02.dbo.Task_Archive_SelectTranslog
	end
	else if @SPName = 'Task_Archive_SelectBettransG'
	begin
		insert into dbo.bettransG(transid, custid, transdate, oddsid, odds, stake, status, winlost, betteam, creator, refno, winlostdate, betfrom
			, checktime, apositiontaking, mpositiontaking, tpositiontaking, awinlost, mwinlost, playerdiscount, discount, adiscount
			, playercomm, comm, acomm, actualrate, matchid, matchdate, statuswinlost, ruben, bettype, spositiontaking, swinlost
			, sdiscount, scomm, statusID, virtualrate, SiteID, transdesc, BetID3rd, epositiontaking, actual_stake, netstake)
		exec DBTXN.bodb02.dbo.Task_Archive_SelectBettransG
	end
	else if @SPName = 'Task_Archive_SelectBettransm'
	begin
		insert into dbo.bettransm([BetCheck], [BetFrom], [BetTeam], [ComStatus], [Status]	  
			, transdate, transid, custid, matchid, oddsid, bettype, hdp1, hdp2, stake, odds, finalodds
			, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking, awinlost, mwinlost, swinlost
			, playerdiscount, discount, adiscount, sdiscount, playercomm, comm, acomm, scomm
			, liveawayscore, livehomescore, liveindicator, matchdate, isfinish
			, oddsspread, refno, ruben, statusID, statuswinlost, winlost
			, actualrate, checktime, creator, winlostdate, recommdate, transdesc, SecAcceptFlag, reasonIDm)
		exec DBTXN.bodb02.dbo.Task_Archive_SelectBettransm
	end
	else if @SPName = 'Task_Archive_SelectNG2_Message'
	begin
		insert into dbo.SettlementNG2_Message_BK(SeqID, CreationTime, DoneAPI_Time, TotalRow, StartCalculate_Time, DoneCalculate_Time, Status, Task, EventDate, GambleID, MatchId)
		exec DBTXN.bodb02.dbo.Task_Archive_SelectNG2_Message
	end
	else if @SPName = 'Task_Archive_bettrans_staging'
	begin
		insert into dbo.bettrans_Staging_bk(SeqId, OBTransId, ObBetType, Odds, ObCustId, Stake, ActualStake, GambleId, Payout, NumberofHit, isSkipped)
		exec DBTXN.bodb02.dbo.Task_Archive_bettrans_staging
	end
	else if @SPName = 'Task_Archive_SelectTransfer_Fi'
	begin
		insert into dbo.transfer_fi(transid, custid, transdate, bettype, actual_stake, winlost, ActualRate, TransDesc, winlostdate, recommend, mrecommend, srecommend, currency, 
			refno, creator, CheckerID, CheckerName, checkTime, isReversal)
		exec DBTXN.bodb02.dbo.Task_Archive_SelectTransfer_Fi
	end
	else if @SPName = 'Task_Archive_SelectTransfer_Coll'
	begin
		insert into dbo.transfer_Coll_BK(CustId,WinlostDate,TransDate,Bettype,Debit,Credit,Currency,ActualRate,TransID,RefNo,Username,Recommend,MRecommend,SRecommend,Creator,TransDesc,IP)
		exec DBTXN.bodb02.dbo.Task_Archive_SelectTransfer_Coll
	end
	else if @SPName = 'Task_Archive_SelectBettrans'
	begin
		select @__rowId = 1, @__winlostdate = null
		while exists (select top 1 1 from @__archiveDates where rowId = @__rowId)
		begin
			select @__winlostdate = winlostdate from @__archiveDates where rowId = @__rowId
			set @__rowId += 1
			
			insert into dbo.bettrans_bk(custid, transdate, oddsid, hdp1, hdp2, odds, stake, actual_stake
				, [status], winlost, awinlost, mwinlost, swinlost
				, playercomm, comm, acomm, scomm, apositiontaking, mpositiontaking, spositiontaking, tpositiontaking
				, playerdiscount, discount, adiscount, sdiscount, livehomescore, liveawayscore, liveindicator
				, [betteam], creator, refno, winlostdate
				, [betfrom], [betcheck], checktime, oddsspread, actualrate, matchid, recommend, mrecommend, srecommend
				, ruben, betid, statuswinlost, modds, betdaqid, tstamp, currency
				, [ip], transdesc, virtualrate, oddstype, statusID
				, currency2, transid, bettype, balance, transid2, SecAcceptFlag, comstatus
				, [CountryCode], ExtraInfo, WalletType, BonusID, RefCode, SettlementTime, epositiontaking, ReasonID, sort)
			exec DBTXN.bodb02.dbo.Task_Archive_SelectBettrans @winlostdate = @__winlostdate
		end
	end
end
