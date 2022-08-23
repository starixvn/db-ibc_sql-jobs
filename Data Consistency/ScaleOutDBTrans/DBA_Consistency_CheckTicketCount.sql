/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_CheckTicketCount]
	@tablename		VARCHAR(50)		= NULL
AS 
/*
Created by: 20220819@Victoria
Task: Check ticket count by status - DBCONSISTENCY
DB: DBCONSISTENCY-bodb_Consistency
Revisions:
	- 20220819@Victoria: Check ticket count by status - DBCONSISTENCY [Redmine:#175881]
	
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @yesterday SMALLDATETIME
	SELECT  @yesterday = CONVERT(DATE, DATEADD(DAY, -1, GETDATE()))

	IF @tablename = 'bettrans'
	BEGIN
		SELECT	SiteDBGroupID, 
				recommend, 
				status, 
				COUNT(1) AS TicketCount
		FROM	dbo.bettrans WITH (NOLOCK)
		WHERE	winlostdate = @yesterday
			AND SiteDBGroupID > 0
		GROUP BY	SiteDBGroupID, 
					recommend, 
					status
	END
	ELSE IF @tablename = 'bettransRnG'
	BEGIN
		SELECT	SiteDBGroupID, 
				recommend, 
				status, 
				COUNT(1) AS TicketCount
		FROM	dbo.bettransRnG WITH (NOLOCK)
		WHERE	winlostdate = @yesterday
			AND SiteDBGroupID > 0
		GROUP BY	SiteDBGroupID, 
					recommend, 
					status
	END
	ELSE IF @tablename = 'bettransLC'
	BEGIN
		SELECT	SiteDBGroupID, 
				recommend, 
				status, 
				COUNT(1) AS TicketCount
		FROM	dbo.bettransLC WITH (NOLOCK)
		WHERE	winlostdate = @yesterday
			AND SiteDBGroupID > 0
		GROUP BY	SiteDBGroupID, 
					recommend, 
					status
	END
	ELSE IF @tablename = 'bettransm'
	BEGIN
		SELECT	bm.SiteDBGroupID, 
				c.recommend, 
				bm.status, 
				COUNT(1) AS TicketCount
		FROM	dbo.bettransm bm WITH (NOLOCK) 
			INNER JOIN dbo.Customer c WITH (NOLOCK) ON c.custid = bm.custid
		WHERE	bm.winlostdate = @yesterday
			AND bm.SiteDBGroupID > 0
		GROUP BY	bm.SiteDBGroupID, 
					c.recommend, 
					bm.status
	END
	ELSE IF @tablename = 'zzzbettrans'
	BEGIN
		SELECT	z.SiteDBGroupID, 
				c.recommend, 
				z.status, 
				COUNT(1) AS TicketCount
		FROM	dbo.zzzbettrans z WITH (NOLOCK)
			INNER JOIN dbo.Customer c WITH (NOLOCK) ON c.custid = z.custid
		WHERE	z.winlostdate = @yesterday
			AND z.SiteDBGroupID > 0
		GROUP BY	z.SiteDBGroupID, 
					c.recommend, 
					z.status
	END
	ELSE IF @tablename = 'zzzbettransm'
	BEGIN
		SELECT	z.SiteDBGroupID, 
				c.recommend, 
				z.status, 
				COUNT(1) AS TicketCount
		FROM	dbo.zzzbettransm z WITH (NOLOCK)
			INNER JOIN dbo.Customer c WITH (NOLOCK) ON c.custid = z.custid
		WHERE	z.winlostdate = @yesterday
			AND z.SiteDBGroupID > 0
		GROUP BY	z.SiteDBGroupID, 
					c.recommend, 
					z.status
	END
END

