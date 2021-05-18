/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_CheckBalance1_Bonus_CheckAll_Manually]
AS
/*
	Task: Compute/Compare balance vs BalanceTable of Bonus for all members
	Original: Task_CheckBalance_CheckAll
	Location: DBTXN.bodb02
	Revision:
		- 20180326@Patrick: Changes bettype from 22026, 22027 to 22200, 22201
		- 20190827@Patrick: Exclude all members below 8RM account for bet restricion [RedmineID: #117727]
			+ Fix issue duplicated custid from Acc_DWLList
		- 20210426@Sol: Alpha/NAP - Migrate from DBACC to DBCust - [Redmine: #154041]
		- 20210514@Patrick: Revise Movebet flow to support transfer 247 - Redmine: [#149927]
		
	Param use:
	Logic & Process:
		update Exception table
		1st compute and compare (all members)
		remove UUS & members having ticket being settle
		2nd compute and compare (filtered members)
*/
SET NOCOUNT ON
Declare @RC int, @RD int, @msg varchar(200)
SET @msg = ''
SET @RD = 0

-- automatic update exception list list
INSERT INTO Task_Cust_CheckBalance_Exception
SELECT custid, 'DWLList'
FROM DBCUST.CustDB.dbo.Acc_DWLList dw with (nolock)
WHERE custid NOT IN (SELECT custid FROM dbo.Task_Cust_CheckBalance_Exception ce with (nolock))
GROUP BY custid
UNION ALL
SELECT custid, 'DWLList_ExtraPT'
FROM DBCUST.CustDB.dbo.Acc_DWLList_ExtraPT dwe with (nolock)
WHERE custid NOT IN (SELECT custid FROM dbo.Task_Cust_CheckBalance_Exception ce with (nolock))
GROUP BY custid
UNION ALL
SELECT custid, 'BetTrade Dummy Accounts'
FROM DBCUST.custDB.dbo.BetTradeCust bt with (nolock)
WHERE custid NOT IN (SELECT custid FROM dbo.Task_Cust_CheckBalance_Exception ce with (nolock))
GROUP BY custid

--for 8RM account
INSERT INTO Task_Cust_CheckBalance_Exception(custid, Remark)
SELECT custid, '8RM'
FROM CustDB.dbo.Customer c WITH(NOLOCK)
WHERE c.recommend IN (SELECT custid FROM CustDB.dbo.Customer t WITH(NOLOCK) WHERE t.username = '8RM' AND roleid = 2)
	AND c.custid NOT IN (SELECT ce.custid FROM dbo.Task_Cust_CheckBalance_Exception ce WITH (NOLOCK))
GROUP BY c.custid

