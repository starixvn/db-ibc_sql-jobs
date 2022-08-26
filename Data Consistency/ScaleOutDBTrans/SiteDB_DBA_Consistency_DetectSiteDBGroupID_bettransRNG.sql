/*<info serverAlias="DBSIG-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SiteDB_DBA_Consistency_DetectSiteDBGroupID_bettransRNG]
(	
	@batchCount INT = 0
	, @SiteDBGroupID SMALLINT = 0
	, @maxTransId BIGINT = NULL OUTPUT
)
AS 
/*
Created by: 20220824@Victoria
Task: Detect SiteDBGroupID - bettransRNG
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
		, IsInvalid SMALLINT DEFAULT(0)
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
	WHERE c.ConfigName = 'bettransRNG'

	INSERT INTO #tmp_TransId (TransId, CustId, SiteDBGroupID)
	SELECT TOP(@batchCount) b.transid, b.custid, b.SiteDBGroupID
	FROM dbo.bettransRnG b WITH (NOLOCK)
	WHERE b.transid > @maxTransId_setting
	ORDER BY  b.transid ASC

	SET @maxTransId = (SELECT MAX(TransId) FROM #tmp_TransId)
	---------------------------------------

	INSERT INTO #tmp_Cust (CustId, site, SiteDBGroupID)
	SELECT DISTINCT c.custid, c.site, s.SiteDBGroupID
	FROM CustDB.dbo.Customer c WITH (NOLOCK)
		INNER JOIN #tmp_TransId tmp ON tmp.CustId = c.custid
		INNER JOIN CustDB.dbo.Site s WITH (NOLOCK) ON s.site = c.site
	---------------------------------------
	UPDATE	ttrans
	SET		ttrans.IsInvalid = 1
			, ttrans.SiteDBGroupIDConfigured = @SiteDBGroupID
	FROM	#tmp_TransId ttrans
	WHERE	ttrans.SiteDBGroupID <> @SiteDBGroupID

	DELETE tcust
	FROM #tmp_Cust tcust
		INNER JOIN #tmp_TransId ttrans ON ttrans.CustId = tcust.CustId
	WHERE ttrans.IsInvalid = 1

	UPDATE	ttrans
	SET		ttrans.IsInvalid = 2
			, ttrans.SiteDBGroupIDConfigured = tcust.SiteDBGroupID
	FROM	#tmp_TransId ttrans
		INNER JOIN #tmp_Cust tcust ON ttrans.CustId = tcust.CustId
	WHERE	ttrans.SiteDBGroupID <> tcust.SiteDBGroupID
	---------------------------------------

	INSERT INTO #CustSiteDBGroupID_Invalid (TableName, TransID, CustID, SiteDBGroupID, SiteDBGroupIDConfigured, IsInvalid)
	SELECT 'bettransRNG' AS TableName, ttrans.TransId, ttrans.CustId, ttrans.SiteDBGroupID, ttrans.SiteDBGroupIDConfigured, ttrans.IsInvalid
	FROM #tmp_TransId ttrans
	WHERE ttrans.IsInvalid > 0

	DROP TABLE #tmp_TransId
	DROP TABLE #tmp_Cust
END