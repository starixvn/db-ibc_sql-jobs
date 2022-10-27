/*<info serverAlias="DBTXN-bodb02" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].Task_ExecRep_Wrapper
(
	@RequestID VARCHAR(4000) = '',
	@ServerName VARCHAR(200) = '',
	@AliasName VARCHAR(200) = '',
	@SqlCommand VARCHAR(MAX) = '',
	@Params VARCHAR(MAX) = '',
	@DoNotRunInServer VARCHAR(500),
	@PriorityOrder TINYINT = 2, --default for order by queueID
	@Remark VARCHAR(8000) = ''
)
AS
/*
	Created: 20220603@Sol
	Task: Database - Sync-up Standby Server data - [Redmine:167261]
	Database: DBTXN-bodb02
	
	Revision:
		- 20221025@Sol: Database - Sync-up Standby Server data - [Redmine:167261]
		
	Param's Explanation:
		- @ServerName: destination server name
		- @AliasName: destination alias name
		- @SqlCommand: command to exec
		- @DoNotRunInServer: server that the execRep will do nothing
		- @PriorityOrder: 1 for run immediately, 2 for order by queueID
		- @Remark: note here
		- @RunningMode: 1 for insert cmd to table queue, 2 will exec the cmd immediated
*/
BEGIN
	
	EXEC bodb02.dbo.ExecRep_NAP_Admin_10 @RequestID = @RequestID, @ServerName = @ServerName, @AliasName = @AliasName, @SqlCommand = @SqlCommand, @doNotRunInServer = @doNotRunInServer, @Remark = @Remark, @PriorityOrder = @PriorityOrder, @Params = @Params

END