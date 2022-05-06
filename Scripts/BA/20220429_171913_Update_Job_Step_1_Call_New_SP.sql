/*<info serverAlias="DBEXT-bodb02,DBACC-bodb02,DBBOF-bodb02,DBBAL-bodb02" executers="" isFunction="0" isNested="0"></info>*/
/*
	Created by: Sol 
	Date: 20220429
	Task: Alter job step 1 to call new sp Task_BATransaction_Loop_Ins
	DB: DBEXT-bodb02,DBACC-bodb02,DBBOF-bodb02,DBBAL-bodb02
	
	Revisions:
		- 20220427@Sol: SQL Server Upgrade to 2019 for DBMSG & enhance related jobs on replicated servers - [RedmineID: #171913]
*/

GO 

USE [msdb]

GO

EXEC msdb.dbo.sp_update_jobstep @job_name = N'bodb02: Retrieve BA Transaction', @step_id=1 , 
		@command=N'EXEC dbo.Task_BATransaction_Loop_Ins'

GO

EXEC msdb.dbo.sp_delete_jobstep @job_name = N'bodb02: Retrieve BA Transaction', @step_id=2

GO