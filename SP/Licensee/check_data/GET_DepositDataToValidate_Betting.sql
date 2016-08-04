USE [bodb_Licensee]
GO
ALTER PROCEDURE [dbo].[GET_DepositDataToValidate_Betting] 
    @Date smalldatetime = null
    ,@DrawFilter tinyint = 1
AS
/*
Created: 20111208@Don
Task : Get deposit data from table db052.bodb_Licensee.dbo.rpt_Betting

DB: bodb_Licensee
Original:

Revisions:	
	- 20140310@daniel: exclude currency C & H
	- 20160608@Jim: Separate Bettrade (#57353)
	- 20160616@Jim: Changes to data integrity automail (#59249)	
Param's Explanation:
    @DrawFilter, 1:Normal - 2:No Draws - 3:No Draws For Turnover Only
    
    
Examples:

DECLARE @DateChecking SMALLDATETIME
SELECT @DateChecking =DATEADD(day, -10, GETDATE())
exec [GET_DepositDataToValidate_Betting] @Date=@DateChecking,@DrawFilter=1

*/

SET NOCOUNT ON
DECLARE --SB
		@SbTurnover MONEY
       ,@SbCustomerWl MONEY
       ,@SbBetCount MONEY
       --RB
	   ,@RbTurnover MONEY
       ,@RbCustomerWl MONEY
       ,@RbBetCount MONEY
       --NG
	   ,@NgTurnover MONEY
       ,@NgCustomerWl MONEY
       ,@NgBetCount MONEY
       -- BA
	   ,@BaTurnover MONEY
       ,@BaCustomerWl MONEY
       ,@BaBetCount MONEY
       --LC
	   ,@LcTurnover MONEY
       ,@LcCustomerWl MONEY
       ,@LcBetCount MONEY
		--BT
	   ,@BTTurnover MONEY
       ,@BTCustomerWl MONEY
       ,@BTBetCount MONEY
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
	   
DECLARE @tblBettype AS TABLE(ProductPrefix VARCHAR (10),Bettype INT)	   
INSERT INTO @tblBettype (ProductPrefix,Bettype)
SELECT DISTINCT ProductPrefix,bettype
FROM bodb02.dbo.SportBettypeMatrix s WITH (NOLOCK)
	INNER JOIN bodb02.dbo.Products p WITH (NOLOCK) ON s.ProductId = p.ProductId
WHERE p.ProductPrefix IN ('SB','RB','NG','LC','VS','CS','KN','AGC','GD','MGCRNG','MGCLC','VG','VB')	
 
-- Data Source 
DECLARE @tblData AS TABLE (ProductPrefix VARCHAR (10),Status INT, Turnover MONEY, Winloss MONEY,BetCount INT)	

INSERT INTO @tblData  (ProductPrefix ,Status,Turnover,Winloss,BetCount)	
SELECT  CASE WHEN b.bettype IN (901,902,903) THEN 'BT' ELSE t.ProductPrefix END 
		 ,Status
		 ,SUM(TurnOver) TurnOver
		 ,SUM(Winloss) Winloss
		 ,SUM(Betcount) Betcount
FROM dbo.rpt_Betting b (NOLOCK)
    INNER JOIN dbo.Licensees lic (NOLOCK) ON b.SiteID=lic.LicenseeID AND IsDeposit=CONVERT(bit,1)
	INNER JOIN @tblBettype t ON b.bettype = t.bettype 
WHERE b.rptDate=@Date
	AND b.Status IN (111,112,113,114,115)
    AND b.currencyID NOT IN(20,27,28)
GROUP BY CASE WHEN b.bettype IN (901,902,903) THEN 'BT' ELSE t.ProductPrefix END 
		 ,Status	
  
---SB
SELECT @SbTurnover=SUM(CASE 
                    WHEN @DrawFilter IN (2,3) THEN 
                        CASE WHEN Status = 111 THEN 0 WHEN Status IN (114,115) THEN 0.5 ELSE 1 END
                    ELSE 1
                END *Turnover)
    ,@SbCustomerWl=SUM(WinLoss)
    ,@SbBetCount=SUM(CASE WHEN @DrawFilter=2 AND Status = 111 THEN 0 ELSE BetCount END)
FROM @tblData 
WHERE ProductPrefix = 'SB'

SELECT @SbTurnover 	 = ISNULL (@SbTurnover, 0),
	   @SbCustomerWl = ISNULL (@SbCustomerWl, 0),
	   @SbBetCount 	 = ISNULL (@SbBetCount, 0)
	   
