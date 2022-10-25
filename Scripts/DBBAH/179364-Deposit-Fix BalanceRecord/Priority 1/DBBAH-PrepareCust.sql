/*<info serverAlias="DBBAH-bodb02" executers="" isFunction="0"></info>*/
/*
    Created: 20221019@Max
	Task: Deposit - Fix BalanceRecord - related Arcadia issue on Aug 2022 [Redmine: #179364]
	DB:DBBAH/bodb02

*/
USE BODB02
GO
CREATE TABLE BalanceRecord_SiteDB2_Round1_tmp (ID INT IDENTITY (1,1) PRIMARY KEY, custid INT)

GO

---------------Preapare data-------------------------------
DECLARE @tmp_preCust AS TABLE (Site NVARCHAR(100), TotalCust INT, SiteDBGroupID SMALLINT, [Priority] TINYINT)

INSERT INTO @tmp_preCust (Site, TotalCust, Priority, SiteDBGroupID)
VALUES ('OneSports',306467,1,2)
,('Macaubet',98985,1,2)
,('X2Dynamic',13807,1,2)
,('9Club',7807,1,2)
,('golden88',32,1,2)

INSERT INTO BalanceRecord_SiteDB2_Round1_tmp (custid)
SELECT b.custid						
FROM [bodb02].[dbo].BalanceRecord b WITH(NOLOCK)									
	INNER JOIN  [bodb02].[dbo].Customer c WITH(NOLOCK) ON c.custid = b.custid								
	INNER JOIN  [bodb02].[dbo].site s WITH(NOLOCK) ON c.site = s.site								
	INNER JOIN [bodb02].[dbo].Dep_CustSuper cs WITH(NOLOCK) ON cs.custid = c.srecommend	
	INNER JOIN @tmp_preCust t ON t.Site = s.site
	LEFT JOIN BalanceRecord_SiteDB2_tmp tmp WITH (NOLOCK) ON tmp.CustId = b.CustId 
WHERE															
	c.creatdate <= '2022-10-13 01:00:00.000'					
	AND s.sitedbgroupid = 2
	AND t.Priority = 1 	
	AND tmp.CustId IS NULL
