/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_CheckTicketCount]
AS 
/*
Created by: 20220819@Victoria
Task: Check ticket count by Status - DBCONSISTENCY
DB: DBCONSISTENCY-bodb_Consistency
Revisions:
	- 20220819@Victoria: Rule #48 - Check ticket count by Status - DBCONSISTENCY [Redmine:#175881]
	
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @yesterday SMALLDATETIME
	SELECT  @yesterday = CONVERT(DATE, DATEADD(DAY, -1, GETDATE()))

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
	FROM	bodb02.dbo.bettrans WITH (NOLOCK)
	WHERE	winlostdate = @yesterday
		AND SiteDBGroupID > 0
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
	FROM bodb02.dbo.bettransRnG WITH (NOLOCK)
	WHERE	winlostdate = @yesterday
		AND SiteDBGroupID > 0
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
	FROM bodb02.dbo.bettransLC WITH (NOLOCK)
	WHERE	winlostdate = @yesterday
		AND SiteDBGroupID > 0
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
	FROM bodb02.dbo.bettransG b WITH (NOLOCK)
		INNER JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON c.custid = b.custid
	WHERE	winlostdate = @yesterday
		AND SiteDBGroupID > 0
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
	FROM bodb02.dbo.translog WITH (NOLOCK)
	WHERE	winlostdate = @yesterday
		AND SiteDBGroupID > 0
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
	FROM bodb02.dbo.bettransm bm WITH (NOLOCK) 
		INNER JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON c.custid = bm.custid
	WHERE	bm.winlostdate = @yesterday
		AND bm.SiteDBGroupID > 0
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
	FROM bodb02.dbo.zzzbettrans z WITH (NOLOCK)
		INNER JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON c.custid = z.custid
	WHERE	z.winlostdate = @yesterday
		AND z.SiteDBGroupID > 0
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
	FROM bodb02.dbo.zzzbettransm z WITH (NOLOCK)
		INNER JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON c.custid = z.custid
	WHERE	z.winlostdate = @yesterday
		AND z.SiteDBGroupID > 0
	GROUP BY	z.SiteDBGroupID, 
				c.Recommend, 
				z.Status
	
	SELECT TableName, SiteDBGroupID, Recommend, Status, TicketCount
	FROM #tmp_betticketcheckcount
	--ORDER BY TableName, SiteDBGroupID, Recommend,  Status

	DROP TABLE #tmp_betticketcheckcount
END

