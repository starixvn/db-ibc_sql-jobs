/*<info serverAlias="DBBET-bk"></info>*/
USE [msdb]
GO
EXEC msdb.dbo.sp_update_jobstep @job_name=N'BK : FC'
		,@step_id=1
		,@command=N'EXEC dbo.Task_DBBET_Control_Job @Jobname = ''BK : FC'' , @Waitfordelay = ''00:00:10.000'''
GO
EXEC msdb.dbo.sp_update_jobstep @job_name=N'BK : FC Rej'
		,@step_id=2
		,@command=N'EXEC dbo.Task_DBBET_Control_Job @Jobname = ''BK : FC Rej'' , @Waitfordelay = ''00:00:30.000'''
GO