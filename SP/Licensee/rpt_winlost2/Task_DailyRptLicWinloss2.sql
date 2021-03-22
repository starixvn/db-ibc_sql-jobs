/*<info serverAlias="DBLIC-bodb_LicenseeReport" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Task_DailyRptLicWinloss2]
	@WinLostDate DATETIME
AS

/*
	Created by:[Henry]
	Date: 2011-09-20
	Task: daily summary for Licensee
	DB: DBLIC.bodb_LicenseeReport
	Revisions:
		- 20111208@Jim: Change bettype condition (bettype<=19000=>bettype<999)
		- 20120116@Henry: Add column IsMobile and Sum the bets that from mobile
		- 20120803@Henry: fix the commission formula
		- 20120814@Henry: sum Livecasino, games, virtual sport
		- 20120816@Henry: include betfrom "l" for smartphone
		- 20120109@Henry: sum wap & smartphone betfrom
		- 20130903@Jim: support Virtual Horse Racing
		- 20131014@Jim: support Virtual Tennis
		- 20131128@Jim: revert code to Group by All Virtual Sport into sporttypeID=180
		- 20140310@Jim: offer KENO 
		- 20140820@Jim: support to add more value bet BetEffective (RedmineID : #20518)
		- 20150618@Patrick: #36263: Fix super balance issue for: AGC, GD & VG
		- 20150630@Jim: add MicroGaming 
		- 20150702@Patrick: Support BetTrade
		- 20150824@Patrick: Not category BA's bettrade ticket
		- 20150909@Patrick: Changes the way generate data from bettrans instead bettrans14
		- 20151113@Jim: separate Microgaming into 2 products
		- 20151231@Patrick: Add more field buybackamt & BABuyBackAmt
		- 20160105@Bobby: #49196 - Implement OneRnG product
		- 20160301@Victor: Redefine betfrom value [Redmine: #50939]
		- 20160415@Victor: Support Voidbridge product [Redmine: #55057]
		- 20160721@Jim: Add product Allbet [Redmine: #59624]
		- 20160726@Francis: Move SP to bodb_LicenseeReport - [Redmine: #60449]
		- 20160727@Jim: LRF - Commercial terms changed for Bet Trade [Redmine: #61342]
		- 20160913@Jim: LRF - Implement Colossus Bets [Redmine: #63785]
		- 20161115@Jim: LRF - Integrate new product Fishing World [RedmineID : #66737]
		- 20170322@Paul: Implement Cash Out [RedmineID :#71727]
		- 20170712@Harper: Implement new Product Betradar VS [Redmine: #78241]
		- 20170802@Sophia: Add new betfrom [redmine: #80687]
		- 20170619@Harper: LRF - Integrate Lottery [RedmineID: #79997]
		- 20170814@Harper: One RNG - Offer New Tablet Games [RedmineID: #78424]
		- 20171225@Sophia: Integrate Exchange Products [Redmine: #86640]
		- 20180212@Harper: Remove LC from product list [Redmine: #85965]
		- 20180409@Joseph: Implement new sports for VS2: BasketBall - Virual Soccer World Cup [Redmine: #90881]
		- 20180418@Joseph: Integrate new product PP [Redmine: #92318]
		- 20181113@Joseph: New betfrom Mobile App (o) [RedmineID: #104587]
		- 20181113@Bruce: New Games Sicbo & Bidme - Service to pull deposit data for Bidme Tips [#102624]
		- 20181211@Joseph: New betfrom Mobile China View (c) [RedmineID: #106088]
		- 20181204@Bruce: Implement Happy 5 [RedmineID: #105723]
		- 20190306@Amande: Implement PP Promotion Prize [RedmineID: #109471]
		- 20190321@Joseph: Remove Microgaming LC + RNG [RedmineID: #107704]
		- 20190710@Amanda: Integrate Card Club [RedmineID: #115449]
		- 20190903@Amanda: Add betfrom Deep Link(t) [RedmineID: #119010]
		- 20190910@Amanda: Add bet types which support Half Won/ Half Lose [RedmineID: #118300]
		- 20190923@Amanda: Change the way to handle Half Won/ Half Lose bet types [RedmineID: #119879]
		- 20191010@Percy: Replace LicenseeBATransaction to LicenseeBATransaction_bk [RedmineID: #103656]
		- 20191022@Amanda: Integrate NPH Promotion [RedmineID: #120333]
		- 20191122@Amanda: Integrate PP Tournament Prize [RedmineID: #123804]
		- 20191219@Amanda: Add betfrom v [RedmineID: #125553]
		- 20191226@Vickie: Add platform 0 [RedmineID: #125824]
		- 20191212@Vickie: Integrate SpadeGaming [RedmineID: #124103]
		- 20200108@Vickie: Integrate Virtual Games [RedmineID: #124911]
		- 20200228@Vickie: Integrate 3 new betffrom [Redmine: #129253]
		- 20200407@Vickie: Integrate Table Games [RedmineID: #131447]
		- 20200416@Vickie: Add new product Indo 4D [RedmineID: #130859]
		- 20200423@Hogan: Add new product Sexy Gaming [RedmineID: #132829]
		- 20200423@Vickie: Integrate Saba Club [RedmineID: #132702]
		- 20200622@Hogan: Integrate 3 new betfrom 4, 5, 6 [Redmine: #136107]
		- 20200715@Kos: Extend Lottery bettype range [RedmineID: #137625]
		- 20200721@Hogan: Add 7 games for Jackpot and 2 bettype for Contribution (4297) and Jackpot Prize (4298) [RedmineID: #137290]
		- 20200803@Kos: Support Saba Loyalty [RedmineID: #138493]
		- 20200918@Hogan: Integrate Joker [RedmineID: #141408]
		- 20201013@Hogan: Integrate SA Gaming [RedmineID: #128493]
		- 20201020@Hogan: Integrate Arcadia Gaming Bonus [RedmineID: #143648]
		- 20201021@Louis: Integrate PG Soft [RedmineID: #139182]
		- 20201022@Louis: Licensee Spread Setting [RedmineID: #142532]	
		- 20201104@Hogan: Add new sport Saba.club Free Bets [RedmineID: #142369]
		- 20201217@Hogan: Add bettype of Saba.club Free Bets [RedmineID: #142369] 
		- 20201231@Louis: Integrate Happy 5 Linked Games [RedmineID: #147446]
		- 20201231@Hogan: Integrate GDG [RedmineID: #147267]
		- 20210120@Mark: Integrate new betfrom 7 [Redmine: #149108]
		- 20210202@Hogan: Integrate Four Guardians [RedmineID: #148100]
		- 20210203@Louis: Saba Red Envelope [RedmineID: #149923]
		- 20210305@Mark: Integrate new betfrom _, @, %(Mobile Euro) [Redmine: #151019]
		- 20210305@Hogan: Integrate Sport Lottery [RedmineID: #150872]
		- 20210315@Hogan: Integrate Cricket AIO [RedmineID: #150386]
		- 20210322@Hogan: Integrate AE Casino Lucky Draw [RedmineID: #151984]

	EXEC Task_DailyRptLicWinloss2 '2017-04-07'
*/

