/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_Consistency_CheckWrongSiteDBGroupID_Job]
AS 
/*
Created by: 20220930@Victoria
Task: Detect SiteDBGroupID
DB: DBCONSISTENCY-bodb_Consistency
Revisions:
	- 20220930@Victoria: Rule #55 - Check if bet tickets are inserted into the correct SiteDBGroupID by reverting the transID in bettransXXX tables [Redmine:#178445]
	- 20221007@Victoria: Modify to add FromSequenceID and ToSequenceID in ResultSet [Redmine: #178864]
Param's Expanation:
*/
BEGIN
	CREATE TABLE #CustSiteDBGroupID_Invalid
	(
		[TableName] [VARCHAR](50) NOT NULL,
		[TransID] [BIGINT] NOT NULL,
		[CustID] [INT] NULL,
		[SourceSiteDBGroupID] [SMALLINT] NULL,
		[CustomerSiteDBGroupID] [SMALLINT] NULL,
		[FromSequenceID] [BIGINT] NULL,
		[ToSequenceID] [BIGINT] NULL
	)
	
	DECLARE @maxSequenceId_bettrans BIGINT
			, @maxSequenceId_bettransLC BIGINT
			, @maxSequenceId_bettransG BIGINT
			, @maxSequenceId_bettransRnG BIGINT
			, @maxSequenceId_translog BIGINT

	--1. bettrans
	EXEC dbo.DBA_Consistency_CheckWrongSiteDBGroupID_bettrans @maxSequenceId = @maxSequenceId_bettrans OUTPUT

	--Update Setting
	IF @maxSequenceId_bettrans IS NOT NULL
	BEGIN
		UPDATE c 
		SET c.VValue = @maxSequenceId_bettrans
		FROM dbo.DBA_SystemSettings c WITH (ROWLOCK, UPDLOCK)
		WHERE c.VName = 'DiffSGId_LastSeqId_bettrans'
	END

	--2. bettransLC
	EXEC dbo.DBA_Consistency_CheckWrongSiteDBGroupID_bettransLC @maxSequenceId = @maxSequenceId_bettransLC OUTPUT

	--Update Setting
	IF @maxSequenceId_bettransLC IS NOT NULL
	BEGIN
		UPDATE c 
		SET c.VValue = @maxSequenceId_bettransLC
		FROM dbo.DBA_SystemSettings c WITH (ROWLOCK, UPDLOCK)
		WHERE c.VName = 'DiffSGId_LastSeqId_bettransLC'
	END

	--3. bettransG
	EXEC dbo.DBA_Consistency_CheckWrongSiteDBGroupID_bettransG @maxSequenceId = @maxSequenceId_bettransG OUTPUT

	--Update Setting
	IF @maxSequenceId_bettransG IS NOT NULL
	BEGIN
		UPDATE c 
		SET c.VValue = @maxSequenceId_bettransG
		FROM dbo.DBA_SystemSettings c WITH (ROWLOCK, UPDLOCK)
		WHERE c.VName = 'DiffSGId_LastSeqId_bettransG'
	END

	--4. bettransRnG
	EXEC dbo.DBA_Consistency_CheckWrongSiteDBGroupID_bettransRnG @maxSequenceId = @maxSequenceId_bettransRnG OUTPUT

	--Update Setting
	IF @maxSequenceId_bettransRnG IS NOT NULL
	BEGIN
		UPDATE c 
		SET c.VValue = @maxSequenceId_bettransRnG
		FROM dbo.DBA_SystemSettings c WITH (ROWLOCK, UPDLOCK)
		WHERE c.VName = 'DiffSGId_LastSeqId_bettransRnG'
	END

	--5. translog
	EXEC dbo.DBA_Consistency_CheckWrongSiteDBGroupID_translog @maxSequenceId = @maxSequenceId_translog OUTPUT

	--Update Setting
	IF @maxSequenceId_translog IS NOT NULL
	BEGIN
		UPDATE c 
		SET c.VValue = @maxSequenceId_translog
		FROM dbo.DBA_SystemSettings c WITH (ROWLOCK, UPDLOCK)
		WHERE c.VName = 'DiffSGId_LastSeqId_translog'
	END
	
	--Final: Send mail
	--Invalid in case of checking mismatch sitedbgroupid between ticket and function revert
	--OR Invalid in case of checking mismatch sitedbgroupid between ticket & table site 
	SELECT TableName, TransID, CustID, SourceSiteDBGroupID, CustomerSiteDBGroupID
	FROM #CustSiteDBGroupID_Invalid

	SELECT DISTINCT TableName, FromSequenceID, ToSequenceID
	FROM #CustSiteDBGroupID_Invalid

	DROP TABLE #CustSiteDBGroupID_Invalid
END