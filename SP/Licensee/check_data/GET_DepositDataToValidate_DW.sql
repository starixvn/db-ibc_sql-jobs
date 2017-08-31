/*<info serverAlias="DBLIC-bodb_Licensee" executers="bodbLicenseeNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[GET_DepositDataToValidate_DW] 
    @Date smalldatetime
    ,@DrawFilter tinyint = 1
AS
/*
Created: 20111208@Don
Task : Get deposit data from table DBWH.bodb_Account.dbo.rptLeague

DB: bodb_Licensee
Original:

Revisions:	
	20131101@daniel: add param sniff to solve wrong plan
	20140310@daniel: exclude currency C & H
	20170822@Harper: Add missing products CB, AB, NG2, FW, CO, VS2, LT into data validation email [RedmineID: #81708]

Param's Explanation:
    @DrawFilter, 1:Normal - 2:No Draws - 3:No Draws For Turnover Only


Examples:

DECLARE @DateChecking SMALLDATETIME
SELECT @DateChecking =DATEADD(day, -10, GETDATE())
exec [GET_DepositDataToValidate_DW] @Date=@DateChecking,@DrawFilter=1
*/

SET NOCOUNT ON

DECLARE @_Date SMALLDATETIME

SELECT @_Date = @Date


DECLARE @SbBaTurnover MONEY
       ,@SbBaCustomerWl MONEY
       ,@SbBaBetCount MONEY,

		@SbTurnover MONEY
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

       --LC
	   ,@LcTurnover MONEY
       ,@LcCustomerWl MONEY
       ,@LcBetCount MONEY
	          
	   --AG
	   ,@AGTurnover MONEY
       ,@AGCustomerWl MONEY
       ,@AGBetCount MONEY
	   --GD
	   ,@GDTurnover MONEY
       ,@GDCustomerWl MONEY
       ,@GDBetCount MONEY
	   --KN
	   ,@KNTurnover MONEY
       ,@KNCustomerWl MONEY
       ,@KNBetCount MONEY
	   --VG: Macau
	   ,@VGTurnover MONEY
       ,@VGCustomerWl MONEY
       ,@VGBetCount MONEY
	   --VB: Macau Games
	   ,@VBTurnover MONEY
       ,@VBCustomerWl MONEY
       ,@VBBetCount MONEY
	   --MGCLC:Microgaming - Live Casino
	   ,@MGCLCTurnover MONEY
       ,@MGCLCCustomerWl MONEY
       ,@MGCLCBetCount MONEY
	   --MGCRNG:Microgaming - RNG Casino
	   ,@MGCRNGTurnover MONEY
       ,@MGCRNGCustomerWl MONEY
       ,@MGCRNGBetCount MONEY
	   ----CS
	   ,@CsTurnover MONEY
       ,@CsCustomerWl MONEY
       ,@CsBetCount MONEY
	    ----VS
	   ,@VsTurnover MONEY
       ,@VsCustomerWl MONEY
       ,@VsBetCount MONEY
	    ----CB
		,@CBTurnover MONEY
		,@CBCustomerWl MONEY
		,@CBBetCount MONEY
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
		----CO
		,@COTurnover MONEY
		,@COCustomerWl MONEY
		,@COBetCount MONEY
		----VS2
		,@VS2Turnover MONEY
		,@VS2CustomerWl MONEY
		,@VS2BetCount MONEY
		----LT
		,@LTTurnover MONEY
		,@LTCustomerWl MONEY
		,@LTBetCount MONEY

-- Ba
SELECT @BaTurnover = SUM(CASE 
                    WHEN @DrawFilter IN (2,3) THEN 
                        CASE WHEN statuslist.StatusID = 111 THEN 0 WHEN statuslist.StatusID IN (114,115) THEN 0.5 ELSE 1 END
                    ELSE 1
                END * b.stake/c.Rate )
    ,@BaCustomerWl=-SUM(  (  WinlostIBC-(WinlostS+WinlostM+WinlostA+Commission)  )/c.Rate  ) 
    ,@BaBetCount=SUM(CASE WHEN @DrawFilter=2 AND statuslist.StatusID=111 THEN 0 ELSE b.BetCount END) 
