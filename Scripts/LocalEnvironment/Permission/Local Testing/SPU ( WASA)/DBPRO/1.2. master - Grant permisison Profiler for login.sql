USE [master]
GO
/*	Windows domain account:
	
*/

-- Grant permisison Profiler for login

IF @@SERVERNAME NOT IN ( 'TESTDBPRO', 'DEVDB061\DEVDBPRO' )
BEGIN
	SELECT 'Wrong server!'
	RETURN
END

DECLARE @strLoginName VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\long.luu'), ('spvn\terry.nguyen')
		,('spvn\casey.huynh'), ('spvn\john.ngo'), ('spvn\harvey.nguyen')

SELECT @strLoginName = @strLoginName + 'GRANT ALTER TRACE TO ' + '[' + Name + ']' + CHAR(13)
FROM	@tmpMember

EXEC (@strLoginName)
GO

