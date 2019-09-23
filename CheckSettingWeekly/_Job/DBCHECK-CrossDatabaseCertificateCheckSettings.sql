/*
	Creator:	20180718@Billy
	Task:		Certificate for cross database authentication - [Redmine: #00000]
	Server:		DBCHECK.CheckResultDB
*/


USE	CheckResultDB;
GO

CREATE CERTIFICATE	CheckSettingAuthenticationCertificate
ENCRYPTION BY PASSWORD = '~~PASSWORD~~'
WITH SUBJECT = 'Certificate for StarixDB to access server level permission';
GO

BACKUP CERTIFICATE	CheckSettingAuthenticationCertificate
TO FILE = 'C:\CheckSettingAuthenticationCertificate.cer'
WITH PRIVATE KEY (
	FILE = 'C:\CheckSettingAuthenticationCertificate_Private.cer'
,	ENCRYPTION BY PASSWORD = '~~PRIVATEKEYPASSWORD~~'
,	DECRYPTION BY PASSWORD = '~~PASSWORD~~'
);
GO

USE	CheckCustDB;
GO

CREATE CERTIFICATE	CheckSettingAuthenticationCertificate
FROM FILE = 'C:\CheckSettingAuthenticationCertificate.cer'
WITH PRIVATE KEY (
	FILE = 'C:\CheckSettingAuthenticationCertificate_Private.cer'
,	DECRYPTION BY PASSWORD = '~~PRIVATEKEYPASSWORD~~'
,	ENCRYPTION BY PASSWORD = '~~PASSWORD~~'
);
GO

CREATE USER	CheckSettingUser
FROM CERTIFICATE	CheckSettingAuthenticationCertificate;
GO

GRANT AUTHENTICATE TO CheckSettingUser;
GO

EXECUTE	sys.sp_addrolemember @rolename = 'db_datareader', @membername = 'CheckSettingUser';
GO