/*
	For Olympus team:
	Affected DB:
		All except system DBs and some special DBs

	Windows domain account:
		spvn\johnson.nguyen
		spvn\sophia.nguyen
		spvn\tacy.nguyen
		spvn\elodie.ho
		spvn\kathy.nguyen
		spvn\tina.vo
		spvn\helen.do
		spvn\percy.nguyen
		spvn\sol.le
		spvn\eden.dang
		spvn\bobby.nguyen
*/
-- Create User
IF @@SERVERNAME <> 'DB-61\DEVDB053'
BEGIN
	SELECT 'Must be run on DB-61\DEVDB053' AS 'Error'

	RETURN
END

DECLARE @strUser	VARCHAR(MAX) = ''
DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
SELECT name
FROM   sys.databases
WHERE  CAST(CASE WHEN name IN ('master', 'model', 'msdb', 'tempdb', 'MonDB', 'LocalMonitorDB') THEN 1 
				WHEN name LIKE 'ReportServer%' THEN 1
				WHEN is_read_only = 1 THEN 1
				WHEN state <> 0 THEN 1
				ELSE is_distributor 
			END AS BIT) = 0


DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\johnson.nguyen'), ('spvn\sophia.nguyen')
		,('spvn\tacy.nguyen'), ('spvn\elodie.ho'), ('spvn\kathy.nguyen')
		,('spvn\tina.vo'), ('spvn\helen.do'), ('spvn\percy.nguyen')
		, ('spvn\sol.le'), ('spvn\eden.dang'), ('spvn\bobby.nguyen')		


/*
	USE DBName
	GO 
	CREATE USER vnXXX FOR LOGIN vnXXX WITH DEFAULT_SCHEMA=[dbo] 
	GO
*/
SELECT	@strUser = @strUser 
					+ 'USE ' + d.DBName + ';'
					+ CHAR(13)
					+ 'IF NOT EXISTS (SELECT TOP 1 1 FROM sys.database_principals WHERE NAME = ''' + t.Name + ''') 
					AND NOT EXISTS (SELECT 1 FROM sys.database_principals d JOIN sys.server_principals s ON d.sid = s.sid WHERE s.NAME = ''' + t.Name + ''') '
					+ CHAR(13) + 'BEGIN'
					+ CHAR(13)
					+ 'CREATE USER ' + '[' + t.Name + ']' + ' FOR LOGIN ' + '[' + t.Name + ']' + ' WITH DEFAULT_SCHEMA=[dbo] ' + ';'
					+ CHAR(13)
					+ 'ALTER USER' + '[' + t.Name + ']' + ' WITH DEFAULT_SCHEMA=[dbo]' + ';'
					+ CHAR(13) + 'END'
					+ CHAR(13) + 'ELSE'
					+ CHAR(13)
					+ 'PRINT DB_NAME() + ''.[' + t.Name + ']'' ' + CHAR(13)
FROM	@tmpAffectedDB d
	CROSS APPLY (
		SELECT	t.Name
		FROM	@tmpMember t
	) t

EXEC (@strUser)
GO

-------------------------------------------
-------------------------------------------
-- Add Role for member

IF @@SERVERNAME <> 'DB-61\DEVDB053'
BEGIN
	SELECT 'Must be run on DB-61\DEVDB053' AS 'Error'

	RETURN
END

DECLARE @strUser VARCHAR(MAX) = ''
		,@RoleName VARCHAR(50) = 'db_owner'

DECLARE @tmpMember TABLE (Name VARCHAR(50))
DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
SELECT name
FROM   sys.databases
WHERE  CAST(CASE WHEN name IN ('master', 'model', 'msdb', 'tempdb', 'MonDB', 'LocalMonitorDB') THEN 1 
				WHEN name LIKE 'ReportServer%' THEN 1
				WHEN is_read_only = 1 THEN 1
				WHEN state <> 0 THEN 1
				ELSE is_distributor 
			END AS BIT) = 0

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\johnson.nguyen'), ('spvn\sophia.nguyen')
		,('spvn\tacy.nguyen'), ('spvn\elodie.ho'), ('spvn\kathy.nguyen')
		,('spvn\tina.vo'), ('spvn\helen.do'), ('spvn\percy.nguyen')
		, ('spvn\sol.le'), ('spvn\eden.dang'), ('spvn\bobby.nguyen')
		

/*
	USE DBName
	GO
	EXEC sp_AddRoleMember 'db_xxx', 'vnxxx'
	GO
*/
SELECT	@strUser = @strUser
					+ 'USE ' + d.DBName + ';'
					+ CHAR(13)
					+ 'IF EXISTS (SELECT TOP 1 1 FROM sys.database_principals WHERE NAME = ''' + t.Name + ''') '
					+ CHAR(13)
					+ 'EXEC sp_AddRoleMember ''' + @RoleName + ''',''' + t.Name + ''' ' + ';'
					+ CHAR(13) + 'ELSE'
					+ CHAR(13)
					+ 'PRINT DB_NAME() + ''.[' + t.Name + ']''' + CHAR(13)
FROM	@tmpAffectedDB d
	CROSS APPLY (
		SELECT Name
		FROM @tmpMember 
	)t

EXEC (@strUser)

GO