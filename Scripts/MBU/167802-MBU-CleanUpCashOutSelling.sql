/*<info serverAlias="DBTXN-bodb02" executers="" selecters="" viewers="" isFunction="0" isNested="0"></info>*/
/*
    Created: 20220209@Max
	Task: MBU - Clean up Cash Out Selling - [Redmine: #167802]
	DB: DBTXN/bodb02

	Notes:
		- Clean up data on CashOutSelling tables has exceeded archive date
*/

USE [bodb02]
GO

CREATE TABLE #Result(
	TransId BIGINT PRIMARY KEY,
	Isfinished BIT
)

CREATE TABLE #Result_batch(
	TransId BIGINT PRIMARY KEY,
)

INSERT INTO #Result (TransId)
SELECT s.TransID
FROM dbo.CashOutSelling s WITH (NOLOCK)
	LEFT JOIN dbo.bettrans b WITH (NOLOCK) ON b.transid = s.TransID
	LEFT JOIN dbo.bettrans14 b14 WITH (NOLOCK) ON b14.transid = s.TransID
WHERE b.transid IS NULL 
	AND b14.transid IS NULL

------ info for deployer

DECLARE @debug_message VARCHAR(500)
WHILE (1 = 1)
BEGIN
	UPDATE TOP (1000) R
		SET Isfinished = 1	
	OUTPUT DELETED.TransId
		INTO #Result_batch (TransId)		
	FROM #Result r
	WHERE r.Isfinished IS NULL
	
	IF @@ROWCOUNT = 0
		BREAK

	SET @debug_message = CONVERT(VARCHAR(50), GETDATE(), 121)			
	RAISERROR (@debug_message, 0, 1) WITH NOWAIT
	
	-- YOUR CODE HERE to process each batch
	DELETE s 
	FROM dbo.CashOutSelling s WITH (ROWLOCK)
		INNER JOIN #Result_batch t ON t.TransId = s.TransID

	TRUNCATE TABLE #Result_batch

	WAITFOR DELAY '00:00:00.100'
END

DROP TABLE #Result
DROP TABLE #Result_batch


