/*<info serverAlias="DBEXT-bodb02" executers="" viewers="vnteam" isFunction="0"></info>*/
USE [bodb02]
GO
ALTER PROCEDURE [dbo].[Task_LicenseeCustInfo_DataCheck]
	@CheckType TINYINT = 0
/*
	Creator: 20160113@Francis
	Task: Check missing data for bodb_Licensee.dbo.LicenseeCustInfo and bodb_Licensee.dbo.LicenseeCust
	DB: DBEXT/bodb02
	Revisions: 
	- 20170208@Fracis: Add @CheckType param to separate LicenseeCustInfo and LicenseeCust 
	- 20180809@Sophia: HA - remove LicenseeCustInfo table [Redmine: #99464]
	Param's Explanation:
*/
AS 
BEGIN
	DECLARE @RowCount INT = 0
	

	IF @CheckType = 1
	BEGIN
	-- Step 2: Checking for LicenseeCust
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

END
GO