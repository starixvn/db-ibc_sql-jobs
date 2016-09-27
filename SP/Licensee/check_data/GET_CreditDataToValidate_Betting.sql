SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.GET_CreditDataToValidate_Betting    Script Date: 7/15/2016 10:24:59 AM ******/


CREATE PROCEDURE [dbo].[GET_CreditDataToValidate_Betting] 
     @Date smalldatetime 
	,@DrawFilter tinyint = 1
AS
/*
Created: 20120307@Don
Task : Get credit data from table db052.bodb_Licensee.dbo.rpt_Betting

DB: bodb_Licensee
Original:

Revisions:	
    - 20121204@Don: Add more validating for Live Casino, RNG Casino and Virtual Sport
    - 20140310@daniel: exclude currency C & H
    - 20150119@daniel: Fix SB bettype condition
    - 20160523@Francis: Change bettype range for RNG Casino (hotfix #55730)
	- 20160616@Jim: Changes to data integrity automail (#59249)	
	 
Param's Explanation:
    @DrawFilter, 1:Normal - 2:No Draws - 3:No Draws For Turnover Only
Examples:

DECLARE @DateChecking SMALLDATETIME
SELECT @DateChecking =DATEADD(day, -10, GETDATE())
exec [GET_CreditDataToValidate_Betting] @Date=@DateChecking,@DrawFilter=1
*/

SET NOCOUNT ON


DECLARE @SbTurnover MONEY
       ,@SbCustomerWl MONEY
       ,@SbBetCount MONEY
	    ----CB
	   ,@CBTurnover MONEY
       ,@CBCustomerWl MONEY
       ,@CBBetCount MONEY 
	   
       ,@RbTurnover MONEY
       ,@RbCustomerWl MONEY
       ,@RbBetCount MONEY
	   
       ,@NgTurnover MONEY
       ,@NgCustomerWl MONEY
       ,@NgBetCount MONEY
       
       ,@LCTurnover MONEY
       ,@LCCustomerWl MONEY
       ,@LCBetCount MONEY
       
	   ,@VsTurnover MONEY
       ,@VsCustomerWl MONEY
       ,@VsBetCount MONEY
		--GD
	   ,@GDTurnover MONEY
       ,@GDCustomerWl MONEY
       ,@GDBetCount MONEY
	   --KN
	   ,@KNTurnover MONEY
       ,@KNCustomerWl MONEY
       ,@KNBetCount MONEY
		--- RNG Casino
       ,@CsTurnover MONEY
       ,@CsCustomerWl MONEY
       ,@CsBetCount MONEY
DECLARE @tblSport AS TABLE (ProductPrefix VARCHAR (10),bettype INT)

INSERT INTO @tblSport (ProductPrefix,bettype)
SELECT DISTINCT p.ProductPrefix,s.bettype
FROM bodb02.dbo.SportBettypeMatrix s WITH (NOLOCK)
	INNER JOIN bodb02.dbo.Products p WITH (NOLOCK) ON s.ProductId = p.ProductId
WHERE p.ProductPrefix IN ('SB','CB','GD','KN','LC','NG','RB','CS','VS')
	 
DECLARE @tblData AS TABLE (ProductPrefix VARCHAR (10),Status INT, TurnOver MONEY,WinLoss MONEY,BetCount INT)

INSERT INTO @tblData (ProductPrefix ,status, TurnOver ,WinLoss ,BetCount )
SELECT  ProductPrefix
		,status
	    ,SUM(TurnOver)
	    ,SUM(Winloss)
	    ,SUM(BetCount)
FROM dbo.rpt_Betting b (NOLOCK)
	INNER JOIN  @tblSport s ON b.bettype = s.bettype
WHERE b.rptDate = @Date
	  AND b.Status IN (111,112,113,114,115)
      AND b.currencyID NOT IN(20,27,28)
      AND b.SiteID NOT IN (SELECT LicenseeID FROM dbo.Licensees (NOLOCK) WHERE IsDeposit = CONVERT(bit,1))	
GROUP BY ProductPrefix
		,status	  
