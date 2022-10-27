/*<info serverAlias="DBTXN-bodb02" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].ExecRep_NAP_Admin_10 
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
		- 20220603@Sol: Database - Sync-up Standby Server data - [Redmine:167261]
		
	Param's Explanation:
		- @ServerName: destination server name
		- @AliasName: destination alias name
		- @SqlCommand: command to exec
		- @DoNotRunInServer: server that the execRep will do nothing
		- @PriorityOrder: 1 for run immediately, 2 for order by queueID
		- @Remark: note here
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @CurrServerName VARCHAR(200) = @@SERVERNAME, @ServerNameByAlias VARCHAR(200)
	
	BEGIN
		--check if this sp is called in dbtrans than do nothing  
		IF @CurrServerName = @doNotRunInServer --'DB-60\DEVDBTRANS' for example
		BEGIN
			RETURN
		END
		ELSE -- this block code is used when this sp is executed at replication server  
		BEGIN
			EXEC dbo.Get_ServerName_By_Alias @Alias  = @AliasName, @ServerName = @ServerNameByAlias OUTPUT
			IF (@ServerNameByAlias = @CurrServerName)
			BEGIN
        		INSERT INTO JobExecutionQueue (RequestID, ServerName, AliasName, SqlCommand, Params, ExecStatus, PriorityOrder, CreatedDate, CompletedDate, ModifiedDate, Remark)
				VALUES (@RequestID, @ServerName, @AliasName, @SqlCommand, @Params, 'Waiting', @PriorityOrder, GETDATE(), NULL, NULL, @Remark);
			END
		END
	END

END