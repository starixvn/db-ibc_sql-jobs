/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[ExecRep_08] @recommend int,
	@winlostdate smalldatetime,
	@parlay bit = 0
AS
-- *** IMPORTANT ***
-- IF new fields add, must to go alter related SP of ExecRep_Queue @ DBTP
-- *****************

	/*
	Created by:[]
	Date:
	Task: 
	DB: DBTXN.BODB02
	Revisions:
		- 20110523@Henry: change bettype to new range
		- 20120316@Victor: add move bettransG to bettransG14
		- 20140305@Vivi: add move translog to translog14
		- 20151012@Sophia: Add Move BettransLC and BettransRNG 
		
		- 20160121@Joe : move command to run in ExecRep_Queue @ DBTP (to solve Blocking problem which cause replication delay)
		- 20160121@Joy : Add Move column :transdesc on bettransm
		- 20160428@Joy : 1. Add Move column :Additional on bettransrng
		-                2. remove Move column :NetStake on bettransrng
		- 20170412@Joy :Add Move column  ExtraInfo on bettrans14 
		- 20170914@Patrick: Integrate with Lucky3 [RedmineId: #83190]
		- 20180117@Patrick: Integrate with Bonus
		- 20180404@Patrick: Add more fields JackpotInfo, RefNo2, ContributionRate, BetStake, ContributionStake3rd on bettransRnG for OneRNG Jackpot
		- 20181217@Patrick: Use local param variable to avoiding param sniffing [RedmineId: #106130]
	 */
	 
DECLARE @__winlostdate SMALLDATETIME, @__recommend INT
SELECT @__winlostdate = @winlostdate, @__recommend = @recommend

IF @@SERVERNAME = 'DBTP' AND @parlay = 0
BEGIN
	IF NOT EXISTS (SELECT 1 FROM dbo.ExecRep_Queue WHERE command = 'ExecRep_08' AND datevalue = @__winlostdate)
		INSERT INTO dbo.ExecRep_Queue (command, datevalue, qPriority) VALUES ('ExecRep_08',@__winlostdate, 1)
		
	RETURN
END

