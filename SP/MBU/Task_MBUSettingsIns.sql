/*<info serverAlias="DBTXN-bodb02,DBACC-bodb02,DBAGE-bodb02,DBBAH-bodb02,DBTP-bodb02,DBBAL-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_MBUSettingsIns] 
	@VName VARCHAR(64), 
	@VValue VARCHAR(255)
AS
/*
	Created: 20220706@Patrick
	Task: Insert Setting by Key
	DB: DBTXN/bodb02
	Revisions:
		- 20220706@Patrick: init [Redmine:#173554]
	Params:
*/
BEGIN
	SET NOCOUNT ON

	INSERT INTO dbo.MBUSettings(VName, VValue)
	VALUES(@VName, @VValue)
END
GO
