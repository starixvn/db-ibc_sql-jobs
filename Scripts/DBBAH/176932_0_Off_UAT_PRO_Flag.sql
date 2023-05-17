/*<info serverAlias="DBBAH-bodb02" executers="" viewers="" isFunction="0"></info>*/  

/*
	Created: 20220130@Louisa
    DB: DBBAH/bodb02
   
    Revisions:
		- 20220130@Louisa: Turn off flag [Redmine:#176932]

*/

USE bodb02
GO

BEGIN
	SET NOCOUNT ON

	UPDATE dbo.SystemSettings WITH(ROWLOCK, UPDLOCK)
	SET VValue = '0'
	WHERE VName  IN (	 'BT_SiteDB01_ServiceStatus_UAT'
						,'BT_SiteDB02_ServiceStatus_UAT'
						,'BT_SiteDB01_ServiceStatus'
						,'BT_SiteDB02_ServiceStatus'
					)  

END