IF @@SERVERNAME NOT LIKE 'DB04%'
BEGIN

	insert into bettrans14 
		(
		transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost, 
		playercomm, comm, acomm, apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, 
		discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, 
		winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, mrecommend, 
		ruben, betid, statuswinlost, modds, bettype, betdaqid, actual_stake, currency, ip, transdesc, 
		sdiscount, scomm, spositiontaking, swinlost, srecommend, virtualrate, Username, CurrencyName, 
		oddstype, statusID, currency2, balance, SecAcceptFlag, transid2, ExtraInfo, WalletType, BonusID, RefCode
		)
	select 
		transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost, 
		playercomm, comm, acomm, apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, 
		discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, 
		winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, mrecommend, 
		ruben, betid, statuswinlost, modds, bettype, betdaqid, actual_stake, currency, ip, transdesc, 
		sdiscount, scomm, spositiontaking, swinlost, srecommend, virtualrate, Username, CurrencyName, 
		oddstype, statusID, currency2, balance, SecAcceptFlag, transid2, ExtraInfo, WalletType, BonusID, RefCode
	from bettrans (nolock)
	where recommend = @__recommend AND winlostdate=@__winlostdate
		and bettype <= 19000

	insert into translog14 
		(
		translogid, custid, transdate, odds, stake, status, apositiontaking, mpositiontaking, tpositiontaking, spositiontaking,
        playerdiscount, discount, adiscount, sdiscount, creator, winlostdate, betfrom, virtualrate, actualrate, actual_stake,
        currency, CurrencyName, recommend, mrecommend, srecommend,ip, statusID, balance, Username, transdesc,
        productID, gameID, eventID, vendorID, GameId3rd, TranId3rd
		)
	select 
		translogid, custid, transdate, odds, stake, status, apositiontaking, mpositiontaking, tpositiontaking, spositiontaking,
        playerdiscount, discount, adiscount, sdiscount, creator, winlostdate, betfrom, virtualrate, actualrate, actual_stake,
        currency, CurrencyName, recommend, mrecommend, srecommend,ip, statusID, balance, Username, transdesc,
        productID, gameID, eventID, vendorID, GameId3rd, TranId3rd
	from translog with (nolock)
	where recommend = @__recommend AND winlostdate=@__winlostdate
		
	INSERT INTO BettransLC14 
		(
		transid, custid, transdate, odds, stake, status, apositiontaking, mpositiontaking, tpositiontaking, spositiontaking, 
		playerdiscount, discount, adiscount, sdiscount, creator, winlostdate, betfrom, virtualrate, actualrate, actual_stake, 
		currency, CurrencyName, recommend, mrecommend, srecommend, ip, statusID, balance, Username, transdesc, productID, gameID, 
		vendorID, GameId3rd, TranId3rd, RefNo, IsSum, winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, Transdate3rd, NetStake
		)
	SELECT 
		transid, custid, transdate, odds, stake, status, apositiontaking, mpositiontaking, tpositiontaking, spositiontaking, 
		playerdiscount, discount, adiscount, sdiscount, creator, winlostdate, betfrom, virtualrate, actualrate, actual_stake, 
		currency, CurrencyName, recommend, mrecommend, srecommend, ip, statusID, balance, Username, transdesc, productID, gameID, 
		vendorID, GameId3rd, TranId3rd, RefNo, IsSum, winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, Transdate3rd, NetStake
	FROM dbo.BettransLC WITH (NOLOCK)
	WHERE recommend = @__recommend AND winlostdate=@__winlostdate

	
	INSERT INTO BettransRNG14
		(
		transid, custid, transdate, odds, stake, status, apositiontaking, mpositiontaking, tpositiontaking, spositiontaking, 
		playerdiscount, discount, adiscount, sdiscount, creator, winlostdate, betfrom, virtualrate, actualrate, actual_stake, 
		currency, CurrencyName, recommend, mrecommend, srecommend, ip, statusID, balance, Username, transdesc, productID, gameID, 
		vendorID, GameId3rd, TranId3rd, RefNo, IsSum, winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, Transdate3rd, Additional,SiteID, 
		JackpotInfo, RefNo2, ContributionRate, BetStake, ContributionStake3rd	
		)
	SELECT 
		transid, custid, transdate, odds, stake, status, apositiontaking, mpositiontaking, tpositiontaking, spositiontaking, 
		playerdiscount, discount, adiscount, sdiscount, creator, winlostdate, betfrom, virtualrate, actualrate, actual_stake, 
		currency, CurrencyName, recommend, mrecommend, srecommend, ip, statusID, balance, Username, transdesc, productID, gameID, 
		vendorID, GameId3rd, TranId3rd, RefNo, IsSum, winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, Transdate3rd, Additional,SiteID, 
		JackpotInfo, RefNo2, ContributionRate, BetStake, ContributionStake3rd
	FROM dbo.BettransRNG WITH (NOLOCK)
	WHERE recommend = @__recommend AND winlostdate=@__winlostdate

END


IF @@SERVERNAME = 'DB04'
BEGIN
	insert into bettrans14 
		(
		transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost, 
		playercomm, comm, acomm, apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, 
		discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, 
		winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, mrecommend, 
		ruben, betid, statuswinlost, modds, bettype, betdaqid, actual_stake, currency, ip, transdesc, 
		sdiscount, scomm, spositiontaking, swinlost, srecommend, virtualrate, Username, CurrencyName, 
		oddstype, statusID, currency2, balance, SecAcceptFlag, transid2, ExtraInfo, WalletType, BonusID, RefCode
		)
	select 
		transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost, 
		playercomm, comm, acomm, apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, 
		discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, 
		winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, mrecommend, 
		ruben, betid, statuswinlost, modds, bettype, betdaqid, actual_stake, currency, ip, transdesc, 
		sdiscount, scomm, spositiontaking, swinlost, srecommend, virtualrate, Username, CurrencyName, 
		oddstype, statusID, currency2, balance, SecAcceptFlag, transid2, ExtraInfo, WalletType, BonusID, RefCode
	from bettrans (nolock)
	where recommend = @__recommend AND winlostdate=@__winlostdate
		and bettype IN (9, 29)
