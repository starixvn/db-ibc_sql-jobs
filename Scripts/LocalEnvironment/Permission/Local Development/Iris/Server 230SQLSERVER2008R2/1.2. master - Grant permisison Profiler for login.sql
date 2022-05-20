USE [master]
GO
/*	Windows domain account:
	
*/

-- Grant permisison Profiler for login

IF @@SERVERNAME <> 'DB230\SQLSERVER2008R2'
BEGIN
	SELECT 'Must be run on DB230\SQLSERVER2008R2' AS 'Error'

	RETURN
END

DECLARE @strLoginName VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\kaka.huynh'), ('spvn\rossa.nguyen'), ('spvn\justin.doan')
		,('spvn\dora.le'), ('spvn\lex.khuat'), ('spvn\megan.dinh')
		,('spvn\tommy.nguyen'), ('spvn\lana.nguyen')
		,('spvn\jane.dinh')

SELECT @strLoginName = @strLoginName + 'GRANT ALTER TRACE TO ' + '[' + Name + ']' + CHAR(13)
FROM	@tmpMember

EXEC (@strLoginName)
GO

