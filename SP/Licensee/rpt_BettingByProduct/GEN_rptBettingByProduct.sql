/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="bodbLicenseeNet" viewers="" isFunction="0" isNested="0"></info>*/
USE bodb_LicenseeReport
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

ALTER PROCEDURE [dbo].[GEN_rptBettingByProduct] (
	@date DATE,
	@date2 DATE = NULL,
	@ProductCodes VARCHAR(1000) = '',
	@DataSource VARCHAR(20) = 'All',
	@SeparatedProductID TINYINT = 0
	)
AS
/*  Created: 20150710@Victor
    Task : Generate data for rpt_BettingByProduct
    DB: DBLIC/bodb_LicenseeReport  
    Param's Explanation:   
		@DataSource = 'Rpt_Betting'
					= 'SeparatedProduct'
					= 'All'
		@SeparatedProductID = 10: AGC
							= 11: GD
							= 0 : All Separate products
		@ProductCodes		= '': Get all data
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

	EXEC GEN_rptBettingByProduct '2018-02-01', '2018-02-28'

*/

BEGIN  
	CREATE TABLE #BettypeProductMapping (Bettype INT, ProductID INT)
	CREATE TABLE #BettypeProductMappingBA (Bettype INT, ProductID INT)

	-- Collect data of 3rd party products
	CREATE TABLE #tmpData (rptDate DATE, CustID INT, ProductID INT, CurrencyId INT, Winlost MONEY, Turnover MONEY, BetCount INT, PlayerComm MONEY, AgentComm MONEY, ValidBetAmount MONEY, GrossWL MONEY, Bettype SMALLINT)

	IF @date2 IS NULL SET @date2 = @date
	SET @date2 = DATEADD(day,1,@date2)

	IF @DataSource IN ('ALL', 'Rpt_Betting')
	BEGIN 		

		DELETE p 
		FROM dbo.rpt_BettingByProduct p
		WHERE p.rptDate >= @date AND p.rptDate < @date2
			  AND NOT (p.ProductID IN (10,11,31) AND p.SiteID <= 1000) ---- Exclude Separate Wallet of GD and AGC and Exchange
			  AND (@ProductCodes = '' OR ProductID IN (SELECT DISTINCT ProductID FROM bodb_licensee.dbo.LA_f_BettypeProductMapping(0, @ProductCodes))) 	 
					
		INSERT INTO #BettypeProductMapping (Bettype, ProductID)
		SELECT Bettype, ProductId
		FROM bodb_licensee.dbo.LA_f_BettypeProductMapping(0,'SB,NG,VS,RB,LC,CS,KN,BG,AGC,BT,GD,CF,CB,VB,AB,FW,CO,VS2,LT,PP,BF,PG,CC') -- Remove Exchange (BX) due to separate wallet only

		INSERT INTO #BettypeProductMappingBA (Bettype, ProductID)
		SELECT Bettype, ProductId 
		FROM bodb_licensee.dbo.LA_f_BettypeProductMapping(0,'BA')

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
			[rptDate]
			,[SiteID]
			,bt.ProductID
			,CASE 
				WHEN bt.ProductID IN (1,13,15,25) 
						OR b.Bettype = 1499 
						OR b.Bettype = 4300 -- Promotion Prize Win
					THEN b.[Bettype]
				WHEN b.Bettype BETWEEN 8101 AND 8120 THEN 8101
				ELSE -1 END [Bettype]
			,[CurrencyId]
			,Status [StatusId]
			,ISNULL([CustomerCategory],-1)
			,SUM(ISNULL(WinLossA,0)) [GrossWL]
			,SUM(ISNULL(WinLoss,0)) [MemberWL]
			,SUM(ISNULL([Turnover],0)) [Turnover]
			,SUM(ISNULL([BetCount],0)) [BetCount]
			,SUM(ISNULL([CommissionA],0)) [CommissionA]
			,SUM(ISNULL([CommissionP],0)) [CommissionP]
			,SUM(ISNULL([BuyBackAmount],0)) [BuyBackAmount]
			,SUM(ISNULL([WinPrizeAmount],0)) [WinPrizeAmount]
			,SUM(ISNULL([CashOutAmount],0)) [CashOutAmount]
			,SUM(ISNULL([oddsspread],0)) 	[ValidBetAmount]
			,SUM(ISNULL([ExtraAmount],0)) [ExtraAmount]
			,TicketType
		FROM dbo.rpt_Betting b WITH (NOLOCK)
			INNER JOIN #BettypeProductMapping bt ON b.Bettype = bt.Bettype
		WHERE rptDate >= @date AND rptDate < @date2
			AND b.Status IN (111,112,113,114,115,101,102,103)
			AND [CurrencyID] <> 20
			AND (@ProductCodes = '' OR b.bettype IN (SELECT Bettype FROM bodb_licensee.dbo.LA_f_BettypeProductMapping(0, @ProductCodes)))
		GROUP BY [rptDate]
				,[SiteID]
				, bt.ProductID
				,CASE 
					WHEN bt.ProductID IN (1,13,15,25) 
							OR b.Bettype = 1499 
							OR b.Bettype = 4300 -- Promotion Prize Win
						THEN b.[Bettype]
					WHEN b.Bettype BETWEEN 8101 AND 8120 THEN 8101
					ELSE -1 END
				,[CurrencyId]
				,Status
				,ISNULL([CustomerCategory],-1)
				,TicketType
		UNION ALL
		SELECT
			[rptDate]
			,[SiteID]
			, bt.ProductID
			,CASE WHEN bt.ProductID IN (1,13) THEN b.[Bettype] ELSE -1 END [Bettype]
			,[CurrencyId]
			,Status [StatusId]
			,ISNULL([CustomerCategory],-1)
			,SUM(ISNULL(WinLossA,0)) [GrossWL]
			,SUM(ISNULL(WinLoss,0)) [MemberWL]
			,SUM(ISNULL([Turnover],0)) [Turnover]
			,SUM(ISNULL([BetCount],0)) [BetCount]
			,SUM(ISNULL([CommissionA],0)) [CommissionA]
			,SUM(ISNULL([CommissionP],0)) [CommissionP]
			,SUM(ISNULL([BuyBackAmount],0)) [BuyBackAmount]
			,0 [WinPrizeAmount]
			,0 [CashOutAmount]
			,0 [ValidBetAmount]	
			,SUM(ISNULL([ExtraAmount],0)) [ExtraAmount]
			,TicketType 
		FROM dbo.rpt_Betting_BA b WITH (NOLOCK)
			INNER JOIN #BettypeProductMappingBA bt ON b.Bettype = bt.Bettype
		WHERE rptDate >= @date AND rptDate < @date2
			AND b.Status IN (111,112,113,114,115,101,102,103)
			AND [CurrencyID] <> 20
			AND (@ProductCodes = '' OR b.bettype IN (SELECT Bettype FROM bodb_licensee.dbo.LA_f_BettypeProductMapping(0, @ProductCodes)))
		GROUP BY [rptDate]
				,[SiteID]
				, bt.ProductID
				,CASE WHEN bt.ProductID IN (1,13) THEN b.[Bettype] ELSE -1 END 
				,[CurrencyId]
				,Status
				,ISNULL([CustomerCategory],-1)
				,TicketType
	
	END
	
	IF @DataSource IN ('All', 'SeparatedProduct')
	BEGIN 	
		-- Exchange product (separate wallet)
		IF @SeparatedProductID IN (0, 31)
		BEGIN
			DECLARE @ResettledDateList AS TABLE (ID BIGINT, SettledDate DATE)
			DECLARE @WLDateList AS TABLE (ID SMALLINT IDENTITY (1,1), Winlostdate DATE)			

			INSERT INTO @ResettledDateList ( ID, SettledDate )
			SELECT h.ID, h.WinlostDate
			FROM bodb_3rdProduct.dbo.Product3rd_SummarizedDateHistory h WITH (NOLOCK)
			WHERE h.ProductID = 31 AND h.SumToThirdPartyDate IS NOT NULL AND h.SumToBettingProductDate IS NULL

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
		
			INSERT INTO #tmpData (rptDate, CustID, ProductID, CurrencyId, Winlost, GrossWL, Turnover, BetCount, PlayerComm, AgentComm, ValidBetAmount)
			SELECT Winlostdate, Custid, ProductId, Currency, Winlost, WinlostA, Turnover, BetCount
				, CommissionP AS PlayerComm
				, CommissionA AS AgentComm
				, ValidBetAmount
			FROM dbo.rptDepWinlost_ThirdParty p WITH (NOLOCK)
			WHERE p.ProductId = 31 
				AND EXISTS (SELECT 1 FROM @WLDateList l WHERE p.Winlostdate = l.Winlostdate)
				AND [Currency] <> 20
			
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
			  AND (p.ProductID IN (10,11) AND p.SiteID <= 1000) 
			  AND ( p.ProductID = @SeparatedProductID OR @SeparatedProductID = 0)

		-- GD, VG (separate wallet)
		IF @SeparatedProductID IN (0, 11)
		BEGIN 
			INSERT INTO #tmpData (rptDate, CustID, ProductID, CurrencyId, Winlost, Turnover, BetCount, PlayerComm, Bettype)
			SELECT Winlostdate, Custid, ProductId, Currency, Winlost, Turnover, BetCount, 0 AS PlayerComm, Bettype
			FROM dbo.rptDepWinlost_ThirdParty WITH (NOLOCK)
			WHERE Winlostdate >= @date AND Winlostdate < @date2
				AND ProductId = 11
				AND [Currency] <> 20 
		END
		
		-- AGCS (separate wallet)
		IF @SeparatedProductID IN (0, 10)
		BEGIN 
			INSERT INTO #tmpData (rptDate, CustID, ProductID, CurrencyId, Winlost, Turnover, BetCount, PlayerComm)
			SELECT Winlostdate, Custid, 10 AS ProductId, Currency, SUM(Winlost), SUM(Turnover), SUM(BetCount), SUM(PlayerComm)
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
			LEFT JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON c.Custid = td.CustID AND c.roleid = 1
			LEFT JOIN bodb02.dbo.customer ag WITH (NOLOCK) ON c.recommend = ag.custid AND ag.roleid = 2
			LEFT JOIN bodb02.dbo.Site ibcsite WITH (NOLOCK) ON ag.site=ibcsite.site
			LEFT JOIN bodb_licensee.dbo.view_site_list [site] WITH (NOLOCK) ON ibcsite.siteid=site.IbcSiteID
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