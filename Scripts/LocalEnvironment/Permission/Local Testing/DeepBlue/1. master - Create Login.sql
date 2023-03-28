USE [master]
GO
-- Create Login

  

DECLARE @strLoginName 	VARCHAR(MAX) = ''

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
		, ('spvn\luke.nguyen')

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

