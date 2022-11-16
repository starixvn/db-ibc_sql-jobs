/*<info serverAlias="DBSIG-bodb02" executers="" viewers="" isFunction="0"></info>*/
/*
	Created: Max@20221116
	DB: DBSIG.BODB02
	Task: 
	Revision:
		- 20221116@Max: [LAP] Detail transaction_Display Different Balance Amount of Deposit & Withdrawal [180295]
*/
USE bodb02
GO

SELECT MIN(Transid)
FROM dbo.BalanceTrigger b WITH (NOLOCK)
WHERE b.Action LIKE 'Transfer%'