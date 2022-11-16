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

DECLARE @MinTransId BIGINT = XXX --OUTPUT OF STEP 3 ON DPLOYMENT STEPS [Redmine: #180523]
 

;WITH CTE(
	TransId, 
	DuplicateCount)
AS (SELECT b.transid, 
           ROW_NUMBER() OVER(PARTITION BY b.transid
           ORDER BY transid) AS DuplicateCount
    FROM dbo.BalanceTrigger b WITH (NOLOCK)
	WHERE b.Action LIKE 'Transfer%'
		AND b.transid > @MinTransId)
DELETE FROM CTE
WHERE DuplicateCount > 1;