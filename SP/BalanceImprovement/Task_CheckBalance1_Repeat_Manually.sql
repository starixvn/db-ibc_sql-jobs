/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isNested="0"></info>*/
USE [bodb02]
GO
CREATE PROCEDURE [dbo].[Task_CheckBalance1_Repeat_Manually]
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
	   
	Note: Does not correct data, only dectect different between bettrans and Balance table

	Param use:

	Logic & Process:
		compute balance for member in question
		update/increase counter + update diff value
		remove member not having problem (after 3 round verified)
		loop to fix(One) any member having round verified >= 5
*/
SET NOCOUNT ON

;WITH
cb AS (
	SELECT b.custid, SUM(winlost-actual_stake+playercomm) Balance
	FROM dbo.bettrans b with (nolock)
		--INNER JOIN CustDB.dbo.custinfo c with (nolock) ON b.custid = c.custid AND c.roleid = 1
		INNER JOIN dbo.Task_Cust_CheckBalanceVerify1_Manually q ON b.custid = q.custid
	GROUP BY b.custid
),
q2 AS (
	-- translog
	SELECT tl.custid, SUM(actual_stake) AS Outstanding
	FROM dbo.translog tl with (nolock)
		--INNER JOIN CustDB.dbo.custinfo c with (nolock) ON tl.custid = c.custid AND c.roleid = 1 and
	WHERE tl.statusID IN (0,1) --summary running tickets only
	GROUP BY tl.custid
),
q3 AS (
	SELECT custid, SUM(CASE WHEN statusid = 0 then -actual_stake ELSE winlost-actual_stake+playercomm END) BalRNG
	FROM dbo.bettransRNG WITH(NOLOCK)
	WHERE IsSum = 0
	GROUP BY custid
),
q4 AS (
	SELECT custid, SUM(CASE WHEN statusid = 0 then -actual_stake ELSE winlost-actual_stake+playercomm END) BalLC
	FROM dbo.bettransLC WITH(NOLOCK)
	WHERE IsSum = 0
	GROUP BY custid
),
t AS (
	SELECT custid, SUM(Amount) AS adjustWinlostAmt
	FROM dbo.BonusAdjustmentTransfer WITH(NOLOCK)
	WHERE isTransferred = 0
	GROUP BY custid
) 
SELECT cb.*, ISNULL(q2.Outstanding,0) Outstanding, ISNULL(q3.BalRNG, 0) BalRNG, ISNULL(q4.BalLC, 0) BalLC, ISNULL(t.adjustWinlostAmt, 0) adjustWinlostAmt,
    cd1.Balance + cd2.Balance + cd3.Balance + cd4.Balance - db1.Balance - db2.Balance - db3.Balance - db4.Balance AS FromBalanceTable
INTO #QuestionLists
FROM cb
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
UPDATE cb
SET roundVerified = 
		CASE q.Balance-q.Outstanding+BalRNG+BalLC+adjustWinlostAmt-q.FromBalanceTable
		WHEN cb.DiffBalance THEN roundVerified + 1 -- if Diff value remain the same amount, increase counter, ELSE reset counter
		ELSE 0 END,
	DiffBalance = q.Balance-q.Outstanding+BalRNG+BalLC+adjustWinlostAmt-q.FromBalanceTable -- update new Diff
FROM dbo.Task_Cust_CheckBalanceVerify1_Manually cb
	INNER JOIN #QuestionLists q ON cb.custid = q.custid

DROP TABLE #QuestionLists

DELETE FROM dbo.Task_Cust_CheckBalanceVerify1_Manually
WHERE DiffBalance = 0 AND roundVerified >= 3 -- remove record, if compare and no diff for 3 times

IF NOT EXISTS (SELECT 1 FROM dbo.Task_Cust_CheckBalanceVerify1_Manually)
BEGIN
	-- GENERATE ERROR TO STOP PROCESS.
	-- raiserror here to continue to next step of jobs
	RAISERROR ('* no more data *', -- Message text.
               16, -- Severity.
               1 -- State.
               );
END
ELSE IF EXISTS (SELECT 1 FROM dbo.Task_Cust_CheckBalanceVerify1_Manually WHERE roundVerified >= 5)
BEGIN
	PRINT 'Start FixOne'
	Declare @i int, @maxRN int, @custid int, @roundVerified int, @DiffBalance money, @result int, @IsUUS bit
	
	CREATE TABLE #c (RN int IDENTITY(1,1) PRIMARY KEY, custid int, roundVerified int)
	INSERT INTO #c (custid, roundVerified) SELECT custid, roundVerified FROM dbo.Task_Cust_CheckBalanceVerify1_Manually WHERE roundVerified >= 5
	SELECT @maxRN = @@ROWCOUNT
	SET @i = 1
	
	WHILE @i <= @maxRN
	BEGIN
		SELECT @custid = custid, @roundVerified = roundVerified FROM #c WHERE RN = @i
		--just call sp to return diff balance amount. This sp dont correct data
		EXEC dbo.Task_CheckBalance1_FixOne_Manually @custid, @DiffBalance OUTPUT, @result OUTPUT, @IsUUS OUTPUT
		
		IF @result = 0
		BEGIN
			DELETE FROM dbo.Task_Cust_CheckBalanceVerify1_Manually WHERE custid = @custid

			-- LOG
			INSERT INTO dbo.Task_Cust_BalanceProblem1_Manually (UserName, custid, DiffBalance, IsFixed, Remark)
			SELECT
				username, @custid, @DiffBalance, 0, 'roundVerified = ' + CAST(@roundVerified as varchar(50)) + CASE @IsUUS WHEN 1 THEN ' UUS' ELSE '' END
			FROM
				CustDB.dbo.custInfo with (nolock)
			WHERE
				custid = @custid

		END
		
		SET @i = @i + 1
	END
END
GO


