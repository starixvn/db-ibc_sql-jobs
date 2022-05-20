USE [master]
GO
/*	Windows domain account:
	spvn\rocky.ping
	spvn\andrew.vu
	spvn\jerry.tran
	spvn\bob.duong
	spvn\martin.tran
	spvn\nancy.dao
	spvn\shane.nguyen
	spvn\kingsley.nguyen
	spvn\rita.bui
	spvn\felix.nguyen
	spvn\lita.tang
*/

-- Grant permisison Profiler for login

IF @@SERVERNAME <> 'DB231\SQLSERVER2008R2'
BEGIN
	SELECT 'Must be run on DB231\SQLSERVER2008R2' AS 'Error'

	RETURN
END

DECLARE @strLoginName VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\rocky.ping'), ('spvn\andrew.vu'), ('spvn\jerry.tran')
		,('spvn\bob.duong'), ('spvn\martin.tran'), ('spvn\nancy.dao')
		,('spvn\shane.nguyen'), ('spvn\kingsley.nguyen')
		,('spvn\rita.bui'), ('spvn\felix.nguyen'), ('spvn\lita.tang')

SELECT @strLoginName = @strLoginName + 'GRANT ALTER TRACE TO ' + '[' + Name + ']' + CHAR(13)
FROM	@tmpMember

EXEC (@strLoginName)
GO

