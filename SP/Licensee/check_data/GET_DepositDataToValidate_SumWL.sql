/*<info serverAlias="DBLIC-bodb_Licensee" executers="bodbLicenseeNet" viewers="" isFunction="0" isNested="0"></info>*/
USE bodb_Licensee
GO
ALTER PROCEDURE [dbo].[GET_DepositDataToValidate_SumWL] 
    @Date smalldatetime
	,@DrawFilter tinyint = 1
AS
/*
Created: 20111213@Don
Task : Get deposit data from table db052.bodb02.dbo.sum_winloss

DB: bodb_Licensee
Original:

Revisions:	
- 20140310@daniel: exclude currency C & H
- 20160608@Jim: Separate Bettrade (#57353) 	
- 20160616@Jim: Changes to data integrity automail (#59249)	
- 20170822@Harper: Add missing products CB, AB, NG2, FW, CO, VS2, LT into data validation email [RedmineID: #81708]
- 20180418@Joseph: Integrate new product PP [Redmine: #92318]
- 20190710@Amanda: Integrate Card Club [RedmineID: #115449]

Param's Explanation:
    @DrawFilter Only support 1:Normal 
		Not support 2:No Draws - 3:No Draws For Turnover Only

Examples:

DECLARE @DateChecking SMALLDATETIME
SELECT @DateChecking =DATEADD(day, -10, GETDATE())
exec [GET_DepositDataToValidate_SumWL] @Date=@DateChecking,@DrawFilter=1
*/
BEGIN
	SET NOCOUNT ON

	IF @DrawFilter <> 1
	BEGIN
	
		SELECT 1 AS Id, CONVERT(MONEY, 0) AS Sb, CONVERT(MONEY, 0) AS Rb, CONVERT(MONEY, 0) AS Ng , CONVERT(MONEY, 0)  AS BA,CONVERT(MONEY, 0) AS CS,  CONVERT(MONEY, 0) AS BT,CONVERT(MONEY, 0) AS LC, CONVERT(MONEY, 0) AS AG ,CONVERT(MONEY, 0) AS GD,CONVERT(MONEY, 0) AS KN ,CONVERT(MONEY, 0) AS VG,CONVERT(MONEY, 0) AS VB,CONVERT(MONEY, 0) AS MGCLC,CONVERT(MONEY, 0) AS MGCRNG, CONVERT(MONEY, 0) AS VS
					, CONVERT(MONEY, 0) AS CB, CONVERT(MONEY, 0) AS AB, CONVERT(MONEY, 0) AS NG2, CONVERT(MONEY, 0) AS FW, CONVERT(MONEY, 0) AS CO, CONVERT(MONEY, 0) AS VS2, CONVERT(MONEY, 0) AS LT, CONVERT(MONEY, 0) AS PP, CONVERT(MONEY, 0) AS CC
		UNION
		SELECT 2, CONVERT(MONEY, 0), CONVERT(MONEY, 0), CONVERT(MONEY, 0),  CONVERT(MONEY, 0) ,CONVERT(MONEY, 0),CONVERT(MONEY, 0),CONVERT(MONEY, 0),CONVERT(MONEY, 0),CONVERT(MONEY, 0) ,CONVERT(MONEY, 0) ,CONVERT(MONEY, 0),CONVERT(MONEY, 0),CONVERT(MONEY, 0),CONVERT(MONEY, 0),CONVERT(MONEY, 0)
					, CONVERT(MONEY, 0), CONVERT(MONEY, 0), CONVERT(MONEY, 0), CONVERT(MONEY, 0), CONVERT(MONEY, 0), CONVERT(MONEY, 0), CONVERT(MONEY, 0), CONVERT(MONEY, 0), CONVERT(MONEY, 0)
		UNION
		SELECT 3, CONVERT(MONEY, 0)t, CONVERT(MONEY, 0), CONVERT(MONEY, 0),   CONVERT(MONEY, 0) ,CONVERT(MONEY, 0),CONVERT(MONEY, 0),CONVERT(MONEY, 0),CONVERT(MONEY, 0) ,CONVERT(MONEY, 0),CONVERT(MONEY, 0),CONVERT(MONEY, 0),CONVERT(MONEY, 0),CONVERT(MONEY, 0),CONVERT(MONEY, 0),CONVERT(MONEY, 0)
					, CONVERT(MONEY, 0), CONVERT(MONEY, 0), CONVERT(MONEY, 0), CONVERT(MONEY, 0), CONVERT(MONEY, 0), CONVERT(MONEY, 0), CONVERT(MONEY, 0), CONVERT(MONEY, 0), CONVERT(MONEY, 0)
	
		RETURN; 
	END

	DECLARE
		 @SbTurnover MONEY
		,@SbCustomerWl MONEY
		,@SbBetCount MONEY

		,@RbTurnover MONEY
		,@RbCustomerWl MONEY
		,@RbBetCount MONEY

		,@NgTurnover MONEY
		,@NgCustomerWl MONEY
		,@NgBetCount MONEY
		--- RNG Casino
		,@CsTurnover MONEY
		,@CsCustomerWl MONEY
		,@CsBetCount MONEY
		-- Live Casino	
		,@LCTurnover MONEY
		,@LCCustomerWl MONEY
		,@LCBetCount MONEY
		--GD
		,@GDTurnover MONEY
		,@GDCustomerWl MONEY
		,@GDBetCount MONEY
		--KN
		,@KNTurnover MONEY
		,@KNCustomerWl MONEY
		,@KNBetCount MONEY
		----VS
		,@VsTurnover MONEY
		,@VsCustomerWl MONEY
		,@VsBetCount MONEY 
		--AG
		,@AGTurnover MONEY
		,@AGCustomerWl MONEY
		,@AGBetCount MONEY
		--BT
		,@BTTurnover MONEY
		,@BTCustomerWl MONEY
		,@BTBetCount MONEY
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
		----PP
		,@PPTurnover MONEY
		,@PPCustomerWl MONEY
		,@PPBetCount MONEY
		----CC
		,@CCTurnover MONEY
		,@CCCustomerWl MONEY
		,@CCBetCount MONEY

	---
	DECLARE @tblSport AS TABLE (ProductPrefix VARCHAR (10),Sporttype INT)

	INSERT INTO @tblSport (ProductPrefix,Sporttype)
	SELECT DISTINCT ProductPrefix,s.Sporttype
	FROM bodb02.dbo.SportBettypeMatrix s WITH (NOLOCK)
		INNER JOIN bodb02.dbo.Products p WITH (NOLOCK) ON s.ProductId = p.ProductId
	WHERE p.ProductPrefix IN ( 'RB','NG','LC','VS','CS','KN','AGC','GD','MGCRNG','MGCLC','VG','VB', 'CB', 'AB', 'NG2', 'FW', 'CO', 'VS2', 'LT','PP','CC')

	INSERT INTO @tblSport(ProductPrefix,Sporttype)
	SELECT 'SB',0

	DECLARE @tblData AS TABLE (ProductPrefix VARCHAR (10), TurnOver MONEY,Winlost MONEY,BetCount INT)

	INSERT INTO @tblData (ProductPrefix , TurnOver ,Winlost ,BetCount )
	SELECT CASE WHEN b.bettype IN (901,902,903) THEN 'BT' 
				WHEN b.bettype IN (911, 912, 913) THEN 'CO' 
			ELSE s.ProductPrefix END ProductPrefix
		   ,SUM(b.TurnOver)
		   ,SUM(b.Winlost)
		   ,SUM(b.BetCount)
	FROM bodb02.dbo.sum_winloss b (NOLOCK)
		INNER JOIN @tblSport s ON b.sporttype = s.sporttype 
		LEFT JOIN bodb02.dbo.Customer c (NOLOCK) ON b.srecommend=c.custid 
	WHERE b.winlostdate=@Date
		AND b.roleid = 4
		AND b.srecommend IN (SELECT custid FROM bodb02.dbo.f_DepSuper_1('All'))
		AND c.currency NOT IN(20,27,28)
	GROUP BY CASE WHEN b.bettype IN (901,902,903) THEN 'BT' 
				WHEN b.bettype IN (911, 912, 913) THEN 'CO' 
			ELSE s.ProductPrefix END

	-- Sportbook
	SELECT @SbTurnover 	= SUM(b.Turnover)
		   ,@SbCustomerWl = SUM(b.Winlost) 
		   ,@SbBetCount = SUM(b.BetCount) 
	FROM @tblData b
	WHERE ProductPrefix ='SB'
	SELECT @SbTurnover = ISNULL (@SbTurnover, 0),
		   @SbCustomerWl = ISNULL (@SbCustomerWl, 0),
		   @SbBetCount = ISNULL (@SbBetCount, 0)
	 ---BT
	SELECT @BTTurnover 	= SUM(b.Turnover)
		   ,@BTCustomerWl = SUM(b.Winlost) 
		   ,@BTBetCount = SUM(b.BetCount) 
	FROM @tblData b
	WHERE ProductPrefix ='BT'

	SELECT @BTTurnover = ISNULL (@BTTurnover, 0),
		   @BTCustomerWl = ISNULL (@BTCustomerWl, 0),
		   @BTBetCount = ISNULL (@BTBetCount, 0)
	-- Racing
	SELECT @RbTurnover=SUM(b.Turnover)
		  ,@RbCustomerWl=SUM(b.Winlost)
		  ,@RbBetCount=SUM(b.BetCount)
	FROM @tblData b 
	WHERE ProductPrefix ='RB'

	SELECT @RbTurnover = ISNULL (@RbTurnover, 0),
		   @RbCustomerWl = ISNULL (@RbCustomerWl, 0),
		   @RbBetCount = ISNULL (@RbBetCount, 0)
	   
	-- Number Game
	SELECT @NgTurnover=SUM(b.Turnover)
		,@NgCustomerWl=SUM(b.Winlost) 
		,@NgBetCount=SUM(b.BetCount) 
	FROM @tblData b 
	WHERE ProductPrefix ='NG'

	SELECT @NgTurnover = ISNULL (@NgTurnover, 0),
		   @NgCustomerWl = ISNULL (@NgCustomerWl, 0),
		   @NgBetCount = ISNULL (@NgBetCount, 0)

	-- Live Casino
	SELECT @LCTurnover=SUM(b.Turnover)
		,@LCCustomerWl=SUM(b.Winlost) 
		,@LCBetCount=SUM(b.BetCount) 
	FROM @tblData b 
	WHERE ProductPrefix ='LC'
    
	SELECT @LCTurnover = ISNULL (@LCTurnover, 0),
		   @LCCustomerWl = ISNULL (@LCCustomerWl, 0),
		   @LCBetCount = ISNULL (@LCBetCount, 0)

	--- RNG Casino
	SELECT @CsTurnover=SUM(b.Turnover)
		,@CsCustomerWl=SUM(b.Winlost) 
		,@CsBetCount=SUM(b.BetCount) 
	FROM @tblData b 
	WHERE ProductPrefix ='CS'
    
	SELECT @CsTurnover = ISNULL (@CsTurnover, 0),
		   @CsCustomerWl = ISNULL (@CsCustomerWl, 0),
		   @CsBetCount = ISNULL (@CsBetCount, 0)
 
	-- GD
	SELECT @GDTurnover=SUM(b.Turnover)
		  ,@GDCustomerWl=SUM(b.Winlost) 
		  ,@GDBetCount=SUM(b.BetCount) 
	FROM @tblData b 
	WHERE ProductPrefix ='GD'

	SELECT  @GDTurnover =ISNULL (@GDTurnover, 0)
		   ,@GDCustomerWl = ISNULL (@GDCustomerWl, 0)
		   ,@GDBetCount = ISNULL (@GDBetCount, 0)

	--- Keno
	SELECT @KNTurnover=SUM(b.Turnover)
		  ,@KNCustomerWl=SUM(b.Winlost) 
		  ,@KNBetCount=SUM(b.BetCount) 
	FROM @tblData b 
	WHERE ProductPrefix ='KN'

	SELECT @KNTurnover =ISNULL (@KNTurnover, 0)
		   ,@KNCustomerWl = ISNULL (@KNCustomerWl, 0)
		   ,@KNBetCount  = ISNULL (@KNBetCount, 0)
	----VS
	SELECT @VSTurnover=SUM(b.Turnover)
		  ,@VSCustomerWl=SUM(b.Winlost) 
		  ,@VSBetCount=SUM(b.BetCount) 
	FROM @tblData b 
	WHERE ProductPrefix ='VS'

	SELECT  @VsTurnover =ISNULL (@VsTurnover, 0)
		   ,@VsCustomerWl = ISNULL (@VsCustomerWl, 0)
		   ,@VsBetCount  = ISNULL (@VsBetCount, 0)
	-- AG
	SELECT @AGTurnover=SUM( b.Turnover)
		,@AGCustomerWl=SUM(b.Winlost)
		,@AGBetCount=SUM(b.BetCount) 
	FROM @tblData b
	WHERE ProductPrefix = 'AGC'

	SELECT @AGTurnover    = ISNULL(@AGTurnover,0)
		   ,@AGCustomerWl = ISNULL(@AGCustomerWl,0)
		   ,@AGBetCount   = ISNULL(@AGBetCount,0)
		   	  
	--VG: Macau
	 SELECT  @VGTurnover=SUM(b.Turnover )
			,@VGCustomerWl=SUM(b.Winlost)
			,@VGBetCount=SUM( b.BetCount) 
	FROM @tblData b
	WHERE ProductPrefix = 'VG'
	SELECT  @VGTurnover  	= ISNULL(@VGTurnover,0)	
		   ,@VGCustomerWl   = ISNULL(@VGCustomerWl,0)
		   ,@VGBetCount     = ISNULL(@VGBetCount,0)

	 --VB: Macau Games
	SELECT  @VBTurnover=SUM( b.Turnover)
			,@VBCustomerWl=SUM(b.Winlost)
			,@VBBetCount=SUM(b.BetCount) 
	FROM @tblData b
	WHERE ProductPrefix = 'VB'
	SELECT @VBTurnover 	= ISNULL(@VBTurnover,0)	
		,@VBCustomerWl 	= ISNULL(@VBCustomerWl,0)
		,@VBBetCount 	= ISNULL(@VBBetCount,0)

	--MGCLC:Microgaming - Live Casino
	SELECT  @MGCLCTurnover=SUM( b.Turnover)
			,@MGCLCCustomerWl=SUM(b.Winlost)
			,@MGCLCBetCount=SUM( b.BetCount ) 
	FROM @tblData b
	WHERE ProductPrefix = 'MGCLC'

	 SELECT  @MGCLCTurnover     = ISNULL(@MGCLCTurnover,0)	
			 ,@MGCLCCustomerWl  = ISNULL(@MGCLCCustomerWl,0)
			 ,@MGCLCBetCount    = ISNULL(@MGCLCBetCount,0)
	   
	  --MGCRNG:Microgaming - RNG Casino
	 SELECT  @MGCRNGTurnover=SUM( b.Turnover)
			,@MGCRNGCustomerWl=SUM(b.Winlost)
			,@MGCRNGBetCount=SUM( b.BetCount ) 
	FROM @tblData b
	WHERE ProductPrefix = 'MGCRNG'
 
	SELECT  @MGCRNGTurnover 	= ISNULL(@MGCRNGTurnover,0)
			,@MGCRNGCustomerWl  = ISNULL(@MGCRNGCustomerWl,0)
			,@MGCRNGBetCount    = ISNULL(@MGCRNGBetCount,0)		   
	
	----CB
	 SELECT  @CBTurnover = SUM( b.Turnover)
			,@CBCustomerWl = SUM(b.winlost)
			,@CBBetCount = SUM( b.BetCount)
	FROM @tblData b
	WHERE ProductPrefix = 'CB'

	SELECT @CBTurnover 		= ISNULL(@CBTurnover,0)
		   ,@CBCustomerWl	= ISNULL(@CBCustomerWl,0)
		   ,@CBBetCount 	= ISNULL(@CBBetCount,0)
	
	----AB
	 SELECT  @ABTurnover = SUM( b.Turnover)
			,@ABCustomerWl = SUM(b.winlost)
			,@ABBetCount = SUM( b.BetCount)
	FROM @tblData b
	WHERE ProductPrefix = 'AB'

	SELECT @ABTurnover 		= ISNULL(@ABTurnover,0)
		   ,@ABCustomerWl	= ISNULL(@ABCustomerWl,0)
		   ,@ABBetCount 	= ISNULL(@ABBetCount,0)

	----NG2
	 SELECT  @NG2Turnover = SUM( b.Turnover)
			,@NG2CustomerWl = SUM(b.winlost)
			,@NG2BetCount = SUM( b.BetCount) 
	FROM @tblData b
	WHERE ProductPrefix = 'NG2'

	SELECT @NG2Turnover 	= ISNULL(@NG2Turnover,0)
		   ,@NG2CustomerWl	= ISNULL(@NG2CustomerWl,0)
		   ,@NG2BetCount 	= ISNULL(@NG2BetCount,0)

	----FW
	 SELECT  @FWTurnover = SUM( b.Turnover)
			,@FWCustomerWl = SUM(b.winlost)
			,@FWBetCount = SUM( b.BetCount) 
	FROM @tblData b
	WHERE ProductPrefix = 'FW'

	SELECT @FWTurnover 		= ISNULL(@FWTurnover,0)
		   ,@FWCustomerWl	= ISNULL(@FWCustomerWl,0)
		   ,@FWBetCount 	= ISNULL(@FWBetCount,0)
	
	-- CO
	SELECT  @COTurnover = SUM( b.Turnover)
			,@COCustomerWl = SUM(b.winlost)
			,@COBetCount = SUM( b.BetCount) 
	FROM @tblData b
	WHERE ProductPrefix = 'CO'
	
	SELECT @COTurnover 	 = ISNULL (@COTurnover, 0),
		   @COCustomerWl = ISNULL (@COCustomerWl, 0),
		   @COBetCount   = ISNULL (@COBetCount, 0)
	
	----VS2
	SELECT  @VS2Turnover = SUM( b.Turnover)
			,@VS2CustomerWl = SUM(b.winlost)
			,@VS2BetCount = SUM( b.BetCount)  
	FROM @tblData b
	WHERE ProductPrefix = 'VS2'

	SELECT @VS2Turnover 	= ISNULL(@VS2Turnover,0)
		   ,@VS2CustomerWl	= ISNULL(@VS2CustomerWl,0)
		   ,@VS2BetCount 	= ISNULL(@VS2BetCount,0)

	----LT
	 SELECT  @LTTurnover = SUM( b.Turnover)
			,@LTCustomerWl = SUM(b.winlost)
			,@LTBetCount = SUM( b.BetCount)  
	FROM @tblData b
	WHERE ProductPrefix = 'LT'

	SELECT @LTTurnover 		= ISNULL(@LTTurnover,0)
		   ,@LTCustomerWl	= ISNULL(@LTCustomerWl,0)
		   ,@LTBetCount 	= ISNULL(@LTBetCount,0)

	----PP
	 SELECT  @PPTurnover = SUM( b.Turnover)
			,@PPCustomerWl = SUM(b.winlost)
			,@PPBetCount = SUM( b.BetCount)  
	FROM @tblData b
	WHERE ProductPrefix = 'PP'

	SELECT @PPTurnover 		= ISNULL(@PPTurnover,0)
		   ,@PPCustomerWl	= ISNULL(@PPCustomerWl,0)
		   ,@PPBetCount 	= ISNULL(@PPBetCount,0)

	----CC
	 SELECT  @CCTurnover = SUM( b.Turnover)
			,@CCCustomerWl = SUM(b.winlost)
			,@CCBetCount = SUM( b.BetCount)  
	FROM @tblData b
	WHERE ProductPrefix = 'CC'

	SELECT @CCTurnover 		= ISNULL(@CCTurnover,0)
		   ,@CCCustomerWl	= ISNULL(@CCCustomerWl,0)
		   ,@CCBetCount 	= ISNULL(@CCBetCount,0)

	-- Result

	SELECT 1 AS Id, @SbTurnover AS Sb
				  , @RbTurnover AS Rb
				  , @NgTurnover AS Ng
				  , CONVERT(MONEY, 0)  AS Ba
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
				  , @VsTurnover  AS VS
				  , @CBTurnover  AS CB
				  , @ABTurnover  AS AB
				  , @NG2Turnover AS NG2
				  , @FWTurnover  AS FW
				  , @COTurnover  AS CO
				  , @VS2Turnover AS VS2
				  , @LTTurnover  AS LT
				  , @PPTurnover  AS PP
				  , @CCTurnover  AS CC
			  
	UNION
	SELECT 2, @SbCustomerWl
			, @RbCustomerWl
			, @NgCustomerWl
			, CONVERT(MONEY, 0)
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
			, @CBCustomerWl
			, @ABCustomerWl
			, @NG2CustomerWl
			, @FWCustomerWl
			, @COCustomerWl
			, @VS2CustomerWl
			, @LTCustomerWl
			, @PPCustomerWl
			, @CCCustomerWl
	UNION
	SELECT 3, @SbBetCount
			, @RbBetCount
			, @NgBetCount
			, CONVERT(MONEY, 0)
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
			, @CBBetCount
			, @ABBetCount
			, @NG2BetCount
			, @FWBetCount
			, @COBetCount
			, @VS2BetCount
			, @LTBetCount
			, @PPBetCount
			, @CCBetCount
END
GO