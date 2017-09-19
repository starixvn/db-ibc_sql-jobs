/*<info serverAlias="DBLIC-bodb_Licensee" executers="bodbLicenseeNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[GET_CreditDataToValidate_Betting] 
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
	- 20160726@Francis: Move SP to bodb_LicenseeReport - [Redmine: #60449]
	- 20170822@Harper: Add missing products CB, AB, NG2, FW, CO, VS2, LT, LK3 into data validation email [RedmineID: #81708]

Param's Explanation:
    @DrawFilter, 1:Normal - 2:No Draws - 3:No Draws For Turnover Only
Examples:

DECLARE @DateChecking SMALLDATETIME
SELECT @DateChecking =DATEADD(day, -10, GETDATE())
exec [GET_CreditDataToValidate_Betting] @Date=@DateChecking,@DrawFilter=1
*/

SET NOCOUNT ON


DECLARE -- SB
		@SbTurnover MONEY
       ,@SbCustomerWl MONEY
       ,@SbBetCount MONEY
	    -- CB
	   ,@CBTurnover MONEY
       ,@CBCustomerWl MONEY
       ,@CBBetCount MONEY 
	   -- RB
       ,@RbTurnover MONEY
       ,@RbCustomerWl MONEY
       ,@RbBetCount MONEY
	   -- NG
       ,@NgTurnover MONEY
       ,@NgCustomerWl MONEY
       ,@NgBetCount MONEY
       -- LC
       ,@LCTurnover MONEY
       ,@LCCustomerWl MONEY
       ,@LCBetCount MONEY
       -- VS
	   ,@VsTurnover MONEY
       ,@VsCustomerWl MONEY
       ,@VsBetCount MONEY
		-- GD
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
	   ----AB
		,@ABTurnover MONEY
		,@ABCustomerWl MONEY
		,@ABBetCount MONEY
		----NG2
		,@NG2Turnover MONEY
		,@NG2CustomerWl MONEY
		,@NG2BetCount MONEY
		----FW
		,@FWTurnover MONEY
		,@FWCustomerWl MONEY
		,@FWBetCount MONEY		
		----VS2
		,@VS2Turnover MONEY
		,@VS2CustomerWl MONEY
		,@VS2BetCount MONEY
		----LT
		,@LTTurnover MONEY
		,@LTCustomerWl MONEY
		,@LTBetCount MONEY
		----LK3
		,@LK3Turnover MONEY
		,@LK3CustomerWl MONEY
		,@LK3BetCount MONEY

DECLARE @tblSport AS TABLE (ProductPrefix VARCHAR (10),bettype INT)

INSERT INTO @tblSport (ProductPrefix,bettype)
SELECT DISTINCT p.ProductPrefix,s.bettype
FROM bodb02.dbo.SportBettypeMatrix s WITH (NOLOCK)
	INNER JOIN bodb02.dbo.Products p WITH (NOLOCK) ON s.ProductId = p.ProductId
WHERE p.ProductPrefix IN ('SB','CB','GD','KN','LC','NG','RB','CS','VS','AB','NG2','FW','VS2','LT','LK3')
	 
DECLARE @tblData AS TABLE (ProductPrefix VARCHAR (10),Status INT, TurnOver MONEY,WinLoss MONEY,BetCount INT)

INSERT INTO @tblData (ProductPrefix ,status, TurnOver ,WinLoss ,BetCount )
SELECT  ProductPrefix
		,status
	    ,SUM(TurnOver)
	    ,SUM(Winloss)
	    ,SUM(BetCount)
FROM bodb_LicenseeReport.dbo.rpt_Betting b (NOLOCK)
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

-- AB
SELECT	@ABTurnover = SUM(CASE WHEN @DrawFilter IN (2,3) AND b.Status = 111 THEN 0 ELSE ISNULL(b.Turnover,0) END)
		,@ABCustomerWl = SUM(ISNULL(b.WinLoss,0))
		,@ABBetCount = SUM(CASE WHEN @DrawFilter = 2 AND b.Status = 111 THEN 0 ELSE ISNULL(b.BetCount,0) END) 
FROM @tblData b
WHERE ProductPrefix ='AB'

SELECT @ABTurnover = ISNULL (@ABTurnover, 0),
	   @ABCustomerWl = ISNULL (@ABCustomerWl, 0),
	   @ABBetCount = ISNULL (@ABBetCount, 0)    

