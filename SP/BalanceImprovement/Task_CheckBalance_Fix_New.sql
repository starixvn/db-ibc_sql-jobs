USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Task_CheckBalance_Fix]    Script Date: 08/31/2015 04:53:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Task_CheckBalance    Script Date: 12/24/2013 12:27:58 PM ******/
ALTER PROCEDURE [dbo].[Task_CheckBalance_Fix_New]
	@FixAll tinyint = 1
AS
/*
	Task: Correct member balance (balance tables) for mem listed in Task_Cust_CheckBalanceVerify
	Original: Task_CheckBalance
	Location: DBTXN.bodb02

	Revision: 
		20150525@Daniel: Clone from Task_CheckBalance & enhance fix process
		20150831@Daniel: new set of balance tables - redmine #40125

	Param use:
		+ @FixAll = 0: Fix top 1 affected member
		+ @FixAll = 1: Fix all affected members (recursive)

/* Test command:

*/

*/
SET NOCOUNT ON

IF(@FixAll = 1)
WHILE EXISTS (SELECT 1 FROM dbo.Task_Cust_CheckBalanceVerify_New)
BEGIN
	EXEC dbo.Task_CheckBalance_Fix_New @FixAll = 0
END
ELSE
BEGIN

	Declare --@FromBalanceTable money, 
			@FromBettrans money, 
			@DiffBalance money,
			@FromTransLog money
		

	-- 2nd round : verify each a/c one by one
	--
	-- Get @custid
	--

	DECLARE @custid int, @type tinyint

	SELECT TOP 1 @custid = custid, @type = [type]
	FROM dbo.Task_Cust_CheckBalanceVerify_New with (nolock)

	DELETE FROM dbo.Task_Cust_CheckBalanceVerify_New WHERE custid = @custid AND [type] = @type

	--
	-- Get/Compare Balance
	--
    IF (@type <> 0)
    BEGIN 
	   IF OBJECT_ID('tempdb..#ProdInfo') IS NOT NULL DROP TABLE #ProdInfo
	   SELECT DISTINCT bettype INTO #ProdInfo 
	   FROM SportBettypeMatrix WITH (NOLOCK)
	   WHERE 
	   	 CASE  
			 WHEN productID = 1 THEN 1 --SB
			 WHEN productID IN(4,6,11,12,13,14) THEN 2 --Casino
			 WHEN productID IN(2,3,5,7,8) THEN 3 --Others
			 ELSE 3 --All unknown put in Others 
		  END = @type
    END	

    IF (@type <> 0)
    BEGIN 	  	
	   --From bettrans
	   SELECT  
		  @FromBettrans = SUM(winlost-b.actual_stake+playercomm)
	   FROM bettrans b WITH (ROWLOCK)     
		  INNER JOIN #ProdInfo p ON b.bettype = p.bettype
	   WHERE b.custid IN(select custid from custDB.dbo.customer with (nolock) where roleid = 1) 
		   AND b.custid = @custID

	   --From translog
	   SELECT @FromTransLog = SUM(b.actual_stake)
	   FROM translog b WITH (NOLOCK) 
		  INNER JOIN #ProdInfo p ON b.GameID = p.bettype
	   WHERE b.statusid = 0
	    AND b.custid = @custID

    END
    ELSE
    BEGIN
	   --From bettrans
	   SELECT  
		  @FromBettrans = SUM(winlost-b.actual_stake+playercomm)
	   FROM bettrans b WITH (ROWLOCK)     
	   WHERE b.custid IN(select custid from custDB.dbo.customer with (nolock) where roleid = 1) 
		   AND b.bettype >= 19999 AND b.custid = @custID
    END

    DECLARE @BalCredit money, @BalDebit money
    
    IF (@type = 0)
    BEGIN
	   SELECT @BalCredit = Balance FROM dbo.BalCreditTransfer WITH (NOLOCK) WHERE custid = @custid
	   SELECT @BalDebit = Balance FROM dbo.BalDebitTransfer WITH (NOLOCK) WHERE custid = @custid
    END
    ELSE IF (@type = 1)
    BEGIN
	   SELECT @BalCredit = Balance FROM dbo.BalCreditSports WITH (NOLOCK) WHERE custid = @custid
	   SELECT @BalDebit = Balance FROM dbo.BalDebitSports WITH (NOLOCK) WHERE custid = @custid    
    END
    ELSE IF (@type = 2)
    BEGIN
	   SELECT @BalCredit = Balance FROM dbo.BalCreditCasino WITH (NOLOCK) WHERE custid = @custid
	   SELECT @BalDebit = Balance FROM dbo.BalDebitCasino WITH (NOLOCK) WHERE custid = @custid    
    END	   
    ELSE IF (@type = 3)
    BEGIN
	   SELECT @BalCredit = Balance FROM dbo.BalCreditOthers WITH (NOLOCK) WHERE custid = @custid
	   SELECT @BalDebit = Balance FROM dbo.BalDebitOthers WITH (NOLOCK) WHERE custid = @custid
    END
	
	SELECT @DiffBalance = IsNull(@FromBettrans, 0) - IsNull(@FromTransLog, 0) - (@BalCredit - @BalDebit)	
	--
	-- Take Action accordingly
	--
	IF @DiffBalance <> 0 --(@FromBettrans-@FromTransLog) <> @FromBalanceTable
	BEGIN
	   IF (@type = 1) 
	   BEGIN
		    IF NOT EXISTS (
			    SELECT 1 FROM dbo.BalCreditSportsPending WHERE custid = @custid
			    UNION
			    SELECT 1 FROM dbo.BalDebitSportsPending  WHERE custid = @custid
		    )
		    BEGIN		

			    --Check member has tickets bet on matches that are being calculated
			    IF EXISTS(
				    SELECT 1 FROM bettrans b WITH (NOLOCK) INNER JOIN #ProdInfo p ON b.bettype = p.bettype
				    WHERE custid = @custid AND matchid IN(SELECT KeyValue FROM TempVariableNumber WHERE KeyID = 1)
				    )
			    BEGIN			
				    INSERT INTO dbo.Task_Cust_BalanceProblem_New(custid, [type], DiffBalance, Remark)
				    SELECT
				    @custid, @type, @DiffBalance,'Skip fix to avoid conflict with settlement (Sportsbook)'
    						
				    UPDATE bp
				    SET username = c.username
				    FROM CustDB.dbo.custinfo c with (nolock)
					    INNER JOIN dbo.Task_Cust_BalanceProblem_New bp ON c.custid = bp.custid AND bp.username IS NULL

				    UPDATE bp
				    SET remark = c.Remark
				    FROM dbo.Task_Cust_CheckBalance_Exception c
					    INNER JOIN dbo.Task_Cust_BalanceProblem_New bp ON c.custid = bp.custid
				    WHERE bp.[type] = @type
					    AND bp.remark = ''

				    RETURN
			    END
    		
			    INSERT INTO dbo.Task_Cust_BalanceProblem_New (custid, [type], DiffBalance, Remark)
			    SELECT
			    @custid, @type, @DiffBalance,'Fixed by LogAndFix'		
    			
			    IF @DiffBalance > 0
				    INSERT INTO dbo.BalCreditSportsPending (custid, Balance) VALUES (@custid, @DiffBalance)
			    ELSE
				    INSERT INTO dbo.BalDebitSportsPending  (custid, Balance) VALUES (@custid, -@DiffBalance)

			    update Task_Cust_BalanceProblem_New
			    set remark = 'Reset ON ' + CONVERT(varchar(10), current_timestamp, 120)
			    where remark = '' and custid = @custid AND [type] = @type
		    END
    	   END
	   ELSE IF (@type = 2) 
	   BEGIN
		    IF NOT EXISTS (
			    SELECT 1 FROM dbo.BalCreditCasinoPending WHERE custid = @custid
			    UNION
			    SELECT 1 FROM dbo.BalDebitCasinoPending  WHERE custid = @custid
		    )
		    BEGIN		

			    --Check member has tickets bet on matches that are being calculated
			    IF EXISTS(
				    SELECT 1 FROM bettrans b WITH (NOLOCK) INNER JOIN #ProdInfo p ON b.bettype = p.bettype
				    WHERE custid = @custid AND matchid IN(SELECT KeyValue FROM TempVariableNumber WHERE KeyID = 1)
				    )
			    BEGIN			
				    INSERT INTO dbo.Task_Cust_BalanceProblem_New(custid, [type], DiffBalance, Remark)
				    SELECT
				    @custid, @type, @DiffBalance,'Skip fix to avoid conflict with settlement (Casino)'
    						
				    UPDATE bp
				    SET username = c.username
				    FROM CustDB.dbo.custinfo c with (nolock)
					    INNER JOIN dbo.Task_Cust_BalanceProblem_New bp ON c.custid = bp.custid AND bp.username IS NULL

				    UPDATE bp
				    SET remark = c.Remark
				    FROM dbo.Task_Cust_CheckBalance_Exception c
					    INNER JOIN dbo.Task_Cust_BalanceProblem_New bp ON c.custid = bp.custid
				    WHERE bp.[type] = @type
					    AND bp.remark = ''

				    RETURN
			    END
    		
			    INSERT INTO dbo.Task_Cust_BalanceProblem_New (custid, [type], DiffBalance, Remark)
			    SELECT
			    @custid, @type, @DiffBalance,'Fixed by LogAndFix'		
    			
			    IF @DiffBalance > 0
				    INSERT INTO dbo.BalCreditCasinoPending (custid, Balance) VALUES (@custid, @DiffBalance)
			    ELSE
				    INSERT INTO dbo.BalDebitCasinoPending  (custid, Balance) VALUES (@custid, -@DiffBalance)

			    update Task_Cust_BalanceProblem_New
			    set remark = 'Reset ON ' + CONVERT(varchar(10), current_timestamp, 120)
			    where remark = '' and custid = @custid AND [type] = @type
		    END
    	   END	    	   
	   ELSE IF (@type = 3) 
	   BEGIN
		    IF NOT EXISTS (
			    SELECT 1 FROM dbo.BalCreditOthersPending WHERE custid = @custid
			    UNION
			    SELECT 1 FROM dbo.BalDebitOthersPending  WHERE custid = @custid
		    )
		    BEGIN		

			    --Check member has tickets bet on matches that are being calculated
			    IF EXISTS(
				    SELECT 1 FROM bettrans b WITH (NOLOCK) INNER JOIN #ProdInfo p ON b.bettype = p.bettype
				    WHERE custid = @custid AND matchid IN(SELECT KeyValue FROM TempVariableNumber WHERE KeyID = 1)
				    )
			    BEGIN			
				    INSERT INTO dbo.Task_Cust_BalanceProblem_New(custid, [type], DiffBalance, Remark)
				    SELECT
				    @custid, @type, @DiffBalance,'Skip fix to avoid conflict with settlement (Others)'
    						
				    UPDATE bp
				    SET username = c.username
				    FROM CustDB.dbo.custinfo c with (nolock)
					    INNER JOIN dbo.Task_Cust_BalanceProblem_New bp ON c.custid = bp.custid AND bp.username IS NULL

				    UPDATE bp
				    SET remark = c.Remark
				    FROM dbo.Task_Cust_CheckBalance_Exception c
					    INNER JOIN dbo.Task_Cust_BalanceProblem_New bp ON c.custid = bp.custid
				    WHERE bp.[type] = @type
					    AND bp.remark = ''

				    RETURN
			    END
    		
			    INSERT INTO dbo.Task_Cust_BalanceProblem_New (custid, [type], DiffBalance, Remark)
			    SELECT
			    @custid, @type, @DiffBalance,'Fixed by LogAndFix'		
    			
			    IF @DiffBalance > 0
				    INSERT INTO dbo.BalCreditOthersPending (custid, Balance) VALUES (@custid, @DiffBalance)
			    ELSE
				    INSERT INTO dbo.BalDebitOthersPending  (custid, Balance) VALUES (@custid, -@DiffBalance)

			    update Task_Cust_BalanceProblem_New
			    set remark = 'Reset ON ' + CONVERT(varchar(10), current_timestamp, 120)
			    where remark = '' and custid = @custid AND [type] = @type
		    END		  		    
    	   END
	   ELSE IF (@type = 0) --Transfers: update balance directly
	   BEGIN    		
		   INSERT INTO dbo.Task_Cust_BalanceProblem_New (custid, [type], DiffBalance, Remark)
		   SELECT
		   @custid, @type, @DiffBalance,'Fixed by LogAndFix'		
    		
		   IF @DiffBalance > 0
		   BEGIN
			 EXEC dbo.Dot_BalanceCreditUpd
				 @custID = @custID,
				 @balance	= @DiffBalance,
				 @type = 2--transfers
		   END
		   ELSE
		   BEGIN
			 SELECT @DiffBalance = -@DiffBalance
			 EXEC dbo.Dot_BalanceDebitUpd
				 @custID = @custID,
				 @balance	= @DiffBalance,
				 @type = 2,--transfers
				 @isForced = 0
		   END

		   update Task_Cust_BalanceProblem_New
		   set remark = 'Reset ON ' + CONVERT(varchar(10), current_timestamp, 120)
		   where remark = '' and custid = @custid AND [type] = @type		  		    
    	   END    	   
    	   	
	END	

	UPDATE bp
	SET username = c.username
	FROM CustDB.dbo.custinfo c with (nolock)
		INNER JOIN dbo.Task_Cust_BalanceProblem_New bp ON c.custid = bp.custid AND bp.username IS NULL	
		
	UPDATE bp
	SET remark = c.Remark
     FROM dbo.Task_Cust_CheckBalance_Exception c
	   INNER JOIN dbo.Task_Cust_BalanceProblem_New bp ON c.custid = bp.custid
	WHERE bp.[type] = @type AND bp.remark = ''		
END

