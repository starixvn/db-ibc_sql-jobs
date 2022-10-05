
-- Create User
IF @@SERVERNAME NOT IN ( 'DB215' , 'DB-61\DevDB053' , 'TESTDB053' )
BEGIN
	SELECT 'Must be run on DB215 or TESTDB053' AS 'Error'

	RETURN
END

DECLARE @strUser	VARCHAR(MAX) = ''
DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
	VALUES 
		-- ('bodb_CustomerLog')
			('bodb_Notification')
			,('bodb_3rdProduct')
			,('bodb_Account')
			,('bodb_archive')
			,('bodb_Customer')
			,('bodb_dwrs')
			,('bodb_LCC')
			,('bodb_licensee')
			,('bodb_LicenseeReport')
			,('bodb_LicenseeReportArchive')
			,('bodb_MMS')
			,('bodb_NAP')
			,('bodb_Staging')
			,('bodb02')
			,('bodb_OIC')
			,('bodb_report')
			,('bodb_RMS')
			,('bodb_PlaytechCS')
			,('bodb_N88')
			,('bodb_Summary')
			,('bodb_ODS')
			,('bodb_Age')
			,('bodb_OLAP')
			,('bodb_CRM')
			,('bodb_adhoc')

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\kaka.huynh'),
		('spvn\dora.le'),
		('spvn\jane.dinh'),
		('spvn\megan.dinh'),
		('spvn\tommy.nguyen'),
		('spvn\Neil.dao'),
		('spvn\harley.nguyen'),
		('spvn\Mike.vu'),
		('spvn\kenny.ho')
		,('spvn\ariana.nguyen')
		,('spvn\benjamin.nguyen')

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
	SELECT 'Must be run on DB215 or TESTDB053' AS 'Error'

	RETURN
END
DECLARE @strUser VARCHAR(MAX) = ''
		,@RoleName VARCHAR(50) = 'db_Iris'
		,@LeaderRoleName VARCHAR(50) = 'db_owner'
		,@Leader VARCHAR(50) = 'spvn\kaka.huynh'

DECLARE @tmpMember TABLE (Name VARCHAR(50), RoleName VARCHAR(50))
DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
	VALUES  
		-- ('bodb_CustomerLog')
			('bodb_Notification')
			,('bodb_3rdProduct')
			,('bodb_Account')
			,('bodb_archive')
			,('bodb_Customer')
			,('bodb_dwrs')
			,('bodb_LCC')
			,('bodb_licensee')
			,('bodb_LicenseeReport')
			,('bodb_LicenseeReportArchive')
			,('bodb_MMS')
			,('bodb_NAP')
			,('bodb_Staging')
			,('bodb02')
			,('bodb_OIC')
			,('bodb_report')
			,('bodb_RMS')
			,('bodb_PlaytechCS')
			,('bodb_N88')
			,('bodb_Summary')
			,('bodb_ODS')
		 	,('bodb_Age')
			,('bodb_OLAP')
			,('bodb_CRM')
			,('bodb_adhoc')

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\kaka.huynh'),
		 ('spvn\dora.le'),
		('spvn\jane.dinh'),
		('spvn\megan.dinh'),
		('spvn\tommy.nguyen'),
		('spvn\Neil.dao'),
		('spvn\harley.nguyen'),
		('spvn\Mike.vu'),
		('spvn\kenny.ho')
		,('spvn\ariana.nguyen')
		,('spvn\benjamin.nguyen')

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