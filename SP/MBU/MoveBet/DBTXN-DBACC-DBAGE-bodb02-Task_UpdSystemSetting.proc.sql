/*<info serverAlias="DBAGE-bodb02,DBTXN-bodb02,DBBOF-bodb02" executers="bodbAdminNet" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_UpdSystemSetting]
(
	@VValue VARCHAR(200),
	@VName VARCHAR(50),
	@IsOverride BIT = 1
)
AS
/*
	Created: 20150617@Daniel
	DB: DBACC/bodb02,DBTXN/bodb02,DBAGE/bodb02
	Task: Update a specific flag of system's Global Settings
	Params:
		+ @IsOverride: 
			1: @VValue value is free text & set override VValue
			0: @VValue value must be integer & not set override VValue.

	Revisions: 
		- 20150617@Daniel: Created for separating custDB to new server DBCUST [Redmine:#36216]  
		- 20160909@Patrick: Duplicated to DBTXN
		- 20210331@Patrick: Adding special logic for MB_ReadyUpdMBDate [Redmine:#149927]
		- 20220804@Patrick: Support scale-out for deposit site Redmine: [#175602]
*/
BEGIN
	SET NOCOUNT ON
	IF @IsOverride = 0
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