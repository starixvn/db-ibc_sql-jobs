/*<info serverAlias="DBARC-msdb"></info>*/
exec msdb.dbo.sp_update_jobstep @job_name = N'Joe : Thursday Routine on DB06'
	, @step_id = 8
	, @subsystem=N'TSQL'
	, @command=N'
SET NOCOUNT ON
WHILE (SELECT VValue FROM DBTXN.bodb02.dbo.SystemSettings WITH (NOLOCK) WHERE VName = ''Task_Archive_State'') <> ''Done''
BEGIN
	DECLARE @__VName VARCHAR(50)
	SELECT @__VName = VValue FROM bodb02.dbo.SystemSettings WITH(NOLOCK) WHERE VName = ''Task_Arc_Flag_Name''
	EXEC DBTXN.bodb02.dbo.Task_Archive_SetState @State = ''Done'', @VName = @__VName

	-- delay 10 seconds before next check
	WAITFOR DELAY ''000:00:10.000''
END'
	, @database_name=N'master'

go

exec msdb.dbo.sp_add_jobstep @job_name = N'Joe : Thursday Routine on DB06'
	, @step_id = 8
	, @cmdexec_success_code = 0
	, @on_success_action = 3
	, @on_success_step_id = 0
	, @on_fail_action = 2
	, @on_fail_step_id = 0
	, @retry_attempts = 0
	, @retry_interval = 0
	, @step_name = N'Archive events'
	, @subsystem=N'TSQL'
	, @command=N'
EXEC dbo.Task_Archive_Event_Control'
	, @database_name=N'bodb_Archive'

go
exec msdb.dbo.sp_delete_jobstep @job_name = N'Joe : Thursday Routine on DB06'
	, @step_id = 4

go

exec msdb.dbo.sp_delete_jobstep @job_name = N'Joe : Thursday Routine on DB06'
	, @step_id = 4

go

