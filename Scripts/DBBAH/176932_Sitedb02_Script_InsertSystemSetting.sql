/*<info serverAlias="DBBAH-bodb02" executers="" viewers="" isFunction="0"></info>*/  
/*
    Created: 20220928@July
    Task: 
    DB: DBBAH/bodb02
    Revisions:
		- 20220928@July: scaleout project [176932]
		
*/
USE bodb02
GO
INSERT INTO SystemSettings (VName, VValue)
SELECT 'BT_SiteDB02_Sync', '0'