-- Bettrade
SELECT @BTTurnover = SUM(CASE 
                    WHEN @DrawFilter IN (2,3) THEN 
                        CASE WHEN b.Status = 111 THEN 0 WHEN b.Status IN (114,115) THEN 0.5 ELSE 1 END
                    ELSE 1
                   END * b.Turnover)
    ,@BTCustomerWl = SUM(b.WinLoss)
    ,@BTBetCount   = SUM(CASE WHEN @DrawFilter=2 AND b.Status = 111 THEN 0 ELSE b.BetCount END)
FROM @tblData b
WHERE ProductPrefix = 'BT'

SELECT @BTTurnover 	 = ISNULL (@BTTurnover, 0),
	   @BTCustomerWl = ISNULL (@BTCustomerWl, 0),
	   @BTBetCount   = ISNULL (@BTBetCount, 0)
	   
-- Racing
SELECT @RbTurnover = SUM(CASE WHEN b.Status IN (114,115) THEN 0.5 ELSE 1 END * b.Turnover) 
		,@RbCustomerWl = SUM(b.WinLoss)
		,@RbBetCount = SUM(b.BetCount)
FROM @tblData b
WHERE ProductPrefix = 'RB'

SELECT @RbTurnover 	 = ISNULL (@RbTurnover, 0),
	   @RbCustomerWl = ISNULL (@RbCustomerWl, 0),
	   @RbBetCount 	 = ISNULL (@RbBetCount, 0)
-- Number Game
SELECT @NgTurnover=SUM(CASE WHEN @DrawFilter IN (2,3) AND b.Status = 111 THEN 0 ELSE b.Turnover END)
    ,@NgCustomerWl=SUM(b.WinLoss)
    ,@NgBetCount=SUM(CASE WHEN @DrawFilter=2 AND b.Status = 111 THEN 0 ELSE b.BetCount END) 
FROM @tblData b
WHERE ProductPrefix = 'NG'

SELECT @NgTurnover 	 = ISNULL (@NgTurnover, 0),
	   @NgCustomerWl = ISNULL (@NgCustomerWl, 0),
	   @NgBetCount 	 = ISNULL (@NgBetCount, 0)
-- Ba
SELECT @BaTurnover=SUM(CASE 
                    WHEN @DrawFilter IN (2,3) THEN 
                        CASE WHEN b.Status = 111 THEN 0 WHEN b.Status IN (114,115) THEN 0.5 ELSE 1 END
                    ELSE 1
                END * b.Turnover)
    ,@BaCustomerWl=SUM(b.WinLoss) 
    ,@BaBetCount=SUM(CASE WHEN @DrawFilter=2 AND b.Status = 111 THEN 0 ELSE b.BetCount END) 
FROM dbo.rpt_Betting_BA b (NOLOCK)
    INNER JOIN dbo.Licensees lic (NOLOCK) ON b.SiteID=lic.LicenseeID AND IsDeposit=CONVERT(bit,1)
WHERE b.rptDate=@Date
    AND b.Status IN (111,112,113,114,115)
    AND b.currencyID NOT IN(20,27,28)

SELECT @BaTurnover   = ISNULL (@BaTurnover, 0),
	   @BaCustomerWl = ISNULL (@BaCustomerWl, 0),
	   @BaBetCount   = ISNULL (@BaBetCount, 0)
-- Live Casino

SELECT @LcTurnover=SUM(CASE 
                    WHEN @DrawFilter IN (2,3) THEN 
                        CASE WHEN b.Status = 111 THEN 0 WHEN b.Status IN (114,115) THEN 0.5 ELSE 1 END
                    ELSE 1
                END * b.Turnover)
    ,@LcCustomerWl=SUM(b.WinLoss)
    ,@LcBetCount=SUM(CASE WHEN @DrawFilter=2 AND b.Status = 111 THEN 0 ELSE b.BetCount END) 
FROM @tblData b
WHERE ProductPrefix = 'LC'

SELECT @LcTurnover   = ISNULL (@LcTurnover, 0),
	   @LcCustomerWl = ISNULL (@LcCustomerWl, 0),
	   @LcBetCount   = ISNULL (@LcBetCount, 0)
-- AG
SELECT @AGTurnover=SUM(CASE 
                    WHEN @DrawFilter IN (2,3) THEN 
                        CASE WHEN b.Status = 111 THEN 0 WHEN b.Status IN (114,115) THEN 0.5 ELSE 1 END
                    ELSE 1
                END * b.Turnover)
    ,@AGCustomerWl=SUM(b.WinLoss)
    ,@AGBetCount=SUM(CASE WHEN @DrawFilter=2 AND b.Status = 111 THEN 0 ELSE b.BetCount END) 
