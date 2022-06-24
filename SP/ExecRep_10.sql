/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE dbo.ExecRep_10
	@FunctionName VARCHAR(100),
	@Allow BIT = 0 OUTPUT,
	@AliasServer VARCHAR(128) = '' OUTPUT
AS
/*
	Created: 20210331@Patrick
	Task: ExecRep_10
	DB: DBTXN/bodb02
	Revisions:   
		- 20210323@Patrick: Initial [Redmine: #149927] 
		- 20211223@July: SQL Server Upgrade 2019- Phase 3 [Redmine: #166039] 
		- 20220624@Patrick: Balance-Up support transfer 247 [RedmineID: #173554]
*/
BEGIN
	SET NOCOUNT ON;
	DECLARE @__serverList TABLE (ServerAlias VARCHAR(128), ServerName VARCHAR(128) PRIMARY KEY)
	DECLARE @__serverName VARCHAR(128)
	SELECT @Allow = 0, @AliasServer = '', @__serverName = @@SERVERNAME

	--PRO
	INSERT INTO @__serverList(ServerAlias, ServerName)
	SELECT 'DBACC', 'DB061' UNION ALL
	SELECT 'DBACC', 'DB06C2\DB06' UNION ALL
	SELECT 'DBACC', 'DB062' UNION ALL
	SELECT 'DBBOF', 'DB055' UNION ALL
	SELECT 'DBBOF', 'DB054C2\DB054' UNION ALL
	SELECT 'DBBOF', 'DB054' UNION ALL
	SELECT 'DBAGE', 'DB052' UNION ALL
	SELECT 'DBAGE', 'DB053'

	--SIT
	UNION ALL
	SELECT 'DBACC', 'SITDB06' UNION ALL
	SELECT 'DBBOF', 'SITDB055' UNION ALL
	SELECT 'DBAGE', 'SITDB052'

	--Local Dev
	UNION ALL
	SELECT 'DBACC', 'DB232' UNION ALL
	SELECT 'DBBOF', 'DEVDB055\INST2' UNION ALL
	SELECT 'DBAGE', 'DEVDB053'

	--Local Test
	UNION ALL
	SELECT 'DBACC', 'DB234' UNION ALL
	SELECT 'DBBOF', 'DB233\SQLSERVER2008R2' UNION ALL
	SELECT 'DBAGE', 'DB215'

	IF @FunctionName = 'WaitforMBCompleted'
	BEGIN
		SELECT @Allow = 1, @AliasServer = ServerAlias
		FROM @__serverList
		WHERE ServerAlias IN ('DBACC', 'DBBOF', 'DBAGE')
			AND ServerName = @__serverName
	END
	ELSE IF @FunctionName = 'WaitforBUCompleted'
	BEGIN
		SELECT @Allow = 1, @AliasServer = ServerAlias
		FROM @__serverList
		WHERE ServerAlias IN ('DBACC', 'DBAGE')
			AND ServerName = @__serverName
	END
	
END
GO
