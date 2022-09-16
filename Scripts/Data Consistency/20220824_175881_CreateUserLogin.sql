/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/

/*
    Created by: 20220824@Victoria
    Task: 
    DB: DBCONSISTENCY-bodb_Consistency

	 Revisions:
		- 20220824@Victoria: Initial Writing [Redmineid:#175881]
*/
USE bodb_Consistency
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name='bodbAdminNet')
BEGIN
	CREATE USER bodbAdminNet FOR LOGIN bodbAdminNet
END

GO