USE [master]
GO
 
-- Grant permisison Profiler for login

EXECUTE AS LOGIN = 'sa'

DECLARE @strUser VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50), IsSysadmin BIT)

INSERT INTO @tmpMember (Name, IsSysadmin) 
	VALUES ('spvn\elodie.ho', 1)
		, ('spvn\johnson.nguyen', 0)
		, ('spvn\eden.dang', 0)
		, ('spvn\winfred.pham',0)
		, ('spvn\tacy.nguyen',0)
		, ('spvn\helios.huynh' , 0)

		, ('spvn\sophia.nguyen', 1)
		, ('spvn\bobby.nguyen',1)
		, ('spvn\sol.le',1)
		, ('spvn\malcolm.huynh',0)
		, ('spvn\evan.trinh',0)
		, ('spvn\danny.nguyen',0)
		, ('spvn\eddie.nguyen', 0)

		, ('spvn\kathy.nguyen', 1)
		, ('spvn\helen.do', 1)
		, ('spvn\louisa.vo',1)
		, ('spvn\max.tran',1)	
		, ('spvn\tina.vo', 0)
		, ('spvn\july.nguyen',0)
		, ('spvn\aries.nguyen',0)

SELECT @strUser  =  @strUser + 'GRANT ALTER TRACE TO [' +t.Name +']'   + CHAR(13)
FROM	@tmpMember t

EXEC (@strUser)

waitfor delay '00:00:01'

SET @strUser = ''
SELECT @strUser = @strUser + 'GRANT CREATE ANY DATABASE TO ' + '[' + t.Name + ']' + CHAR(13)
FROM	@tmpMember t

EXEC (@strUser)

waitfor delay '00:00:01'

SET @strUser = ''
SELECT	@strUser = @strUser + 'EXEC sp_addsrvrolemember @rolename = N''sysadmin''' + ', @loginame = N''' + t.Name + '''' 
		+ CHAR(13)
FROM	@tmpMember t
WHERE IsSysadmin = 1

EXEC (@strUser)




 