/*<info serverAlias="DBBAH-bodb02" executers="" isFunction="0"></info>*/
/*
    Created: 20230522@Louisa
	Task: Detail Transaction - Re-init balance for the rest of licensees [Redmine: #188569]
	DB:DBBAH/bodb02

*/
USE bodb02
GO

BEGIN
	SET NOCOUNT ON

	----Turn OFF PRO flag for SiteDB2

	UPDATE dbo.SystemSettings WITH(ROWLOCK, UPDLOCK)
	SET VValue = '0'
	WHERE VName  = 'BT_SiteDB02_ServiceStatus'

END
