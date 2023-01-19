 
 

DECLARE @strUser	VARCHAR(MAX) = ''
		, @RoleName VARCHAR(50) = 'db_owner'
DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
SELECT name 
FROM   sys.databases
WHERE  CAST(CASE WHEN name IN ('master', 'model', 'msdb', 'tempdb', 'MonDB', 'LocalMonitorDB' ) THEN 1 
				WHEN name LIKE 'ReportServer%' THEN 1
				WHEN is_read_only = 1 THEN 1
		 		WHEN state <> 0 THEN 1
				ELSE is_distributor 
			END AS BIT) = 0


DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\elodie.ho' )
		, ('spvn\johnson.nguyen' )
		, ('spvn\eden.dang' )
		, ('spvn\winfred.pham' )
		, ('spvn\tacy.nguyen' )
		, ('spvn\helios.huynh'  )

		, ('spvn\sophia.nguyen' )
		, ('spvn\bobby.nguyen' )
		, ('spvn\sol.le' )
		, ('spvn\malcolm.huynh' )
		, ('spvn\evan.trinh' )
		, ('spvn\danny.nguyen' )
		, ('spvn\eddie.nguyen' )

		, ('spvn\kathy.nguyen' )
		, ('spvn\helen.do' )
		, ('spvn\louisa.vo' )
		, ('spvn\max.tran' )	
		, ('spvn\tina.vo' )
		, ('spvn\july.nguyen' )
		, ('spvn\aries.nguyen' )
 
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
waitfor delay '00:00:01'
 
SET @strUser = ''
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