FROM DBWH.bodb_Account.dbo.rptLeague_BA b WITH(NOLOCK)
    INNER JOIN dbo.view_site_list_dw s (NOLOCK) ON b.division=s.DwSiteID
    INNER JOIN dbo.Licensees lic (NOLOCK) ON s.SiteID=lic.LicenseeID AND IsDeposit=CONVERT(bit,1)
    INNER JOIN DBWH.bodb_Account.dbo.tbl_Currency_Daily c WITH(NOLOCK) ON b.currency=c.Currency AND b.rptDate=c.ExchangeDate
    LEFT JOIN dbo.view_status_list statuslist (NOLOCK) ON b.Status=statuslist.DwStatusID
WHERE b.rptDate=@_date
    AND statuslist.StatusID IN (111,112,113,114,115)
    AND b.currency NOT IN(20,27,28)

SELECT @BaTurnover = ISNULL (@BaTurnover, 0),
	   @BaCustomerWl = ISNULL (@BaCustomerWl, 0),
	   @BaBetCount = ISNULL (@BaBetCount, 0)

-- Sportsbook
-- Sportsbook + Ba
SELECT @SbBaTurnover=SUM(CASE 
                    WHEN @DrawFilter IN (2,3) THEN 
                        CASE WHEN statuslist.StatusID = 111 THEN 0 WHEN statuslist.StatusID IN (114,115) THEN 0.5 ELSE 1 END
                    ELSE 1
                END * b.stake/c.Rate)
    ,@SbBaCustomerWl=-SUM(  (  WinlostIBC-(WinlostS+WinlostM+WinlostA+Commission)  )/c.Rate  )
    ,@SbBaBetCount=SUM(CASE WHEN @DrawFilter=2 AND statuslist.StatusID=111 THEN 0 ELSE b.BetCount END)
FROM DBWH.bodb_Account.dbo.rptLeague b WITH(NOLOCK)
    INNER JOIN dbo.view_site_list_dw s (NOLOCK) ON b.division=s.DwSiteID
    INNER JOIN dbo.Licensees lic (NOLOCK) ON s.SiteID=lic.LicenseeID AND IsDeposit=CONVERT(bit,1)
    INNER JOIN DBWH.bodb_Account.dbo.tbl_Currency_Daily c WITH(NOLOCK) ON b.currency=c.Currency AND b.rptDate=c.ExchangeDate
    LEFT JOIN dbo.view_status_list statuslist (NOLOCK) ON b.Status=statuslist.DwStatusID
WHERE b.rptDate=@_date
    AND ( (b.bettype<31) OR (b.bettype>=121 and b.bettype<1000) OR (b.bettype=18999) )
    AND statuslist.StatusID IN (111,112,113,114,115)
    AND b.currency NOT IN(20,27,28)

SELECT @SbBaTurnover = ISNULL (@SbBaTurnover, 0),
	   @SbBaCustomerWl = ISNULL (@SbBaCustomerWl, 0),
	   @SbBaBetCount = ISNULL (@SbBaBetCount, 0)

	   
SELECT @SbTurnover = @SbBaTurnover - @BaTurnover,
	   @SbCustomerWl = @SbBaCustomerWl - @BaCustomerWl ,
	   @SbBetCount = @SbBaBetCount - @BaBetCount

-- Racing

SELECT @RbTurnover = ISNULL(SUM(Turnover),0)
    ,@RbCustomerWl = ISNULL(SUM(WinlossP),0)
    ,@RbBetCount = ISNULL(SUM(BetCount),0)
FROM DBWH.bodb_Account.dbo.mcDailyRacing b WITH(NOLOCK)
    INNER JOIN dbo.view_site_list_dw s (NOLOCK) ON b.SiteID=s.DwSiteID
    INNER JOIN dbo.Licensees lic (NOLOCK) ON s.SiteID=lic.LicenseeID AND IsDeposit=CONVERT(bit,1)
WHERE b.rptDate=@_date
    AND b.CurrencyID<>20

SELECT @RbTurnover = ISNULL (@RbTurnover, 0),
	   @RbCustomerWl = ISNULL (@RbCustomerWl, 0),
	   @RbBetCount = ISNULL (@RbBetCount, 0)

-- For Another Product
DECLARE @tblSport AS TABLE (ProductPrefix VARCHAR (10),bettype INT)

INSERT INTO @tblSport (ProductPrefix, bettype)
SELECT DISTINCT p.ProductPrefix,s.bettype
FROM bodb02.dbo.SportBettypeMatrix s WITH (NOLOCK)
	INNER JOIN bodb02.dbo.Products p WITH (NOLOCK) ON s.ProductId = p.ProductId
