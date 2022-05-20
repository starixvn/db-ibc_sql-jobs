USE [master]
GO
/*	Windows domain account:
	spvn\jacob.phan
	spvn\robert.tran
	spvn\kaden.trinh
	spvn\leo.vo
	spvn\franklin.nguyen
	spvn\alan.nguyen
	spvn\kane.le
	spvn\charles.nguyen
	spvn\tyler.dang
	spvn\carlos.nguyen
*/

-- Grant permisison Profiler for login

IF @@SERVERNAME <> 'DB232'
BEGIN
	SELECT 'Must be run on DB232' AS 'Error'

	RETURN
END

DECLARE @strLoginName VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\jacob.phan'), ('spvn\robert.tran'), ('spvn\kaden.trinh')
		,('spvn\leo.vo'), ('spvn\franklin.nguyen'), ('spvn\alan.nguyen')
		, ('spvn\kane.le'), ('spvn\charles.nguyen'), ('spvn\raymond.le')
		, ('spvn\tyler.dang'), ('spvn\carlos.nguyen')

SELECT @strLoginName = @strLoginName + 'GRANT ALTER TRACE TO ' + '[' + Name + ']' + CHAR(13)
FROM	@tmpMember

EXEC (@strLoginName)
GO

