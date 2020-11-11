/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="bodbLicenseeNet" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[GET_DepositDataToValidate_LicenseeWL]
	@Date		SMALLDATETIME,
	@DrawFilter	TINYINT			= 1
AS

/*
	Created: 20111209@Don
	Task: Get deposit data from table db052.bodb_Licensee.dbo.rptLicWinloss2
	DB: DBLIC.bodb_LicenseeReport

	Revisions:
		- 20140310@daniel: exclude currency C & H
		- 20160726@Francis: Move SP to bodb_LicenseeReport [Redmine: #60449]
		- 20160608@Jim: Separate Bettrade (#57353)
		- 20160616@Jim: Changes to data integrity automail (#59249)
		- 20160906@Jim: Correct value of SB & BA [Redmine #63571]
		- 20170822@Harper: Add missing products CB, AB, NG2, FW, CO, VS2, LT, LK3 into data validation email [RedmineID: #81708]
		- 20180418@Joseph: Integrate new product PP [Redmine: #92318]
		- 20190710@Amanda: Integrate Card Club [RedmineID: #115449]
		- 20191106@Amanda: Integrate NPHP [RedmineID: #120333]
		- 20191204@Amanda: Change name of NPH Promotion to Saba Promotion [Redmine: #124612]
		- 20191212@Vickie: Integrate SpadeGaming [RedmineID: #124103]
		- 20200108@Vickie: Integrate Virtual Games [RedmineID: #124911]
		- 20200407@Vickie: Integrate Table Games [RedmineID: #131447]
		- 20200416@Vickie: Add new product Indo 4D [RedmineID: #130859]
		- 20200423@Hogan: Add new product Sexy Gaming [RedmineID: #132829]
		- 20200423@Vickie: Integrate Saba Club [RedmineID: #132702]
		- 20200918@Hogan: Integrate Joker [RedmineID: #141408]
		- 20201013@Hogan: Integrate SA Gaming [RedmineID: #128493]
		- 20201021@Louis: Integrate PG Soft [RedmineID: #139182]

	Param's Explanation:
		@DrawFilter
			- 1: Normal
			- 2: No Draws
			- 3: No Draws For Turnover Only

	Examples:
		DECLARE @DateChecking SMALLDATETIME
		SELECT @DateChecking =DATEADD(day, -10, GETDATE())
		exec [GET_DepositDataToValidate_LicenseeWL] @Date=@DateChecking,@DrawFilter=1
*/

