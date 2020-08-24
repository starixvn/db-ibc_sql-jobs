/*<info serverAlias="DBPRO-bodb02" executers="" viewers="" isFunction="0"></info>*/

/*
    Created by: 20200824@Louisa
    Task: Enable Job Cleanup External Result [Redmine:#140150]
    DB: DBPRO/bodb02
    
    Revisions:            
		- 20200824@Louisa: Enable Job Cleanup External Result [Redmine:#140150]
		
*/

USE [msdb]
GO

EXEC msdb.dbo.sp_update_job
 @job_name='bodb02: Task Cleanup External Result for Esports and OtherSports'
,@enabled = 1

GO