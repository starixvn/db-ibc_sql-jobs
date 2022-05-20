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

DECLARE @strUser VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50), IsSysadmin BIT)

INSERT INTO @tmpMember (Name, IsSysadmin) 
	VALUES ('spvn\johnson.nguyen', 0), ('spvn\sophia.nguyen', 1)
		,('spvn\jamie.dao', 1), ('spvn\elodie.ho', 1), ('spvn\kathy.nguyen', 1)
		,('spvn\tina.vo', 0), ('spvn\helen.do', 1), ('spvn\percy.nguyen', 0)
		, ('spvn\sol.le', 1), ('spvn\eden.dang', 0), ('spvn\bobby.nguyen',0)
		,('spvn\tiara.nguyen', 0)

SELECT	@strUser = @strUser + 'EXEC sp_addsrvrolemember @rolename = N''sysadmin''' + ', @loginame = N''' + t.Name + '''' 
		+ CHAR(13)
FROM	@tmpMember t
WHERE IsSysadmin = 1

EXEC (@strUser)

SET @strUser = ''

SELECT	@strUser = @strUser + 'EXEC sp_dropsrvrolemember @rolename = N''sysadmin''' + ', @loginame = N''' + t.Name + '''' 
		+ CHAR(13)
FROM	@tmpMember t
WHERE IsSysadmin = 0

EXEC (@strUser)
GO