BEGIN
	SET NOCOUNT ON
	
	DELETE FROM dbo.rptLicWinloss2 WITH (ROWLOCK) WHERE winlostdate = @WinLostDate

	DECLARE @HWHLCutDate SMALLDATETIME = '2019-10-01' -- half won/ half lose cut date
	
	--Member Level
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
		,[statusID]
		,[isBA]
		,[isMobile]
		,[betfrom]
		,[BuyBackAmt]
		,[BABuyBackAmt] 
		)
	SELECT
		@winlostdate
		,customer.username
		,customer.username2
		,customer.custid
		,1
		,customer.recommend
		,customer.mrecommend
		,customer.srecommend
		,SUM(CASE
				WHEN bettrans.liveawayscore = 0 AND bettrans.bettype IN (33, 43) THEN ABS(bettrans.stake/2)
				ELSE ABS(bettrans.stake)
			END) AS TurnOver
		,SUM(winlost - actual_stake) winlost
		,CASE
			WHEN bettrans.statusID IN (112,113) THEN SUM(CASE
															WHEN (bettrans.bettype IN (4300, 4299, 4298, 4297, 3007, 1906, 1698, 1699, 3150)
																OR (bettrans.bettype BETWEEN 1611 AND 1697 AND bettrans.matchid = 150)) THEN 0
															ELSE ABS(winlost - actual_stake)
														END)  -- exclude PP Prize, SAG Tip ticket from BetEffective
			ELSE 0
		END AS BetEffective
		,SUM(awinlost) awinlost
		,SUM(mwinlost) mwinlost
		,SUM(ISNULL(swinlost,0)) swinlost
		,SUM(playercomm) playercomm  
		,SUM(comm) comm
		,SUM(acomm) acomm
		,SUM(ISNULL(scomm,0)) scomm
		,SUM((winlost - actual_stake) * virtualrate) AS WinlostVirtual
		,SUM((comm)*virtualrate) AS CommVirtual
		,COUNT(bettrans.transid) BetCount
		,bettrans.currency
		,CASE
			WHEN bettype IN (71,72) THEN 251 --casino
			WHEN bettype = 1000 THEN 253 --games
			WHEN bettype BETWEEN 81 AND 120 THEN 161 --Number Game
			WHEN bettype BETWEEN 8101 AND 8120 THEN 164 --Number Game - Happy 5
			WHEN bettype BETWEEN 3601 AND 3610 THEN 168 --Happy 5 Linked Games
			WHEN (bettype BETWEEN 1201 AND 1299 ) THEN 180  --Virtual Sport  
			WHEN bettype BETWEEN 51 AND 69 THEN 201
			WHEN bettype IN (31,32,33,41,42,43) THEN 151
			WHEN bettype BETWEEN 1501  AND 1599 THEN 202 -- Keno
			WHEN bettype BETWEEN 1800 AND 1899 THEN 250 -- AGC
			WHEN bettype BETWEEN 1700 AND 1799 THEN 255 -- GD
			WHEN bettype = 1900 THEN 249 -- VG  
			WHEN bettype BETWEEN 2101 AND 2199 THEN 208
			WHEN bettype BETWEEN 2201 AND 2299 THEN 209
			WHEN (bettype BETWEEN 2301 AND 2399 OR bettype BETWEEN 2901 AND 2999) THEN 210
			WHEN bettype BETWEEN 4001 AND 4100 THEN 212 -- VB
			WHEN bettype BETWEEN 2401 AND 2499 THEN 211 -- AB
			WHEN bettype BETWEEN 18000 AND 18006 THEN 204 --CB
			WHEN bettype BETWEEN 1011 AND 1020 THEN 219
			WHEN bettype BETWEEN 2701 AND 2799 THEN 190 --Betradar Virtual Sport
			WHEN bettype BETWEEN 2800 AND 2829 THEN 193 --Virtual Basketball
			WHEN bettype BETWEEN 1021 AND 1099 THEN 220 -- Lottery
			WHEN bettype BETWEEN 8000 AND 8099 THEN 221 -- Exchange
			WHEN bettype BETWEEN 4101 AND 4300 THEN 248 -- PP
			WHEN bettype BETWEEN 1901 AND 1999 THEN 165 -- CC
			WHEN bettype BETWEEN 4301 AND 4600 THEN 247 -- SG
			WHEN bettype BETWEEN 4601 AND 4900 THEN 245 -- VRG
			WHEN bettype BETWEEN 4901 AND 5000 THEN 222 -- TG
			WHEN bettype BETWEEN 5001 AND 5099 THEN 223 -- I4D
			WHEN bettype BETWEEN 3101 AND 3150 THEN 243 -- SXG
			WHEN (bettype BETWEEN 1611 AND 1699 AND matchid <> 150) THEN 200 -- SBC
			WHEN (bettype BETWEEN 1611 AND 1699 AND matchid = 150) THEN 150 -- SBC FreeBets
			WHEN bettype BETWEEN 6401 AND 6700 THEN 234 -- JK
			WHEN bettype BETWEEN 3001 AND 3099 THEN 244 -- SAG
			WHEN bettype BETWEEN 6001 AND 6300 THEN 232 -- PGS
			WHEN bettype BETWEEN 5701 AND 5799 THEN 236 -- GDG
			WHEN bettype BETWEEN 3611 AND 3620 THEN 169 -- SLT
			WHEN bettype IN (17000, 17003, 17004) THEN 246 -- NPHP
			ELSE 0
		END AS sporttype
		-- 1706: bidme tip, 4300 - PP Promotion Prize
		,CASE
			WHEN (bettype IN (71, 72, 1000, 901, 902, 903, 904, 911, 912, 913, 914, 1706, 4300, 17000, 17003, 17004, 4299, 4298, 4297, 3007, 1906, 999, 1698, 1699, 3150)
				OR (bettype BETWEEN 1611 AND 1697 AND matchid = 150)) THEN bettype
			ELSE 0
		END bettype
		--114: half win, 115: half lose
		,CASE
			WHEN bettrans.winlostdate >= @HWHLCutDate
				AND bettrans.statusID IN (112,113)
				AND bettrans.modds IN (-0.25, 0.25)
				AND (bettrans.bettype < 999							-- Sportsbook
					OR bettrans.bettype BETWEEN 1301 AND 1399
					OR bettrans.bettype BETWEEN 9001 AND 9399
					OR bettrans.bettype BETWEEN 9400 AND 9699)
				AND bettrans.bettype NOT IN (29,38,911,912,913,914)  --- Parlay, betbuilder, Cashout
				AND bettrans.bettype NOT BETWEEN 81 AND 120
				THEN CASE WHEN bettrans.statusID = 112 THEN 114 ELSE 115 END
			WHEN bettrans.winlostdate < @HWHLCutDate
				AND bettrans.statusID IN (112, 113)
				AND bettrans.bettype IN(1,3,7,8,17,18,124,125,482,483,484,485)
				AND ABS(modds) = 0.25
				THEN CASE WHEN bettrans.statusID = 112 THEN 114 ELSE 115 END
			ELSE bettrans.statusID
		END AS statusID
		,CASE
			WHEN BA.transid IS NULL THEN 0
			WHEN BA.transid IS NOT NULL THEN 1
		END AS isBA
		,CASE
			WHEN bettrans.betfrom IN ('s','m','l','r','o','c','2','5','_','@','%') THEN 1
			ELSE 0
		END AS isMobile
		,CASE
			WHEN bettrans.betfrom IN ('a','d','e','u','s','m','l','g','r','x','y','z','o','c','t','v','0','1','2','3','4','5','6','7','_','@','%') THEN bettrans.betfrom
			ELSE ''
		END AS betfrom
		,SUM(CASE 
				WHEN bettrans.bettype IN (902, 912) AND transid2 = 0 THEN actual_stake
				WHEN bettrans.bettype IN (4297, 1698) THEN oddsspread
				ELSE 0 END) AS BuyBackAmt
		,SUM(CASE WHEN bettrans.bettype IN (902, 912) AND transid2 = 1 THEN actual_stake ELSE 0 END) AS BABuyBackAmt
	FROM
		bodb02.dbo.bettrans14 bettrans WITH (NOLOCK)
		INNER JOIN bodb02.dbo.customer WITH (NOLOCK) ON bettrans.custid = customer.custid
		LEFT JOIN bodb_licensee.dbo.LicenseeBATransaction_bk ba WITH (NOLOCK) ON bettrans.transid = ba.transid
	WHERE
		bettrans.winlostdate = @WinLostDate
		AND customer.srecommend IN (SELECT custid FROM bodb02.dbo.f_DepSuper_1('All'))
		AND bettrans.statusID IN (101, 111, 112, 113) --REJECT, DRAW, WON, LOSE
		AND bettrans.bettype <= 19999
	GROUP BY
		customer.custid
		,customer.recommend
		,customer.mrecommend
		,customer.srecommend
		,customer.username
		,customer.username2
		,bettrans.currency
		,bettrans.statusID
		,CASE
			WHEN bettype IN (71,72) THEN 251 --casino
			WHEN bettype = 1000 THEN 253 --games
			WHEN bettype BETWEEN 81 AND 120 THEN 161 --Number Game 
			WHEN bettype BETWEEN 8101 AND 8120 THEN 164 --Number Game - Happy 5
			WHEN bettype BETWEEN 3601 AND 3610 THEN 168 --Happy 5 Linked Games
			WHEN (bettype BETWEEN 1201 AND 1299 ) THEN 180  --Virtual Sport
			WHEN bettype BETWEEN 51 AND 69 THEN 201
			WHEN bettype IN (31,32,33,41,42,43) THEN 151
			WHEN bettype BETWEEN 1501  AND 1599 THEN 202
			WHEN bettype BETWEEN 1800 AND 1899 THEN 250 -- AGC
			WHEN bettype BETWEEN 1700 AND 1799 THEN 255 -- GD
			WHEN bettype = 1900 THEN 249 -- VG
			WHEN bettype BETWEEN 2101 AND 2199 THEN 208
			WHEN bettype BETWEEN 2201 AND 2299 THEN 209
			WHEN (bettype BETWEEN 2301 AND 2399 OR bettype BETWEEN 2901 AND 2999) THEN 210
			WHEN bettype BETWEEN 4001 AND 4100 THEN 212 -- VB 
			WHEN bettype BETWEEN 2401 AND 2499 THEN 211 -- AB
			WHEN bettype BETWEEN 18000 AND 18006 THEN 204
			WHEN bettype BETWEEN 1011  AND 1020 THEN 219
			WHEN bettype BETWEEN 2701 AND 2799 THEN 190 --Betradar Virtual Sport
			WHEN bettype BETWEEN 2800 AND 2829 THEN 193 --Virtual Basketball
			WHEN bettype BETWEEN 1021 AND 1099 THEN 220 -- Lottery
			WHEN bettype BETWEEN 8000 AND 8099 THEN 221 -- Exchange
			WHEN bettype BETWEEN 4101 AND 4300 THEN 248 -- PP
			WHEN bettype BETWEEN 1901 AND 1999 THEN 165 -- CC
			WHEN bettype BETWEEN 4301 AND 4600 THEN 247 -- SG
			WHEN bettype BETWEEN 4601 AND 4900 THEN 245 -- VRG
			WHEN bettype BETWEEN 4901 AND 5000 THEN 222 -- TG
			WHEN bettype BETWEEN 5001 AND 5099 THEN 223 -- I4D
			WHEN bettype BETWEEN 3101 AND 3150 THEN 243 -- SXG
			WHEN (bettype BETWEEN 1611 AND 1699 AND matchid <> 150) THEN 200 -- SBC
			WHEN (bettype BETWEEN 1611 AND 1699 AND matchid = 150) THEN 150 -- SBC FreeBets
			WHEN bettype BETWEEN 6401 AND 6700 THEN 234 -- JK
			WHEN bettype BETWEEN 3001 AND 3099 THEN 244 -- SAG
			WHEN bettype BETWEEN 6001 AND 6300 THEN 232 -- PGS
			WHEN bettype BETWEEN 5701 AND 5799 THEN 236 -- GDG
			WHEN bettype BETWEEN 3611 AND 3620 THEN 169 -- SLT
			WHEN bettype IN (17000, 17003, 17004) THEN 246 -- NPHP
			ELSE 0
		END
		,CASE
			WHEN (bettype IN (71, 72, 1000, 901, 902, 903, 904, 911, 912, 913, 914, 1706, 4300, 17000, 17003, 17004, 4299, 4298, 4297, 3007, 1906, 999, 1698, 1699, 3150)
				OR (bettype BETWEEN 1611 AND 1697 AND matchid = 150)) THEN bettype
			ELSE 0
		END
		,CASE
			WHEN bettrans.winlostdate >= @HWHLCutDate
				AND bettrans.statusID IN (112, 113)
				AND bettrans.modds IN (-0.25, 0.25)
				AND (bettrans.bettype < 999						-- Sportsbook
					OR bettrans.bettype BETWEEN 1301 AND 1399
					OR bettrans.bettype BETWEEN 9001 AND 9399
					OR bettrans.bettype BETWEEN 9400 AND 9699)
				AND bettrans.bettype NOT IN (29,38,911,912,913,914)  --- Parlay, betbuilder, Cashout
				AND bettrans.bettype NOT BETWEEN 81 AND 120
				THEN CASE WHEN bettrans.statusID = 112 THEN 114 ELSE 115 END
			WHEN bettrans.winlostdate < @HWHLCutDate
				AND bettrans.statusID IN (112, 113)
				AND bettrans.bettype IN (1,3,7,8,17,18,124,125,482,483,484,485)
				AND ABS(modds) = 0.25
				THEN CASE WHEN bettrans.statusID = 112 THEN 114 ELSE 115 END
			ELSE bettrans.statusID 
		END
		,CASE
			WHEN BA.transid IS NULL THEN 0
			WHEN BA.transid IS NOT NULL THEN 1
		END
		,CASE
			WHEN bettrans.betfrom IN ('s','m','l','r','o','c','2','5','_','@','%') THEN 1
			ELSE 0
		END
		,CASE
			WHEN bettrans.betfrom IN ('a','d','e','u','s','m','l','g','r','x','y','z','o','c','t','v','0','1','2','3','4','5','6','7','_','@','%') THEN bettrans.betfrom
			ELSE ''
		END

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
		,[statusID]
		,[isBA]
		,[isMobile]
		,[betfrom]
		,[BuyBackAmt]
		,[BABuyBackAmt]
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
		,b.statusID
		,b.isBA
		,b.isMobile
		,b.betfrom
		,SUM(BuyBackAmt)
		,SUM(BABuyBackAmt)
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
		,b.statusID
		,b.isBA
		,b.isMobile
		,b.betfrom

	-- Master Level (sum on member)
	INSERT INTO dbo.rptLicWinloss2
		(
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
		,[statusID]
		,[isBA]
		,[isMobile]
		,[betfrom]
		,[BuyBackAmt]
		,[BABuyBackAmt]
		)
	SELECT
		@winlostdate
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
		,b.statusID
		,b.isBA
		,b.isMobile
		,b.betfrom
		,SUM(BuyBackAmt)
		,SUM(BABuyBackAmt)
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
		,b.statusID
		,b.isBA
		,b.isMobile
		,b.betfrom

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
		,[statusID]
		,[isBA]
		,[isMobile]
		,[betfrom]
		,[BuyBackAmt]
		,[BABuyBackAmt]
		)
	SELECT
		@winlostdate
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
		,b.statusID
		,b.isBA
		,b.isMobile
		,b.betfrom
		,SUM(BuyBackAmt)
		,SUM(BABuyBackAmt)
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
		,b.statusID
		,b.isBA
		,b.isMobile
		,b.betfrom
END
GO
