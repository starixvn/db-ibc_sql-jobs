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
*/
-- Grant permisison Profiler for login
IF @@SERVERNAME NOT IN ( 'DB233\SQLSERVER2008R2' ,'TESTDB055' )
BEGIN
	SELECT 'Must be run on DB233\SQLSERVER2008R2' AS 'Error'

	RETURN
END
DECLARE @strLoginName VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\alex.nguyen'), ('spvn\joseph.pham'), ('spvn\bruce.bui')
		,('spvn\walter.tran'), ('spvn\scofield.huynh'), ('spvn\amanda.luong'), ('spvn\parsons.nguyen')

SELECT @strLoginName = @strLoginName + 'GRANT ALTER TRACE TO ' + '[' + Name + ']' + CHAR(13)
FROM	@tmpMember

EXEC (@strLoginName)
GO

