/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="bodbLicenseeNet" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[GEN_rptBettingByProduct]
	@date				DATE,
	@date2				DATE			= NULL,
	@DataSource			VARCHAR(20)		= 'All',
	@SeparatedProductID	TINYINT			= 0,
	@ProductCodes		VARCHAR(1000)	= ''
AS

/*
	Created: 20150710@Victor
	Task: Generate data for rpt_BettingByProduct
	DB: DBLIC/bodb_LicenseeReport
	Param's Explanation:
		@DataSource = 'Rpt_Betting'
					= 'SeparatedProduct'
					= 'All'
		@SeparatedProductID = 10: AGC
							= 11: GD
							= 0 : All Separate products
		@ProductCodes		= '': Get all of datum
							= 'VS, PP ..': Get data by specific product
	Revisions:
		- 20150923@Victor: Fix third party data summary issues (AGCS, VG, GD)
		- 20151002@Victor: Move all Bettrade detail tickets (901,902,903) to product BT
		- 20151021@Victor: Support AG Casino Single Wallet and include Void, Reject, Refund tickets
		- 20151105@Victor: Summary data for Racing by bettype [Redmine: #44873]
		- 20151201@Bravo: Change Product code: MGC -> MGCLC
		- 20151222@Francis: Add GD Single Wallet data for Credit
		- 20160226@Victor: Support Cock Fighting data [Redmine: #52452]
		- 20160315@Bruce: Summary data for Colossus bets(CB)
		- 20160509@Bruce: Summary data for Voidbridge(VB)
		- 20160726@Francis: Move SP to bodb_LicenseeReport - [Redmine: #60449]
		- 20160907@Harper: #62820_Add AllBet for ProductMapping
		- 20161205@Jim: LA - GD commercial terms changed for credit sites [RedmineID #67310]
		- 20170314@Sophia: Integrate Fishing World [Redmine: #73303]
		- 20170323@Harper: LA - Implement Cashout Product [Redmine: #73310]
		- 20170526@Sophia: add Param @DataSource, @SeparatedProductID [Redmine: #72914]
		- 20170712@Harper: Implement new Product Betradar VS [Redmine: #78241]
		- 20170619@Harper: LRF - Integrate Lottery [RedmineID: #79997]
		- 20171220@Harper: LRF - Integrate separate wallet Exchange product [RedmineID: #86640]
		- 20180207@Harper: LA - Fix bug date range for Exchange product [RedmineID: #87754]
		- 20180316@Harper: LA - Colossus Bets Free Play Integration [RedmineID: #89768]
		- 20180420@Bruce: LA - Implement sum job for Pragmatic [RedmineId #93958]
		- 20180910@Bruce: LA - WL report for Poker Games & Bullfighting [#98487]
		- 20181113@Bruce: New Games Sicbo & Bidme - Service to pull deposit data for Bidme Tips [#102624]
		- 20181204@Bruce: Implement Happy 5 [RedmineID: #105723]
			bettype: 8101 - 8120
			bettypeRef: 8101
		- 20190308@Parsons: Integrate PP promotion prize [#109014]
		- 20190418@Percy: Remove Exchange for Datasource = rpt_Betting [RedmineID: #111937]
		- 20190321@Joseph: Remove Microgaming LC + RNG [RedmineID: #107704]
		- 20190710@Amanda: Integrate Card Club [RedmineID: #115449]
		- 20190819@Parsons: Provide House Turnover In NG WL Report [Redmine: #117674]
		- 20191122@Amanda: Integrate PP Tournament Prize [#123804]
		- 20191125@Parsons: Integrate NPH Promotion [RedmineID: #119538]
		- 20191218@Amanda: Integrate Spadegaming [#124103]
		- 20200108@Vickie: Integrate Virtual Games [RedmineID: #124911]
		- 20200326@Parsons: Integrate Sexy Gaming [RedmineID: #130948]
		- 20200407@Vickie: Integrate Table Games [RedmineID: #131447]
		- 20200415@Parsons: Integrate BBIN-Live-Casino [RedmineID: #132237]
		- 20200416@Vickie: Add new product Indo 4D [RedmineID: #130859]
		- 20200422@Parsons: Integrate-IBCBET-Live-Casino [RedmineID: #131165]
		- 20200423@Vickie: Integrate Saba Club [RedmineID: #132702]
		- 20200610@Parsons: Integrate RNG WAR and ION [RedmineID: #134452]
		- 20200714@Parsons: Implement PP Jackpot [RedmineID: #137306]
		- 20200909@Parsons: Implement PG Soft [RedmineID: #138983]
		- 20200921@Parsons: Implement Joker Games [RedmineID: #141421]
		- 20201009@Parsons: Integrate SA Gaming [#143272]
		- 20201021@Parsons: Integrate WM Live Casino [#141357]
		- 20201019@Parsons: Arcadia Gaming - Add Bonus feature [RedmineID: #143597]
		- 20201026@Parsons: Change request of Odds Spread [RedmineID: #142345]
		- 20201130@Parsons: Integrate Leap Gaming Virtual Sports [#145339]
		- 20201203@Parsons: Integrate Gold Diamond Gaming [#145340]
		- 20210104@Parsons: Integrate Big Gaming [#145342]
		- 20210104@Parsons: Integrate MaxGame [#147375]
		- 20210113@Parsons: Saba.club Integrate Slot Game [#147977]
		- 20210308@Parsons: Integrate Habanero  Product [#150636]
		- 20210308@Parsons: Integrate Sports Lottery Product [#150866]

	EXEC GEN_rptBettingByProduct '2018-02-01', '2018-02-28'
*/

