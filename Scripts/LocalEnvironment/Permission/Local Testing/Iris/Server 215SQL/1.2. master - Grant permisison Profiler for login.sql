USE [master]
GO
/*	Windows domain account:
	
*/

-- Grant permisison Profiler for login

IF @@SERVERNAME <> 'DB215\SQLSERVER2008R2'
BEGIN
	SELECT 'Must be run on DB215\SQLSERVER2008R2' AS 'Error'

	RETURN
END

DECLARE @strLoginName VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\kaka.huynh')
		,('spvn\dora.le'), ('spvn\megan.dinh')
		,('spvn\tommy.nguyen'), ('spvn\Neil.dao')
		,('spvn\jane.dinh'), ('spvn\harley.nguyen'), ('spvn\dory.vu')
		,('spvn\elio.nguyen')

SELECT @strLoginName = @strLoginName + 'GRANT ALTER TRACE TO ' + '[' + Name + ']' + CHAR(13)
FROM	@tmpMember

EXEC (@strLoginName)
GO

