USE [master]
GO
 

IF @@SERVERNAME NOT IN ( 'DB233' , 'TESTDBCUST')
BEGIN
	SELECT 'Must be run on DB233/TESTDBCUST' AS 'Error'

	RETURN
END

EXECUTE AS LOGIN = 'sa'

DECLARE @strLoginName VARCHAR(MAX) = ''

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
		,('SPVN\Victoria.le')
		,('SPVN\Eddie.nguyen')
		,('spvn\Victoria.le')
		,('spvn\eddie.nguyen' )

SELECT @strLoginName = @strLoginName + 'GRANT ALTER TRACE TO ' + '[' + Name + ']' + CHAR(13)
FROM	@tmpMember

EXEC (@strLoginName)

SET @strLoginName = ''

SELECT @strLoginName = @strLoginName + 'GRANT CREATE ANY DATABASE TO ' + '[' + Name + ']' + CHAR(13)
FROM	@tmpMember

EXEC (@strLoginName)

REVERT
GO

