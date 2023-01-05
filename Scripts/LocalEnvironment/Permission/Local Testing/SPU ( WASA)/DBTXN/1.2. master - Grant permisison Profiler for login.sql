USE [master]
GO
/*	Windows domain account:
	
*/

-- Grant permisison Profiler for login
IF @@SERVERNAME NOT LIKE '%DBTRANS' AND @@SERVERNAME NOT LIKE  '%SiteDB%'
BEGIN
	SELECT 'Wrong server' AS 'Error'
	RETURN
END

DECLARE @strLoginName VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\long.luu'), ('spvn\terry.nguyen')
		,('spvn\casey.huynh'), ('spvn\john.ngo'), ('spvn\harvey.nguyen')
		, ('spvn\victoria.le')

SELECT @strLoginName = @strLoginName + 'GRANT ALTER TRACE TO ' + '[' + Name + ']' + CHAR(13)
FROM	@tmpMember

EXEC (@strLoginName)
GO

