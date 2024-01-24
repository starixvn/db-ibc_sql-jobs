/*<info serverAlias="DBAGE-bodb_AGE" isNested="0"></info>*/
/*
	Created by: 20231201@Bobby
	Task: 153357 - Alpha - CDC bettrans_compact - GEN data
	DB: DBAGE.bodb_AGE
	Revisions:
		- 20240116@Bobby: CheckSum data from bettrans
		
*/

use bodb02;

declare 
	@winlostdate datetime = '2024-01-16' --6794
BEGIN

	SET NOCOUNT ON

	DECLARE @NetTO_CutOffDate SMALLDATETIME, @GrossComm_CutOffDate SMALLDATETIME, @SabaInfo_CutOffDate SMALLDATETIME

	SELECT  @NetTO_CutOffDate = CASE WHEN f.TypeName = 'NetTO' THEN f.CutoffDate ELSE @NetTO_CutOffDate END
			,@GrossComm_CutOffDate = CASE WHEN f.TypeName = 'GrossComm' THEN f.CutoffDate ELSE @NetTO_CutOffDate END
			,@SabaInfo_CutOffDate = CASE WHEN f.TypeName = 'SabaSport' THEN f.CutoffDate ELSE @SabaInfo_CutOffDate END
	FROM dbo.f_GetCutOffDate() f
	WHERE f.TypeName IN ('NetTO', 'GrossComm','SabaSport')

	---- get extra PT from table setting
	DROP TABLE IF EXISTS #__SuperExtraPT
	CREATE TABLE #__SuperExtraPT(productId INT, bettypePT INT, SuperId INT, ExtraPT MONEY, RefTable TINYINT, IsUsingOddsSpread BIT, IsContributionBettype BIT)
	CREATE CLUSTERED INDEX CIX_#__SuperExtraPT ON #__SuperExtraPT(SuperId, bettypePT)

	;WITH rs AS 
	(
		SELECT DISTINCT b.bettype , b.srecommend
		FROM dbo.bettrans b WITH(NOLOCK) 
		LEFT JOIN dbo.Dep_CustSuper cs WITH(NOLOCK) ON cs.custid = b.srecommend
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
			FROM f_SportBettypeMatrix_Sel(0, 0, b.bettype, 2, '', '', 0) tbl
			WHERE b.bettype = tbl.bettype 
				--and  tbl.RefTable not in (1,2)
		) tbl
		OUTER APPLY 
		(
			SELECT DISTINCT expt2.SuperId, expt2.ExtraPT
			FROM dbo.Acc_GroupExtraPT2Setting expt2 WITH (NOLOCK)
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

	DROP TABLE IF EXISTS #sum_winloss_CheckSum;
	CREATE TABLE #sum_winloss_CheckSum (
		[winlostdate] [smalldatetime] NOT NULL,
		[custid] [int] NOT NULL,
		[productid] [tinyint] NOT NULL,
		[sporttype] [int] NOT NULL,
		[bettype] [int] NOT NULL,
		[leagueGroupID] [int] NOT NULL,
		[ticketType] [int] NOT NULL,
		[BetCount] [int] NULL,
		[turnover] [money] NULL,
		[netTurnover] [money] NOT NULL,
		[TurnoverNoDraw] [money] NULL,
		[winlost] [money] NULL,
		[awinlost] [money] NULL,
		[mwinlost] [money] NULL,
		[swinlost] [money] NULL,
		[playercomm] [money] NULL,
		[comm] [money] NULL,
		[acomm] [money] NULL,
		[scomm] [money] NULL,
		[grosscomm] [money] NULL,
		[ExtraWinloss] [money] NULL,
		[ExtraComm] [money] NULL
	);
	--insert to main table
	--member 
	INSERT INTO #sum_winloss_CheckSum
	(
		winlostdate, custid, productid, sporttype, bettype, leagueGroupID, ticketType
		,betcount, turnover, netTurnover, TurnoverNoDraw, winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, grosscomm, ExtraWinloss, ExtraComm
	)
	---- gen all data
	SELECT
		b.winlostdate, cal.custid, b.productid, b.sporttype, b.bettype, b.leagueGroupID, b.ticketType
		, SUM(cal.betcount) AS betcount
		, SUM(cal.turnover) AS turnover
		, SUM(cal.netTurnover) AS netTurnover
		, SUM(cal.TurnoverNoDraw) AS TurnoverNoDraw
		, SUM(cal.winlost) AS winlost
		, SUM(cal.awinlost) AS awinlost
		, SUM(cal.mwinlost) AS mwinlost
		, SUM(cal.swinlost) AS swinlost
		, SUM(cal.playercomm) AS playercomm
		, SUM(cal.comm) AS comm
		, SUM(cal.acomm) AS acomm
		, SUM(cal.scomm) AS scomm
		, SUM(cal.grosscomm) AS grosscomm
		, SUM(cal.ExtraWinloss) AS ExtraWinloss
		, SUM(cal.ExtraComm) AS ExtraComm
	FROM (
		SELECT
			winlostdate
		   ,bettrans.custid
		   ,bettrans.recommend
		   ,bettrans.mrecommend
		   ,bettrans.srecommend
		   ,tbl.productId
		   ,ck.sporttype
		   ,bettrans.bettype
		   ,ck.LeagueGroupID
		   ,ck.ticketType
		   ,COUNT(1) BetCount
		   ,SUM(ABS(stake)) Turnover
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
			END) AS TurnoverNoDraw
		   ,SUM(winlost - actual_stake) winlost
		   ,SUM(awinlost) awinlost
		   ,SUM(mwinlost) mwinlost
		   ,SUM(ISNULL(swinlost, 0)) swinlost
		   ,SUM(playercomm) playercomm
		   ,SUM(comm) comm
		   ,SUM(acomm) acomm
		   ,SUM(ISNULL(scomm, 0)) scomm
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
			,-1 * SUM(
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
				) AS ExtraWinloss
			,-1 * SUM(CASE 
						/*IBCBet Live Casino*/
						WHEN bettrans.bettype BETWEEN 3201 AND 3299 THEN bettrans.scomm
						WHEN bettrans.bettype IN (2198, 2398, 2998, 2199, 2399, 2999, 4297, 4298, 4599, 4600) THEN 0
						ELSE 
							CASE 
								WHEN bettrans.tpositiontaking = 1 THEN 0 
								ELSE bettrans.scomm / (1 - bettrans.tpositiontaking)
							END * CASE WHEN tbl.ExtraPT IS NOT NULL THEN tbl.ExtraPT ELSE ISNULL(bettrans.epositiontaking, 0) END
					END
				) AS ExtraComm
		FROM dbo.bettrans bettrans WITH (NOLOCK)
			INNER JOIN #__SuperExtraPT tbl ON bettrans.srecommend = tbl.SuperId	AND bettrans.bettype = tbl.bettypePT
			LEFT JOIN dbo.[match] m WITH(NOLOCK) ON bettrans.matchid = m.matchid AND m.sporttype IN (1, 2, 5, 43, 50)
			LEFT JOIN dbo.League l WITH(NOLOCK) ON m.leagueid=l.leagueid AND l.LeagueGroupID IN (42,74,108,113,122,151)
			CROSS APPLY (
				SELECT 
					CASE WHEN  bettrans.betdaqid <> -2 AND l.LeagueGroupID > 0 THEN ISNULL(m.sporttype, 0) ELSE 0 END AS sporttype
					,CASE WHEN bettrans.betdaqid <> -2 AND m.sporttype > 0 THEN ISNULL(l.LeagueGroupID,0) ELSE 0 END AS LeagueGroupID
					,CASE WHEN bettrans.betdaqid = -2 THEN 1 ELSE 0 END ticketType
			) AS ck
		WHERE 
			bettrans.winlostdate = @winlostdate
			AND bettrans.statusID IN (111, 112, 113)
		GROUP BY winlostdate
		   ,bettrans.custid
		   ,bettrans.recommend
		   ,bettrans.mrecommend
		   ,bettrans.srecommend
		   ,tbl.productId
		   ,ck.sporttype
		   ,bettrans.bettype
		   ,ck.LeagueGroupID
		   ,ck.ticketType
		
	) AS b
	CROSS APPLY (
			SELECT custid, turnover, netTurnover, TurnoverNoDraw, winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, betcount, grosscomm, ExtraWinloss, ExtraComm
			UNION ALL
			SELECT recommend, turnover, anetTurnover, TurnoverNoDraw, winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, betcount, agrosscomm, ExtraWinloss, ExtraComm
			UNION ALL
			SELECT mrecommend, turnover, mnetTurnover, TurnoverNoDraw, winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, betcount, mgrosscomm, ExtraWinloss, ExtraComm
			UNION ALL
			SELECT srecommend, turnover, snetTurnover, TurnoverNoDraw, winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, betcount, sgrosscomm, ExtraWinloss, ExtraComm
	) AS cal (custid, turnover, netTurnover, TurnoverNoDraw, winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, betcount, grosscomm, ExtraWinloss, ExtraComm)
	GROUP BY b.winlostdate
		, cal.custid
		, b.productid
		, b.sporttype
		, b.bettype
		, b.leagueGroupID
		, b.ticketType

	--TODO: check data
	--select custid, winlostdate, productid, sporttype, bettype, LeagueGroupID, ticketType,betcount, turnover,netTurnover,TurnoverNoDraw,winlost,awinlost, mwinlost,swinlost,playercomm,comm,acomm,scomm,grosscomm, ExtraWinloss,ExtraComm
	--from #sum_winloss_CheckSum where custid=7178176 and bettype=219

	--select * from bodb_AGE.dbo.bettrans_compact where custid=7178176 and winlostdate=@winlostdate and bettype=219

	--TODO: checkSUM & bettrans_compact
	;with bt_checksum AS (
		select cal.custid, cal.productid, cal.sporttype, cal.bettype, cal.LeagueGroupID, cal.ticketType
			--, (betcount) AS betcount, (netTurnover) AS netTurnover, (winlost) AS winlost
			, (CHECKSUM(CONCAT_WS('|',betcount,	winlost, turnover,netTurnover,
				awinlost, mwinlost,swinlost,playercomm,comm,acomm,scomm,TurnoverNoDraw,grosscomm))) AS checkSumData

		from #sum_winloss_CheckSum cal 
		--group by cal.custid, cal.productid, sporttype, cal.bettype, cal.LeagueGroupID, cal.ticketType
	), compact_checkSum AS (
		select custid, b.productId, b.sporttype, bettype, LeagueGroupID, ticketType
			--, (betcount) AS betcount, (netTurnover) AS netTurnover, (winlost) AS winlost
			, (CHECKSUM(CONCAT_WS('|',betcount,	winlost, turnover,netTurnover,
				awinlost, mwinlost,swinlost,playercomm,comm,acomm,scomm,TurnoverNoDraw,grosscomm))) AS checkSumData 
		
		from bodb_AGE.dbo.bettrans_compact b with(nolock)
		where b.winlostdate = @winlostdate 
			and b.betcount > 0
		--group by custid, b.productId, b.sporttype, bettype, LeagueGroupID, ticketType
	)
	select bt.*, 'xxxx',ck.*
	--select distinct sb.RefTable
	from  bt_checksum bt
	--inner join (select distinct BetType, RefTable from SportBettypeMatrix with(nolock)) sb on sb.BetType = bt.bettype
	full join compact_checkSum ck on ck.custid = bt.custid 
		and ck.ProductID = bt.ProductID
		and ck.sporttype = bt.sporttype
		and ck.bettype = bt.bettype
		and ck.LeagueGroupID = bt.LeagueGroupID
		and ck.ticketType = bt.ticketType
	--where ck.checkSumData = bt.checkSumData
	where (bt.custid is null or ck.custid is null or ck.checkSumData <> bt.checkSumData)

END
GO