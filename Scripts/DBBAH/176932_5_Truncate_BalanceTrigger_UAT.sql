/*<info serverAlias="DBBAH-bodb02" executers="" viewers="" isFunction="0"></info>*/  

/*
	Created: 20220130@Louisa
    DB: DBBAH/bodb02
   
    Revisions:
		- 20220130@Louisa: truncate table BalanceTrigger_UAT [Redmine:#176932]

*/

USE bodb02
GO

BEGIN
	SET NOCOUNT ON

	----truncate data test after release
	IF EXISTS (SELECT TOP 1 1 FROM bodb02.sys.objects WHERE name = 'BalanceTrigger_UAT')
	BEGIN
		TRUNCATE TABLE BalanceTrigger_UAT
	END

END