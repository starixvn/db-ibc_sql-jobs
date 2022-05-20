USE [master]
GO
/*
	spvn\alex.nguyen
	spvn\joseph.pham
	spvn\bruce.bui
	spvn\walter.tran
	spvn\scofield.huynh
	spvn\amanda.luong
	spvn\parsons.nguyen
	spvn\mason.nguyen
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
	VALUES ('spvn\alex.nguyen'), ('spvn\joseph.pham'), ('spvn\bruce.bui')
		,('spvn\walter.tran'), ('spvn\scofield.huynh'), ('spvn\amanda.luong'), ('spvn\parsons.nguyen')
		, ('spvn\mason.nguyen'), ('spvn\howard.nguyen')

SELECT @strLoginName = @strLoginName + 'GRANT ALTER TRACE TO ' + '[' + Name + ']' + CHAR(13)
FROM	@tmpMember

EXEC (@strLoginName)
GO