-- Sportbook
SELECT @SbTurnover = SUM(
                CASE 
                    WHEN @DrawFilter IN (2,3) THEN 
                        CASE WHEN b.Status = 111 THEN 0 WHEN b.Status IN (114,115) THEN 0.5 ELSE 1 END
                    ELSE 1
                END * ISNULL(b.Turnover,0))
    ,@SbCustomerWl = SUM(ISNULL(b.WinLoss,0))
    ,@SbBetCount = SUM(CASE WHEN @DrawFilter = 2 AND b.Status = 111 THEN 0 ELSE ISNULL(b.BetCount,0) END)
FROM @tblData b
WHERE ProductPrefix ='SB' 

SELECT @SbTurnover = ISNULL (@SbTurnover, 0),
	   @SbCustomerWl = ISNULL (@SbCustomerWl, 0),
	   @SbBetCount = ISNULL (@SbBetCount, 0)

-- Racing

SELECT @RbTurnover = ISNULL(SUM(CASE WHEN b.Status IN (114,115) THEN 0.5 ELSE 1 END * b.Turnover),0) 
       ,@RbCustomerWl = ISNULL(SUM(b.WinLoss),0) 
       ,@RbBetCount = ISNULL(SUM(b.BetCount),0) 
FROM @tblData b
WHERE ProductPrefix ='RB' 

SELECT @RbTurnover = ISNULL (@RbTurnover, 0),
	   @RbCustomerWl = ISNULL (@RbCustomerWl, 0),
	   @RbBetCount = ISNULL (@RbBetCount, 0)
	   
-- Number Game

SELECT @NgTurnover = SUM(CASE WHEN @DrawFilter IN (2,3) AND b.Status = 111 THEN 0 ELSE ISNULL(b.Turnover,0) END)
       ,@NgCustomerWl = SUM(ISNULL(b.WinLoss,0))
       ,@NgBetCount = SUM(CASE WHEN @DrawFilter = 2 AND b.Status = 111 THEN 0 ELSE ISNULL(b.BetCount,0) END) 
FROM @tblData b
WHERE ProductPrefix ='NG' 

SELECT @NgTurnover = ISNULL (@NgTurnover, 0),
	   @NgCustomerWl = ISNULL (@NgCustomerWl, 0),
	   @NgBetCount = ISNULL (@NgBetCount, 0)
	   
-- Live Casino

SELECT @LCTurnover = SUM(CASE WHEN @DrawFilter IN (2,3) AND b.Status = 111 THEN 0 ELSE ISNULL(b.Turnover,0) END)
      ,@LCCustomerWl = SUM(ISNULL(b.WinLoss,0))
      ,@LCBetCount = SUM(CASE WHEN @DrawFilter = 2 AND b.Status = 111 THEN 0 ELSE ISNULL(b.BetCount,0) END) 
FROM @tblData b
WHERE ProductPrefix ='LC' 

SELECT @LCTurnover = ISNULL   (@LCTurnover, 0),
	   @LCCustomerWl = ISNULL (@LCCustomerWl, 0),
	   @LCBetCount = ISNULL  (@LCBetCount, 0)
	   
 
	   
-- Virtual Sport

SELECT @VsTurnover = SUM(CASE WHEN @DrawFilter IN (2,3) AND b.Status = 111 THEN 0 ELSE ISNULL(b.Turnover,0) END)
      ,@VsCustomerWl = SUM(ISNULL(b.WinLoss,0))
      ,@VsBetCount = SUM(CASE WHEN @DrawFilter = 2 AND b.Status = 111 THEN 0 ELSE ISNULL(b.BetCount,0) END) 
FROM @tblData b
WHERE ProductPrefix ='VS'
     

SELECT @VsTurnover = ISNULL (@VsTurnover, 0),
	   @VsCustomerWl = ISNULL (@VsCustomerWl, 0),
	   @VsBetCount = ISNULL (@VsBetCount, 0)
	---Colossus Bets

