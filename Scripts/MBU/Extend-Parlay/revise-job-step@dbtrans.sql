/*<info serverAlias="DBTXN-msdb"></info>*/
exec msdb.dbo.sp_update_jobstep @job_name = N'Joe : DBTRANS_bodb02 : Thursday routine'
	, @step_id = 1
	, @step_name = N'List 7 days to archive'
	, @subsystem=N'TSQL'
	, @command=N'
DELETE FROM dbo.Task_ArchiveDate

INSERT INTO dbo.Task_ArchiveDate
SELECT DISTINCT TOP 7 winlostdate
FROM dbo.bettrans14 (nolock)
ORDER BY winlostdate

EXEC bodb02.dbo.Task_Archive_SetState @State = ''Prepare''
EXEC bodb02.dbo.Task_Archive_SetState @State = ''Flag'', @VName = ''Task_Archive_Flag_61''
EXEC bodb02.dbo.Task_Archive_SetState @State = ''Flag'', @VName = ''Task_Archive_Flag_06'''
	, @database_name=N'bodb02'

go
exec msdb.dbo.sp_update_jobstep @job_name = N'Joe : DBTRANS_bodb02 : Thursday routine'
	, @step_id = 17
	, @step_name = N'Archive - Trigger job on DB06X'
	, @subsystem=N'TSQL'
	, @command=N'
EXEC bodb02.dbo.Task_Archive_SetState @State = ''Ready'''
	, @database_name=N'bodb02'

go
exec msdb.dbo.sp_update_jobstep @job_name = N'Joe : DBTRANS_bodb02 : Thursday routine'
	, @step_id = 18
	, @step_name = N'Archive - Waitfor job done on DB06X'
	, @subsystem=N'TSQL'
	, @command=N'
SET NOCOUNT ON

WHILE (SELECT VValue FROM bodb02.dbo.SystemSettings WITH (NOLOCK) WHERE VName = ''Task_Archive_State'') <> ''Done''
BEGIN
   -- delay 10 seconds before next check
   WAITFOR DELAY ''000:00:10.000''
END

PRINT ''State Reported as Done'''
	, @database_name=N'bodb02'

go
exec msdb.dbo.sp_update_jobstep @job_name = N'Joe : DBTRANS_bodb02 : Thursday routine'
	, @step_id = 19
	, @on_success_action = 1
	
go
exec msdb.dbo.sp_delete_jobstep @job_name = N'Joe : DBTRANS_bodb02 : Thursday routine'
	, @step_id = 20

go

