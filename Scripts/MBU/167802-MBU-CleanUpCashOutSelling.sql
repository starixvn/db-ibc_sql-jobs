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

BEGIN
	CREATE TABLE #tmpTransId (TransId BIGINT)
	
	INSERT INTO #tmpTransId (TransId)
	SELECT s.TransID
	FROM dbo.CashOutSelling s WITH (NOLOCK)
	WHERE NOT EXISTS (SELECT transid FROM dbo.bettrans b WITH (NOLOCK) WHERE b.transid = s.TransID)
		AND NOT EXISTS (SELECT transid from dbo.bettrans14 b14 WITH (NOLOCK) WHERE b14.transid = s.TransID)

	WHILE (1=1)
	BEGIN
		DELETE TOP(1000) s 
		FROM dbo.CashOutSelling s WITH (ROWLOCK)
			INNER JOIN #tmpTransId t ON t.TransId = s.TransID

		IF @@ROWCOUNT < 1000
			BREAK
	END
END

