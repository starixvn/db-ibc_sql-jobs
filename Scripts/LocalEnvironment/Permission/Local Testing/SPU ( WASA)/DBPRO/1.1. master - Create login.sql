USE [master]
GO
-- Create Login
/*	Windows domain account:
	
*/
IF @@SERVERNAME NOT IN ( 'TESTDBPRO', 'DEVDB061\DEVDBPRO' )
BEGIN
	SELECT 'Wrong server!'
	RETURN
END

DECLARE @strLoginName 	VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\long.luu')
		--, ('spvn\thai.tran')
		, ('spvn\terry.nguyen')
		,('spvn\casey.huynh'), ('spvn\john.ngo')
		, ('spvn\victoria.le')
		, ('spvn\harvey.nguyen')

-- CREATE LOGIN [spvn\nickname] FROM WINDOWS;  
SELECT @strLoginName = @strLoginName 
			+  'CREATE LOGIN [' + t.Name + '] FROM WINDOWS; ' 
			+ CHAR(13)
FROM @tmpMember t
	LEFT JOIN sys.server_principals s
		ON s.name = t.Name
WHERE	s.name IS NULL	


EXEC (@strLoginName)
GO

