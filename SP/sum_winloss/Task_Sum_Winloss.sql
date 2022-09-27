/*<info serverAlias="DBTXN-bodb02" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Sum_Winloss]
	@winlostdate datetime
AS
/*
	Created by: Sol
	Date: 20200708
	Task: generate data for sum_winloss table
	DB: DBTXN/BODB02
	Revisions:
		- 20200708@Sol: Generate data for sum_winloss table - Redmine: [#136320]
		- 20200820@Sol: enhence performance when statistics are not updated yet - Redmine: [#136320]
		- 20200830@Sophia: Add PG Soft [redmine: #137767]
		- 20200909@Malcolm : Report Enhancement for Jackpot Product [RedmineID : #139575]
		- 20200918@Malcolm: Add Joker [redmine: #131609]
		- 20200915@Malcolm: Add WM Live Casino [redmine: #131584]
		- 20201201@Malcolm : Add Gold Diamond Gaming [Redmine : #144110]
		- 20201124@Malcolm: Add Virtual Sports 3 [redmine: #131375]
		- 20201210@Malcolm: Add Big Gaming And Happy 5 Linked Games [RedminedId : #146542]
		- 20201228@Malcolm: Add MaxGame [redmine: #147572]
		- 20210203@Malcolm: Add Saba Promotion [redmine: #149952]
		- 20210302@Malcolm: Add Sports Lottery [redmine: #147362]
		- 20210305@Malcolm: Add Cricket AIO[redmine: #148454]
		- 20210310@Malcolm: Add Pragmatic Live Casino [RedmineId : #133717]
		- 20210301@Malcolm: Add Habanero [RedmineId : #145457]		
		- 20210408@Malcolm: Change bettype range of AE Casino(Sexy gaming) [RedmineId : #151334]
		- 20210406@Malcolm: Add Creative Gaming [redmine: #146017]
		- 20210427@Malcolm: Add VGaming [RedmineId : #153938]
		- 20210518@Malcolm: Add AdvantPlay Mini [redmine: #155131]
		- 20210512@Malcolm: Add AdvantPlay Product [redmine: #154256]
		- 20210609@Malcolm: Add AE Sexy and change bettype range of Happy 5 Linked Games- [Redmine: #156239]
		- 20210617@Sol: changed how to calc net turn over - [RedmineId : #156653]
		- 20210810@Evan: Add Bitcoin product [Redmine: #159036]
		- 20211122@Percy: Enhance gross comm formula [RedmineID: #164479]
		- 20211214@Evan: Add New Games for PP [Redmine: #165393]
		- 20220106@Evan: Add SG Jackpot - [Redmine: #166685]
		- 20220124@Evan: Add Allbet Promotion - [Redmine: #166981]
		- 20220209@Evan: Expand Sportsbook bettype range - Cricket [Redmine: #166332]
		- 20220208@Evan: Add FGG product - [Redmine: #165685]	
		- 20220328@Evan: Expand bettype of Macau Games - [Redmine: #170383]
		- 20221002@Danny: Add New LeagueGroupID and TicketType columns [Redmine: #167177]	
		- 20220825@Eddie: Add SEAL Entertainment  [RedmineID: #176078]
*/
BEGIN

	SET NOCOUNT ON

	DECLARE @NetTO_CutOffDate SMALLDATETIME, @GrossComm_CutOffDate SMALLDATETIME, @SabaInfo_CutOffDate SMALLDATETIME

	SELECT  @NetTO_CutOffDate = CASE WHEN f.TypeName = 'NetTO' THEN f.CutoffDate ELSE @NetTO_CutOffDate END
			,@GrossComm_CutOffDate = CASE WHEN f.TypeName = 'GrossComm' THEN f.CutoffDate ELSE @NetTO_CutOffDate END
			,@SabaInfo_CutOffDate = CASE WHEN f.TypeName = 'SabaSport' THEN f.CutoffDate ELSE @SabaInfo_CutOffDate END
	FROM dbo.f_GetCutOffDate() f
	WHERE f.TypeName IN ('NetTO', 'GrossComm','SabaSport')

	---- get extra PT from table setting
	CREATE TABLE #__SuperExtraPT(productId INT, bettypePT INT, SuperId INT, ExtraPT MONEY, RefTable TINYINT, IsUsingOddsSpread BIT, IsContributionBettype BIT)
	CREATE CLUSTERED INDEX CIX_#__SuperExtraPT ON #__SuperExtraPT(SuperId, bettypePT)

	---- get bettype from bettransRnG/bettransLC
	CREATE TABLE #__Bettype (Bettype SMALLINT, SporttypeRef SMALLINT, BettypeRef SMALLINT, RefTable TINYINT, IsContributionBettype BIT)

	---- temp table to get data Net TO, Gross Comm from bettransRnG/bettransLC
	CREATE TABLE #__NetTO_GrossComm (custid INT, sporttype SMALLINT, bettype SMALLINT, TurnoverNoDraw MONEY, grosscomm MONEY, agrosscomm MONEY, mgrosscomm MONEY, sgrosscomm MONEY)

	---- temp table to store data from bettrans
	CREATE TABLE #sum_winloss_tmp(
		[winlostdate] [datetime] NULL,
		[custid] [int] NOT NULL,
		[roleid] [int] NULL,
		[recommend] [int] NOT NULL,
		[mrecommend] [int] NOT NULL,
		[srecommend] [int] NOT NULL,
		[turnover] [money] NULL,
		[winlost] [money] NULL,
		[awinlost] [money] NULL,
		[mwinlost] [money] NULL,
		[swinlost] [money] NULL,
		[playercomm] [money] NULL,
		[comm] [money] NULL,
		[acomm] [money] NULL,
		[scomm] [money] NULL,
		[BetCount] [int] NULL,
		[grosscomm] [money] NULL,
		[agrosscomm] [money] NULL,
		[mgrosscomm] [money] NULL,
		[sgrosscomm] [money] NULL,
		[sporttype] [smallint] NOT NULL,
		[bettype] [smallint] NULL,
		[netTurnover] [money] NULL,
		[anetTurnover] [money] NULL,
		[mnetTurnover] [money] NULL,
		[snetTurnover] [money] NULL,
		[TurnoverNoDraw] [money] NULL,
		[ExtraWinloss] [money] NULL,
		[ExtraComm] [money] NULL,
		[leagueGroupID] [smallint] NULL,
		[ticketType] [tinyint] NULL
	)

	;WITH rs AS 
	(
		SELECT DISTINCT b.bettype , b.srecommend
		FROM bettrans14 b WITH(NOLOCK) 
		WHERE 
			b.winlostdate = @winlostdate
			AND b.statusID NOT IN (0, 1, 102, 101, 103)
			AND b.bettype <= 19000
	)
	INSERT INTO #__SuperExtraPT (productId, bettypePT, SuperId, ExtraPT, RefTable, IsUsingOddsSpread, IsContributionBettype)
	SELECT tbl.ProductID, b.bettype , b.srecommend , T.ExtraPT, tbl.RefTable, tbl.IsUsingOddsSpread, CASE WHEN cont.Bettype IS NOT NULL THEN 1 ELSE 0 END AS IsContributionBettype
	FROM rs b 
		CROSS APPLY 
		(
			SELECT DISTINCT
				tbl.ProductID, tbl.RefTable, CASE WHEN tbl.RefTable IN (1,2) OR tbl.ProductID = 47 THEN 1 ELSE 0 END IsUsingOddsSpread
			FROM f_SportBettypeMatrix_Sel(0, 0, b.bettype, 2, '', '', 0) tbl
			WHERE b.bettype = tbl.bettype
		) tbl
		OUTER APPLY 
		(
			SELECT DISTINCT expt2.SuperId, expt2.ExtraPT
			FROM CustDB.dbo.Acc_GroupExtraPT2Setting expt2 WITH (NOLOCK)
			WHERE @winlostdate BETWEEN expt2.FromDate AND expt2.ToDate
					AND tbl.ProductID = expt2.ProductID
					AND b.srecommend = expt2.SuperId 
					AND ISNULL(expt2.SubProduct,'') = ''
					AND expt2.Sporttype = 0
		) t
		OUTER APPLY 
		(
			SELECT f.Bettype
			FROM dbo.f_BettypePrizeGroup() f
			WHERE f.BettypeGroup = 'Contribution'
				AND f.Bettype = b.bettype
		) cont

	---- gen all data
	INSERT INTO #sum_winloss_tmp
	(
		winlostdate, roleid, custid, recommend, mrecommend, srecommend, turnover, winlost, awinlost, mwinlost, swinlost,
		playercomm, comm, acomm, scomm, betcount, grosscomm, agrosscomm, mgrosscomm, sgrosscomm, Sporttype, bettype, netTurnover, anetTurnover, mnetTurnover, snetTurnover, TurnoverNoDraw, ExtraWinloss, ExtraComm,
		leagueGroupID, ticketType
	)
	SELECT
		@winlostdate
	   ,1
	   ,bettrans.custid
	   ,bettrans.recommend
	   ,bettrans.mrecommend
	   ,bettrans.srecommend
	   ,SUM(ABS(stake)) TurnOver
	   ,SUM(winlost - actual_stake) winlost
	   ,SUM(awinlost) awinlost
	   ,SUM(mwinlost) mwinlost
	   ,SUM(ISNULL(swinlost, 0)) swinlost
	   ,SUM(playercomm) playercomm
	   ,SUM(comm) comm
	   ,SUM(acomm) acomm
	   ,SUM(ISNULL(scomm, 0)) scomm
	   ,COUNT(1) BetCount
	   ,SUM(CASE
			WHEN tbl.RefTable IN (1, 2) AND winlostdate >= @GrossComm_CutOffDate THEN 0
			WHEN apositiontaking = 1 THEN 0
			ELSE ISNULL(comm / (1 - apositiontaking), 0)
		END) grosscomm
		,SUM(CASE
			WHEN tbl.RefTable IN (1, 2) AND winlostdate >= @GrossComm_CutOffDate THEN 0
			WHEN apositiontaking + mpositiontaking = 1 THEN 0
			ELSE ISNULL(acomm / (1 - apositiontaking - mpositiontaking), 0)
		END) agrosscomm
		,SUM(CASE
			WHEN tbl.RefTable IN (1, 2) AND winlostdate >= @GrossComm_CutOffDate THEN 0
			WHEN tpositiontaking = 1 THEN 0
			ELSE scomm / (1 - tpositiontaking)
		END) mgrosscomm
		,SUM(CASE
			WHEN tbl.RefTable IN (1, 2) AND winlostdate >= @GrossComm_CutOffDate THEN 0
			WHEN tpositiontaking = 1 THEN 0
			ELSE scomm / (1 - tpositiontaking)
		END) sgrosscomm
	   ,CASE WHEN ( 
					(l.LeagueGroupID IN (42,74,108,113) AND m.sporttype = 1 ) 
						OR (l.LeagueGroupID IN (122, 42) AND m.sporttype = 2 )
						OR (l.LeagueGroupID = 42 AND m.sporttype = 50)
				 ) AND betdaqid <> -2   AND winlostdate >= @SabaInfo_CutOffDate THEN m.sporttype
			WHEN bettype BETWEEN 81 AND 120 OR -- Number Game 
				bettype BETWEEN 8101 AND 8120 OR -- Happy 5 
				bettype BETWEEN 3601 AND 3610 THEN 161 -- Happy 5 Linked Games
			WHEN bettype BETWEEN 1201 AND 1299 THEN 180 -- Virtual Sport
			WHEN bettype BETWEEN 2700 AND 2899 THEN 190 -- Betradar Virtual Sport
			WHEN bettype IN (71, 72) THEN 251
			WHEN bettype BETWEEN 1501 AND 1599 THEN 202 -- Keno
			WHEN bettype BETWEEN 1021 AND 1099 THEN 220 -- Keno Lottery
			WHEN bettype BETWEEN 1700 AND 1799 THEN 255 -- Gold Deluxe
			WHEN bettype BETWEEN 1800 AND 1899 THEN 250 --- AG Casino 
			WHEN bettype = 1900 THEN 249 --- Vegas Games 
			WHEN bettype BETWEEN 18000 AND 18099 THEN 204 --- Colossus Bets
			WHEN bettype BETWEEN 2101 AND 2199 THEN 208
			WHEN bettype BETWEEN 2201 AND 2299 THEN 209
			WHEN bettype BETWEEN 2301 AND 2399 OR
				bettype BETWEEN 2901 AND 2999 THEN 210
			WHEN bettype BETWEEN 2401 AND 2499 THEN 211 --- Allbet
			WHEN bettype BETWEEN 4001 AND 4100 OR 
				bettype BETWEEN 5800 AND 5999 THEN 212 -- Voidbridge
			WHEN bettype BETWEEN 4101 AND 4300 OR 
				bettype BETWEEN 6701 AND 7000 THEN 248 -- Pragmatic
			WHEN bettype BETWEEN 2501 AND 2699 THEN 213 --NG2 -
			WHEN bettype BETWEEN 1011 AND 1020 THEN 219 --Fishing World -
			WHEN bettype BETWEEN 8000 AND 8099 THEN 221 -- Exchange
			WHEN bettype BETWEEN 1901 AND 1999 THEN 165 -- Card Club
			WHEN bettype BETWEEN 4301 AND 4600 THEN 247 -- Spadegaming
			WHEN bettype BETWEEN 4601 AND 4900 THEN 245 -- Virtual Games
			WHEN bettype BETWEEN 1611 AND 1699 THEN 200 -- Saba.Club
			WHEN bettype BETWEEN 3001 AND 3099 THEN 244 -- SA Gaming
			WHEN bettype BETWEEN 3101 AND 3150 THEN 243 -- AE Casino
			WHEN bettype BETWEEN 5001 AND 5099 THEN 223 -- Indo 4D
			WHEN bettype BETWEEN 4901 AND 5000 THEN 222 -- Table Games	
			WHEN bettype BETWEEN 3300 AND 3399 THEN 241 -- BBIN	
			WHEN bettype BETWEEN 3201 AND 3299 THEN 242 -- IBCBet Live Casino		
			WHEN bettype BETWEEN 5601 AND 5699 THEN 225 -- ION					
			WHEN bettype BETWEEN 5500 AND 5599 THEN 224 -- RNG War		
			WHEN bettype BETWEEN 6001 AND 6300 THEN 232 -- PG Soft
			WHEN bettype BETWEEN 6401 AND 6700 THEN 234-- Joker
			WHEN bettype BETWEEN 3401 AND 3499 THEN 233 -- WM
			WHEN bettype BETWEEN 5701 AND 5799 THEN 236 -- GDG
			WHEN bettype BETWEEN 5301 AND 5399 THEN 231 -- Virtual Sports 3
			WHEN bettype BETWEEN 3501 AND 3599 THEN 239 -- BG
			WHEN bettype BETWEEN 5401 AND 5499 THEN 237 -- MaxGame
			WHEN bettype BETWEEN 17000 AND 17030 THEN 246 -- Saba promotion
			WHEN bettype BETWEEN 3611 AND 3620 THEN 169 -- Sports Lottery
			WHEN bettype BETWEEN 3701 AND 3799 THEN 170 -- PP Live Casino
			WHEN bettype BETWEEN 7001 AND 7300 THEN 238 -- Habanero
			WHEN bettype BETWEEN 7301 AND 7600 THEN 167 -- Creative Gaming
			WHEN bettype BETWEEN 3801 AND 3899 THEN 171 -- VGaming 
			WHEN bettype BETWEEN 7801 AND 7899 THEN 174 -- AdvantPlay Mini
			WHEN bettype BETWEEN 7701 AND 7799 THEN 172 -- AdvantPlay Product
			WHEN bettype BETWEEN 7901 AND 7999 THEN 175 -- Bitcoin Product
			WHEN bettype BETWEEN 8201 AND 8299 THEN 176 -- FGG Product
			WHEN bettype BETWEEN 8900 AND 8999 THEN 156 -- SEAL Entertainment
			ELSE 0
		END sporttype
	   ,CASE
			WHEN bettype IN (71, 72, 3150, 4297, 4298, 4599, 4600, 2499) THEN bettype
			ELSE 0
		END bettype
	   ,0 AS netTurnover
	   ,SUM(ABS(stake * apositiontaking)) AS anetTurnover
	   ,SUM(ABS(stake * mpositiontaking)) AS mnetTurnover
	   ,SUM(ABS(stake * spositiontaking)) AS snetTurnover
	   ,SUM(CASE
			WHEN statusID IN (112, 113) AND
				modds IN (-0.25, 0.25)
				---- Sportsbook
				AND (bettype < 999 OR
				bettype BETWEEN 1301 AND 1399 OR--Sporting Solution
				bettype BETWEEN 9001 AND 9399 OR--E-Sports
				bettype BETWEEN 9400 AND 9998) AND --Cricket AIO
				bettype NOT IN (71, 72) AND
				bettype NOT BETWEEN 81 AND 120 THEN ABS(stake) / 2
			WHEN statusID = 111 AND
				(
				---- Sportsbook
				(bettype < 999 OR
				bettype BETWEEN 1301 AND 1399 OR--Sporting Solution
				bettype BETWEEN 9001 AND 9399 OR--E-Sports
				bettype BETWEEN 9400 AND 9998) AND--Cricket AIO
				bettype NOT IN (71, 72) AND
				bettype NOT BETWEEN 81 AND 120
				) THEN 0
			WHEN bettrans.winlostdate < @NetTO_CutOffDate AND 
				(
					bettype BETWEEN 2401 AND 2499   -- Allbet
					OR bettype BETWEEN 3001 AND 3099   -- SA Gaming
					OR bettype BETWEEN 3101 AND 3150   -- AE Casino
					OR bettype BETWEEN 3300 AND 3399   -- BBIN	
					OR bettype BETWEEN 3201 AND 3299   -- IBCBet Live Casino
					OR bettype BETWEEN 5601 AND 5699   -- ION 	 
					OR bettype BETWEEN 3401 AND 3499   -- WM
					OR bettype BETWEEN 5701 AND 5799   -- GDG
					OR bettype BETWEEN 3501 AND 3599   -- BG
					OR bettype BETWEEN 3701 AND 3799   -- PP Live Casino
				) THEN oddsspread
			WHEN tbl.productId = 47 THEN bettrans.oddsspread -- BBIN
			WHEN tbl.RefTable IN (1, 2) AND bettrans.winlostdate >= @GrossComm_CutOffDate THEN 0
			WHEN tbl.RefTable IN (1, 2) AND bettrans.winlostdate >= @NetTO_CutOffDate THEN
				CASE WHEN tbl.IsContributionBettype = 0 THEN bettrans.oddsspread ELSE 0	END
			ELSE ABS(stake)
		END) AS TurnoverNoDraw,
		-1 * SUM(
					CASE
						-- Jackpot
						WHEN bettrans.bettype IN (2198, 2398, 2998, 4297, 4599) THEN
							CASE WHEN bettrans.tpositiontaking = 1 THEN 0 ELSE ISNULL(bettrans.betid/CONVERT(DECIMAL(19,8), 100000000), 0) END
						WHEN bettrans.bettype IN (2199, 2399, 2999, 4298, 4600) THEN 0
						ELSE CASE WHEN bettrans.tpositiontaking = 1 THEN 0 ELSE bettrans.winlost - bettrans.actual_stake END
					END
					* CASE WHEN tbl.ExtraPT IS NOT NULL THEN tbl.ExtraPT
							ELSE ISNULL(bettrans.epositiontaking, 0)
						END
			) AS ExtraWinloss,
		-1 * SUM(CASE 
					/*IBCBet Live Casino*/
					WHEN bettrans.bettype BETWEEN 3201 AND 3299 THEN bettrans.scomm
					WHEN bettrans.bettype IN (2198, 2398, 2998, 2199, 2399, 2999, 4297, 4298, 4599, 4600) THEN 0
					ELSE 
						CASE 
							WHEN bettrans.tpositiontaking = 1 THEN 0 
							ELSE bettrans.scomm / (1 - bettrans.tpositiontaking)
						END * CASE WHEN tbl.ExtraPT IS NOT NULL THEN tbl.ExtraPT ELSE ISNULL(bettrans.epositiontaking, 0) END
				END
			) AS ExtraComm,
		  CASE WHEN ( 
						(l.LeagueGroupID IN (42,74,108,113) AND m.sporttype = 1 ) 
						OR (l.LeagueGroupID IN (122, 42) AND m.sporttype = 2 )
						OR (l.LeagueGroupID = 42 AND m.sporttype = 50)
					) AND betdaqid <> -2 AND winlostdate >= @SabaInfo_CutOffDate  THEN l.LeagueGroupID ELSE 0 END AS LeagueGroupID,
		  CASE WHEN bettrans.betdaqid = -2 AND winlostdate >= @SabaInfo_CutOffDate  THEN 1 ELSE 0 END ticketType
	FROM dbo.bettrans14 bettrans WITH (NOLOCK)
			INNER JOIN #__SuperExtraPT tbl 
				ON bettrans.srecommend = tbl.SuperId
					AND bettrans.bettype = tbl.bettypePT
	LEFT JOIN dbo.match14 m WITH(NOLOCK) ON bettrans.matchid = m.matchid
	LEFT JOIN (
				SELECT LeagueGroupID, leagueid
				FROM dbo.League l WITH(NOLOCK) WHERE l.LeagueGroupID IN (42,74,108,113,122)
			  )l  ON m.leagueid = l.leagueid
	WHERE 
		bettrans.winlostdate = @winlostdate
		AND bettrans.statusID NOT IN (0, 1, 102, 101, 103)
		AND bettrans.bettype <= 19000
	GROUP BY bettrans.custid
			,bettrans.recommend
			,bettrans.mrecommend
			,bettrans.srecommend
			,CASE
				WHEN ( 
					(l.LeagueGroupID IN (42,74,108,113) AND m.sporttype = 1 ) 
						OR (l.LeagueGroupID IN (122, 42) AND m.sporttype = 2 )
						OR (l.LeagueGroupID = 42 AND m.sporttype = 50)
				 ) AND betdaqid <> -2   AND winlostdate >= @SabaInfo_CutOffDate THEN m.sporttype
				 WHEN bettype BETWEEN 81 AND 120 OR -- Number Game 
					bettype BETWEEN 8101 AND 8120 OR -- Happy 5 
					bettype BETWEEN 3601 AND 3610 THEN 161 -- Happy 5 Linked Games
				 WHEN bettype BETWEEN 1201 AND 1299 THEN 180 -- Virtual Sports
				 WHEN bettype BETWEEN 2700 AND 2899 THEN 190 -- Betradar Virtual Sports
				 WHEN bettype IN (71, 72) THEN 251
				 WHEN bettype BETWEEN 1501 AND 1599 THEN 202 -- Keno
				 WHEN bettype BETWEEN 1021 AND 1099 THEN 220 -- Keno Lottery
				 WHEN bettype BETWEEN 1700 AND 1799 THEN 255 -- Gold Deluxe
				 WHEN bettype BETWEEN 1800 AND 1899 THEN 250 --- AG Casino 
				 WHEN bettype = 1900 THEN 249 --- Vegas Games 
				 WHEN bettype BETWEEN 18000 AND 18099 THEN 204 --- Colossus Bets
				 WHEN bettype BETWEEN 2101 AND 2199 THEN 208
				 WHEN bettype BETWEEN 2201 AND 2299 THEN 209
				 WHEN bettype BETWEEN 2301 AND 2399 OR
					 bettype BETWEEN 2901 AND 2999 THEN 210
				 WHEN bettype BETWEEN 2401 AND 2499 THEN 211 --- Allbet
				 WHEN bettype BETWEEN 4001 AND 4100 OR 
				 	bettype BETWEEN 5800 AND 5999 THEN 212 -- Voidbridge
				 WHEN bettype BETWEEN 4101 AND 4300 OR 
				 	bettype BETWEEN 6701 AND 7000 THEN 248 -- Pragmatic
				 WHEN bettype BETWEEN 2501 AND 2699 THEN 213 --NG2 -
				 WHEN bettype BETWEEN 1011 AND 1020 THEN 219 --Fishing World -
				 WHEN bettype BETWEEN 8000 AND 8099 THEN 221 -- Exchange
				 WHEN bettype BETWEEN 1901 AND 1999 THEN 165 -- Card Club
				 WHEN bettype BETWEEN 4301 AND 4600 THEN 247 -- Spadegaming
				 WHEN bettype BETWEEN 4601 AND 4900 THEN 245 -- Virtual Games
				 WHEN bettype BETWEEN 1611 AND 1699 THEN 200 -- Saba.Club
				 WHEN bettype BETWEEN 3001 AND 3099 THEN 244 -- SA Gaming
				 WHEN bettype BETWEEN 3101 AND 3150 THEN 243 -- AE Casino
				 WHEN bettype BETWEEN 5001 AND 5099 THEN 223 -- Indo 4D
				 WHEN bettype BETWEEN 4901 AND 5000 THEN 222 -- Table Games
				 WHEN bettype BETWEEN 3300 AND 3399 THEN 241 -- BBIN
				 WHEN bettype BETWEEN 3201 AND 3299 THEN 242 -- IBCBet Live Casino
				 WHEN bettype BETWEEN 5601 AND 5699 THEN 225 -- ION
				 WHEN bettype BETWEEN 5500 AND 5599 THEN 224 -- RNG War	
				 WHEN bettype BETWEEN 6001 AND 6300 THEN 232 -- PG Soft
				 WHEN bettype BETWEEN 6401 AND 6700 THEN 234-- Joker
				 WHEN bettype BETWEEN 3401 AND 3499 THEN 233 -- WM
				 WHEN bettype BETWEEN 5701 AND 5799 THEN 236 -- GDG
				 WHEN bettype BETWEEN 5301 AND 5399 THEN 231 -- Virtual Sports 3
				 WHEN bettype BETWEEN 3501 AND 3599 THEN 239 -- BG
				 WHEN bettype BETWEEN 5401 AND 5499 THEN 237 -- MaxGame
				 WHEN bettype BETWEEN 17000 AND 17030 THEN 246 -- Saba promotion
				 WHEN bettype BETWEEN 3611 AND 3620 THEN 169 -- Sports Lottery
				 WHEN bettype BETWEEN 3701 AND 3799 THEN 170 -- PP Live Casino
				 WHEN bettype BETWEEN 7001 AND 7300 THEN 238 -- Habanero
				 WHEN bettype BETWEEN 7301 AND 7600 THEN 167 -- Creative Gaming
				 WHEN bettype BETWEEN 3801 AND 3899 THEN 171 -- VGaming 
				 WHEN bettype BETWEEN 7801 AND 7899 THEN 174 -- AdvantPlay Mini
				 WHEN bettype BETWEEN 7701 AND 7799 THEN 172 -- AdvantPlay Product
				 WHEN bettype BETWEEN 7901 AND 7999 THEN 175 -- Bitcoin Product
				 WHEN bettype BETWEEN 8201 AND 8299 THEN 176 -- FGG Product
				 WHEN bettype BETWEEN 8900 AND 8999 THEN 156 -- SEAL Entertainment
				 ELSE 0
			 END
			,CASE
				WHEN bettype IN (71, 72, 3150, 4297, 4298, 4599, 4600, 2499) THEN bettype
				 ELSE 0
			 END,
			  CASE WHEN ( 
						(l.LeagueGroupID IN (42,74,108,113) AND m.sporttype = 1 ) 
						OR (l.LeagueGroupID IN (122, 42) AND m.sporttype = 2 )
						OR (l.LeagueGroupID = 42 AND m.sporttype = 50)
					) AND betdaqid <> -2 AND winlostdate >= @SabaInfo_CutOffDate  THEN l.LeagueGroupID ELSE 0 END,
			 CASE WHEN bettrans.betdaqid = -2 AND winlostdate >= @SabaInfo_CutOffDate THEN 1 ELSE 0 END 
	OPTION (optimize for (@winlostdate UNKNOWN))

	-- Update Gross Comm / Net Turnover
	IF @winlostdate >= @GrossComm_CutOffDate
	BEGIN
		INSERT INTO #__Bettype (Bettype, RefTable, IsContributionBettype, BettypeRef, SporttypeRef)
		SELECT DISTINCT bettypePT, RefTable, IsContributionBettype
			-- bettransRnG/bettransLC
			,CASE WHEN bettypePT IN (3150, 4297, 4298, 4599, 4600) THEN bettypePT ELSE 0 END AS BettypeRef
			,CASE
				 WHEN bettypePT BETWEEN 1800 AND 1899 THEN 250 -- AG Casino
				 WHEN bettypePT BETWEEN 2101 AND 2199 THEN 208 -- RNG Casino
				 WHEN bettypePT BETWEEN 2201 AND 2299 THEN 209 -- RNG Casino
				 WHEN bettypePT BETWEEN 2301 AND 2399
					OR bettypePT BETWEEN 2901 AND 2999 THEN 210 -- RNG Casino
				 WHEN bettypePT BETWEEN 2401 AND 2499 THEN 211 -- Allbet
				 WHEN bettypePT BETWEEN 4001 AND 4100 OR 
				 	bettypePT BETWEEN 5800 AND 5999 THEN 212 -- Voidbridge
				 WHEN bettypePT BETWEEN 4101 AND 4300 OR 
				 	bettypePT BETWEEN 6701 AND 7000 THEN 248 -- Pragmatic
				 WHEN bettypePT BETWEEN 1011 AND 1020 THEN 219 -- Fishing World
				 WHEN bettypePT BETWEEN 1901 AND 1999 THEN 165 -- Card Club
				 WHEN bettypePT BETWEEN 4301 AND 4600 THEN 247 -- Spadegaming
				 WHEN bettypePT BETWEEN 1611 AND 1699 THEN 200 -- Saba.Club
				 WHEN bettypePT BETWEEN 3001 AND 3099 THEN 244 -- SA Gaming
				 WHEN bettypePT BETWEEN 3101 AND 3150 THEN 243 -- AE Casino
				 WHEN bettypePT BETWEEN 3201 AND 3299 THEN 242 -- IBCBet Live Casino
				 WHEN bettypePT BETWEEN 5601 AND 5699 THEN 225 -- ION
				 WHEN bettypePT BETWEEN 5500 AND 5599 THEN 224 -- RNG War
				 WHEN bettypePT BETWEEN 6001 AND 6300 THEN 232 -- PG Soft
				 WHEN bettypePT BETWEEN 6401 AND 6700 THEN 234-- Joker
				 WHEN bettypePT BETWEEN 3401 AND 3499 THEN 233 -- WM
				 WHEN bettypePT BETWEEN 5701 AND 5799 THEN 236 -- GDG
				 WHEN bettypePT BETWEEN 3501 AND 3599 THEN 239 -- BG
				 WHEN bettypePT BETWEEN 5401 AND 5499 THEN 237 -- MaxGame
				 WHEN bettypePT BETWEEN 3701 AND 3799 THEN 170 -- PP Live Casino
				 WHEN bettypePT BETWEEN 7001 AND 7300 THEN 238 -- Habanero
				 WHEN bettypePT BETWEEN 7301 AND 7600 THEN 167 -- Creative Gaming
				 WHEN bettypePT BETWEEN 3801 AND 3899 THEN 171 -- VGaming
				 WHEN bettypePT BETWEEN 7801 AND 7899 THEN 174 -- AdvantPlay Mini
				 WHEN bettypePT BETWEEN 7701 AND 7799 THEN 172 -- AdvantPlay Product
				 WHEN bettypePT BETWEEN 8201 AND 8299 THEN 176 -- FGG Product
				 WHEN bettypePT BETWEEN 8900 AND 8999 THEN 156 -- SEAL Entertainment				 
				 ELSE 0 END AS SporttypeRef
		FROM #__SuperExtraPT WHERE RefTable IN (1, 2)

		INSERT INTO #__NetTO_GrossComm (custid, sporttype, bettype, TurnoverNoDraw, grosscomm, agrosscomm, mgrosscomm, sgrosscomm)
		SELECT b.custid, bt.SporttypeRef, bt.BettypeRef
			,SUM(CASE WHEN bt.IsContributionBettype = 0 THEN b.BetStake ELSE 0 END) AS TurnoverNoDraw
			,SUM(b.BetStake * discount) grosscomm
			,SUM(b.BetStake * adiscount) agrosscomm
			,SUM(b.BetStake * sdiscount) mgrosscomm
			,SUM(b.BetStake * sdiscount) sgrosscomm
		FROM dbo.bettransRnG14 b WITH (NOLOCK)
			INNER JOIN #__Bettype bt ON b.gameID = bt.Bettype AND bt.RefTable = 1
		WHERE b.winlostdate = @winlostdate
		GROUP BY b.custid, bt.SporttypeRef, bt.BettypeRef
		HAVING SUM(CASE WHEN bt.IsContributionBettype = 0 THEN b.BetStake ELSE 0 END) <> 0
			OR SUM(b.BetStake * discount) <> 0
			OR SUM(b.BetStake * adiscount) <> 0
			OR SUM(b.BetStake * sdiscount) <> 0
		OPTION (OPTIMIZE FOR (@winlostdate UNKNOWN))

		INSERT INTO #__NetTO_GrossComm (custid, sporttype, bettype, TurnoverNoDraw, grosscomm, agrosscomm, mgrosscomm, sgrosscomm)
		SELECT b.custid, bt.SporttypeRef, bt.BettypeRef
			,SUM(CASE WHEN bt.IsContributionBettype = 0 THEN b.NetStake ELSE 0 END) AS TurnoverNoDraw
			,SUM(b.NetStake * discount) grosscomm
			,SUM(b.NetStake * adiscount) agrosscomm
			,SUM(b.NetStake * sdiscount) mgrosscomm
			,SUM(b.NetStake * sdiscount) sgrosscomm
		FROM dbo.bettransLC14 b WITH (NOLOCK)
			INNER JOIN #__Bettype bt ON b.gameID = bt.Bettype AND bt.RefTable = 2
		WHERE b.winlostdate = @winlostdate
		GROUP BY b.custid, bt.SporttypeRef, bt.BettypeRef
		HAVING SUM(CASE WHEN bt.IsContributionBettype = 0 THEN b.NetStake ELSE 0 END) <> 0
			OR SUM(b.NetStake * discount) <> 0
			OR SUM(b.NetStake * adiscount) <> 0
			OR SUM(b.NetStake * sdiscount) <> 0
		OPTION (OPTIMIZE FOR (@winlostdate UNKNOWN))

		UPDATE t
		SET t.TurnoverNoDraw = ISNULL(c.TurnoverNoDraw, 0)
			,t.grosscomm = ISNULL(c.grosscomm, 0)
			,t.agrosscomm = ISNULL(c.agrosscomm, 0)
			,t.mgrosscomm = ISNULL(c.mgrosscomm, 0)
			,t.sgrosscomm = ISNULL(c.sgrosscomm, 0)
		FROM #sum_winloss_tmp t
			INNER JOIN #__NetTO_GrossComm c ON t.custid = c.custid AND t.sporttype = c.sporttype and t.bettype = c.bettype
	END

	--insert to main table
	--member 
	INSERT INTO dbo.sum_winloss_tmp
	(
		winlostdate, roleid, custid, recommend, mrecommend, srecommend, turnover, winlost, awinlost, mwinlost, swinlost,
		playercomm, comm, acomm, scomm, betcount, grosscomm, Sporttype, bettype, netTurnover, TunroverNoDraw, ExtraWinloss, ExtraComm, leagueGroupID, ticketType
	)
	SELECT winlostdate, roleid, custid, recommend, mrecommend, srecommend, turnover, winlost, awinlost, mwinlost, swinlost,
		playercomm, comm, acomm, scomm, betcount, grosscomm, Sporttype, bettype, netTurnover, TurnoverNoDraw, ExtraWinloss, ExtraComm, leagueGroupID, ticketType
	FROM #sum_winloss_tmp

	---- Agent
	INSERT INTO sum_winloss_tmp
	(
		winlostdate, roleid, custid, recommend, mrecommend, srecommend, turnover, winlost, awinlost, mwinlost, swinlost,
		playercomm, comm, acomm, scomm, BetCount, grosscomm, sporttype, bettype, netTurnover, TunroverNoDraw, ExtraWinloss, ExtraComm, leagueGroupID, ticketType
	)
	SELECT
		@winlostdate
	   ,2
	   ,bettrans.recommend
	   ,bettrans.recommend
	   ,bettrans.mrecommend
	   ,bettrans.srecommend
	   ,SUM(turnover) TurnOver
	   ,SUM(winlost) winlost
	   ,SUM(awinlost) awinlost
	   ,SUM(mwinlost) mwinlost
	   ,SUM(bettrans.swinlost) swinlost
	   ,SUM(playercomm) playercomm
	   ,SUM(comm) comm
	   ,SUM(acomm) acomm
	   ,SUM(ISNULL(scomm, 0)) scomm
	   ,sum(bettrans.BetCount) BetCount
	   ,SUM(bettrans.agrosscomm) agrosscomm
	   ,sporttype
	   ,bettype
	   ,SUM(bettrans.anetTurnover) AS netTurnover
	   ,SUM(TurnoverNoDraw) AS TurnoverNoDraw,
		SUM(ExtraWinloss) AS ExtraWinloss,
		SUM(ExtraComm) AS ExtraComm,
		bettrans.leagueGroupID,
		bettrans.ticketType
	FROM #sum_winloss_tmp bettrans WITH (NOLOCK)
	GROUP BY bettrans.recommend
			,bettrans.mrecommend
			,bettrans.srecommend
			,bettrans.sporttype
			,bettrans.bettype
			,bettrans.leagueGroupID
			,bettrans.ticketType

	---- Master
	INSERT INTO sum_winloss_tmp
	(
		winlostdate, roleid, custid, recommend, mrecommend, srecommend, turnover, winlost, awinlost, mwinlost, swinlost,
		playercomm, comm, acomm, scomm, BetCount, grosscomm, sporttype, bettype, netTurnover, TunroverNoDraw, ExtraWinloss, ExtraComm, leagueGroupID, ticketType
	)
	SELECT
		@winlostdate
	   ,3
	   ,bettrans.mrecommend
	   ,0 recommend
	   ,bettrans.mrecommend
	   ,bettrans.srecommend
	   ,SUM(turnover) TurnOver
	   ,SUM(winlost) winlost
	   ,SUM(awinlost) awinlost
	   ,SUM(mwinlost) mwinlost
	   ,SUM(bettrans.swinlost) swinlost
	   ,SUM(playercomm) playercomm
	   ,SUM(comm) comm
	   ,SUM(acomm) acomm
	   ,SUM(ISNULL(scomm, 0)) scomm
	   ,sum(bettrans.BetCount) BetCount
	   ,SUM(bettrans.mgrosscomm) mgrosscomm
	   ,sporttype
	   ,bettype
	   ,SUM(bettrans.mnetTurnover) AS netTurnover
	   ,SUM(bettrans.TurnoverNoDraw) AS TurnoverNoDraw,
		SUM(ExtraWinloss) AS ExtraWinloss,
		SUM(ExtraComm) AS ExtraComm
	   ,bettrans.leagueGroupID
	   ,bettrans.ticketType
	FROM #sum_winloss_tmp bettrans WITH (NOLOCK)
	GROUP BY bettrans.mrecommend
			,bettrans.srecommend
			,bettrans.sporttype
			,bettrans.bettype
			,bettrans.leagueGroupID
			,bettrans.ticketType


	---- Super
	INSERT INTO sum_winloss_tmp
	(
		winlostdate, roleid, custid, recommend, mrecommend, srecommend, turnover, winlost, awinlost, mwinlost, swinlost,
		playercomm, comm, acomm, scomm, BetCount, grosscomm, sporttype, bettype, netTurnover, TunroverNoDraw, ExtraWinloss, ExtraComm, leagueGroupID, ticketType
	)
	SELECT
		@winlostdate
	   ,4
	   ,bettrans.srecommend
	   ,0 recommend
	   ,0 mrecommend
	   ,bettrans.srecommend
	   ,SUM(turnover) TurnOver
	   ,SUM(winlost) winlost
	   ,SUM(awinlost) awinlost
	   ,SUM(mwinlost) mwinlost
	   ,SUM(bettrans.swinlost) swinlost
	   ,SUM(playercomm) playercomm
	   ,SUM(comm) comm
	   ,SUM(acomm) acomm
	   ,SUM(ISNULL(scomm, 0)) scomm
	   ,sum(bettrans.BetCount) BetCount
	   ,SUM(bettrans.sgrosscomm) sgrosscomm
	   ,sporttype
	   ,bettype
	   ,SUM(bettrans.snetTurnover) AS netTurnover
	   ,SUM(bettrans.TurnoverNoDraw) AS TurnoverNoDraw,
		SUM(ExtraWinloss) AS ExtraWinloss,
		SUM(ExtraComm) AS ExtraComm
	   ,bettrans.leagueGroupID
	   ,bettrans.ticketType
	FROM #sum_winloss_tmp bettrans WITH (NOLOCK)
	GROUP BY bettrans.srecommend
			,bettrans.sporttype
			,bettrans.bettype
			,bettrans.leagueGroupID
			,bettrans.ticketType

	-- update username for main table
	-- temp table for only one day, no need to update by batch
	UPDATE s
		SET s.username = c.username
	FROM sum_winloss_tmp s WITH(ROWLOCK)
		INNER JOIN CustDB.dbo.Customer c WITH(NOLOCK)
			ON s.custid = c.custid
	WHERE s.winlostdate = @winlostdate
	
	DROP TABLE #__SuperExtraPT
	DROP TABLE #sum_winloss_tmp
	DROP TABLE #__Bettype
	DROP TABLE #__NetTO_GrossComm
END
GO