
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.GET_CreditDataToValidate_DW    Script Date: 7/4/2016 1:07:46 PM ******/

CREATE PROCEDURE [dbo].[GET_CreditDataToValidate_DW]
     @Date smalldatetime 
	,@DrawFilter tinyint = 1
AS
/*
Created: 20120307@Don
Task : Get credit data from table DBWH.bodb_Account.dbo.rptLeague

DB: DBLIC/bodb_Licensee
Original:

Revisions:	
	- 20121204@Don: Add more validating for Live Casino, RNG Casino and Virtual Sport
	- 20140310@daniel: exclude currency C & H
	- 20150119@daniel: Fix SB bettype condition
	- 20160523@Francis: Change bettype range for RNG Casino (hotfix #55730)
	- 20160602@Jim: include Casino refund ticket (#58453)
	- 20160616@Jim: Changes to data integrity automail (#59249)	
Param's Explanation:
    @DrawFilter, 1:Normal - 2:No Draws - 3:No Draws For Turnover Only
    
DECLARE @DateChecking SMALLDATETIME
SELECT @DateChecking =DATEADD(day, -10, GETDATE())
exec [GET_CreditDataToValidate_DW] @Date=@DateChecking,@DrawFilter=1
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

DECLARE @tblData AS TABLE (ProductPrefix VARCHAR (10),StatusID INT, stake MONEY,WinLoss MONEY,BetCount INT)
INSERT INTO @tblData (ProductPrefix ,statusID, stake ,WinLoss ,BetCount )
SELECT  	t.ProductPrefix
			,statuslist.StatusID  
			,SUM(b.stake/c.Rate) AS stake		
			,SUM((WinlostIBC-(WinlostS+WinlostM+WinlostA+Commission)  )/c.Rate) AS WinLoss
			,SUM(CASE WHEN @DrawFilter=2 AND statuslist.StatusID=111 THEN 0 ELSE b.BetCount END) AS BetCount
FROM DBWH.bodb_Account.dbo.rptLeague b WITH(NOLOCK)
    INNER JOIN DBWH.bodb_Account.dbo.tbl_Currency_Daily c WITH(NOLOCK) ON b.currency=c.Currency AND b.rptDate=c.ExchangeDate
	INNER JOIN @tblSport t ON b.bettype = t.bettype
    LEFT JOIN dbo.view_status_list statuslist (NOLOCK) ON b.Status=statuslist.DwStatusID
WHERE b.rptDate=@Date
    AND statuslist.StatusID IN (111,112,113,114,115)
    AND b.currency NOT IN(20,27,28)
    AND b.division=-1
GROUP BY t.ProductPrefix
		 ,statuslist.StatusID 	
-- Sportbook
SELECT @SbTurnover=SUM(
                CASE 
                     WHEN @DrawFilter IN (2,3) THEN 
                        CASE WHEN  StatusID = 111 THEN 0 WHEN  StatusID IN (114,115) THEN 0.5 ELSE 1 END
                    ELSE 1
                END *  stake )
    ,@SbCustomerWl=-SUM(WinLoss)
    ,@SbBetCount=SUM(BetCount)
FROM @tblData
WHERE ProductPrefix = 'SB'

SELECT @SbTurnover = ISNULL (@SbTurnover, 0),
	   @SbCustomerWl = ISNULL (@SbCustomerWl, 0),
	   @SbBetCount = ISNULL (@SbBetCount, 0)

-- Racing

SELECT @RbTurnover = SUM(Turnover)
    ,@RbCustomerWl = SUM(WinlossP)
    ,@RbBetCount = SUM(BetCount)
FROM DBWH.bodb_Account.dbo.mcDailyRacing b WITH(NOLOCK)
    LEFT JOIN DBWH.bodb_Account.dbo.tbl_Site s WITH(NOLOCK) ON b.SiteID=s.siteid
WHERE b.rptDate=@Date
    AND b.CurrencyID NOT IN(20,27,28)
    AND ISNULL(s.IsDeposit,0)=0

SELECT @RbTurnover = ISNULL(@RbTurnover, 0),
	   @RbCustomerWl = ISNULL (@RbCustomerWl, 0),
	   @RbBetCount = ISNULL (@RbBetCount, 0)
	   
-- Number Game

SELECT @NgTurnover=SUM(CASE WHEN @DrawFilter IN (2,3) AND  StatusID=111 THEN 0 ELSE  stake  END)
    ,@NgCustomerWl=-SUM( WinLoss)
    ,@NgBetCount=SUM(BetCount)
FROM @tblData
WHERE ProductPrefix = 'NG'
    
SELECT @NgTurnover = ISNULL (@NgTurnover, 0),
	   @NgCustomerWl = ISNULL (@NgCustomerWl, 0),
	   @NgBetCount = ISNULL (@NgBetCount, 0)
    
-- Live Casino

SELECT @LCTurnover=SUM(CASE WHEN @DrawFilter IN (2,3) AND  StatusID=111 THEN 0 ELSE stake  END)
    ,@LCCustomerWl=-SUM(WinLoss)
    ,@LCBetCount=SUM(BetCount)
FROM @tblData
WHERE  ProductPrefix = 'LC'

SELECT @LCTurnover = ISNULL (@LCTurnover, 0),
	   @LCCustomerWl = ISNULL (@LCCustomerWl, 0),
	   @LCBetCount = ISNULL (@LCBetCount, 0)

-- RNG Casino

SELECT @CSTurnover=SUM(CASE WHEN @DrawFilter IN (2,3) AND  StatusID=111 THEN 0 ELSE  stake  END)
    ,@CSCustomerWl=-SUM(WinLoss)
    ,@CSBetCount=SUM(BetCount)
FROM @tblData
WHERE  ProductPrefix = 'CS'

SELECT @CSTurnover = ISNULL (@CSTurnover, 0),
	   @CSCustomerWl = ISNULL (@CSCustomerWl, 0),
	   @CSBetCount = ISNULL (@CSBetCount, 0)

-- Virtual Sport

SELECT @VsTurnover=SUM(CASE WHEN @DrawFilter IN (2,3) AND  StatusID = 111 THEN 0 ELSE  stake END)
      ,@VsCustomerWl=-SUM(WinLoss )
    ,@VsBetCount=SUM(BetCount)
FROM @tblData
WHERE  ProductPrefix = 'VS'

SELECT @VsTurnover = ISNULL (@VsTurnover, 0),
	   @VsCustomerWl = ISNULL (@VsCustomerWl, 0),
	   @VsBetCount = ISNULL (@VsBetCount, 0)
-- CB

SELECT @CBTurnover=SUM(CASE WHEN @DrawFilter IN (2,3) AND  StatusID = 111 THEN 0 ELSE  stake END)
       ,@CBCustomerWl=-SUM(WinLoss )
	   ,@CBBetCount=SUM(BetCount)
FROM @tblData
WHERE  ProductPrefix = 'CB'

SELECT @CBTurnover = ISNULL (@CBTurnover, 0),
	   @CBCustomerWl = ISNULL (@CBCustomerWl, 0),
	   @CBBetCount = ISNULL (@CBBetCount, 0)
-- GD

SELECT @GDTurnover=SUM(CASE WHEN @DrawFilter IN (2,3) AND  StatusID = 111 THEN 0 ELSE  stake END)
       ,@GDCustomerWl=-SUM(WinLoss )
	   ,@GDBetCount=SUM(BetCount)
FROM @tblData
WHERE  ProductPrefix = 'GD'

SELECT @GDTurnover = ISNULL (@GDTurnover, 0),
	   @GDCustomerWl = ISNULL (@GDCustomerWl, 0),
	   @GDBetCount = ISNULL (@GDBetCount, 0)
-- KN

SELECT @KNTurnover=SUM(CASE WHEN @DrawFilter IN (2,3) AND  StatusID = 111 THEN 0 ELSE  stake END)
       ,@KNCustomerWl=-SUM(WinLoss )
	   ,@KNBetCount=SUM(BetCount)
FROM @tblData
WHERE  ProductPrefix = 'KN'

SELECT @KNTurnover = ISNULL (@KNTurnover, 0),
	   @KNCustomerWl = ISNULL (@KNCustomerWl, 0),
	   @KNBetCount = ISNULL (@KNBetCount, 0)	   
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
 GRANT VIEW DEFINITION ON [dbo].[GET_CreditDataToValidate_DW] TO [vnteam]
GO 
 GRANT EXECUTE ON [dbo].[GET_CreditDataToValidate_DW] TO [bodbLicenseeNet]
GO 