BEGIN
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
		----SPR
		,@SPRTurnover MONEY
		,@SPRCustomerWl MONEY
		,@SPRBetCount MONEY
		----SG
		,@SGTurnover MONEY
		,@SGCustomerWl MONEY
		,@SGBetCount MONEY
		----VRG
		,@VRGTurnover MONEY
		,@VRGCustomerWl MONEY
		,@VRGBetCount MONEY
		----TG
		,@TGTurnover MONEY
		,@TGCustomerWl MONEY
		,@TGBetCount MONEY
		----I4D
		,@I4DTurnover MONEY
		,@I4DCustomerWl MONEY
		,@I4DBetCount MONEY
		----SXG
		,@SXGTurnover MONEY
		,@SXGCustomerWl MONEY
		,@SXGBetCount MONEY
		----SBC
		,@SBCTurnover MONEY
		,@SBCCustomerWl MONEY
		,@SBCBetCount MONEY
		----JK
		,@JKTurnover MONEY
		,@JKCustomerWl MONEY
		,@JKBetCount MONEY
		---SAG
		,@SAGTurnover MONEY
		,@SAGCustomerWl MONEY
		,@SAGBetCount MONEY
		----PGS
		,@PGSTurnover MONEY
		,@PGSCustomerWl MONEY
		,@PGSBetCount MONEY

	DECLARE @tblSporttype AS TABLE (ProductPrefix VARCHAR(10), Sporttype SMALLINT)

	INSERT INTO @tblSporttype (
		ProductPrefix,
		Sporttype)
	SELECT DISTINCT
		p.ProductPrefix,
		s.SportType
	FROM bodb02.dbo.SportBettypeMatrix s WITH (NOLOCK)
		INNER JOIN bodb02.dbo.Products p WITH (NOLOCK) ON s.ProductId = p.ProductId
	WHERE p.ProductPrefix IN ( 'RB','NG','LC','VS','CS','KN','AGC','GD','MGCRNG','MGCLC','VG','VB', 'CB', 
		'AB', 'NG2', 'FW', 'CO', 'VS2', 'LT', 'PP', 'CC', 'SPR', 'SG', 'VRG', 'TG', 'I4D', 'SXG', 'SBC', 'JK', 'SAG', 'PGS')

	INSERT INTO @tblSporttype
	SELECT 'SB', 0

	-- Data Source 
	DECLARE @tblData AS TABLE (
		ProductPrefix	VARCHAR (10),
		StatusId		INT,
		Turnover		MONEY,
		WinLost			MONEY,
		BetCount		INT)

	INSERT INTO @tblData (
		ProductPrefix,
		StatusId,
		Turnover,
		WinLost,
		BetCount)
	SELECT
		t.ProductPrefix,
		b.statusID,
		SUM(b.turnover) Turnover,
		SUM(b.winlost) WinLoss,
		SUM(b.BetCount) Betcount
	FROM dbo.rptLicWinloss2 b WITH (NOLOCK)
		INNER JOIN @tblSporttype t ON b.sporttype = t.sporttype
	WHERE b.winlostdate = @Date
		 AND b.statusID IN (111, 112, 113, 114, 115)
		 AND b.currency NOT IN (20, 27, 28)
		 AND b.roleid = 4
		 AND b.srecommend IN (SELECT custid FROM bodb02.dbo.f_Depsuper_1('All'))
		 AND b.isBA = CONVERT(BIT, 0)
		-- AND b.bettype NOT IN (901,902,903)
	GROUP BY
		t.ProductPrefix,
		b.statusID 

	-- Sportbook
	SELECT @SbTurnover = SUM(CASE 
						WHEN @DrawFilter IN (2, 3) THEN 
							CASE WHEN b.statusID = 111 THEN 0 WHEN b.statusID IN (114, 115) THEN 0.5 ELSE 1 END
						ELSE 1
					END * b.Turnover)
		,@SbCustomerWl = SUM(b.winlost) 
		,@SbBetCount = SUM(CASE WHEN @DrawFilter = 2 AND b.statusID = 111 THEN 0 ELSE b.BetCount END)
	FROM @tblData b
	WHERE ProductPrefix = 'SB'
	
	SELECT @SbTurnover = ISNULL (@SbTurnover, 0),
		@SbCustomerWl = ISNULL (@SbCustomerWl, 0),
		@SbBetCount = ISNULL (@SbBetCount, 0)

	-- Bettrade
	SELECT @BTTurnover = SUM(CASE 
						WHEN @DrawFilter IN (2, 3) THEN 
							CASE WHEN b.statusID = 111 THEN 0 WHEN b.statusID IN (114, 115) THEN 0.5 ELSE 1 END
						ELSE 1
					END * b.Turnover)
		,@BTCustomerWl = SUM(b.winlost) 
		,@BTBetCount = SUM(CASE WHEN @DrawFilter = 2 AND b.statusID = 111 THEN 0 ELSE b.BetCount END)
	FROM dbo.rptLicWinloss2 b (NOLOCK)
	WHERE b.winlostdate = @Date
		AND b.sporttype = 0
		AND b.statusID IN (111, 112, 113, 114, 115)
		AND b.currency NOT IN (20, 27, 28)
		AND b.roleid = 4
		AND b.srecommend IN (SELECT custid FROM bodb02.dbo.f_Depsuper_1('All'))
		AND b.isBA = CONVERT(BIT,0)
		AND b.bettype IN (901, 902, 903, 904)
	
	SELECT @BTTurnover = ISNULL (@BTTurnover, 0),
		@BTCustomerWl = ISNULL (@BTCustomerWl, 0),
		@BTBetCount = ISNULL (@BTBetCount, 0)

	-- Racing
	SELECT @RbTurnover = SUM(b.turnover)
		,@RbCustomerWl = SUM(b.winlost)
		,@RbBetCount = SUM(b.BetCount)
	FROM @tblData b
	WHERE ProductPrefix = 'RB'

	SELECT @RbTurnover = ISNULL (@RbTurnover, 0),
		@RbCustomerWl = ISNULL (@RbCustomerWl, 0),
		@RbBetCount = ISNULL (@RbBetCount, 0)

	-- Number Game
	SELECT @NgTurnover = SUM(CASE WHEN @DrawFilter IN (2, 3) AND b.statusID = 111 THEN 0 ELSE b.turnover END)
		,@NgCustomerWl = SUM(b.winlost) 
		,@NgBetCount = SUM(CASE WHEN @DrawFilter = 2 AND b.statusID = 111 THEN 0 ELSE b.BetCount END) 
	FROM @tblData b
	WHERE ProductPrefix = 'NG'
 
	SELECT @NgTurnover = ISNULL (@NgTurnover, 0),
		@NgCustomerWl = ISNULL (@NgCustomerWl, 0),
		@NgBetCount = ISNULL (@NgBetCount, 0)

	-- Section: BA
	SELECT @BaTurnover = SUM(CASE 
						WHEN @DrawFilter IN (2, 3) THEN 
							CASE WHEN b.statusID = 111 THEN 0 WHEN b.statusID IN (114, 115) THEN 0.5 ELSE 1 END
						ELSE 1
					END * b.Turnover)
		,@BaCustomerWl = SUM(b.winlost)
		,@BaBetCount = SUM(CASE WHEN @DrawFilter = 2 AND b.statusID = 111 THEN 0 ELSE b.BetCount END) 
	FROM dbo.rptLicWinloss2 b (NOLOCK)
	WHERE b.winlostdate = @Date
		AND b.statusID IN (111, 112, 113, 114, 115)
		AND b.currency NOT IN (20, 27, 28)
		AND b.roleid = 4
		AND b.isBA = CONVERT(BIT,1)

	SELECT @BaTurnover = ISNULL (@BaTurnover, 0),
		@BaCustomerWl = ISNULL (@BaCustomerWl, 0),
		@BaBetCount = ISNULL (@BaBetCount, 0)

	-- Live Casino
	 SELECT @LCTurnover = SUM(CASE WHEN @DrawFilter IN (2, 3) AND b.statusID = 111 THEN 0 ELSE b.turnover END)
		,@LCCustomerWl = SUM(b.winlost) 
		,@LCBetCount = SUM(CASE WHEN @DrawFilter = 2 AND b.statusID = 111 THEN 0 ELSE b.BetCount END) 
	FROM @tblData b
	WHERE ProductPrefix = 'LC'

	SELECT @LCTurnover = ISNULL (@LCTurnover, 0),
		@LCCustomerWl = ISNULL (@LCCustomerWl, 0),
		@LCBetCount = ISNULL (@LCBetCount, 0)

	-- AG
	SELECT @AGTurnover = SUM(CASE WHEN @DrawFilter IN (2, 3) THEN 
							CASE WHEN b.StatusID = 111 THEN 0 WHEN b.StatusID IN (114, 115) THEN 0.5 ELSE 1 END
								ELSE 1
								END * b.Turnover)
		,@AGCustomerWl = SUM(b.winlost)
		,@AGBetCount = SUM(CASE WHEN @DrawFilter = 2 AND b.statusID = 111 THEN 0 ELSE b.BetCount END) 
	FROM @tblData b
	WHERE ProductPrefix = 'AGC'

	SELECT @AGTurnover = ISNULL(@AGTurnover,0)
		,@AGCustomerWl = ISNULL(@AGCustomerWl,0)
		,@AGBetCount = ISNULL(@AGBetCount,0)

	-- Gold Deluxe
	SELECT @GDTurnover=SUM(CASE WHEN @DrawFilter IN (2, 3) AND b.StatusID = 111 THEN 0 ELSE b.Turnover END)
			,@GDCustomerWl=SUM(b.winlost)
			,@GDBetCount=SUM(CASE WHEN @DrawFilter = 2 AND b.StatusID = 111 THEN 0 ELSE b.BetCount END) 
	FROM @tblData b
	WHERE ProductPrefix = 'GD'

	SELECT @GDTurnover = ISNULL(@GDTurnover,0)
		,@GDCustomerWl = ISNULL(@GDCustomerWl,0)
		,@GDBetCount = ISNULL(@GDBetCount,0)

	---KN
	SELECT @KNTurnover=SUM(CASE
						WHEN @DrawFilter IN (2, 3) THEN 
							CASE WHEN b.StatusID = 111 THEN 0 WHEN b.StatusID IN (114, 115) THEN 0.5 ELSE 1 END
						ELSE 1
					END * b.Turnover)
		,@KNCustomerWl=SUM(b.winlost)
		,@KNBetCount=SUM(CASE WHEN @DrawFilter = 2 AND b.StatusID = 111 THEN 0 ELSE b.BetCount END)
	FROM @tblData b
	WHERE ProductPrefix = 'KN'

	SELECT @KNTurnover = ISNULL(@KNTurnover,0)
		,@KNCustomerWl = ISNULL(@KNCustomerWl,0)
		,@KNBetCount = ISNULL(@KNBetCount,0)

	--VG: Macau
	 SELECT @VGTurnover = SUM(CASE WHEN @DrawFilter IN (2, 3) AND b.StatusID = 111 THEN 0 ELSE b.Turnover END)
		,@VGCustomerWl = SUM(b.winlost)
		,@VGBetCount = SUM(CASE WHEN @DrawFilter = 2 AND b.StatusID = 111 THEN 0 ELSE b.BetCount END)
	FROM @tblData b
	WHERE ProductPrefix = 'VG'

	SELECT @VGTurnover = ISNULL(@VGTurnover,0)
		,@VGCustomerWl = ISNULL(@VGCustomerWl,0)
		,@VGBetCount = ISNULL(@VGBetCount,0)

	--VB: Macau Games
	SELECT @VBTurnover=SUM(CASE 
						WHEN @DrawFilter IN (2, 3) THEN 
							CASE WHEN b.StatusID = 111 THEN 0 WHEN b.StatusID IN (114, 115) THEN 0.5 ELSE 1 END
						ELSE 1
					END * b.Turnover)
		,@VBCustomerWl=SUM(b.winlost)
		,@VBBetCount=SUM(CASE WHEN @DrawFilter = 2 AND b.StatusID = 111 THEN 0 ELSE b.BetCount END)
	FROM @tblData b
	WHERE ProductPrefix = 'VB'

	SELECT @VBTurnover 	= ISNULL(@VBTurnover,0)
		,@VBCustomerWl 	= ISNULL(@VBCustomerWl,0)
		,@VBBetCount 	= ISNULL(@VBBetCount,0)

	 --MGCLC: Microgaming - Live Casino
	SELECT @MGCLCTurnover=SUM(CASE 
						WHEN @DrawFilter IN (2, 3) THEN 
							CASE WHEN b.StatusID = 111 THEN 0 WHEN b.StatusID IN (114, 115) THEN 0.5 ELSE 1 END
						ELSE 1
					END * b.Turnover)
			,@MGCLCCustomerWl=SUM(b.winlost)
			,@MGCLCBetCount=SUM(CASE WHEN @DrawFilter = 2 AND b.StatusID = 111 THEN 0 ELSE b.BetCount END) 
	FROM @tblData b
	WHERE ProductPrefix = 'MGCLC'

	SELECT @MGCLCTurnover = ISNULL(@MGCLCTurnover,0)	
		,@MGCLCCustomerWl = ISNULL(@MGCLCCustomerWl,0)
		,@MGCLCBetCount = ISNULL(@MGCLCBetCount,0)

	--MGCRNG: Microgaming - RNG Casino
	 SELECT @MGCRNGTurnover=SUM(CASE 
						WHEN @DrawFilter IN (2, 3) THEN 
							CASE WHEN b.StatusID = 111 THEN 0 WHEN b.StatusID IN (114, 115) THEN 0.5 ELSE 1 END
						ELSE 1
					END * b.Turnover)
			,@MGCRNGCustomerWl=SUM(b.winlost)
			,@MGCRNGBetCount=SUM(CASE WHEN @DrawFilter = 2 AND b.StatusID = 111 THEN 0 ELSE b.BetCount END)
	FROM @tblData b
	WHERE ProductPrefix = 'MGCRNG'
 
	SELECT @MGCRNGTurnover = ISNULL(@MGCRNGTurnover,0)
		,@MGCRNGCustomerWl = ISNULL(@MGCRNGCustomerWl,0)
		,@MGCRNGBetCount = ISNULL(@MGCRNGBetCount,0)

	 ----CS
	 SELECT @CsTurnover=SUM(CASE 
						WHEN @DrawFilter IN (2, 3) THEN 
							CASE WHEN b.StatusID = 111 THEN 0 WHEN b.StatusID IN (114, 115) THEN 0.5 ELSE 1 END
						ELSE 1
					END * b.Turnover)
		,@CsCustomerWl=SUM(b.winlost)
		,@CsBetCount=SUM(CASE WHEN @DrawFilter = 2 AND b.StatusID = 111 THEN 0 ELSE b.BetCount END)
	FROM @tblData b
	WHERE ProductPrefix = 'CS'

	SELECT @CsTurnover = ISNULL(@CsTurnover,0)
		,@CsCustomerWl = ISNULL(@CsCustomerWl,0)
		,@CsBetCount = ISNULL(@CsBetCount,0)	

	----VS
	 SELECT @VsTurnover = SUM(CASE 
					WHEN @DrawFilter IN (2, 3) THEN 
						CASE WHEN b.StatusID = 111 THEN 0 WHEN b.StatusID IN (114, 115) THEN 0.5 ELSE 1 END
					ELSE 1
				END * b.Turnover)
		,@VsCustomerWl = SUM(b.winlost)
		,@VsBetCount = SUM(CASE WHEN @DrawFilter = 2 AND b.StatusID = 111 THEN 0 ELSE b.BetCount END)
	FROM @tblData b
	WHERE ProductPrefix = 'VS'

	SELECT @VsTurnover = ISNULL(@VsTurnover,0)
		,@VsCustomerWl = ISNULL(@VsCustomerWl,0)
		,@VsBetCount = ISNULL(@VsBetCount,0)

	----CB
	 SELECT @CBTurnover = SUM(CASE 
								WHEN @DrawFilter IN (2, 3) THEN 
								CASE WHEN b.StatusID = 111 THEN 0 WHEN b.StatusID IN (114, 115) THEN 0.5 ELSE 1 END
							ELSE 1
							END * b.Turnover)
		,@CBCustomerWl = SUM(b.winlost)
		,@CBBetCount = SUM(CASE WHEN @DrawFilter = 2 AND b.StatusID = 111 THEN 0 ELSE b.BetCount END)
	FROM @tblData b
	WHERE ProductPrefix = 'CB'

	SELECT @CBTurnover = ISNULL(@CBTurnover,0)
		,@CBCustomerWl = ISNULL(@CBCustomerWl,0)
		,@CBBetCount = ISNULL(@CBBetCount,0)
	
	----AB
	 SELECT @ABTurnover = SUM(CASE 
								WHEN @DrawFilter IN (2, 3) THEN 
								CASE WHEN b.StatusID = 111 THEN 0 WHEN b.StatusID IN (114, 115) THEN 0.5 ELSE 1 END
							ELSE 1
							END * b.Turnover)
		,@ABCustomerWl = SUM(b.winlost)
		,@ABBetCount = SUM(CASE WHEN @DrawFilter = 2 AND b.StatusID = 111 THEN 0 ELSE b.BetCount END)
	FROM @tblData b
	WHERE ProductPrefix = 'AB'

	SELECT @ABTurnover = ISNULL(@ABTurnover,0)
		,@ABCustomerWl = ISNULL(@ABCustomerWl,0)
		,@ABBetCount = ISNULL(@ABBetCount,0)

	----NG2
	 SELECT @NG2Turnover = SUM(CASE 
									WHEN @DrawFilter IN (2, 3) THEN 
									CASE WHEN b.StatusID = 111 THEN 0 WHEN b.StatusID IN (114, 115) THEN 0.5 ELSE 1 END
								ELSE 1
								END * b.Turnover)
		,@NG2CustomerWl = SUM(b.winlost)
		,@NG2BetCount = SUM(CASE WHEN @DrawFilter = 2 AND b.StatusID = 111 THEN 0 ELSE b.BetCount END)
	FROM @tblData b
	WHERE ProductPrefix = 'NG2'

	SELECT @NG2Turnover 	= ISNULL(@NG2Turnover,0)
		,@NG2CustomerWl	= ISNULL(@NG2CustomerWl,0)
		,@NG2BetCount 	= ISNULL(@NG2BetCount,0)

	----FW
	 SELECT @FWTurnover = SUM(CASE 
									WHEN @DrawFilter IN (2, 3) THEN 
									CASE WHEN b.StatusID = 111 THEN 0 WHEN b.StatusID IN (114, 115) THEN 0.5 ELSE 1 END
								ELSE 1
								END * b.Turnover)
		,@FWCustomerWl = SUM(b.winlost)
		,@FWBetCount = SUM(CASE WHEN @DrawFilter = 2 AND b.StatusID = 111 THEN 0 ELSE b.BetCount END) 
	FROM @tblData b
	WHERE ProductPrefix = 'FW'

	SELECT @FWTurnover = ISNULL(@FWTurnover,0)
		,@FWCustomerWl = ISNULL(@FWCustomerWl,0)
		,@FWBetCount = ISNULL(@FWBetCount,0)
	
	-- CO
	SELECT @COTurnover = SUM(CASE 
								WHEN @DrawFilter IN (2, 3) THEN 
									CASE WHEN b.statusID = 111 THEN 0 WHEN b.statusID IN (114, 115) THEN 0.5 ELSE 1 END
								ELSE 1
							END * b.Turnover)
		,@COCustomerWl = SUM(b.winlost) 
		,@COBetCount = SUM(CASE WHEN @DrawFilter = 2 AND b.statusID = 111 THEN 0 ELSE b.BetCount END)
	FROM dbo.rptLicWinloss2 b (NOLOCK)
	WHERE b.winlostdate = @Date
		AND b.sporttype = 0
		AND b.statusID IN (111, 112, 113, 114, 115)
		AND b.currency NOT IN (20, 27, 28)
		AND b.roleid = 4
		AND b.srecommend IN (SELECT custid FROM bodb02.dbo.f_Depsuper_1('All'))
		AND b.isBA = CONVERT(BIT,0)
		AND b.bettype IN (911, 912, 913, 914)
	
	SELECT @COTurnover = ISNULL (@COTurnover, 0),
		@COCustomerWl = ISNULL (@COCustomerWl, 0),
		@COBetCount = ISNULL (@COBetCount, 0)
	
	----VS2
	 SELECT @VS2Turnover=SUM(CASE 
						WHEN @DrawFilter IN (2, 3) THEN 
							CASE WHEN b.StatusID = 111 THEN 0 WHEN b.StatusID IN (114, 115) THEN 0.5 ELSE 1 END
						ELSE 1
					END * b.Turnover)
		,@VS2CustomerWl=SUM(b.winlost)
		,@VS2BetCount=SUM(CASE WHEN @DrawFilter = 2 AND b.StatusID = 111 THEN 0 ELSE b.BetCount END) 
	FROM @tblData b
	WHERE ProductPrefix = 'VS2'

	SELECT @VS2Turnover 	= ISNULL(@VS2Turnover,0)
		,@VS2CustomerWl	= ISNULL(@VS2CustomerWl,0)
		,@VS2BetCount 	= ISNULL(@VS2BetCount,0)

	----LT
	 SELECT @LTTurnover=SUM(CASE 
						WHEN @DrawFilter IN (2, 3) THEN 
							CASE WHEN b.StatusID = 111 THEN 0 WHEN b.StatusID IN (114, 115) THEN 0.5 ELSE 1 END
						ELSE 1
					END * b.Turnover)
		,@LTCustomerWl=SUM(b.winlost)
		,@LTBetCount=SUM(CASE WHEN @DrawFilter = 2 AND b.StatusID = 111 THEN 0 ELSE b.BetCount END) 
	FROM @tblData b
	WHERE ProductPrefix = 'LT'

	SELECT @LTTurnover = ISNULL(@LTTurnover,0)
		,@LTCustomerWl = ISNULL(@LTCustomerWl,0)
		,@LTBetCount = ISNULL(@LTBetCount,0)

	 ----PP
	SELECT @PPTurnover = SUM(CASE 
						WHEN @DrawFilter IN (2, 3) THEN 
							CASE WHEN b.StatusID = 111 THEN 0 WHEN b.StatusID IN (114, 115) THEN 0.5 ELSE 1 END
						ELSE 1
					END * b.Turnover)
		,@PPCustomerWl = SUM(b.winlost)
		,@PPBetCount = SUM(CASE WHEN @DrawFilter = 2 AND b.StatusID = 111 THEN 0 ELSE b.BetCount END) 
	FROM @tblData b
	WHERE ProductPrefix = 'PP'

	SELECT @PPTurnover = ISNULL(@PPTurnover,0)
		,@PPCustomerWl = ISNULL(@PPCustomerWl,0)
		,@PPBetCount = ISNULL(@PPBetCount,0)

	----CC
	SELECT @CCTurnover=SUM(CASE 
						WHEN @DrawFilter IN (2, 3) THEN 
							CASE WHEN b.StatusID = 111 THEN 0 WHEN b.StatusID IN (114, 115) THEN 0.5 ELSE 1 END
						ELSE 1
					END * b.Turnover)
			,@CCCustomerWl=SUM(b.winlost)
			,@CCBetCount=SUM(CASE WHEN @DrawFilter = 2 AND b.StatusID = 111 THEN 0 ELSE b.BetCount END) 
	FROM @tblData b
	WHERE ProductPrefix = 'CC'

	SELECT @CCTurnover = ISNULL(@CCTurnover,0)
		,@CCCustomerWl = ISNULL(@CCCustomerWl,0)
		,@CCBetCount = ISNULL(@CCBetCount,0)

	----SPR
	SELECT @SPRTurnover = SUM(CASE 
						WHEN @DrawFilter IN (2, 3) THEN 
							CASE WHEN b.StatusID = 111 THEN 0 WHEN b.StatusID IN (114, 115) THEN 0.5 ELSE 1 END
						ELSE 1
					END * b.Turnover)
		,@SPRCustomerWl = SUM(b.winlost)
		,@SPRBetCount = SUM(CASE WHEN @DrawFilter = 2 AND b.StatusID = 111 THEN 0 ELSE b.BetCount END) 
	FROM @tblData b
	WHERE ProductPrefix = 'SPR'

	SELECT @SPRTurnover = ISNULL(@SPRTurnover,0)
		,@SPRCustomerWl = ISNULL(@SPRCustomerWl,0)
		,@SPRBetCount = ISNULL(@SPRBetCount,0)

	----SG
	SELECT @SGTurnover = SUM(CASE 
						WHEN @DrawFilter IN (2, 3) THEN 
							CASE WHEN b.StatusID = 111 THEN 0 WHEN b.StatusID IN (114, 115) THEN 0.5 ELSE 1 END
						ELSE 1
					END * b.Turnover)
		,@SGCustomerWl = SUM(b.winlost)
		,@SGBetCount = SUM(CASE WHEN @DrawFilter = 2 AND b.StatusID = 111 THEN 0 ELSE b.BetCount END)
	FROM @tblData b
	WHERE ProductPrefix = 'SG'

	SELECT @SGTurnover = ISNULL(@SGTurnover,0)
		,@SGCustomerWl = ISNULL(@SGCustomerWl,0)
		,@SGBetCount = ISNULL(@SGBetCount,0)
	
	----VRG
	SELECT @VRGTurnover = SUM(CASE 
						WHEN @DrawFilter IN (2, 3) THEN 
							CASE WHEN b.StatusID = 111 THEN 0 WHEN b.StatusID IN (114, 115) THEN 0.5 ELSE 1 END
						ELSE 1
					END * b.Turnover)
		,@VRGCustomerWl = SUM(b.winlost)
		,@VRGBetCount = SUM(CASE WHEN @DrawFilter = 2 AND b.StatusID = 111 THEN 0 ELSE b.BetCount END) 
	FROM @tblData b
	WHERE ProductPrefix = 'VRG'

	SELECT @VRGTurnover = ISNULL(@VRGTurnover,0)
		,@VRGCustomerWl = ISNULL(@VRGCustomerWl,0)
		,@VRGBetCount = ISNULL(@VRGBetCount,0)

	----TG
	SELECT @TGTurnover = SUM(CASE 
						WHEN @DrawFilter IN (2,3) THEN
							CASE WHEN b.StatusID = 111 THEN 0 WHEN b.StatusID IN (114,115) THEN 0.5 ELSE 1 END
						ELSE 1
					END * b.Turnover)
		,@TGCustomerWl = SUM(b.winlost)
		,@TGBetCount = SUM(CASE WHEN @DrawFilter=2 AND b.StatusID = 111 THEN 0 ELSE b.BetCount END)
	FROM @tblData b
	WHERE ProductPrefix = 'TG'

	SELECT @TGTurnover = ISNULL(@TGTurnover,0)
		,@TGCustomerWl = ISNULL(@TGCustomerWl,0)
		,@TGBetCount = ISNULL(@TGBetCount,0)

	-- I4D
	SELECT
		@I4DTurnover = SUM(CASE
							WHEN @DrawFilter IN (2, 3) THEN 
								CASE
									WHEN StatusId = 111 THEN 0
									WHEN StatusId IN (114, 115) THEN 0.5
									ELSE 1
								END
							ELSE 1
						END * Turnover),
		@I4DCustomerWl = SUM(WinLost),
		@I4DBetCount = SUM(CASE WHEN @DrawFilter = 2 AND StatusId = 111 THEN 0 ELSE BetCount END) 
	FROM @tblData
	WHERE ProductPrefix = 'I4D'
	
	-- SBC
	SELECT
		@SBCTurnover = SUM(CASE
							WHEN @DrawFilter IN (2, 3) THEN 
								CASE
									WHEN StatusId = 111 THEN 0
									WHEN StatusId IN (114, 115) THEN 0.5
									ELSE 1
								END
							ELSE 1
						END * Turnover),
		@SBCCustomerWl = SUM(WinLost),
		@SBCBetCount = SUM(CASE WHEN @DrawFilter = 2 AND StatusId = 111 THEN 0 ELSE BetCount END) 
	FROM @tblData
	WHERE ProductPrefix = 'SBC'

	----SXG
	SELECT
		@SXGTurnover=SUM(CASE 
							WHEN @DrawFilter IN (2,3) THEN 	
								CASE
									WHEN b.StatusID = 111 THEN 0
									WHEN b.StatusID IN (114,115) THEN 0.5
									ELSE 1
								END
							ELSE 1
						END * b.Turnover)
		,@SXGCustomerWl=SUM(b.winlost)
		,@SXGBetCount=SUM(CASE WHEN @DrawFilter=2 AND b.StatusID = 111 THEN 0 ELSE b.BetCount END)
	FROM @tblData b
	WHERE ProductPrefix = 'SXG'

	----JK
	SELECT
		@JKTurnover=SUM(CASE 
							WHEN @DrawFilter IN (2,3) THEN 	
								CASE
									WHEN b.StatusID = 111 THEN 0
									WHEN b.StatusID IN (114,115) THEN 0.5
									ELSE 1
								END
							ELSE 1
						END * b.Turnover)
		,@JKCustomerWl=SUM(b.winlost)
		,@JKBetCount=SUM(CASE WHEN @DrawFilter=2 AND b.StatusID = 111 THEN 0 ELSE b.BetCount END)
	FROM @tblData b
	WHERE ProductPrefix = 'JK'
	
	----SAG
	SELECT
		@SAGTurnover=SUM(CASE 
							WHEN @DrawFilter IN (2,3) THEN 	
								CASE
									WHEN b.StatusID = 111 THEN 0
									WHEN b.StatusID IN (114,115) THEN 0.5
									ELSE 1
								END
							ELSE 1
						END * b.Turnover)
		,@SAGCustomerWl=SUM(b.winlost)
		,@SAGBetCount=SUM(CASE WHEN @DrawFilter=2 AND b.StatusID = 111 THEN 0 ELSE b.BetCount END)
	FROM @tblData b
	WHERE ProductPrefix = 'SAG'

	----PGS
	SELECT
		@PGSTurnover=SUM(CASE 
							WHEN @DrawFilter IN (2,3) THEN 	
								CASE
									WHEN b.StatusID = 111 THEN 0
									WHEN b.StatusID IN (114,115) THEN 0.5
									ELSE 1
								END
							ELSE 1
						END * b.Turnover)
		,@PGSCustomerWl=SUM(b.winlost)
		,@PGSBetCount=SUM(CASE WHEN @DrawFilter=2 AND b.StatusID = 111 THEN 0 ELSE b.BetCount END)
	FROM @tblData b
	WHERE ProductPrefix = 'PGS'

	-- Result
	SELECT
		1 AS id
		,@SbTurnover AS Sb
		, @RbTurnover AS Rb
		, @NgTurnover AS Ng
		, @BaTurnover AS Ba
		, @CsTurnover AS Cs
		, @BTTurnover AS BT
		, @LcTurnover AS LC
		, @AGTurnover AS AG
		, @GDTurnover AS GD
		, @KNTurnover AS KN
		, @VGTurnover AS VG
		, @VBTurnover AS VB 
		, @MGCLCTurnover AS MGCLC
		, @MGCRNGTurnover AS MGCRNG
		, @VsTurnover AS VS
		, @CBTurnover AS CB
		, @ABTurnover AS AB
		, @NG2Turnover AS NG2
		, @FWTurnover AS FW
		, @COTurnover AS CO
		, @VS2Turnover AS VS2
		, @LTTurnover AS LT
		, @PPTurnover AS PP
		, @CCTurnover AS CC
		, @SPRTurnover AS SPR
		, @SGTurnover AS SG
		, @VRGTurnover AS VRG
		, @TGTurnover AS TG
		, ISNULL(@I4DTurnover,0) AS I4D
		, ISNULL(@SXGTurnover,0) AS SXG
		, ISNULL(@SBCTurnover,0) AS SBC
		, ISNULL(@JKTurnover,0) AS JK
		, ISNULL(@SAGTurnover,0) AS SAG
		, ISNULL(@PGSTurnover,0) AS PGS
	UNION
	SELECT
		2
		, @SbCustomerWl
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
		, @CBCustomerWl
		, @ABCustomerWl
		, @NG2CustomerWl
		, @FWCustomerWl
		, @COCustomerWl
		, @VS2CustomerWl
		, @LTCustomerWl
		, @PPCustomerWl
		, @CCCustomerWl
		, @SPRCustomerWl
		, @SGCustomerWl
		, @VRGCustomerWl
		, @TGCustomerWl
		, ISNULL(@I4DCustomerWl,0)
		, ISNULL(@SXGCustomerWl,0)
		, ISNULL(@SBCCustomerWl,0)
		, ISNULL(@JKCustomerWl,0)
		, ISNULL(@SAGCustomerWl,0)
		, ISNULL(@PGSCustomerWl,0)
	UNION
	SELECT
		3
		, @SbBetCount
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
		, @CBBetCount
		, @ABBetCount
		, @NG2BetCount
		, @FWBetCount
		, @COBetCount
		, @VS2BetCount
		, @LTBetCount
		, @PPBetCount
		, @CCBetCount
		, @SPRBetCount
		, @SGBetCount
		, @VRGBetCount
		, @TGBetCount
		, ISNULL(@I4DBetCount,0)
		, ISNULL(@SXGBetCount,0)
		, ISNULL(@SBCBetCount,0)
		, ISNULL(@JKBetCount,0)
		, ISNULL(@SAGBetCount,0)
		, ISNULL(@PGSBetCount,0)

	SET NOCOUNT OFF
END
GO