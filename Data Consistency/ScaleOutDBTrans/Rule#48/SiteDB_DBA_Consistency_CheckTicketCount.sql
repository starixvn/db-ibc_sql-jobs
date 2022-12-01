/*<info serverAlias="DBSIG-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SiteDB_DBA_Consistency_CheckTicketCount]
(
	@CurrentTime	DATETIME
   ,@RecommendList	VARCHAR(MAX) = NULL
   ,@TableName		VARCHAR(50) = NULL 
)
AS 
/*
	Created by: 20220819@Victoria
	Task: Check ticket count by Status - SiteDB
	DB: DBSIG-bodb02
	Revisions:
		- 20220819@Victoria: Rule #48 - Check ticket count by Status - SiteDB [Redmine:#175881]
		- 20221012@Victoria: Modify to show FromDate and ToDate
								AND replication latency with ticket odds adjustment [Redmine:#178864]	
		- 20221123@July: Support filter recommend list [Redmine:#178864]
	
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @before_yesterday SMALLDATETIME, @yesterday SMALLDATETIME
	SELECT  @before_yesterday = CONVERT(DATE, DATEADD(DAY, -2, GETDATE()))
	SELECT  @yesterday = CONVERT(DATE, DATEADD(DAY, -1, GETDATE()))
	
	IF @RecommendList IS NOT NULL
	BEGIN
		IF @TableName IN ('bettrans', 'bettransRnG', 'bettransLC','translog')
		BEGIN
			EXEC dbo.CheckTicketCount_ByRecommendList 
					@CurrentTime = @CurrentTime
				  , @RecommendList = @RecommendList
				  , @TableName = @TableName 
				  , @before_yesterday = @before_yesterday
				  , @yesterday = @yesterday
			RETURN;
		END
		ELSE IF @TableName = 'bettransG'
		BEGIN
			EXEC dbo.SiteDB_CheckTicketCount_ByRecommendList_bettransG
					@CurrentTime = @CurrentTime
				  , @RecommendList = @RecommendList
				  , @before_yesterday = @before_yesterday
				  , @yesterday = @yesterday
			RETURN;
		END
		ELSE IF @TableName = 'bettransm'
		BEGIN
			EXEC dbo.SiteDB_CheckTicketCount_ByRecommendList_bettransm
					@CurrentTime = @CurrentTime
				  , @RecommendList = @RecommendList
				  , @before_yesterday = @before_yesterday
				  , @yesterday = @yesterday
			RETURN;
		END
		ELSE IF @TableName = 'zzzbettrans'
		BEGIN
			EXEC dbo.SiteDB_CheckTicketCount_ByRecommendList_zzzbettrans
					@CurrentTime = @CurrentTime
				  , @RecommendList = @RecommendList
				  , @before_yesterday = @before_yesterday
				  , @yesterday = @yesterday
			RETURN;
		END
		ELSE IF @TableName = 'zzzbettransm'
		BEGIN
			EXEC dbo.SiteDB_CheckTicketCount_ByRecommendList_zzzbettransm
					@CurrentTime = @CurrentTime
				  , @RecommendList = @RecommendList
				  , @before_yesterday = @before_yesterday
				  , @yesterday = @yesterday
			RETURN;
		END
	END

	CREATE TABLE #tmp_betticketcheckcount
	(
		TableName VARCHAR(50),
		SiteDBGroupID SMALLINT,
		Recommend INT,
		Status NVARCHAR(10),
		TicketCount INT
	)

	INSERT INTO #tmp_betticketcheckcount
	(
			TableName,
			SiteDBGroupID, 
			Recommend,
			Status,
			TicketCount
	)
	SELECT	'bettrans' AS TableName,
			SiteDBGroupID, 
			Recommend, 
			Status, 
			COUNT(1) AS TicketCount
	FROM	dbo.bettrans WITH (NOLOCK)
	WHERE	winlostdate IN (@before_yesterday,@yesterday)
		AND transdate < @CurrentTime
	GROUP BY	SiteDBGroupID, 
				Recommend, 
				Status
	
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
	FROM	dbo.bettransRnG WITH (NOLOCK)
	WHERE	winlostdate IN (@before_yesterday,@yesterday)
		AND transdate < @CurrentTime
	GROUP BY	SiteDBGroupID, 
				Recommend, 
				Status
	
	INSERT INTO #tmp_betticketcheckcount
	(
			TableName,
			SiteDBGroupID, 
			Recommend,
			Status,
			TicketCount
	)
	SELECT	'bettransLC' AS TableName,
			SiteDBGroupID, 
			Recommend, 
			Status, 
			COUNT(1) AS TicketCount
	FROM	dbo.bettransLC WITH (NOLOCK)
	WHERE	winlostdate IN (@before_yesterday,@yesterday)
		AND transdate < @CurrentTime
	GROUP BY	SiteDBGroupID, 
				Recommend, 
				Status
	
	INSERT INTO #tmp_betticketcheckcount
	(
			TableName,
			SiteDBGroupID, 
			Recommend,
			Status,
			TicketCount
	)
	SELECT	'bettransG' AS TableName,
			b.SiteDBGroupID, 
			c.Recommend, 
			b.Status, 
			COUNT(1) AS TicketCount
	FROM	dbo.bettransG b WITH (NOLOCK)
		INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON c.custid = b.custid
	WHERE	b.winlostdate IN (@before_yesterday,@yesterday)
		AND transdate < @CurrentTime
	GROUP BY	b.SiteDBGroupID, 
				c.Recommend, 
				b.Status
	
	INSERT INTO #tmp_betticketcheckcount
	(
			TableName,
			SiteDBGroupID, 
			Recommend,
			Status,
			TicketCount
	)
	SELECT	'translog' AS TableName,
			SiteDBGroupID, 
			Recommend, 
			Status, 
			COUNT(1) AS TicketCount
	FROM	dbo.translog WITH (NOLOCK)
	WHERE	winlostdate IN (@before_yesterday,@yesterday)
		AND transdate < @CurrentTime
	GROUP BY	SiteDBGroupID, 
				Recommend, 
				Status
	
	INSERT INTO #tmp_betticketcheckcount
	(
			TableName,
			SiteDBGroupID, 
			Recommend,
			Status,
			TicketCount
	)
	SELECT	'bettransm' AS TableName,
			bm.SiteDBGroupID, 				
			c.Recommend, 
			bm.Status, 
			COUNT(1) AS TicketCount
	FROM	dbo.bettransm bm WITH (NOLOCK) 
		INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON c.custid = bm.custid
	WHERE	bm.winlostdate IN (@before_yesterday,@yesterday)
		AND bm.transdate < @CurrentTime
	GROUP BY	bm.SiteDBGroupID, 
				c.Recommend, 
				bm.Status
	
	INSERT INTO #tmp_betticketcheckcount
	(
			TableName,
			SiteDBGroupID, 
			Recommend,
			Status,
			TicketCount
	)
	SELECT	'zzzbettrans' AS TableName,
			z.SiteDBGroupID, 
			c.Recommend, 
			z.Status, 
			COUNT(1) AS TicketCount
	FROM	dbo.zzzbettrans z WITH (NOLOCK)
		INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON c.custid = z.custid
	WHERE	z.winlostdate IN (@before_yesterday,@yesterday)
		AND z.transdate < @CurrentTime
	GROUP BY	z.SiteDBGroupID, 
				c.Recommend, 
				z.Status
	
	INSERT INTO #tmp_betticketcheckcount
	(
			TableName,
			SiteDBGroupID, 
			Recommend,
			Status,
			TicketCount
	)
	SELECT	'zzzbettransm' AS TableName,
			z.SiteDBGroupID,  
			c.Recommend, 
			z.Status, 
			COUNT(1) AS TicketCount
	FROM	dbo.zzzbettransm z WITH (NOLOCK)
		INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON c.custid = z.custid
	WHERE	z.winlostdate IN (@before_yesterday,@yesterday)
		AND z.transdate < @CurrentTime
	GROUP BY	z.SiteDBGroupID, 
				c.Recommend, 
				z.Status

	SELECT TableName, SiteDBGroupID, Recommend, Status, TicketCount
	FROM #tmp_betticketcheckcount
	ORDER BY TableName, SiteDBGroupID, Recommend, Status

	SELECT @before_yesterday AS FromDate, @yesterday AS ToDate

	DROP TABLE #tmp_betticketcheckcount
END