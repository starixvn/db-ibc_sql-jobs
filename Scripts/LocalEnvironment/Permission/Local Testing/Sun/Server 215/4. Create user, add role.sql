


/*	Note: DB215.bodb_CustomerLog is located on TESTDB055.bodb_CustomerLog	*/


-- Create User
IF @@SERVERNAME NOT IN ( 'DB215' , 'DB-61\DevDB053' , 'TESTDB053' )
BEGIN
	SELECT 'Must be run on DB215 or DevDB053 or TESTDB053' AS 'Error'
	RETURN
END

DECLARE @strUser	VARCHAR(MAX) = ''
DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
	VALUES  ('bodb_3rdProduct'),
			('bodb_licensee'),
			('Affiliate_12BET'),
			('Affiliate_Athena000'),
			--('bodb_CustomerLog'), /*	Note: DB215.bodb_CustomerLog is located on TESTDB055.bodb_CustomerLog	*/
			('bodb_oddsfeed'),
			('Affiliate_Macaubet'),
			('Affiliate_spondemo'),
			('bodb_LicenseeReport'),
			('bodb02'),
			('bodb_OIC'),
			('bodb_report'),
			('bodb_PlaytechCS'),
			('bodb_N88'),
			('bodb_account'),
			('Affiliate_N8G'),
			('Affiliate_N8B'),
			('Affiliate_N88'),
			('bodb_N88_Archive'),
			('bodb_CRM')

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\william.nguyen'),
	('spvn\maia.le'),
	('spvn\selina.dinh'),
	('spvn\lionel.nguyen'),
	('spvn\Winston.chau'),
	('spvn\ruby.nguyen'),
	('spvn\corbin.hoang'),
	--('spvn\kaylin.truong'),
	('spvn\jenny.phan'),
	('spvn\harmony.huynh'),
	('spvn\laura.nguyen'),
	('SPVN\nina.nguyen'),
	('SPVN\roshan.nguyen'),
	('SPVN\victor.nguyen')

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
	) t

EXEC (@strUser)
GO

-------------------------------------------
-------------------------------------------
-- Add Role for member

IF @@SERVERNAME NOT IN ( 'DB215' , 'DB-61\DevDB053' , 'TESTDB053' )
BEGIN
	SELECT 'Must be run on DB215 or DevDB053 or TESTDB053' AS 'Error'
	RETURN
END
DECLARE @strUser VARCHAR(MAX) = ''
		,@RoleName VARCHAR(50) = 'db_Sun'
		,@LeaderRoleName VARCHAR(50) = 'db_owner'
		,@Leader VARCHAR(50) = 'spvn\william.nguyen'

DECLARE @tmpMember TABLE (Name VARCHAR(50), RoleName VARCHAR(50))
DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
	VALUES  ('bodb_3rdProduct'),
			('bodb_licensee'),
			('Affiliate_12BET'),
			('Affiliate_Athena000'),
			--('bodb_CustomerLog'),/*	Note: DB215.bodb_CustomerLog is located on TESTDB055.bodb_CustomerLog	*/
			('bodb_oddsfeed'),
			('Affiliate_Macaubet'),
			('Affiliate_spondemo'),
			('bodb_LicenseeReport'),
			('bodb02'),
			('bodb_OIC'),
			('bodb_report'),
			('bodb_PlaytechCS'),
			('bodb_N88'),
			('bodb_account'),
			('Affiliate_N8G'),
			('Affiliate_N8B'),
			('Affiliate_N88'),
			('bodb_N88_Archive'),
			('bodb_CRM')

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\william.nguyen'),
	('spvn\maia.le'),
	('spvn\selina.dinh'),
	('spvn\lionel.nguyen'),
	('spvn\Winston.chau'),
	('spvn\ruby.nguyen'),
	('spvn\corbin.hoang'),
	--('spvn\kaylin.truong'),
	('spvn\jenny.phan'),
	('spvn\harmony.huynh'),
	('spvn\laura.nguyen'),
	('SPVN\nina.nguyen'),
	('SPVN\roshan.nguyen'),
	('SPVN\victor.nguyen')

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