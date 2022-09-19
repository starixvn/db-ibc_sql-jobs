/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_SystemSetting_Update]
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
	DB: DBCONSISTENCY-bodb_Consistency

	Revisions: 
		- 20220823@Sol: Scale out DBTrans - Detect data consistency SiteDB and CentralDB 
						- update last transid into system setting - [Redmine:#175881]

	Param's Expanation:
*/
BEGIN
	SET NOCOUNT ON

	--parameters
	DECLARE 
		@checkDiffSiteGroupIdKey VARCHAR(50) = 'DiffSGId_LastTransId'

	---validate data
	IF (@CheckConsistencyKeyName <> @checkDiffSiteGroupIdKey)
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'Invalid consistency key name!'
		RETURN
	END

	IF (ISNULL(@NewTransferLastTransId, 0) = 0)
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'Invalid LastTransID!'
		RETURN
	END

	--update setting
	BEGIN
		
		UPDATE dbo.DBA_SystemSettings
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