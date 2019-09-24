SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE [dbo].[Task_CheckBalance]
	@Step tinyint = 0,
	@Action varchar(20) = 'JustLog', -- 'JustFix', 'LogAndFix'
	@custid int = 0 
AS
/*
	Revision: 
		-- 20131108@Elodie: Splitting bodb02 into CustDB (call custinfo by link database)
		-- 20140212@Vivi: add summary [translog] keno outstanding
*/
SET NOCOUNT ON

Declare --@FromBalanceTable money, 
		@FromBettrans money, 
		@DiffBalance money,
		@FromTransLog money
		
IF @custid > 0
BEGIN
	IF @Action = 'LogAndFix'
	BEGIN
		INSERT INTO dbo.Task_Cust_CheckBalanceVerify (custid) VALUES (@custid)
		
				EXEC dbo.Task_CheckBalance @Step = 3, @Action = 'LogAndFix'
		
		RETURN	
	END
	
	-- @FromBettrans
	SELECT @FromBettrans = SUM(winlost-actual_stake+playercomm)
	FROM dbo.bettrans with (rowlock)
	WHERE custid = @custid

	-- @FromTransLog: KENO outstanding
	SELECT @FromTransLog = SUM(actual_stake)
	FROM dbo.translog with (nolock)
	WHERE custid = @custid and statusID = 0
	
	SELECT @custid custid, c.username,
		(isnull(@FromBettrans,0)-isnull(@FromTransLog,0)) FromBettrans,	--20140213@Vivi: deduct keno outstanding
		cd.Balance - db.Balance FromBalanceTable,
		(isnull(@FromBettrans,0)-isnull(@FromTransLog,0)) - (cd.Balance - db.Balance) Diff
	FROM
		CustDB.dbo.custinfo c with (nolock)
		INNER JOIN dbo.BalanceCredit cd with (nolock) ON c.custid = cd.custid
		INNER JOIN dbo.BalanceDebit  db with (nolock) ON c.custid = db.custid
	WHERE
		c.custid = @custid
	
	RETURN
END

IF @Step = 99
-- run through all step automatic
BEGIN
		EXEC dbo.Task_CheckBalance @Step = 1
		EXEC dbo.Task_CheckBalance @Step = 2
		EXEC dbo.Task_CheckBalance @Step = 33, @Action = @Action
		EXEC dbo.Task_CheckBalance @Step = 5
END
ELSE IF @Step = 33
BEGIN
	WHILE EXISTS (SELECT 1 FROM dbo.Task_Cust_CheckBalanceVerify)
	BEGIN
				EXEC dbo.Task_CheckBalance @Step = 3, @Action = @Action
	END
END
ELSE IF @Step = 1 -- Get List of Customer & Balance
BEGIN
	DELETE FROM dbo.Task_Cust_CheckBalance

	INSERT INTO dbo.Task_Cust_CheckBalance (custid, FromBettrans, FromTransLog)
	SELECT c.custid, SUM(winlost-actual_stake+playercomm), 0
	FROM dbo.bettrans b with (nolock)
		INNER JOIN CustDB.dbo.custinfo c with (nolock) ON b.custid = c.custid AND c.roleid = 1
	GROUP BY c.custid

	-- translog
	CREATE TABLE #translog (custid int primary key, outstanding	money)

	INSERT INTO #translog (custid, outstanding)
	SELECT c.custid, SUM(actual_stake)
	FROM dbo.translog tl with (nolock)
		INNER JOIN CustDB.dbo.custinfo c with (nolock) ON tl.custid = c.custid AND c.roleid = 1 and tl.statusID=0 --summary running tickets only
	GROUP BY c.custid

	UPDATE cb
	SET FromTransLog = outstanding
	FROM
		dbo.Task_Cust_CheckBalance cb
		INNER JOIN #translog tl with (nolock) ON cb.custid = tl.custid
