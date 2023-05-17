/*<info serverAlias="DBBAH-bodb02" executers="" viewers="" isFunction="0"></info>*/  

/*
	Created: 20220130@Louisa
    DB: DBBAH/bodb02
   
    Revisions:
		- 20220130@Louisa: Phase 2 - use Web Service to pull ticket from DBSIG to DB05/DB05BK1 [Redmine:#176932]

*/

USE bodb02
GO

BEGIN
	SET NOCOUNT ON

	----Turn on PRO flag

	UPDATE dbo.SystemSettings WITH(ROWLOCK, UPDLOCK)
	SET VValue = '1'
	WHERE VName  IN ('BT_SiteDB01_ServiceStatus', 'BT_SiteDB02_ServiceStatus' ) 

END