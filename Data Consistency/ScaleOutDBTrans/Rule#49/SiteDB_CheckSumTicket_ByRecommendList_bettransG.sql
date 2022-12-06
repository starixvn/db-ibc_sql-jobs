/*<info serverAlias="DBSIG-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[SiteDB_CheckSumTicket_ByRecommendList_bettransG]
(
	@CurrentTime		DATETIME
   ,@RecommendList		VARCHAR(MAX) 
   ,@before_yesterday	SMALLDATETIME
   ,@yesterday			SMALLDATETIME
)
AS 
/*
	Created by: 20221124@July
	Task: CheckSum ticket
	DB: DBSIG-bodb02
	Revisions:
		- 20221124@July: Clone SP - Support filter recommend list [Redmine:#178864]
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @recommend INT; 
	
	CREATE TABLE #tmp_recommendlist (recommend INT ,IsFinish BIT)

	CREATE TABLE #tmp_betticketchecksum
	(
		TableName VARCHAR(50),
		SiteDBGroupID SMALLINT,
		Recommend INT,
		TotalCheckSumAgg BIGINT
	)
	CREATE TABLE #tmp_betticketchecksum_detail
	(
		TransId BIGINT, SiteDBGroupID SMALLINT, Recommend INT, Transdate DATETIME,
		[custid] INT, [oddsid] INT, [odds] SMALLMONEY, [stake] MONEY, [status] NVARCHAR(10), [winlost] MONEY, [betteam] NVARCHAR(10), [creator] INT, [refno] BIGINT, [betfrom] NVARCHAR(3),
		[apositiontaking] SMALLMONEY, [mpositiontaking] SMALLMONEY, [tpositiontaking] SMALLMONEY, [awinlost] MONEY, [mwinlost] MONEY, [playerdiscount] DECIMAL(9,8), [discount] DECIMAL(9,8), [adiscount] DECIMAL(9,8), [playercomm] MONEY, [comm] MONEY, 
		[acomm] MONEY,  [actualrate] FLOAT, [matchid] INT, matchdate SMALLDATETIME, [statuswinlost] TINYINT, [ruben] TINYINT, [bettype] SMALLINT, [spositiontaking] SMALLMONEY, [swinlost] MONEY, [sdiscount] DECIMAL(9,8), [scomm] MONEY, [statusID] TINYINT,
		[SiteID] VARCHAR(7), [TransDesc] NVARCHAR(2000), [BetID3rd] NVARCHAR(50), [actual_stake] MONEY, [netstake] MONEY
	)
	
	INSERT INTO #tmp_recommendlist (recommend)
	SELECT DISTINCT value AS recommend
	FROM STRING_SPLIT(@RecommendList, ',')
	WHERE value <> ''

	WHILE (1=1)
	BEGIN
		TRUNCATE TABLE #tmp_betticketchecksum_detail;
		
		UPDATE TOP (1) t
		SET IsFinish = 1, @recommend = t.recommend
		FROM #tmp_recommendlist t
		WHERE IsFinish IS NULL

		IF @@ROWCOUNT = 0 BREAK

		INSERT INTO #tmp_betticketchecksum_detail(
				TransId, SiteDBGroupID, Recommend, Transdate,
				[custid], [oddsid], [odds], [stake], [status], [winlost], [betteam], [creator], [refno], [betfrom],
				[apositiontaking], [mpositiontaking], [tpositiontaking], [awinlost], [mwinlost], [playerdiscount], [discount], [adiscount], [playercomm], [comm], 
				[acomm], [actualrate], [matchid], [matchdate], [statuswinlost], [ruben], [bettype], [spositiontaking], [swinlost], [sdiscount], [scomm], [statusID], 
				[SiteID], [TransDesc], [BetID3rd], [actual_stake], [netstake]
			)
		SELECT	g.TransId, g.SiteDBGroupID, c.Recommend, g.Transdate,
				g.[custid], g.[oddsid], g.[odds], g.[stake], g.[status], g.[winlost], g.[betteam], g.[creator], g.[refno], g.[betfrom],
				g.[apositiontaking], g.[mpositiontaking], g.[tpositiontaking], g.[awinlost], g.[mwinlost], g.[playerdiscount], g.[discount], g.[adiscount], g.[playercomm], g.[comm], 
				g.[acomm], g.[actualrate], g.[matchid], g.[matchdate], g.[statuswinlost], g.[ruben], g.[bettype], g.[spositiontaking], g.[swinlost], g.[sdiscount], g.[scomm], g.[statusID], 
				g.[SiteID], g.[TransDesc], g.[BetID3rd], g.[actual_stake], g.[netstake]
		FROM	dbo.bettransG g WITH (NOLOCK, INDEX = [IX_winlostdate])
			INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON c.custid = g.custid
		WHERE	g.winlostdate IN (@before_yesterday,@yesterday)
			AND g.transdate < @CurrentTime
			AND c.recommend = @recommend
		
		-- Remove duplicate transid if page split occurs
		;WITH cteDuplicateTransId
		AS(
			SELECT	TransId
					,ROW_NUMBER() OVER(PARTITION BY TransId ORDER BY TransId) as rn 
			FROM	#tmp_betticketchecksum_detail
		)
		DELETE 
		FROM	cteDuplicateTransId
		WHERE	rn > 1

		INSERT INTO #tmp_betticketchecksum
		(
				TableName,
				SiteDBGroupID, 
				Recommend,
				TotalCheckSumAgg
		)
		SELECT	'bettransG' AS TableName,
				SiteDBGroupID, 
				Recommend, 
				CHECKSUM_AGG(CHECKSUM(	[custid], [oddsid], [odds], [stake], [status], [winlost], [betteam], [creator], [refno], [betfrom],
										[apositiontaking], [mpositiontaking], [tpositiontaking], [awinlost], [mwinlost], [playerdiscount], [discount], [adiscount], [playercomm], [comm], 
										[acomm], CONVERT(DECIMAL(19,8), [actualrate]), [matchid], [matchdate], [statuswinlost], [ruben], [bettype], [spositiontaking], [swinlost], [sdiscount], [scomm], [statusID], 
										[SiteID], [TransDesc], [BetID3rd], [actual_stake], [netstake]
							)) AS TotalCheckSumAgg
		FROM	#tmp_betticketchecksum_detail
		GROUP BY	SiteDBGroupID, 
					Recommend

	END

	SELECT TableName, SiteDBGroupID, Recommend, TotalCheckSumAgg
	FROM #tmp_betticketchecksum
	ORDER BY TableName, SiteDBGroupID, Recommend

	SELECT @before_yesterday AS FromDate, @yesterday AS ToDate

	DROP TABLE #tmp_recommendlist
	DROP TABLE #tmp_betticketchecksum
	DROP TABLE #tmp_betticketchecksum_detail
END


