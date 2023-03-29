

-- Create User
 

DECLARE @strUser	VARCHAR(MAX) = ''
DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
SELECT db.name FROM master.sys.databases db
WHERE db.name not in ('master','tempdb','model','msdb', 'distribution', 'SSISDB','ReportServer', 'ReportServerTempDB', 'RedGate')
		AND db.state = 0 --ONLINE
		AND is_read_only = 0

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('SPVN\gary.vu')
			,('SPVN\chris.lu')
			,('SPVN\aaron.dinh')
			,('SPVN\harry.vu')
			,('SPVN\liz.nguyen')
			,('SPVN\paladin.dao')
			,('spvn\carter.ngo')
			,('spvn\rachel.vo') 

SELECT	@strUser = @strUser 
					+ 'USE ' + d.DBName + ';'
					+ CHAR(13)
					----+ 'EXEC sp_dropuser' + '''' + t.name + ''''
					+ 'IF NOT EXISTS (SELECT TOP 1 1 FROM sys.database_principals WHERE NAME = ''' + t.Name + ''') '
					+ 'CREATE USER ' + '[' + t.Name + ']' + ' FOR LOGIN ' + '[' + t.Name + ']' + ' WITH DEFAULT_SCHEMA=[dbo] ' + ';'
					+ CHAR(13)
					+ 'ALTER USER' + '[' + t.Name + ']' + ' WITH DEFAULT_SCHEMA=[dbo]' + ';'
					+ CHAR(13)
FROM	@tmpAffectedDB d
	CROSS APPLY (
		SELECT	t.Name
		FROM	@tmpMember t
	) t

EXEC (@strUser)
waitfor delay '00:00:01'
 
-------------------------------------------
-- Add Role for member
 
DECLARE  @RoleName VARCHAR(50) = 'db_owner' 
  
SET @strUser = ''
SELECT	@strUser = @strUser
					+ 'USE ' + d.DBName + ';'
					+ CHAR(13)
					--+ 'EXEC sp_AddRoleMember ''' + t.RoleName + ''',''' + t.Name + ''' ' + ';'
					+ 'EXEC sp_AddRoleMember ''' + @RoleName + ''',''' + t.Name + ''' ' + ';'
					+ CHAR(13)
FROM	@tmpAffectedDB d
	CROSS APPLY (
		SELECT Name 
		FROM @tmpMember 
	)t

EXEC (@strUser)
