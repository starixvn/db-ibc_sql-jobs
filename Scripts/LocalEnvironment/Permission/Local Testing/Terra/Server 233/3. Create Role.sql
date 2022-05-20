/*
	For Rome team:
	Affected DB:
		CustDB
		IPDB
		NAP_UserControl
		bodb_CustomerLog
*/
-- Create Role
IF @@SERVERNAME NOT IN (  'DB-60\DevDBcust', 'TESTDBCUST' )
BEGIN
	SELECT 'Must be run on  DevDBcust or TESTDBCUST' AS 'Error'

	RETURN
END

DECLARE @RoleName VARCHAR(50) = 'db_Terra'
		,@strRole	VARCHAR(MAX) = ''

DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
		VALUES ('CustDB'),('IPDB'),('NAP_UserControl'),('bodb_CustomerLog'), ('bodb_Licensee')

SELECT @strRole = @strRole + ' '
					 + 'USE ' + DBName + ';'
					+ CHAR(13)
					+ 'IF NOT EXISTS (SELECT TOP 1 1 FROM sys.database_principals WHERE	name=''' + @RoleName + ''' and Type = ''R'') '
					+ 'CREATE ROLE ' + @RoleName + ';'
					+ CHAR(13)
FROM	@tmpAffectedDB

EXEC (@strRole)
GO
--------------------------------------------------------------------------------------

IF @@SERVERNAME NOT IN (  'DB-60\DevDBcust', 'TESTDBCUST' )
BEGIN
	SELECT 'Must be run on DevDBcust or TESTDBCUST' AS 'Error'

	RETURN
END

-- Grant permission to new role
DECLARE @RoleName VARCHAR(50) = 'db_Terra'
		,@strPermission	VARCHAR(MAX) = ''
		,@strAlterSP	VARCHAR(MAX) = ''

DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))
DECLARE @tmpPermission TABLE (PermissionName VARCHAR(50))
DECLARE @tmpSPName TABLE (SPName VARCHAR(200), DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
	VALUES ('CustDB'),('IPDB'),('NAP_UserControl'),('bodb_CustomerLog'), ('bodb_Licensee')

INSERT INTO @tmpPermission (PermissionName)
	VALUES ('VIEW DEFINITION'),('SELECT'),('INSERT'),('UPDATE'),('DELETE'),('EXECUTE'), ('ALTER')

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

INSERT INTO @tmpSPName (SPName,DBName)
	VALUES ('Acc_DynamicCustSetting3rd_09','CustDB'),('Acc_DynamicCustomerInfo_09','CustDB')

SELECT @strAlterSP = @strAlterSP + ' '
					 + 'USE ' + s.DBName + ' ' + ';'
					 + CHAR(13)
					 + 'GRANT ALTER ON ' + s.SPName + ' TO ' + @RoleName + ' ' + ';'
					 + CHAR(13)
FROM	@tmpSPName s
	
SELECT @strAlterSP
--EXEC (@strAlterSP)

USE CustDB
GRANT ALTER ON Acc_DynamicCustSetting3rd_09 TO db_Terra
GO

 USE CustDB ;
GRANT ALTER ON Acc_DynamicCustSetting3rd_09 TO db_Terra ;
 USE CustDB ;
GRANT ALTER ON Acc_DynamicCustomerInfo_09 TO db_Terra ;
