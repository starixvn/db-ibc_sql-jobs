/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_Sum_Winloss]
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
	
*/
BEGIN

	SET NOCOUNT ON

	---- get extra PT from table setting
	CREATE TABLE #__SuperExtraPT(productId INT, bettypePT INT, SuperId INT, ExtraPT MONEY)
	CREATE CLUSTERED INDEX CIX_#__SuperExtraPT ON #__SuperExtraPT(SuperId, bettypePT)

	;WITH rs AS 
	(
		SELECT DISTINCT b.bettype , b.srecommend
		FROM bettrans14 b WITH(NOLOCK) 
		WHERE 
			b.winlostdate = @winlostdate
			AND b.statusID NOT IN (0, 1, 102, 101, 103)
			AND b.bettype <= 19000
	)
	INSERT INTO #__SuperExtraPT (productId, bettypePT, SuperId, ExtraPT)
	SELECT tbl.ProductID, b.bettype , b.srecommend , T.ExtraPT
	FROM rs b 
		CROSS APPLY 
		(
			SELECT DISTINCT
				tbl.ProductID
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

	---- Member
	INSERT INTO sum_winloss_tmp
	(
		winlostdate, roleid, custid, recommend, mrecommend, srecommend, turnover, winlost, awinlost, mwinlost, swinlost,
		playercomm, comm, acomm, scomm, betcount, grosscomm, Sporttype, bettype, netTurnover, TunroverNoDraw, ExtraWinloss, ExtraComm
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
			WHEN apositiontaking = 1 THEN 0
			ELSE ISNULL(comm / (1 - apositiontaking), 0)
		END) grosscomm
	   ,CASE
			WHEN bettype BETWEEN 81 AND 120 OR
				bettype BETWEEN 8101 AND 8120 THEN 161 -- Number Game 
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
			WHEN bettype BETWEEN 4001 AND 4100 THEN 212 --Voidbridge
			WHEN bettype BETWEEN 4101 AND 4300 THEN 248 --Pragmatic
			WHEN bettype BETWEEN 2501 AND 2699 THEN 213 --NG2 -
			WHEN bettype BETWEEN 1011 AND 1020 THEN 219 --Fishing World -
			WHEN bettype BETWEEN 8000 AND 8099 THEN 221 -- Exchange
			WHEN bettype BETWEEN 1901 AND 1999 THEN 165 -- Card Club
			WHEN bettype BETWEEN 4301 AND 4600 THEN 247 -- Spadegaming
			WHEN bettype BETWEEN 4601 AND 4900 THEN 245 -- Virtual Games
			WHEN bettype BETWEEN 1611 AND 1699 THEN 200 -- Saba.Club
			WHEN bettype BETWEEN 3001 AND 3099 THEN 244 -- SA Gaming
			WHEN bettype BETWEEN 3101 AND 3199 THEN 243 -- Sexy Gaming
			WHEN bettype BETWEEN 5001 AND 5099 THEN 223 -- Indo 4D
			WHEN bettype BETWEEN 4901 AND 5000 THEN 222 -- Table Games	
			WHEN bettype BETWEEN 3300 AND 3399 THEN 241 -- BBIN	
			WHEN bettype BETWEEN 3201 AND 3299 THEN 242 -- IBCBet Live Casino		
			WHEN bettype BETWEEN 5601 AND 5699 THEN 225 -- ION					
			WHEN bettype BETWEEN 5500 AND 5599 THEN 224 -- RNG War				
			ELSE 0
		END sporttype
	   ,CASE
			WHEN bettype IN (71, 72) THEN bettype
			ELSE 0
		END bettype
	   ,0 AS netTurnover
	   ,SUM(CASE
			WHEN statusID IN (112, 113) AND
				modds IN (-0.25, 0.25)
				---- Sportsbook
				AND (bettype < 999 OR
				bettype BETWEEN 1301 AND 1399 OR
				bettype BETWEEN 9001 AND 9399) AND
				bettype NOT IN (71, 72) AND
				bettype NOT BETWEEN 81 AND 120 THEN ABS(stake) / 2
			WHEN statusID = 111 AND
				(
				---- Sportsbook
				(bettype < 999 OR
				bettype BETWEEN 1301 AND 1399 OR
				bettype BETWEEN 9001 AND 9399) AND
				bettype NOT IN (71, 72) AND
				bettype NOT BETWEEN 81 AND 120
				) THEN 0
			WHEN bettype BETWEEN 2401 AND 2499   -- Allbet
				OR bettype BETWEEN 3001 AND 3099   -- SA Gaming
				OR bettype BETWEEN 3101 AND 3199   -- Sexy Gaming
				OR bettype BETWEEN 3300 AND 3399   -- BBIN	
				OR bettype BETWEEN 3201 AND 3299   -- IBCBet Live Casino
				OR bettype BETWEEN 5601 AND 5699   -- ION 	 
			THEN oddsspread
			ELSE ABS(stake)
		END) AS TurnoverNoDraw,
		-1 * SUM(
					CASE
						-- Jackpot
						WHEN bettrans.bettype IN (2198, 2398, 2998, 4297) THEN
							CASE WHEN bettrans.tpositiontaking = 1 THEN 0 ELSE ISNULL(bettrans.betid/CONVERT(DECIMAL(19,8), 100000000), 0) END
						WHEN bettrans.bettype IN (2199, 2399, 2999, 4298) THEN 0
						ELSE CASE WHEN bettrans.tpositiontaking = 1 THEN 0 ELSE bettrans.winlost - bettrans.actual_stake END
					END
					* CASE WHEN tbl.ExtraPT IS NOT NULL THEN tbl.ExtraPT
							ELSE ISNULL(bettrans.epositiontaking, 0)
						END
			) AS ExtraWinloss,
		-1 * SUM(CASE 
					/*IBCBet Live Casino*/
					WHEN bettrans.bettype BETWEEN 3201 AND 3299 THEN bettrans.scomm
					WHEN bettrans.bettype IN (2198, 2398, 2998, 2199, 2399, 2999, 4297, 4298) THEN 0
					ELSE 
						CASE 
							WHEN bettrans.tpositiontaking = 1 THEN 0 
							ELSE bettrans.scomm / (1 - bettrans.tpositiontaking)
						END * CASE WHEN tbl.ExtraPT IS NOT NULL THEN tbl.ExtraPT ELSE ISNULL(bettrans.epositiontaking, 0) END
				END
			) AS ExtraComm
	FROM dbo.bettrans14 bettrans WITH (NOLOCK)
			INNER JOIN #__SuperExtraPT tbl 
				ON bettrans.srecommend = tbl.SuperId
					AND bettrans.bettype = tbl.bettypePT
	WHERE 
		bettrans.winlostdate = @winlostdate
		AND bettrans.statusID NOT IN (0, 1, 102, 101, 103)
		AND bettrans.bettype <= 19000
	GROUP BY bettrans.custid
			,bettrans.recommend
			,bettrans.mrecommend
			,bettrans.srecommend
			,CASE
				 WHEN bettype BETWEEN 81 AND 120 OR
					 bettype BETWEEN 8101 AND 8120 THEN 161 -- Number Game 
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
				 WHEN bettype BETWEEN 4001 AND 4100 THEN 212 --Voidbridge
				 WHEN bettype BETWEEN 4101 AND 4300 THEN 248 --Pragmatic
				 WHEN bettype BETWEEN 2501 AND 2699 THEN 213 --NG2 -
				 WHEN bettype BETWEEN 1011 AND 1020 THEN 219 --Fishing World -
				 WHEN bettype BETWEEN 8000 AND 8099 THEN 221 -- Exchange
				 WHEN bettype BETWEEN 1901 AND 1999 THEN 165 -- Card Club
				 WHEN bettype BETWEEN 4301 AND 4600 THEN 247 -- Spadegaming
				 WHEN bettype BETWEEN 4601 AND 4900 THEN 245 -- Virtual Games
				 WHEN bettype BETWEEN 1611 AND 1699 THEN 200 -- Saba.Club
				 WHEN bettype BETWEEN 3001 AND 3099 THEN 244 -- SA Gaming
				 WHEN bettype BETWEEN 3101 AND 3199 THEN 243 -- Sexy Gaming
				 WHEN bettype BETWEEN 5001 AND 5099 THEN 223 -- Indo 4D
				 WHEN bettype BETWEEN 4901 AND 5000 THEN 222 -- Table Games
				 WHEN bettype BETWEEN 3300 AND 3399 THEN 241 -- BBIN
				 WHEN bettype BETWEEN 3201 AND 3299 THEN 242 -- IBCBet Live Casino
				 WHEN bettype BETWEEN 5601 AND 5699 THEN 225 -- ION
				 WHEN bettype BETWEEN 5500 AND 5599 THEN 224 -- RNG War	
				 ELSE 0
			 END
			,CASE
				 WHEN bettype IN (71, 72) THEN bettype
				 ELSE 0
			 END
	OPTION (optimize for (@winlostdate UNKNOWN))

	---- Agent
	INSERT INTO sum_winloss_tmp
	(
		winlostdate, roleid, custid, recommend, mrecommend, srecommend, turnover, winlost, awinlost, mwinlost, swinlost,
		playercomm, comm, acomm, scomm, BetCount, grosscomm, sporttype, bettype, netTurnover, TunroverNoDraw, ExtraWinloss, ExtraComm
	)
	SELECT
		@winlostdate
	   ,2
	   ,bettrans.recommend
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
			WHEN apositiontaking + mpositiontaking = 1 THEN 0
			ELSE ISNULL(acomm / (1 - apositiontaking - mpositiontaking), 0)
		END) grosscomm
	   ,CASE
			WHEN bettype BETWEEN 81 AND 120 OR
				bettype BETWEEN 8101 AND 8120 THEN 161 -- Number Game 
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
			WHEN bettype BETWEEN 4001 AND 4100 THEN 212 --Voidbridge
			WHEN bettype BETWEEN 4101 AND 4300 THEN 248 --Pragmatic
			WHEN bettype BETWEEN 2501 AND 2699 THEN 213 --NG2 -
			WHEN bettype BETWEEN 1011 AND 1020 THEN 219 --Fishing World -
			WHEN bettype BETWEEN 8000 AND 8099 THEN 221 -- Exchange
			WHEN bettype BETWEEN 1901 AND 1999 THEN 165 -- Card Club
			WHEN bettype BETWEEN 4301 AND 4600 THEN 247 -- Spadegaming
			WHEN bettype BETWEEN 4601 AND 4900 THEN 245 -- Virtual Games
			WHEN bettype BETWEEN 1611 AND 1699 THEN 200 -- Saba.Club
			WHEN bettype BETWEEN 3001 AND 3099 THEN 244 -- SA Gaming
			WHEN bettype BETWEEN 3101 AND 3199 THEN 243 -- Sexy Gaming
			WHEN bettype BETWEEN 5001 AND 5099 THEN 223 -- Indo 4D
			WHEN bettype BETWEEN 4901 AND 5000 THEN 222 -- Table Games
			WHEN bettype BETWEEN 3300 AND 3399 THEN 241 -- BBIN
			WHEN bettype BETWEEN 3201 AND 3299 THEN 242 -- IBCBet Live Casino
			WHEN bettype BETWEEN 5601 AND 5699 THEN 225 -- ION
			WHEN bettype BETWEEN 5500 AND 5599 THEN 224 -- RNG War	
			ELSE 0
		END sporttype
	   ,CASE
			WHEN bettype IN (71, 72) THEN bettype
			ELSE 0
		END bettype
	   ,SUM(ABS(stake * apositiontaking)) AS netTurnover
	   ,SUM(CASE
			WHEN statusID IN (112, 113) AND
				modds IN (-0.25, 0.25)
				---- Sportsbook
				AND (bettype < 999 OR
				bettype BETWEEN 1301 AND 1399 OR
				bettype BETWEEN 9001 AND 9399) AND
				bettype NOT IN (71, 72) AND
				bettype NOT BETWEEN 81 AND 120 THEN ABS(stake) / 2
			WHEN statusID = 111 AND
				(
				---- Sportsbook
				(bettype < 999 OR
				bettype BETWEEN 1301 AND 1399 OR
				bettype BETWEEN 9001 AND 9399) AND
				bettype NOT IN (71, 72) AND
				bettype NOT BETWEEN 81 AND 120
				) THEN 0
			WHEN bettype BETWEEN 2401 AND 2499   -- Allbet
				OR bettype BETWEEN 3001 AND 3099   -- SA Gaming
				OR bettype BETWEEN 3101 AND 3199   -- Sexy Gaming
				OR bettype BETWEEN 3300 AND 3399   -- BBIN	
				OR bettype BETWEEN 3201 AND 3299   -- IBCBet Live Casino
				OR bettype BETWEEN 5601 AND 5699   -- ION 
			THEN oddsspread
			ELSE ABS(stake)
		END) AS TurnoverNoDraw,
		-1 * SUM(
					CASE
						-- Jackpot
						WHEN bettrans.bettype IN (2198, 2398, 2998, 4297) THEN
							CASE WHEN bettrans.tpositiontaking = 1 THEN 0 ELSE ISNULL(bettrans.betid/CONVERT(DECIMAL(19,8), 100000000), 0) END
						WHEN bettrans.bettype IN (2199, 2399, 2999, 4298) THEN 0
						ELSE CASE WHEN bettrans.tpositiontaking = 1 THEN 0 ELSE bettrans.winlost - bettrans.actual_stake END
					END
					* CASE WHEN tbl.ExtraPT IS NOT NULL THEN tbl.ExtraPT
							ELSE ISNULL(bettrans.epositiontaking, 0)
						END
			) AS ExtraWinloss,
		-1 * SUM(CASE 
					/*IBCBet Live Casino*/
					WHEN bettrans.bettype BETWEEN 3201 AND 3299 THEN bettrans.scomm
					WHEN bettrans.bettype IN (2198, 2398, 2998, 2199, 2399, 2999, 4297, 4298) THEN 0
					ELSE 
						CASE 
							WHEN bettrans.tpositiontaking = 1 THEN 0 
							ELSE bettrans.scomm / (1 - bettrans.tpositiontaking)
						END * CASE WHEN tbl.ExtraPT IS NOT NULL THEN tbl.ExtraPT ELSE ISNULL(bettrans.epositiontaking, 0) END
				END
			) AS ExtraComm
	FROM dbo.bettrans14 bettrans WITH (NOLOCK)
			INNER JOIN #__SuperExtraPT tbl 
				ON bettrans.srecommend = tbl.SuperId
					AND bettrans.bettype = tbl.bettypePT
	WHERE 
		bettrans.winlostdate = @winlostdate
		AND bettrans.statusID NOT IN (0, 1, 102, 101, 103)
		AND bettrans.bettype <= 19000
	GROUP BY bettrans.recommend
			,bettrans.mrecommend
			,bettrans.srecommend
			,CASE
				 WHEN bettype BETWEEN 81 AND 120 OR
					 bettype BETWEEN 8101 AND 8120 THEN 161 -- Number Game 
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
				 WHEN bettype BETWEEN 4001 AND 4100 THEN 212 --Voidbridge
				 WHEN bettype BETWEEN 4101 AND 4300 THEN 248 --Pragmatic
				 WHEN bettype BETWEEN 2501 AND 2699 THEN 213 --NG2 -
				 WHEN bettype BETWEEN 1011 AND 1020 THEN 219 --Fishing World -
				 WHEN bettype BETWEEN 8000 AND 8099 THEN 221 -- Exchange
				 WHEN bettype BETWEEN 1901 AND 1999 THEN 165 -- Card Club
				 WHEN bettype BETWEEN 4301 AND 4600 THEN 247 -- Spadegaming
				 WHEN bettype BETWEEN 4601 AND 4900 THEN 245 -- Virtual Games
				 WHEN bettype BETWEEN 1611 AND 1699 THEN 200 -- Saba.Club
				 WHEN bettype BETWEEN 3001 AND 3099 THEN 244 -- SA Gaming
				 WHEN bettype BETWEEN 3101 AND 3199 THEN 243 -- Sexy Gaming
				 WHEN bettype BETWEEN 5001 AND 5099 THEN 223 -- Indo 4D
				 WHEN bettype BETWEEN 4901 AND 5000 THEN 222 -- Table Games
				 WHEN bettype BETWEEN 3300 AND 3399 THEN 241 -- BBIN
				 WHEN bettype BETWEEN 3201 AND 3299 THEN 242 -- IBCBet Live Casino
				 WHEN bettype BETWEEN 5601 AND 5699 THEN 225 -- ION
				 WHEN bettype BETWEEN 5500 AND 5599 THEN 224 -- RNG War	
				 ELSE 0
			 END
			,CASE
				 WHEN bettype IN (71, 72) THEN bettype
				 ELSE 0
			 END
	OPTION (optimize for (@winlostdate UNKNOWN))

	---- Master
	INSERT INTO sum_winloss_tmp
	(
		winlostdate, roleid, custid, recommend, mrecommend, srecommend, turnover, winlost, awinlost, mwinlost, swinlost,
		playercomm, comm, acomm, scomm, BetCount, grosscomm, sporttype, bettype, netTurnover, TunroverNoDraw, ExtraWinloss, ExtraComm
	)
	SELECT
		@winlostdate
	   ,3
	   ,bettrans.mrecommend
	   ,0 recommend
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
			WHEN tpositiontaking = 1 THEN 0
			ELSE scomm / (1 - tpositiontaking)
		END) grosscomm
	   ,CASE
			WHEN bettype BETWEEN 81 AND 120 OR
				bettype BETWEEN 8101 AND 8120 THEN 161 -- Number Game 
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
			WHEN bettype BETWEEN 4001 AND 4100 THEN 212 --Voidbridge
			WHEN bettype BETWEEN 4101 AND 4300 THEN 248 --Pragmatic
			WHEN bettype BETWEEN 2501 AND 2699 THEN 213 --NG2 -
			WHEN bettype BETWEEN 1011 AND 1020 THEN 219 --Fishing World -
			WHEN bettype BETWEEN 8000 AND 8099 THEN 221 -- Exchange
			WHEN bettype BETWEEN 1901 AND 1999 THEN 165 -- Card Club
			WHEN bettype BETWEEN 4301 AND 4600 THEN 247 -- Spadegaming
			WHEN bettype BETWEEN 4601 AND 4900 THEN 245 -- Virtual Games
			WHEN bettype BETWEEN 1611 AND 1699 THEN 200 -- Saba.Club
			WHEN bettype BETWEEN 3001 AND 3099 THEN 244 -- SA Gaming
			WHEN bettype BETWEEN 3101 AND 3199 THEN 243 -- Sexy Gaming
			WHEN bettype BETWEEN 5001 AND 5099 THEN 223 -- Indo 4D
			WHEN bettype BETWEEN 4901 AND 5000 THEN 222 -- Table Games
			WHEN bettype BETWEEN 3300 AND 3399 THEN 241 -- BBIN
			WHEN bettype BETWEEN 3201 AND 3299 THEN 242 -- IBCBet Live Casino
			WHEN bettype BETWEEN 5601 AND 5699 THEN 225 -- ION
			WHEN bettype BETWEEN 5500 AND 5599 THEN 224 -- RNG War	
			ELSE 0
		END sporttype
	   ,CASE
			WHEN bettype IN (71, 72) THEN bettype
			ELSE 0
		END bettype
	   ,SUM(ABS(stake * mpositiontaking)) AS netTurnover
	   ,SUM(CASE
			WHEN statusID IN (112, 113) AND
				modds IN (-0.25, 0.25)
				---- Sportsbook
				AND (bettype < 999 OR
				bettype BETWEEN 1301 AND 1399 OR
				bettype BETWEEN 9001 AND 9399) AND
				bettype NOT IN (71, 72) AND
				bettype NOT BETWEEN 81 AND 120 THEN ABS(stake) / 2
			WHEN statusID = 111 AND
				(
				---- Sportsbook
				(bettype < 999 OR
				bettype BETWEEN 1301 AND 1399 OR
				bettype BETWEEN 9001 AND 9399) AND
				bettype NOT IN (71, 72) AND
				bettype NOT BETWEEN 81 AND 120
				) THEN 0
			WHEN bettype BETWEEN 2401 AND 2499   -- Allbet
				OR bettype BETWEEN 3001 AND 3099   -- SA Gaming
				OR bettype BETWEEN 3101 AND 3199   -- Sexy Gaming
				OR bettype BETWEEN 3300 AND 3399   -- BBIN	
				OR bettype BETWEEN 3201 AND 3299   -- IBCBet Live Casino
				OR bettype BETWEEN 5601 AND 5699   -- ION 
			THEN oddsspread
			ELSE ABS(stake)
		END) AS TurnoverNoDraw,
		-1 * SUM(
					CASE
						-- Jackpot
						WHEN bettrans.bettype IN (2198, 2398, 2998, 4297) THEN
							CASE WHEN bettrans.tpositiontaking = 1 THEN 0 ELSE ISNULL(bettrans.betid/CONVERT(DECIMAL(19,8), 100000000), 0) END
						WHEN bettrans.bettype IN (2199, 2399, 2999, 4298) THEN 0
						ELSE CASE WHEN bettrans.tpositiontaking = 1 THEN 0 ELSE bettrans.winlost - bettrans.actual_stake END
					END
					* CASE WHEN tbl.ExtraPT IS NOT NULL THEN tbl.ExtraPT
							ELSE ISNULL(bettrans.epositiontaking, 0)
						END
			) AS ExtraWinloss,
		-1 * SUM(CASE 
					/*IBCBet Live Casino*/
					WHEN bettrans.bettype BETWEEN 3201 AND 3299 THEN bettrans.scomm
					WHEN bettrans.bettype IN (2198, 2398, 2998, 2199, 2399, 2999, 4297, 4298) THEN 0
					ELSE 
						CASE 
							WHEN bettrans.tpositiontaking = 1 THEN 0 
							ELSE bettrans.scomm / (1 - bettrans.tpositiontaking)
						END * CASE WHEN tbl.ExtraPT IS NOT NULL THEN tbl.ExtraPT ELSE ISNULL(bettrans.epositiontaking, 0) END
				END
			) AS ExtraComm
	FROM dbo.bettrans14 bettrans WITH (NOLOCK)
			INNER JOIN #__SuperExtraPT tbl 
				ON bettrans.srecommend = tbl.SuperId
					AND bettrans.bettype = tbl.bettypePT
	WHERE 
		bettrans.winlostdate = @winlostdate
		AND bettrans.statusID NOT IN (0, 1, 102, 101, 103)
		AND bettrans.bettype <= 19000
	GROUP BY bettrans.mrecommend
			,bettrans.srecommend
			,CASE
				 WHEN bettype BETWEEN 81 AND 120 OR
					 bettype BETWEEN 8101 AND 8120 THEN 161 -- Number Game 
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
				 WHEN bettype BETWEEN 4001 AND 4100 THEN 212 --Voidbridge
				 WHEN bettype BETWEEN 4101 AND 4300 THEN 248 --Pragmatic
				 WHEN bettype BETWEEN 2501 AND 2699 THEN 213 --NG2 -
				 WHEN bettype BETWEEN 1011 AND 1020 THEN 219 --Fishing World -
				 WHEN bettype BETWEEN 8000 AND 8099 THEN 221 -- Exchange
				 WHEN bettype BETWEEN 1901 AND 1999 THEN 165 -- Card Club
				 WHEN bettype BETWEEN 4301 AND 4600 THEN 247 -- Spadegaming
				 WHEN bettype BETWEEN 4601 AND 4900 THEN 245 -- Virtual Games
				 WHEN bettype BETWEEN 1611 AND 1699 THEN 200 -- Saba.Club
				 WHEN bettype BETWEEN 3001 AND 3099 THEN 244 -- SA Gaming
				 WHEN bettype BETWEEN 3101 AND 3199 THEN 243 -- Sexy Gaming
				 WHEN bettype BETWEEN 5001 AND 5099 THEN 223 -- Indo 4D
				 WHEN bettype BETWEEN 4901 AND 5000 THEN 222 -- Table Games
				 WHEN bettype BETWEEN 3300 AND 3399 THEN 241 -- BBIN
				 WHEN bettype BETWEEN 3201 AND 3299 THEN 242 -- IBCBet Live Casino
				 WHEN bettype BETWEEN 5601 AND 5699 THEN 225 -- ION
				 WHEN bettype BETWEEN 5500 AND 5599 THEN 224 -- RNG War	
				 ELSE 0
			 END
			,CASE
				 WHEN bettype IN (71, 72) THEN bettype
				 ELSE 0
			 END
	OPTION (optimize for (@winlostdate UNKNOWN))

	---- Super
	INSERT INTO sum_winloss_tmp
	(
		winlostdate, roleid, custid, recommend, mrecommend, srecommend, turnover, winlost, awinlost, mwinlost, swinlost,
		playercomm, comm, acomm, scomm, BetCount, grosscomm, sporttype, bettype, netTurnover, TunroverNoDraw, ExtraWinloss, ExtraComm
	)
	SELECT
		@winlostdate
	   ,4
	   ,bettrans.srecommend
	   ,0 recommend
	   ,0 mrecommend
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
			WHEN tpositiontaking = 1 THEN 0
			ELSE scomm / (1 - tpositiontaking)
		END) grosscomm
	   ,CASE
			WHEN bettype BETWEEN 81 AND 120 OR
				bettype BETWEEN 8101 AND 8120 THEN 161 -- Number Game 
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
			WHEN bettype BETWEEN 4001 AND 4100 THEN 212 --Voidbridge
			WHEN bettype BETWEEN 4101 AND 4300 THEN 248 --Pragmatic
			WHEN bettype BETWEEN 2501 AND 2699 THEN 213 --NG2 -
			WHEN bettype BETWEEN 1011 AND 1020 THEN 219 --Fishing World -
			WHEN bettype BETWEEN 8000 AND 8099 THEN 221 -- Exchange
			WHEN bettype BETWEEN 1901 AND 1999 THEN 165 -- Card Club
			WHEN bettype BETWEEN 4301 AND 4600 THEN 247 -- Spadegaming
			WHEN bettype BETWEEN 4601 AND 4900 THEN 245 -- Virtual Games
			WHEN bettype BETWEEN 1611 AND 1699 THEN 200 -- Saba.Club
			WHEN bettype BETWEEN 3001 AND 3099 THEN 244 -- SA Gaming
			WHEN bettype BETWEEN 3101 AND 3199 THEN 243 -- Sexy Gaming
			WHEN bettype BETWEEN 5001 AND 5099 THEN 223 -- Indo 4D
			WHEN bettype BETWEEN 4901 AND 5000 THEN 222 -- Table Games
			WHEN bettype BETWEEN 3300 AND 3399 THEN 241 -- BBIN
			WHEN bettype BETWEEN 3201 AND 3299 THEN 242 -- IBCBet Live Casino
			WHEN bettype BETWEEN 5601 AND 5699 THEN 225 -- ION
			WHEN bettype BETWEEN 5500 AND 5599 THEN 224 -- RNG War	
			ELSE 0
		END sporttype
	   ,CASE
			WHEN bettype IN (71, 72) THEN bettype
			ELSE 0
		END bettype
	   ,SUM(ABS(stake * spositiontaking)) AS netTurnover
	   ,SUM(CASE
			WHEN statusID IN (112, 113) AND
				modds IN (-0.25, 0.25)
				---- Sportsbook
				AND (bettype < 999 OR
				bettype BETWEEN 1301 AND 1399 OR
				bettype BETWEEN 9001 AND 9399) AND
				bettype NOT IN (71, 72) AND
				bettype NOT BETWEEN 81 AND 120 THEN ABS(stake) / 2
			WHEN statusID = 111 AND
				(
				---- Sportsbook
				(bettype < 999 OR
				bettype BETWEEN 1301 AND 1399 OR
				bettype BETWEEN 9001 AND 9399) AND
				bettype NOT IN (71, 72) AND
				bettype NOT BETWEEN 81 AND 120
				) THEN 0
			WHEN bettype BETWEEN 2401 AND 2499   -- Allbet
				OR bettype BETWEEN 3001 AND 3099   -- SA Gaming
				OR bettype BETWEEN 3101 AND 3199   -- Sexy Gaming
				OR bettype BETWEEN 3300 AND 3399   -- BBIN
				OR bettype BETWEEN 5601 AND 5699   -- ION
				OR bettype BETWEEN 3201 AND 3299   -- IBCBet Live Casino						
				OR bettype BETWEEN 5601 AND 5699   -- ION 	
			THEN oddsspread
			ELSE ABS(stake)
		END) AS TurnoverNoDraw,
		-1 * SUM(
					CASE
						-- Jackpot
						WHEN bettrans.bettype IN (2198, 2398, 2998, 4297) THEN
							CASE WHEN bettrans.tpositiontaking = 1 THEN 0 ELSE ISNULL(bettrans.betid/CONVERT(DECIMAL(19,8), 100000000), 0) END
						WHEN bettrans.bettype IN (2199, 2399, 2999, 4298) THEN 0
						ELSE CASE WHEN bettrans.tpositiontaking = 1 THEN 0 ELSE bettrans.winlost - bettrans.actual_stake END
					END
					* CASE WHEN tbl.ExtraPT IS NOT NULL THEN tbl.ExtraPT
							ELSE ISNULL(bettrans.epositiontaking, 0)
						END
			) AS ExtraWinloss,
		-1 * SUM(CASE 
					/*IBCBet Live Casino*/
					WHEN bettrans.bettype BETWEEN 3201 AND 3299 THEN bettrans.scomm
					WHEN bettrans.bettype IN (2198, 2398, 2998, 2199, 2399, 2999, 4297, 4298) THEN 0
					ELSE 
						CASE 
							WHEN bettrans.tpositiontaking = 1 THEN 0 
							ELSE bettrans.scomm / (1 - bettrans.tpositiontaking)
						END * CASE WHEN tbl.ExtraPT IS NOT NULL THEN tbl.ExtraPT ELSE ISNULL(bettrans.epositiontaking, 0) END
				END
			) AS ExtraComm
	FROM dbo.bettrans14 bettrans WITH (NOLOCK)
			INNER JOIN #__SuperExtraPT tbl 
				ON bettrans.srecommend = tbl.SuperId
					AND bettrans.bettype = tbl.bettypePT
	WHERE 
		bettrans.winlostdate = @winlostdate
		AND bettrans.statusID NOT IN (0, 1, 102, 101, 103)
		AND bettrans.bettype <= 19000

	GROUP BY bettrans.srecommend
			,CASE
				 WHEN bettype BETWEEN 81 AND 120 OR
					 bettype BETWEEN 8101 AND 8120 THEN 161 -- Number Game 
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
				 WHEN bettype BETWEEN 4001 AND 4100 THEN 212 --Voidbridge
				 WHEN bettype BETWEEN 4101 AND 4300 THEN 248 --Pragmatic
				 WHEN bettype BETWEEN 2501 AND 2699 THEN 213 --NG2 -
				 WHEN bettype BETWEEN 1011 AND 1020 THEN 219 --Fishing World -
				 WHEN bettype BETWEEN 8000 AND 8099 THEN 221 -- Exchange
				 WHEN bettype BETWEEN 1901 AND 1999 THEN 165 -- Card Club
				 WHEN bettype BETWEEN 4301 AND 4600 THEN 247 -- Spadegaming
				 WHEN bettype BETWEEN 4601 AND 4900 THEN 245 -- Virtual Games
				 WHEN bettype BETWEEN 1611 AND 1699 THEN 200 -- Saba.Club
				 WHEN bettype BETWEEN 3001 AND 3099 THEN 244 -- SA Gaming
				 WHEN bettype BETWEEN 3101 AND 3199 THEN 243 -- Sexy Gaming
				 WHEN bettype BETWEEN 5001 AND 5099 THEN 223 -- Indo 4D
				 WHEN bettype BETWEEN 4901 AND 5000 THEN 222 -- Table Games
				 WHEN bettype BETWEEN 3300 AND 3399 THEN 241 -- BBIN
				 WHEN bettype BETWEEN 3201 AND 3299 THEN 242 -- IBCBet Live Casino
				 WHEN bettype BETWEEN 5601 AND 5699 THEN 225 -- ION
				 WHEN bettype BETWEEN 5500 AND 5599 THEN 224 -- RNG War	
				 ELSE 0
			 END
			,CASE
				 WHEN bettype IN (71, 72) THEN bettype
				 ELSE 0
			 END
	OPTION (optimize for (@winlostdate UNKNOWN))

	-- update username for main table
	-- temp table for only one day, no need to update by batch
	UPDATE s
		SET s.username = c.username
	FROM sum_winloss_tmp s WITH(ROWLOCK)
		INNER JOIN CustDB.dbo.Customer c WITH(NOLOCK)
			ON s.custid = c.custid
	WHERE s.winlostdate = @winlostdate
	
	DROP TABLE #__SuperExtraPT

END
GO