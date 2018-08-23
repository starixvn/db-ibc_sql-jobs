/*<info serverAlias="DBEXT-bodb02" executers="" viewers="vnteam" isFunction="0"></info>*/
USE [bodb02]
GO
 
ALTER PROCEDURE [dbo].[DBA_LicenseeCustInfo_InsertMissingData]
AS

/*    
	Created:     
	Task : 
	DB:   DBEXT-bodb02
	Original:    
	    
	Revisions:    
	 - 20180809@Sophia: HA - remove LicenseeCustInfo table [Redmine: #99464]
	 
*/

BEGIN 
	SET NOCOUNT ON
	 DECLARE @RowCount INT = 0	   
	
	       
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
 
GO 