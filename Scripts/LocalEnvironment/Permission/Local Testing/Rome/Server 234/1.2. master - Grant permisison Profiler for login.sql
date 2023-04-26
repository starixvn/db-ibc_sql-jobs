USE [master]
GO
/*	Windows domain account:
	spvn\ethan.nguyen
	spvn\andy.nguyen
	spvn\david.tran
	spvn\phillip.truong
	spvn\louis.nguyen
	spvn\kan.nguyen
	spvn\razor.nguyen
	spvn\alvin.nguyen
*/


-- Grant permisison Profiler for login

IF @@SERVERNAME NOT IN ( 'DB234' , 'TESTDB061' )
BEGIN
	SELECT 'Must be run on DB234' AS 'Error'

	RETURN
END

DECLARE @strLoginName VARCHAR(MAX) = ''

DECLARE @tmpMember TABLE (Name VARCHAR(50))

INSERT INTO @tmpMember (Name) 
	VALUES ('spvn\ethan.nguyen'), ('spvn\andy.nguyen'), ('spvn\david.tran')
		,('spvn\phillip.truong'), ('spvn\louis.nguyen'), ('spvn\kan.nguyen')
		,('spvn\razor.nguyen'), ('spvn\alvin.nguyen')
		,('spvn\jack.nguyen'), ('spvn\issac.le'),('spvn\lucian.vo')

SELECT @strLoginName = @strLoginName + 'GRANT ALTER TRACE TO ' + '[' + Name + ']' + CHAR(13)
FROM	@tmpMember

EXEC (@strLoginName)
GO

