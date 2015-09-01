USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Task_CheckBalance_NoFix]    Script Date: 08/20/2015 04:35:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Task_CheckBalance    Script Date: 12/24/2013 12:27:58 PM ******/
ALTER PROCEDURE [dbo].[Task_CheckBalance_NoFix_New]
	@Step tinyint = 0,
	@Action varchar(20) = 'JustLog', 
	@custid int = 0 
AS
/*
	Task: Check bal and insert member ids to table Task_Cust_CheckBalanceVerify
	Original: Task_CheckBalance
	Location: DBTXN.bodb02

	Revision: 
		20150525@Daniel: Clone from Task_CheckBalance, remove fix steps
		20150820@Daniel: new set of balance tables - redmine #40125


/* Test command

*/
	exec Task_CheckBalance_NoFix @Step = 99, @Action = 'LogAndFix'
*/
SET NOCOUNT ON

Declare --@FromBalanceTable money, 
		@FromBettrans money, 
		@DiffBalance money,
		@FromTransLog money

IF OBJECT_ID('tempdb..#ProdInfo') IS NOT NULL DROP TABLE #ProdInfo
SELECT DISTINCT productid, bettype INTO #ProdInfo FROM SportBettypeMatrix WITH (NOLOCK)

		
IF @custid > 0
BEGIN
	IF @Action = 'LogAndFix'
	BEGIN
		INSERT INTO dbo.Task_Cust_CheckBalanceVerify (custid) VALUES (@custid)
		
				--EXEC dbo.Task_CheckBalance @Step = 3, @Action = 'LogAndFix'
		
		RETURN	
	END

    IF OBJECT_ID('tempdb..#FromBettrans') IS NOT NULL DROP TABLE #FromBettrans
    IF OBJECT_ID('tempdb..#FromTranslog') IS NOT NULL DROP TABLE #FromTranslog	
	
    --From bettrans
    SELECT  
	   CASE
		  WHEN b.bettype >= 19999 THEN 0 --transfer
		  WHEN p.productID = 1 THEN 1 --SB
		  WHEN p.productID IN(4,6,11,12,13,14) THEN 2 --Casino
		  WHEN p.productID IN(2,3,5,7,8) THEN 3 --Others
		  ELSE 3 --All unknown put in Others 
	   END Type,
	   SUM(winlost-b.actual_stake+playercomm) BAL
    INTO #FromBettrans
    FROM bettrans b WITH (ROWLOCK)     
	   LEFT JOIN #ProdInfo p ON b.bettype = p.bettype
    WHERE b.custid IN(select custid from custDB.dbo.customer with (nolock) where roleid = 1) 
	    AND b.custid = @custID
    GROUP BY
	   CASE
		  WHEN b.bettype >= 19999 THEN 0 --transfer
		  WHEN p.productID = 1 THEN 1 --SB
		  WHEN p.productID IN(4,6,11,12,13,14) THEN 2 --Casino
		  WHEN p.productID IN(2,3,5,7,8) THEN 3 --Others
		  ELSE 3 --All unknown put in Others 
	   END    

    --From translog
    SELECT
	   CASE
		  WHEN p.productID = 1 THEN 1 --SB
		  WHEN p.productID IN(4,6,11,12,13,14) THEN 2 --Casino
		  WHEN p.productID IN(2,3,5,7,8) THEN 3 --Others
		  ELSE 3 --All unknown put in Others 
	   END Type,
	   SUM(b.actual_stake) Oxt
    INTO #FromTranslog
    FROM translog b WITH (NOLOCK) 
	   LEFT JOIN #ProdInfo p ON b.GameID = p.bettype
    WHERE b.statusid = 0
	AND b.custid = @custID
    GROUP BY
	   CASE
		  WHEN p.productID = 1 THEN 1 --SB
		  WHEN p.productID IN(4,6,11,12,13,14) THEN 2 --Casino
		  WHEN p.productID IN(2,3,5,7,8) THEN 3 --Others
		  ELSE 3 --All unknown put in Others
	   END 

	DECLARE @username VARCHAR(50)
	SELECT @username = username FROM CustDB.dbo.custinfo WITH (NOLOCK) WHERE custid = @custid
	
	SELECT @custid custid, @username username,
		b.[type],
		CASE b.[type] WHEN 0 THEN 'Transfer' WHEN 1 THEN 'Sportsbook' WHEN 2 THEN 'Casino' WHEN 3 THEN 'Others' END Product,
		ISNULL(b.BAL,0)-ISNULL(l.Oxt,0) FromBettrans,
		ISNULL(cd.Balance,0) - ISNULL(db.Balance,0) FromBalanceTable,
		(ISNULL(b.BAL,0)-ISNULL(l.Oxt,0)) - (cd.Balance - db.Balance) Diff
	FROM	
		#FromBettrans b
		LEFT JOIN #FromTransLog l ON b.[type] = l.[type]
		LEFT JOIN 
		(
		  SELECT custid, 0 [Type], Balance FROM dbo.BalCreditTransfer WITH (NOLOCK) WHERE custid = @custid
		  UNION ALL SELECT custid, 1 [Type], Balance FROM dbo.BalCreditSports WITH (NOLOCK) WHERE custid = @custid
		  UNION ALL SELECT custid, 2 [Type], Balance FROM dbo.BalCreditCasino WITH (NOLOCK) WHERE custid = @custid
		  UNION ALL SELECT custid, 3 [Type], Balance FROM dbo.BalCreditOthers WITH (NOLOCK) WHERE custid = @custid
		 ) cd ON b.[type] = cd.[type]
		LEFT JOIN
		(
		  SELECT custid, 0 [Type], Balance FROM dbo.BalDebitTransfer WITH (NOLOCK) WHERE custid = @custid
		  UNION ALL SELECT custid, 1 [Type], Balance FROM dbo.BalDebitSports WITH (NOLOCK) WHERE custid = @custid
		  UNION ALL SELECT custid, 2 [Type], Balance FROM dbo.BalDebitCasino WITH (NOLOCK) WHERE custid = @custid
		  UNION ALL SELECT custid, 3 [Type], Balance FROM dbo.BalDebitOthers WITH (NOLOCK) WHERE custid = @custid
		 ) db ON b.[type] = db.[type]
	
	RETURN
