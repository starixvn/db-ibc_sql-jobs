/*
	

	Windows domain account:
		
*/
-- Create User
IF @@SERVERNAME NOT IN ( 'TESTDB055', 'DB-61\DEVDB055')
BEGIN
	SELECT 'Wrong Server' AS 'Error'

	RETURN
END

DECLARE @strUser	VARCHAR(MAX) = ''
		,@RoleName VARCHAR(50) = 'db_SPU'
		,@LeaderRoleName VARCHAR(50) = 'db_owner'
		,@Leader VARCHAR(50) 

DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
	VALUES ('LogCDB')
	
DECLARE @tmpMember TABLE (Name VARCHAR(50), RoleName VARCHAR(50))

INSERT INTO @tmpMember (Name) 
		VALUES ('spvn\long.luu') 
		, ('spvn\terry.nguyen')
		,('spvn\casey.huynh')
		, ('spvn\john.ngo')
		, ('spvn\victoria.le')
		, ('spvn\jonathan.doan')
		,('spvn\Irena.vo')
		,('spvn\Adam.tran')

/*
	USE DBName
	GO 
	CREATE USER vnXXX FOR LOGIN vnXXX WITH DEFAULT_SCHEMA=[dbo] 
	GO

	-- Delete user: EXEC sp_dropuser 'spvn\xxx.xxx';
*/

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
		--	LEFT JOIN sys.database_principals s
		--		ON t.Name = s.name
		--WHERE	s.name IS NULL
	) t
	
	

EXEC (@strUser)
waitfor delay '00:00:01'

-------------------------------------------
-------------------------------------------
-- Add Role for member

set @strUser  = ''
  
UPDATE @tmpMember
	SET RoleName = CASE WHEN Name = @Leader THEN @LeaderRoleName ELSE @RoleName	END
/*
	USE DBName
	GO
	EXEC sp_AddRoleMember 'db_xxx', 'vnxxx'
	GO
*/
SELECT	@strUser = @strUser
					+ 'USE ' + d.DBName + ';'
					+ CHAR(13)
					+ 'EXEC sp_AddRoleMember ''' + t.RoleName + ''',''' + t.Name + ''' ' + ';'
					+ CHAR(13)
FROM	@tmpAffectedDB d
	CROSS APPLY (
		SELECT Name, RoleName
		FROM @tmpMember 
	)t

EXEC (@strUser)

GO