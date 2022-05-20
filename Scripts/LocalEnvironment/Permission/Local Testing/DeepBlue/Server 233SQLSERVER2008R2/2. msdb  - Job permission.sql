-- Create User
USE [msdb]
GO
/*	Windows domain account:
		spvn\johnson.nguyen
		spvn\sophia.nguyen
		spvn\jamie.dao
		spvn\elodie.ho
		spvn\kathy.nguyen
		spvn\winfred.pham
		spvn\helen.do
		spvn\percy.nguyen
		spvn\sol.le
		spvn\eden.dang
		spvn\bobby.nguyen
		spvn\tina.vo
*/

IF @@SERVERNAME NOT IN ( 'DB233\SQLSERVER2008R2' , 'TESTDB055' )
BEGIN
	SELECT 'Must be run on DB233\SQLSERVER2008R2 or TESTDB055' AS 'Error'

	RETURN
END

DECLARE @strUser VARCHAR(MAX) = ''
DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\johnson.nguyen'), ('spvn\sophia.nguyen')
		--,('spvn\jamie.dao')
		, ('spvn\elodie.ho'), ('spvn\kathy.nguyen')
		,('spvn\winfred.pham'), ('spvn\helen.do'), ('spvn\percy.nguyen')
		, ('spvn\sol.le'), ('spvn\eden.dang'), ('spvn\bobby.nguyen'), ('spvn\tina.vo')
		,('spvn\july.nguyen')
		,('spvn\evan.trinh')
		,('spvn\danny.nguyen')
		, ('spvn\malcolm.huynh')
		,('spvn\louisa.vo')
		,('spvn\max.tran')

SELECT	@strUser = @strUser 
			+ 'CREATE USER ' + '[' + t.Name + ']' + ' FOR LOGIN ' + '[' + t.Name + ']' + ' WITH DEFAULT_SCHEMA=[dbo]; '
			+ CHAR(13)
			+ 'ALTER USER' + '[' + t.Name + ']' + ' WITH DEFAULT_SCHEMA=[dbo]' + ';'
			+ CHAR(13)
FROM	@tmpMember t
	LEFT JOIN sys.database_principals s
		ON t.Name = s.name
WHERE	s.name IS NULL

EXEC (@strUser)
GO


-- Add Role
USE [msdb]
GO

IF @@SERVERNAME NOT IN ( 'DB233\SQLSERVER2008R2' , 'TESTDB055' )
BEGIN
	SELECT 'Must be run on DB233\SQLSERVER2008R2 or TESTDB055' AS 'Error'

	RETURN
END

DECLARE @strUser VARCHAR(MAX) = ''
DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\johnson.nguyen'), ('spvn\sophia.nguyen')
		--,('spvn\jamie.dao')
		, ('spvn\elodie.ho'), ('spvn\kathy.nguyen')
		,('spvn\winfred.pham'), ('spvn\helen.do'), ('spvn\percy.nguyen')
		, ('spvn\sol.le'), ('spvn\eden.dang'), ('spvn\bobby.nguyen'), ('spvn\tina.vo')
		,('spvn\july.nguyen')
		,('spvn\evan.trinh')
		,('spvn\danny.nguyen')
		, ('spvn\malcolm.huynh')
		,('spvn\louisa.vo')
		,('spvn\max.tran')

SELECT	@strUser = @strUser + 'EXEC sp_AddRoleMember ''SQLAgentOperatorRole''' + ', ''' + t.Name + '''' 
		+ CHAR(13)
FROM	@tmpMember t

EXEC (@strUser)
GO