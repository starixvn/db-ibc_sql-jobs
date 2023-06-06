/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isNested="0"></info>*/
USE [bodb02]
GO
CREATE PROCEDURE [dbo].[Task_CheckBalance1_Repeat]
AS
/*
	Task: Compute/Compare balance vs BalanceTable for detected account
	Original: Task_CheckBalance_Repeat
	Location: DBTXN.bodb02

	Revision:
	   20150907@Daniel: Clone from Task_CheckBalance_Repeat & apply new set of bal tables
		20151210@Daniel: calc balance from table bettransRNG & bettransLC 
		20160112@Daniel: Remove redundant RowVersion MAX(tstamp)
		20170929@Patrick: Update code for Bonus project
		20171201@Patrick: Bullfighting - calc waiting ticket into outstanding amt on translog
		20190319@Patrick: Exclude CN88 account - push code to git [RedmineID: #110530]
		20210514@Patrick: Revise Movebet flow to support transfer 247 - Redmine: [#149927]
		20211231@Patrick: Split bettype >= 19999 out bettrans Redmine: [#164197]
		20220804@Patrick: Support scale-out for deposit site Redmine: [#175602]
		20221227@Patrick: Support BU 247 Redmine: [#182882]
	   
	Param use:

	Logic & Process:
		compute balance for member in question
		update/increase counter + update diff value
		remove member not having problem (after 3 round verified)
		loop to fix(One) any member having round verified >= 5
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @__movebetdate SMALLDATETIME, @__siteDBGroupId SMALLINT = 0
		, @__balanceupdate SMALLDATETIME
	EXEC dbo.NAP_Admin_GetMovebetDate @MovebetDate = @__movebetdate OUTPUT
	EXEC dbo.NAP_Admin_GetBalanceUpDate @BalanceUpDate = @__balanceupdate OUTPUT

	SELECT @__siteDBGroupId = dbo.f_Get_SiteDBGroupID()

	__tryagain:
	IF OBJECT_ID('tempdb.dbo.#QuestionLists') IS NOT NULL
		DROP TABLE #QuestionLists

	CREATE TABLE #QuestionLists(custid INT, balance MONEY, RowVersion INT, Outstanding MONEY, BalRNG MONEY
			, BalLC MONEY, FromBalanceTable MONEY, adjustWinlostAmt MONEY)
	;WITH
	cb AS (
		SELECT b.custid, SUM(winlost-actual_stake+playercomm) Balance
		FROM dbo.bettrans b WITH (NOLOCK)
			INNER JOIN dbo.Task_Cust_CheckBalanceVerify1 q ON b.custid = q.custid
		WHERE 1 = CASE WHEN bettype >= 19999 THEN 0 --> get from transfer table
					 WHEN bettype < 19999 AND winlostdate <= @__movebetdate THEN 0 --> old bet
					 ELSE 1 END
			AND ISNULL(b.SiteDBGroupID, 0) = @__siteDBGroupId
		GROUP BY b.custid
	),
	ct AS (
		SELECT t.custid, SUM(winlost-actual_stake+playercomm) Balance
		FROM dbo.Transfer t WITH (NOLOCK)
			INNER JOIN dbo.Task_Cust_CheckBalanceVerify1 q ON t.custid = q.custid
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
	INSERT INTO #QuestionLists(custid, balance, RowVersion, Outstanding, BalRNG, BalLC, adjustWinlostAmt, FromBalanceTable)
	SELECT cb.custid, cb.balance, cb.RowVersion, ISNULL(q2.Outstanding,0) Outstanding, ISNULL(q3.BalRNG, 0) BalRNG, ISNULL(q4.BalLC, 0) BalLC, ISNULL(t.adjustWinlostAmt, 0) adjustWinlostAmt,
		cd1.Balance + cd2.Balance + cd3.Balance + cd4.Balance - db1.Balance - db2.Balance - db3.Balance - db4.Balance AS FromBalanceTable
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

	UPDATE cb
	SET roundVerified = 
			CASE q.Balance-q.Outstanding+BalRNG+BalLC-adjustWinlostAmt-q.FromBalanceTable
			WHEN cb.DiffBalance THEN roundVerified + 1 -- if Diff value remain the same amount, increase counter, ELSE reset counter
			ELSE 0 END,
		DiffBalance = q.Balance-q.Outstanding+BalRNG+BalLC-adjustWinlostAmt-q.FromBalanceTable -- update new Diff
	FROM dbo.Task_Cust_CheckBalanceVerify1 cb
		INNER JOIN #QuestionLists q ON cb.custid = q.custid

	DROP TABLE #QuestionLists

	DELETE FROM dbo.Task_Cust_CheckBalanceVerify1
	WHERE DiffBalance = 0 AND roundVerified >= 3 -- remove record, if compare and no diff for 3 times

	IF NOT EXISTS (SELECT 1 FROM dbo.Task_Cust_CheckBalanceVerify1)
	BEGIN
		-- GENERATE ERROR TO STOP PROCESS.
		-- raiserror here to continue to next step of jobs
		RAISERROR ('* no more data *', -- Message text.
				   16, -- Severity.
				   1 -- State.
				   );
	END
	ELSE IF EXISTS (SELECT 1 FROM dbo.Task_Cust_CheckBalanceVerify1 WHERE roundVerified >= 5)
	BEGIN
		PRINT 'Start FixOne'
		Declare @i int, @maxRN int, @custid int, @roundVerified int
			, @DiffBalance money, @result int, @IsUUS bit, @DiffBalanceInput money
	
		CREATE TABLE #c (RN int IDENTITY(1,1) PRIMARY KEY, custid int, roundVerified int, DiffBalanceInput money)
		INSERT INTO #c (custid, roundVerified, DiffBalanceInput) SELECT custid, roundVerified, DiffBalance 
		FROM dbo.Task_Cust_CheckBalanceVerify1 WHERE roundVerified >= 5
		
		SELECT @maxRN = @@ROWCOUNT
		SET @i = 1
	
		WHILE @i <= @maxRN
		BEGIN
			SELECT @custid = custid, @roundVerified = roundVerified, @DiffBalanceInput = DiffBalanceInput
			FROM #c WHERE RN = @i
			
			EXEC dbo.Task_CheckBalance1_FixOne @custid = @custid
				, @DiffBalance = @DiffBalance OUTPUT
				, @result = @result OUTPUT
				, @IsUUS = @IsUUS OUTPUT
				, @DiffBalanceInput = @DiffBalanceInput
		
			IF @result = 0
			BEGIN
				DELETE FROM dbo.Task_Cust_CheckBalanceVerify1 WHERE custid = @custid

				-- LOG
				INSERT INTO dbo.Task_Cust_BalanceProblem1 (UserName, custid, DiffBalance, IsFixed, Remark)
				SELECT username, @custid, @DiffBalance, 1, 'roundVerified = ' + CAST(@roundVerified as varchar(50)) + CASE @IsUUS WHEN 1 THEN ' UUS' ELSE '' END
				FROM CustDB.dbo.custInfo with (nolock)
				WHERE custid = @custid

			END
			ELSE IF @result <> 0 AND @roundVerified > 21 --wont fix
			BEGIN
				DELETE FROM dbo.Task_Cust_CheckBalanceVerify1 WHERE custid = @custid

				INSERT INTO dbo.Task_Cust_BalanceProblem1 (UserName, custid, DiffBalance, IsFixed, Remark)
				SELECT username, @custid, @DiffBalanceInput, 0, 'wont fix, roundVerified = ' + CAST(@roundVerified as varchar(50)) + CASE WHEN currency = 20 THEN ' UUS' ELSE '' END + ', errCode = ' + CAST(@result AS VARCHAR(50))
				FROM CustDB.dbo.custInfo with (nolock)
				WHERE custid = @custid
			END
		
			SET @i = @i + 1
		END
	END
END
GO