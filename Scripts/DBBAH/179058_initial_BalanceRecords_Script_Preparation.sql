/*<info serverAlias="DBBAH-bodb02" executers="" isFunction="0"></info>*/
/*
    Created: 20221013@Helen
	Task: init data for sitedb1,2 due to trigger insert on bettransRnG not captured data[Redmine:#179058]
	DB:DBBAH/bodb02

*/
USE BODB02
GO
CREATE TABLE BalanceRecord_SiteDB1_tmp (custid INT)
CREATE TABLE BalanceRecord_SiteDB2_tmp (custid INT)

GO

CREATE TABLE #temp (custid INT, sitedbgroupid SMALLINT)
INSERT INTO #temp (custid, sitedbgroupid)
SELECT DISTINCT bk.custid,s.sitedbgroupid
FROM balancerecord.dbo.BalanceRecord_bk bk with(nolock)
INNER JOIN bodb02.dbo.vw_customer ci with(nolock) on ci.custid = bk.custid
INNER JOIN bodb02.dbo.site s with (nolock) on s.site = ci.site
WHERE ActionDate >= '2022-09-20 02:16:17.030'
	AND s.SiteDBGroupID = 1 -- IN (1,2) 
	AND action like 'RNG (IsSUM :%' 
	AND rowid >= 60813434030
	--60813434030

INSERT INTO BalanceRecord_SiteDB1_tmp (custid)
SELECT custid
FROM #temp
WHERE sitedbgroupid = 1

INSERT INTO BalanceRecord_SiteDB2_tmp (custid)
SELECT custid
FROM #temp
WHERE sitedbgroupid = 2