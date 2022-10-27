USE [master]
GO
/*	Windows domain account:
	SPVN\jacob.phan
	SPVN\robert.tran
	SPVN\kaden.trinh
	SPVN\leo.vo
	SPVN\franklin.nguyen
	SPVN\alan.nguyen
	SPVN\raymond.le
	SPVN\charles.nguyen
*/

-- Grant permisison Profiler for login

IF @@SERVERNAME NOT in ('DB215','TESTDB053','DB-61\DevDB053')
BEGIN
	SELECT 'Must be run on DB215' AS 'Error'

	RETURN
END

DECLARE @strLoginName VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('SPVN\jacob.phan')	
			,('SPVN\robert.tran')	
			,('SPVN\kaden.trinh')	
			,('SPVN\franklin.nguyen')	
			,('SPVN\charles.nguyen')	
			,('SPVN\raymond.le')	
			,('SPVN\zane.trinh')  
			,('SPVN\johnny.thai')	
			,('SPVN\luca.duong')		
			,('SPVN\levi.vu')
			,('SPVN\luca.duong')

SELECT @strLoginName = @strLoginName + 'GRANT ALTER TRACE TO ' + '[' + Name + ']' + CHAR(13)
FROM	@tmpMember

EXEC (@strLoginName)
GO