END

IF @Step = 99
-- run through all step automatic
BEGIN
		EXEC dbo.Task_CheckBalance_NoFix_New @Step = 1
		EXEC dbo.Task_CheckBalance_NoFix_New @Step = 2
END
ELSE IF @Step = 1 -- Get List of Customer & Balance
BEGIN
	DELETE FROM dbo.Task_Cust_CheckBalance_New

    IF OBJECT_ID('tempdb..#FromBettrans1') IS NOT NULL DROP TABLE #FromBettrans
    IF OBJECT_ID('tempdb..#FromTranslog1') IS NOT NULL DROP TABLE #FromTranslog	
	
    --From bettrans
    SELECT b.custid,
	   CASE
		  WHEN b.bettype >= 19999 THEN 0 --transfer
		  WHEN p.productID = 1 THEN 1 --SB
		  WHEN p.productID IN(4,6,11,12,13,14) THEN 2 --Casino
		  WHEN p.productID IN(2,3,5,7,8) THEN 3 --Others
		  ELSE 3 --All unknown put in Others 
	   END Type,
	   SUM(winlost-b.actual_stake+playercomm) BAL
    INTO #FromBettrans1
    FROM bettrans b WITH (ROWLOCK)
	   INNER JOIN CustDB.dbo.custinfo c with (nolock) ON b.custid = c.custid AND c.roleid = 1
	   LEFT JOIN #ProdInfo p ON b.bettype = p.bettype
    GROUP BY
	   b.custid,
	   CASE
		  WHEN b.bettype >= 19999 THEN 0 --transfer
		  WHEN p.productID = 1 THEN 1 --SB
		  WHEN p.productID IN(4,6,11,12,13,14) THEN 2 --Casino
		  WHEN p.productID IN(2,3,5,7,8) THEN 3 --Others
		  ELSE 3 --All unknown put in Others 
	   END    

    --From translog
    SELECT
	   b.custid,
	   CASE
		  WHEN p.productID = 1 THEN 1 --SB
		  WHEN p.productID IN(4,6,11,12,13,14) THEN 2 --Casino
		  WHEN p.productID IN(2,3,5,7,8) THEN 3 --Others
		  ELSE 3 --All unknown put in Others 
	   END Type,
	   SUM(b.actual_stake) Oxt
    INTO #FromTranslog1
    FROM translog b WITH (NOLOCK) 
	   INNER JOIN CustDB.dbo.custinfo c with (nolock) ON b.custid = c.custid AND c.roleid = 1 and b.statusID=0
	   LEFT JOIN #ProdInfo p ON b.GameID = p.bettype
    GROUP BY
	   b.custid,
	   CASE
		  WHEN p.productID = 1 THEN 1 --SB
		  WHEN p.productID IN(4,6,11,12,13,14) THEN 2 --Casino
		  WHEN p.productID IN(2,3,5,7,8) THEN 3 --Others
		  ELSE 3 --All unknown put in Others
	   END 

	INSERT INTO dbo.Task_Cust_CheckBalance_New (custid, [type], FromBettrans, FromTransLog)
	SELECT b.custid,
		b.[type],
		ISNULL(b.BAL,0) FromBettrans,
		ISNULL(l.Oxt,0) FromTransLog
	FROM	#FromBettrans1 b LEFT JOIN #FromTransLog1 l ON b.custid = l.custid AND b.[type] = l.[type]
		
END
ELSE IF @Step = 2 -- 1st round : check BalanceBettrans -vs- BalanceTable , Then save list to verify
BEGIN
		
	UPDATE cb
	SET FromBalanceTable = cd.Balance - db.Balance		
	FROM
		dbo.Task_Cust_CheckBalance_New cb
		INNER JOIN 
		(
		  SELECT custid, 0 [Type], Balance FROM dbo.BalCreditTransfer WITH (NOLOCK)
		  UNION ALL SELECT custid, 1 [Type], Balance FROM dbo.BalCreditSports WITH (NOLOCK)
		  UNION ALL SELECT custid, 2 [Type], Balance FROM dbo.BalCreditCasino WITH (NOLOCK)
		  UNION ALL SELECT custid, 3 [Type], Balance FROM dbo.BalCreditOthers WITH (NOLOCK)
		 ) cd ON cb.[type] = cd.[type]
		INNER JOIN
		(
		  SELECT custid, 0 [Type], Balance FROM dbo.BalDebitTransfer WITH (NOLOCK)
		  UNION ALL SELECT custid, 1 [Type], Balance FROM dbo.BalDebitSports WITH (NOLOCK)
		  UNION ALL SELECT custid, 2 [Type], Balance FROM dbo.BalDebitCasino WITH (NOLOCK)
		  UNION ALL SELECT custid, 3 [Type], Balance FROM dbo.BalDebitOthers WITH (NOLOCK)
		 ) db ON cb.[type] = db.[type]

	DELETE FROM dbo.Task_Cust_CheckBalanceVerify_New

	INSERT INTO dbo.Task_Cust_CheckBalanceVerify_New (custid, [type])
	SELECT custid, [type]
	FROM dbo.Task_Cust_CheckBalance_New with (nolock)
	WHERE (FromBettrans-FromTransLog) <> FromBalanceTable --20140213@Vivi: deduct keno outstanding
END

