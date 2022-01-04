/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isNested="0"></info>*/
USE [bodb02]
GO
ALTER PROCEDURE [dbo].[Task_CheckBalance1_Bonus_Repeat]
AS
/*
	Task: Compute/Compare balance vs BalanceTable of Bonus for detected account
	Original: Task_CheckBalance_Repeat
	Location: DBTXN.bodb02
	Revision:
		- 20180326@Patrick: Changes bettype from 22026, 22027 to 22200, 22201
		- 20210514@Patrick: Revise Movebet flow to support transfer 247 - Redmine: [#149927]
		- 20211231@Patrick: Split bettype >= 19999 out bettrans Redmine: [#164197]

	Param use:
	Logic & Process:
		compute balance for member in question
		update/increase counter + update diff value
		remove member not having problem (after 3 round verified)
		loop to fix(One) any member having round verified >= 5
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @__movebetdate SMALLDATETIME
	EXEC dbo.NAP_Admin_GetMovebetDate @MovebetDate = @__movebetdate OUTPUT

	__tryagain:
	IF OBJECT_ID('tempdb.dbo.#QuestionLists') IS NOT NULL
		DROP TABLE #QuestionLists

	CREATE TABLE #QuestionLists(custid INT, winlostAmt MONEY, BonusId INT, winlostAmtBalanceTable MONEY, RowVersion INT)

	;WITH
	cb AS (
		SELECT b.custid, b.BonusID, SUM(CASE WHEN walletType = 1 AND bettype NOT IN (22200, 22201) THEN winlost - actual_stake + playercomm ELSE 0 END) winlostAmt, 0 AS RowVersion
		FROM dbo.bettrans b WITH (NOLOCK)
			INNER JOIN dbo.Task_Cust_CheckBalanceVerify1_Bonus q ON b.custid = q.custid AND b.BonusID = q.BonusID
		WHERE b.BonusID > 0
			AND 1 = CASE WHEN bettype = 19999 AND winlostdate > @__movebetdate THEN 0 --> new sum
					 WHEN bettype < 19999 AND winlostdate <= @__movebetdate THEN 0 --> old bet
					 ELSE 1 END
		GROUP BY b.custid, b.BonusID
	), __bonus_sum_winloss_cte AS (
		SELECT b.CustId, b.BonusId, SUM(Amount) AS winlostAmt, 0 AS RowVersion
		FROM dbo.Bonus_sum_winloss b WITH(NOLOCK)
			INNER JOIN dbo.Task_Cust_CheckBalanceVerify1_Bonus q ON b.custid = q.custid AND b.BonusID = q.BonusID
		WHERE winlostdate <= @__movebetdate
		GROUP BY b.CustId, b.BonusId
	), ct AS (
		SELECT t.custid, ti.BonusID, SUM(CASE WHEN walletType = 1 AND bettype NOT IN (22200, 22201) THEN winlost - actual_stake + playercomm ELSE 0 END) winlostAmt
		FROM dbo.Transfer t WITH (NOLOCK)
			INNER JOIN dbo.TransferInfo ti WITH(NOLOCK) ON t.TransId = ti.TransId
		WHERE ti.BonusID > 0
			AND 1 = CASE WHEN bettype = 19999 AND winlostdate > @__movebetdate THEN 0 --> new sum
					ELSE 1 END
			AND EXISTS (SELECT TOP 1 1 FROM dbo.Task_Cust_CheckBalanceVerify1_Bonus q WHERE t.CustId = q.custid AND ti.BonusID = q.BonusId)
		GROUP BY t.custid, ti.BonusID
	)
	INSERT INTO #QuestionLists(custid, BonusId, winlostAmt, RowVersion, winlostAmtBalanceTable)
	SELECT cb.*, 0 AS RowVersion
		, (c1.Amount - d1.Amount) AS winlostAmtBalanceTable
	FROM (
		SELECT ISNULL(t.custid, tt.custid) AS CustId, ISNULL(t.BonusId, tt.BonusId) AS BonusId
			, SUM(ISNULL(t.winlostAmt, 0) + ISNULL(tt.winlostAmt, 0)) AS winlostAmt
		FROM (
			SELECT ISNULL(cb.custid, ct.CustId) custid, SUM(ISNULL(cb.winlostAmt, 0) + ISNULL(ct.winlostAmt, 0)) winlostAmt
				, ISNULL(cb.BonusId, ct.BonusId) BonusId
			FROM cb FULL OUTER JOIN ct ON cb.custid = ct.CustId AND cb.BonusId = ct.BonusId
			GROUP BY ISNULL(cb.custid, ct.CustId), ISNULL(cb.BonusId, ct.BonusId)
		) t 
		FULL OUTER JOIN __bonus_sum_winloss_cte tt ON t.custid = tt.CustId AND t.BonusID = tt.BonusId
		GROUP BY ISNULL(t.custid, tt.custid), ISNULL(t.BonusId, tt.BonusId)
	)cb INNER JOIN dbo.BonusWalletCredit c1 WITH (NOLOCK) ON cb.custid = c1.custid AND cb.BonusID = c1.BonusID
		INNER JOIN dbo.BonusWalletDebit d1 WITH (NOLOCK) ON cb.custid = d1.custid AND cb.BonusID = d1.BonusID

		--//get MovebetDate again if it was changed
	DECLARE @__movebetdateF SMALLDATETIME
	EXEC dbo.NAP_Admin_GetMovebetDate @MovebetDate = @__movebetdateF OUTPUT
	IF @__movebetdate <> @__movebetdateF
	BEGIN
		SET @__movebetdate = @__movebetdateF
		GOTO __tryagain
	END

	UPDATE cb
	SET roundVerified = 
			CASE q.winlostAmt - q.winlostAmtBalanceTable
			WHEN cb.DiffBalance THEN roundVerified + 1 -- if Diff value remain the same amount, increase counter, ELSE reset counter
			ELSE 0 END,
		DiffBalance = q.winlostAmt - q.winlostAmtBalanceTable -- update new Diff
	FROM dbo.Task_Cust_CheckBalanceVerify1_Bonus cb
		INNER JOIN #QuestionLists q ON cb.custid = q.custid AND cb.BonusID = q.BonusID

	DROP TABLE #QuestionLists

	DELETE FROM dbo.Task_Cust_CheckBalanceVerify1_Bonus
	WHERE DiffBalance = 0 AND roundVerified >= 3 -- remove record, if compare and no diff for 3 times

	IF NOT EXISTS (SELECT 1 FROM dbo.Task_Cust_CheckBalanceVerify1_Bonus)
	BEGIN
		-- GENERATE ERROR TO STOP PROCESS.
		-- raiserror here to continue to next step of jobs
		RAISERROR ('* no more data *', -- Message text.
				   16, -- Severity.
				   1 -- State.
				   );
	END
	ELSE IF EXISTS (SELECT 1 FROM dbo.Task_Cust_CheckBalanceVerify1_Bonus WHERE roundVerified >= 5)
	BEGIN
		PRINT 'Start FixOne'
		Declare @i int, @maxRN int, @custid int, @roundVerified int, @DiffBalance money, @bonusId int, @result int, @IsUUS bit
	
		CREATE TABLE #c (RN int IDENTITY(1,1) PRIMARY KEY, custid int, bonusId int, roundVerified int)
		INSERT INTO #c (custid, bonusId, roundVerified) 
		SELECT custid, bonusId, roundVerified 
		FROM dbo.Task_Cust_CheckBalanceVerify1_Bonus WHERE roundVerified >= 5
	
		SELECT @maxRN = @@ROWCOUNT
		SET @i = 1
	
		WHILE @i <= @maxRN
		BEGIN
			SELECT @custid = custid, @bonusId = bonusId, @roundVerified = roundVerified FROM #c WHERE RN = @i
			EXEC dbo.Task_CheckBalance1_Bonus_FixOne @custid, @bonusId, @DiffBalance OUTPUT, @result OUTPUT, @IsUUS OUTPUT
		
			IF @result = 0
			BEGIN
				DELETE FROM dbo.Task_Cust_CheckBalanceVerify1_Bonus WHERE custid = @custid AND bonusId = @bonusId

				-- LOG
				INSERT INTO dbo.Task_Cust_BalanceProblem1_Bonus (UserName, custid, bonusId, DiffBalance, IsFixed, Remark)
				SELECT username, @custid, @bonusId, @DiffBalance, 1, 'roundVerified = ' + CAST(@roundVerified as varchar(50)) + CASE @IsUUS WHEN 1 THEN ' UUS' ELSE '' END
				FROM CustDB.dbo.custInfo with (nolock)
				WHERE custid = @custid

			END
		
			SET @i = @i + 1
		END
	END
END