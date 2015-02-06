USE [bodb_Licensee]
GO

/****** Object:  StoredProcedure [dbo].[GET_DepositDataToValidate_LicenseeWL]    Script Date: 02/04/2015 02:19:41 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[GET_DepositDataToValidate_LicenseeWL] 
    @Date smalldatetime 
	,@DrawFilter tinyint = 1
AS
/*
Created: 20111209@Don
Task : Get deposit data from table db052.bodb_Licensee.dbo.rptLicWinloss2

DB: bodb_Licensee
Original:

Revisions:	
- 20140310@daniel: exclude currency C & H
	
Param's Explanation:
    @DrawFilter, 1:Normal - 2:No Draws - 3:No Draws For Turnover Only

Examples:

DECLARE @DateChecking SMALLDATETIME
SELECT @DateChecking =DATEADD(day, -10, GETDATE())
exec [GET_DepositDataToValidate_LicenseeWL] @Date=@DateChecking,@DrawFilter=1
*/

SET NOCOUNT ON


DECLARE @SbTurnover MONEY
       ,@SbCustomerWl MONEY
       ,@SbBetCount MONEY
       ,@RbTurnover MONEY
       ,@RbCustomerWl MONEY
       ,@RbBetCount MONEY
       ,@NgTurnover MONEY
       ,@NgCustomerWl MONEY
       ,@NgBetCount MONEY
       ,@BaTurnover MONEY
       ,@BaCustomerWl MONEY
       ,@BaBetCount MONEY
       ,@CsTurnover MONEY
       ,@CsCustomerWl MONEY
       ,@CsBetCount MONEY
       
-- Sportbook

SELECT @SbTurnover = SUM(CASE 
                    WHEN @DrawFilter IN (2,3) THEN 
                        CASE WHEN b.statusID = 111 THEN 0 WHEN b.statusID IN (114,115) THEN 0.5 ELSE 1 END
                    ELSE 1
                END * b.Turnover)
    ,@SbCustomerWl=SUM(b.winlost) 
    ,@SbBetCount=SUM(CASE WHEN @DrawFilter=2 AND b.statusID = 111 THEN 0 ELSE b.BetCount END)
FROM dbo.rptLicWinloss2 b (NOLOCK)
WHERE b.winlostdate=@Date
    AND b.sporttype=0
    AND b.statusID IN (111,112,113,114,115)
    AND b.currency NOT IN(20,27,28)
    AND b.roleid = 4
    AND b.srecommend IN (SELECT custid FROM bodb02.dbo.f_Depsuper_1('All'))
    AND isBA = CONVERT(bit,0)

SELECT @SbTurnover = ISNULL (@SbTurnover, 0),
	   @SbCustomerWl = ISNULL (@SbCustomerWl, 0),
	   @SbBetCount = ISNULL (@SbBetCount, 0)

-- Racing

SELECT @RbTurnover = SUM(b.turnover) 
    ,@RbCustomerWl = SUM(b.winlost) 
    ,@RbBetCount = SUM(b.BetCount)
FROM dbo.rptLicWinloss2 b (NOLOCK)
WHERE b.winlostdate=@Date
    AND b.sporttype=151
    AND b.statusID IN (111,112,113,114,115)
    AND b.currency NOT IN(20,27,28)
    AND b.roleid = 4
    AND b.srecommend IN (SELECT custid FROM bodb02.dbo.f_Depsuper_1('All'))
    AND isBA = CONVERT(bit,0)

SELECT @RbTurnover = ISNULL (@RbTurnover, 0),
	   @RbCustomerWl = ISNULL (@RbCustomerWl, 0),
	   @RbBetCount = ISNULL (@RbBetCount, 0)
        
-- Number Game

SELECT @NgTurnover = CONVERT(money,0) 
    ,@NgCustomerWl = CONVERT(money,0)
    ,@NgBetCount = CONVERT(money,0)

