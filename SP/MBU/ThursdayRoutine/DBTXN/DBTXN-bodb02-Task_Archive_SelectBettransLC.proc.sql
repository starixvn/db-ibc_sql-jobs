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
*/
BEGIN 
	SET NOCOUNT ON

	DECLARE  @max_winlostdate SMALLDATETIME

	SELECT	 @max_winlostdate = MAX(winlostdate)
	FROM	dbo.Task_ArchiveDate

	-- to DB06.bodb_Archive.dbo.bettransLC_BK
	SELECT 
		b.transid, custid, transdate, odds, stake, status, apositiontaking, mpositiontaking, tpositiontaking, spositiontaking, 
		playerdiscount, discount, adiscount, sdiscount, creator, b.winlostdate, betfrom, virtualrate, actualrate, actual_stake, 
		currency, CurrencyName, recommend, mrecommend, srecommend, ip, statusID, balance, Username, transdesc, productID, gameID, 
		vendorID, GameId3rd, TranId3rd, RefNo, IsSum, winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, Transdate3rd,NetStake,p.CountryShort as countryCode
	FROM dbo.BettransLC14 b WITH (NOLOCK)
		INNER JOIN Task_bettransLC14_IP2Country p WITH(NOLOCK) ON b.transid = p.transid
	WHERE b.winlostdate <= @max_winlostdate
END
GO
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/