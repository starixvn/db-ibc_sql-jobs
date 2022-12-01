/*<info serverAlias="DBCONSISTENCY-bodb_Consistency, DBSIG-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[CheckSumTicket_ByRecommendList_translog]
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
		Translogid BIGINT, SiteDBGroupID SMALLINT, Transdate DATETIME,
		[custid] INT, [odds] SMALLMONEY, [stake] MONEY, [status] NVARCHAR(10), [apositiontaking] SMALLMONEY, [mpositiontaking] SMALLMONEY, [tpositiontaking] SMALLMONEY, [spositiontaking] SMALLMONEY, 
		[playerdiscount] DECIMAL(9,8), [discount] DECIMAL(9,8), [adiscount] DECIMAL(9,8), [sdiscount] DECIMAL(9,8), [creator] INT, [betfrom] VARCHAR(3), [actualrate] FLOAT, [actual_stake] MONEY, 
		[currency] TINYINT, [CurrencyName] NVARCHAR(50), [Recommend] INT, [mrecommend] INT, [srecommend] INT, [ip] VARCHAR(45), [statusID] TINYINT, [balance] MONEY, [Username] NVARCHAR(50), [transdesc] NVARCHAR(1000), [productID] SMALLINT, 
		[gameID] INT, [eventID] INT, [vendorID] INT, [Gameid3rd] NVARCHAR(50), [Tranid3rd] NVARCHAR(64), [custom1] VARCHAR(50), [liveindicator] BIT, [custom2] VARCHAR(50), [custom3] VARCHAR(50), [SiteId] VARCHAR(7), [checkCount] TINYINT
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
				Translogid, SiteDBGroupID, Transdate,
				[custid], [odds], [stake], [status], [apositiontaking], [mpositiontaking], [tpositiontaking], [spositiontaking], 
				[playerdiscount], [discount], [adiscount], [sdiscount], [creator], [betfrom], [actualrate], [actual_stake], 
				[currency], [CurrencyName], [Recommend], [mrecommend], [srecommend], [ip], [statusID], [balance], [Username], [transdesc], [productID], 
				[gameID], [eventID], [vendorID], [Gameid3rd], [Tranid3rd], [custom1], [liveindicator], [custom2], [custom3], [SiteId], [checkCount]
			)
		SELECT	Translogid, SiteDBGroupID, Transdate,
				[custid], [odds], [stake], [status], [apositiontaking], [mpositiontaking], [tpositiontaking], [spositiontaking], 
				[playerdiscount], [discount], [adiscount], [sdiscount], [creator], [betfrom], [actualrate], [actual_stake], 
				[currency], [CurrencyName], [Recommend], [mrecommend], [srecommend], [ip], [statusID], [balance], [Username], [transdesc], [productID], 
				[gameID], [eventID], [vendorID], [Gameid3rd], [Tranid3rd], [custom1], [liveindicator], [custom2], [custom3], [SiteId], [checkCount]
		FROM	bodb02.dbo.translog WITH (NOLOCK, INDEX = [IX_recommend])
		WHERE	winlostdate IN (@before_yesterday,@yesterday)
			AND transdate < @CurrentTime
			AND recommend = @recommend
		
		-- Remove duplicate transid if page split occurs
		;WITH cteDuplicateTransId
		AS(
			SELECT	Translogid
					,ROW_NUMBER() OVER(PARTITION BY Translogid ORDER BY Translogid) as rn 
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
		SELECT	'translog' AS TableName,
				SiteDBGroupID, 
				Recommend,  
				CHECKSUM_AGG(CHECKSUM(	[custid], [odds], [stake], [status], [apositiontaking], [mpositiontaking], [tpositiontaking], [spositiontaking], 
										[playerdiscount], [discount], [adiscount], [sdiscount], [creator], [betfrom], CONVERT(DECIMAL(19,8), [actualrate]), [actual_stake], 
										[currency], [CurrencyName], [Recommend], [mrecommend], [srecommend], [ip], [statusID], [balance], [Username], [transdesc], [productID], 
										[gameID], [eventID], [vendorID], [Gameid3rd], [Tranid3rd], [custom1], [liveindicator], [custom2], [custom3], [SiteId], [checkCount]
								)) AS TotalCheckSumAgg
		FROM	#tmp_betticketchecksum_detail
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


