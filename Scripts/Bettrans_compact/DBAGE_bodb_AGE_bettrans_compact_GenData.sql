/*<info serverAlias="DBAGE-bodb_AGE" isNested="0"></info>*/
/*
	Created by: 20231201@Bobby
	Task: 153357 - Alpha - CDC bettrans_compact - GEN data
	DB: DBAGE.bodb_AGE
	Revisions:
		- 20240116@Bobby: Re-init data from bettrans
		
*/

USE bodb_Age;
GO

BEGIN

	SET NOCOUNT ON;

	DECLARE @NetTO_CutOffDate SMALLDATETIME
		, @GrossComm_CutOffDate SMALLDATETIME
		, @SabaInfo_CutOffDate SMALLDATETIME
		, @winlostdate SMALLDATETIME
		, @today SMALLDATETIME
		, @MBdate SMALLDATETIME
		, @message VARCHAR(200)
		, @startTime DATETIME;

		---- get extra PT from table setting
		DROP TABLE IF EXISTS #__SuperExtraPT
		CREATE TABLE #__SuperExtraPT(productId INT, bettypePT INT, SuperId INT, ExtraPT MONEY, RefTable TINYINT, IsUsingOddsSpread BIT, IsContributionBettype BIT)
		CREATE CLUSTERED INDEX CIX_#__SuperExtraPT ON #__SuperExtraPT(SuperId, bettypePT)

		---- temp table to store data from bettrans
		DROP TABLE IF EXISTS #sum_winloss_tmp
		CREATE TABLE #sum_winloss_tmp(
			[winlostdate] [datetime] NULL,
			[custid] [int] NOT NULL,
			[roleid] [int] NULL,
			[recommend] [int] NOT NULL,
			[mrecommend] [int] NOT NULL,
			[srecommend] [int] NOT NULL,
			[productId] [int],
			[sporttype] [int] NOT NULL,
			[bettype] [int] NULL,
			[leagueGroupID] [int] NULL,
			[ticketType] [int] NULL,
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
			[netTurnover] [money] NULL,
			[anetTurnover] [money] NULL,
			[mnetTurnover] [money] NULL,
			[snetTurnover] [money] NULL,
			[TurnoverNoDraw] [money] NULL,
			[ExtraWinloss] [money] NULL,
			[ExtraComm] [money] NULL
		);

	DROP TABLE IF EXISTS #bettrans_compact_tmp;
	CREATE TABLE #bettrans_compact_tmp (
		[winlostdate] [datetime] NOT NULL,
		[custid] [int] NOT NULL,
		[roleid] [int] NULL,
		[productid] [int],
		[sporttype] [int] NOT NULL,
		[bettype] [int] NOT NULL,
		[leagueGroupID] [int] NOT NULL,
		[ticketType] [int] NOT NULL,
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
		[netTurnover] [money] NOT NULL,
		[TurnoverNoDraw] [money] NULL,
		[ExtraWinloss] [money] NULL,
		[ExtraComm] [money] NULL
	);

	SELECT  @NetTO_CutOffDate = CASE WHEN f.TypeName = 'NetTO' THEN f.CutoffDate ELSE @NetTO_CutOffDate END
			,@GrossComm_CutOffDate = CASE WHEN f.TypeName = 'GrossComm' THEN f.CutoffDate ELSE @NetTO_CutOffDate END
			,@SabaInfo_CutOffDate = CASE WHEN f.TypeName = 'SabaSport' THEN f.CutoffDate ELSE @SabaInfo_CutOffDate END
	FROM bodb02.dbo.f_GetCutOffDate() f
	WHERE f.TypeName IN ('NetTO', 'GrossComm','SabaSport')

		
	--TODO: GET MBD
	SELECT @MBdate = MAX(winlostdate)
	FROM bodb02.dbo.bettrans14 WITH(NOLOCK);

	SELECT @today		= CAST(GETDATE() AS DATE)
		,@winlostdate	= DATEADD(DAY, 1, @MBdate)
	;

	--CLEAN old data from MBU
	SELECT @MBdate AS [@MBdate]

	--TODO: Process data from bettrans
	WHILE (@winlostdate <= @today)
	BEGIN
		
		SET @startTime = CURRENT_TIMESTAMP;
		SET @message = CONCAT(@@SERVERNAME, '_',db_name(), ' - Processing bettrans_compact winlostdate: ', FORMAT(@winlostdate, 'yyyy-MM-dd HH:mm:ss'));
		RAISERROR (@message, 0, 1) WITH NOWAIT;

		TRUNCATE TABLE #__SuperExtraPT;
		TRUNCATE TABLE #sum_winloss_tmp;
		TRUNCATE TABLE #bettrans_compact_tmp;

		---TODO: GEN data from bettrans
		;WITH rs AS 
		(
			SELECT DISTINCT b.bettype , b.srecommend
			FROM bodb02.dbo.bettrans b WITH(NOLOCK) 
			LEFT JOIN bodb02.dbo.Dep_CustSuper cs WITH(NOLOCK) ON cs.custid = b.srecommend
			WHERE 
				b.winlostdate = @winlostdate
				AND b.statusID IN (111,112,113)
				AND cs.custid IS NULL
		)
		INSERT INTO #__SuperExtraPT (productId, bettypePT, SuperId, ExtraPT, RefTable, IsUsingOddsSpread, IsContributionBettype)
		SELECT tbl.ProductID, b.bettype , b.srecommend , T.ExtraPT, tbl.RefTable, tbl.IsUsingOddsSpread, CASE WHEN cont.Bettype IS NOT NULL THEN 1 ELSE 0 END AS IsContributionBettype
		FROM rs b 
			CROSS APPLY 
			(
				SELECT DISTINCT
					tbl.ProductID, tbl.RefTable, CASE WHEN tbl.RefTable IN (1,2) OR tbl.ProductID = 47 THEN 1 ELSE 0 END IsUsingOddsSpread
				FROM bodb02.dbo.f_SportBettypeMatrix_Sel(0, 0, b.bettype, 2, '', '', 0) tbl
				WHERE b.bettype = tbl.bettype
			) tbl
			OUTER APPLY 
			(
				SELECT DISTINCT expt2.SuperId, expt2.ExtraPT
				FROM bodb02.dbo.Acc_GroupExtraPT2Setting expt2 WITH (NOLOCK)
				WHERE @winlostdate BETWEEN expt2.FromDate AND expt2.ToDate
						AND tbl.ProductID = expt2.ProductID
						AND b.srecommend = expt2.SuperId 
						AND ISNULL(expt2.SubProduct,'') = ''
						AND expt2.Sporttype = 0
			) t
			OUTER APPLY 
			(
				SELECT f.Bettype
				FROM bodb02.dbo.f_BettypePrizeGroup() f
				WHERE f.BettypeGroup = 'Contribution'
					AND f.Bettype = b.bettype
			) cont

		---- gen all data
		INSERT INTO #sum_winloss_tmp
		(
			winlostdate, roleid, custid, recommend, mrecommend, srecommend, 
			productId, Sporttype, bettype, leagueGroupID, ticketType,
			turnover, winlost, awinlost, mwinlost, swinlost,
			playercomm, comm, acomm, scomm, betcount, grosscomm, agrosscomm, mgrosscomm, sgrosscomm, netTurnover, anetTurnover, mnetTurnover, snetTurnover, TurnoverNoDraw, ExtraWinloss, ExtraComm
		)
		SELECT
			@winlostdate
		   ,1
		   ,b.custid
		   ,b.recommend
		   ,b.mrecommend
		   ,b.srecommend
		   ,tbl.productId
		   ,ck.sporttype
		   ,b.bettype
		   ,ck.LeagueGroupID
		   ,ck.ticketType
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
	   
		   ,0 AS netTurnover
		   ,SUM(ABS(stake) * apositiontaking) AS anetTurnover
		   ,SUM(ABS(stake) * mpositiontaking) AS mnetTurnover
		   ,SUM(ABS(stake) * spositiontaking) AS snetTurnover
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
				WHEN b.winlostdate < @NetTO_CutOffDate AND 
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
				WHEN tbl.productId = 47 THEN b.oddsspread -- BBIN
				WHEN tbl.RefTable IN (1, 2) AND b.winlostdate >= @GrossComm_CutOffDate THEN 0
				WHEN tbl.RefTable IN (1, 2) AND b.winlostdate >= @NetTO_CutOffDate THEN
					CASE WHEN tbl.IsContributionBettype = 0 THEN b.oddsspread ELSE 0	END
				ELSE ABS(stake)
			END) AS TurnoverNoDraw,
			-1 * SUM(
						CASE
							-- Jackpot
							WHEN b.bettype IN (2198, 2398, 2998, 4297, 4599) THEN
								CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE ISNULL(b.betid/CONVERT(DECIMAL(19,8), 100000000), 0) END
							WHEN b.bettype IN (2199, 2399, 2999, 4298, 4600) THEN 0
							ELSE CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE b.winlost - b.actual_stake END
						END
						* CASE WHEN tbl.ExtraPT IS NOT NULL THEN tbl.ExtraPT
								ELSE ISNULL(b.epositiontaking, 0)
							END
				) AS ExtraWinloss,
			-1 * SUM(CASE 
						/*IBCBet Live Casino*/
						WHEN b.bettype BETWEEN 3201 AND 3299 THEN b.scomm
						WHEN b.bettype IN (2198, 2398, 2998, 2199, 2399, 2999, 4297, 4298, 4599, 4600) THEN 0
						ELSE 
							CASE 
								WHEN b.tpositiontaking = 1 THEN 0 
								ELSE b.scomm / (1 - b.tpositiontaking)
							END * CASE WHEN tbl.ExtraPT IS NOT NULL THEN tbl.ExtraPT ELSE ISNULL(b.epositiontaking, 0) END
					END
				) AS ExtraComm
		FROM bodb02.dbo.bettrans b WITH (NOLOCK)
		INNER JOIN #__SuperExtraPT tbl ON b.srecommend = tbl.SuperId AND b.bettype = tbl.bettypePT
		LEFT JOIN bodb02.dbo.[match] m WITH(NOLOCK) ON b.matchid = m.matchid AND m.sporttype IN (1, 2, 5, 43, 50)
		LEFT JOIN bodb02.dbo.League l WITH(NOLOCK) ON m.leagueid=l.leagueid AND l.LeagueGroupID IN (42,74,108,113,122,151)
		CROSS APPLY (
			SELECT 
				CASE WHEN  b.betdaqid <> -2 AND l.LeagueGroupID > 0 THEN ISNULL(m.sporttype, 0) ELSE 0 END AS sporttype
				,CASE WHEN b.betdaqid <> -2 AND m.sporttype > 0 THEN ISNULL(l.LeagueGroupID,0) ELSE 0 END AS LeagueGroupID
				,CASE WHEN b.betdaqid = -2 THEN 1 ELSE 0 END ticketType
		) AS ck
		WHERE 
			b.winlostdate = @winlostdate
			AND b.statusID IN (111, 112, 113)
		GROUP BY b.custid
				,b.recommend
				,b.mrecommend
				,b.srecommend
				,tbl.productId
				,ck.sporttype
				,b.bettype
				,ck.LeagueGroupID
				,ck.ticketType

		--insert to bettrans_compact_tmp
		--member 
		INSERT INTO #bettrans_compact_tmp
		(
			winlostdate, roleid, custid, productid, Sporttype, bettype,leagueGroupID, ticketType,
			turnover, winlost, awinlost, mwinlost, swinlost,
			playercomm, comm, acomm, scomm, betcount, grosscomm,  netTurnover, TurnoverNoDraw, ExtraWinloss, ExtraComm
		)
		SELECT winlostdate, 1 AS roleid, custid, productid, Sporttype, bettype,leagueGroupID, ticketType,
			turnover, winlost, awinlost, mwinlost, swinlost,
			playercomm, comm, acomm, scomm, betcount, grosscomm, netTurnover, TurnoverNoDraw, ExtraWinloss, ExtraComm
		FROM #sum_winloss_tmp

		---- Agent
		INSERT INTO #bettrans_compact_tmp
		(
			winlostdate, roleid, custid, productid, Sporttype, bettype, leagueGroupID, ticketType,
			turnover, winlost, awinlost, mwinlost, swinlost,
			playercomm, comm, acomm, scomm, betcount, grosscomm, netTurnover, TurnoverNoDraw, ExtraWinloss, ExtraComm
		)
		SELECT
			@winlostdate
		   ,2
		   ,b.recommend
		   ,productId
		   ,sporttype
		   ,bettype,
			b.leagueGroupID,
			b.ticketType
		   ,SUM(turnover) TurnOver
		   ,SUM(winlost) winlost
		   ,SUM(awinlost) awinlost
		   ,SUM(mwinlost) mwinlost
		   ,SUM(b.swinlost) swinlost
		   ,SUM(playercomm) playercomm
		   ,SUM(comm) comm
		   ,SUM(acomm) acomm
		   ,SUM(ISNULL(scomm, 0)) scomm
		   ,sum(b.BetCount) BetCount
		   ,SUM(b.agrosscomm) agrosscomm
		   ,SUM(b.anetTurnover) AS netTurnover
		   ,SUM(TurnoverNoDraw) AS TurnoverNoDraw,
			SUM(ExtraWinloss) AS ExtraWinloss,
			SUM(ExtraComm) AS ExtraComm
		
		FROM #sum_winloss_tmp b WITH (NOLOCK)
		GROUP BY b.recommend
				,b.productId
				,b.sporttype
				,b.bettype
				,b.leagueGroupID
				,b.ticketType

		---- Master
		INSERT INTO #bettrans_compact_tmp
		(
			winlostdate, roleid, custid,productid, Sporttype, bettype, leagueGroupID, ticketType,
			turnover, winlost, awinlost, mwinlost, swinlost,
			playercomm, comm, acomm, scomm, betcount, grosscomm, netTurnover, TurnoverNoDraw, ExtraWinloss, ExtraComm
		)
		SELECT
			@winlostdate
		   ,3
		   ,b.mrecommend
		   ,productId
		   ,sporttype
		   ,bettype
		   ,b.leagueGroupID
		   ,b.ticketType
		   ,SUM(turnover) TurnOver
		   ,SUM(winlost) winlost
		   ,SUM(awinlost) awinlost
		   ,SUM(mwinlost) mwinlost
		   ,SUM(b.swinlost) swinlost
		   ,SUM(playercomm) playercomm
		   ,SUM(comm) comm
		   ,SUM(acomm) acomm
		   ,SUM(ISNULL(scomm, 0)) scomm
		   ,sum(b.BetCount) BetCount
		   ,SUM(b.mgrosscomm) mgrosscomm
	   
		   ,SUM(b.mnetTurnover) AS netTurnover
		   ,SUM(b.TurnoverNoDraw) AS TurnoverNoDraw,
			SUM(ExtraWinloss) AS ExtraWinloss,
			SUM(ExtraComm) AS ExtraComm
	   
		FROM #sum_winloss_tmp b WITH (NOLOCK)
		GROUP BY b.mrecommend
				,b.productId
				,b.sporttype
				,b.bettype
				,b.leagueGroupID
				,b.ticketType

		---- Super
		INSERT INTO #bettrans_compact_tmp
		(
			winlostdate, roleid, custid, productid , Sporttype, bettype, leagueGroupID, ticketType,
			turnover, winlost, awinlost, mwinlost, swinlost,
			playercomm, comm, acomm, scomm, betcount, grosscomm, netTurnover, TurnoverNoDraw, ExtraWinloss, ExtraComm
		)
		SELECT
			@winlostdate
		   ,4
		   ,b.srecommend
		   ,b.productId
		   ,sporttype
		   ,bettype
		   ,b.leagueGroupID
		   ,b.ticketType
		   ,SUM(turnover) TurnOver
		   ,SUM(winlost) winlost
		   ,SUM(awinlost) awinlost
		   ,SUM(mwinlost) mwinlost
		   ,SUM(b.swinlost) swinlost
		   ,SUM(playercomm) playercomm
		   ,SUM(comm) comm
		   ,SUM(acomm) acomm
		   ,SUM(ISNULL(scomm, 0)) scomm
		   ,sum(b.BetCount) BetCount
		   ,SUM(b.sgrosscomm) sgrosscomm
		   ,SUM(b.snetTurnover) AS netTurnover
		   ,SUM(b.TurnoverNoDraw) AS TurnoverNoDraw,
			SUM(ExtraWinloss) AS ExtraWinloss,
			SUM(ExtraComm) AS ExtraComm

		FROM #sum_winloss_tmp b WITH (NOLOCK)
		GROUP BY b.srecommend
				,b.productId
				,b.sporttype
				,b.bettype
				,b.leagueGroupID
				,b.ticketType;

		--select top 10 *, count(1) over() as totalRow from #bettrans_compact_tmp up
			
		--TODO: check sum
		--SELECT top(100) tmp.netTurnover, up.netTurnover, up.betcount
		--FROM [dbo].[bettrans_compact] up
		--INNER JOIN #bettrans_compact_tmp tmp ON up.[custid] = tmp.[custid]
	 --       AND up.[winlostdate] = tmp.[winlostdate]
	 --       AND up.[productId] = tmp.[productId]
	 --       AND up.[sporttype] = tmp.[sporttype]
	 --       AND up.[bettype] = tmp.[bettype]
	 --       AND up.[leagueGroupID] = tmp.[leagueGroupID]
	 --       AND up.[ticketType] = tmp.[ticketType]
		--WHERE CHECKSUM(CONCAT_WS('|',up.betcount,up.winlost,up.turnover,up.netTurnover,up.awinlost,up.mwinlost,up.swinlost,up.playercomm,up.comm,up.acomm,up.scomm,up.TurnoverNoDraw,up.grosscomm))
		--	<> CHECKSUM(CONCAT_WS('|',tmp.betcount,tmp.winlost,tmp.turnover,tmp.netTurnover,tmp.awinlost,tmp.mwinlost,tmp.swinlost,tmp.playercomm,tmp.comm,tmp.acomm,tmp.scomm,tmp.TurnoverNoDraw,tmp.grosscomm))
		
		--TODO: INSERT [bettrans_compact]
		INSERT INTO [dbo].[bettrans_compact]
			([custid]
			,[winlostdate]
			,[productId]
			,[sporttype]
			,[bettype]
			,[leagueGroupID]
			,[ticketType]
			,[betcount]
			,[turnover]
			,[netTurnover]
			,[TurnoverNoDraw]
			,[winlost]
			,[awinlost]
			,[mwinlost]
			,[swinlost]
			,[playercomm]
			,[comm]
			,[acomm]
			,[scomm]
			,[grosscomm]
			,[extraWinloss]
			,[extraComm])
		SELECT tmp.[custid]
			,tmp.[winlostdate]
			,tmp.[productId]
			,tmp.[sporttype]
			,tmp.[bettype]
			,tmp.[leagueGroupID]
			,tmp.[ticketType]
			,tmp.[betcount]
			,tmp.[turnover]
			,tmp.[netTurnover]
			,tmp.[TurnoverNoDraw]
			,tmp.[winlost]
			,tmp.[awinlost]
			,tmp.[mwinlost]
			,tmp.[swinlost]
			,tmp.[playercomm]
			,tmp.[comm]
			,tmp.[acomm]
			,tmp.[scomm]
			,tmp.[grosscomm]
			,tmp.[extraWinloss]
			,tmp.[extraComm]
		FROM #bettrans_compact_tmp tmp
		WHERE tmp.[betcount] > 0
		;

		SET @message = CONCAT(@@SERVERNAME, '_',db_name(), ' - Completed bettrans_compact winlostdate: ', FORMAT(@winlostdate, 'yyyy-MM-dd HH:mm:ss'), ', duration:', DATEDIFF(SECOND, @startTime, CURRENT_TIMESTAMP));
		RAISERROR (@message, 0, 1) WITH NOWAIT;

		--TODO: Loop next @winlostdate
		SET @winlostdate = DATEADD(DAY, 1, @winlostdate)
	END
END
GO