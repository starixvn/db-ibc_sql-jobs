/*
	Creator:	20180718@Billy
	Task:		Certificate for cross database authentication - [Redmine: #00000]
	Server:		DBTP.bodbConsistency
*/


USE	master;
GO

CREATE CERTIFICATE	CrossDatabaseAuthenticationCertificate
ENCRYPTION BY PASSWORD = '[xxx]'
WITH SUBJECT = 'Certificate to access cross databases';
GO

BACKUP CERTIFICATE	CrossDatabaseAuthenticationCertificate
TO FILE = 'C:\CrossDatabaseAuthenticationCertificate.cer'
WITH PRIVATE KEY (
	FILE = 'C:\CrossDatabaseAuthenticationCertificate_Private.cer'
,	ENCRYPTION BY PASSWORD = '[yyy]'
,	DECRYPTION BY PASSWORD = '[xxx]'
);
GO

USE	bodb02;
GO

CREATE CERTIFICATE	CrossDatabaseAuthenticationCertificate
FROM FILE = 'C:\CrossDatabaseAuthenticationCertificate.cer'
WITH PRIVATE KEY (
	FILE = 'C:\CrossDatabaseAuthenticationCertificate_Private.cer'
,	DECRYPTION BY PASSWORD = '[yyy]'
,	ENCRYPTION BY PASSWORD = '[xxx]'
);
GO

CREATE USER	CrossDatabaseUser
FROM CERTIFICATE	CrossDatabaseAuthenticationCertificate;
GO

GRANT AUTHENTICATE TO CrossDatabaseUser;
GO

EXECUTE	sys.sp_addrolemember @rolename = 'db_datareader', @membername = 'CrossDatabaseUser';
GO

USE	bodb_Consistency;
GO

CREATE CERTIFICATE	CrossDatabaseAuthenticationCertificate
FROM FILE = 'C:\CrossDatabaseAuthenticationCertificate.cer'
WITH PRIVATE KEY (
	FILE = 'C:\CrossDatabaseAuthenticationCertificate_Private.cer'
,	DECRYPTION BY PASSWORD = '[yyy]'
,	ENCRYPTION BY PASSWORD = '[xxx]'
);
GO

CREATE USER	CrossDatabaseUser
FROM CERTIFICATE	CrossDatabaseAuthenticationCertificate;
GO

GRANT AUTHENTICATE TO CrossDatabaseUser;
GO

EXECUTE	sys.sp_addrolemember @rolename = 'db_datareader', @membername = 'CrossDatabaseUser';
GO