/*<info serverAlias="DBBAH-bodb02" executers="" isFunction="0"></info>*/
/*
    Created: 20230629@Louisa
	Task: Correct balance again - after correct on July 2023 [Redmine: #188569]
	DB:DBBAH/bodb02

*/
USE bodb02
GO

	----init data again for W88
 
	INSERT INTO BalanceRecordDiff_SiteDB2_Order1 (custid)
	SELECT DISTINCT b.custid						
	FROM [bodb02].[dbo].BalanceRecord b WITH(NOLOCK)									
		INNER JOIN  [bodb02].[dbo].Customer c WITH(NOLOCK) ON c.custid = b.custid								
		INNER JOIN  [bodb02].[dbo].site s WITH(NOLOCK) ON c.site = s.site								
		INNER JOIN [bodb02].[dbo].Dep_CustSuper cs WITH(NOLOCK) ON cs.custid = c.srecommend	
		INNER JOIN [bodb02].[dbo].BalanceRecord_SiteName_tmp t WITH(NOLOCK) ON t.Site = s.site AND s.sitedbgroupid = t.SiteDBGroupID
	WHERE															
		c.creatdate <= '2022-10-13 01:00:00.000'				
		AND s.sitedbgroupid = 2
		AND t.OrderNo = 1
		AND s.site = 'W88'
  

