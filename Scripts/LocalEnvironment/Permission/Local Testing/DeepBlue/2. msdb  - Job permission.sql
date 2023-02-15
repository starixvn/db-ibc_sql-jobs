-- Create User
USE [msdb]
GO
  

DECLARE @strUser VARCHAR(MAX) = ''
DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES  ('spvn\elodie.ho' )
		, ('spvn\johnson.nguyen' )
		, ('spvn\eden.dang' )
		, ('spvn\winfred.pham' )
		, ('spvn\tacy.nguyen' )
		, ('spvn\helios.huynh'  )

		, ('spvn\sophia.nguyen' )
		, ('spvn\bobby.nguyen' )
		, ('spvn\sol.le' )
		, ('spvn\malcolm.huynh' )
		, ('spvn\evan.trinh' )
		, ('spvn\danny.nguyen' )
		, ('spvn\eddie.nguyen' )

		, ('spvn\kathy.nguyen' )
		, ('spvn\helen.do' )
		, ('spvn\louisa.vo' )
		, ('spvn\max.tran' )	
		, ('spvn\tina.vo' )
		, ('spvn\july.nguyen' )
		, ('spvn\aries.nguyen' )

SELECT	@strUser = @strUser 
			+ 'CREATE USER ' + '[' + t.Name + ']' + ' FOR LOGIN ' + '[' + t.Name + ']' + ' WITH DEFAULT_SCHEMA=[dbo]; '
			+ CHAR(13)
			+ 'ALTER USER' + '[' + t.Name + ']' + ' WITH DEFAULT_SCHEMA=[dbo]' + ';'
			+ CHAR(13)
FROM	@tmpMember t
	LEFT JOIN sys.database_principals s
		ON t.Name = s.name
WHERE	s.name IS NULL

EXEC (@strUser)
GO


-- Add Role
USE [msdb]
GO
 
DECLARE @strUser VARCHAR(MAX) = ''
DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES  ('spvn\elodie.ho' )
		, ('spvn\johnson.nguyen' )
		, ('spvn\eden.dang' )
		, ('spvn\winfred.pham' )
		, ('spvn\tacy.nguyen' )
		, ('spvn\helios.huynh'  )

		, ('spvn\sophia.nguyen' )
		, ('spvn\bobby.nguyen' )
		, ('spvn\sol.le' )
		, ('spvn\malcolm.huynh' )
		, ('spvn\evan.trinh' )
		, ('spvn\danny.nguyen' )
		, ('spvn\eddie.nguyen' )

		, ('spvn\kathy.nguyen' )
		, ('spvn\helen.do' )
		, ('spvn\louisa.vo' )
		, ('spvn\max.tran' )	
		, ('spvn\tina.vo' )
		, ('spvn\july.nguyen' )
		, ('spvn\aries.nguyen' )

SELECT	@strUser = @strUser + 'EXEC sp_AddRoleMember ''SQLAgentOperatorRole''' + ', ''' + t.Name + '''' 
		+ CHAR(13)
FROM	@tmpMember t

EXEC (@strUser)
GO