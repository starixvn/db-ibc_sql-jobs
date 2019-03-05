/*<info serverAlias="DBEXT-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Task_DailySummary_Verify]
	@winlostdate datetime,
	@TestMode tinyint = 1
AS

/*
	Created by:Thien
	Date: 20111018
	Task: to verify the move bet process at tomorrow's mornings
	DB: DBEXT.bodb02

	Revisions:
		- 20160119@Daniel: check table bettransRNG & bettransLC
		- 20170719@Patrick: check valid ip for bettrans, bettransrng, bettranslc, translog
		- 20170712@Harper: Implement new Product Betradar VS [Redmine: #78241]
		- 20171010@Percy: Apply Bullfighting [RedmineID: #84690]
		- 20180918@Patrick: Add more rule check if a custid belong to more than an upline [RedmineID: #101549]
		- 20190305@Patrick: Remove statement check rowcount for check running/waiting ticket at translog statement [RedmineID: #109805]
*/

SET NOCOUNT ON

DECLARE @transid bigint
-- ====================
-- DATA VERIFICATION
-- ====================
-- ==================== Check running/waiting ticket at translog =================
IF EXISTS (
	SELECT 1 FROM translog with (nolock)
	WHERE	statusID IN (0, 1)
			AND custid <> 0
			AND winlostdate <= @winlostdate
			AND currency <> 20
)
BEGIN
	RAISERROR ('FAILED: Have translog running/wating tickets', 16, 1)
	RETURN
END


-- ==================== Check running ticket/ not summed at bettransRNG & bettransLC =================
IF EXISTS (
	SELECT 1 FROM bettransRNG with (nolock)
	WHERE	(statusID = 0 OR isSum = 0)
			AND custid <> 0
			AND winlostdate <= @winlostdate
			AND currency <> 20
)
BEGIN
	RAISERROR ('FAILED: bettransRNG have running tickets or not summed to bettrans yet', 16, 1)
	RETURN
END

IF EXISTS (
	SELECT 1 FROM bettransLC with (nolock)
	WHERE	(statusID = 0 OR isSum = 0)
			AND custid <> 0
			AND winlostdate <= @winlostdate
			AND currency <> 20
)
BEGIN
	RAISERROR ('FAILED: bettransLC have running tickets or not summed to bettrans yet', 16, 1)
	RETURN
END


