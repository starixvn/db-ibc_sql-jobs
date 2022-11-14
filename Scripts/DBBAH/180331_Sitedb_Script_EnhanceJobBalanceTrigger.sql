/*<info serverAlias="DBSIG-bodb02" executers="" viewers="" isFunction="0"></info>*/  
/*
    Created: 20221110@July
    Task: Scale out DBTrans - Enhance Job clean BalanceTrigger
    DB: DBSIG/bodb02
    Revisions:
		- 20221110@July: Create index ActionDate table BalanceTrigger [180331]
		
*/
USE bodb02
GO

CREATE NONCLUSTERED INDEX [IX_BalanceTrigger_ActionDate] ON [dbo].[BalanceTrigger]
(
	ActionDate ASC
) WITH (ONLINE = ON) ON [BALANCE]
GO
