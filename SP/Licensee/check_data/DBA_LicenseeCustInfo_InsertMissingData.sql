USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[DBA_LicenseeCustInfo_InsertMissingData]    Script Date: 05/04/2016 03:45:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[DBA_LicenseeCustInfo_InsertMissingData]
AS
BEGIN 
	SET NOCOUNT ON
	 DECLARE @RowCount INT = 0
	   
	--Step 1: Fix data fo LicenseeCustInfo
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
	     
	 IF @RowCount > 0  
	  INSERT INTO bodb_Licensee.dbo.LicenseeCustinfo(Custid,recommend,username,username2,currency,SpecialLevel)  
	   SELECT  
		c.CustId  
		,c.Recommend  
		,c.Username  
		,c.Username2  
		,c.Currency  
		,0 SpecialLevel  
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
		AND ag.Username NOT LIKE '%cas' + e.currency + '%'  
		AND ag.Username NOT LIKE '%Bank' + e.currency + '%'  
	 
	 SET @RowCount = @@ROWCOUNT   
	   
	 PRINT CAST(@RowCount AS vARCHAR (500)) + ' customer(s) inserted to LicenseeCustInfo' 
	    
	 DROP TABLE #member  
	       
	 --Step 2: Fix for LicenseeCust  
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
	     
	 IF @RowCount > 0  
	  INSERT INTO bodb_Licensee.dbo.LicenseeCust([LicenseeID],[CustID],[RoleID],[Currency],[CurrencyName],[Description])  
	   SELECT l.LicenseeId,   
		ag.CustId [DummyAgentId],  
		2 [RoleID],  
		ag.Currency [Currency],   
		CASE ag.Currency WHEN 20 THEN 'UUS' ELSE e.Code END [CurrencyName],  
		'' [Description]  
	   FROM #Dummy d WITH(NOLOCK)  
		INNER JOIN dbo.Customer ag WITH(NOLOCK) ON d.DummyAgentId = ag.CustId  
		INNER JOIN dbo.Exchange e WITH(NOLOCK) ON ag.Currency = e.ExchangeId  
		INNER JOIN bodb_licensee.dbo.Licensees l WITH(NOLOCK) ON ag.Site = l.LicenseeName  
	   WHERE ag.Currency <> 20  
		AND ag.Username NOT LIKE '%Aff%' 
		AND ag.Username NOT LIKE '%ACC' + e.currency + '%'  
		AND ag.Username NOT LIKE '%ACC' + e.code + '%' 
		AND ag.Username NOT LIKE '%cas' + e.currency + '%'  
		AND ag.Username NOT LIKE '%Bank' + e.currency + '%'  
	 
	 SET @RowCount = @@ROWCOUNT  
	 
	 PRINT CAST(@RowCount AS vARCHAR (500)) + ' customer(s) inserted to LicenseeCust' 
	  
	 DROP TABLE #Dummy
 END
 
 GRANT VIEW DEFINITION ON DBA_LicenseeCustInfo_InsertMissingData TO vnteam


GO
GRANT VIEW DEFINITION ON [dbo].[DBA_LicenseeCustInfo_InsertMissingData] TO [vnteam] AS [dbo]