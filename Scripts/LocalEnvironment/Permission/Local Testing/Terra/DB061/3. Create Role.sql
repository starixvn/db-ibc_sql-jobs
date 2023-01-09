 
-- Create Role
IF @@SERVERNAME NOT IN ( 'DEVDB061' , 'TESTDB061' )
BEGIN
	SELECT 'Wrong server' AS 'Error'
	RETURN
END

DECLARE @RoleName VARCHAR(50) = 'db_Terra'
		,@strRole	VARCHAR(MAX) = ''
		,@strPermission	VARCHAR(MAX) = ''

DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))
DECLARE @tmpPermission TABLE (PermissionName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
select db.name 
from master.sys.databases db
where db.name in   ('bodb02' 
						,'bodb_ACC' 
						,'bodb_Report' 
						,'bodb_Archive' 
						,'bodb_Message' 
						,'bodb_TGRS'
					)
and db.state = 0
and is_read_only = 0

INSERT INTO @tmpPermission (PermissionName)
VALUES ('VIEW DEFINITION'),('SELECT'),('INSERT'),('UPDATE'),('DELETE'),('EXECUTE')

---create database role
begin
	SELECT @strRole = @strRole + ' '
						 + 'USE ' + DBName + ';'
						+ CHAR(13)
						+ 'IF NOT EXISTS (SELECT TOP 1 1 FROM sys.database_principals WHERE	name=''' + @RoleName + ''' and Type = ''R'') '
						+ 'CREATE ROLE ' + @RoleName + ';'
						+ CHAR(13)
	FROM	@tmpAffectedDB

	EXEC (@strRole)
	
	waitfor delay '00:00:01'
END

-- Grant permission to new role
begin

	SELECT @strPermission = @strPermission + ' '
						 + 'USE ' + d.DBName + ' ' + ';'
						 + CHAR(13)
						 + 'GRANT ' + p.PermissionName + ' ON SCHEMA::dbo TO ' + @RoleName + ' ' + ';'
						 + CHAR(13)
	FROM	@tmpAffectedDB d
		CROSS APPLY (
			SELECT PermissionName
			FROM	@tmpPermission
		) p
	EXEC (@strPermission)

end
GO