/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="bodbLicenseeNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[GEN_rptBettingByProduct] (
	@date DATE,
	@date2 DATE = NULL,
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
	EXEC GEN_rptBettingByProduct '2017-04-16', '2017-04-16'

*/

BEGIN  
	CREATE TABLE #BettypeProductMapping (Bettype INT, ProductID INT)
	CREATE TABLE #BettypeProductMappingBA (Bettype INT, ProductID INT)

	-- Collect data of 3rd party products
	CREATE TABLE #tmpData (rptDate DATE, CustID INT, ProductID INT, CurrencyId INT, Winlost MONEY, Turnover MONEY, BetCount INT, PlayerComm MONEY)

	IF @DataSource IN ('ALL', 'Rpt_Betting')
	BEGIN 
	
		IF @date2 IS NULL SET @date2 = @date
		SET @date2 = DATEADD(day,1,@date2)

		DELETE p 
		FROM dbo.rpt_BettingByProduct p
		WHERE p.rptDate >= @date AND p.rptDate < @date2
			  AND NOT (p.ProductID IN (10,11) AND p.SiteID <= 1000) ---- Exclude Separate Wallet of GD and AGC	  	 
			

		
		
		INSERT INTO #BettypeProductMapping (Bettype, ProductID)
		SELECT Bettype, ProductId
		FROM bodb_licensee.dbo.LA_f_BettypeProductMapping(0,'SB,NG,VS,RB,LC,CS,KN,BG,AGC,MGCLC,MGCRNG,BT,GD,CF,CB,VB,AB,FW,CO,VS2,LT')   

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
				)
		SELECT
			[rptDate]
			,[SiteID]
			,bt.ProductID
			,CASE WHEN bt.ProductID IN (1,13,14,17,15,25) THEN b.[Bettype] ELSE -1 END [Bettype]
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
		FROM dbo.rpt_Betting b WITH (NOLOCK)
			INNER JOIN #BettypeProductMapping bt ON b.Bettype = bt.Bettype
		WHERE rptDate >= @date AND rptDate < @date2
			AND b.Status IN (111,112,113,114,115,101,102,103)
			AND [CurrencyID] <> 20
		GROUP BY [rptDate]
				,[SiteID]
				, bt.ProductID
				,CASE WHEN bt.ProductID IN (1,13,14,17,15,25) THEN b.[Bettype] ELSE -1 END 
				,[CurrencyId]
				,Status
				,ISNULL([CustomerCategory],-1)
		UNION ALL
		SELECT
			[rptDate]
			,[SiteID]
			, bt.ProductID
			,CASE WHEN bt.ProductID IN (1,13,14,17) THEN b.[Bettype] ELSE -1 END [Bettype]
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
		FROM dbo.rpt_Betting_BA b WITH (NOLOCK)
			INNER JOIN #BettypeProductMappingBA bt ON b.Bettype = bt.Bettype
		WHERE rptDate >= @date AND rptDate < @date2
			AND b.Status IN (111,112,113,114,115,101,102,103)
			AND [CurrencyID] <> 20
		GROUP BY [rptDate]
				,[SiteID]
				, bt.ProductID
				,CASE WHEN bt.ProductID IN (1,13,14,17) THEN b.[Bettype] ELSE -1 END 
				,[CurrencyId]
				,Status
				,ISNULL([CustomerCategory],-1)
	
	END
	
	IF @DataSource IN ('All', 'SeparatedProduct')
	BEGIN 	

		DELETE p 
		FROM dbo.rpt_BettingByProduct p
		WHERE p.rptDate >= @date AND p.rptDate < @date2
			  AND (p.ProductID IN (10,11) AND p.SiteID <= 1000) ---- Delete only Separate Wallet of GD and AGC
			  AND ( p.ProductID = @SeparatedProductID OR @SeparatedProductID = 0)

		-- GD, VG (separate wallet)
		IF @SeparatedProductID IN (0, 11)
		BEGIN 
			INSERT INTO #tmpData (rptDate, CustID, ProductID, CurrencyId, Winlost, Turnover, BetCount, PlayerComm)
			SELECT Winlostdate, Custid, ProductId, Currency, Winlost, Turnover, BetCount, 0 AS PlayerComm
			FROM dbo.rptDepWinlost_ThirdParty WITH (NOLOCK)
			WHERE Winlostdate >= @date AND Winlostdate < @date2
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
				,[CashOutAmount])
		SELECT td.rptDate
			, ISNULL(site.SiteID,-1) AS SiteId
			, td.productId
			, -1 AS bettype
			, td.CurrencyId
			, CASE 
				WHEN td.Winlost > 0 THEN 112
				WHEN td.Winlost < 0 THEN 113
				ELSE 111
			  END AS StatusId
			, -1 AS CustomerCategory
			, 0 AS GrossWL
			, SUM(ISNULL(td.Winlost,0)) AS MemberWL
			, SUM(ISNULL(td.Turnover,0)) AS Turnover
			, SUM(ISNULL(td.BetCount,0)) AS BetCount
			, 0 AS CommissionA
			, SUM(ISNULL(PlayerComm,0)) AS CommissionP
			, 0 AS BuyBackAmount
			, 0 [WinPrizeAmount]
			, 0 [CashOutAmount]
		FROM #tmpData td WITH (NOLOCK)
			LEFT JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON c.Custid = td.CustID AND c.roleid = 1
			LEFT JOIN bodb02.dbo.customer ag WITH (NOLOCK) ON c.recommend = ag.custid AND ag.roleid = 2
			LEFT JOIN bodb02.dbo.Site ibcsite WITH (NOLOCK) ON ag.site=ibcsite.site
			LEFT JOIN bodb_licensee.dbo.view_site_list [site] WITH (NOLOCK) ON ibcsite.siteid=site.IbcSiteID
		GROUP BY rptDate
			, ISNULL(site.SiteID,-1)
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
