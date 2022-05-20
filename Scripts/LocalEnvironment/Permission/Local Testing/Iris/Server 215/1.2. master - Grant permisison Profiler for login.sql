USE [master]
GO
/*	Windows domain account:
	
*/

-- Grant permisison Profiler for login

IF @@SERVERNAME NOT IN ( 'DB215' , 'TESTDB053' )
BEGIN
	SELECT 'Must be run on DB215 or TESTDB053' AS 'Error'

	RETURN
END

DECLARE @strLoginName VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\kaka.huynh'),
		('spvn\dora.le'),
		('spvn\jane.dinh'),
		('spvn\megan.dinh'),
		('spvn\tommy.nguyen'),
		('spvn\Dory.vu'),
		('spvn\Neil.dao'),
		('spvn\harley.nguyen'),
		('spvn\Mike.vu'),
		('spvn\kenny.ho')


SELECT @strLoginName = @strLoginName + 'GRANT ALTER TRACE TO ' + '[' + Name + ']' + CHAR(13)
FROM	@tmpMember

EXEC (@strLoginName)
GO