FROM @tblData b
WHERE ProductPrefix = 'AGC'

SELECT @AGTurnover    = ISNULL(@AGTurnover,0)
	   ,@AGCustomerWl = ISNULL(@AGCustomerWl,0)
	   ,@AGBetCount   = ISNULL(@AGBetCount,0)
---KN
SELECT  @KNTurnover=SUM(CASE 
                    WHEN @DrawFilter IN (2,3) THEN 
                        CASE WHEN b.Status = 111 THEN 0 WHEN b.Status IN (114,115) THEN 0.5 ELSE 1 END
                    ELSE 1
                END * b.Turnover)
		,@KNCustomerWl=SUM(b.WinLoss)
		,@KNBetCount=SUM(CASE WHEN @DrawFilter=2 AND b.Status = 111 THEN 0 ELSE b.BetCount END) 
FROM @tblData b
WHERE ProductPrefix = 'KN'
SELECT @KNTurnover  	= ISNULL(@KNTurnover,0)
       ,@KNCustomerWl   = ISNULL(@KNCustomerWl,0)
       ,@KNBetCount   	= ISNULL(@KNBetCount,0)
-- Gold Deluxe
SELECT  @GDTurnover=SUM(CASE WHEN @DrawFilter IN (2,3) AND b.Status = 111 THEN 0 ELSE b.Turnover END)
		,@GDCustomerWl=SUM(b.WinLoss)
		,@GDBetCount=SUM(CASE WHEN @DrawFilter=2 AND b.Status = 111 THEN 0 ELSE b.BetCount END) 
FROM @tblData b
WHERE ProductPrefix = 'GD'

SELECT  @GDTurnover 	= ISNULL(@GDTurnover,0)
       ,@GDCustomerWl 	= ISNULL(@GDCustomerWl,0)
       ,@GDBetCount 	= ISNULL(@GDBetCount,0)
--VG: Macau
 SELECT  @VGTurnover=SUM(CASE WHEN @DrawFilter IN (2,3) AND b.Status = 111 THEN 0 ELSE b.Turnover END)
		,@VGCustomerWl=SUM(b.WinLoss)
		,@VGBetCount=SUM(CASE WHEN @DrawFilter=2 AND b.Status = 111 THEN 0 ELSE b.BetCount END) 
FROM @tblData b
WHERE ProductPrefix = 'VG'
SELECT  @VGTurnover  	= ISNULL(@VGTurnover,0)	
       ,@VGCustomerWl   = ISNULL(@VGCustomerWl,0)
       ,@VGBetCount     = ISNULL(@VGBetCount,0)
 --VB: Macau Games
SELECT  @VBTurnover=SUM(CASE 
                    WHEN @DrawFilter IN (2,3) THEN 
                        CASE WHEN b.Status = 111 THEN 0 WHEN b.Status IN (114,115) THEN 0.5 ELSE 1 END
                    ELSE 1
                END * b.Turnover)
		,@VBCustomerWl=SUM(b.WinLoss)
		,@VBBetCount=SUM(CASE WHEN @DrawFilter=2 AND b.Status = 111 THEN 0 ELSE b.BetCount END) 
FROM @tblData b
WHERE ProductPrefix = 'VB'
 SELECT @VBTurnover 	= ISNULL(@VBTurnover,0)	
       ,@VBCustomerWl 	= ISNULL(@VBCustomerWl,0)
       ,@VBBetCount 	= ISNULL(@VBBetCount,0)
 --MGCLC:Microgaming - Live Casino
SELECT  @MGCLCTurnover=SUM(CASE 
                    WHEN @DrawFilter IN (2,3) THEN 
                        CASE WHEN b.Status = 111 THEN 0 WHEN b.Status IN (114,115) THEN 0.5 ELSE 1 END
                    ELSE 1
                END * b.Turnover)
		,@MGCLCCustomerWl=SUM(b.WinLoss)
		,@MGCLCBetCount=SUM(CASE WHEN @DrawFilter=2 AND b.Status = 111 THEN 0 ELSE b.BetCount END) 
