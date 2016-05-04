USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Task_LicenseeCustInfo_DataCheck]    Script Date: 05/04/2016 03:45:21 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_LicenseeCustInfo_DataCheck]
/*
	Creator: 20160113@Francis
	Task: Check missing data for bodb_Licensee.dbo.LicenseeCustInfo and bodb_Licensee.dbo.LicenseeCust
	DB: DBEXT/bodb02
	Revisions: 
	Param's Explanation:
*/
AS 
BEGIN
	DECLARE @RowCount int

	SELECT ds.Username,c.CustId
	INTO #member
	FROM dbo.Dep_CustSuper ds WITH(NOLOCK)
		INNER JOIN dbo.Customer c WITH(NOLOCK) ON ds.CustId = c.SRecommend AND c.RoleId = 1
		LEFT JOIN bodb_licensee.dbo.LicenseeCustInfo lci WITH(NOLOCK) ON c.CustId = lci.CustId
	WHERE lci.Custid IS NULL

	SELECT 
		l.LicenseeID
		,ag.Site
		,e.Currency
		,t.Username [DummySuper]
		,ag.Username [DummyAgent]
		,c.Username [Member]
		,c.CustId
		,c.creatdate [CreatedDate]
	FROM #member t
		INNER JOIN dbo.Customer c WITH(NOLOCK) ON t.CustId = c.CustId
		INNER JOIN dbo.CustInfo ci WITH(NOLOCK) ON c.CustId = ci.CustId
		INNER JOIN dbo.Customer ag WITH(NOLOCK) ON c.Recommend = ag.CustId
		INNER JOIN dbo.Exchange e WITH(NOLOCK) ON c.Currency = e.exchangeid
		INNER JOIN bodb_Licensee.dbo.Licensees l WITH(NOLOCK) ON ag.Site = l.LicenseeName
	WHERE
		c.Currency <> 20
		AND c.Username NOT LIKE '%Transfer%'	
		AND ag.Username NOT LIKE '%ACC' + e.currency + '%' 
		AND ag.Username NOT LIKE '%ACC' + e.code + '%' 
		AND ag.Username NOT LIKE '%Cas' + e.currency + '%' 
		AND ag.Username NOT LIKE '%Bank' + e.currency + '%'
		--Hard code to remove KeenOcenan rule-broken usernames
		AND t.custid NOT IN (14373737, 14373735, 14373736, 18200278)

	SET @RowCount = @@ROWCOUNT
	DROP TABLE #member

	IF (@RowCount > 0)
		RAISERROR('Missing data for bodb_License: LicenseeCustInfo', 16, 1);
		

	-- Step 2: Checking for LicenseeCust
	SET @RowCount = 0

	SELECT ds.CustId DummySuperId, ag.CustId DummyAgentId
	INTO #Dummy
	FROM dbo.Dep_CustSuper ds WITH(NOLOCK)
		INNER JOIN dbo.Customer ag WITH(NOLOCK) ON ds.CustId = ag.SRecommend AND ag.RoleId = 2
		LEFT JOIN bodb_Licensee.dbo.LicenseeCust lc WITH(NOLOCK) ON ag.CustId = lc.CustId
	WHERE lc.CustId IS NULL

	SELECT l.LicenseeId, 
		ag.Site [Site], 
		e.Currency [Currency], 
		d.DummySuperId [DummySuperId],
		ag.CustId [DummyAgentId],
		ag.username [DummyAgent],
		ag.creatdate [DummyAgentCreatedDate]
	FROM #Dummy d WITH(NOLOCK)
		INNER JOIN dbo.Customer ag WITH(NOLOCK) ON d.DummyAgentId = ag.CustId
		INNER JOIN dbo.Exchange e WITH(NOLOCK) ON ag.Currency = e.ExchangeId
		INNER JOIN bodb_licensee.dbo.Licensees l WITH(NOLOCK) ON ag.Site = l.LicenseeName
	WHERE ag.Currency <> 20
		AND ag.Username NOT LIKE '%Aff%'
		AND ag.Username NOT LIKE '%ACC' + e.currency + '%' 
		AND ag.Username NOT LIKE '%ACC' + e.code + '%'
		AND ag.Username NOT LIKE '%Cas' + e.currency + '%' 
		AND ag.Username NOT LIKE '%Bank' + e.currency + '%' 
		--Hard code to remove KeenOcenan rule-broken usernames
		AND d.DummyAgentId NOT IN (14373733)
	SET @RowCount = @@ROWCOUNT
	DROP TABLE #Dummy

	IF (@RowCount > 0)
		RAISERROR('Missing data for bodb_License: LicenseeCust', 16, 1);

END

GRANT VIEW DEFINITION ON Task_LicenseeCustInfo_DataCheck TO vnteam



GO
GRANT VIEW DEFINITION ON [dbo].[Task_LicenseeCustInfo_DataCheck] TO [vnteam] AS [dbo]