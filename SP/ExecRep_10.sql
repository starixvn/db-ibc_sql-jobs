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
		- 20220804@Patrick: Support scale-out for deposit site Redmine: [#175602]
*/
BEGIN
	SET NOCOUNT ON;
	DECLARE @__serverList TABLE (ServerAlias VARCHAR(128), ServerName VARCHAR(128) PRIMARY KEY, Level VARCHAR(32))
	DECLARE @__serverName VARCHAR(128)
	SELECT @Allow = 0, @AliasServer = '', @__serverName = @@SERVERNAME

	--PRO
	INSERT INTO @__serverList(ServerAlias, ServerName, Level)
	SELECT 'DBACC', 'DB061', 'Sub' UNION ALL
	SELECT 'DBACC', 'DB062', 'Sub' UNION ALL
	SELECT 'DBBOF', 'DB055', 'Sub' UNION ALL
	SELECT 'DBBOF', 'DB054', 'Sub' UNION ALL
	SELECT 'DBAGE', 'DB052', 'Sub' UNION ALL
	SELECT 'DBAGE', 'DB053', 'Sub' UNION ALL
	SELECT 'DBCTG', 'DBTrans', 'Main' UNION ALL
	SELECT 'DBSite', 'DBGRP01N1', 'Main' UNION ALL
	SELECT 'DBSite', 'DBGRP01N2', 'Main'

	--SIT
	UNION ALL
	SELECT 'DBACC', 'SITDB06', 'Sub' UNION ALL
	SELECT 'DBBOF', 'SITDB055', 'Sub' UNION ALL
	SELECT 'DBAGE', 'SITDB052', 'Sub' UNION ALL
	SELECT 'DBCTG', 'SITDBTrans', 'Main' UNION ALL
	SELECT 'DBSite', 'SITDBGRP01N1', 'Main' UNION ALL
	SELECT 'DBSite', 'SITDBGRP01N2', 'Main'

	--Local Dev
	UNION ALL
	SELECT 'DBACC', 'DEVDB061', 'Sub' UNION ALL
	SELECT 'DBBOF', 'DB-61\DevDB055', 'Sub' UNION ALL
	SELECT 'DBAGE', 'DB-61\DevDB053', 'Sub' UNION ALL
	SELECT 'DBCTG', 'DB-60\DEVDBTRANS', 'Main' UNION ALL
	SELECT 'DBSite', 'DB62\DEVSITEDB', 'Main'

	--Local Test
	UNION ALL
	SELECT 'DBACC', 'TESTDB061', 'Sub' UNION ALL
	SELECT 'DBBOF', 'TESTDB055', 'Sub' UNION ALL
	SELECT 'DBAGE', 'TESTDB053', 'Sub' UNION ALL
	SELECT 'DBCTG', 'TESTDBTRANS', 'Main' UNION ALL
	SELECT 'DBSite', 'TESTDB053\TESTSITEDB', 'Main'

	IF @FunctionName IN ('WaitforMBCompleted', 'WaitforBUCompleted')
	BEGIN
		SELECT @Allow = 1, @AliasServer = ServerAlias
		FROM @__serverList
		WHERE ServerAlias IN ('DBACC', 'DBBOF', 'DBAGE', 'DBSite')
			AND ServerName = @__serverName
	END
	ELSE IF @FunctionName = 'ScaleOut'
	BEGIN
		SELECT @Allow = 1, @AliasServer = ServerAlias
		FROM @__serverList
		WHERE ServerAlias IN ('DBCTG', 'DBSite')
			AND ServerName = @__serverName
	END
	
END
GO
