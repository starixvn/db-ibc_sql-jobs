/*<info serverAlias="DBSIG-bodb02" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[SiteDB_DBA_Consistency_SystemSetting_Update]
(
	@CheckConsistencyKeyName VARCHAR(50),
	@NewTransferLastTransId BIGINT = 0,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg VARCHAR(MAX) = '' OUTPUT 
)
AS
/*
	Created: 20220823@Sol
	Task: Data consistency
	DB: DBSIG-bodb02

	Revisions: 
		- 20220823@Sol: Scale out DBTrans - Detect data consistency SiteDB and CentralDB 
						- update last transid into system setting - [Redmine:#175881]

	Param's Expanation:
*/
BEGIN
	SET NOCOUNT ON

	--parameters
	DECLARE 
		@checkCountKey VARCHAR(50) = 'SiteDB_CheckCons_Transfer_Count_LastTransId'
		,@checkDiffSiteGroupIdKey VARCHAR(50) = 'SiteDB_CheckCons_Transfer_DiffSGId_LastTransId'
		,@internalSiteDBGroupID SMALLINT

	---validate data
	IF (@CheckConsistencyKeyName NOT IN(@checkCountKey,@checkDiffSiteGroupIdKey))
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Invalid consistency key name!'
		RETURN
	END

	IF (ISNULL(@NewTransferLastTransId, 0) = 0)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Invalid LastTransID!'
		RETURN
	END

	--update setting
	BEGIN
		
		UPDATE bodb02.dbo.SystemSettings
			SET VValue = @NewTransferLastTransId
		WHERE VName = @CheckConsistencyKeyName

	END

	IF (@@ROWCOUNT = 0)
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'No row was updated!'
		RETURN
	END
	
END
GO