END
ELSE IF @Step = 2 -- 1st round : check BalanceBettrans -vs- BalanceTable , Then save list to verify
BEGIN
	UPDATE cb
	SET FromBalanceTable = cd.Balance - db.Balance
	FROM
		dbo.Task_Cust_CheckBalance cb
		INNER JOIN dbo.BalanceCredit cd with (nolock) ON cb.custid = cd.custid
		INNER JOIN dbo.BalanceDebit  db with (nolock) ON cb.custid = db.custid

	DELETE FROM dbo.Task_Cust_CheckBalanceVerify

	INSERT INTO dbo.Task_Cust_CheckBalanceVerify (custid)
	SELECT custid
	FROM dbo.Task_Cust_CheckBalance with (nolock)
	WHERE (FromBettrans-FromTransLog) <> FromBalanceTable --20140213@Vivi: deduct keno outstanding
END
ELSE IF @Step = 3 -- 2nd round : verify each a/c one by one
BEGIN
	--
	-- Get @custid
	--
	SELECT TOP 1 @custid = custid
	FROM dbo.Task_Cust_CheckBalanceVerify with (nolock)

	DELETE FROM dbo.Task_Cust_CheckBalanceVerify WHERE custid = @custid

	--
	-- Get/Compare Balance
	--

	-- @FromBettrans
	SELECT @FromBettrans = SUM(winlost-actual_stake+playercomm)
	FROM dbo.bettrans with (rowlock)
	WHERE custid = @custid
	
	-- @FromTransLog: KENO outstanding
	SELECT @FromTransLog = SUM(actual_stake)
	FROM dbo.translog with (nolock)
	WHERE custid = @custid and statusID = 0

	SELECT --@FromBalanceTable = cd.Balance - db.Balance
		@DiffBalance = IsNull(@FromBettrans, 0) - IsNull(@FromTransLog, 0) - (cd.Balance - db.Balance)
	FROM dbo.BalanceCredit cd with (nolock)
		INNER JOIN dbo.BalanceDebit db with (nolock) ON cd.custid = db.custid
	WHERE
		cd.custid = @custid
		AND db.custid = @custid
	
	--
	-- Take Action accordingly
	--
	IF @DiffBalance <> 0 --(@FromBettrans-@FromTransLog) <> @FromBalanceTable
	BEGIN
		IF NOT EXISTS (
			SELECT 1 FROM dbo.BalancePendingCredit WHERE custid = @custid
			UNION
			SELECT 1 FROM dbo.BalancePendingDebit  WHERE custid = @custid
		)
		BEGIN
			IF @Action IN ('JustLog', 'LogAndFix')
				INSERT INTO dbo.Task_Cust_BalanceProblem (custid, DiffBalance, Remark)
				SELECT
					@custid, @DiffBalance,
					CASE @Action
					WHEN 'LogAndFix' THEN 'Fixed by LogAndFix'
					ELSE '' END
			
			IF @Action IN ('JustFix', 'LogAndFix')
			BEGIN
				IF @DiffBalance > 0
					INSERT INTO dbo.BalancePendingCredit (custid, Balance) VALUES (@custid, @DiffBalance)
				ELSE
					INSERT INTO dbo.BalancePendingDebit  (custid, Balance) VALUES (@custid,-@DiffBalance)

				update task_cust_balanceproblem
				set remark = 'Reset ON ' + CONVERT(varchar(10), current_timestamp, 120)
				where remark = '' and custid = @custid

			END	
		END		
	END	
END
ELSE IF @Step = 4 -- check if need to continue
BEGIN
	IF EXISTS (SELECT 1 FROM dbo.Task_Cust_CheckBalanceVerify)
		-- raiserror here to continue to next step of jobs
		RAISERROR ('* no more data *', -- Message text.
				   16, -- Severity.
				   1 -- State.
				   );	
END
ELSE IF @Step = 5 -- Finishing
BEGIN
	UPDATE bp
	SET username = c.username
	FROM CustDB.dbo.custinfo c with (nolock)
		INNER JOIN dbo.Task_Cust_BalanceProblem bp ON c.custid = bp.custid AND bp.username IS NULL

	UPDATE bp
	SET remark = c.Remark
	FROM dbo.Task_Cust_CheckBalance_Exception c
		INNER JOIN dbo.Task_Cust_BalanceProblem bp ON c.custid = bp.custid
	WHERE
		bp.remark = ''
	
/*
	UPDATE bp
	SET remark = 'UUS'
	FROM dbo.custinfo c with (nolock)
		INNER JOIN dbo.Task_Cust_BalanceProblem bp ON c.custid = bp.custid
	WHERE
		c.currency = 20 AND bp.remark = ''
*/
END
GO
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/