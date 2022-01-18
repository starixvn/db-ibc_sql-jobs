/*<info serverAlias="DBCUST-msdb" executers="" selecters="" viewers="" isFunction="0" isNested="0"></info>*/
/*
    Created: 20220118@July
	Task: MBU - Timeout due to add full backup for custdb - [Redmine: #167669]
	DB: DBCUST/msdb

	Notes:
		- Create permisssion to start job [BalanceUPBackground_BackupFull_Cust]
*/

USE [msdb]
GO
CREATE USER [SqlLink] FOR LOGIN [SqlLink]
GO
USE [msdb]
GO
EXEC sp_addrolemember N'SQLAgentOperatorRole', N'SqlLink'
GO