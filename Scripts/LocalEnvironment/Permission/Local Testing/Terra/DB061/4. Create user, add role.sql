 
-- Create User
IF @@SERVERNAME NOT IN ( 'DEVDB061' , 'TESTDB061' )
BEGIN
	SELECT 'Wrong server' AS 'Error'
	RETURN
END

DECLARE @strUser	VARCHAR(MAX) = ''
		,@RoleName VARCHAR(50) = 'db_Terra'
		,@LeaderRoleName VARCHAR(50) = 'db_owner'
		,@Leader VARCHAR(50) = 'spvn\jerry.tran'

DECLARE @tmpMember TABLE (Name VARCHAR(50), RoleName VARCHAR(50))
DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
select db.name  from master.sys.databases db 
where is_read_only = 0 
	and state = 0
	and db.name in ( 'bodb02'
					,'bodb_ACC'
					,'bodb_Report'
					,'bodb_Archive'
					,'bodb_Message'
					,'bodb_TGRS'
				)

INSERT INTO @tmpMember (Name) 
	VALUES   ('SPVN\jerry.tran')
			,('SPVN\andrew.vu')
			,('SPVN\susan.le')
			,('SPVN\martin.tran')
			,('SPVN\shane.nguyen')
			,('SPVN\rocky.ping')
			,('SPVN\felix.nguyen')
			,('SPVN\lita.tang')
			,('SPVN\benji.duong')
			,('SPVN\henry.nguyen')
			,('SPVN\lucy.ho')
			,('SPVN\bill.nguyen')
			,('SPVN\joyce.pham')
UPDATE @tmpMember
	SET RoleName = CASE WHEN Name = @Leader THEN @LeaderRoleName ELSE @RoleName	END

---create user database
begin
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
end
 
---add use to database role
begin
	set @strUser = ''
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
end
go