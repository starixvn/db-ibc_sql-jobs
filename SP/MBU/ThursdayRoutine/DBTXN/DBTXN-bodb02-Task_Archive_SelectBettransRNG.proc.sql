SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE	dbo.Task_Archive_SelectBettransRNG
AS
/*
	Creator:	20151013@Sophia
	Task:		Insert data from bettransRNG14 to bettransRNG_BK at bodb_Archive
	Database:	DBTXN.bodb02

	Revisions:
		- 20160519@Joy:		remove NetStake /  Add  Additional    
		- 20180405@Billy:	Add [JackpotInfo], [RefNo2], [ContributionRate], [BetStake], [ContributionStake3rd] columns - [Redmine: #93177] 
		- 20191104@Billy:	Add column [epositiontaking] of [bettransRnG] - [Redmine: #123267]
		- 20200612@Patrick: Avoid sort to reduce log file growth [Redmine: #135806]
*/
BEGIN;
	SET NOCOUNT ON;

	DECLARE	@max_winlostdate	SMALLDATETIME
		, @__winlostdate SMALLDATETIME;

	SELECT	@max_winlostdate = MAX(winlostdate), @__winlostdate = MIN(winlostdate)
	FROM	dbo.Task_ArchiveDate WITH (NOLOCK);

	-- to DB06.bodb_Archive.dbo.bettransRNG_BK
	WHILE @__winlostdate <= @max_winlostdate
	BEGIN
		SELECT	b.transid, b.custid, b.transdate, b.odds, b.stake, b.status, b.apositiontaking, b.mpositiontaking, b.tpositiontaking, b.spositiontaking
			,	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.creator, b.winlostdate, b.betfrom, b.virtualrate, b.actualrate, b.actual_stake
			,	b.currency, b.CurrencyName, b.recommend, b.mrecommend, b.srecommend, b.ip, b.statusID, b.balance, b.Username, b.transdesc, b.productID, b.gameID
			,	b.vendorID, b.GameId3rd, b.TranId3rd, b.RefNo, b.IsSum, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, b.acomm, b.scomm, b.Transdate3rd
			,	[countryCode] = ip.countryShort
			,	b.Additional, b.JackpotInfo, b.RefNo2, b.ContributionRate, b.BetStake, b.ContributionStake3rd, b.epositiontaking
		FROM		dbo.bettransRnG14 AS b WITH (NOLOCK)
		INNER JOIN	dbo.Task_bettransRNG14_IP2Country AS ip WITH (NOLOCK)
				ON	b.transid = ip.transid AND ip.winlostdate = @__winlostdate
		WHERE	b.winlostdate = @__winlostdate;

		SET @__winlostdate = DATEADD(DAY, 1, @__winlostdate)
	END
END;
GO
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/