USE [master]
GO
-- Create Login

IF @@SERVERNAME  NOT IN ( 'DB233' , 'TESTDBCUST', 'DB-60\DEVDBCUST')
BEGIN
	SELECT 'Must be run on DB233/TESTDBCUST' AS 'Error'

	RETURN
END

DECLARE @strLoginName 	VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\johnson.nguyen'), ('spvn\elodie.ho'),('spvn\winfred.pham'),('spvn\tacy.nguyen'), ('spvn\eden.dang')
		
		, ('spvn\sol.le'), ('spvn\bobby.nguyen'), ('spvn\tina.vo')
		
		, ('spvn\helen.do'),('spvn\july.nguyen'), ('spvn\kathy.nguyen'),('spvn\louisa.vo'),('spvn\max.tran'),('spvn\Victoria.le')
		
		, ('spvn\sophia.nguyen'),('spvn\evan.trinh'),('spvn\danny.nguyen'), ('spvn\malcolm.huynh'),('spvn\eddie.nguyen')

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

