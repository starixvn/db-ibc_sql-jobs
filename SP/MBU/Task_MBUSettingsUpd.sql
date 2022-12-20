/*<info serverAlias="DBTXN-bodb02,DBACC-bodb02,DBAGE-bodb02,DBBAH-bodb02,DBTP-bodb02,DBBAL-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_MBUSettingsUpd] 
	@VName VARCHAR(64), 
	@VValue VARCHAR(255),
	@IsOverride BIT = 1
AS
/*
	Created: 20220706@Patrick
	Task: Update Setting by Key
	DB: DBTXN/bodb02
	Revisions:
		- 20220706@Patrick: init [Redmine:#173554]
		
	Params:
		+ @Mode: 
			0: @VValue value is free text & set override VValue
			9999: @VValue value must be integer & not set override VValue.
*/
BEGIN
	SET NOCOUNT ON
	IF @IsOverride = 0
	BEGIN
		UPDATE s WITH(ROWLOCK, UPDLOCK)
		SET VValue = CAST((CAST(VValue AS INT) + CAST(@VValue AS INT)) AS VARCHAR(10))
		FROM dbo.MBUSettings s
		WHERE VName = @VName
	END
	ELSE
	BEGIN
		UPDATE dbo.MBUSettings SET VValue = @VValue WHERE VName = @VName
	END
END
GO
