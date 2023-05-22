/*<info serverAlias="DBBAH-bodb02" executers="" isFunction="0"></info>*/
/*
    Created: 20230522@Louisa
	Task: Detail Transaction - Re-init balance for the rest of licensees [Redmine: #188569]
	DB:DBBAH/bodb02

*/
USE bodb02
GO

--- proccess data for SiteDBGroupID = 1

IF EXISTS ( select top 1 1 from sys.objects where name = 'BalanceRecord_diff_SiteDB1_tmp' )
BEGIN
	CREATE TABLE BalanceRecord_diff_SiteDB1_tmp (ID INT IDENTITY (1,1) PRIMARY KEY, custid INT)
END

---------------Preapare data-------------------------------
DECLARE @tmp_preCust AS TABLE (Site NVARCHAR(100), TotalCust INT, [Priority] TINYINT, SiteDBGroupID SMALLINT)

INSERT INTO @tmp_preCust (Site, TotalCust, Priority, SiteDBGroupID)
VALUES	 ('OneSports'	,306467	,1	,1)
		,('Macaubet'	,98985	,1	,1)
		,('X2Dynamic'	,13807	,1	,1)
		,('9Club'		,7807	,1	,1)
		,('golden88'	,32		,1	,1)

INSERT INTO BalanceRecord_diff_SiteDB1_tmp (custid)
SELECT b.custid						
FROM [bodb02].[dbo].BalanceRecord b WITH(NOLOCK)									
	INNER JOIN  [bodb02].[dbo].Customer c WITH(NOLOCK) ON c.custid = b.custid								
	INNER JOIN  [bodb02].[dbo].site s WITH(NOLOCK) ON c.site = s.site								
	INNER JOIN [bodb02].[dbo].Dep_CustSuper cs WITH(NOLOCK) ON cs.custid = c.srecommend	
	INNER JOIN @tmp_preCust t ON t.Site = s.site
	LEFT JOIN BalanceRecord_diff_SiteDB1_tmp tmp WITH (NOLOCK) ON tmp.CustId = b.CustId 
WHERE															
	c.creatdate > '2022-10-13 01:00:00.000'					
	AND s.sitedbgroupid = 1
	AND t.Priority = 1 	
	AND tmp.CustId IS NULL
