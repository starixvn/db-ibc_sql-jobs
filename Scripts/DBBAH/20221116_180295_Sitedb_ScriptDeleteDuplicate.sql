/*<info serverAlias="DBBAH-bodb02" executers="" viewers="" isFunction="0"></info>*/
/*
	Created: Max@20221116
	DB: DBBAH.BODB02
	Task: 
	Revision:
		- 20221116@Max: [LAP] Detail transaction_Display Different Balance Amount of Deposit & Withdrawal [180295]
*/
USE bodb02
GO

DECLARE @MinTransId BIGINT = XXX --OUTPUT OF STEP 3 ON DEPLOYMENT STEPS [Redmine: #180523]

SELECT b.transid, actionid, action, balancechanged INTO #tmp
FROM dbo.BalanceTrigger b WITH (NOLOCK)
WHERE b.Action LIKE 'Transfer%'
	AND b.transid >= @MinTransId
GROUP BY b.transid, actionid, action, balancechanged
HAVING COUNT(1) > 1

SELECT b.transid, b.ActionID, b.Action, b.BalanceChanged, MIN(b.RowID) AS min_row  INTO #tmp_1
FROM #tmp t 
	INNER JOIN dbo.BalanceTrigger b WITH (NOLOCK) ON b.transid = t.transid AND b.ActionID = t.ActionID AND b.Action = t.Action AND b.BalanceChanged = t.BalanceChanged
GROUP BY b.transid, b.ActionID, b.Action, b.BalanceChanged

SELECT b.RowID into #row_delete
FROM dbo.BalanceTrigger b WITH (NOLOCK)
	INNER JOIN #tmp_1 t ON b.transid = t.transid AND b.ActionID = t.ActionID AND b.Action = t.Action AND b.BalanceChanged = t.BalanceChanged AND b.RowID > t.min_row

DELETE b
FROM dbo.BalanceTrigger b 
INNER JOIN #row_delete d on d.RowID = b.RowID

