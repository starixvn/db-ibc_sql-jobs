/*<info serverAlias="DBLIC-bodb_LicenseeReport" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[GEN_rptBetting]
	@date			SMALLDATETIME,
	@date2			SMALLDATETIME = NULL,
	@ProductCodes	VARCHAR(1000) = ''
AS

/*
	Created: 20110517@Elly
	Task: Generate data into rpt_Betting 
	DB: DBLIC.bodb_LicenseeReport

	Revisions:
		20110708@Elly: Process data of Fee and Comm
		20110726@Daniel: Process Non-BA data only
		20111115@Don: Add information to identify 8RM (customercategory=27)
		20121102@Jim: add process to generate data for KPI NumberGame report
		20130903@Jim: support Virtual Horse Racing
		20150623@Patrick: Support BetTrade
		20150917@Francis: Cast LiveIndicator to 0 if it is NULL
		20151119@Jim: separate MicroGame into 2 product (#46454 )
		20160106@Bobby: add OneRnG Casino
		20160129@Jim: fix bug #51781
		20160321@Victor: Support Colossus bet [Redmine: #52575]
		20160726@Francis: Move SP to bodb_LicenseeReport - [Redmine: #60449]
		20161205@Jim: LA - GD commercial terms changed for credit sites [RedmineID #67310]
		20170323@Harper: LA - Implement Cashout Product [Redmine: #73310]
		20170712@Harper: Implement new Product Betradar VS [Redmine: #78241]
		20171019@Harper: LA - Shutdown KPI Report [RedmineID: #83983]
		20180316@Harper: LA - Colossus Bets Free Play Integration [RedmineID: #89768]
		20180910@Bruce: LA - WL report for Poker Games & Bullfighting [#98487]
		20190508@Parsons: Implement BetBuilder [Redmine: #108995]
		20190808@Parsons: Provide House Turnover In NG WL Report [Redmine: #117674]
		20190918@Parsons: Update house turnover's formula [Redmine: #120119]
		20191209@Percy: Enhance performance [RedmineID: #125028]
		20200403@Parsons: Indo 4D Integration [RedmineID: #130910]
		20200804@Sol: Include vsraceinfo14 [RedmineID: #135963]
		20201029@Parsons: Add ExtraPT in Number Game Win Loss Report [RedmineID: #142969]
		20210113@Parsons: Saba.club Integrate Slot Game [#147977]
		20210412@Sophia: Change Range of AE Casino [Redmine :#152141]
		20210514@Danny: Integrate Vgaming [#154080] 


	Param's Explanation:

	EXEC GEN_rptBetting '2018-02-01', '2018-02-28'
*/
BEGIN
	SET NOCOUNT ON

	IF @date2 IS NULL
		SET @date2 = @date
	
	DECLARE @BettypeProductMapping TABLE (Bettype INT, ProductID INT)
	INSERT INTO @BettypeProductMapping (Bettype, ProductID)
	SELECT Bettype, ProductId
	FROM bodb_licensee.dbo.LA_f_BettypeProductMapping(0, @ProductCodes)

	DECLARE @tmpDate DATETIME
	SELECT	@tmpDate = @date

	WHILE @tmpDate <= @date2
	BEGIN
		IF @ProductCodes = ''
		BEGIN
			DELETE dbo.rpt_Betting WHERE rptDate = @tmpDate

			INSERT INTO dbo.rpt_Betting
			(
				rptDate,SiteID,Bettype,LeagueID,CurrencyID,Status,IsLive,BetCount,MemberCount,Turnover,WinLoss,WinLossA,WinLossM,WinLossS,WinLossE
				,CommissionP,CommissionA,CommissionM,CommissionS,CommissionE,WinLossVirtual,CommissionSVirtual,CustomerCategory,BuyBackAmount
				,WinPrizeAmount,CashOutAmount,oddsspread,TicketType,ExtraAmount
			)
			SELECT
				b.winlostdate				AS rptDate
				,ISNULL(s.SiteID, -1)		AS siteid
				,b.bettype
				,CASE 
					WHEN b.bettype = 9		THEN -9
					WHEN b.bettype = 2799	THEN -2799
					WHEN b.bettype = 10		THEN ISNULL(o.leagueid, -1)
					WHEN b.bettype IN (1231,1232,1233,1237,1238) THEN ISNULL(r.leagueid, r14.leagueid)
					ELSE ISNULL(m.leagueid, -1) END AS leagueid
				,b.currency					AS [CurrencyID]
				,b.statusid					AS [Status]
				,ISNULL(b.liveindicator, 0)	AS [IsLive]
				,COUNT(1)					AS Betcount
				,COUNT(DISTINCT b.custid)	AS MemberCount
				,SUM(stake)					AS Turnover
				,SUM(winlost-actual_stake)	AS winloss
				,SUM(awinlost)				AS winlossA
				,SUM(mwinlost)				AS winlossM
				,SUM(swinlost)				AS winlossS
				,SUM(-
					CASE
						-- Jackpot
						WHEN b.bettype IN (2198, 2398, 2998, 4297, 1698, 3898) THEN
							CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE ISNULL(b.betid/CONVERT(DECIMAL(19,8), 100000000), 0) END
						WHEN b.bettype IN (2199, 2399, 2999, 4298, 1699, 3899) THEN 0
						ELSE CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE b.winlost - b.actual_stake END
					END * ISNULL(b.epositiontaking, 0)) AS WinLossE
				,SUM(playercomm)			AS commissionP
				,SUM(comm)					AS commissionA
				,SUM(acomm)					AS commissionM
				,SUM(scomm)					AS commissionS
				,SUM(-
					CASE 
						WHEN b.bettype IN (2198, 2398, 2998, 2199, 2399, 2999, 4297, 4298, 1698, 1699, 3898, 3899) THEN 0
						ELSE 
							CASE 
								WHEN b.tpositiontaking = 1 THEN 0 
								ELSE b.scomm / (1 - b.tpositiontaking)
							END
					END * ISNULL(b.epositiontaking, 0))	AS CommissionE
				,SUM((winlost-actual_stake)*virtualrate) AS WinLossVirtual
				,SUM(scomm*virtualrate)		AS CommissionSVirtual
				,b.customercategory
				,SUM(CASE
						WHEN b.bettype IN (901, 911) THEN winlost
						WHEN b.bettype = 18000 THEN ISNULL(CashInAmount, 0)
						ELSE 0 END)				AS BuyBackAmount
				,SUM(ISNULL(WinPrizeAmount,0))	AS WinPrizeAmount
				,SUM(ISNULL(CashOutAmount,0))	AS CashOutAmount
				,SUM(ISNULL(oddsspread,0))		AS oddsspread
				,b.TicketType
				,SUM(CASE
						WHEN b.bettype = 18000 OR b.bettype BETWEEN 1401 AND 1499 THEN CONVERT(MONEY, ISNULL(b.ExtraInfo, 0))
						WHEN b.bettype BETWEEN 81 AND 120 OR b.bettype BETWEEN 8101 AND 8120 THEN b.stake * (1 - b.tpositiontaking) -- House Turnover In NG WL
						WHEN b.bettype BETWEEN 5001 AND 5099 THEN b.actual_stake -- Net Turnover In Indo 4D
						ELSE 0 END)				AS ExtraAmount
			FROM dbo.bettrans b WITH (NOLOCK)
				LEFT JOIN bodb02.dbo.customer ag WITH (NOLOCK) ON b.recommend = ag.custid AND ag.roleid = 2
				LEFT JOIN bodb_Licensee.dbo.view_site_list s WITH (NOLOCK) ON s.SiteName = ag.site
				LEFT JOIN dbo.match m WITH (NOLOCK) ON b.matchid = m.matchid
				LEFT JOIN dbo.outright o WITH (NOLOCK) ON b.matchid = o.matchid
				LEFT JOIN bodb02.dbo.VSRaceInfo r WITH (NOLOCK) ON b.matchid = r.EventID AND b.bettype IN(1231,1232,1233,1237,1238)
				LEFT JOIN bodb02.dbo.VSRaceInfo14 r14 WITH (NOLOCK) ON b.matchid = r14.EventID AND b.bettype IN(1231,1232,1233,1237,1238)
			WHERE b.winlostdate = @tmpDate
				AND isBA = 0
			GROUP BY
				b.winlostdate
				,ISNULL(s.SiteID, -1)
				,b.bettype
				,CASE 
					WHEN b.bettype = 9		THEN -9
					WHEN b.bettype = 2799	THEN -2799
					WHEN b.bettype = 10		THEN ISNULL(o.leagueid, -1)
					WHEN b.bettype IN (1231,1232,1233,1237,1238) THEN ISNULL(r.leagueid, r14.leagueid)
					ELSE ISNULL(m.leagueid, -1) END
				,b.currency
				,b.statusid
				,ISNULL(b.liveindicator, 0)
				,b.customercategory
				,b.TicketType
		END
		ELSE
		BEGIN
			DELETE dbo.rpt_Betting WHERE rptDate = @tmpDate AND bettype IN (SELECT bettype FROM @BettypeProductMapping)

			INSERT INTO dbo.rpt_Betting
			(
				rptDate,SiteID,Bettype,LeagueID,CurrencyID,Status,IsLive,BetCount,MemberCount,Turnover,WinLoss,WinLossA,WinLossM,WinLossS,WinLossE
				,CommissionP,CommissionA,CommissionM,CommissionS,CommissionE,WinLossVirtual,CommissionSVirtual,CustomerCategory,BuyBackAmount
				,WinPrizeAmount,CashOutAmount,oddsspread,TicketType,ExtraAmount
			)
			SELECT
				b.winlostdate				AS rptDate
				,ISNULL(s.SiteID, -1)		AS siteid
				,b.bettype
				,CASE 
					WHEN b.bettype = 9		THEN -9
					WHEN b.bettype = 2799	THEN -2799
					WHEN b.bettype = 10		THEN ISNULL(o.leagueid, -1)
					WHEN b.bettype IN (1231,1232,1233,1237,1238) THEN ISNULL(r.leagueid, r14.leagueid)
					ELSE ISNULL(m.leagueid, -1) END AS leagueid
				,b.currency					AS [CurrencyID]
				,b.statusid					AS [Status]
				,ISNULL(b.liveindicator, 0)	AS [IsLive]
				,COUNT(1)					AS Betcount
				,COUNT(DISTINCT b.custid)	AS MemberCount
				,SUM(stake)					AS Turnover
				,SUM(winlost-actual_stake)	AS winloss
				,SUM(awinlost)				AS winlossA
				,SUM(mwinlost)				AS winlossM
				,SUM(swinlost)				AS winlossS
				,SUM(-
					CASE
						-- Jackpot
						WHEN b.bettype IN (2198, 2398, 2998, 4297, 1698, 3898) THEN
							CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE ISNULL(b.betid/CONVERT(DECIMAL(19,8), 100000000), 0) END
						WHEN b.bettype IN (2199, 2399, 2999, 4298, 1699, 3899) THEN 0
						ELSE CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE b.winlost - b.actual_stake END
					END * ISNULL(b.epositiontaking, 0))	AS WinLossE
				,SUM(playercomm)			AS commissionP
				,SUM(comm)					AS commissionA
				,SUM(acomm)					AS commissionM
				,SUM(scomm)					AS commissionS
				,SUM(-
					CASE 
						WHEN b.bettype IN (2198, 2398, 2998, 2199, 2399, 2999, 4297, 4298, 1698, 1699, 3898, 3899) THEN 0
						ELSE 
							CASE 
								WHEN b.tpositiontaking = 1 THEN 0 
								ELSE b.scomm / (1 - b.tpositiontaking)
							END
					END * ISNULL(b.epositiontaking, 0))	 AS CommissionE
				,SUM((winlost-actual_stake)*virtualrate) AS WinLossVirtual
				,SUM(scomm*virtualrate)		AS CommissionSVirtual
				,b.customercategory
				,SUM(CASE
						WHEN b.bettype IN (901, 911) THEN winlost
						WHEN b.bettype = 18000 THEN ISNULL(CashInAmount, 0)
						ELSE 0 END)				AS BuyBackAmount
				,SUM(ISNULL(WinPrizeAmount,0))	AS WinPrizeAmount
				,SUM(ISNULL(CashOutAmount,0))	AS CashOutAmount
				,SUM(ISNULL(oddsspread,0))		AS oddsspread
				,b.TicketType
				,SUM(CASE
						WHEN b.bettype = 18000 OR b.bettype BETWEEN 1401 AND 1499 THEN CONVERT(MONEY, ISNULL(b.ExtraInfo, 0))
						WHEN b.bettype BETWEEN 81 AND 120 OR b.bettype BETWEEN 8101 AND 8120 THEN b.stake * (1 - b.tpositiontaking) -- House Turnover In NG WL
						WHEN b.bettype BETWEEN 5001 AND 5099 THEN b.actual_stake -- Net Turnover In Indo 4D
						ELSE 0 END)				AS ExtraAmount
			FROM dbo.bettrans b WITH (NOLOCK)
				LEFT JOIN bodb02.dbo.customer ag WITH (NOLOCK) ON b.recommend = ag.custid AND ag.roleid = 2
				LEFT JOIN bodb_Licensee.dbo.view_site_list s WITH (NOLOCK) ON s.SiteName = ag.site
				LEFT JOIN dbo.match m WITH (NOLOCK) ON b.matchid = m.matchid
				LEFT JOIN dbo.outright o WITH (NOLOCK) ON b.matchid = o.matchid
				LEFT JOIN bodb02.dbo.VSRaceInfo r WITH (NOLOCK) ON b.matchid = r.EventID AND b.bettype IN(1231,1232,1233,1237,1238)
				LEFT JOIN bodb02.dbo.VSRaceInfo14 r14 WITH (NOLOCK) ON b.matchid = r14.EventID AND b.bettype IN(1231,1232,1233,1237,1238)
			WHERE b.winlostdate = @tmpDate
				AND isBA = 0
				AND bettype IN (SELECT bettype FROM @BettypeProductMapping)
			GROUP BY
				b.winlostdate
				,ISNULL(s.SiteID, -1)
				,b.bettype
				,CASE 
					WHEN b.bettype = 9		THEN -9
					WHEN b.bettype = 2799	THEN -2799
					WHEN b.bettype = 10		THEN ISNULL(o.leagueid, -1)
					WHEN b.bettype IN (1231,1232,1233,1237,1238) THEN ISNULL(r.leagueid, r14.leagueid)
					ELSE ISNULL(m.leagueid, -1) END
				,b.currency
				,b.statusid
				,ISNULL(b.liveindicator, 0)
				,b.customercategory
				,b.TicketType
		END

		SELECT @tmpDate = DATEADD(DAY, 1, @tmpDate)
	END
END
GO