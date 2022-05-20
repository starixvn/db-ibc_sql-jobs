USE [master]
GO
/*	Windows domain account:
		spvn\anders.le
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
	VALUES ('spvn\anders.le')

SELECT @strLoginName = @strLoginName + 'GRANT ALTER TRACE TO ' + '[' + Name + ']' + CHAR(13)
FROM	@tmpMember

EXEC (@strLoginName)
GO

