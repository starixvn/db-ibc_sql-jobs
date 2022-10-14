/*<info serverAlias="DBSIG-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SiteDB_DBA_Consistency_DetectSiteDBGroupID_Job]
AS 
/*
Created by: 20220824@Victoria
Task: Detect SiteDBGroupID
DB: DBSIG-bodb02
Revisions:
	- 20220824@Victoria: Rule #53 - Detect tickets contain value different from SiteDBGroupID of the site setting configuration
							and SiteGroupDBID on tickets contain value different from site of customer [Redmine:#175881]
	- 20221007@Victoria: Modify to add FromTransID and ToTransID in ResultSet [Redmine: #178864]
Param's Expanation:
*/
BEGIN
	SET NOCOUNT ON

	CREATE TABLE #CustSiteDBGroupID_Invalid
	(
		[TableName] [VARCHAR](50) NOT NULL,
		[TransID] [BIGINT] NOT NULL,
		[CustID] [INT] NULL,
		[SiteDBGroupID] [SMALLINT] NULL,
		[SiteDBGroupIDConfigured] [SMALLINT] NULL,
		[FromTransID] [BIGINT] NULL,
		[ToTransID] [BIGINT] NULL
	)
	
	DECLARE @maxTransId_bettrans BIGINT
			, @maxTransId_bettransLC BIGINT
			, @maxTransId_bettransG BIGINT
			, @maxTransId_bettransRnG BIGINT
			, @maxTransId_translog BIGINT
			, @maxTransId_Transfer BIGINT 
			, @maxTransId_bettransm BIGINT 
			, @batchCount INT = 4000
			, @SiteDBGroupID SMALLINT

	SET @SiteDBGroupID = dbo.f_Get_SiteDBGroupID()

	
	--1. bettrans
	EXEC dbo.SiteDB_DBA_Consistency_DetectSiteDBGroupID_bettrans @batchCount = @batchCount
											, @SiteDBGroupID = @SiteDBGroupID
											, @maxTransId = @maxTransId_bettrans OUTPUT

	--Update Setting
	IF @maxTransId_bettrans IS NOT NULL
	BEGIN
		UPDATE c 
		SET c.ConfigValue = @maxTransId_bettrans
		FROM dbo.SiteDB_DataConsistencyCheck_Config c WITH (ROWLOCK, UPDLOCK)
		WHERE c.ConfigName = 'bettrans'
	END
	-----------------------------------------------

	--2. bettransLC
	EXEC dbo.SiteDB_DBA_Consistency_DetectSiteDBGroupID_bettransLC @batchCount = @batchCount
												, @SiteDBGroupID = @SiteDBGroupID
												, @maxTransId = @maxTransId_bettransLC OUTPUT

	--Update Setting
	IF @maxTransId_bettransLC IS NOT NULL
	BEGIN
		UPDATE c 
		SET c.ConfigValue = @maxTransId_bettransLC
		FROM dbo.SiteDB_DataConsistencyCheck_Config c WITH (ROWLOCK, UPDLOCK)
		WHERE c.ConfigName = 'bettransLC'
	END
		
	----3. bettransG
	EXEC dbo.SiteDB_DBA_Consistency_DetectSiteDBGroupID_bettransG @batchCount = @batchCount
											, @SiteDBGroupID = @SiteDBGroupID
											, @maxTransId = @maxTransId_bettransG OUTPUT

	--Update Setting
	IF @maxTransId_bettransG IS NOT NULL
	BEGIN
		UPDATE c 
		SET c.ConfigValue = @maxTransId_bettransG
		FROM dbo.SiteDB_DataConsistencyCheck_Config c WITH (ROWLOCK, UPDLOCK)
		WHERE c.ConfigName = 'bettransG'
	END
	
	----4. bettransRNG
	EXEC dbo.SiteDB_DBA_Consistency_DetectSiteDBGroupID_bettransRNG @batchCount = @batchCount
												, @SiteDBGroupID = @SiteDBGroupID
												, @maxTransId = @maxTransId_bettransRnG OUTPUT

	--Update Setting
	IF @maxTransId_bettransRnG IS NOT NULL
	BEGIN
		UPDATE c 
		SET c.ConfigValue = @maxTransId_bettransRnG
		FROM dbo.SiteDB_DataConsistencyCheck_Config c WITH (ROWLOCK, UPDLOCK)
		WHERE c.ConfigName = 'bettransRNG'
	END

	----5. translog
	EXEC dbo.SiteDB_DBA_Consistency_DetectSiteDBGroupID_translog @batchCount = @batchCount
											, @SiteDBGroupID = @SiteDBGroupID
											, @maxTransId = @maxTransId_translog OUTPUT
	
	--Update Setting
	IF @maxTransId_translog IS NOT NULL
	BEGIN
		UPDATE c 
		SET c.ConfigValue = @maxTransId_translog
		FROM dbo.SiteDB_DataConsistencyCheck_Config c WITH (ROWLOCK, UPDLOCK)
		WHERE c.ConfigName = 'translog'
	END


	----6. Transfer
	EXEC dbo.SiteDB_DBA_Consistency_DetectSiteDBGroupID_Transfer @batchCount = @batchCount
											, @SiteDBGroupID = @SiteDBGroupID
											, @maxTransId = @maxTransId_Transfer OUTPUT
	
	--Update Setting
	IF @maxTransId_Transfer IS NOT NULL
	BEGIN
		UPDATE c 
		SET c.ConfigValue = @maxTransId_Transfer
		FROM dbo.SiteDB_DataConsistencyCheck_Config c WITH (ROWLOCK, UPDLOCK)
		WHERE c.ConfigName = 'Transfer'
	END
	
	----7. bettransm
	EXEC dbo.SiteDB_DBA_Consistency_DetectSiteDBGroupID_bettransm @batchCount = @batchCount
											, @SiteDBGroupID = @SiteDBGroupID
											, @maxTransId = @maxTransId_bettransm OUTPUT
	
	--Update Setting
	IF @maxTransId_bettransm IS NOT NULL
	BEGIN
		UPDATE c 
		SET c.ConfigValue = @maxTransId_bettransm
		FROM dbo.SiteDB_DataConsistencyCheck_Config c WITH (ROWLOCK, UPDLOCK)
		WHERE c.ConfigName = 'bettransm'
	END
	
	--8. Send Mail
	--Invalid in case of checking mismatch sitedbgroupid between server config and ticket
	--OR Invalid in case of checking mismatch sitedbgroupid between ticket & table site 
	SELECT TableName, TransID, CustID, SiteDBGroupID, SiteDBGroupIDConfigured
	FROM #CustSiteDBGroupID_Invalid
	--WHERE CustID = 23963984

	SELECT DISTINCT TableName, FromTransID, ToTransID
	FROM #CustSiteDBGroupID_Invalid

	DROP TABLE #CustSiteDBGroupID_Invalid
END