/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/

/*
    Created by: 20220930@Victoria
	Task: 
	DB: DBCONSISTENCY-bodb_Consistency
	Revisions:
		- 20220930@Victoria:  Inital Writing [Redmine:#178445]
*/

DECLARE @maxSequenceId_bettrans BIGINT
		, @maxSequenceId_bettransLC BIGINT
		, @maxSequenceId_bettransG BIGINT
		, @maxSequenceId_bettransRnG BIGINT
		, @maxSequenceId_translog BIGINT

SELECT	@maxSequenceId_bettrans = MAX(sequenceid)
FROM	bodb02.dbo.bettrans WITH (NOLOCK)

SELECT	@maxSequenceId_bettransLC = MAX(sequenceid)
FROM	bodb02.dbo.bettransLC WITH (NOLOCK)

SELECT	@maxSequenceId_bettransG = MAX(sequenceid)
FROM	bodb02.dbo.bettransG WITH (NOLOCK)

SELECT	@maxSequenceId_bettransRnG = MAX(sequenceid)
FROM	bodb02.dbo.bettransRnG WITH (NOLOCK)

SELECT	@maxSequenceId_translog = MAX(sequenceid)
FROM	bodb02.dbo.translog WITH (NOLOCK)

INSERT INTO dbo.DBA_SystemSettings (VName, VValue)
SELECT 'DiffSGId_LastSeqId_bettrans',	ISNULL(@maxSequenceId_bettrans,0)
UNION
SELECT 'DiffSGId_LastSeqId_bettransLC', ISNULL(@maxSequenceId_bettransLC,0)
UNION
SELECT 'DiffSGId_LastSeqId_bettransG',	ISNULL(@maxSequenceId_bettransG,0)
UNION
SELECT 'DiffSGId_LastSeqId_bettransRnG', ISNULL(@maxSequenceId_bettransRnG,0)
UNION
SELECT 'DiffSGId_LastSeqId_translog',	ISNULL(@maxSequenceId_translog,0)