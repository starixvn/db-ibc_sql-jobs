/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_BettransRNG14_Export]
	@winlostdate smalldatetime=null
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]	
	Database: DBTXN.bodb02
	Original: Task_Archive_SelectBettransRnG 
	
	Revisions:
		- 20130831@Bobby: Init
 */
BEGIN
	SET NOCOUNT ON;

	DECLARE @__minTransId BIGINT, @__maxTransId BIGINT
	SELECT @__minTransId = MIN(TransId), @__maxTransId = MAX(TransId)
	FROM dbo.bettransRnG14 AS b WITH (NOLOCK)
	WHERE winlostdate = @winlostdate

	-- to DB06.bodb_Archive.dbo.bettransRNG_BK
	SELECT	b.transid, b.custid, b.transdate, b.odds, b.stake, b.status, b.apositiontaking, b.mpositiontaking, b.tpositiontaking, b.spositiontaking
		,	b.playerdiscount, b.discount, b.adiscount, b.sdiscount, b.creator, b.winlostdate, b.betfrom, b.virtualrate, b.actualrate, b.actual_stake
		,	b.currency, b.CurrencyName, b.recommend, b.mrecommend, b.srecommend
		,	ISNULL(ip.IPArchive, b.ip) AS ip
		,	b.statusID, b.balance, b.Username, b.transdesc, b.productID, b.gameID
		,	b.vendorID, b.GameId3rd, b.TranId3rd, b.RefNo, b.IsSum, b.winlost, b.awinlost, b.mwinlost, b.swinlost, b.playercomm, b.comm, b.acomm, b.scomm, b.Transdate3rd
		,	[CountryCode] = ip.CountryShort
		,	b.Additional, b.JackpotInfo, b.RefNo2, b.ContributionRate, b.BetStake, b.ContributionStake3rd, b.epositiontaking, b.SiteId
	FROM		dbo.bettransRnG14 AS b WITH (NOLOCK)
	INNER JOIN	dbo.Task_bettransRNG14_IP2Country AS ip WITH (NOLOCK)
			ON	b.transid = ip.transid
	WHERE ip.winlostdate = @winlostdate
		AND ip.transid BETWEEN @__minTransId AND @__maxTransId
END
GO
