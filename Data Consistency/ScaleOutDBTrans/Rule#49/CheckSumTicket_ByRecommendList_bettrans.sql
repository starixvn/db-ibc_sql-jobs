/*<info serverAlias="DBCONSISTENCY-bodb_Consistency, DBSIG-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[CheckSumTicket_ByRecommendList_bettrans]
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
		TransId BIGINT, SiteDBGroupID SMALLINT, Transdate DATETIME, 
		[custid] INT, [oddsid] INT, [hdp1] SMALLMONEY, [hdp2] SMALLMONEY, [odds] SMALLMONEY, [stake] MONEY, [status] NVARCHAR(10), [winlost] MONEY, [awinlost] MONEY, [mwinlost] MONEY, [playercomm] MONEY, [comm] MONEY, [acomm] MONEY, 
		[apositiontaking] SMALLMONEY, [mpositiontaking] SMALLMONEY, [tpositiontaking] SMALLMONEY, [playerdiscount] DECIMAL(9,8), [discount] DECIMAL(9,8), [adiscount] DECIMAL(9,8), [livehomescore] SMALLINT, [liveawayscore] SMALLINT, 
		[liveindicator] BIT, [betteam] NVARCHAR(10), [creator] INT, [refno] BIGINT, [comstatus] NVARCHAR(20), [betfrom] NVARCHAR(3), [betcheck] NVARCHAR(50), [oddsspread] MONEY,  [actualrate] FLOAT, [matchid] INT, 
		[Recommend] INT, [mrecommend] INT, [ruben] TINYINT, [betid] BIGINT, [statuswinlost] TINYINT, [modds] SMALLMONEY, [bettype] SMALLINT, [betdaqid] BIGINT, [actual_stake] MONEY, [currency] TINYINT, [ip] VARCHAR(45), [transdesc] NVARCHAR(1000), 
		[sdiscount] DECIMAL(9,8), [scomm] MONEY, [spositiontaking] SMALLMONEY, [swinlost] MONEY, [srecommend] INT, [Username] NVARCHAR(50), [CurrencyName] NVARCHAR(50), [oddstype] TINYINT, [statusID] TINYINT, [currency2] TINYINT, 
		[balance] MONEY, [transid2] BIGINT, [WalletType] TINYINT, [BonusID] INT, [RefCode] BIGINT
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
				TransId, SiteDBGroupID, Transdate,
				[custid], [oddsid], [hdp1], [hdp2], [odds], [stake], [status], [winlost], [awinlost], [mwinlost], [playercomm], [comm], [acomm], 
				[apositiontaking], [mpositiontaking], [tpositiontaking], [playerdiscount], [discount], [adiscount], [livehomescore], [liveawayscore], 
				[liveindicator], [betteam], [creator], [refno], [comstatus], [betfrom], [betcheck], [oddsspread], [actualrate], [matchid], 
				[Recommend], [mrecommend], [ruben], [betid], [statuswinlost], [modds], [bettype], [betdaqid], [actual_stake], [currency], [ip], [transdesc], 
				[sdiscount], [scomm], [spositiontaking], [swinlost], [srecommend], [Username], [CurrencyName], [oddstype], [statusID], [currency2], 
				[balance], [transid2], [WalletType], [BonusID], [RefCode]
			)
		SELECT	TransId, SiteDBGroupID, Transdate,
				[custid], [oddsid], [hdp1], [hdp2], [odds], [stake], [status], [winlost], [awinlost], [mwinlost], [playercomm], [comm], [acomm], 
				[apositiontaking], [mpositiontaking], [tpositiontaking], [playerdiscount], [discount], [adiscount], [livehomescore], [liveawayscore], 
				[liveindicator], [betteam], [creator], [refno], [comstatus], [betfrom], [betcheck], [oddsspread], [actualrate], [matchid], 
				[Recommend], [mrecommend], [ruben], [betid], [statuswinlost], [modds], [bettype], [betdaqid], [actual_stake], [currency], [ip], [transdesc], 
				[sdiscount], [scomm], [spositiontaking], [swinlost], [srecommend], [Username], [CurrencyName], [oddstype], [statusID], [currency2], 
				[balance], [transid2], [WalletType], [BonusID], [RefCode]
		FROM	bodb02.dbo.bettrans WITH (NOLOCK, INDEX = [IX_recommend])
		WHERE winlostdate IN (@before_yesterday,@yesterday)
			AND transdate < @CurrentTime
			AND recommend = @recommend
		
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
		SELECT	'bettrans' AS TableName,
				SiteDBGroupID, 
				Recommend, 
				CHECKSUM_AGG(CHECKSUM(	[custid], [oddsid], [hdp1], [hdp2], [odds], [stake], [status], [winlost], [awinlost], [mwinlost], [playercomm], [comm], [acomm], 
										[apositiontaking], [mpositiontaking], [tpositiontaking], [playerdiscount], [discount], [adiscount], [livehomescore], [liveawayscore], 
										[liveindicator], [betteam], [creator], [refno], [comstatus], [betfrom], [betcheck], [oddsspread], CONVERT(DECIMAL(19,8), [actualrate]), [matchid], 
										[Recommend], [mrecommend], [ruben], [betid], [statuswinlost], [modds], [bettype], [betdaqid], [actual_stake], [currency], [ip], [transdesc], 
										[sdiscount], [scomm], [spositiontaking], [swinlost], [srecommend], [Username], [CurrencyName], [oddstype], [statusID], [currency2], 
										[balance], [transid2], [WalletType], [BonusID], [RefCode]
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


