/*<info serverAlias="DBAGE-bodb02" executers="" selectors="" viewers="" isFunction="0" isNested="0"></info>*/
/* 
	Created by:20220428@Max
    Task: SQL Server Upgrade to 2019 for DBMSG & enhance related jobs on replicated servers [Redmine:#171913]
    DB: DBBAH/bodb02

*/

USE [msdb]
GO
EXEC msdb.dbo.sp_update_jobstep @job_name=N'bodb02: SSB - Get settled tickets'
		,@step_id=1
		,@on_success_action=4
		,@on_success_step_id=2
		,@on_fail_action=2
		,@step_name=N'Call SP Task_SSB_SettledTickets_Control_Job'
		,@command=N'EXEC dbo.Task_SSB_SettledTickets_Control_Job  @Jobname = ''bodb02: SSB - Get settled tickets'' , @Waitfordelay = ''00:00:00.280'''
GO


