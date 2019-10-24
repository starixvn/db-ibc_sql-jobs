use msdb
go

/*
	Created: 20191022@Percy
	DB: DB06x
	Task: Modify jobs to archive data for LicenseeBATransaction_active
*/

------ job check and delete
exec dbo.sp_update_job
	@job_name = 'bodb_Licensee: Archive BA Trans'
	,@new_name = 'bodb_Licensee: Archive BA Transaction - Correct and Delete data'

exec dbo.sp_update_jobstep
	@job_name = 'bodb_Licensee: Archive BA Transaction - Correct and Delete data'
	,@step_id = 5
	,@step_name = 'Archive BA Transaction - Correct and Delete data'
	,@database_name = 'bodb02'
	,@command = 'EXEC dbo.Task_LicenseeBATransaction_Archive_Delete'


------ job copy
exec dbo.sp_add_job
	@job_name = 'bodb_Licensee: Archive BA Transaction - Copy data'
	,@enabled = 1
	,@notify_level_eventlog = 0
	,@notify_level_email = 0
	,@notify_level_netsend = 0
	,@notify_level_page = 0
	,@delete_level = 0
	,@description = N'No description available.'
	,@category_name = N'[Uncategorized (Local)]'
	,@owner_login_name = N'sa'

exec dbo.sp_add_jobstep
	@job_name = 'bodb_Licensee: Archive BA Transaction - Copy data'
	,@step_id = 1
	,@step_name = N'Archive BA Transaction - Copy data'
	,@on_success_action = 1
	,@database_name = N'bodb02'
	,@command = N'EXEC dbo.Task_LicenseeBATransaction_Archive_Copy'

exec dbo.sp_add_jobschedule
	@job_name = 'bodb_Licensee: Archive BA Transaction - Copy data'
	,@name = N'Everyday before MoveBet New'
	,@enabled = 1
	,@freq_type = 4
	,@freq_interval = 1
	,@freq_subday_type = 1
	,@freq_subday_interval = 0
	,@freq_relative_interval = 0
	,@freq_recurrence_factor = 0
	,@active_start_date = 20191022
	,@active_end_date = 99991231
	,@active_start_time = 60000
	,@active_end_time = 235959