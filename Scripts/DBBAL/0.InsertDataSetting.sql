/*<info serverAlias="DBBAL-msdb"></info>*/
USE bodb02
GO 

--ALTER TABLE SystemSettings ALTER COLUMN VName VARCHAR(50)

---------------------
SET IDENTITY_INSERT SystemSettings ON 
INSERT INTO  SystemSettings (
		 VID,
		VName,
		VValue)
 
SELECT VID,
		VName,
		VValue 
FROM DBEXT.bodb02.dbo.SystemSettings

SET IDENTITY_INSERT SystemSettings OFF

-----------------------
USE bodb_licensee
GO 

SET IDENTITY_INSERT bodb_licensee.dbo.LICSettings ON

INSERT INTO bodb_licensee.dbo.LICSettings (VID,
VName,
VValue,
VValue2)

SELECT VID,
VName,
VValue,
VValue2 
FROM DBLIC.bodb_licensee.dbo.LICSettings 


SET IDENTITY_INSERT bodb_licensee.dbo.LICSettings OFF

------------
USE bodb_3rdproduct 
GO 


SET IDENTITY_INSERT LicSystemSetting ON

INSERT INTO LicSystemSetting (ID,
ProductId,
SName,
SValue)
SELECT ID,
ProductId,
SName,
SValue
FROM DBLIC.bodb_3rdproduct.dbo.LicSystemSetting
 
SET IDENTITY_INSERT LicSystemSetting OFF

 ----------------------------------
 USE bodb_PlaytechCS 
 GO 
  
INSERT INTO LicIntegrationSetting ( LicenseeID,
LicenseeName,
SettingName,
SettingValue,
AllowApiBalance) 

SELECT LicenseeID,
LicenseeName,
SettingName,
SettingValue,
AllowApiBalance
FROM  DBPTSC.bodb_PlaytechCS.dbo.LicIntegrationSetting