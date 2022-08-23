/*<info serverAlias="DBSIG-bodb02" executers="" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[SiteDB_DBA_Consistency_SystemSetting_Update]
(
	@SiteDBGroupID SMALLINT,
	@TransferLastTransId BIGINT = 0,
	@TransferCollLastTransId BIGINT = 0,
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
						- update last transid into system setting - [Redmine:#155714]

	Param's Expanation:
*/
BEGIN
	SET NOCOUNT ON

	--parameters
	DECLARE 
		@transferKey VARCHAR(50) = 'SiteDB_CheckConsistency_Transfer_LastTransId'
		,@transferCollKey VARCHAR(50) = 'SiteDB_CheckConsistency_TransferColl_LastTransId'
		,@internalSiteDBGroupID SMALLINT

	---get site group id
	SELECT @internalSiteDBGroupID = dbo.f_Get_SiteDBGroupID()

	---validate data
	IF (@SiteDBGroupID <> @internalSiteDBGroupID) -- invalid site group id, return error
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'Invalid SiteDBGroupID!'
		RETURN
	END

	IF (ISNULL(@TransferLastTransId, 0) = 0 OR ISNULL(@TransferCollLastTransId, 0) = 0)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Invalid LastTransID!'
		RETURN
	END

	--update setting
	BEGIN
		
		UPDATE bodb02.dbo.SystemSettings
			SET VValue = @TransferLastTransId
		where VName = @transferKey
			
		UPDATE bodb02.dbo.SystemSettings
			SET VValue = @TransferCollLastTransId
		where VName = @transferCollKey
	END
	
END
GO