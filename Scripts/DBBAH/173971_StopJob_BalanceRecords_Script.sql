/*<info serverAlias="DBBAH-bodb02" executers="" isFunction="0"></info>*/
/*
    Created: 20220629@Helen
	Task: BalanceRecord -> wrong capture balance change and new balance when resettle tickets AE-Sexy product [Redmine:#173971]
	DB:DBBAH/bodb02

*/
-- STOP JOB AND DISABLE JOB
EXEC msdb.dbo.sp_stop_job @job_name='bodb02 : Task_BalanceRecord_Insert'
EXEC msdb.dbo.sp_update_job @job_name='bodb02 : Task_BalanceRecord_Insert',@enabled = 0