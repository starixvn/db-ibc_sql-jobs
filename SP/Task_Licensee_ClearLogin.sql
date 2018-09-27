/*<info serverAlias="DBCUST-bodb_Licensee" executers="" viewers="vnteam" isFunction="0"></info>*/
USE [bodb_Licensee]
GO

 
CREATE PROCEDURE [dbo].[Task_Licensee_ClearLogin]
	
AS

/*
	Created:  20101209@Henry
	Task: Clear Login
	DB: DBCUST.bodb_Licensee
	Original SP:
	
	Revisions:
		- 20180926@Sophia: migrate bodb_Licensee from DB052 to DBCUST [redmine: #99855]
		
*/
SET NOCOUNT ON
DELETE FROM On_User with (updlock)
WHERE        
reload_time < dateadd(minute,-30,CURRENT_TIMESTAMP) AND (ServerID IN (200,201))


GO


