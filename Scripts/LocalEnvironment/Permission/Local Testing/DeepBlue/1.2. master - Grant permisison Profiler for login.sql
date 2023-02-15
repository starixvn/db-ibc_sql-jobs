USE [master]
GO
 


EXECUTE AS LOGIN = 'sa'

DECLARE @strLoginName VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\elodie.ho' )
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

SELECT @strLoginName = @strLoginName + 'GRANT ALTER TRACE TO ' + '[' + Name + ']' + CHAR(13)
FROM	@tmpMember

EXEC (@strLoginName)

SET @strLoginName = ''

SELECT @strLoginName = @strLoginName + 'GRANT CREATE ANY DATABASE TO ' + '[' + Name + ']' + CHAR(13)
FROM	@tmpMember

EXEC (@strLoginName)

REVERT
GO

