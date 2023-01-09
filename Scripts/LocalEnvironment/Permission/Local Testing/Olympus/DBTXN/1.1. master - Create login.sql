USE [master]
GO
 --	select @@servername
IF @@SERVERNAME NOT LIKE '%DBTRANS' AND @@SERVERNAME NOT LIKE  '%SiteDB%'
BEGIN
	SELECT 'Wrong server' AS 'Error'
	RETURN
END

DECLARE @strLoginName 	VARCHAR(MAX) = ''
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
			,('SPVN\luca.duong')
			,('SPVN\levi.vu')
			,('SPVN\agnes.tran')

SELECT @strLoginName = @strLoginName 
			+  'CREATE LOGIN [' + t.Name + '] FROM WINDOWS; ' 
			+ CHAR(13)
FROM @tmpMember t
	LEFT JOIN sys.server_principals s
		ON s.name = t.Name
WHERE	s.name IS NULL	


EXEC (@strLoginName)
GO

