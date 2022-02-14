/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_BettransLC14_Export]
	@winlostdate smalldatetime=null
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]	
	Database: DBTXN.bodb02
	Original: Task_Archive_SelectBettransLC
	
	Revisions:
		- 20130831@Bobby: Init
 */
BEGIN 
	SET NOCOUNT ON

	--DECLARE @__tempVar TABLE(winlostdate SMALLDATETIME)

	--INSERT INTO @__tempVar(winlostdate)
	--SELECT winlostdate 
	--FROM dbo.Task_ArchiveDate WITH (NOLOCK) ORDER BY winlostdate

	-- to DB06.bodb_Archive.dbo.bettransLC_BK
	SELECT	b.transid, b.custid, b.transdate, b.odds, b.stake, b.status, b.apositiontaking, b.mpositiontaking, b.tpositiontaking, b.spositiontaking
		,	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.creator, b.winlostdate, b.betfrom, b.virtualrate, b.actualrate, b.actual_stake
		,	b.currency, b.CurrencyName, b.recommend, b.mrecommend, b.srecommend
		,   ISNULL(p.IPArchive, b.IP) AS ip
		,	b.statusID, b.balance, b.Username, b.transdesc, b.productID, b.gameID
		,	b.vendorID, b.GameId3rd, b.TranId3rd, b.RefNo, b.IsSum, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, b.acomm, b.scomm
		,	b.Transdate3rd, b.NetStake
		,	[countryCode] = p.CountryShort
		,	b.epositiontaking, b.siteID
	FROM		dbo.bettransLC14 AS b WITH (NOLOCK)
	INNER JOIN	dbo.Task_bettransLC14_IP2Country AS p WITH (NOLOCK)
			ON	b.transid = p.transid AND p.winlostdate = b.winlostdate
	WHERE b.winlostdate = @winlostdate
END
GO
