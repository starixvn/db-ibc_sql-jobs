/*<info serverAlias="DBBAH-bodb02" executers="" isFunction="0"></info>*/
/*
    Created: 20230713@Louisa
	Task: Turn off pro flof for sitedb1, sitedb2 - PRODUCTION [Redmine: #188569]
	DB:DBBAH/bodb02

*/

USE bodb02
GO


---DB05/DB05BK1

BEGIN
	SET NOCOUNT ON

	----Turn OFF PRO flag for SiteDB1

	UPDATE dbo.SystemSettings WITH(ROWLOCK, UPDLOCK)
	SET VValue = '0'
	WHERE VName  = 'BT_SiteDB01_ServiceStatus'


	----Turn OFF PRO flag for SiteDB2

	UPDATE dbo.SystemSettings WITH(ROWLOCK, UPDLOCK)
	SET VValue = '0'
	WHERE VName  = 'BT_SiteDB02_ServiceStatus'

END