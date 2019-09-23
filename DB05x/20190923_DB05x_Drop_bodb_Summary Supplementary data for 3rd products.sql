USE [msdb]
GO

/*
	Created: 20190923@Percy
	DB: DB052, DB053
	Task: Drop un-used jobs [RedmineID: #116925]
*/

EXEC msdb.dbo.sp_delete_job @job_name=N'bodb_Summary: Supplementary data for 3rd products', @delete_unused_schedule=1
GO

EXEC msdb.dbo.sp_delete_job @job_name=N'bodb_Summary: Supplementary data for 3rd products - Check and Correct Data', @delete_unused_schedule=1
GO