WHERE p.ProductPrefix IN ('NG','LC','VS','CS','KN','AGC','GD','MGCRNG','MGCLC','VG','VB','CB', 'AB', 'NG2', 'FW', 'CO', 'VS2', 'LT')       

DECLARE @tblData AS TABLE (ProductPrefix VARCHAR (10),StatusID INT, stake MONEY,WinLoss MONEY,BetCount INT)
INSERT INTO @tblData (ProductPrefix ,statusID, stake ,WinLoss ,BetCount )
SELECT  	t.ProductPrefix
			,statuslist.StatusID  
			,SUM(b.stake/c.Rate) AS stake		
			,SUM((WinlostIBC-(WinlostS+WinlostM+WinlostA+Commission)  )/c.Rate) AS WinLoss
			,SUM(CASE WHEN @DrawFilter=2 AND statuslist.StatusID=111 THEN 0 ELSE b.BetCount END) AS BetCount
FROM DBWH.bodb_Account.dbo.rptLeague b WITH(NOLOCK)
	INNER JOIN dbo.view_site_list_dw s (NOLOCK) ON b.division=s.DwSiteID
    INNER JOIN dbo.Licensees lic (NOLOCK) ON s.SiteID = lic.LicenseeID AND IsDeposit = CONVERT(bit,1)
    INNER JOIN DBWH.bodb_Account.dbo.tbl_Currency_Daily c WITH(NOLOCK) ON b.currency=c.Currency AND b.rptDate=c.ExchangeDate
	INNER JOIN @tblSport t ON b.bettype = t.bettype
    LEFT JOIN dbo.view_status_list statuslist (NOLOCK) ON b.Status=statuslist.DwStatusID
WHERE b.rptDate = @Date
    AND statuslist.StatusID IN (111,112,113,114,115)
    AND b.currency NOT IN(20,27,28)
    AND b.division=-1
GROUP BY t.ProductPrefix
		 ,statuslist.StatusID 	

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
SELECT @LCTurnover=SUM(CASE WHEN @DrawFilter IN (2,3) AND  StatusID=111 THEN 0 ELSE  stake  END)
    ,@LCCustomerWl=-SUM(WinLoss)
    ,@LCBetCount=SUM(BetCount)
FROM @tblData
WHERE  ProductPrefix = 'LC'

SELECT @LCTurnover = ISNULL (@LCTurnover, 0),
	   @LCCustomerWl = ISNULL (@LCCustomerWl, 0),
	   @LCBetCount = ISNULL (@LCBetCount, 0)

-- VS
SELECT @VSTurnover=SUM(CASE WHEN @DrawFilter IN (2,3) AND  StatusID=111 THEN 0 ELSE  stake  END)
    ,@VSCustomerWl=-SUM( WinLoss)
    ,@VSBetCount=SUM(BetCount)
FROM @tblData
WHERE ProductPrefix = 'VS'
    
SELECT @VSTurnover = ISNULL (@VSTurnover, 0),
	   @VSCustomerWl = ISNULL (@VSCustomerWl, 0),
	   @VSBetCount = ISNULL (@VSBetCount, 0)

-- CS
SELECT @CSTurnover=SUM(CASE WHEN @DrawFilter IN (2,3) AND  StatusID=111 THEN 0 ELSE  stake  END)
    ,@CSCustomerWl=-SUM(WinLoss)
    ,@CSBetCount=SUM(BetCount)
FROM @tblData
WHERE  ProductPrefix = 'CS'

SELECT @CSTurnover = ISNULL (@CSTurnover, 0),
	   @CSCustomerWl = ISNULL (@CSCustomerWl, 0),
	   @CSBetCount = ISNULL (@CSBetCount, 0)

-- KN
SELECT @KNTurnover=SUM(CASE WHEN @DrawFilter IN (2,3) AND  StatusID=111 THEN 0 ELSE  stake  END)
    ,@KNCustomerWl=-SUM( WinLoss)
    ,@KNBetCount=SUM(BetCount)
FROM @tblData
WHERE ProductPrefix = 'KN'
    
SELECT @KNTurnover = ISNULL (@KNTurnover, 0),
	   @KNCustomerWl = ISNULL (@KNCustomerWl, 0),
	   @KNBetCount = ISNULL (@KNBetCount, 0)

-- AGC
SELECT @AGTurnover=SUM(CASE WHEN @DrawFilter IN (2,3) AND  StatusID=111 THEN 0 ELSE  stake  END)
    ,@AGCustomerWl=-SUM(WinLoss)
    ,@AGBetCount=SUM(BetCount)
