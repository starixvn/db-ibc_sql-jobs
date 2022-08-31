/*<info serverAlias="DBSIG-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[SiteDB_DBA_Consistency_CheckTicketCount]
AS 
/*
Created by: 20220819@Victoria
Task: Check ticket count by Status - SiteDB
DB: DBSIG-bodb02
Revisions:
	- 20220819@Victoria: Check ticket count by Status - DBCONSISTENCY [Redmine:#175881]
	
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @yesterday SMALLDATETIME
	SELECT  @yesterday = CONVERT(DATE, DATEADD(DAY, -1, GETDATE()))
	
	SELECT	'bettrans' AS TableName,
			SiteDBGroupID, 
			Recommend, 
			Status, 
			COUNT(1) AS TicketCount
	FROM	dbo.bettrans WITH (NOLOCK)
	WHERE	winlostdate = @yesterday
		AND SiteDBGroupID > 0
	GROUP BY	SiteDBGroupID, 
				Recommend, 
				Status
	UNION ALL
	SELECT	'bettransRnG' AS TableName,
			SiteDBGroupID, 
			Recommend, 
			Status, 
			COUNT(1) AS TicketCount
	FROM	dbo.bettransRnG WITH (NOLOCK)
	WHERE	winlostdate = @yesterday
		AND SiteDBGroupID > 0
	GROUP BY	SiteDBGroupID, 
				Recommend, 
				Status
	UNION ALL
	SELECT	'bettransLC' AS TableName,
			SiteDBGroupID, 
			Recommend, 
			Status, 
			COUNT(1) AS TicketCount
	FROM	dbo.bettransLC WITH (NOLOCK)
	WHERE	winlostdate = @yesterday
		AND SiteDBGroupID > 0
	GROUP BY	SiteDBGroupID, 
				Recommend, 
				Status
	UNION ALL
	SELECT	'bettransG' AS TableName,
			b.SiteDBGroupID, 
			c.Recommend, 
			b.Status, 
			COUNT(1) AS TicketCount
	FROM	dbo.bettransG b WITH (NOLOCK)
		INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON c.custid = b.custid
	WHERE	winlostdate = @yesterday
		AND SiteDBGroupID > 0
	GROUP BY	b.SiteDBGroupID, 
				c.Recommend, 
				b.Status
	UNION ALL
	SELECT	'translog' AS TableName,
			SiteDBGroupID, 
			Recommend, 
			Status, 
			COUNT(1) AS TicketCount
	FROM	dbo.translog WITH (NOLOCK)
	WHERE	winlostdate = @yesterday
		AND SiteDBGroupID > 0
	GROUP BY	SiteDBGroupID, 
				Recommend, 
				Status
	UNION ALL
	SELECT	'bettransm' AS TableName,
			bm.SiteDBGroupID, 				
			c.Recommend, 
			bm.Status, 
			COUNT(1) AS TicketCount
	FROM	dbo.bettransm bm WITH (NOLOCK) 
		INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON c.custid = bm.custid
	WHERE	bm.winlostdate = @yesterday
		AND bm.SiteDBGroupID > 0
	GROUP BY	bm.SiteDBGroupID, 
				c.Recommend, 
				bm.Status
	UNION ALL
	SELECT	'zzzbettrans' AS TableName,
			z.SiteDBGroupID, 
			c.Recommend, 
			z.Status, 
			COUNT(1) AS TicketCount
	FROM	dbo.zzzbettrans z WITH (NOLOCK)
		INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON c.custid = z.custid
	WHERE	z.winlostdate = @yesterday
		AND z.SiteDBGroupID > 0
	GROUP BY	z.SiteDBGroupID, 
				c.Recommend, 
				z.Status
	UNION ALL
	SELECT	'zzzbettransm' AS TableName,
			z.SiteDBGroupID,  
			c.Recommend, 
			z.Status, 
			COUNT(1) AS TicketCount
	FROM	dbo.zzzbettransm z WITH (NOLOCK)
		INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON c.custid = z.custid
	WHERE	z.winlostdate = @yesterday
		AND z.SiteDBGroupID > 0
	GROUP BY	z.SiteDBGroupID, 
				c.Recommend, 
				z.Status
	ORDER BY TableName, SiteDBGroupID, Recommend,  Status
END

