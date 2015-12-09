USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Task_CheckBalance_Repeat]    Script Date: 12/07/2015 23:00:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_CheckBalance_Repeat]
AS
/*
	Task: Compute/Compare balance vs BalanceTable for detected account
	Original: Task_CheckBalance_Repeat
	Location: DBTXN.bodb02

	Revision:
		20151210@Daniel: calc balance from table bettransRNG & bettransLC 

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
		SELECT b.custid, SUM(winlost-actual_stake+playercomm) Balance, MAX(tstamp) as RowVersion
		FROM dbo.bettrans b with (nolock)
			INNER JOIN dbo.Task_Cust_CheckBalanceVerify q ON b.custid = q.custid
		GROUP BY b.custid
	),
	q2 AS (
		-- translog
		SELECT tl.custid, SUM(actual_stake) AS Outstanding
		FROM dbo.translog tl with (nolock)
		WHERE tl.statusID=0 --summary running tickets only
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
	)
	SELECT cb.*, ISNULL(q2.Outstanding,0) Outstanding, ISNULL(q3.BalRNG, 0) BalRNG, ISNULL(q4.BalLC, 0) BalLC,
		cd.Balance - db.Balance AS FromBalanceTable
	INTO #QuestionLists
	FROM cb
		INNER JOIN dbo.BalanceCredit cd with (nolock) ON cb.custid = cd.custid
		INNER JOIN dbo.BalanceDebit  db with (nolock) ON cb.custid = db.custid
		LEFT OUTER JOIN q2 ON cb.custid = q2.custid
		LEFT OUTER JOIN q3 ON cb.custid = q3.custid
		LEFT OUTER JOIN q4 ON cb.custid = q4.custid
	UPDATE cb
	SET roundVerified = 
			CASE q.Balance-q.Outstanding+BalRNG+BalLC-q.FromBalanceTable
			WHEN cb.DiffBalance THEN roundVerified + 1 -- if Diff value remain the same amount, increase counter, ELSE reset counter
			ELSE 0 END,
		DiffBalance = q.Balance-q.Outstanding+BalRNG+BalLC-q.FromBalanceTable -- update new Diff
	FROM dbo.Task_Cust_CheckBalanceVerify cb
		INNER JOIN #QuestionLists q ON cb.custid = q.custid
	
	DROP TABLE #QuestionLists

	DELETE FROM dbo.Task_Cust_CheckBalanceVerify
	WHERE DiffBalance = 0 AND roundVerified >= 3 -- remove record, if compare and no diff for 3 times



IF NOT EXISTS (SELECT 1 FROM dbo.Task_Cust_CheckBalanceVerify)
BEGIN
	-- GENERATE ERROR TO STOP PROCESS.
	-- raiserror here to continue to next step of jobs
	RAISERROR ('* no more data *', -- Message text.
               16, -- Severity.
               1 -- State.
               );
END
ELSE IF EXISTS (SELECT 1 FROM dbo.Task_Cust_CheckBalanceVerify WHERE roundVerified >= 5)
BEGIN
	PRINT 'Start FixOne'
	Declare @i int, @maxRN int, @custid int, @roundVerified int, @DiffBalance money, @result int, @IsUUS bit
	
	CREATE TABLE #c (RN int IDENTITY(1,1) PRIMARY KEY, custid int, roundVerified int)
	INSERT INTO #c (custid, roundVerified) SELECT custid, roundVerified FROM dbo.Task_Cust_CheckBalanceVerify WHERE roundVerified >= 5
	SELECT @maxRN = @@ROWCOUNT
	SET @i = 1
	
	WHILE @i <= @maxRN
	BEGIN
		SELECT @custid = custid, @roundVerified = roundVerified FROM #c WHERE RN = @i
		EXEC dbo.Task_CheckBalance_FixOne @custid, @DiffBalance OUTPUT, @result OUTPUT, @IsUUS OUTPUT
		
		IF @result = 0
		BEGIN
			DELETE FROM dbo.Task_Cust_CheckBalanceVerify WHERE custid = @custid

			-- LOG
			INSERT INTO dbo.Task_Cust_BalanceProblem (UserName, custid, DiffBalance, IsFixed, Remark)
			SELECT
				username, @custid, @DiffBalance, 1, 'roundVerified = ' + CAST(@roundVerified as varchar(50)) + CASE @IsUUS WHEN 1 THEN ' UUS' ELSE '' END
			FROM
				CustDB.dbo.custInfo with (nolock)
			WHERE
				custid = @custid

		END
		
		SET @i = @i + 1
	END
END