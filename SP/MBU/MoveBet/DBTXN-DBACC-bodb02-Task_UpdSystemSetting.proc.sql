SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE [dbo].[Task_UpdSystemSetting]
(
	@VValue VARCHAR(200),
	@VName VARCHAR(50)
)
AS
/*
	Created: 20150617@DAniel
	DB: DBACC/bodb02; DBTXN/bodb02
	Task: Update a specific flag of system's Global Settings
	
	Revisions: 
		- 20150617@Daniel: Created for separating custDB to new server DBCUST [Redmine:#36216]  
		- 20160909@Patrick: Duplicated to DBTXN
*/
BEGIN
	SET NOCOUNT ON
	UPDATE dbo.SystemSettings SET VValue = @VValue WHERE VName = @VName
END
GO
/*<info serverAlias="DBTXN-bodb02,DBACC-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/