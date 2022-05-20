USE [master]
GO
/*	Windows domain account:
	SPVN\jacob.phan
	SPVN\robert.tran
	SPVN\kaden.trinh
	SPVN\leo.vo
	SPVN\franklin.nguyen
	SPVN\alan.nguyen
*/

-- Grant permisison Profiler for login

IF @@SERVERNAME NOT IN ( 'DB233\SQLSERVER2008R2' ,'TESTDB055' )
BEGIN
	SELECT 'Must be run on DB233\SQLSERVER2008R2' AS 'Error'

	RETURN
END

DECLARE @strLoginName VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('SPVN\jacob.phan'), ('SPVN\robert.tran'), ('SPVN\kaden.trinh')
		,('SPVN\leo.vo'), ('SPVN\franklin.nguyen')--, ('SPVN\alan.nguyen')
		,('SPVN\zane.trinh')

SELECT @strLoginName = @strLoginName + 'GRANT ALTER TRACE TO ' + '[' + Name + ']' + CHAR(13)
FROM	@tmpMember

EXEC (@strLoginName)
GO

