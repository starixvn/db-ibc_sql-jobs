USE [master]
GO
/*	Windows domain account:
	spvn\quinn.vo
	spvn\tim.trinh
	spvn\scofield.huynh
*/

-- Grant permisison Profiler for login

IF @@SERVERNAME NOT in ('DB215','TESTDB053')
BEGIN
	SELECT 'Must be run on DB215' AS 'Error'

	RETURN
END

DECLARE @strLoginName VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES    ('spvn\kos.nguyen')
			,('spvn\parsons.nguyen')
			,('spvn\hubert.duong')		
			,('spvn\howard.nguyen')		
			,('spvn\hogan.pham')	 
			,('spvn\steve.nguyen')		
			,('spvn\happy.duong')	
			,('spvn\kai.le')

SELECT @strLoginName = @strLoginName + 'GRANT ALTER TRACE TO ' + '[' + Name + ']' + CHAR(13)
FROM	@tmpMember

EXEC (@strLoginName)
GO

