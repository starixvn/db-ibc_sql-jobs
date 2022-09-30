 
-- Create User
IF @@SERVERNAME NOT IN ('DB-61\DevDB053','TESTDB053')
BEGIN
	SELECT 'Must be run on DevDB053 or TESTDB053' AS 'Error'
	RETURN
END

DECLARE @strUser	VARCHAR(MAX) = ''
DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
		VALUES  ('bodb_3rdProduct')
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
				,('bk')
				,('bodb_PlaytechCS')
				, ('ON_USER')
				,('bodb_Maintenance')
				,('bodb_Chatbot')


DECLARE @tmpMember TABLE (Name VARCHAR(50))

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
			,('spvn\joyce.pham')
			--,('SPVN\rita.bui')
			--,('SPVN\bob.duong')
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
IF @@SERVERNAME NOT IN ('DB-61\DevDB053','TESTDB053')
BEGIN
	SELECT 'Must be run on DevDB053 or TESTDB053' AS 'Error'
	RETURN
END

DECLARE @strUser VARCHAR(MAX) = ''
		,@RoleName VARCHAR(50) = 'db_Terra'
		,@LeaderRoleName VARCHAR(50) = 'db_owner'
		,@Leader VARCHAR(50) = 'spvn\jerry.tran'

DECLARE @tmpMember TABLE (Name VARCHAR(50), RoleName VARCHAR(50))
DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
		VALUES  ('bodb_3rdProduct')
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
				,('bk')
				,('bodb_PlaytechCS')
				, ('ON_USER')
				,('bodb_Maintenance')
				,('bodb_Chatbot')


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
			,('spvn\joyce.pham')
			--,('SPVN\rita.bui')
			--,('SPVN\bob.duong')

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
WHERE 1 = CASE WHEN t.Name = 'SPVN\bill.nguyen' AND d.DBName = 'bodb_Chatbot' THEN 1
				WHEN d.DBName  <> 'bodb_Chatbot' THEN 1
				ELSE 0
				END

EXEC (@strUser)

GO