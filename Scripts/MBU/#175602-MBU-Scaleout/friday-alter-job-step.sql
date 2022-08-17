USE msdb
GO

EXEC msdb.dbo.sp_update_jobstep @step_id = 2,
    @job_name = N'Joe : DBTRANS_bodb02 : Friday routine',  
	@command=N'EXEC dbo.Task_Archive_Event_Control_Job'
GO