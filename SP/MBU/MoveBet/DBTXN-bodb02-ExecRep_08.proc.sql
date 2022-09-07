SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE	dbo.ExecRep_08
	@recommend int,
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
		- 20110523@Henry:	change bettype to new range
		- 20120316@Victor:	add move bettransG to bettransG14
		- 20140305@Vivi:	add move translog to translog14
		- 20151012@Sophia:	Add Move BettransLC and BettransRNG 
		- 20160121@Joe:		move command to run in ExecRep_Queue @ DBTP (to solve Blocking problem which cause replication delay)
		- 20160121@Joy:		Add Move column :transdesc on bettransm
		- 20160428@Joy:		1. Add Move column :Additional on bettransrng
							2. remove Move column :NetStake on bettransrng
		- 20170412@Joy:		Add Move column  ExtraInfo on bettrans14 
		- 20170914@Patrick:	Integrate with Lucky3 [RedmineId: #83190]
		- 20180117@Patrick:	Integrate with Bonus
		- 20180404@Patrick:	Add more fields JackpotInfo, RefNo2, ContributionRate, BetStake, ContributionStake3rd on bettransRnG for OneRNG Jackpot
		- 20181217@Patrick:	Use local param variable to avoiding param sniffing [RedmineId: #106130]
		- 20181222@Billy:	Remove Queue processing on DBTP - [Redmine: #000000]
		- 20190213@Billy:	Add column [SecAcceptFlag] of [bettransm] - [Redmine: #108780]
		- 20190424@Billy:	Add column [SettlementTime] of [bettrans] - [Redmine: #112464]
		- 20190828@Billy:	Add table [bettransInfo] & column [SecAcceptTime], [LiveBetAcceptTime] of [bettransm] - [Redmine: #119219]
		- 20191104@Billy:	Add column [epositiontaking] of [bettrans], [bettransLC], [bettransRnG] - [Redmine: #123267]
		- 20191030@Billy:	Remove table [BetLucky3Result] - [Redmine: #122987]
		- 20191126@Patrick:	Ignore copy data to [14] on DB054/DB055 - [Redmine: #124104]
		- 20200311@Billy:	Add column [ReasonID] of [bettrans] - [Redmine: #130202]
							Add [epositiontaking], [actual_stake] of [bettransG] - [Redmine: #130201]
		- 20200710@Brice:	Add column [sort] of [bettrans] - [Redmine: #137129]
		- 20200714@Brice:	Add column [netstake] of [bettransG] - [Redmine: #137591]
		- 20200923@Brice:	Add column [reasonIDm] of [bettransM] - [Redmine: #141650]
		- 20201008@Brice:	Add column [OriginalOdds] of [bettransInfo] - [Redmine: #140906]
		- 20201221@Brice:	Add column [siteID] of [bettransLC] - [Redmine: #147084]
		- 20210126@Patrick: Migrate DB Server DB054 to cluster [Redmine: #149273]
		- 20210519@Patrick: Support SIT environment [Redmine: #149927]
		- 20220727@Patrick: Add column ThirdTransID into bettransInfo/14 [Redmine: #175666]
		- 20220804@Patrick: Support scale-out for deposit site Redmine: [#175602]
	 */
	 
DECLARE @__winlostdate SMALLDATETIME, @__recommend INT
SELECT @__winlostdate = @winlostdate, @__recommend = @recommend

	-- 20181222@Billy: Comment code due to replication issue from DBTP to DBMNL
/*
IF @@SERVERNAME = 'DBTP' AND @parlay = 0
BEGIN
	IF NOT EXISTS (SELECT 1 FROM dbo.ExecRep_Queue WHERE command = 'ExecRep_08' AND datevalue = @__winlostdate)
		INSERT INTO dbo.ExecRep_Queue (command, datevalue, qPriority) VALUES ('ExecRep_08',@__winlostdate, 1)
		
	RETURN
END
*/

-- 20190828@Billy:	Temp table variable contain output transid for copy [bettransInfo]
DECLARE	@__tmpTransId AS TABLE (
			id		BIGINT		PRIMARY KEY CLUSTERED
		);

IF @@SERVERNAME NOT LIKE 'DB04%' 
	AND @@SERVERNAME NOT IN ('DB054', 'DB054C2\DB054', 'DB055', 'SITDB055') 
	AND @@SERVERNAME NOT LIKE 'SITDB04%'
BEGIN
	
	-- Note: Exclude columns: [tstamp], [recommdate]
	-- 20191104@Billy:	Add column [epositiontaking]
	-- 20200311@Billy:	Add column [ReasonID]
	INSERT INTO	dbo.bettrans14
		(	transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost
		,	playercomm, comm, acomm, apositiontaking, mpositiontaking, tpositiontaking, playerdiscount
		,	discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus
		,	winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, mrecommend
		,	ruben, betid, statuswinlost, modds, bettype, betdaqid, actual_stake, currency, ip, transdesc
		,	sdiscount, scomm, spositiontaking, swinlost, srecommend, virtualrate, Username, CurrencyName
		,	oddstype, statusID, currency2, balance, SecAcceptFlag, transid2, ExtraInfo, WalletType, BonusID
		,	RefCode, SettlementTime, epositiontaking, ReasonID, sort, SiteDBGroupId
		)
	OUTPUT	Inserted.transid
	INTO	@__tmpTransId (id)
	SELECT	transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost
		,	playercomm, comm, acomm, apositiontaking, mpositiontaking, tpositiontaking, playerdiscount
		,	discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus
		,	winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, mrecommend
		,	ruben, betid, statuswinlost, modds, bettype, betdaqid, actual_stake, currency, ip, transdesc
		,	sdiscount, scomm, spositiontaking, swinlost, srecommend, virtualrate, Username, CurrencyName
		,	oddstype, statusID, currency2, balance, SecAcceptFlag, transid2, ExtraInfo, WalletType, BonusID
		,	RefCode, SettlementTime, epositiontaking, ReasonID, sort, SiteDBGroupId
	FROM	dbo.bettrans WITH (NOLOCK)
	WHERE	recommend = @__recommend
		AND	winlostdate = @__winlostdate
		AND	bettype <= 19000;

	-- 20190828@Billy: Add [bettransInfo]
	INSERT INTO	dbo.BettransInfo14
		(	transid, SecAcceptTime, LiveBetAcceptTime, OriginalOdds, ThirdTransID)
	SELECT	transid, SecAcceptTime, LiveBetAcceptTime, OriginalOdds, ThirdTransID
	FROM		dbo.BettransInfo AS bi WITH (NOLOCK)
	INNER JOIN	@__tmpTransId AS tmp
			ON	bi.transid = tmp.id;

	insert into translog14 
		(
		translogid, custid, transdate, odds, stake, status, apositiontaking, mpositiontaking, tpositiontaking, spositiontaking,
        playerdiscount, discount, adiscount, sdiscount, creator, winlostdate, betfrom, virtualrate, actualrate, actual_stake,
        currency, CurrencyName, recommend, mrecommend, srecommend,ip, statusID, balance, Username, transdesc,
        productID, gameID, eventID, vendorID, GameId3rd, TranId3rd, SiteDBGroupId
		)
	select 
		translogid, custid, transdate, odds, stake, status, apositiontaking, mpositiontaking, tpositiontaking, spositiontaking,
        playerdiscount, discount, adiscount, sdiscount, creator, winlostdate, betfrom, virtualrate, actualrate, actual_stake,
        currency, CurrencyName, recommend, mrecommend, srecommend,ip, statusID, balance, Username, transdesc,
        productID, gameID, eventID, vendorID, GameId3rd, TranId3rd, SiteDBGroupId
	from translog with (nolock)
	where recommend = @__recommend AND winlostdate=@__winlostdate

	-- 20191104@Billy:	Add column [epositiontaking]
	INSERT INTO	dbo.bettransLC14
		(	transid, custid, transdate, odds, stake, status, apositiontaking, mpositiontaking, tpositiontaking, spositiontaking
		,	playerdiscount, discount, adiscount, sdiscount, creator, winlostdate, betfrom, virtualrate, actualrate, actual_stake
		,	currency, CurrencyName, recommend, mrecommend, srecommend, ip, statusID, balance, Username, transdesc, productID, gameID
		,	vendorID, GameId3rd, TranId3rd, RefNo, IsSum, winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm
		,	Transdate3rd, NetStake, epositiontaking,siteID, SiteDBGroupId
		)
	SELECT	transid, custid, transdate, odds, stake, status, apositiontaking, mpositiontaking, tpositiontaking, spositiontaking
		,	playerdiscount, discount, adiscount, sdiscount, creator, winlostdate, betfrom, virtualrate, actualrate, actual_stake
		,	currency, CurrencyName, recommend, mrecommend, srecommend, ip, statusID, balance, Username, transdesc, productID, gameID
		,	vendorID, GameId3rd, TranId3rd, RefNo, IsSum, winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm
		,	Transdate3rd, NetStake, epositiontaking,siteID, SiteDBGroupId
	FROM	dbo.bettransLC WITH (NOLOCK)
	WHERE	recommend = @__recommend
		AND	winlostdate = @__winlostdate;

	-- 20191104@Billy: Add column [epositiontaking]
	INSERT INTO dbo.bettransRnG14
		(	transid, custid, transdate, odds, stake, status, apositiontaking, mpositiontaking, tpositiontaking, spositiontaking
		,	playerdiscount, discount, adiscount, sdiscount, creator, winlostdate, betfrom, virtualrate, actualrate, actual_stake
		,	currency, CurrencyName, recommend, mrecommend, srecommend, ip, statusID, balance, Username, transdesc, productID, gameID
		,	vendorID, GameId3rd, TranId3rd, RefNo, IsSum, winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, Transdate3rd
		,	Additional, SiteID, JackpotInfo, RefNo2, ContributionRate, BetStake, ContributionStake3rd, epositiontaking, SiteDBGroupId
		)
	SELECT	transid, custid, transdate, odds, stake, status, apositiontaking, mpositiontaking, tpositiontaking, spositiontaking
		,	playerdiscount, discount, adiscount, sdiscount, creator, winlostdate, betfrom, virtualrate, actualrate, actual_stake
		,	currency, CurrencyName, recommend, mrecommend, srecommend, ip, statusID, balance, Username, transdesc, productID, gameID
		,	vendorID, GameId3rd, TranId3rd, RefNo, IsSum, winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, Transdate3rd
		,	Additional, SiteID, JackpotInfo, RefNo2, ContributionRate, BetStake, ContributionStake3rd, epositiontaking, SiteDBGroupId
	FROM	dbo.bettransRnG WITH (NOLOCK)
	WHERE	recommend = @__recommend
		AND	winlostdate=@__winlostdate;

END

/*
IF @@SERVERNAME = 'DB04'
BEGIN
	-- Note: Exclude columns: [tstamp], [recommdate]
	-- 20191104@Billy:	Add column [epositiontaking]
	INSERT INTO	dbo.bettrans14
		(	transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost
		,	playercomm, comm, acomm, apositiontaking, mpositiontaking, tpositiontaking, playerdiscount
		,	discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus
		,	winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, mrecommend
		,	ruben, betid, statuswinlost, modds, bettype, betdaqid, actual_stake, currency, ip, transdesc
		,	sdiscount, scomm, spositiontaking, swinlost, srecommend, virtualrate, Username, CurrencyName
		,	oddstype, statusID, currency2, balance, SecAcceptFlag, transid2, ExtraInfo, WalletType, BonusID
		,	RefCode, SettlementTime, epositiontaking, ReasonID, sort
		)
	OUTPUT	Inserted.transid
	INTO	@__tmpTransId (id)
	SELECT	transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost
		,	playercomm, comm, acomm, apositiontaking, mpositiontaking, tpositiontaking, playerdiscount
		,	discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus
		,	winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, mrecommend
		,	ruben, betid, statuswinlost, modds, bettype, betdaqid, actual_stake, currency, ip, transdesc
		,	sdiscount, scomm, spositiontaking, swinlost, srecommend, virtualrate, Username, CurrencyName
		,	oddstype, statusID, currency2, balance, SecAcceptFlag, transid2, ExtraInfo, WalletType, BonusID
		,	RefCode, SettlementTime, epositiontaking, ReasonID, sort
	FROM	dbo.bettrans WITH (NOLOCK)
	WHERE	recommend = @__recommend
		AND	winlostdate = @__winlostdate
		AND	bettype IN (9, 29);

	-- 20190828@Billy: Add [bettransInfo]
	INSERT INTO	dbo.BettransInfo14
		(	transid, SecAcceptTime, LiveBetAcceptTime)
	SELECT	transid, SecAcceptTime, LiveBetAcceptTime
	FROM		dbo.BettransInfo AS bi WITH (NOLOCK)
	INNER JOIN	@__tmpTransId AS tmp
			ON	bi.transid = tmp.id;
END

*/


IF @@SERVERNAME NOT LIKE 'DB04_' AND @@SERVERNAME NOT IN ('DB054', 'DB054C2\DB054', 'DB055')
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

		-- 20190828@Billy: Add [SecAcceptTime], [LiveBetAcceptTime] of [bettransm]
		INSERT INTO	dbo.bettransm14 (
				transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, [status], winlost, livehomescore
			,	liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck
			,	checktime, oddsspread, apositiontaking, mpositiontaking, tpositiontaking, awinlost, mwinlost
			,	playerdiscount, discount, adiscount, playercomm, comm, acomm, actualrate, matchid, matchdate
			,	finalodds, isfinish, statuswinlost, ruben, bettype, spositiontaking, swinlost, sdiscount, scomm
			,	statusID, transdesc, SecAcceptFlag, SecAcceptTime, LiveBetAcceptTime,reasonIDm, SiteDBGroupId
			)
		SELECT	transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, [status], winlost, livehomescore
			,	liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck
			,	checktime, oddsspread, apositiontaking, mpositiontaking, tpositiontaking, awinlost, mwinlost
			,	playerdiscount, discount, adiscount, playercomm, comm, acomm, actualrate, matchid, matchdate
			,	finalodds, isfinish, statuswinlost, ruben, bettype, spositiontaking, swinlost, sdiscount, scomm
			,	statusID, transdesc, SecAcceptFlag, SecAcceptTime, LiveBetAcceptTime,reasonIDm, SiteDBGroupId
		FROM	dbo.bettransm AS b WITH (NOLOCK)
		WHERE	winlostdate = @__winlostdate;

		-- 20200311@Billy: Add [epositiontaking], [actual_stake] of [bettransG]
		INSERT INTO	dbo.bettransG14
			(	transid, custid, transdate, oddsid, odds, stake, status, winlost, betteam, creator, refno, winlostdate
			,	betfrom, checktime, apositiontaking, mpositiontaking, tpositiontaking, awinlost, mwinlost, playerdiscount
			,	discount, adiscount, playercomm, comm, acomm, actualrate, matchid, matchdate, statuswinlost, ruben, bettype
			,	spositiontaking, swinlost, sdiscount, scomm, statusID, virtualrate, SiteID, transdesc, BetID3rd
			,	epositiontaking, actual_stake, netstake, SiteDBGroupId
			)
		SELECT	transid, custid, transdate, oddsid, odds, stake, status, winlost, betteam, creator, refno, winlostdate
			,	betfrom, checktime, apositiontaking, mpositiontaking, tpositiontaking, awinlost, mwinlost, playerdiscount
			,	discount, adiscount, playercomm, comm, acomm, actualrate, matchid, matchdate, statuswinlost, ruben, bettype
			,	spositiontaking, swinlost, sdiscount, scomm, statusID, virtualrate, SiteID, transdesc, BetID3rd
			,	epositiontaking, actual_stake, netstake, SiteDBGroupId
		FROM	dbo.bettransG AS b WITH (NOLOCK)
		WHERE	winlostdate = @__winlostdate;
	END
END
GO
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/