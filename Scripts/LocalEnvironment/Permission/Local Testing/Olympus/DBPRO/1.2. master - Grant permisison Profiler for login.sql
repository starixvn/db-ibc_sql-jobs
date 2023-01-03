USE [master]
GO
 
IF @@SERVERNAME NOT IN ( 'TESTDBPRO', 'DEVDB061\DEVDBPRO' )
BEGIN
	SELECT 'Wrong server' AS 'Error'
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
			,('SPVN\carlos.nguyen')	
			,('SPVN\mira.nguyen')	
			,('SPVN\liam.pham')	
			,('SPVN\johnny.thai')
			,('SPVN\levi.vu')
			,('SPVN\luca.duong')

SELECT @strLoginName = @strLoginName + 'GRANT ALTER TRACE TO ' + '[' + Name + ']' + CHAR(13)
FROM	@tmpMember

EXEC (@strLoginName)
GO

