USE [master]
GO
/*	Windows domain account:
	
*/

-- Grant permisison Profiler for login

IF @@SERVERNAME NOT IN ( 'TESTDB055', 'DB-61\DEVDB055')
BEGIN
	SELECT 'Wrong Server' AS 'Error'

	RETURN
END

DECLARE @strLoginName VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
		VALUES ('spvn\long.luu') 
		, ('spvn\terry.nguyen')
		,('spvn\casey.huynh')
		, ('spvn\john.ngo')
		, ('spvn\victoria.le')
		, ('spvn\jonathan.doan')
		,('spvn\Irena.vo')
		,('spvn\Adam.tran')

SELECT @strLoginName = @strLoginName + 'GRANT ALTER TRACE TO ' + '[' + Name + ']' + CHAR(13)
FROM	@tmpMember

EXEC (@strLoginName)
GO

