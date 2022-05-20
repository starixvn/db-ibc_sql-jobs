USE [master]
GO
/*	Windows domain account:
	spvn\quinn.vo
	spvn\tim.trinh
	spvn\scofield.huynh
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
	VALUES ('spvn\quinn.vo'), ('spvn\tim.trinh'), ('spvn\scofield.huynh'), ('spvn\drake.doi'), ('spvn\oliver.dang')

SELECT @strLoginName = @strLoginName + 'GRANT ALTER TRACE TO ' + '[' + Name + ']' + CHAR(13)
FROM	@tmpMember

EXEC (@strLoginName)
GO

