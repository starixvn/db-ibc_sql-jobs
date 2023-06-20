/*<info serverAlias="DBSIG-bodb02" executers="" viewers="" isFunction="0"></info>*/ 
/*
    Created: 20230530@Louisa
	Task: Create index [Redmine:#188569]
	DB:DBSIG/bodb02

	Revisions:
		20230530@Louisa: Create index on BalanceTrigger [Redmine:#188569]

*/
USE bodb02
GO

CREATE NONCLUSTERED INDEX [inx_BalanceTrigger_custid] ON [dbo].[BalanceTrigger]
(
	[custid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [BALANCE]
GO


