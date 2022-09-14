/*<info serverAlias="DBBAH-bodb02" executers="" viewers="" isFunction="0"></info>*/  
/*
    Created: 20220913@Helen
    Task: 
    DB: DBBAH/bodb02
    Revisions:
		- 20220912@Helen: scaleout project [176932]
		
*/
USE bodb02
GO
INSERT INTO SystemSettings (VName, VValue)
SELECT 'BalanceRecord_SiteDB_Sync', '0'
