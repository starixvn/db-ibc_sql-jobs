/*<info serverAlias="DBSIG-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[SiteDB_CheckTicketCount_ByRecommendList_bettransG]
(
	@CurrentTime		DATETIME
   ,@RecommendList		VARCHAR(MAX) 
   ,@before_yesterday	SMALLDATETIME
   ,@yesterday			SMALLDATETIME
)
AS 
/*
	Created by: 20221124@July
	Task: Check ticket count by Status
	DB: DBSIG-bodb02
	Revisions:
		- 20221124@July: Clone SP - Support filter recommend list [Redmine:#178864]
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @recommend INT; 
	
	CREATE TABLE #tmp_recommendlist (recommend INT ,IsFinish BIT)

	CREATE TABLE #tmp_betticketcheckcount
	(
		TableName VARCHAR(50),
		SiteDBGroupID SMALLINT,
		Recommend INT,
		Status NVARCHAR(10),
		TicketCount INT
	)

	CREATE TABLE #tmp_betticketcheckcount_detail
	(
		TransId BIGINT, 
		SiteDBGroupID SMALLINT,
		Recommend INT,
		transdate DATETIME,
		Status NVARCHAR(10)
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

		INSERT INTO #tmp_betticketcheckcount_detail(
				TransId, SiteDBGroupID, Recommend, transdate, Status
			)
		SELECT	b.TransId, b.SiteDBGroupID, c.Recommend, b.transdate, b.Status
		FROM dbo.bettransG b WITH (NOLOCK, INDEX = [IX_winlostdate])
			INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON c.custid = b.custid
		WHERE	b.winlostdate IN (@before_yesterday,@yesterday)
			AND b.transdate < @CurrentTime
			AND c.recommend = @recommend
		
		-- Remove duplicate transid if page split occurs
		;WITH cteDuplicateTransId
		AS(
			SELECT	TransId
					,ROW_NUMBER() OVER(PARTITION BY TransId, transdate ORDER BY TransId) as rn 
			FROM	#tmp_betticketcheckcount_detail
		)
		DELETE 
		FROM	cteDuplicateTransId
		WHERE	rn > 1

		INSERT INTO #tmp_betticketcheckcount
		(
				TableName,
				SiteDBGroupID, 
				Recommend,
				Status,
				TicketCount
		)
		SELECT	'bettransG' AS TableName,
				SiteDBGroupID, 
				Recommend, 
				Status, 
				COUNT(1) AS TicketCount
		FROM #tmp_betticketcheckcount_detail
		GROUP BY	SiteDBGroupID, 
					Recommend, 
					Status

	END
	
	SELECT TableName, SiteDBGroupID, Recommend, Status, TicketCount
	FROM #tmp_betticketcheckcount
	ORDER BY TableName, SiteDBGroupID, Recommend,  Status

	SELECT @before_yesterday AS FromDate, @yesterday AS ToDate
	
	DROP TABLE #tmp_recommendlist
	DROP TABLE #tmp_betticketcheckcount
	DROP TABLE #tmp_betticketcheckcount_detail
END