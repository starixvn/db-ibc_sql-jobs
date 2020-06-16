SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE	dbo.Task_Archive_SelectBettransLC
AS
/*
	Creator:	20151013@Sophia
	Task:		Insert data from bettransLC14 to bettransLC_BK at bodb_Archive
	Database:	DBTXN.bodb02

	Revisions:
		- 20151013@Sophia:	Initial - [Redmine: #000000] 
		- 20191104@Billy:	Add column [epositiontaking] of [bettransLC] - [Redmine: #123267]
		- 20200612@Patrick: Avoid sort to reduce log file growth [Redmine: #135806]
*/
BEGIN 
	SET NOCOUNT ON

	DECLARE  @max_winlostdate SMALLDATETIME
		, @__winlostdate SMALLDATETIME

	SELECT	 @max_winlostdate = MAX(winlostdate), @__winlostdate = MIN(winlostdate)
	FROM	dbo.Task_ArchiveDate

	-- to DB06.bodb_Archive.dbo.bettransLC_BK
	WHILE @__winlostdate <= @max_winlostdate
	BEGIN
		SELECT	b.transid, b.custid, b.transdate, b.odds, b.stake, b.status, b.apositiontaking, b.mpositiontaking, b.tpositiontaking, b.spositiontaking
			,	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.creator, b.winlostdate, b.betfrom, b.virtualrate, b.actualrate, b.actual_stake
			,	b.currency, b.CurrencyName, b.recommend, b.mrecommend, b.srecommend, b.ip, b.statusID, b.balance, b.Username, b.transdesc, b.productID, b.gameID
			,	b.vendorID, b.GameId3rd, b.TranId3rd, b.RefNo, b.IsSum, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, b.acomm, b.scomm
			,	b.Transdate3rd, b.NetStake
			,	[countryCode] = p.CountryShort
			,	b.epositiontaking
		FROM		dbo.bettransLC14 AS b WITH (NOLOCK)
		INNER JOIN	dbo.Task_bettransLC14_IP2Country AS p WITH (NOLOCK)
				ON	b.transid = p.transid AND p.winlostdate = @__winlostdate
		WHERE	b.winlostdate = @__winlostdate;

		SET @__winlostdate = DATEADD(DAY, 1, @__winlostdate)
	END
END
GO
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/