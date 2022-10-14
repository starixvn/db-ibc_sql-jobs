/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_Consistency_CheckWrongSiteDBGroupID_bettrans]
(	
	@maxSequenceId BIGINT = NULL OUTPUT
)
AS 
/*
Created by: 20220930@Victoria
Task: Detect SiteDBGroupID - bettrans
DB: DBCONSISTENCY-bodb_Consistency
Revisions:
	- 20220930@Victoria: Rule #55 - Check if bet tickets are inserted into the correct SiteDBGroupID by reverting the transID in bettransXXX tables [Redmine:#178445]
	- 20221007@Victoria: Modify to add FromSequenceID and ToSequenceID in ResultSet 
							AND get top 5000 to limit the page split issue [Redmine: #178864]
Param's Expanation:
	
*/
BEGIN
	SET NOCOUNT ON

	IF OBJECT_ID('tempdb..#CustSiteDBGroupID_Invalid') IS NULL
	BEGIN
		RETURN
	END

	CREATE TABLE #tmp_TransId (
		TransId BIGINT PRIMARY KEY
		, Sequenceid BIGINT
		, CustId INT
		, IsInvalid BIT DEFAULT(0)
		, SourceSiteDBGroupID SMALLINT
		, CustomerSiteDBGroupID SMALLINT
	)

	CREATE TABLE #tmp_Cust (
		CustId INT PRIMARY KEY
		, site VARCHAR(10)
		, SiteDBGroupID SMALLINT
	)
	
	DECLARE @maxSequenceId_setting BIGINT,
			@fromSequenceId BIGINT,
			@currentTime DATETIME

	SET @currentTime = DATEADD(MINUTE, -2, GETDATE())

	SELECT @maxSequenceId_setting = CONVERT(BIGINT, c.VValue)
	FROM dbo.DBA_SystemSettings c WITH (NOLOCK)
	WHERE c.VName = 'DiffSGId_LastSeqId_bettrans'

	INSERT INTO #tmp_TransId (TransId, Sequenceid, CustId, SourceSiteDBGroupID)
	SELECT TOP 5000 b.transid, b.sequenceid, b.custid, r.SiteDBGroupID
	FROM bodb02.dbo.bettrans b WITH (NOLOCK)
	CROSS APPLY 
	(
		SELECT f.SiteDBGroupID
		FROM bodb02.dbo.f_dba_transid_revert(b.transid, 0) f 
	) r
	WHERE b.sequenceid > @maxSequenceId_setting
		AND b.transdate < @currentTime
	ORDER BY  b.sequenceid ASC

	SELECT @fromSequenceId =  MIN(Sequenceid), @maxSequenceId = MAX(Sequenceid) FROM #tmp_TransId
	---------------------------------------

	INSERT INTO #tmp_Cust (CustId, site, SiteDBGroupID)
	SELECT DISTINCT c.custid, c.site, s.SiteDBGroupID
	FROM bodb02.dbo.Customer c WITH (NOLOCK)
		INNER JOIN #tmp_TransId tmp ON tmp.CustId = c.custid
		INNER JOIN bodb02.dbo.Site s WITH (NOLOCK) ON s.site = c.site

	---------------------------------------
	-- Invalid in case of checking mismatch sitedbgroupid between ticket & table site 
	UPDATE  ttrans
	SET ttrans.IsInvalid = 1
	  , ttrans.CustomerSiteDBGroupID = tcust.SiteDBGroupID
	FROM  #tmp_TransId ttrans
		INNER JOIN #tmp_Cust tcust ON ttrans.CustId = tcust.CustId
	WHERE  ttrans.SourceSiteDBGroupID <> tcust.SiteDBGroupID
		AND ttrans.IsInvalid = 0

	---------------------------------------
	INSERT INTO #CustSiteDBGroupID_Invalid (TableName, TransID, CustID, SourceSiteDBGroupID, CustomerSiteDBGroupID, FromSequenceID, ToSequenceID)
	SELECT 'bettrans' AS TableName, ttrans.TransId, ttrans.CustId, ttrans.SourceSiteDBGroupID, ttrans.CustomerSiteDBGroupID, @fromSequenceId, @maxSequenceId
	FROM #tmp_TransId ttrans
	WHERE ttrans.IsInvalid = 1

	DROP TABLE #tmp_TransId
	DROP TABLE #tmp_Cust
END