FROM @tblData
WHERE  ProductPrefix = 'AGC'

SELECT @AGTurnover = ISNULL (@AGTurnover, 0),
	   @AGCustomerWl = ISNULL (@AGCustomerWl, 0),
	   @AGBetCount = ISNULL (@AGBetCount, 0)

-- GD
SELECT @GDTurnover=SUM(CASE WHEN @DrawFilter IN (2,3) AND  StatusID=111 THEN 0 ELSE  stake  END)
    ,@GDCustomerWl=-SUM(WinLoss)
    ,@GDBetCount=SUM(BetCount)
FROM @tblData
WHERE  ProductPrefix = 'GD'

SELECT @GDTurnover = ISNULL (@GDTurnover, 0),
	   @GDCustomerWl = ISNULL (@GDCustomerWl, 0),
	   @GDBetCount = ISNULL (@GDBetCount, 0)

-- MGCRNG
SELECT @MGCRNGTurnover=SUM(CASE WHEN @DrawFilter IN (2,3) AND  StatusID=111 THEN 0 ELSE  stake  END)
    ,@MGCRNGCustomerWl=-SUM( WinLoss)
    ,@MGCRNGBetCount=SUM(BetCount)
FROM @tblData
WHERE ProductPrefix = 'MGCRNG'
    
SELECT @MGCRNGTurnover = ISNULL (@MGCRNGTurnover, 0),
	   @MGCRNGCustomerWl = ISNULL (@MGCRNGCustomerWl, 0),
	   @MGCRNGBetCount = ISNULL (@MGCRNGBetCount, 0)

-- MGCLC
SELECT @MGCLCTurnover=SUM(CASE WHEN @DrawFilter IN (2,3) AND  StatusID=111 THEN 0 ELSE  stake  END)
    ,@MGCLCCustomerWl=-SUM(WinLoss)
    ,@MGCLCBetCount=SUM(BetCount)
FROM @tblData
WHERE  ProductPrefix = 'MGCLC'

SELECT @MGCLCTurnover = ISNULL (@MGCLCTurnover, 0),
	   @MGCLCCustomerWl = ISNULL (@MGCLCCustomerWl, 0),
	   @MGCLCBetCount = ISNULL (@MGCLCBetCount, 0)

-- VG
SELECT @VGTurnover=SUM(CASE WHEN @DrawFilter IN (2,3) AND  StatusID=111 THEN 0 ELSE  stake  END)
    ,@VGCustomerWl=-SUM( WinLoss)
    ,@VGBetCount=SUM(BetCount)
FROM @tblData
WHERE ProductPrefix = 'VG'
    
SELECT @VGTurnover = ISNULL (@VGTurnover, 0),
	   @VGCustomerWl = ISNULL (@VGCustomerWl, 0),
	   @VGBetCount = ISNULL (@VGBetCount, 0)

-- VB
SELECT @VBTurnover=SUM(CASE WHEN @DrawFilter IN (2,3) AND  StatusID=111 THEN 0 ELSE  stake  END)
    ,@VBCustomerWl=-SUM(WinLoss)
    ,@VBBetCount=SUM(BetCount)
FROM @tblData
WHERE  ProductPrefix = 'VB'

SELECT @VBTurnover = ISNULL (@VBTurnover, 0),
	   @VBCustomerWl = ISNULL (@VBCustomerWl, 0),
	   @VBBetCount = ISNULL (@VBBetCount, 0)

-- CB
SELECT @CBTurnover=SUM(CASE WHEN @DrawFilter IN (2,3) AND  StatusID = 111 THEN 0 ELSE  stake END)
       ,@CBCustomerWl=-SUM(WinLoss )
	   ,@CBBetCount=SUM(BetCount)
FROM @tblData
WHERE  ProductPrefix = 'CB'

SELECT @CBTurnover = ISNULL (@CBTurnover, 0),
	   @CBCustomerWl = ISNULL (@CBCustomerWl, 0),
	   @CBBetCount = ISNULL (@CBBetCount, 0)
-- AB
SELECT @ABTurnover = SUM(CASE WHEN @DrawFilter IN (2,3) AND StatusID = 111 THEN 0 ELSE stake END)
       ,@ABCustomerWl = -SUM(WinLoss )
	   ,@ABBetCount = SUM(BetCount)
FROM @tblData
WHERE  ProductPrefix = 'AB'

