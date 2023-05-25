/*<info serverAlias="DBBAH-bodb02" executers="" isFunction="0"></info>*/
/*
    Created: 20230522@Louisa
	Task: Detail Transaction - Re-init balance for the rest of licensees [Redmine: #188569]
	DB:DBBAH/bodb02

*/
USE bodb02
GO

--- proccess data for SiteDBGroupID = 2

-------Input section: Required input @Order --------

	/*	select tmp.SiteDBGroupID , tmp.OrderNo, count(tmp.Site) as cnt_Site
		from BalanceRecord_SiteName_tmp tmp with(nolock)
		group by tmp.SiteDBGroupID , tmp.OrderNo
		order by tmp.SiteDBGroupID , tmp.OrderNo
	*/

	DECLARE @Order TINYINT


---------------Preapare data-------------------------------
	IF @Order IS NULL
	RETURN

	IF @Order = 1
	BEGIN
		INSERT INTO BalanceRecordDiff_SiteDB2_Order1 (custid)
		SELECT b.custid						
		FROM [bodb02].[dbo].BalanceRecord b WITH(NOLOCK)									
			INNER JOIN  [bodb02].[dbo].Customer c WITH(NOLOCK) ON c.custid = b.custid								
			INNER JOIN  [bodb02].[dbo].site s WITH(NOLOCK) ON c.site = s.site								
			INNER JOIN [bodb02].[dbo].Dep_CustSuper cs WITH(NOLOCK) ON cs.custid = c.srecommend	
			INNER JOIN [bodb02].[dbo].BalanceRecord_SiteName_tmp t WITH(NOLOCK) ON t.Site = s.site AND s.sitedbgroupid = t.SiteDBGroupID
		WHERE															
			c.creatdate <= '2022-10-13 01:00:00.000'				
			AND s.sitedbgroupid = 2
			AND t.OrderNo = @Order
	END

	IF @Order = 5
	BEGIN
		INSERT INTO BalanceRecordDiff_SiteDB2_Order5 (custid)
		SELECT b.custid						
		FROM [bodb02].[dbo].BalanceRecord b WITH(NOLOCK)									
			INNER JOIN  [bodb02].[dbo].Customer c WITH(NOLOCK) ON c.custid = b.custid								
			INNER JOIN  [bodb02].[dbo].site s WITH(NOLOCK) ON c.site = s.site								
			INNER JOIN [bodb02].[dbo].Dep_CustSuper cs WITH(NOLOCK) ON cs.custid = c.srecommend	
			INNER JOIN [bodb02].[dbo].BalanceRecord_SiteName_tmp t WITH(NOLOCK) ON t.Site = s.site AND s.sitedbgroupid = t.SiteDBGroupID
		WHERE															
			c.creatdate <= '2022-10-13 01:00:00.000'				
			AND s.sitedbgroupid = 2
			AND t.OrderNo = @Order
	END

	IF @Order = 6
	BEGIN
		INSERT INTO BalanceRecordDiff_SiteDB2_Order6 (custid)
		SELECT b.custid						
		FROM [bodb02].[dbo].BalanceRecord b WITH(NOLOCK)									
			INNER JOIN  [bodb02].[dbo].Customer c WITH(NOLOCK) ON c.custid = b.custid								
			INNER JOIN  [bodb02].[dbo].site s WITH(NOLOCK) ON c.site = s.site								
			INNER JOIN [bodb02].[dbo].Dep_CustSuper cs WITH(NOLOCK) ON cs.custid = c.srecommend	
			INNER JOIN [bodb02].[dbo].BalanceRecord_SiteName_tmp t WITH(NOLOCK) ON t.Site = s.site AND s.sitedbgroupid = t.SiteDBGroupID
		WHERE															
			c.creatdate <= '2022-10-13 01:00:00.000'				
			AND s.sitedbgroupid = 2
			AND t.OrderNo = @Order
	END

	----check data
	select count(1) as cnt_CustId from BalanceRecordDiff_SiteDB2_Order1
	select count(1) as cnt_CustId from BalanceRecordDiff_SiteDB2_Order5
	select count(1) as cnt_CustId from BalanceRecordDiff_SiteDB2_Order6
