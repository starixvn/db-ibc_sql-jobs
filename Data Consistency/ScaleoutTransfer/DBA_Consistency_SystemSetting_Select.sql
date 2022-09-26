/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].DBA_Consistency_SystemSetting_Select
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
	DB: DBCONSISTENCY-bodb_Consistency

	Revisions: 
		- 20220823@Sol: Scale out DBTrans - Detect data consistency SiteDB and CentralDB 
						- Get last transid and new last transid - [Redmine:#175881]

	Param's Expanation:
*/
BEGIN
	SET NOCOUNT ON

	--parameters
	DECLARE 
		@checkDiffSiteGroupIdKey VARCHAR(50) = 'DiffSGId_LastTransId'
		,@minTransID BIGINT = 0 --- for the first time run sp, 
		,@currTime DATETIME

	---validate
	IF (@CheckConsistencyKeyName <> @checkDiffSiteGroupIdKey)
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'Invalid consistency key name!'
		RETURN
	END
	
	--check if the setting exists or not, if exists, get the value, if not, select min transid and insert the setting
	--this is for the first time that sp run, next time will get the last transid
	BEGIN
		IF NOT EXISTS (
					SELECT 1
					FROM dbo.DBA_SystemSettings s WITH (NOLOCK)
					WHERE s.VName = @CheckConsistencyKeyName
					)
			BEGIN
				SELECT @ErrCode = 100, @ErrMsg = 'Consistency key is not exist!'
				RETURN
			END
			ELSE --get value from system setting
			BEGIN
				SELECT @TransferLastTransId = CAST(VValue AS BIGINT)
				FROM dbo.DBA_SystemSettings s WITH (NOLOCK)
				WHERE VName = @CheckConsistencyKeyName
			END
	END

	---assign current time - 2 mins to @currTime
	SELECT @currTime =  DATEADD(MINUTE, -2, GETDATE())

	---get last transid
	BEGIN
		SELECT @NewTransferLastTransId = MAX(t.TransId)
		FROM bodb02.dbo.Transfer t WITH (NOLOCK)
			INNER JOIN bodb02.dbo.Customer c WITH (NOLOCK)
						ON t.CustId = c.custid
					INNER JOIN bodb02.dbo.Site s WITH (NOLOCK)
						ON s.site = c.site
		WHERE t.TransId > @transferLastTransId
			AND t.TransDate < @currTime
			AND s.SiteDBGroupID = 0

		---incase cannot get latest transid due to no new transid with transdate < getdate() - 2 minutes, keep the value setting unchanged
		IF (ISNULL(@NewTransferLastTransId, 0) = 0)
		BEGIN
			SELECT @NewTransferLastTransId = @TransferLastTransId
		END
	END

END
GO