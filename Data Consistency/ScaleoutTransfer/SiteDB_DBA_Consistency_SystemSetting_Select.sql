/*<info serverAlias="DBSIG-bodb02" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].SiteDB_DBA_Consistency_SystemSetting_Select
(
	@CheckConsistencyKeyName VARCHAR(50),
	@TransferLastTransId BIGINT OUTPUT,
	@NewTransferLastTransId BIGINT OUTPUT,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg VARCHAR(MAX)= '' OUTPUT 
)
AS
/*
	Created: 20220823@Sol
	Task: Data consistency - get last trans id and new last transid 
	DB: DBSIG-bodb02

	Revisions: 
		- 20220823@Sol: Scale out DBTrans - Detect data consistency SiteDB and CentralDB 
						- Get last transid and new last transid - [Redmine:#175881]

	Param's Expanation:
*/
BEGIN
	SET NOCOUNT ON

	--parameters
	DECLARE 
		@checkCountKey VARCHAR(50) = 'SiteDB_CheckCons_Transfer_Count_LastTransId'
		,@checkDiffSiteGroupIdKey VARCHAR(50) = 'SiteDB_CheckCons_Transfer_DiffSGId_LastTransId'
		,@minTransID BIGINT = 0 --- for the first time run sp, 
		,@currTime DATETIME

	---validate
	IF (@CheckConsistencyKeyName <> @checkCountKey OR @CheckConsistencyKeyName <> @checkDiffSiteGroupIdKey)
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'Invalid consistency key name!'
		RETURN
	END
	
	--check if the setting exists or not, if exists, get the value, if not, select min transid and insert the setting
	--this is for the first time that sp run, next time will get the last transid
	BEGIN
		IF NOT EXISTS (
				SELECT 1
				FROM bodb02.dbo.SystemSettings s WITH (NOLOCK)
				WHERE s.VName = @CheckConsistencyKeyName
				)
		BEGIN
			SELECT @minTransID = MIN(t.TransId)
			FROM Transfer t WITH (NOLOCK)

			---insert to table setting
			INSERT INTO bodb02.dbo.SystemSettings (VName,VValue)
			VALUES (@CheckConsistencyKeyName,CAST(@minTransID AS VARCHAR(200)))

			SELECT @TransferLastTransId = @minTransID
		END
		ELSE --get value from system setting
		BEGIN
			SELECT @TransferLastTransId = CAST(VValue AS BIGINT)
			FROM bodb02.dbo.SystemSettings s WITH (NOLOCK)
			WHERE VName = @CheckConsistencyKeyName
		END
	END

	---assign current time - 2 mins to @currTime
	SELECT @currTime =  DATEADD(MINUTE, -2, GETDATE())

	---get last transid
	BEGIN
		SELECT @NewTransferLastTransId = MAX(t.TransId)
		FROM dbo.Transfer t WITH (NOLOCK)
		WHERE t.TransId > @transferLastTransId
			AND t.TransDate < @currTime
	END

END
GO