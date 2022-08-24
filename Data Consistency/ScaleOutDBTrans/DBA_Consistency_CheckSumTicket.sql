/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_CheckSumTicket]
AS 
/*
Created by: 20220819@Victoria
Task: CheckSum ticket
DB: DBCONSISTENCY-bodb_Consistency
Revisions:
	- 20220819@Victoria: CheckSum ticket [Redmine:#175881]
	
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @yesterday SMALLDATETIME
	SELECT  @yesterday = CONVERT(DATE, DATEADD(DAY, -1, GETDATE()))

	SELECT	'bettrans' AS TableName,
			[SiteDBGroupID], 
			[Recommend], 
			CHECKSUM_AGG(CHECKSUM(	[custid], [oddsid], [hdp1], [hdp2], [odds], [stake], [status], [winlost], [awinlost], [mwinlost], [playercomm], [comm], [acomm], 
									[apositiontaking], [mpositiontaking], [tpositiontaking], [playerdiscount], [discount], [adiscount], [livehomescore], [liveawayscore], 
									[liveindicator], [betteam], [creator], [refno], [comstatus], [betfrom], [betcheck], [checktime], [oddsspread], [actualrate], [matchid], 
									[Recommend], [mrecommend], [ruben], [betid], [statuswinlost], [modds], [bettype], [betdaqid], [actual_stake], [currency], [ip], [transdesc], 
									[sdiscount], [scomm], [spositiontaking], [swinlost], [srecommend], [Username], [CurrencyName], [virtualrate], [oddstype], [statusID], [currency2], 
									[balance], [transid2], [WalletType], [BonusID], [RefCode])) AS Total_CheckSum_Agg
	FROM	bodb02.dbo.bettrans WITH (NOLOCK)
	WHERE	[winlostdate] = @yesterday
		AND [SiteDBGroupID] > 0
	GROUP BY	[SiteDBGroupID], 
				[recommend]
	UNION ALL 
	SELECT	'bettransRnG' AS TableName,
			[SiteDBGroupID], 
			[Recommend],  
			CHECKSUM_AGG(CHECKSUM(	[custid], [odds], [stake], [status], [apositiontaking], [mpositiontaking], [tpositiontaking], [spositiontaking], [playerdiscount], [discount], 
									[adiscount], [sdiscount], [creator], [betfrom], [virtualrate], [actualrate], [actual_stake], [currency], [CurrencyName], [Recommend], 
									[mrecommend], [srecommend], [ip], [statusID], [balance], [Username], [transdesc], [productID], [gameID], [vendorID], [GameId3rd], 
									[TranId3rd], [RefNo], [IsSum], [winlost], [awinlost], [mwinlost], [swinlost], [playercomm], [comm], [acomm], [scomm], [Transdate3rd], 
									[SiteID], [Additional], [JackpotInfo], [RefNo2], [ContributionRate], [BetStake], [ContributionStake3rd])) AS Total_CheckSum_Agg
	FROM	bodb02.dbo.bettransRnG WITH (NOLOCK)
	WHERE	[winlostdate] = @yesterday
		AND [SiteDBGroupID] > 0
	GROUP BY	[SiteDBGroupID], 
				[recommend]
	UNION ALL
	SELECT	'bettransLC' AS TableName,
			[SiteDBGroupID], 
			[Recommend],   
			CHECKSUM_AGG(CHECKSUM(	[custid], [odds], [stake], [status], [apositiontaking], [mpositiontaking], [tpositiontaking], [spositiontaking], [playerdiscount], 
									[discount], [adiscount], [sdiscount], [creator], [betfrom], [virtualrate], [actualrate], [actual_stake], [currency], [CurrencyName], 
									[Recommend], [mrecommend], [srecommend], [ip], [statusID], [balance], [Username], [transdesc], [productID], [gameID], [vendorID], [GameId3rd], 
									[TranId3rd], [RefNo], [IsSum], [winlost], [awinlost], [mwinlost], [swinlost], [playercomm], [comm], [acomm], [scomm], [Transdate3rd], [NetStake], 
									[SiteID])) AS Total_CheckSum_Agg
	FROM	bodb02.dbo.bettransLC WITH (NOLOCK)
	WHERE	[winlostdate] = @yesterday
		AND [SiteDBGroupID] > 0
	GROUP BY	[SiteDBGroupID], 
				[recommend]
	UNION ALL
	SELECT	'bettransG' AS TableName,
			g.[SiteDBGroupID], 
			c.[Recommend], 
			CHECKSUM_AGG(CHECKSUM(	g.[custid], g.[oddsid], g.[odds], g.[stake], g.[status], g.[winlost], g.[betteam], g.[creator], g.[refno], g.[betfrom], g.[checktime], 
									[apositiontaking], g.[mpositiontaking], g.[tpositiontaking], g.[awinlost], g.[mwinlost], g.[playerdiscount], g.[discount], g.[adiscount], g.[playercomm], g.[comm], 
									[acomm], g.[actualrate], g.[matchid], g.[matchdate], g.[statuswinlost], g.[ruben], g.[bettype], g.[spositiontaking], g.[swinlost], g.[sdiscount], g.[scomm], g.[statusID], 
									[virtualrate], g.[SiteID], g.[TransDesc], g.[BetID3rd], g.[actual_stake], g.[netstake])) AS Total_CheckSum_Agg
	FROM	bodb02.dbo.bettransG g WITH (NOLOCK)
		INNER JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON c.custid = g.custid
	WHERE	[winlostdate] = @yesterday
		AND g.[SiteDBGroupID] > 0
	GROUP BY	g.[SiteDBGroupID], 
				c.[recommend]
	UNION ALL
	SELECT	'translog' AS TableName,
			[SiteDBGroupID], 
			[Recommend],  
			CHECKSUM_AGG(CHECKSUM(	[custid], [odds], [stake], [status], [apositiontaking], [mpositiontaking], [tpositiontaking], [spositiontaking], 
									[playerdiscount], [discount], [adiscount], [sdiscount], [creator], [betfrom], [virtualrate], [actualrate], [actual_stake], 
									[currency], [CurrencyName], [Recommend], [mrecommend], [srecommend], [ip], [statusID], [balance], [Username], [transdesc], [productID], 
									[gameID], [eventID], [vendorID], [Gameid3rd], [Tranid3rd], [custom1], [liveindicator], [custom2], [custom3], [SiteId], 
									[checkCount])) AS Total_CheckSum_Agg
	FROM	bodb02.dbo.translog WITH (NOLOCK)
	WHERE	[winlostdate] = @yesterday
		AND [SiteDBGroupID] > 0
	GROUP BY	[SiteDBGroupID], 
				[recommend]
	UNION ALL
	SELECT	'bettransm' AS TableName,
			bm.[SiteDBGroupID],
			c.[Recommend], 
			CHECKSUM_AGG(CHECKSUM(	bm.[custid], bm.[oddsid], bm.[hdp1], bm.[hdp2], bm.[odds], bm.[stake], bm.[status], bm.[winlost], bm.[livehomescore], 
									bm.[liveawayscore], bm.[liveindicator], bm.[betteam], bm.[creator], bm.[refno], bm.[comstatus], bm.[betfrom], 
									bm.[betcheck], bm.[checktime], bm.[oddsspread], bm.[apositiontaking], bm.[mpositiontaking], bm.[tpositiontaking], bm.[awinlost], 
									bm.[mwinlost], bm.[playerdiscount], bm.[discount], bm.[adiscount], bm.[playercomm], bm.[comm], bm.[acomm], bm.[actualrate], bm.[matchid], 
									bm.[matchdate], bm.[finalodds], bm.[isfinish], bm.[statuswinlost], bm.[ruben], bm.[bettype], bm.[spositiontaking], bm.[swinlost], 
									bm.[sdiscount], bm.[scomm], bm.[statusID], bm.[transdesc], bm.[SecAcceptFlag], bm.[SecAcceptTime], bm.[LiveBetAcceptTime], 
									bm.[PriceMultiplier])) AS Total_CheckSum_Agg
	FROM	bodb02.dbo.bettransm bm WITH (NOLOCK) 
		INNER JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON c.custid = bm.custid
	WHERE	bm.[winlostdate] = @yesterday
		AND bm.[SiteDBGroupID] > 0
	GROUP BY	bm.[SiteDBGroupID], 
				c.[recommend]
END

