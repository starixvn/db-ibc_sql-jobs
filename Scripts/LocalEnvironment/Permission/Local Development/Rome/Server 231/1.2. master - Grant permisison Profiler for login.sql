USE [master]
GO
/*	Windows domain account:
	spvn\ethan.nguyen
	spvn\andy.nguyen
	spvn\david.tran
	spvn\phillip.truong
	spvn\louis.nguyen
	spvn\kan.nguyen
	spvn\razor.nguyen
	spvn\alvin.nguyen
*/

-- Grant permisison Profiler for login

IF @@SERVERNAME <> 'DB231'
BEGIN
	SELECT 'Must be run on DB231' AS 'Error'

	RETURN
END

DECLARE @strLoginName VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\ethan.nguyen'), ('spvn\andy.nguyen'), ('spvn\david.tran')
		,('spvn\phillip.truong'), ('spvn\louis.nguyen'), ('spvn\kan.nguyen')
		,('spvn\razor.nguyen'), ('spvn\alvin.nguyen')

SELECT @strLoginName = @strLoginName + 'GRANT ALTER TRACE TO ' + '[' + Name + ']' + CHAR(13)
FROM	@tmpMember

EXEC (@strLoginName)
GO

