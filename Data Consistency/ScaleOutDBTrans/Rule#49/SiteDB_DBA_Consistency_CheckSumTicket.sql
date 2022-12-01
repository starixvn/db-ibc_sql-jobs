/*<info serverAlias="DBSIG-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[SiteDB_DBA_Consistency_CheckSumTicket]
(
	@CurrentTime	DATETIME
   ,@RecommendList	VARCHAR(MAX) = NULL
   ,@TableName		VARCHAR(50) = NULL
)
AS 
/*
	Created by: 20220819@Victoria
	Task: CheckSum ticket - SiteDB
	DB: DBSIG-bodb02
	Revisions:
		- 20220819@Victoria: Rule #49 - CheckSum ticket - SiteDB [Redmine:#175881]
		- 20221012@Victoria: Modify to show FromDate and ToDate
								AND replication latency with ticket odds adjustment [Redmine:#178864]	
		- 20221019@Victoria: Remove VirtualRate inside of CheckSum Function [Redmine:#178864]
		- 20221028@Victoria: Remove checktime inside of CheckSum Function [Redmine:#178864]
		- 20221102@Victoria: Convert ActualRate with a Float data type to a DECIMAL [Redmine:#178864]  
		- 20221123@July: Support filter recommend list [Redmine:#178864]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @before_yesterday SMALLDATETIME, @yesterday SMALLDATETIME
	SELECT  @before_yesterday = CONVERT(DATE, DATEADD(DAY, -2, GETDATE()))
	SELECT  @yesterday = CONVERT(DATE, DATEADD(DAY, -1, GETDATE()))

	IF @RecommendList IS NOT NULL
	BEGIN
		IF @TableName IN ('bettrans', 'bettransRnG', 'bettranLC','translog')
		BEGIN
			EXEC dbo.CheckSumTicket_ByRecommendList 
					@CurrentTime = @CurrentTime
				  , @RecommendList = @RecommendList
				  , @TableName = @TableName 
				  , @before_yesterday = @before_yesterday
				  , @yesterday = @yesterday
			RETURN;
		END
		ELSE IF @TableName = 'bettransG'
		BEGIN
			EXEC dbo.SiteDB_CheckSumTicket_ByRecommendList_bettransG
					@CurrentTime = @CurrentTime
				  , @RecommendList = @RecommendList
				  , @before_yesterday = @before_yesterday
				  , @yesterday = @yesterday
			RETURN;
		END
		ELSE IF @TableName = 'bettransm'
		BEGIN
			EXEC dbo.SiteDB_CheckSumTicket_ByRecommendList_bettransm
					@CurrentTime = @CurrentTime
				  , @RecommendList = @RecommendList
				  , @before_yesterday = @before_yesterday
				  , @yesterday = @yesterday
			RETURN;
		END
	END

	CREATE TABLE #tmp_betticketchecksum
	(
		TableName VARCHAR(50),
		SiteDBGroupID SMALLINT,
		Recommend INT,
		TotalCheckSumAgg BIGINT
	)

	INSERT INTO #tmp_betticketchecksum
	(
			TableName,
			SiteDBGroupID, 
			Recommend,
			TotalCheckSumAgg
	)
	SELECT	'bettrans' AS TableName,
			[SiteDBGroupID], 
			[Recommend], 
			CHECKSUM_AGG(CHECKSUM(	[custid], [oddsid], [hdp1], [hdp2], [odds], [stake], [status], [winlost], [awinlost], [mwinlost], [playercomm], [comm], [acomm], 
									[apositiontaking], [mpositiontaking], [tpositiontaking], [playerdiscount], [discount], [adiscount], [livehomescore], [liveawayscore], 
									[liveindicator], [betteam], [creator], [refno], [comstatus], [betfrom], [betcheck], [oddsspread], CONVERT(DECIMAL(19,8), [actualrate]), [matchid], 
									[Recommend], [mrecommend], [ruben], [betid], [statuswinlost], [modds], [bettype], [betdaqid], [actual_stake], [currency], [ip], [transdesc], 
									[sdiscount], [scomm], [spositiontaking], [swinlost], [srecommend], [Username], [CurrencyName], [oddstype], [statusID], [currency2], 
									[balance], [transid2], [WalletType], [BonusID], [RefCode])) AS TotalCheckSumAgg
	FROM	dbo.bettrans WITH (NOLOCK)
	WHERE	[winlostdate] IN (@before_yesterday,@yesterday)
		AND [transdate] < @CurrentTime
	GROUP BY	[SiteDBGroupID], 
				[recommend]
	
	INSERT INTO #tmp_betticketchecksum
	(
			TableName,
			SiteDBGroupID, 
			Recommend,
			TotalCheckSumAgg
	)
	SELECT	'bettransRnG' AS TableName,
			[SiteDBGroupID],  
			[Recommend],  
			CHECKSUM_AGG(CHECKSUM(	[custid], [odds], [stake], [status], [apositiontaking], [mpositiontaking], [tpositiontaking], [spositiontaking], [playerdiscount], [discount], 
									[adiscount], [sdiscount], [creator], [betfrom], CONVERT(DECIMAL(19,8), [actualrate]), [actual_stake], [currency], [CurrencyName], [Recommend], 
									[mrecommend], [srecommend], [ip], [statusID], [balance], [Username], [transdesc], [productID], [gameID], [vendorID], [GameId3rd], 
									[TranId3rd], [RefNo], [IsSum], [winlost], [awinlost], [mwinlost], [swinlost], [playercomm], [comm], [acomm], [scomm], [Transdate3rd], 
									[SiteID], [Additional], [JackpotInfo], [RefNo2], [ContributionRate], [BetStake], [ContributionStake3rd])) AS TotalCheckSumAgg
	FROM	dbo.bettransRnG WITH (NOLOCK)
	WHERE	[winlostdate] IN (@before_yesterday,@yesterday)
		AND [transdate] < @CurrentTime
	GROUP BY	[SiteDBGroupID], 
				[recommend]
	
	INSERT INTO #tmp_betticketchecksum
	(
			TableName,
			SiteDBGroupID, 
			Recommend,
			TotalCheckSumAgg
	)
	SELECT	'bettransLC' AS TableName,
			[SiteDBGroupID],  
			[Recommend],   
			CHECKSUM_AGG(CHECKSUM(	[custid], [odds], [stake], [status], [apositiontaking], [mpositiontaking], [tpositiontaking], [spositiontaking], [playerdiscount], 
									[discount], [adiscount], [sdiscount], [creator], [betfrom], CONVERT(DECIMAL(19,8), [actualrate]), [actual_stake], [currency], [CurrencyName], 
									[Recommend], [mrecommend], [srecommend], [ip], [statusID], [balance], [Username], [transdesc], [productID], [gameID], [vendorID], [GameId3rd], 
									[TranId3rd], [RefNo], [IsSum], [winlost], [awinlost], [mwinlost], [swinlost], [playercomm], [comm], [acomm], [scomm], [Transdate3rd], [NetStake], 
									[SiteID])) AS TotalCheckSumAgg
	FROM	dbo.bettransLC WITH (NOLOCK)
	WHERE	[winlostdate] IN (@before_yesterday,@yesterday)
		AND [transdate] < @CurrentTime
	GROUP BY	[SiteDBGroupID], 
				[recommend]
	
	INSERT INTO #tmp_betticketchecksum
	(
			TableName,
			SiteDBGroupID, 
			Recommend,
			TotalCheckSumAgg
	)
	SELECT	'bettransG' AS TableName,
			g.[SiteDBGroupID],  
			c.[Recommend], 
			CHECKSUM_AGG(CHECKSUM(	g.[custid], g.[oddsid], g.[odds], g.[stake], g.[status], g.[winlost], g.[betteam], g.[creator], g.[refno], g.[betfrom],
									g.[apositiontaking], g.[mpositiontaking], g.[tpositiontaking], g.[awinlost], g.[mwinlost], g.[playerdiscount], g.[discount], g.[adiscount], g.[playercomm], g.[comm], 
									g.[acomm], CONVERT(DECIMAL(19,8), g.[actualrate]), g.[matchid], g.[matchdate], g.[statuswinlost], g.[ruben], g.[bettype], g.[spositiontaking], g.[swinlost], g.[sdiscount], g.[scomm], g.[statusID], 
									g.[SiteID], g.[TransDesc], g.[BetID3rd], g.[actual_stake], g.[netstake])) AS TotalCheckSumAgg
	FROM	dbo.bettransG g WITH (NOLOCK)
		INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON c.custid = g.custid
	WHERE	g.[winlostdate] IN (@before_yesterday,@yesterday)
		AND g.[transdate] < @CurrentTime
	GROUP BY	g.[SiteDBGroupID], 
				c.[recommend]
	
	INSERT INTO #tmp_betticketchecksum
	(
			TableName,
			SiteDBGroupID, 
			Recommend,
			TotalCheckSumAgg
	)
	SELECT	'translog' AS TableName,
			[SiteDBGroupID], 
			[Recommend],  
			CHECKSUM_AGG(CHECKSUM(	[custid], [odds], [stake], [status], [apositiontaking], [mpositiontaking], [tpositiontaking], [spositiontaking], 
									[playerdiscount], [discount], [adiscount], [sdiscount], [creator], [betfrom], CONVERT(DECIMAL(19,8), [actualrate]), [actual_stake], 
									[currency], [CurrencyName], [Recommend], [mrecommend], [srecommend], [ip], [statusID], [balance], [Username], [transdesc], [productID], 
									[gameID], [eventID], [vendorID], [Gameid3rd], [Tranid3rd], [custom1], [liveindicator], [custom2], [custom3], [SiteId], 
									[checkCount])) AS TotalCheckSumAgg
	FROM	dbo.translog WITH (NOLOCK)
	WHERE	[winlostdate] IN (@before_yesterday,@yesterday)
		AND [transdate] < @CurrentTime
	GROUP BY	[SiteDBGroupID], 
				[recommend]
	
	INSERT INTO #tmp_betticketchecksum
	(
			TableName,
			SiteDBGroupID, 
			Recommend,
			TotalCheckSumAgg
	)
	SELECT	'bettransm' AS TableName,
			bm.[SiteDBGroupID], 
			c.[Recommend], 
			CHECKSUM_AGG(CHECKSUM(	bm.[custid], bm.[oddsid], bm.[hdp1], bm.[hdp2], bm.[odds], bm.[stake], bm.[status], bm.[winlost], bm.[livehomescore], 
									bm.[liveawayscore], bm.[liveindicator], bm.[betteam], bm.[creator], bm.[refno], bm.[comstatus], bm.[betfrom], 
									bm.[betcheck], bm.[oddsspread], bm.[apositiontaking], bm.[mpositiontaking], bm.[tpositiontaking], bm.[awinlost], 
									bm.[mwinlost], bm.[playerdiscount], bm.[discount], bm.[adiscount], bm.[playercomm], bm.[comm], bm.[acomm], CONVERT(DECIMAL(19,8), bm.[actualrate]), bm.[matchid], 
									bm.[matchdate], bm.[finalodds], bm.[isfinish], bm.[statuswinlost], bm.[ruben], bm.[bettype], bm.[spositiontaking], bm.[swinlost], 
									bm.[sdiscount], bm.[scomm], bm.[statusID], bm.[transdesc], bm.[SecAcceptFlag], bm.[SecAcceptTime], bm.[LiveBetAcceptTime])) AS TotalCheckSumAgg
	FROM	dbo.bettransm bm WITH (NOLOCK) 
		INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON c.custid = bm.custid
	WHERE	bm.[winlostdate] IN (@before_yesterday,@yesterday)
		AND bm.[transdate] < @CurrentTime
	GROUP BY	bm.[SiteDBGroupID], 
				c.[recommend]
	
	SELECT TableName, SiteDBGroupID, Recommend, TotalCheckSumAgg
	FROM #tmp_betticketchecksum
	ORDER BY TableName, SiteDBGroupID, Recommend

	SELECT @before_yesterday AS FromDate, @yesterday AS ToDate

	DROP TABLE #tmp_betticketchecksum
END

