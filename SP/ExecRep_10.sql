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
	SELECT 'DBACC', 'DB06C2\DB06', 'Sub' UNION ALL
	SELECT 'DBACC', 'DB062', 'Sub' UNION ALL
	SELECT 'DBBOF', 'DB055', 'Sub' UNION ALL
	SELECT 'DBBOF', 'DB054C2\DB054', 'Sub' UNION ALL
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
	SELECT 'DBACC', 'DB232', 'Sub' UNION ALL
	SELECT 'DBBOF', 'DEVDB055\INST2', 'Sub' UNION ALL
	SELECT 'DBAGE', 'DEVDB053', 'Sub' UNION ALL
	SELECT 'DBCTG', 'DB-60\DEVDBTRANS', 'Main' UNION ALL
	SELECT 'DBSite', 'DB62\DEVSITEDB', 'Main'

	--Local Test
	UNION ALL
	SELECT 'DBACC', 'DB234', 'Sub' UNION ALL
	SELECT 'DBBOF', 'DB233\SQLSERVER2008R2', 'Sub' UNION ALL
	SELECT 'DBAGE', 'DB215', 'Sub' UNION ALL
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
