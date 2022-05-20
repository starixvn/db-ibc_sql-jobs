USE [master]
GO
/*	Windows domain account:
	
*/

-- Grant permisison Profiler for login

IF @@SERVERNAME <> 'DB230'
BEGIN
	SELECT 'Must be run on DB230' AS 'Error'

	RETURN
END

DECLARE @strLoginName VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\long.luu'), ('spvn\thai.tran'), ('spvn\terry.nguyen')
		,('spvn\casey.huynh'), ('spvn\john.ngo'), ('spvn\simon.huynh'), ('spvn\harvey.nguyen')

SELECT @strLoginName = @strLoginName + 'GRANT ALTER TRACE TO ' + '[' + Name + ']' + CHAR(13)
FROM	@tmpMember

EXEC (@strLoginName)
GO

