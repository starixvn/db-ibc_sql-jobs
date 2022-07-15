/*<info serverAlias="DBLIC-bodb_LicenseeReport,DBBAL-bodb_LicenseeReport" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_DailyRptLicenseeWinloss_Bettrans]
	@WinLostDate SMALLDATETIME
AS

/*
	Created: 20220630@Sophia
	Task: Daily summary for RptLicenseeWinloss from bettrans
	DB: DBLIC.bodb_LicenseeReport
	Revisions:
		- 20220630@Sophia: initial SP [Redmine: #172604]		 
 
*/

BEGIN
	SET NOCOUNT ON

	DELETE FROM dbo.rptLicenseeWinloss WITH (ROWLOCK) WHERE winlostdate = @WinLostDate

	CREATE TABLE #SportBettype (ProductId TINYINT, BetType SMALLINT, EventType TINYINT, RefTable TINYINT, ProductPrefix VARCHAR(10), ProductId3rd TINYINT)

	--CREATE CLUSTERED INDEX IX_BetType ON #SportBettype (BetType)

	INSERT INTO #SportBettype (ProductID, BetType, EventType, RefTable, ProductPrefix, ProductId3rd)
	SELECT c.ProductID, c.BetType, c.EventType, c.RefTable, c.ProductPrefix, ISNULL(d.ProductId,0) AS ProductId3rd
	FROM bodb02.dbo.f_SportBettypeMatrix_Sel (1, 0, 0, 2, '', '', 1) c
	LEFT JOIN bodb_Licensee.dbo.Product3rd d ON c.ProductPrefix = d.ProductPrefix
	
	--- Note:  Eventtype = 1, 2, 3 thì join event table to get Sporttype, 
	---		   Eventtype = 5 Bitcoin have it own sporttype so no need to join Match3rd (up to now), treat same as Eventype = 0


 
	INSERT INTO dbo.rptLicWinloss2 
		(
			WinlostDate
           ,CustId
           ,StatusId
		   ,ProductId
           ,Sporttype
           ,Bettype
           ,LiveIndicator
           ,LeagueGroupId
           ,TicketType
           ,Betfrom
           ,IsBA
           ,Recommend		   
           ,APositiontaking
           ,BetCount
           ,Turnover
           ,ValidBetAmount
           ,Winlost
           ,AWinlost
           ,MWinlost
           ,SWinlost
           ,PComm
           ,AComm
           ,MComm
           ,SComm
           ,BetEffective
           ,Amount	
		)
	SELECT
		@WinLostDate
		,b.CustId
		,CASE
			WHEN b.winlostdate >= @HWHLCutDate
				AND b.StatusId IN (112, 113)
				AND b.modds IN (-0.25, 0.25)
				AND bt.ProductID = 0 			-- Sportsbook
				AND b.bettype NOT IN (29, 38)  	-- Parlay, betbuilder		 
				THEN CASE WHEN b.StatusId = 112 THEN 114 ELSE 115 END			
			ELSE b.StatusId
			END AS StatusId	 
		,bt.ProductId3rd AS ProductId			
		,Sporttype
		,b.Bettype
		,b.LiveIndicator
		,LeagueGroupId
		,CASE WHEN b.betdaqid = -2 THEN 1 ELSE 0 END AS TicketType   --- = 0: normal, = 1: Cashout
		,b.Betfrom
		,CASE
			WHEN BA.transid IS NULL THEN 0
			WHEN BA.transid IS NOT NULL THEN 1
			END AS isBA
		,b.Recommend
		,b.APositiontaking
		,COUNT(b.transid) AS BetCount
		,SUM(ABS(b.stake)) AS TurnOver
		,ValidBetAmount
		,SUM(b.winlost - b.actual_stake) AS Winlost
		,SUM(b.AWinlost) AS AWinlost
		,SUM(b.MWinlost) AS MWinlost
		,SUM(b.SWinlost) AS SWinlost
		,SUM(b.PlayerComm) AS PComm
		,SUM(b.Comm) AS AComm
		,SUM(b.AComm) AS MComm
		,SUM(b.SComm) AS SComm		
		,CASE
			WHEN b.StatusId IN (112, 113) THEN SUM(CASE  --- WILL GET ON BETTRANSRNG/LC
														WHEN (b.bettype IN (4300, 4299, 4298, 4297, 3007, 1906, 1698, 1699, 3150, 3898, 3899, 4599, 4600, 2499)
															OR (b.bettype BETWEEN 1611 AND 1697 AND b.matchid = 150)
															OR (b.bettype BETWEEN 3801 AND 3899 AND b.matchid = 173)) 
														THEN 0
														ELSE ABS(b.winlost - b.actual_stake)
													END) -- exclude Promotion Prize, Tip ticket from BetEffective
			ELSE 0
			END AS BetEffective
		,SUM(CASE
				WHEN (b.bettype IN (902, 912) --- Buy BackAmount of Old Cashout 
						OR (b.bettype = 29 AND b.oddsspread = 1)) --- Actual_Stake of God Of Fortune
				THEN b.actual_stake
				---WHEN b.bettype IN (4297, 1698, 3898, 4599) THEN b.oddsspread --- Turnover of ExtraPayout  --- WILL GET ON BETTRANSRNG/LC
				ELSE 0
			END) AS Amount	 ---BuyBackAmt of Old Cashout,  Actual_Stake of God Of Fortune, Turnover of ExtraPayout
		
		
		 
		

	/*	  
		,CASE
			WHEN b.bettype IN (71, 72) THEN 251 --casino
			WHEN b.bettype = 1000 THEN 253 --games
			WHEN b.bettype BETWEEN 81 AND 120 THEN 161 --Number Game
			WHEN b.bettype BETWEEN 8101 AND 8120 THEN 164 --Number Game - Happy 5
			WHEN b.bettype BETWEEN 3601 AND 3610 THEN 168 --Happy 5 Linked Games
			WHEN (b.bettype BETWEEN 1201 AND 1299 ) THEN 180  --Virtual Sport
			WHEN b.bettype BETWEEN 51 AND 69 THEN 201
			WHEN b.bettype IN (31,32,33,41,42,43) THEN 151
			WHEN b.bettype BETWEEN 1501  AND 1599 THEN 202 -- Keno
			WHEN b.bettype BETWEEN 1800 AND 1899 THEN 250 -- AGC
			WHEN b.bettype BETWEEN 1700 AND 1799 THEN 255 -- GD
			WHEN b.bettype = 1900 THEN 249 -- VG
			WHEN b.bettype BETWEEN 2101 AND 2199 THEN 208
			WHEN b.bettype BETWEEN 2201 AND 2299 THEN 209
			WHEN (b.bettype BETWEEN 2301 AND 2399 OR b.bettype BETWEEN 2901 AND 2999) THEN 210
			WHEN b.bettype BETWEEN 4001 AND 4100 OR b.bettype BETWEEN 5800 AND 5999 THEN 212 -- VB
			WHEN b.bettype BETWEEN 2401 AND 2499 THEN 211 -- AB
			WHEN b.bettype BETWEEN 18000 AND 18006 THEN 204 --CB
			WHEN b.bettype BETWEEN 1011 AND 1020 THEN 219
			WHEN b.bettype BETWEEN 2701 AND 2799 THEN 190 --Betradar Virtual Sport
			WHEN b.bettype BETWEEN 2800 AND 2829 THEN 193 --Virtual Basketball
			WHEN b.bettype BETWEEN 1021 AND 1099 THEN 220 -- Lottery
			WHEN b.bettype BETWEEN 8000 AND 8099 THEN 221 -- Exchange
			WHEN b.bettype BETWEEN 4101 AND 4300 OR b.bettype BETWEEN 6701 AND 7000 THEN 248 -- PP
			WHEN b.bettype BETWEEN 1901 AND 1999 THEN 165 -- CC
			WHEN b.bettype BETWEEN 4301 AND 4600 THEN 247 -- SG
			WHEN b.bettype BETWEEN 4601 AND 4900 THEN 245 -- VRG
			WHEN b.bettype BETWEEN 4901 AND 5000 THEN 222 -- TG
			WHEN b.bettype BETWEEN 5001 AND 5099 THEN 223 -- I4D
			WHEN b.bettype BETWEEN 3101 AND 3150 THEN 243 -- SXG
			WHEN (b.bettype BETWEEN 1611 AND 1699 AND b.matchid <> 150) THEN 200 -- SBC
			WHEN (b.bettype BETWEEN 1611 AND 1699 AND b.matchid = 150) THEN 150 -- SBC FreeBets
			WHEN b.bettype BETWEEN 6401 AND 6700 THEN 234 -- JK
			WHEN b.bettype BETWEEN 3001 AND 3099 THEN 244 -- SAG
			WHEN b.bettype BETWEEN 6001 AND 6300 THEN 232 -- PGS
			WHEN b.bettype BETWEEN 5701 AND 5799 THEN 236 -- GDG
			WHEN b.bettype BETWEEN 3611 AND 3620 THEN 169 -- SLT
			WHEN b.bettype BETWEEN 7001 AND 7300 THEN 238 -- HB
			WHEN b.bettype BETWEEN 3401 AND 3499 THEN 233 -- WM
			WHEN (b.bettype BETWEEN 3801 AND 3899 AND b.matchid <> 173) THEN 171 -- VGA
			WHEN (b.bettype BETWEEN 3801 AND 3899 AND b.matchid = 173) THEN 173 -- VGA FreeBets
			WHEN b.bettype BETWEEN 17000 AND 17030 THEN 246 -- Saba Promotion
			WHEN b.bettype BETWEEN 3501 AND 3599 THEN 239 -- BGG
			WHEN b.bettype BETWEEN 7301 AND 7600 THEN 167 -- CG
			WHEN b.bettype BETWEEN 7701 AND 7799 THEN 172 -- AP
			WHEN b.bettype BETWEEN 7801 AND 7899 THEN 174 -- APM
			WHEN b.bettype BETWEEN 5301 AND 5399 THEN 231 -- VS3
			WHEN b.bettype BETWEEN 7901 AND 7999 THEN 175 -- BTC
			WHEN b.bettype BETWEEN 8201 AND 8299 THEN 176 -- FGG
			ELSE 0
		END AS sporttype
		-- 1706: bidme tip, 4300 - PP Promotion Prize
		*/
		/*
		,CASE
			WHEN b.bettype IN (71, 72, 1000, 901, 902, 903, 904, 911, 912, 913, 914, 1706, 4300, 4299, 4298, 4297, 3007, 1906, 999, 1698, 1699, 3150, 3898, 3899, 4599, 4600, 2499)
				OR (b.bettype BETWEEN 1611 AND 1697 AND b.matchid = 150)
				OR (b.bettype BETWEEN 3801 AND 3899 AND b.matchid = 173)
				OR (b.bettype BETWEEN 17000 AND 17030) THEN b.bettype
			WHEN b.bettype = 29 AND b.oddsspread = 1 THEN -29		-- God Of Fortune
			ELSE 0
		END bettype*/
			
		
		 
	FROM
		bodb02.dbo.bettrans AS b WITH (NOLOCK)
		INNER JOIN bodb02.dbo.Dep_CustSuper AS s WITH (NOLOCK) ON b.srecommend = s.CustId 		---- Licensee Account only
		INNER JOIN #SportBettype AS bt ON bt.BetType = b.bettype 
		LEFT JOIN bodb_Licensee.dbo.LicenseeBATransaction_active AS BA WITH (NOLOCK) ON b.transid = BA.transid
		OUTER APPLY (
					SELECT 	m.Sporttype, ISNULL(l.LeagueGroupID, 0) AS LeagueGroupID
					FROM 	bodb02.dbo.match m WITH (NOLOCK) ON b.matchid = m.matchid AND bt.EventType = 1 
						LEFT JOIN (
									SELECT LeagueGroupID, leagueid
									FROM dbo.League l WITH(NOLOCK) WHERE l.LeagueGroupID IN (42,74,108,113,122)
									)l  ON m.leagueid = l.leagueid
					UNION ALL
					SELECT 	m.Sporttype, 0 AS LeagueGroupID
					FROM 	bodb02.dbo.outright m WITH (NOLOCK) ON b.matchid = m.matchid AND bt.EventType = 2
					
					UNION ALL
					SELECT 	m.Sporttype, 0 AS LeagueGroupID
					FROM 	bodb02.dbo.outright m WITH (NOLOCK) ON b.matchid = m.matchid AND bt.EventType = 3
					) m 
		
	WHERE
		b.winlostdate = @WinLostDate
		AND b.StatusId IN (111, 112, 113)  ---DRAW, WON, LOSE	
		AND bt.RefTable = 0 --- Get bettype from bettrans only
	GROUP BY
		 
	OPTION (MAXDOP 8)

	-- Agent Level (sum on member)
	INSERT INTO dbo.rptLicWinloss2 (
		[winlostdate]
		,[username]
		,[username2]
		,[custid]
		,[roleid]
		,[recommend]
		,[mrecommend]
		,[srecommend]
		,[turnover]
		,[winlost]
		,[BetEffective]
		,[awinlost]
		,[mwinlost]
		,[swinlost]
		,[playercomm]
		,[comm]
		,[acomm]
		,[scomm]
		,[winlostvirtual]
		,[commvirtual]
		,[BetCount]
		,[Currency]
		,[sporttype]
		,[bettype]
		,[StatusId]
		,[isBA]
		,[isMobile]
		,[betfrom]
		,[BuyBackAmt]
		,[BABuyBackAmt]
		,[apositiontaking]
		,TicketType
	)
	SELECT
		@WinLostDate
		,c.username
		,c.username2
		,c.custid
		,2 AS roleid
		,b.recommend
		,b.mrecommend
		,b.srecommend
		,SUM(turnover)
		,SUM(winlost)
		,SUM(BetEffective)
		,SUM(awinlost)
		,SUM(mwinlost)
		,SUM(swinlost)
		,SUM(playercomm)
		,SUM(comm)
		,SUM(acomm)
		,SUM(scomm)
		,SUM(winlostvirtual)
		,SUM(commvirtual)
		,SUM(BetCount)
		,b.currency
		,b.sporttype
		,b.bettype
		,b.StatusId
		,b.isBA
		,b.isMobile
		,b.betfrom
		,SUM(BuyBackAmt)
		,SUM(BABuyBackAmt)
		,b.apositiontaking
		,b.TicketType
	FROM
		dbo.rptLicWinloss2 AS b WITH (NOLOCK)
		INNER JOIN bodb02.dbo.customer AS c WITH (NOLOCK) ON b.recommend = c.custid
	WHERE
		b.winlostdate = @WinLostDate
		AND b.roleid = 1
		AND c.roleid = 2
	GROUP BY
		c.username
		,c.username2
		,c.custid
		,b.recommend
		,b.mrecommend
		,b.srecommend
		,b.currency
		,b.sporttype
		,b.bettype
		,b.StatusId
		,b.isBA
		,b.isMobile
		,b.betfrom
		,b.apositiontaking
		,b.TicketType

	-- Master Level (sum on member)
	INSERT INTO dbo.rptLicWinloss2 (
		[winlostdate]
		,[username]
		,[username2]
		,[custid]
		,[roleid]
		,[recommend]
		,[mrecommend]
		,[srecommend]
		,[turnover]
		,[winlost]
		,[BetEffective]
		,[awinlost]
		,[mwinlost]
		,[swinlost]
		,[playercomm]
		,[comm]
		,[acomm]
		,[scomm]
		,[winlostvirtual]
		,[commvirtual]
		,[BetCount]
		,[Currency]
		,[sporttype]
		,[bettype]
		,[StatusId]
		,[isBA]
		,[isMobile]
		,[betfrom]
		,[BuyBackAmt]
		,[BABuyBackAmt]
		,[apositiontaking]
		,TicketType
	)
	SELECT
		@WinLostDate
		,c.username
		,c.username2
		,c.custid
		,3 AS roleid
		,0
		,b.mrecommend
		,b.srecommend
		,SUM(turnover)
		,SUM(winlost)
		,SUM(BetEffective)
		,SUM(awinlost)
		,SUM(mwinlost)
		,SUM(swinlost)
		,SUM(playercomm)
		,SUM(comm)
		,SUM(acomm)
		,SUM(scomm)
		,SUM(winlostvirtual)
		,SUM(commvirtual)
		,SUM(BetCount)
		,b.currency
		,b.sporttype
		,b.bettype
		,b.StatusId
		,b.isBA
		,b.isMobile
		,b.betfrom
		,SUM(BuyBackAmt)
		,SUM(BABuyBackAmt)
		,b.apositiontaking
		,b.TicketType
	FROM
		dbo.rptLicWinloss2 AS b WITH (NOLOCK)
		INNER JOIN bodb02.dbo.customer AS c WITH (NOLOCK) ON b.mrecommend = c.custid
	WHERE
		b.winlostdate = @WinLostDate
		AND b.roleid = 1
		AND c.roleid = 3
	GROUP BY
		c.username
		,c.username2
		,c.custid
		,b.mrecommend
		,b.srecommend
		,b.currency
		,b.sporttype
		,b.bettype
		,b.StatusId
		,b.isBA
		,b.isMobile
		,b.betfrom
		,b.apositiontaking
		,b.TicketType

	-- Super Level (Sum on member)
	INSERT INTO dbo.rptLicWinloss2 (
		[winlostdate]
		,[username]
		,[username2]
		,[custid]
		,[roleid]
		,[recommend]
		,[mrecommend]
		,[srecommend]
		,[turnover]
		,[winlost]
		,[BetEffective]
		,[awinlost]
		,[mwinlost]
		,[swinlost]
		,[playercomm]
		,[comm]
		,[acomm]
		,[scomm]
		,[winlostvirtual]
		,[commvirtual]
		,[BetCount]
		,[Currency]
		,[sporttype]
		,[bettype]
		,[StatusId]
		,[isBA]
		,[isMobile]
		,[betfrom]
		,[BuyBackAmt]
		,[BABuyBackAmt]
		,[apositiontaking]
		,TicketType
	)
	SELECT
		@WinLostDate
		,c.username
		,c.username2
		,c.custid
		,4 AS roleid
		,0
		,0
		,b.srecommend
		,SUM(turnover)
		,SUM(winlost)
		,SUM(BetEffective)
		,SUM(awinlost)
		,SUM(mwinlost)
		,SUM(swinlost)
		,SUM(playercomm)
		,SUM(comm)
		,SUM(acomm)
		,SUM(scomm)
		,SUM(winlostvirtual)
		,SUM(commvirtual)
		,SUM(BetCount)
		,b.currency
		,b.sporttype
		,b.bettype
		,b.StatusId
		,b.isBA
		,b.isMobile
		,b.betfrom
		,SUM(BuyBackAmt)
		,SUM(BABuyBackAmt)
		,b.apositiontaking
		,b.TicketType
	FROM
		dbo.rptLicWinloss2 AS b WITH (NOLOCK)
		INNER JOIN bodb02.dbo.customer AS c WITH (NOLOCK) ON b.srecommend = c.custid
	WHERE
		b.winlostdate = @WinLostDate
		AND b.roleid = 1
		AND c.roleid = 4
	GROUP BY
		c.username
		,c.username2
		,c.custid
		,b.srecommend
		,b.currency
		,b.sporttype
		,b.bettype
		,b.StatusId
		,b.isBA
		,b.isMobile
		,b.betfrom
		,b.apositiontaking
		,b.TicketType
END
GO