SELECT @CBTurnover = SUM(CASE WHEN @DrawFilter IN (2,3) AND b.Status = 111 THEN 0 ELSE ISNULL(b.Turnover,0) END)
	  ,@CBCustomerWl = SUM(ISNULL(b.WinLoss,0))
	 ,@CBBetCount = SUM(CASE WHEN @DrawFilter = 2 AND b.Status = 111 THEN 0 ELSE ISNULL(b.BetCount,0) END) 
FROM @tblData b
WHERE ProductPrefix ='CB'

SELECT @CBTurnover = ISNULL (@CBTurnover, 0),
	   @CBCustomerWl = ISNULL (@CBCustomerWl, 0),
	   @CBBetCount = ISNULL (@CBBetCount, 0)
-- GD
	SELECT  @GDTurnover = SUM(CASE WHEN @DrawFilter IN (2,3) AND b.Status = 111 THEN 0 ELSE ISNULL(b.Turnover,0) END)
			,@GDCustomerWl = SUM(ISNULL(b.WinLoss,0))
			,@GDBetCount = SUM(CASE WHEN @DrawFilter = 2 AND b.Status = 111 THEN 0 ELSE ISNULL(b.BetCount,0) END) 
FROM @tblData b
WHERE ProductPrefix ='GD'

SELECT @GDTurnover = ISNULL (@GDTurnover, 0),
	   @GDCustomerWl = ISNULL (@GDCustomerWl, 0),
	   @GDBetCount = ISNULL (@GDBetCount, 0)   
-- KN
	SELECT  @KNTurnover = SUM(CASE WHEN @DrawFilter IN (2,3) AND b.Status = 111 THEN 0 ELSE ISNULL(b.Turnover,0) END)
			,@KNCustomerWl = SUM(ISNULL(b.WinLoss,0))
			,@KNBetCount = SUM(CASE WHEN @DrawFilter = 2 AND b.Status = 111 THEN 0 ELSE ISNULL(b.BetCount,0) END) 
FROM @tblData b
WHERE ProductPrefix ='KN'

SELECT @KNTurnover = ISNULL (@KNTurnover, 0),
	   @KNCustomerWl = ISNULL (@KNCustomerWl, 0),
	   @KNBetCount = ISNULL (@KNBetCount, 0) 
-- CS
	SELECT  @CSTurnover = SUM(CASE WHEN @DrawFilter IN (2,3) AND b.Status = 111 THEN 0 ELSE ISNULL(b.Turnover,0) END)
			,@CSCustomerWl = SUM(ISNULL(b.WinLoss,0))
			,@CSBetCount = SUM(CASE WHEN @DrawFilter = 2 AND b.Status = 111 THEN 0 ELSE ISNULL(b.BetCount,0) END) 
FROM @tblData b
WHERE ProductPrefix ='CS'

SELECT @CSTurnover = ISNULL (@CSTurnover, 0),
	   @CSCustomerWl = ISNULL (@CSCustomerWl, 0),
	   @CSBetCount = ISNULL (@CSBetCount, 0) 	   
-- Result

SELECT 1 AS Id, @SbTurnover  AS Sb
			  , @RbTurnover  AS Rb
			  , @NgTurnover  AS Ng
			  , @LCTurnover  AS LC
			  , @VsTurnover  AS Vs
			  ,	@CBTurnover  AS CB
			  ,	@GDTurnover  AS GD
			  ,	@KNTurnover  AS KN
			  ,	@CSTurnover  AS CS
UNION	
SELECT 2, @SbCustomerWl
		, @RbCustomerWl
		, @NgCustomerWl
		, @LCCustomerWl
		, @VsCustomerWl
		, @CBCustomerWl
		, @GDCustomerWl
		, @KNCustomerWl
		, @CSCustomerWl
UNION
SELECT 3, @SbBetCount
		, @RbBetCount
		, @NgBetCount
		, @LCBetCount
		, @VsBetCount
		, @CBBetCount
		, @GDBetCount
		, @KNBetCount
		, @CSBetCount
SET NOCOUNT OFF


GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT VIEW DEFINITION ON [dbo].[GET_CreditDataToValidate_Betting] TO [vnteam]
GO 
 GRANT EXECUTE ON [dbo].[GET_CreditDataToValidate_Betting] TO [bodbLicenseeNet]
GO 
