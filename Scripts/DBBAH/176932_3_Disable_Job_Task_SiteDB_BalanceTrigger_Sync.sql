/*<info serverAlias="DBBAH-bodb02" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/  

/*
	Created: 20220130@Louisa
    DB: DBBAH/bodb02
   
    Revisions:
		- 20220130@Louisa: Phase 2 - use Web Service to pull ticket from SiteDB to DB05/DB05BK1 [Redmine:#176932]
	
	Param's explaination:
*/

USE msdb ;  
GO  
  
EXEC dbo.sp_stop_job  
    @job_name = N'bodb02 : Task_SiteDB_BalanceTrigger_Sync' ;  
GO 

EXEC dbo.sp_update_job 
	@job_name =  N'bodb02 : Task_SiteDB_BalanceTrigger_Sync' 
	,@enabled = 0 ; 