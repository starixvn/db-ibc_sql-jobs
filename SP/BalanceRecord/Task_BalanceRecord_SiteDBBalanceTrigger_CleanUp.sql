/*<info serverAlias="DBBAH-bodb02" executers="" viewers="" isFunction="0"></info>*/  
ALTER PROCEDURE [dbo].[Task_BalanceRecord_SiteDBBalanceTrigger_CleanUp] 

AS
/*
    Created: 20220913@Helen
    Task: 
    DB: DBBAH/bodb02
    Revisions:
		- 20220912@Helen: scaleout project [176932]
		- 20220928@July: scaleout project - Balance record [176932]
		- 20220130@Louisa: Remove @VName [Redmine:#176932]
*/
BEGIN
	
	SET NOCOUNT ON
	
	EXEC dbo.SiteDBBalanceTrigger_CleanUp @SiteDBAlias ='DBSIG01'

	EXEC dbo.SiteDBBalanceTrigger_CleanUp @SiteDBAlias ='DBSIG02'

END



