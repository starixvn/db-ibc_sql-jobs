USE [master]
GO
-- Create Login
/*
	spvn\alex.nguyen
	spvn\joseph.pham
	spvn\bruce.bui
	spvn\walter.tran
	spvn\scofield.huynh
	spvn\amanda.luong
	spvn\parsons.nguyen
	spvn\hubert.duong
	spvn\mason.nguyen
*/
IF @@SERVERNAME <> 'DB231'
BEGIN
	SELECT 'Must be run on DB231' AS 'Error'

	RETURN
END
DECLARE @strLoginName 	VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES
		 ('spvn\alex.nguyen'), ('spvn\joseph.pham'), ('spvn\bruce.bui')
		,('spvn\walter.tran'), ('spvn\scofield.huynh'), ('spvn\amanda.luong'), ('spvn\parsons.nguyen')
		, ('spvn\hubert.duong'), ('spvn\mason.nguyen'), ('spvn\howard.nguyen'), ('spvn\hogan.pham')
		

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
