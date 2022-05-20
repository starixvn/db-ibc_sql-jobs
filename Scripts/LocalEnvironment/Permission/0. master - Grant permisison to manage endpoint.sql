USE [master]
GO
/*	Windows domain account:
		spvn\johnson.nguyen
*/

-- Grant permisison Profiler for login

--IF @@SERVERNAME <> 'DB206'
--BEGIN
--	SELECT 'Must be run on DB206' AS 'Error'

--	RETURN
--END

--EXECUTE AS LOGIN = 'DB206\SQL'

DECLARE @strLoginName VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\johnson.nguyen')

SELECT @strLoginName = @strLoginName + 'GRANT ALTER ANY ENDPOINT TO ' + '[' + Name + ']' + CHAR(13)
FROM	@tmpMember

EXEC (@strLoginName)

SET @strLoginName = ''

SELECT @strLoginName = @strLoginName + 'GRANT VIEW ANY DEFINITION TO ' + '[' + Name + ']' + CHAR(13)
FROM	@tmpMember

EXEC (@strLoginName)

REVERT
GO

