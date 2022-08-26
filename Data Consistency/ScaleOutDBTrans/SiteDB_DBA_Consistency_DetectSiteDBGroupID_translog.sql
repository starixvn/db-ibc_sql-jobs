/*<info serverAlias="DBSIG-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SiteDB_DBA_Consistency_DetectSiteDBGroupID_translog]
(	
	@batchCount INT = 0
	, @SiteDBGroupID SMALLINT = 0
	, @maxTransId BIGINT = NULL OUTPUT
)
AS 
/*
Created by: 20220824@Victoria
Task: Detect SiteDBGroupID - translog
DB: DBSIG-bodb02
Revisions:
	- 20220824@Victoria: Detect tickets contain value different from SiteDBGroupID of the site setting configuration
							and SiteGroupDBID on tickets contain value different from site of customer [Redmine:#175881]
	
*/
BEGIN
	SET NOCOUNT ON
	
	IF OBJECT_ID('tempdb..#CustSiteDBGroupID_Invalid') IS NULL
	BEGIN
		RETURN
	END

	
	CREATE TABLE #tmp_TransId (
		TransId BIGINT PRIMARY KEY
		, CustId INT
		, IsInvalid BIT DEFAULT(0)
		, SiteDBGroupID SMALLINT
		, SiteDBGroupIDConfigured SMALLINT
	)

	CREATE TABLE #tmp_Cust (
		CustId INT PRIMARY KEY
		, site VARCHAR(10)
		, SiteDBGroupID SMALLINT
	)
	
	DECLARE @maxTransId_setting BIGINT
	
	SELECT @maxTransId_setting = CONVERT(BIGINT, c.ConfigValue)
	FROM dbo.SiteDB_MaxTrans_Config c WITH (NOLOCK)
	WHERE c.ConfigName = 'translog'

	INSERT INTO #tmp_TransId (TransId, CustId, SiteDBGroupID)
	SELECT TOP(@batchCount) b.translogid, b.custid, b.SiteDBGroupID
	FROM dbo.translog b WITH (NOLOCK)
	WHERE b.translogid > @maxTransId_setting
	ORDER BY  b.translogid ASC

	SET @maxTransId = (SELECT MAX(TransId) FROM #tmp_TransId)
	---------------------------------------

	INSERT INTO #tmp_Cust (CustId, site, SiteDBGroupID)
	SELECT DISTINCT c.custid, c.site, s.SiteDBGroupID
	FROM CustDB.dbo.Customer c WITH (NOLOCK)
		INNER JOIN #tmp_TransId tmp ON tmp.CustId = c.custid
		INNER JOIN CustDB.dbo.Site s WITH (NOLOCK) ON s.site = c.site
	---------------------------------------
	-- Invalid in case of checking mismatch sitedbgroupid between server config and ticket
	UPDATE  ttrans
	SET ttrans.IsInvalid = 1
	  , ttrans.SiteDBGroupIDConfigured = @SiteDBGroupID
	FROM  #tmp_TransId ttrans
	WHERE  ttrans.SiteDBGroupID <> @SiteDBGroupID

	-- Invalid in case of checking mismatch sitedbgroupid between ticket & table site 
	UPDATE  ttrans
	SET ttrans.IsInvalid = 1
	  , ttrans.SiteDBGroupIDConfigured = tcust.SiteDBGroupID
	FROM  #tmp_TransId ttrans
	INNER JOIN #tmp_Cust tcust ON ttrans.CustId = tcust.CustId
	WHERE  ttrans.SiteDBGroupID <> tcust.SiteDBGroupID
	AND ttrans.IsInvalid = 0

	---------------------------------------
	INSERT INTO #CustSiteDBGroupID_Invalid (TableName, TransID, CustID, SiteDBGroupID, SiteDBGroupIDConfigured)
	SELECT 'translog' AS TableName, ttrans.TransId, ttrans.CustId, ttrans.SiteDBGroupID, ttrans.SiteDBGroupIDConfigured
	FROM #tmp_TransId ttrans
	WHERE ttrans.IsInvalid = 1

	DROP TABLE #tmp_TransId
	DROP TABLE #tmp_Cust
END