SELECT @ABTurnover = ISNULL (@ABTurnover, 0),
	   @ABCustomerWl = ISNULL (@ABCustomerWl, 0),
	   @ABBetCount = ISNULL (@ABBetCount, 0)	
	   
-- NG2
SELECT @NG2Turnover = SUM(CASE WHEN @DrawFilter IN (2,3) AND StatusID = 111 THEN 0 ELSE stake END)
       ,@NG2CustomerWl = -SUM(WinLoss )
	   ,@NG2BetCount = SUM(BetCount)
FROM @tblData
WHERE  ProductPrefix = 'NG2'

SELECT @NG2Turnover = ISNULL (@NG2Turnover, 0),
	   @NG2CustomerWl = ISNULL (@NG2CustomerWl, 0),
	   @NG2BetCount = ISNULL (@NG2BetCount, 0)	   

-- FW
SELECT @FWTurnover = SUM(CASE WHEN @DrawFilter IN (2,3) AND StatusID = 111 THEN 0 ELSE stake END)
       ,@FWCustomerWl = -SUM(WinLoss )
	   ,@FWBetCount = SUM(BetCount)
FROM @tblData
WHERE  ProductPrefix = 'FW'

SELECT @FWTurnover = ISNULL (@FWTurnover, 0),
	   @FWCustomerWl = ISNULL (@FWCustomerWl, 0),
	   @FWBetCount = ISNULL (@FWBetCount, 0)	

-- CO
SELECT @FWTurnover = SUM(CASE WHEN @DrawFilter IN (2,3) AND StatusID = 111 THEN 0 ELSE stake END)
       ,@FWCustomerWl = -SUM(WinLoss )
	   ,@FWBetCount = SUM(BetCount)
FROM @tblData
WHERE  ProductPrefix = 'CO'

SELECT @FWTurnover = ISNULL (@FWTurnover, 0),
	   @FWCustomerWl = ISNULL (@FWCustomerWl, 0),
	   @FWBetCount = ISNULL (@FWBetCount, 0)
	   
-- VS2
SELECT @VS2Turnover = SUM(CASE WHEN @DrawFilter IN (2,3) AND StatusID = 111 THEN 0 ELSE stake END)
       ,@VS2CustomerWl = -SUM(WinLoss )
	   ,@VS2BetCount = SUM(BetCount)
FROM @tblData
WHERE  ProductPrefix = 'VS2'

SELECT @VS2Turnover = ISNULL (@VS2Turnover, 0),
	   @VS2CustomerWl = ISNULL (@VS2CustomerWl, 0),
	   @VS2BetCount = ISNULL (@VS2BetCount, 0)	

-- LT
SELECT @LTTurnover = SUM(CASE WHEN @DrawFilter IN (2,3) AND StatusID = 111 THEN 0 ELSE stake END)
       ,@LTCustomerWl = -SUM(WinLoss )
	   ,@LTBetCount = SUM(BetCount)
FROM @tblData
WHERE  ProductPrefix = 'LT'

SELECT @LTTurnover = ISNULL (@LTTurnover, 0),
	   @LTCustomerWl = ISNULL (@LTCustomerWl, 0),
	   @LTBetCount = ISNULL (@LTBetCount, 0)	

-- Result

SELECT 1 AS Id, @SbTurnover AS Sb
				, @RbTurnover AS Rb 
				, @NgTurnover AS Ng 
				, @BaTurnover AS Ba 
				, @CsTurnover AS Cs
				, @CBTurnover  AS CB
				, @ABTurnover  AS AB
				, @NG2Turnover AS NG2
				, @FWTurnover  AS FW
				, @COTurnover  AS CO
				, @VS2Turnover AS VS2
				, @LTTurnover  AS LT
UNION
SELECT 2, @SbCustomerWl
		, @RbCustomerWl
		, @NgCustomerWl
		, @BaCustomerWl
		, @CsCustomerWl
		, @CBCustomerWl	
		, @ABCustomerWl
		, @NG2CustomerWl
		, @FWCustomerWl
		, @COCustomerWl
		, @VS2CustomerWl
		, @LTCustomerWl
UNION
SELECT 3, @SbBetCount
	, @RbBetCount
	, @NgBetCount
	, @BaBetCount
	, @CsBetCount
	, @CBBetCount
	, @ABBetCount
	, @NG2BetCount
	, @FWBetCount
	, @COBetCount
	, @VS2BetCount
	, @LTBetCount
SET NOCOUNT OFF
GO