FROM @tblData b
WHERE ProductPrefix = 'MGCLC'

 SELECT  @MGCLCTurnover     = ISNULL(@MGCLCTurnover,0)	
         ,@MGCLCCustomerWl  = ISNULL(@MGCLCCustomerWl,0)
         ,@MGCLCBetCount    = ISNULL(@MGCLCBetCount,0)
	   
  --MGCRNG:Microgaming - RNG Casino
 SELECT  @MGCRNGTurnover=SUM(CASE 
                    WHEN @DrawFilter IN (2,3) THEN 
                        CASE WHEN b.Status = 111 THEN 0 WHEN b.Status IN (114,115) THEN 0.5 ELSE 1 END
                    ELSE 1
                END * b.Turnover)
		,@MGCRNGCustomerWl=SUM(b.WinLoss)
		,@MGCRNGBetCount=SUM(CASE WHEN @DrawFilter=2 AND b.Status = 111 THEN 0 ELSE b.BetCount END) 
FROM @tblData b
WHERE ProductPrefix = 'MGCRNG'
 
SELECT  @MGCRNGTurnover 	= ISNULL(@MGCRNGTurnover,0)
        ,@MGCRNGCustomerWl  = ISNULL(@MGCRNGCustomerWl,0)
	    ,@MGCRNGBetCount    = ISNULL(@MGCRNGBetCount,0)	
 ----CS
 SELECT  @CsTurnover=SUM(CASE 
                    WHEN @DrawFilter IN (2,3) THEN 
                        CASE WHEN b.Status = 111 THEN 0 WHEN b.Status IN (114,115) THEN 0.5 ELSE 1 END
                    ELSE 1
                END * b.Turnover)
		,@CsCustomerWl=SUM(b.WinLoss)
		,@CsBetCount=SUM(CASE WHEN @DrawFilter=2 AND b.Status = 111 THEN 0 ELSE b.BetCount END) 
FROM @tblData b
WHERE ProductPrefix = 'CS'
SELECT  @CsTurnover   = ISNULL(@CsTurnover,0)
       ,@CsCustomerWl = ISNULL(@CsCustomerWl,0)
       ,@CsBetCount   = ISNULL(@CsBetCount,0)	
----VS
 SELECT  @VsTurnover=SUM(CASE 
                    WHEN @DrawFilter IN (2,3) THEN 
                        CASE WHEN b.Status = 111 THEN 0 WHEN b.Status IN (114,115) THEN 0.5 ELSE 1 END
                    ELSE 1
                END * b.Turnover)
		,@VsCustomerWl=SUM(b.WinLoss)
		,@VsBetCount=SUM(CASE WHEN @DrawFilter=2 AND b.Status = 111 THEN 0 ELSE b.BetCount END) 
FROM @tblData b
WHERE ProductPrefix = 'VS'
SELECT @VsTurnover 		= ISNULL(@VsTurnover,0)
       ,@VsCustomerWl	= ISNULL(@VsCustomerWl,0)
       ,@VsBetCount 	= ISNULL(@VsBetCount,0)	
	   
 
-- Result

SELECT 1 AS Id, @SbTurnover AS Sb
			  , @RbTurnover AS Rb
			  , @NgTurnover AS Ng
			  , @BaTurnover AS Ba
			  , @CsTurnover AS Cs
			  , @BTTurnover AS BT
			  , @LcTurnover AS LC
			  , @AGTurnover as AG
			  , @GDTurnover AS GD
			  , @KNTurnover AS KN
			  , @VGTurnover AS VG
			  , @VBTurnover AS VB 
			  , @MGCLCTurnover  AS MGCLC 
			  , @MGCRNGTurnover AS  MGCRNG
			  , @VsTurnover AS VS
			  
UNION
SELECT 2, @SbCustomerWl
		, @RbCustomerWl
		, @NgCustomerWl
		, @BaCustomerWl
		, @CsCustomerWl
		, @BTCustomerWl
		, @LcCustomerWl
		, @AGCustomerWl
		, @GDCustomerWl 
		, @KNCustomerWl
		, @VGCustomerWl
		, @VBCustomerWl
		, @MGCLCCustomerWl
		, @MGCRNGCustomerWl
		, @VsCustomerWl
UNION
SELECT 3, @SbBetCount
		, @RbBetCount
		, @NgBetCount
		, @BaBetCount
		, @CsBetCount
		, @BTBetCount
		, @LcBetCount
		, @AGBetCount
		, @GDBetCount
		, @KNBetCount
		, @VGBetCount
		, @VBBetCount
		, @MGCLCBetCount
		, @MGCRNGBetCount
		, @VsBetCount	

SET NOCOUNT OFF
 GO
 GRANT EXECUTE ON [dbo].[GET_DepositDataToValidate_Betting] TO [bodbLicenseeNet]  