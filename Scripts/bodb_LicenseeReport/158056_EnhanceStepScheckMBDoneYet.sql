/*<info serverAlias="DBEXT-msdb,DBAGE-msdb" ></info>*/

/*
	Created: 20210712@Sophia
	DB: DBEXT-msdb,DBAGE-msdb
	Task: Enhance Job check MB done Yet, check more at DBACC [Redmind: 158056] 
*/

USE [msdb]
GO
EXEC msdb.dbo.sp_update_jobstep @job_name=N'bodb_LicenseeReport: DW - Check and Correct Data', @step_id=1 , 
		@command=N'EXEC Task_MoveBets_Status_Job
EXEC DBACC.bodb02.dbo.Task_MoveBets_Status_Job'
GO


USE [msdb]
GO
EXEC msdb.dbo.sp_update_jobstep @job_name=N'bodb_LicenseeReport: Licensee Winloss - Check and Correct Data', @step_id=1 , 
		@command=N'EXEC Task_MoveBets_Status_Job

EXEC DBACC.bodb02.dbo.Task_MoveBets_Status_Job'
GO