-- NG2
SELECT	@NG2Turnover = SUM(CASE WHEN @DrawFilter IN (2,3) AND b.Status = 111 THEN 0 ELSE ISNULL(b.Turnover,0) END)
		,@NG2CustomerWl = SUM(ISNULL(b.WinLoss,0))
		,@NG2BetCount = SUM(CASE WHEN @DrawFilter = 2 AND b.Status = 111 THEN 0 ELSE ISNULL(b.BetCount,0) END) 
FROM @tblData b
WHERE ProductPrefix ='NG2'

SELECT @NG2Turnover = ISNULL (@NG2Turnover, 0),
	   @NG2CustomerWl = ISNULL (@NG2CustomerWl, 0),
	   @NG2BetCount = ISNULL (@NG2BetCount, 0)    

-- FW
SELECT	@FWTurnover = SUM(CASE WHEN @DrawFilter IN (2,3) AND b.Status = 111 THEN 0 ELSE ISNULL(b.Turnover,0) END)
		,@FWCustomerWl = SUM(ISNULL(b.WinLoss,0))
		,@FWBetCount = SUM(CASE WHEN @DrawFilter = 2 AND b.Status = 111 THEN 0 ELSE ISNULL(b.BetCount,0) END) 
FROM @tblData b
WHERE ProductPrefix ='FW'

SELECT @FWTurnover = ISNULL (@FWTurnover, 0),
	   @FWCustomerWl = ISNULL (@FWCustomerWl, 0),
	   @FWBetCount = ISNULL (@FWBetCount, 0)    

-- VS2
SELECT	@VS2Turnover = SUM(CASE WHEN @DrawFilter IN (2,3) AND b.Status = 111 THEN 0 ELSE ISNULL(b.Turnover,0) END)
		,@VS2CustomerWl = SUM(ISNULL(b.WinLoss,0))
		,@VS2BetCount = SUM(CASE WHEN @DrawFilter = 2 AND b.Status = 111 THEN 0 ELSE ISNULL(b.BetCount,0) END) 
FROM @tblData b
WHERE ProductPrefix ='VS2'

SELECT @VS2Turnover = ISNULL (@VS2Turnover, 0),
	   @VS2CustomerWl = ISNULL (@VS2CustomerWl, 0),
	   @VS2BetCount = ISNULL (@VS2BetCount, 0)  

-- LT
SELECT	@LTTurnover = SUM(CASE WHEN @DrawFilter IN (2,3) AND b.Status = 111 THEN 0 ELSE ISNULL(b.Turnover,0) END)
		,@LTCustomerWl = SUM(ISNULL(b.WinLoss,0))
		,@LTBetCount = SUM(CASE WHEN @DrawFilter = 2 AND b.Status = 111 THEN 0 ELSE ISNULL(b.BetCount,0) END) 
FROM @tblData b
WHERE ProductPrefix ='LT'

SELECT @LTTurnover = ISNULL (@LTTurnover, 0),
	   @LTCustomerWl = ISNULL (@LTCustomerWl, 0),
	   @LTBetCount = ISNULL (@LTBetCount, 0)  

-- LK3
SELECT	@LK3Turnover = SUM(CASE WHEN @DrawFilter IN (2,3) AND b.Status = 111 THEN 0 ELSE ISNULL(b.Turnover,0) END)
		,@LK3CustomerWl = SUM(ISNULL(b.WinLoss,0))
		,@LK3BetCount = SUM(CASE WHEN @DrawFilter = 2 AND b.Status = 111 THEN 0 ELSE ISNULL(b.BetCount,0) END) 
FROM @tblData b
WHERE ProductPrefix ='LK3'

SELECT @LK3Turnover = ISNULL (@LK3Turnover, 0),
	   @LK3CustomerWl = ISNULL (@LK3CustomerWl, 0),
	   @LK3BetCount = ISNULL (@LK3BetCount, 0)  
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
			  , @ABTurnover	 AS AB
			  , @NG2Turnover AS NG2
			  , @FWTurnover  AS FW
			  , @VS2Turnover AS VS2
			  , @LTTurnover  AS LT
			  , @LK3Turnover AS LK3
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
		, @ABCustomerWl
		, @NG2CustomerWl
		, @FWCustomerWl
		, @VS2CustomerWl
		, @LTCustomerWl
		, @LK3CustomerWl
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
		, @ABBetCount
		, @NG2BetCount
		, @FWBetCount
		, @VS2BetCount
		, @LTBetCount
		, @LK3BetCount
SET NOCOUNT OFF


GO
GRANT EXECUTE ON [dbo].[GET_CreditDataToValidate_Betting] TO [bodbLicenseeNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GET_CreditDataToValidate_Betting] TO [vnteam] AS [dbo]