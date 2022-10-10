/*<info serverAlias="DBTXN-msdb" executers="" viewers="" isFunction="0"></info>*/
/*
   Created:20221003@Louisa
   Task: Enhancement - avoid wrong balance value due to DBTrans got issue [Redmine:#178231]
 
	DB: DBTXN/msdb
 	
	Revisions:
		- 20221003@Louisa: Enable Job check Balance Pending process is slowly [Redmine:#178231]
 	
	Param's Explanation: 
 
*/

USE [msdb]
GO 

EXEC dbo.sp_update_job  
    @job_name = N'vndba:Check slowly BalanceUpdCreditSports process',  
    @enabled = 1 ;  
GO  