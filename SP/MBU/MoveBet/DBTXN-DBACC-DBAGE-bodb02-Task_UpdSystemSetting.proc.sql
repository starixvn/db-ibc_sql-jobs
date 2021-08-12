/*<info serverAlias="DBAGE-bodb02,DBTXN-bodb02,DBBOF-bodb02" executers="bodbAdminNet" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_UpdSystemSetting]
(
	@VValue VARCHAR(200),
	@VName VARCHAR(50)
)
AS
/*
	Created: 20150617@Daniel
	DB: DBACC/bodb02,DBTXN/bodb02,DBAGE/bodb02
	Task: Update a specific flag of system's Global Settings
	
	Revisions: 
		- 20150617@Daniel: Created for separating custDB to new server DBCUST [Redmine:#36216]  
		- 20160909@Patrick: Duplicated to DBTXN
		- 20210331@Patrick: Adding special logic for MB_ReadyUpdMBDate [Redmine:#149927] 
*/
BEGIN
	SET NOCOUNT ON
	IF @VName = 'MB_ReadyUpdMBDate'
	BEGIN
		UPDATE s WITH(ROWLOCK, UPDLOCK)
		SET VValue = CAST((CAST(VValue AS INT) + CAST(@VValue AS INT)) AS VARCHAR(10))
		FROM dbo.SystemSettings s
		WHERE VName = @VName
	END
	ELSE
	BEGIN
		UPDATE dbo.SystemSettings SET VValue = @VValue WHERE VName = @VName
	END
END
GO