/*<info serverAlias="DBTXN-bodb02" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].Task_ExecRep_Wrapper
(
	@ServerName VARCHAR(200) = '',
	@AliasName VARCHAR(200) = '',
	@SqlCommand VARCHAR(MAX) = '',
	@Params VARCHAR(MAX) = '',
	@DoNotRunInServer VARCHAR(500),
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
		- @Remark: note here
*/
BEGIN
	
	EXEC bodb02.dbo.ExecRep_NAP_Admin_05 @ServerName = @ServerName, @AliasName = @AliasName, @SqlCommand = @SqlCommand, @doNotRunInServer = @doNotRunInServer, @Remark = @Remark, @Params = @Params

END