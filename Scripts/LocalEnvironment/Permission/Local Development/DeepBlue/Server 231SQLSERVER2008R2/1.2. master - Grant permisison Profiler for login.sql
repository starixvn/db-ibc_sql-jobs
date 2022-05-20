USE [master]
GO
/*	Windows domain account:
		spvn\johnson.nguyen
		spvn\sophia.nguyen
		spvn\jamie.dao
		spvn\elodie.ho
		spvn\kathy.nguyen
		spvn\tina.vo
		spvn\helen.do
		spvn\percy.nguyen
		spvn\sol.le
		spvn\eden.dang
		spvn\bobby.nguyen
*/

-- Grant permisison Profiler for login

IF @@SERVERNAME <> 'DB231\SQLSERVER2008R2'
BEGIN
	SELECT 'Must be run on DB231\SQLSERVER2008R2' AS 'Error'

	RETURN
END

EXECUTE AS LOGIN = 'DB231\SQL'

DECLARE @strLoginName VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\johnson.nguyen'), ('spvn\sophia.nguyen')
		,('spvn\jamie.dao'), ('spvn\elodie.ho'), ('spvn\kathy.nguyen')
		,('spvn\tina.vo'), ('spvn\helen.do'), ('spvn\percy.nguyen')
		, ('spvn\sol.le'), ('spvn\eden.dang'), ('spvn\bobby.nguyen')
		,('spvn\tiara.nguyen')

SELECT @strLoginName = @strLoginName + 'GRANT ALTER TRACE TO ' + '[' + Name + ']' + CHAR(13)
FROM	@tmpMember

EXEC (@strLoginName)

SET @strLoginName = ''

SELECT @strLoginName = @strLoginName + 'GRANT CREATE ANY DATABASE TO ' + '[' + Name + ']' + CHAR(13)
FROM	@tmpMember

EXEC (@strLoginName)

REVERT
GO

