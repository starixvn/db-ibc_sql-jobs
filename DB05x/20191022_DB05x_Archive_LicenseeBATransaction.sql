use msdb
go

/*
	Created: 20191022@Percy
	DB: DB05x
	Task: Modify jobs to archive data for LicenseeBATransaction_active
*/

exec dbo.sp_update_jobstep
	@job_name = 'bodb_LicenseeReport: Licensee Winloss - Check and Correct Data'
	,@step_id = 5
	,@step_name = 'Archive BA Transaction - Correct and Delete data'
	,@database_name = 'bodb02'
	,@command = 'EXEC dbo.Task_LicenseeBATransaction_Archive_Delete'

exec dbo.sp_add_jobstep
	@job_name = 'bodb_LicenseeReport: Daily Summary Licensee Winloss'
	,@step_id = 2
	,@step_name = 'Archive BA Transaction - Copy data'
	,@database_name = 'bodb02'
	,@command = 'EXEC dbo.Task_LicenseeBATransaction_Archive_Copy'
	,@on_success_action = 3