SELECT @NgTurnover=SUM(CASE WHEN @DrawFilter IN (2,3) AND b.statusID = 111 THEN 0 ELSE b.turnover END)
    ,@NgCustomerWl=SUM(b.winlost) 
    ,@NgBetCount=SUM(CASE WHEN @DrawFilter=2 AND b.statusID = 111 THEN 0 ELSE b.BetCount END) 
FROM dbo.rptLicWinloss2 b (NOLOCK)
WHERE b.winlostdate=@Date
    AND b.sporttype=161
    AND b.statusID IN (111,112,113,114,115)
    AND b.currency NOT IN(20,27,28)
    AND b.roleid = 4
    AND b.srecommend IN (SELECT custid FROM bodb02.dbo.f_Depsuper_1('All'))
    AND isBA = CONVERT(bit,0)

SELECT @NgTurnover = ISNULL (@NgTurnover, 0),
	   @NgCustomerWl = ISNULL (@NgCustomerWl, 0),
	   @NgBetCount = ISNULL (@NgBetCount, 0)

-- Section: BA

SELECT @BaTurnover=SUM(CASE 
                    WHEN @DrawFilter IN (2,3) THEN 
                        CASE WHEN b.statusID = 111 THEN 0 WHEN b.statusID IN (114,115) THEN 0.5 ELSE 1 END
                    ELSE 1
                END * b.Turnover)
    ,@BaCustomerWl=SUM(b.winlost) 
    ,@BaBetCount=SUM(CASE WHEN @DrawFilter=2 AND b.statusID = 111 THEN 0 ELSE b.BetCount END) 
FROM dbo.rptLicWinloss2 b (NOLOCK)
WHERE b.winlostdate=@Date
    AND b.statusID IN (111,112,113,114,115)
    AND b.currency NOT IN(20,27,28)
    AND b.roleid = 4
    AND isBA = CONVERT(bit,1)

SELECT @BaTurnover = ISNULL (@BaTurnover, 0),
	   @BaCustomerWl = ISNULL (@BaCustomerWl, 0),
	   @BaBetCount = ISNULL (@BaBetCount, 0)
	   
-- Live Casino

SELECT @CsTurnover = CONVERT(money,0) 
    ,@CsCustomerWl = CONVERT(money,0)
    ,@CsBetCount = CONVERT(money,0)

SELECT @CsTurnover = SUM(CASE WHEN @DrawFilter IN (2,3) AND b.statusID = 111 THEN 0 ELSE b.turnover END)
    ,@CsCustomerWl = SUM(b.winlost) 
    ,@CsBetCount = SUM(CASE WHEN @DrawFilter=2 AND b.statusID = 111 THEN 0 ELSE b.BetCount END) 
FROM dbo.rptLicWinloss2 b (NOLOCK)
WHERE b.winlostdate=@Date
    AND b.sporttype=162
    AND b.statusID IN (111,112,113,114,115)
    AND b.currency NOT IN(20,27,28)
    AND b.roleid = 4
    AND b.srecommend IN (SELECT custid FROM bodb02.dbo.f_Depsuper_1('All'))
    AND isBA = CONVERT(bit,0)

SELECT @CsTurnover = ISNULL (@CsTurnover, 0),
	   @CsCustomerWl = ISNULL (@CsCustomerWl, 0),
	   @CsBetCount = ISNULL (@CsBetCount, 0)

-- Result

SELECT 1 AS Id, @SbTurnover AS Sb, @RbTurnover AS Rb, @NgTurnover AS Ng, @BaTurnover AS Ba, @CsTurnover AS Cs
UNION
SELECT 2, @SbCustomerWl, @RbCustomerWl, @NgCustomerWl, @BaCustomerWl, @CsCustomerWl
UNION
SELECT 3, @SbBetCount, @RbBetCount, @NgBetCount, @BaBetCount, @CsBetCount

SET NOCOUNT OFF





GO

GRANT EXECUTE ON [dbo].[GET_DepositDataToValidate_LicenseeWL] TO [bodbLicenseeNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[GET_DepositDataToValidate_LicenseeWL] TO [vnteam] AS [dbo]
GO


