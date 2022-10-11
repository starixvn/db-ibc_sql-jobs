/*<info serverAlias="DBSIG-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SiteDB_DBA_Consistency_DetectSiteDBGroupID_Transfer]
(	
	@batchCount INT = 0
	, @SiteDBGroupID SMALLINT = 0
	, @maxTransId BIGINT = NULL OUTPUT
)
AS 
/*
Created by: 20220824@Victoria
Task: Detect SiteDBGroupID - Transfer
DB: DBSIG-bodb02
Revisions:
	- 20220824@Victoria: Rule #53 - Detect SiteGroupDBID on tickets contain value different from site of customer [Redmine:#175881]
	
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

	DECLARE @maxTransId_setting BIGINT,
			@fromtransid BIGINT
	
	SELECT @maxTransId_setting = CONVERT(BIGINT, c.ConfigValue)
	FROM dbo.SiteDB_DataConsistencyCheck_Config c WITH (NOLOCK)
	WHERE c.ConfigName = 'Transfer'

	INSERT INTO #tmp_TransId (TransId, CustId, SiteDBGroupID)
	SELECT TOP(@batchCount) b.TransId, b.CustId, s.SiteDBGroupID
	FROM dbo.Transfer b WITH (NOLOCK)
		INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON c.custid = b.CustId
		INNER JOIN CustDB.dbo.Site s WITH (NOLOCK) ON s.site = c.site
	WHERE b.TransId > @maxTransId_setting
		AND b.CustId <> 3
		AND b.Bettype NOT IN (19999, 20000)
	ORDER BY  b.TransId ASC

	SET @fromtransid = (SELECT MIN(TransId) FROM #tmp_TransId)
	SET @maxTransId = (SELECT MAX(TransId) FROM #tmp_TransId)
	---------------------------------------
	-- Invalid in case of checking mismatch sitedbgroupid between server config & table site 
	UPDATE	ttrans
	SET		ttrans.IsInvalid = 1
			,ttrans.SiteDBGroupIDConfigured = @SiteDBGroupID
	FROM	#tmp_TransId ttrans
	WHERE	ttrans.SiteDBGroupID <> @SiteDBGroupID

	---------------------------------------
	INSERT INTO #CustSiteDBGroupID_Invalid (TableName, TransID, CustID, SiteDBGroupID, SiteDBGroupIDConfigured, FromTransID, ToTransID)
	SELECT 'Transfer' AS TableName, ttrans.TransId, ttrans.CustId, ttrans.SiteDBGroupID, ttrans.SiteDBGroupIDConfigured, @fromtransid, @maxTransId
	FROM #tmp_TransId ttrans
	WHERE ttrans.IsInvalid = 1

	DROP TABLE #tmp_TransId
END