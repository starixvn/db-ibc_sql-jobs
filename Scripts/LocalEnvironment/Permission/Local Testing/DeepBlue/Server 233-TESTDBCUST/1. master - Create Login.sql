USE [master]
GO
-- Create Login
/*	Windows domain account:
		spvn\johnson.nguyen
		spvn\sophia.nguyen
		spvn\tacy.nguyen
		spvn\elodie.ho
		spvn\kathy.nguyen
		spvn\winnie.vu
		spvn\helen.do
		spvn\percy.nguyen
		spvn\sol.le
		spvn\eden.dang
		spvn\bobby.nguyen
		spvn\winfred.pham
		spvn\tina.vo
*/
IF @@SERVERNAME  NOT IN ( 'DB233' , 'TESTDBCUST')
BEGIN
	SELECT 'Must be run on DB233/TESTDBCUST' AS 'Error'

	RETURN
END

DECLARE @strLoginName 	VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\johnson.nguyen'), ('spvn\sophia.nguyen')
		, ('spvn\elodie.ho'), ('spvn\kathy.nguyen')
		, ('spvn\helen.do'), ('spvn\percy.nguyen')
		, ('spvn\sol.le'), ('spvn\eden.dang'), ('spvn\bobby.nguyen'),('spvn\winfred.pham'), ('spvn\tina.vo')
		,('spvn\july.nguyen')
		,('spvn\evan.trinh')
		,('spvn\danny.nguyen'),('spvn\tacy.nguyen')
		, ('spvn\malcolm.huynh')
		,('spvn\louisa.vo')
		,('spvn\max.tran')

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

