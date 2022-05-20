USE [master]
GO
-- Create Login
/*	Windows domain account:
	spvn\rocky.ping
	spvn\andrew.vu
	spvn\jerry.tran
	spvn\bob.duong
	spvn\martin.tran
	spvn\nancy.dao
	spvn\shane.nguyen
	spvn\kingsley.nguyen
	spvn\rita.bui
	spvn\felix.nguyen
	spvn\lita.tang

*/
select @@SERVERNAME
IF @@SERVERNAME <> 'DB-61\DEVDB053'
BEGIN
	SELECT 'Must be run on DB-61\DEVDB053' AS 'Error'

	RETURN
END
DECLARE @strLoginName 	VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\rocky.ping'), ('spvn\andrew.vu'), ('spvn\jerry.tran')
		,('spvn\bob.duong'), ('spvn\martin.tran'), ('spvn\nancy.dao')
		,('spvn\shane.nguyen')
		--, ('spvn\kingsley.nguyen')
		,('spvn\rita.bui'), ('spvn\felix.nguyen'), ('spvn\lita.tang')
		,('spvn\Henry.Nguyen'), ('spvn\Lucy.Ho'),('spvn\benji.duong')
		,('spvn\Bill.Nguyen')

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