IF NOT EXISTS (SELECT 1 FROM dbo.Task_Cust_CheckBalanceVerify1_Bonus_Manually)
BEGIN

	DECLARE @__movebetdate SMALLDATETIME
	EXEC dbo.NAP_Admin_GetMovebetDate @MovebetDate = @__movebetdate OUTPUT

	__tryagain:
	IF OBJECT_ID('tempdb.dbo.#QuestionLists') IS NOT NULL
		DROP TABLE #QuestionLists

	;WITH cb AS (
		--//ignore sum data winlost ticket only
		SELECT b.custid, b.BonusID, SUM(CASE WHEN walletType = 1 AND bettype NOT IN (22200, 22201) THEN winlost - actual_stake + playercomm ELSE 0 END) winlostAmt
		FROM dbo.bettrans b WITH (NOLOCK)
		WHERE b.BonusID > 0
			AND 1 = CASE WHEN bettype = 19999 AND winlostdate > @__movebetdate THEN 0 --> new sum
				 WHEN bettype < 19999 AND winlostdate <= @__movebetdate THEN 0 --> old bet
				 ELSE 1 END
		GROUP BY b.custid, b.BonusID
	), __bonus_sum_winloss_cte AS (
		SELECT CustId, BonusId, SUM(Amount) AS winlostAmt
		FROM dbo.Bonus_sum_winloss WITH(NOLOCK)
		GROUP BY CustId, BonusId
	)

	SELECT cb.*, c1.Amount - d1.Amount AS BonusAmt
	INTO #QuestionLists
	FROM (
		SELECT ISNULL(t.custid, tt.custid) AS CustId, ISNULL(t.BonusId, tt.BonusId) AS BonusId
			, SUM(ISNULL(t.winlostAmt, 0) + ISNULL(tt.winlostAmt, 0)) AS winlostAmt
		FROM cb t FULL OUTER JOIN __bonus_sum_winloss_cte tt ON t.custid = tt.CustId AND t.BonusID = tt.BonusId
		GROUP BY ISNULL(t.custid, tt.custid), ISNULL(t.BonusId, tt.BonusId)
	)cb INNER JOIN dbo.BonusWalletCredit c1 WITH (NOLOCK) ON cb.custid = c1.custid AND cb.BonusID = c1.BonusID
		INNER JOIN dbo.BonusWalletDebit d1 WITH (NOLOCK) ON cb.custid = d1.custid AND cb.BonusID = d1.BonusID
	WHERE (cb.winlostAmt) <> (c1.Amount - d1.Amount)
		AND NOT EXISTS (SELECT 1 FROM dbo.Task_Cust_CheckBalance_Exception ex WITH (NOLOCK) WHERE cb.custid = ex.custid)

	SET @RC = @@ROWCOUNT
	SET @msg = CAST(@RC as varchar(50))

	--//get MovebetDate again if it was changed
	DECLARE @__movebetdateF SMALLDATETIME
	EXEC dbo.NAP_Admin_GetMovebetDate @MovebetDate = @__movebetdateF OUTPUT
	IF @__movebetdate <> @__movebetdateF
	BEGIN
		SET @__movebetdate = @__movebetdateF
		GOTO __tryagain
	END
	
	-- remove settlement involvement
	IF  EXISTS (SELECT 1 FROM #QuestionLists)
		AND
		EXISTS (SELECT 1 FROM TempVariableNumber WHERE KeyID = 1)
	BEGIN
		;WITH m AS (SELECT CAST(KeyValue AS INT) matchid FROM TempVariableNumber WHERE KeyID = 1)
		
		DELETE q
		FROM #QuestionLists q
		WHERE EXISTS (
			SELECT 1 
			FROM dbo.bettrans b WITH (NOLOCK)
			INNER JOIN m ON b.matchid = m.matchid AND b.custid = q.custid AND b.BonusID > 0
		)
			
		SET @RD = @RD + @@ROWCOUNT
	END

	SET @__movebetdate = @__movebetdateF
	-- check one more time (with less accounts)
	;WITH
	cb AS (
		SELECT b.custid, b.BonusID, SUM(CASE WHEN b.walletType = 1 AND bettype NOT IN (22200, 22201) THEN winlost - actual_stake + playercomm ELSE 0 END) winlostAmt, 0 AS RowVersion
		FROM dbo.bettrans b WITH (NOLOCK)
			INNER JOIN #QuestionLists q ON b.custid = q.custid AND b.BonusID = q.BonusID
		WHERE b.BonusID > 0
			AND 1 = CASE WHEN bettype = 19999 AND winlostdate > @__movebetdate THEN 0 --> new sum
				 WHEN bettype < 19999 AND winlostdate <= @__movebetdate THEN 0 --> old bet
				 ELSE 1 END
		GROUP BY b.custid, b.BonusID
	), __bonus_sum_winloss_cte AS (
		SELECT b.CustId, b.BonusId, SUM(Amount) AS winlostAmt, 0 AS RowVersion
		FROM dbo.Bonus_sum_winloss b WITH(NOLOCK)
			INNER JOIN #QuestionLists q ON b.custid = q.custid AND b.BonusID = q.BonusID
		GROUP BY b.CustId, b.BonusId
	)

	INSERT INTO dbo.Task_Cust_CheckBalanceVerify1_Bonus_Manually(custid, BonusId, roundVerified, MaxRowVersion, DiffBalance)
	SELECT cb.custid, cb.BonusID, 0, RowVersion
		, (cb.winlostAmt) - (c1.Amount - d1.Amount) AS DiffBalance
	FROM (
		SELECT ISNULL(t.custid, tt.custid) AS CustId, ISNULL(t.BonusId, tt.BonusId) AS BonusId
			, SUM(ISNULL(t.winlostAmt, 0) + ISNULL(tt.winlostAmt, 0)) AS winlostAmt, ISNULL(t.RowVersion, tt.RowVersion) AS RowVersion
		FROM cb t FULL OUTER JOIN __bonus_sum_winloss_cte tt ON t.custid = tt.CustId AND t.BonusID = tt.BonusId
		GROUP BY ISNULL(t.custid, tt.custid), ISNULL(t.BonusId, tt.BonusId), ISNULL(t.RowVersion, tt.RowVersion)
	)cb INNER JOIN dbo.BonusWalletCredit c1 WITH (NOLOCK) ON cb.custid = c1.custid AND cb.BonusID = c1.BonusID
		INNER JOIN dbo.BonusWalletDebit d1 WITH (NOLOCK) ON cb.custid = d1.custid AND cb.BonusID = d1.BonusID
	WHERE (cb.winlostAmt) <> (c1.Amount - d1.Amount)
		AND NOT EXISTS (SELECT 1 FROM dbo.Task_Cust_CheckBalance_Exception ex WITH (NOLOCK) WHERE cb.custid = ex.custid)
		AND NOT EXISTS (SELECT 1 FROM dbo.BonusWalletPending p WITH (NOLOCK) WHERE cb.custid = p.custid AND cb.BonusID = p.BonusID)
		
	PRINT @msg + ' -' + CAST(@RD as varchar(50)) + ' -> ' + CAST(@@ROWCOUNT as varchar(50)) + ' accounts add to verify balance'
	
	DROP TABLE #QuestionLists

END
GO
