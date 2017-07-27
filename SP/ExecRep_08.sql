USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[ExecRep_08]    Script Date: 10/12/2015 02:46:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[ExecRep_08]
	@recommend int,
	@winlostdate smalldatetime,
	@parlay bit = 0
AS
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
    
    
	 */
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
		oddstype, statusID, currency2, balance, SecAcceptFlag, transid2
		)
	select 
		transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost, 
		playercomm, comm, acomm, apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, 
		discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, 
		winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, mrecommend, 
		ruben, betid, statuswinlost, modds, bettype, betdaqid, actual_stake, currency, ip, transdesc, 
		sdiscount, scomm, spositiontaking, swinlost, srecommend, virtualrate, Username, CurrencyName, 
		oddstype, statusID, currency2, balance, SecAcceptFlag, transid2
	from bettrans (nolock)
	where recommend = @recommend AND winlostdate=@winlostdate
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
	where recommend = @recommend AND winlostdate=@winlostdate
		
	INSERT INTO BettransLC14 
		(
		transid, custid, transdate, odds, stake, status, apositiontaking, mpositiontaking, tpositiontaking, spositiontaking, 
		playerdiscount, discount, adiscount, sdiscount, creator, winlostdate, betfrom, virtualrate, actualrate, actual_stake, 
		currency, CurrencyName, recommend, mrecommend, srecommend, ip, statusID, balance, Username, transdesc, productID, gameID, 
		vendorID, GameId3rd, TranId3rd, RefNo, IsSum, winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, Transdate3rd
		)
	SELECT 
		transid, custid, transdate, odds, stake, status, apositiontaking, mpositiontaking, tpositiontaking, spositiontaking, 
		playerdiscount, discount, adiscount, sdiscount, creator, winlostdate, betfrom, virtualrate, actualrate, actual_stake, 
		currency, CurrencyName, recommend, mrecommend, srecommend, ip, statusID, balance, Username, transdesc, productID, gameID, 
		vendorID, GameId3rd, TranId3rd, RefNo, IsSum, winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, Transdate3rd
	FROM dbo.BettransLC WITH (NOLOCK)
	WHERE recommend = @recommend AND winlostdate=@winlostdate

	
	INSERT INTO BettransRNG14
		(
		transid, custid, transdate, odds, stake, status, apositiontaking, mpositiontaking, tpositiontaking, spositiontaking, 
		playerdiscount, discount, adiscount, sdiscount, creator, winlostdate, betfrom, virtualrate, actualrate, actual_stake, 
		currency, CurrencyName, recommend, mrecommend, srecommend, ip, statusID, balance, Username, transdesc, productID, gameID, 
		vendorID, GameId3rd, TranId3rd, RefNo, IsSum, winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, Transdate3rd	
		)
	SELECT 
		transid, custid, transdate, odds, stake, status, apositiontaking, mpositiontaking, tpositiontaking, spositiontaking, 
		playerdiscount, discount, adiscount, sdiscount, creator, winlostdate, betfrom, virtualrate, actualrate, actual_stake, 
		currency, CurrencyName, recommend, mrecommend, srecommend, ip, statusID, balance, Username, transdesc, productID, gameID, 
		vendorID, GameId3rd, TranId3rd, RefNo, IsSum, winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, Transdate3rd
	FROM dbo.BettransRNG WITH (NOLOCK)
	WHERE recommend = @recommend AND winlostdate=@winlostdate

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
		oddstype, statusID, currency2, balance, SecAcceptFlag, transid2
		)
	select 
		transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost, 
		playercomm, comm, acomm, apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, 
		discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, 
		winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, mrecommend, 
		ruben, betid, statuswinlost, modds, bettype, betdaqid, actual_stake, currency, ip, transdesc, 
		sdiscount, scomm, spositiontaking, swinlost, srecommend, virtualrate, Username, CurrencyName, 
		oddstype, statusID, currency2, balance, SecAcceptFlag, transid2
	from bettrans (nolock)
	where recommend = @recommend AND winlostdate=@winlostdate
		and bettype IN (9, 29)
END


IF @@SERVERNAME NOT LIKE 'DB04_'
BEGIN

	IF @parlay = 1
	BEGIN
		--set true for the flag isMovingBet on DB06.bodb02.dbo.SystemSettings
		--to prevent the Mix Parlay calculation while this process is running
		IF @@SERVERNAME = 'DB06'
		BEGIN
			if exists (select * from dbo.sysobjects where name = 'SystemSettings')
			BEGIN
				UPDATE SystemSettings set VValue = 1 where VName = 'isMovingBet'
			END
		END

		insert into bettransm14
			(
			transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, [status], winlost, livehomescore, 
			liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, 
			checktime, oddsspread, apositiontaking, mpositiontaking, tpositiontaking, awinlost, mwinlost, 
			playerdiscount, discount, adiscount, playercomm, comm, acomm, actualrate, matchid, matchdate, 
			finalodds, isfinish, statuswinlost, ruben, bettype, spositiontaking, swinlost, sdiscount, scomm, 
			statusID
			)
		select
			transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, [status], winlost, livehomescore, 
			liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, 
			checktime, oddsspread, apositiontaking, mpositiontaking, tpositiontaking, awinlost, mwinlost, 
			playerdiscount, discount, adiscount, playercomm, comm, acomm, actualrate, matchid, matchdate, 
			finalodds, isfinish, statuswinlost, ruben, bettype, spositiontaking, swinlost, sdiscount, scomm, 
			statusID
		from bettransm b (nolock)
			--INNER JOIN custinfo c (nolock) ON b.custid = c.custid
		where --recommend = @recommend AND 
			winlostdate=@winlostdate


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
			winlostdate=@winlostdate

	END
	
END
GO
GRANT VIEW DEFINITION ON [dbo].[ExecRep_08] TO [vnteam] AS [dbo]