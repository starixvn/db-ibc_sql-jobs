USE [master]
GO
/*	Windows domain account:
	spvn\quinn.vo
	spvn\tim.trinh
	spvn\scofield.huynh
*/

-- Grant permisison Profiler for login

IF @@SERVERNAME NOT IN ( 'DB206' , 'TESTDBTRANS' )
BEGIN
	SELECT 'Must be run on DB206' AS 'Error'

	RETURN
END

DECLARE @strLoginName VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\quinn.vo'), ('spvn\tim.trinh'), ('spvn\scofield.huynh'), ('spvn\oliver.dang'), ('spvn\drake.doi')

SELECT @strLoginName = @strLoginName + 'GRANT ALTER TRACE TO ' + '[' + Name + ']' + CHAR(13)
FROM	@tmpMember

EXEC (@strLoginName)
GO

