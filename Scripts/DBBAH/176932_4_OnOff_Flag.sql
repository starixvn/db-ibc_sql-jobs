/*<info serverAlias="DBBAH-bodb02" executers="" viewers="" isFunction="0"></info>*/  

/*
	Created: 20220130@Louisa
    DB: DBBAH/bodb02
   
    Revisions:
		- 20220130@Louisa: Phase 2 - use Web Service to pull ticket from DBSIG to DB05/DB05BK1 [Redmine:#176932]

*/

USE bodb02
GO

---- for release Production
BEGIN
	SET NOCOUNT ON

	----1. Turn off UAT flag

	UPDATE dbo.SystemSettings WITH(ROWLOCK, UPDLOCK)
	SET VValue = '0'
	WHERE VName  IN ('BT_SiteDB01_ServiceStatus_UAT', 'BT_SiteDB02_ServiceStatus_UAT') 

	----2. Turn on PRO flag

	UPDATE dbo.SystemSettings WITH(ROWLOCK, UPDLOCK)
	SET VValue = '1'
	WHERE VName  IN ('BT_SiteDB01_ServiceStatus', 'BT_SiteDB02_ServiceStatus' ) 

END