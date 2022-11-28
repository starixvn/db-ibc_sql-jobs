/*<info serverAlias="DBCONSISTENCY-bodb_Consistency, DBSIG-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[CheckSumTicket_ByRecommendList_bettransm]
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
	DB: DBCONSISTENCY-bodb_Consistency, DBSIG-bodb02
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
		[custid] INT, [oddsid] INT, [hdp1] SMALLMONEY, [hdp2] SMALLMONEY, [odds] SMALLMONEY, [stake] MONEY, [status] NVARCHAR(10), [winlost] MONEY, [livehomescore] SMALLINT,
		[liveawayscore] SMALLINT, [liveindicator] BIT, [betteam] NVARCHAR(10), [creator] INT, [refno] BIGINT, [comstatus] NVARCHAR(20), [betfrom] NVARCHAR(3),
		[betcheck] NVARCHAR(50), [oddsspread] MONEY, [apositiontaking] SMALLMONEY, [mpositiontaking] SMALLMONEY, [tpositiontaking] SMALLMONEY, [awinlost] MONEY,
		[mwinlost] MONEY, [playerdiscount] DECIMAL(9,8), [discount] DECIMAL(9,8), [adiscount] DECIMAL(9,8), [playercomm] MONEY, [comm] MONEY, [acomm] MONEY,  [actualrate] FLOAT, [matchid] INT, 
		[matchdate] SMALLDATETIME, [finalodds] SMALLMONEY, [isfinish] CHAR(1), [statuswinlost] TINYINT, [ruben] TINYINT, [bettype] SMALLINT, [spositiontaking] SMALLMONEY, [swinlost] MONEY, 
		[sdiscount] DECIMAL(9,8), [scomm] MONEY, [statusID] TINYINT, [transdesc] NVARCHAR(1000), [SecAcceptFlag] BIT, [SecAcceptTime] TINYINT, [LiveBetAcceptTime] SMALLINT
	)
	
	INSERT INTO #tmp_recommendlist (recommend)
	SELECT DISTINCT value AS recommend
	FROM STRING_SPLIT(@RecommendList, ',')
	WHERE value <> ''

	WHILE (1=1)
	BEGIN
		UPDATE TOP (1) t
		SET IsFinish = 1, @recommend = t.recommend
		FROM #tmp_recommendlist t
		WHERE IsFinish IS NULL

		IF @@ROWCOUNT = 0 BREAK

		INSERT INTO #tmp_betticketchecksum_Detail(
				TransId, SiteDBGroupID, Recommend, Transdate,
				[custid], [oddsid], [hdp1], [hdp2], [odds], [stake], [status], [winlost], [livehomescore], 
				[liveawayscore], [liveindicator], [betteam], [creator], [refno], [comstatus], [betfrom], 
				[betcheck], [oddsspread], [apositiontaking], [mpositiontaking], [tpositiontaking], [awinlost], 
				[mwinlost], [playerdiscount], [discount], [adiscount], [playercomm], [comm], [acomm], [actualrate], [matchid], 
				[matchdate], [finalodds], [isfinish], [statuswinlost], [ruben], [bettype], [spositiontaking], [swinlost], 
				[sdiscount], [scomm], [statusID], [transdesc], [SecAcceptFlag], [SecAcceptTime], [LiveBetAcceptTime]
			)
		SELECT	bm.TransId, bm.SiteDBGroupID, c.Recommend, bm.Transdate,
				bm.[custid], bm.[oddsid], bm.[hdp1], bm.[hdp2], bm.[odds], bm.[stake], bm.[status], bm.[winlost], bm.[livehomescore], 
				bm.[liveawayscore], bm.[liveindicator], bm.[betteam], bm.[creator], bm.[refno], bm.[comstatus], bm.[betfrom], 
				bm.[betcheck], bm.[oddsspread], bm.[apositiontaking], bm.[mpositiontaking], bm.[tpositiontaking], bm.[awinlost], 
				bm.[mwinlost], bm.[playerdiscount], bm.[discount], bm.[adiscount], bm.[playercomm], bm.[comm], bm.[acomm], bm.[actualrate], bm.[matchid], 
				bm.[matchdate], bm.[finalodds], bm.[isfinish], bm.[statuswinlost], bm.[ruben], bm.[bettype], bm.[spositiontaking], bm.[swinlost], 
				bm.[sdiscount], bm.[scomm], bm.[statusID], bm.[transdesc], bm.[SecAcceptFlag], bm.[SecAcceptTime], bm.[LiveBetAcceptTime]
		FROM	bodb02.dbo.bettransm bm WITH (NOLOCK) 
			INNER JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON c.custid = bm.custid
		WHERE	bm.[winlostdate] IN (@before_yesterday,@yesterday)
			AND bm.[transdate] < @CurrentTime
			AND c.recommend = @recommend
		
		-- Remove duplicate transid if page split occurs
		;WITH cteDuplicateTransId
		AS(
			SELECT	TransId
					,ROW_NUMBER() OVER(PARTITION BY TransId, Transdate ORDER BY TransId) as rn 
			FROM	#tmp_betticketchecksum_Detail
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
		SELECT	'bettransm' AS TableName,
				SiteDBGroupID, 
				Recommend, 
				CHECKSUM_AGG(CHECKSUM(	[custid], [oddsid], [hdp1], [hdp2], [odds], [stake], [status], [winlost], [livehomescore], 
										[liveawayscore], [liveindicator], [betteam], [creator], [refno], [comstatus], [betfrom], 
										[betcheck], [oddsspread], [apositiontaking], [mpositiontaking], [tpositiontaking], [awinlost], 
										[mwinlost], [playerdiscount], [discount], [adiscount], [playercomm], [comm], [acomm], CONVERT(DECIMAL(19,8), [actualrate]), [matchid], 
										[matchdate], [finalodds], [isfinish], [statuswinlost], [ruben], [bettype], [spositiontaking], [swinlost], 
										[sdiscount], [scomm], [statusID], [transdesc], [SecAcceptFlag], [SecAcceptTime], [LiveBetAcceptTime]
									)) AS TotalCheckSumAgg
		FROM	#tmp_betticketchecksum_Detail
		GROUP BY	SiteDBGroupID, 
					recommend

	END

	SELECT TableName, SiteDBGroupID, Recommend, TotalCheckSumAgg
	FROM #tmp_betticketchecksum
	ORDER BY TableName, SiteDBGroupID, Recommend

	SELECT @before_yesterday AS FromDate, @yesterday AS ToDate

	DROP TABLE #tmp_recommendlist
	DROP TABLE #tmp_betticketchecksum
	DROP TABLE #tmp_betticketchecksum_detail
END