BEGIN
	SET NOCOUNT ON

	CREATE TABLE #BettypeProductMapping (Bettype INT, ProductID INT)
	CREATE TABLE #BettypeProductMappingBA (Bettype INT, ProductID INT)

	DECLARE @ProductIdList AS TABLE(ProductId INT)

	INSERT INTO @ProductIdList(ProductId)
	SELECT ProductID
	FROM bodb_Licensee.dbo.LA_f_Products3rd(@ProductCodes)

	-- Collect data of 3rd party products
	CREATE TABLE #tmpData (
		rptDate			DATE,
		CustID			INT,
		ProductID		INT,
		CurrencyId		INT,
		Winlost			MONEY,
		Turnover		MONEY,
		BetCount		INT,
		PlayerComm		MONEY,
		AgentComm		MONEY,
		ValidBetAmount	MONEY,
		GrossWL			MONEY,
		Bettype			SMALLINT)

	IF @date2 IS NULL
		SET @date2 = @Date

	SET @date2 = DATEADD(DAY, 1, @date2)

	IF @DataSource IN ('ALL', 'Rpt_Betting')
	BEGIN
		DELETE p
		FROM dbo.rpt_BettingByProduct p
		WHERE p.rptDate >= @date AND p.rptDate < @date2
			AND NOT (p.ProductID IN (10,11,31) AND p.SiteID <= 1000) ---- Exclude Separate Wallet of GD and AGC and Exchange
			AND (@ProductCodes = '' OR ProductID IN (SELECT ProductID FROM @ProductIdList))

		INSERT INTO #BettypeProductMapping (Bettype, ProductID)
		SELECT Bettype, ProductId
		FROM bodb_licensee.dbo.LA_f_BettypeProductMapping(0,'SB,NG,VS,RB,LC,CS,KN,BG,AGC,BT,GD,CF,CB,VB,AB,FW,CO,VS2,LT,PP,BF,PG,CC,SPR,SG,VRG,SXG,TG,BBIN,I4D,IBCLC,SBC,ION,RNGW,PGS,JK,SAG,WM,VS3,GDG,BGG,MXG,HB,SLT') -- Remove Exchange (BX) due to separate wallet only
		WHERE @ProductCodes = ''
			OR ProductID IN (SELECT ProductID FROM @ProductIdList)

		INSERT INTO #BettypeProductMappingBA (Bettype, ProductID)
		SELECT Bettype, ProductId 
		FROM bodb_licensee.dbo.LA_f_BettypeProductMapping(0,'BA')
		WHERE @ProductCodes = ''
			OR ProductID IN (SELECT ProductID FROM @ProductIdList)

		-- Import data from rpt_Betting / rpt_Betting_BA
		INSERT INTO [dbo].[rpt_BettingByProduct]
			([rptDate]
			,[SiteID]
			,[ProductID]
			,[Bettype]
			,[CurrencyId]
			,[StatusId]
			,[CustomerCategory]
			,[GrossWL]
			,[MemberWL]
			,[Turnover]
			,[BetCount]
			,[CommissionA]
			,[CommissionP]
			,[BuyBackAmount]
			,[WinPrizeAmount]
			,[CashOutAmount]
			,[ValidBetAmount]
			,[ExtraAmount]
			,[TicketType]
			)
		SELECT
			b.rptDate
			,b.SiteID
			,bt.ProductID
			,CASE
				WHEN bt.ProductID IN (1,13,15,25) 
						OR b.Bettype IN (1499, 4300, 4299, 4297, 4298, 3007, 1906, 999,1698,1699) 
						/* PP Prize (4300,4299), PP-Jackpot-Contribution(4297), PP-Jackpot-Prize(4298)
						   , SAG_Tips (3007)
						   , CC-Bonus(1906)
						   , SB-Adjusted Odds(999)
						   , Saba.club Contribution(1698), Saba.club Jackpot Prize(1699)
						*/
					THEN b.Bettype
				WHEN b.Bettype BETWEEN 8101 AND 8120 THEN 8101
				ELSE -1
			END AS Bettype
			,b.CurrencyID
			,b.Status AS StatusId
			,ISNULL([CustomerCategory],-1)
			,SUM(ISNULL(b.WinLossA, 0)) [GrossWL]
			,SUM(ISNULL(b.WinLoss, 0)) [MemberWL]
			,SUM(ISNULL([Turnover], 0)) [Turnover]
			,SUM(ISNULL([BetCount], 0)) [BetCount]
			,SUM(ISNULL([CommissionA], 0)) [CommissionA]
			,SUM(ISNULL([CommissionP], 0)) [CommissionP]
			,SUM(ISNULL([BuyBackAmount], 0)) [BuyBackAmount]
			,SUM(ISNULL([WinPrizeAmount], 0)) [WinPrizeAmount]
			,SUM(ISNULL([CashOutAmount], 0)) [CashOutAmount]
			,SUM(ISNULL([oddsspread], 0)) [ValidBetAmount]
			,SUM(ISNULL([ExtraAmount], 0)) [ExtraAmount]
			,TicketType
		FROM dbo.rpt_Betting b WITH (NOLOCK)
			INNER JOIN #BettypeProductMapping bt ON b.Bettype = bt.Bettype
		WHERE b.rptDate >= @date AND b.rptDate < @date2
			AND b.Status IN (111,112,113,114,115,101,102,103)
			AND b.CurrencyID <> 20
		GROUP BY b.rptDate
			,b.SiteID
			,bt.ProductID
			,CASE 
				WHEN bt.ProductID IN (1,13,15,25) 
						OR b.Bettype IN (1499, 4300, 4299, 4297, 4298, 3007, 1906, 999,1698,1699) 
						/* PP Prize (4300,4299), PP-Jackpot-Contribution(4297), PP-Jackpot-Prize(4298)
						   , SAG_Tips (3007)
						   , CC-Bonus(1906)
						   , SB-Adjusted Odds(999)
						   , Saba.club Contribution(1698), Saba.club Jackpot Prize(1699)
						*/
					THEN b.Bettype
				WHEN b.Bettype BETWEEN 8101 AND 8120 THEN 8101
				ELSE -1
			END
			,b.CurrencyID
			,b.Status
			,ISNULL(b.CustomerCategory,-1)
			,b.TicketType
		UNION ALL
		SELECT
			b.rptDate
			,b.SiteID
			, bt.ProductID
			,CASE WHEN bt.ProductID IN (1,13) THEN b.Bettype ELSE -1 END Bettype
			,b.CurrencyID
			,b.Status AS StatusId
			,ISNULL(b.CustomerCategory, -1)
			,SUM(ISNULL(b.WinLossA, 0)) AS GrossWL
			,SUM(ISNULL(b.WinLoss, 0)) AS MemberWL
			,SUM(ISNULL(b.Turnover, 0)) AS Turnover
			,SUM(ISNULL(b.BetCount, 0)) AS BetCount
			,SUM(ISNULL(b.CommissionA, 0)) AS CommissionA
			,SUM(ISNULL(b.CommissionP, 0)) AS CommissionP
			,SUM(ISNULL(b.BuyBackAmount, 0)) AS BuyBackAmount
			,0 WinPrizeAmount
			,0 CashOutAmount
			,0 ValidBetAmount
			,SUM(ISNULL(b.ExtraAmount,0)) ExtraAmount
			,b.TicketType
		FROM dbo.rpt_Betting_BA b WITH (NOLOCK)
			INNER JOIN #BettypeProductMappingBA bt ON b.Bettype = bt.Bettype
		WHERE b.rptDate >= @date AND b.rptDate < @date2
			AND b.Status IN (111,112,113,114,115,101,102,103)
			AND b.CurrencyID <> 20
		GROUP BY b.rptDate
			,b.SiteID
			,bt.ProductID
			,CASE WHEN bt.ProductID IN (1,13) THEN b.Bettype ELSE -1 END 
			,b.CurrencyID
			,b.Status
			,ISNULL(b.CustomerCategory, -1)
			,b.TicketType
	END
	
	IF @DataSource IN ('All', 'SeparatedProduct')
	BEGIN
		-- Exchange product (separate wallet)
		DECLARE @HasExchangeProduct BIT = 1

		IF @ProductCodes <> ''
			AND NOT EXISTS(SELECT TOP 1 1 FROM @ProductIdList WHERE ProductID = 31)
		BEGIN
			SET @HasExchangeProduct = 0
		END

		IF @SeparatedProductID IN (0, 31) AND @HasExchangeProduct = 1
		BEGIN
			DECLARE @ResettledDateList AS TABLE (ID BIGINT, SettledDate DATE)
			DECLARE @WLDateList AS TABLE (ID SMALLINT IDENTITY (1,1), Winlostdate DATE)

			INSERT INTO @ResettledDateList (ID, SettledDate)
			SELECT ID, WinlostDate
			FROM bodb_3rdProduct.dbo.Product3rd_SummarizedDateHistory WITH (NOLOCK)
			WHERE ProductID = 31
				AND SumToThirdPartyDate IS NOT NULL
				AND SumToBettingProductDate IS NULL

			;WITH WLDate AS (	SELECT @date AS [Date]
								UNION ALL
								SELECT DATEADD(DAY, 1, [Date])
								FROM WLDate
								WHERE DATEADD(DAY, 1, [Date]) < @date2 )
			INSERT INTO @WLDateList	(Winlostdate)
			SELECT [Date] AS Winlostdate
			FROM WLDate OPTION (MAXRECURSION 0)

			INSERT INTO @WLDateList ( Winlostdate )
			SELECT DISTINCT r.SettledDate
			FROM @ResettledDateList r
			WHERE NOT EXISTS (SELECT 1 FROM @WLDateList d WHERE r.SettledDate = d.Winlostdate)

			-- Delete data for exchange product
			DELETE p
			FROM dbo.rpt_BettingByProduct p
			WHERE (p.ProductID = 31 AND p.SiteID <= 1000) 
				AND EXISTS (SELECT 1 FROM @WLDateList WHERE Winlostdate = p.rptDate)
		
			INSERT INTO #tmpData (
				rptDate,
				CustID,
				ProductID,
				CurrencyId,
				Winlost,
				GrossWL,
				Turnover,
				BetCount,
				PlayerComm,
				AgentComm,
				ValidBetAmount)
			SELECT
				p.Winlostdate,
				p.Custid,
				p.ProductId,
				p.Currency,
				p.Winlost,
				p.WinLostA,
				p.Turnover,
				p.BetCount,
				p.CommissionP AS PlayerComm,
				p.CommissionA AS AgentComm,
				p.ValidBetAmount
			FROM dbo.rptDepWinlost_ThirdParty AS p WITH (NOLOCK)
			WHERE p.ProductId = 31 
				AND EXISTS (SELECT 1 FROM @WLDateList l WHERE p.Winlostdate = l.Winlostdate)
				AND p.Currency <> 20
			
			UPDATE h
			SET h.SumToBettingProductDate = GETDATE()
			FROM bodb_3rdProduct.dbo.Product3rd_SummarizedDateHistory h WITH (ROWLOCK)
			WHERE EXISTS (SELECT 1 FROM @WLDateList d WHERE h.WinlostDate = d.Winlostdate)
				AND EXISTS (SELECT 1 FROM @ResettledDateList r WHERE h.ID = r.ID)
		END
		-- End Exchange product

		---- Delete only Separate Wallet of GD and AGC
		DELETE p 
		FROM dbo.rpt_BettingByProduct p
		WHERE p.rptDate >= @date AND p.rptDate < @date2
			AND (p.ProductID IN (10, 11) AND p.SiteID <= 1000) 
			AND ( p.ProductID = @SeparatedProductID OR @SeparatedProductID = 0)
			AND (@ProductCodes = '' OR ProductID IN (SELECT pList.ProductID FROM @ProductIdList pList))

		-- GD, VG (separate wallet)
		DECLARE @HasGDProduct BIT = 1

		IF @ProductCodes <> ''
			AND NOT EXISTS(SELECT TOP 1 1 FROM @ProductIdList WHERE ProductID = 11)
		BEGIN
			SET @HasGDProduct = 0
		END

		IF @SeparatedProductID IN (0, 11) AND @HasGDProduct = 1
		BEGIN 
			INSERT INTO #tmpData (
				rptDate,
				CustID,
				ProductID,
				CurrencyId,
				Winlost,
				Turnover,
				BetCount,
				PlayerComm,
				Bettype)
			SELECT
				Winlostdate,
				Custid,
				ProductId,
				Currency,
				Winlost,
				Turnover,
				BetCount,
				0 AS PlayerComm,
				Bettype
			FROM dbo.rptDepWinlost_ThirdParty WITH (NOLOCK)
			WHERE Winlostdate >= @date AND Winlostdate < @date2
				AND ProductId = 11
				AND Currency <> 20
		END
		
		-- AGCS (separate wallet)
		DECLARE @HasAGCProduct BIT = 1

		IF @ProductCodes <> ''
			AND NOT EXISTS(SELECT TOP 1 1 FROM @ProductIdList WHERE ProductID = 10)
		BEGIN
			SET @HasAGCProduct = 0
		END

		IF @SeparatedProductID IN (0, 10) AND @HasAGCProduct = 1
		BEGIN
			INSERT INTO #tmpData (
				rptDate,
				CustID,
				ProductID,
				CurrencyId,
				Winlost,
				Turnover,
				BetCount,
				PlayerComm)
			SELECT
				Winlostdate,
				Custid,
				10 AS ProductId,
				Currency,
				SUM(Winlost),
				SUM(Turnover),
				SUM(BetCount),
				SUM(PlayerComm)
			FROM DBRPT.bodb_report.dbo.rptDepWinlost_AGCasino WITH (NOLOCK)
			WHERE Winlostdate >= @date AND Winlostdate < @date2
				AND [Currency] <> 20
			GROUP BY Winlostdate, Custid, Currency
		END

		-- PTCS
		/*	
		INSERT INTO #tmpData (rptDate, CustID, ProductID, CurrencyId, Winlost, Turnover, BetCount, PlayerComm)
		SELECT Winlostdate, Custid, 9 AS ProductId, Currency, Winlost, Turnover, BetCount, PlayerComm
		FROM DBRPT.bodb_report.dbo.rptDepWinlost_PlaytechCS WITH (NOLOCK)
		WHERE Winlostdate >= @date AND Winlostdate < @date2
			AND [Currency] <> 20
		*/

		INSERT INTO [dbo].[rpt_BettingByProduct]
			([rptDate]
			,[SiteID]
			,[ProductID]
			,[Bettype]
			,[CurrencyId]
			,[StatusId]
			,[CustomerCategory]
			,[GrossWL]
			,[MemberWL]
			,[Turnover]
			,[BetCount]
			,[CommissionA]
			,[CommissionP]
			,[BuyBackAmount]
			,[WinPrizeAmount]
			,[CashOutAmount]
			,[ExtraAmount]
			,[TicketType])
		SELECT td.rptDate
			, ISNULL(site.SiteID,-1) AS SiteId
			, td.productId
			, ISNULL(td.Bettype, -1) AS bettype
			, td.CurrencyId
			, CASE 
				WHEN td.Winlost > 0 THEN 112
				WHEN td.Winlost < 0 THEN 113
				ELSE 111
			  END AS StatusId
			, -1 AS CustomerCategory
			, SUM(ISNULL(td.GrossWL,0)) AS GrossWL
			, SUM(ISNULL(td.Winlost,0)) AS MemberWL
			, SUM(ISNULL(td.Turnover,0)) AS Turnover
			, SUM(ISNULL(td.BetCount,0)) AS BetCount
			, SUM(ISNULL(td.AgentComm,0)) AS CommissionA
			, SUM(ISNULL(td.PlayerComm,0)) AS CommissionP
			, 0 AS BuyBackAmount
			, 0 [WinPrizeAmount]
			, 0 [CashOutAmount]
			, 0 AS [ExtraAmount]
			, 0 AS [TicketType]
		FROM #tmpData td WITH (NOLOCK)
			LEFT JOIN bodb02.dbo.Customer AS c WITH (NOLOCK) ON c.Custid = td.CustID AND c.roleid = 1
			LEFT JOIN bodb02.dbo.customer AS ag WITH (NOLOCK) ON c.recommend = ag.custid AND ag.roleid = 2
			LEFT JOIN bodb02.dbo.Site AS ibcsite WITH (NOLOCK) ON ag.site = ibcsite.site
			LEFT JOIN bodb_licensee.dbo.view_site_list AS [site] WITH (NOLOCK) ON ibcsite.SiteID = site.IbcSiteID
		GROUP BY rptDate
			, ISNULL(site.SiteID,-1)
			, ISNULL(td.Bettype, -1)
			, td.productId
			, td.CurrencyId
			, CASE 
				WHEN td.Winlost > 0 THEN 112
				WHEN td.Winlost < 0 THEN 113
				ELSE 111
			  END
	END

	DROP TABLE #tmpData
	DROP TABLE #BettypeProductMapping
	DROP TABLE #BettypeProductMappingBA
END
GO