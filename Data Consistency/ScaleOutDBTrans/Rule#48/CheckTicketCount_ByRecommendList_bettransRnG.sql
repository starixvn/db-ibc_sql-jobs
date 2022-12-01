/*<info serverAlias="DBCONSISTENCY-bodb_Consistency, DBSIG-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[CheckTicketCount_ByRecommendList_bettransRnG]
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
DB: DBCONSISTENCY-bodb_Consistency, DBSIG-bodb02
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
		Transdate DATETIME,
		Status NVARCHAR(10)
	)

	INSERT INTO #tmp_recommendlist (recommend)
	SELECT DISTINCT value AS recommend
	FROM STRING_SPLIT(@RecommendList, ',')
	WHERE value <> ''

	WHILE (1=1)
	BEGIN
		TRUNCATE TABLE #tmp_betticketcheckcount_detail;

		UPDATE TOP (1) t
		SET IsFinish = 1, @recommend = t.recommend
		FROM #tmp_recommendlist t
		WHERE IsFinish IS NULL

		IF @@ROWCOUNT = 0 BREAK

		INSERT INTO #tmp_betticketcheckcount_detail(
				TransId, SiteDBGroupID, Recommend, Transdate, Status
			)
		SELECT	TransId, SiteDBGroupID, Recommend, Transdate, Status
		FROM	bodb02.dbo.bettransRnG WITH (NOLOCK, INDEX = [IX_recommend])
		WHERE	winlostdate IN (@before_yesterday,@yesterday)
			AND transdate < @CurrentTime
			AND recommend = @recommend
		
		-- Remove duplicate transid if page split occurs
		;WITH cteDuplicateTransId
		AS(
			SELECT	TransId
					,ROW_NUMBER() OVER(PARTITION BY TransId, Transdate ORDER BY TransId) as rn 
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
		SELECT	'bettransRnG' AS TableName,
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