-- ==================== Check running ticket at bettrans =================
IF EXISTS (
	SELECT transid FROM bettrans with (nolock)
	WHERE	--[status] = 'running' 
			statusID = 0
			AND custid <> 0
			AND bettype <=19000 AND bettype <> 10 AND winlostdate <= @winlostdate
			AND currency <> 20
)
BEGIN
	SELECT DISTINCT matchid FROM bettrans (nolock)
	WHERE	winlostdate <= @winlostdate 
			--AND [status] = 'running'
			AND statusID = 0 
			AND bettype <=19000 and bettype NOT IN (9, 10, 29, 2799)

	SELECT DISTINCT 'EXEC matchname ' + CAST(bm.matchid as varchar(10)) matchid, m.eventdate, bm.matchid, ',' [Comma]
	FROM dbo.bettrans b (nolock)
		INNER JOIN dbo.bettransm bm (nolock) ON b.refno = bm.refno
		INNER JOIN dbo.match m (nolock) ON bm.matchid = m.matchid
	WHERE	b.winlostdate <= @winlostdate 
			--AND b.[status] = 'running' AND bm.[status] = 'running'
			AND b.statusID = 0 AND bm.statusID = 0 
			AND b.bettype in (9,29,2799)
			--AND b.matchid = 0
			AND b.matchID in (9,29,2799)
			AND b.currency <> 20
	ORDER BY m.eventdate

	IF @@ROWCOUNT > 0
	BEGIN
		PRINT '--'
		PRINT '--SELECT * FROM bettrans (nolock) WHERE status = ''running'' AND matchid IN (9,29,2799) AND bettype IN (9,29,2799) AND winlostdate <= ''' + CONVERT(varchar(10), @winlostdate, 120) + ''''
		PRINT '--UPDATE dbo.bettrans SET winlostdate = ''' + CONVERT(varchar(10), DATEADD(day,1,@winlostdate), 120) + ''' WHERE transid IN ( xxxxx )'
		PRINT '--'
	END

	RAISERROR ('FAILED: Have running tickets', 16, 1)
	RETURN
END
-- ====================
IF EXISTS (
	SELECT transid FROM bettrans with (nolock)
	WHERE srecommend <= 100 AND (scomm <> acomm OR swinlost <> 0)
	AND bettype <=19000 AND winlostdate = @winlostdate
)
BEGIN
	RAISERROR ('FAILED: Incorrect Company SuperAgent setting', 16, 1)
	RETURN
END
-- ====================
IF EXISTS (
	SELECT transid FROM bettrans with (nolock)
	WHERE (scomm IS NULL OR acomm IS NULL OR comm IS NULL OR playercomm IS NULL
	OR swinlost IS NULL OR mwinlost IS NULL OR awinlost IS NULL OR winlost IS NULL)
	AND bettype <=19000 AND winlostdate = @winlostdate
)
BEGIN
	RAISERROR ('FAILED: Null Commission/WinLost', 16, 1)
	RETURN
END
-- ====================
IF EXISTS (
	SELECT currency
	FROM bettrans (nolock)
	WHERE bettype <=19000 AND winlostdate = @winlostdate
	GROUP BY currency
	HAVING COUNT(DISTINCT actualrate) > 1
)
BEGIN
	RAISERROR ('FAILED: Multiple Exchange Rate', 16, 1)
	RETURN
END
-- ====================

IF EXISTS (
	SELECT  b.transid,  b.winlostdate, b.statusID, b.status, m.matchid, m.eventdate, m.eventstatus
	FROM bettransm b WITH(NOLOCK)
		inner join match m WITH(NOLOCK) ON b.matchid = m.matchid 
	WHERE winlostdate = @winlostdate 
		and b.winlostdate <> m.eventdate
	)
BEGIN
	RAISERROR ('FAILED: Multiple winlostdate for a match', 16, 1)
	RETURN
END

--//check invalid IP  
--//bettrans  
IF EXISTS (  
 SELECT TOP 1 1  
 FROM dbo.bettrans WITH(NOLOCK)  
 WHERE winlostdate = @winlostdate AND ISNUMERIC(REPLACE(ip, '.', '')) = 0 AND ip <> ''  
)  
BEGIN  
 RAISERROR ('FAILED: Invalid IP on bettrans', 16, 1)  
 RETURN  
END  
  
--//bettransrng  
IF EXISTS (  
 SELECT TOP 1 1  
 FROM dbo.bettransrng WITH(NOLOCK)  
 WHERE winlostdate = @winlostdate AND ISNUMERIC(REPLACE(ip, '.', '')) = 0 AND ip <> ''  
)  
BEGIN  
 RAISERROR ('FAILED: Invalid IP on bettransrng', 16, 1)  
 RETURN  
END  
  
--//bettranslc  
IF EXISTS (  
	SELECT TOP 1 1  
	FROM dbo.bettranslc WITH(NOLOCK)  
	WHERE winlostdate = @winlostdate AND ISNUMERIC(REPLACE(ip, '.', '')) = 0 AND ip <> ''  
)  
BEGIN  
	RAISERROR ('FAILED: Invalid IP on bettranslc', 16, 1)  
	RETURN  
END  
  
--//translog  
IF EXISTS (  
	SELECT TOP 1 1  
	FROM dbo.translog WITH(NOLOCK)  
	WHERE winlostdate = @winlostdate AND ISNUMERIC(REPLACE(ip, '.', '')) = 0 AND ip <> ''  
)  
BEGIN  
	RAISERROR ('FAILED: Invalid IP on translog', 16, 1)  
	RETURN  
END  

--//check a custid belong to more than a upline
IF EXISTS (
	SELECT TOP 10 custid, currency
	FROM (
		SELECT srecommend, mrecommend, recommend, custid, currency
		FROM dbo.bettrans WITH(NOLOCK) 
		WHERE custid > 0 --ignore case ticket with status completed
		GROUP BY srecommend, mrecommend, recommend, custid, currency
	)t
	GROUP BY custid, currency
	HAVING COUNT(1) > 1
)
BEGIN
	RAISERROR ('FAILED: One more than custid belong to multiple uplines', 16, 1)
	PRINT('sql statement: ^^^ 
		SELECT TOP 10 custid, currency
		FROM (
			SELECT srecommend, mrecommend, recommend, custid, currency
			FROM dbo.bettrans WITH(NOLOCK) 
			WHERE custid > 0 --ignore case ticket with status completed
			GROUP BY srecommend, mrecommend, recommend, custid, currency
		)t
		GROUP BY custid, currency
		HAVING COUNT(1) > 1 ^^^')

	RETURN
END

IF @TestMode = 1
BEGIN
	PRINT 'DATA OK'

	IF EXISTS (SELECT 1 FROM bettrans with (nolock)
		WHERE bettype = 10 
			--AND [status] = 'running'
			AND statusID = 0 
			AND winlostdate = @winlostdate)
		PRINT 'Some Outright need to moved : Run with parameter = 2'

	IF EXISTS (SELECT 1 FROM bettrans with (nolock)
		WHERE currency = 20
			AND winlostdate = @winlostdate
			AND bettype <=19000
			AND statusID = 0)
		PRINT 'Some TEST Ticket need to Refund : Run with parameter = 2'

	RETURN
END
GO
