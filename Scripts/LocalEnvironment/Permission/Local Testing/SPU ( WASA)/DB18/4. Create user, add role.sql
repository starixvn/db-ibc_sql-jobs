/*
	For Olympus team:
	Affected DB:
		bodb02

	
*/
-- Create User
IF  @@SERVERNAME NOT LIKE '%DB18' 
BEGIN
	SELECT 'Wrong server' AS 'Error'
	RETURN
END

DECLARE @strUser	VARCHAR(MAX) = ''
		,@RoleName VARCHAR(50) = 'db_Fps'
		,@LeaderRoleName VARCHAR(50) = 'db_owner'
		,@Leader VARCHAR(50)

DECLARE @tmpMember TABLE (Name VARCHAR(50), RoleName VARCHAR(50))

DECLARE @tmpAffectedDB TABLE (DBName VARCHAR(50))

INSERT INTO @tmpAffectedDB (DBName)
	VALUES  ('FPS_DeviceFingerprint'),('FPS_ADMIN'),('FPS_DEV'),('FPS_EVI'),('FPS_MONITOR'),('FPS_RPT'),('FPS_SUB_Alpha'),('FPS_LOG'),('IPDB') 
	 

INSERT INTO @tmpMember (Name) 
	VALUES	   ('spvn\long.luu')
			 , ('spvn\terry.nguyen')
			 , ('spvn\casey.huynh')

			, ('spvn\john.ngo')
			, ('spvn\victoria.le')
			, ('spvn\jonathan.doan')

 UPDATE @tmpMember
	SET RoleName = CASE WHEN Name = @Leader THEN @LeaderRoleName ELSE @RoleName	END
	
SELECT	@strUser = @strUser 
					+ 'USE ' + d.DBName + ';'
					+ CHAR(13)
					+ 'IF NOT EXISTS (SELECT TOP 1 1 FROM sys.database_principals WHERE NAME = ''' + t.Name + ''') '
					+ 'CREATE USER ' + '[' + t.Name + ']' + ' FOR LOGIN ' + '[' + t.Name + ']' + ' WITH DEFAULT_SCHEMA=[dbo] ' + ';'
					+ CHAR(13)
					+ 'ALTER USER' + '[' + t.Name + ']' + ' WITH DEFAULT_SCHEMA=[dbo]' + ';'
					+ CHAR(13)
FROM	@tmpAffectedDB d
	CROSS APPLY (
		SELECT	t.Name
		FROM	@tmpMember t
	) t

EXEC (@strUser)
WAITFOR DELAY '00:00:01'
 
-------------------------------------------
-- Add Role for member
SET @strUser = '' 
SELECT	@strUser = @strUser
					+ 'USE ' + d.DBName + ';'
					+ CHAR(13)
					+ 'EXEC sp_AddRoleMember ''' + t.RoleName + ''',''' + t.Name + ''' ' + ';'
					+ CHAR(13)
FROM	@tmpAffectedDB d
	CROSS APPLY (
		SELECT Name, RoleName
		FROM @tmpMember 
	)t

EXEC (@strUser)

GO