END


IF @@SERVERNAME NOT LIKE 'DB04_'
BEGIN

	IF @parlay = 1
	BEGIN
		--set true for the flag isMovingBet on DB06.bodb02.dbo.SystemSettings
		--to prevent the Mix Parlay calculation while this process is running
		--IF @@SERVERNAME = 'DB06'
		--BEGIN
		--	if exists (select * from dbo.sysobjects where name = 'SystemSettings')
		--	BEGIN
		--		UPDATE SystemSettings set VValue = 1 where VName = 'isMovingBet'
		--	END
		--END

		insert into bettransm14
			(
			transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, [status], winlost, livehomescore, 
			liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, 
			checktime, oddsspread, apositiontaking, mpositiontaking, tpositiontaking, awinlost, mwinlost, 
			playerdiscount, discount, adiscount, playercomm, comm, acomm, actualrate, matchid, matchdate, 
			finalodds, isfinish, statuswinlost, ruben, bettype, spositiontaking, swinlost, sdiscount, scomm, 
			statusID, transdesc
			)
		select
			transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, [status], winlost, livehomescore, 
			liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, 
			checktime, oddsspread, apositiontaking, mpositiontaking, tpositiontaking, awinlost, mwinlost, 
			playerdiscount, discount, adiscount, playercomm, comm, acomm, actualrate, matchid, matchdate, 
			finalodds, isfinish, statuswinlost, ruben, bettype, spositiontaking, swinlost, sdiscount, scomm, 
			statusID, transdesc
		from bettransm b (nolock)
			--INNER JOIN custinfo c (nolock) ON b.custid = c.custid
		where --recommend = @__recommend AND 
			winlostdate=@__winlostdate


		insert into bettransG14
			(transid, custid, transdate, oddsid, odds, stake, status, winlost, 
			betteam, creator, refno, winlostdate, betfrom, checktime, apositiontaking, 
			mpositiontaking, tpositiontaking, awinlost, mwinlost, playerdiscount, discount, 
			adiscount, playercomm, comm, acomm, actualrate, matchid, matchdate, 
			statuswinlost, ruben, bettype, spositiontaking, swinlost, sdiscount, scomm, statusID, 
			virtualrate, SiteID, transdesc, BetID3rd)
		select transid, custid, transdate, oddsid, odds, stake, status, winlost, 
			betteam, creator, refno, winlostdate, betfrom, checktime, apositiontaking, 
			mpositiontaking, tpositiontaking, awinlost, mwinlost, playerdiscount, discount, 
			adiscount, playercomm, comm, acomm, actualrate, matchid, matchdate, 
			statuswinlost, ruben, bettype, spositiontaking, swinlost, sdiscount, scomm, statusID, 
			virtualrate, SiteID, transdesc, BetID3rd
		from bettransG with (nolock)
		where  
			winlostdate=@__winlostdate

		--copy ticket to [14] for lucky3
		IF (SELECT COUNT(1) FROM dbo.sysobjects WHERE name IN ('BetLucky3Result', 'BetLucky3Result14')) = 2
		BEGIN
			INSERT INTO dbo.BetLucky3Result14(MatchId, TransId, CustId, Bettype, Currency, Hdp1, Odds
				, StatusId, Hits, Prize, PrizeAmount, Winlost, aWinlost, mWinlost, sWinlost, PlayerComm
				, Comm, aComm, sComm, aPositionTaking, mPositionTaking, sPositionTaking, PlayerDiscount
				, Discount, aDiscount, sDiscount, TransDesc, WinlostDate)
			SELECT MatchId, TransId, CustId, Bettype, Currency, Hdp1, Odds
				, StatusId, Hits, Prize, PrizeAmount, Winlost, aWinlost, mWinlost, sWinlost, PlayerComm
				, Comm, aComm, sComm, aPositionTaking, mPositionTaking, sPositionTaking, PlayerDiscount
				, Discount, aDiscount, sDiscount, TransDesc, WinlostDate
			FROM dbo.BetLucky3Result b WITH(NOLOCK)
			WHERE WinlostDate = @__winlostdate
		END
	END
	
END
GO
