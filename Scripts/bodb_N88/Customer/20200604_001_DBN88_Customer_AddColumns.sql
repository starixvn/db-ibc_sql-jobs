/*<info serverAlias="DBN88-bodb_N88"></info>*/
/*
	Created: 20200604@Percy
	DB: DBN88-bodb_N88
	Task: Add new columns TpUserName (Saba Username2), TpSystemUserName (Saba Username)

	Step 1: Add columns
*/

USE bodb_N88
GO

ALTER TABLE dbo.Customer
	ADD TpUserName VARCHAR(50)
		,TpSystemUserName VARCHAR(50)
GO