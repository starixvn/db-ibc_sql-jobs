/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_CheckBalance1_CheckAll]
AS

/*
	Task: Compute/Compare balance vs BalanceTable for all members
	Original: Task_CheckBalance_CheckAll
	Location: DBTXN.bodb02

	Revision:
	   20150907@Daniel: Clone from Task_CheckBalance_CheckAll & apply new set of bal tables
		20151210@Daniel: calc balance from table bettransRNG & bettransLC 
		20160112@Daniel: enhance using FULL JOIN when get data from translog, bettransRNG, bettransLC
		20160906@Daniel: add update exception list for BetTrade accounts
		20170929@Patrick: Update code for Bonus project
		20171201@Patrick: Bullfighting - calc waiting ticket into outstanding amt on translog
		20190319@Patrick: Exclude CN88 account - push code to git [RedmineID: #110530]
		20190827@Patrick: Exclude all members below 8RM account for bet restricion [RedmineID: #117727]
			+ Fix issue duplicated custid from Acc_DWLList
		- 20210426@Sol: Alpha/NAP - Migrate from DBACC to DBCust - [Redmine: #154041]
		20210514@Patrick: Revise Movebet flow to support transfer 247 - Redmine: [#149927]
		20211231@Patrick: Split bettype >= 19999 out bettrans Redmine: [#164197]
		20220715@Patrick: Use insert into instead of select into Redmine: [#175440]
		20220804@Patrick: Support scale-out for deposit site Redmine: [#175602]
		20221227@Patrick: Support BU 247 Redmine: [#182882]
		
	Param use:


	Logic & Process:
		update Exception table
		1st compute and compare (all members)
		remove UUS & members having ticket being settle
		2nd compute and compare (filtered members)
*/
BEGIN
	SET NOCOUNT ON
	Declare @RC int, @RD int, @msg varchar(200), @__siteDBGroupId SMALLINT = 0
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

	SELECT @__siteDBGroupId = dbo.f_Get_SiteDBGroupID()

	IF NOT EXISTS (SELECT 1 FROM dbo.Task_Cust_CheckBalanceVerify1)
	BEGIN
		IF OBJECT_ID('tempdb.dbo.#tmpCal') IS NOT NULL
			DROP TABLE #tmpCal

		CREATE TABLE #tmpCal ( custid INT, Outstanding MONEY, BalRNG MONEY, BalLC MONEY, adjustWinlostAmt MONEY)
			
		;WITH q2 AS (
			-- translog
			SELECT tl.custid, SUM(actual_stake) AS Outstanding
			FROM dbo.translog tl with (nolock)
			WHERE tl.statusID IN (0,1) --summary running tickets only
				AND ISNULL(tl.SiteDBGroupID, 0) = @__siteDBGroupId
			GROUP BY tl.custid
		),
		q3 AS (
			SELECT custid, SUM(CASE WHEN statusid = 0 THEN -actual_stake ELSE winlost-actual_stake+playercomm END) BalRNG
			FROM dbo.bettransRNG WITH(NOLOCK)
			WHERE IsSum = 0 AND ISNULL(SiteDBGroupID, 0) = @__siteDBGroupId
			GROUP BY custid
		),
		q4 AS (
			SELECT custid, SUM(CASE WHEN statusid = 0 then -actual_stake ELSE winlost-actual_stake+playercomm END) BalLC
			FROM dbo.bettransLC WITH(NOLOCK)
			WHERE IsSum = 0 AND ISNULL(SiteDBGroupID, 0) = @__siteDBGroupId
			GROUP BY custid
		), 
		t AS (
			SELECT custid, SUM(Amount) AS adjustWinlostAmt
			FROM dbo.BonusAdjustmentTransfer WITH(NOLOCK)
			WHERE isTransferred = 0
			GROUP BY custid
		) 

		INSERT INTO #tmpCal(custid, Outstanding, BalRNG, BalLC, adjustWinlostAmt)
		SELECT ISNULL(q2.custid, ISNULL(q3.custid, ISNULL(q4.custid, t.CustId))) custid, SUM(ISNULL(Outstanding, 0)) Outstanding
			, SUM(ISNULL(BalRNG, 0)) BalRNG, SUM(ISNULL(BalLC, 0)) BalLC, SUM(ISNULL(adjustWinlostAmt, 0)) adjustWinlostAmt
		FROM q2 FULL OUTER JOIN q3 ON q2.custid = q3.custid
		FULL OUTER JOIN q4 ON q2.custid = q4.custid
		FULL OUTER JOIN t ON q2.custid = t.CustID
		GROUP BY ISNULL(q2.custid, ISNULL(q3.custid, ISNULL(q4.custid, t.CustId)))

		CREATE CLUSTERED INDEX CIX_t ON #tmpCal (custid)

		DECLARE @__movebetdate SMALLDATETIME
		EXEC dbo.NAP_Admin_GetMovebetDate @MovebetDate = @__movebetdate OUTPUT

		DECLARE @__balanceupdate SMALLDATETIME
		EXEC dbo.NAP_Admin_GetBalanceUpDate @BalanceUpDate = @__balanceupdate OUTPUT

		__tryagain:
		IF OBJECT_ID('tempdb.dbo.#QuestionLists') IS NOT NULL
			DROP TABLE #QuestionLists

		CREATE TABLE #QuestionLists(custid INT, balance MONEY, RowVersion INT, Outstanding MONEY, BalRNG MONEY
			, BalLC MONEY, FromBalanceTable MONEY, adjustWinlostAmt MONEY)

		;WITH
		cb AS (
			SELECT b.custid, SUM(winlost-actual_stake+playercomm) Balance
			FROM dbo.bettrans b WITH (NOLOCK)
			WHERE 1 = CASE WHEN bettype >= 19999 THEN 0 --> get from transfer table
					 WHEN bettype < 19999 AND winlostdate <= @__movebetdate THEN 0 --> old bet
					 ELSE 1 END
				AND ISNULL(b.SiteDBGroupID, 0) = @__siteDBGroupId
			GROUP BY b.custid
		),
		ct AS (
			SELECT t.custid, SUM(winlost-actual_stake+playercomm) AS Balance
			FROM dbo.Transfer t WITH(NOLOCK)
				LEFT JOIN CustDB.dbo.Dep_CustSuper s WITH(NOLOCK) ON t.SRecommend = s.custid
			WHERE 1 = CASE WHEN bettype = 19999 AND winlostdate > @__movebetdate THEN 0 --> new sum
						   WHEN bettype = 20000 AND WinlostDate > @__balanceupdate THEN 0 --> new balanceup record
						   WHEN WinlostDate < @__balanceupdate THEN 0 --> old data
					 ELSE 1 END
				AND ISNULL(s.SiteDBGroupID, 0) = @__siteDBGroupId
			GROUP BY t.custid
		)
		INSERT INTO #QuestionLists(custid, balance, RowVersion, Outstanding, BalRNG, BalLC, FromBalanceTable, adjustWinlostAmt)
		SELECT cb.custid, cb.balance, cb.RowVersion, ISNULL(qq.Outstanding,0) Outstanding, ISNULL(qq.BalRNG, 0) BalRNG, ISNULL(qq.BalLC, 0) BalLC, 
		   cd1.Balance + cd2.Balance + cd3.Balance + cd4.Balance 
		   - db1.Balance - db2.Balance - db3.Balance - db4.Balance AS FromBalanceTable
		   , ISNULL(adjustWinlostAmt, 0) adjustWinlostAmt
		FROM (
			SELECT ISNULL(cb.custid, ct.CustId) custid, SUM(ISNULL(cb.balance, 0) + ISNULL(ct.balance, 0)) balance, 0 as RowVersion
			FROM cb FULL OUTER JOIN ct ON cb.custid = ct.CustId
			GROUP BY ISNULL(cb.custid, ct.CustId)
		)cb	
			INNER JOIN dbo.BalCreditTransfer cd1 with (nolock) ON cb.custid = cd1.custid
			INNER JOIN dbo.BalCreditSports cd2 with (nolock) ON cb.custid = cd2.custid
			INNER JOIN dbo.BalCreditCasino cd3 with (nolock) ON cb.custid = cd3.custid
			INNER JOIN dbo.BalCreditOthers cd4 with (nolock) ON cb.custid = cd4.custid
			INNER JOIN dbo.BalDebitTransfer db1 with (nolock) ON cb.custid = db1.custid
			INNER JOIN dbo.BalDebitSports db2 with (nolock) ON cb.custid = db2.custid
			INNER JOIN dbo.BalDebitCasino db3 with (nolock) ON cb.custid = db3.custid
			INNER JOIN dbo.BalDebitOthers db4 with (nolock) ON cb.custid = db4.custid
			LEFT OUTER JOIN #tmpCal qq ON cb.custid = qq.custid
		WHERE
			cb.Balance - ISNULL(qq.Outstanding,0) + ISNULL(qq.BalRNG, 0) + ISNULL(qq.BalLC, 0) - ISNULL(adjustWinlostAmt, 0) <> cd1.Balance + cd2.Balance + cd3.Balance + cd4.Balance - db1.Balance - db2.Balance - db3.Balance - db4.Balance
			AND NOT EXISTS (SELECT 1 FROM dbo.Task_Cust_CheckBalance_Exception ex with (nolock) WHERE cb.custid = ex.custid)

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

		--//get BalanceUpDate again if it was changed
		DECLARE @__balanceupdateF SMALLDATETIME
		EXEC dbo.NAP_Admin_GetBalanceUpDate @BalanceUpDate = @__balanceupdateF OUTPUT
		IF @__balanceupdate <> @__balanceupdateF
		BEGIN
			SET @__balanceupdate = @__balanceupdateF
			GOTO __tryagain
		END

		-- remove settlement involvement
		IF  EXISTS (SELECT 1 FROM #QuestionLists)
			AND
			EXISTS (SELECT 1 FROM TempVariableNumber WHERE KeyID = 1)
		BEGIN
			;WITH m AS (SELECT CAST(KeyValue as int) matchid FROM TempVariableNumber WHERE KeyID = 1)
			DELETE q
			FROM #QuestionLists q
			WHERE EXISTS (
				SELECT 1 
				FROM dbo.bettrans b WITH (NOLOCK) 
				INNER JOIN m ON b.matchid = m.matchid AND b.custid = q.custid
			)
			
			SET @RD = @RD + @@ROWCOUNT
		END

		SELECT @__movebetdate = @__movebetdateF, @__balanceupdate = @__balanceupdateF
		-- check one more time (with less accounts)
		;WITH
		cb AS (
			SELECT b.custid, SUM(winlost-actual_stake+playercomm) Balance, 0 as RowVersion
			FROM dbo.bettrans b WITH (NOLOCK)
				INNER JOIN #QuestionLists q ON b.custid = q.custid
			WHERE 1 = CASE WHEN bettype >= 19999 THEN 0 --> get from transfer table
					 WHEN bettype < 19999 AND winlostdate <= @__movebetdate THEN 0 --> old bet
					 ELSE 1 END
				AND ISNULL(b.SiteDBGroupID, 0) = @__siteDBGroupId
			GROUP BY b.custid
		),
		ct AS (
			SELECT t.custid, SUM(winlost-actual_stake+playercomm) Balance
			FROM dbo.Transfer t WITH (NOLOCK)
				INNER JOIN #QuestionLists q ON t.custid = q.custid
				LEFT JOIN CustDB.dbo.Dep_CustSuper c WITH(NOLOCK) ON t.SRecommend = c.custid
			WHERE 1 = CASE WHEN bettype = 19999 AND winlostdate > @__movebetdate THEN 0 --> new sum
						   WHEN bettype = 20000 AND WinlostDate > @__balanceupdate THEN 0 --> new balanceup record
						   WHEN WinlostDate < @__balanceupdate THEN 0 --> old data
					 ELSE 1 END
				AND ISNULL(c.SiteDBGroupID, 0) = @__siteDBGroupId
			GROUP BY t.custid
		),
		q2 AS (
			-- translog
			SELECT tl.custid, SUM(actual_stake) AS Outstanding
			FROM dbo.translog tl with (nolock)
			WHERE tl.statusID IN (0,1) --summary running tickets only
				AND ISNULL(tl.SiteDBGroupID, 0) = @__siteDBGroupId
			GROUP BY tl.custid
		),
		q3 AS (
			SELECT custid, SUM(CASE WHEN statusid = 0 then -actual_stake ELSE winlost-actual_stake+playercomm END) BalRNG
			FROM dbo.bettransRNG WITH(NOLOCK)
			WHERE IsSum = 0 AND ISNULL(SiteDBGroupID, 0) = @__siteDBGroupId
			GROUP BY custid
		),
		q4 AS (
			SELECT custid, SUM(CASE WHEN statusid = 0 then -actual_stake ELSE winlost-actual_stake+playercomm END) BalLC
			FROM dbo.bettransLC WITH(NOLOCK)
			WHERE IsSum = 0 AND ISNULL(SiteDBGroupID, 0) = @__siteDBGroupId
			GROUP BY custid
		),
		t AS (
			SELECT custid, SUM(Amount) AS adjustWinlostAmt
			FROM dbo.BonusAdjustmentTransfer WITH(NOLOCK)
			WHERE isTransferred = 0
			GROUP BY custid
		)
		INSERT INTO dbo.Task_Cust_CheckBalanceVerify1(custid, roundVerified, MaxRowVersion, DiffBalance)
		SELECT cb.custid, 0, RowVersion, 
		   cb.Balance - ISNULL(q2.Outstanding,0) + ISNULL(BalRNG, 0) + ISNULL(BalLC, 0) - ISNULL(t.adjustWinlostAmt, 0)
		   - (cd1.Balance + cd2.Balance + cd3.Balance + cd4.Balance - db1.Balance - db2.Balance - db3.Balance - db4.Balance)
		FROM (
			SELECT ISNULL(cb.custid, ct.CustId) custid, SUM(ISNULL(cb.balance, 0) + ISNULL(ct.balance, 0)) balance, 0 as RowVersion
			FROM cb FULL OUTER JOIN ct ON cb.custid = ct.CustId
			GROUP BY ISNULL(cb.custid, ct.CustId)
		)cb
			INNER JOIN dbo.BalCreditTransfer cd1 with (nolock) ON cb.custid = cd1.custid
			INNER JOIN dbo.BalCreditSports cd2 with (nolock) ON cb.custid = cd2.custid
			INNER JOIN dbo.BalCreditCasino cd3 with (nolock) ON cb.custid = cd3.custid
			INNER JOIN dbo.BalCreditOthers cd4 with (nolock) ON cb.custid = cd4.custid
			INNER JOIN dbo.BalDebitTransfer db1 with (nolock) ON cb.custid = db1.custid
			INNER JOIN dbo.BalDebitSports db2 with (nolock) ON cb.custid = db2.custid
			INNER JOIN dbo.BalDebitCasino db3 with (nolock) ON cb.custid = db3.custid
			INNER JOIN dbo.BalDebitOthers db4 with (nolock) ON cb.custid = db4.custid
			LEFT OUTER JOIN q2 ON cb.custid = q2.custid
			LEFT OUTER JOIN q3 ON cb.custid = q3.custid
			LEFT OUTER JOIN q4 ON cb.custid = q4.custid	
			LEFT OUTER JOIN t ON cb.custid = t.CustID		
		WHERE
			cb.Balance - ISNULL(q2.Outstanding,0) + ISNULL(BalRNG, 0) + ISNULL(BalLC, 0) - ISNULL(t.adjustWinlostAmt, 0) <> cd1.Balance + cd2.Balance + cd3.Balance + cd4.Balance - db1.Balance - db2.Balance - db3.Balance - db4.Balance
			AND NOT EXISTS (SELECT 1 FROM dbo.Task_Cust_CheckBalance_Exception ex with (nolock) WHERE cb.custid = ex.custid)
			AND NOT EXISTS (SELECT 1 FROM dbo.BalCreditSportsPending cdp2 with (nolock) WHERE cb.custid = cdp2.custid)
			AND NOT EXISTS (SELECT 1 FROM dbo.BalCreditCasinoPending cdp3 with (nolock) WHERE cb.custid = cdp3.custid)
			AND NOT EXISTS (SELECT 1 FROM dbo.BalCreditOthersPending cdp4 with (nolock) WHERE cb.custid = cdp4.custid)
			AND NOT EXISTS (SELECT 1 FROM dbo.BalDebitSportsPending dbp2 with (nolock) WHERE cb.custid = dbp2.custid)
			AND NOT EXISTS (SELECT 1 FROM dbo.BalDebitCasinoPending dbp3 with (nolock) WHERE cb.custid = dbp3.custid)
			AND NOT EXISTS (SELECT 1 FROM dbo.BalDebitOthersPending dbp4 with (nolock) WHERE cb.custid = dbp4.custid)
		
		SET @msg = @msg + ' -' + CAST(@RD as varchar(50)) + ' -> ' + CAST(@@ROWCOUNT as varchar(50)) + ' accounts add to verify balance'

		DELETE t
		FROM dbo.Task_Cust_CheckBalanceVerify1 t WITH(ROWLOCK)
			INNER JOIN CustDB.dbo.Customer c WITH(NOLOCK) ON t.custid = c.custid
		WHERE EXISTS (SELECT TOP 1 1 FROM dbo.CS_CustSuper cs WITH(NOLOCK) WHERE c.srecommend = cs.CustId)

		PRINT @msg + ' -' + CAST(@@ROWCOUNT as varchar(50)) + ' accounts of CN88 was deleted from verify balance list'
	
		DROP TABLE #tmpCal
		DROP TABLE #QuestionLists

	END
END
GO


