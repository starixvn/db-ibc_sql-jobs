/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_CheckTicketCount]
AS 
/*
Created by: 20220819@Victoria
Task: Check ticket count by Status - DBCONSISTENCY
DB: DBCONSISTENCY-bodb_Consistency
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
	FROM	bodb02.dbo.bettrans WITH (NOLOCK)
	WHERE	winlostdate = @yesterday
		AND SiteDBGroupID > 0
	GROUP BY	SiteDBGroupID, 
				Recommend, 
				Status
	UNION
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
	UNION
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
	UNION
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
	UNION
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
	UNION
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
	ORDER BY TableName,SiteDBGroupID,Recommend,Status
END

