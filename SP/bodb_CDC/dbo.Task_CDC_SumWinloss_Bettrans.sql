/*<info serverAlias="DBAGE-bodb02" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_CDC_Process_Bettrans_compact]
AS
/*
	Created by: 20231201@Bobby
	Task: 153357 - Alpha - CDC bettrans_compact
	DB: DBAGE.bodb02
	Revisions:
		
*/

BEGIN

	SET NOCOUNT ON;

	DECLARE @lastRowId	BIGINT = 0 --515426
		, @maxRowId		bigint = 0 --1070646
		, @batchSize	INT = 500
		, @batchCount	INT
		, @sysVName		VARCHAR(200) = 'Age_cdc_bettrans_compact'
		, @sysVValue	VARCHAR(200) = '';

	DECLARE @startTime DATETIME, @loopCnt INT = 1, @message VARCHAR(500)
		, @minActiondate DATETIME
		, @maxActiondate DATETIME;
	
	SELECT @sysVValue = VValue
	FROM dbo.SystemSettings WITH(NOLOCK)
	WHERE VName=@sysVName;

	SELECT @lastRowId = CAST(JSON_VALUE(@sysVValue, '$.lastRowId') AS BIGINT)

	SELECT @maxRowId		= MAX(rowid)
		, @minActiondate	= MIN(Actiondate)
		, @maxActiondate	= MAX(Actiondate)
	FROM dbo.cdc_bettrans WITH(ROWLOCK)
	WHERE rowid > @lastRowId;

	DROP TABLE IF EXISTS #bettrans_compact_tmp;
	CREATE TABLE #bettrans_compact_tmp(
		[custid] [int] NOT NULL,
		[winlostdate] [smalldatetime] NOT NULL,
		[productId] [tinyint] NOT NULL,
		[sporttype] [int] NOT NULL,
		[bettype] [smallint] NOT NULL,
		[leagueGroupID] [int] NOT NULL,
		[ticketType] [int] NOT NULL,
		[betcount] [int] NULL,
		[turnover] [money] NULL,
		[netTurnover] [money] NULL,
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
		[extraWinloss] [decimal](38, 6) NULL,
		[extraComm] [decimal](38, 6) NULL
	);
	CREATE CLUSTERED INDEX [CIX_#bettrans_compact_tmp] ON #bettrans_compact_tmp
	(
		[custid] ASC,
		[winlostdate] ASC,
		[productId] ASC,
		[sporttype] ASC,
		[bettype] ASC,
		[leagueGroupID] ASC,
		[ticketType] ASC
	);

	DROP TABLE IF EXISTS #merge_update_tmp;
	CREATE TABLE #merge_update_tmp (
		[custid] INT
        ,[winlostdate] SMALLDATETIME
        ,[productId] SMALLINT
        ,[sporttype] SMALLINT
        ,[bettype] INT
        ,[leagueGroupID] INT
        ,[ticketType] TINYINT
	);

	SET @startTime = CURRENT_TIMESTAMP;

	WHILE (@lastRowId <= @maxRowId)
	BEGIN
		
		DELETE dbo.cdc_bettrans_batch;
		DELETE #merge_update_tmp;
		DELETE #bettrans_compact_tmp;
		
		INSERT INTO dbo.cdc_bettrans_batch
		SELECT TOP (@batchSize)
		--SELECT
			[rowId]
			,[__$operation] AS cmdType
			,[__$command_id] AS cmdId
			,[__$start_lsn] AS cmdTxn
			,[transid]
			,[custid],[recommend],[mrecommend],[srecommend]
			,[odds]
			,[winlostdate]
			,[bettype]
			,[stake]
			,[actual_stake]
			,[winlost]
			,[awinlost]
			,[mwinlost]
			,[swinlost]
			,[playercomm]
			,[comm]
			,[acomm]
			,[scomm]
			,[apositiontaking]
			,[mpositiontaking]
			,[spositiontaking]
			,[tpositiontaking]
			,[epositiontaking]
			,IIF([status] IN ('running','waiting'),0,[statusID]) [statusID]
			,[modds]
			,[oddsspread]
			,[betid]
			,[betdaqid]
			,[matchid]
			,[actiondate]
		FROM [dbo].[cdc_bettrans] WITH(NOLOCK)
		WHERE rowId > @lastRowId AND rowId <= @maxRowId
		ORDER BY rowId ASC;

		SET @batchCount = @@ROWCOUNT;
		IF (@batchCount = 0) GOTO END_PROCESS;

		;WITH refSuper AS 
		(
			SELECT DISTINCT b.srecommend, b.winlostdate, b.bettype
			FROM dbo.cdc_bettrans_batch b WITH(NOLOCK)
			LEFT JOIN bodb02.dbo.Dep_CustSuper cs WITH(NOLOCK) ON cs.custid = b.srecommend
			WHERE cs.custid IS NULL
		)
		,SuperExtraPT AS (
			SELECT tbl.ProductID, b.bettype, b.srecommend, b.winlostdate, T.ExtraPT, tbl.RefTable
				, tbl.IsUsingOddsSpread, CASE WHEN cont.Bettype IS NOT NULL THEN 1 ELSE 0 END AS IsContributionBettype
			FROM refSuper b 
			CROSS APPLY 
			(
				SELECT DISTINCT
					tbl.ProductID, tbl.RefTable, CASE WHEN tbl.RefTable IN (1,2) OR tbl.ProductID = 47 THEN 1 ELSE 0 END IsUsingOddsSpread
				FROM bodb02.dbo.f_SportBettypeMatrix_Sel(0, 0, b.bettype, 2, '', '', 0) tbl
				WHERE b.bettype = tbl.bettype
			) AS tbl
			OUTER APPLY 
			(
				SELECT DISTINCT expt2.SuperId, expt2.ExtraPT
				FROM bodb02.dbo.Acc_GroupExtraPT2Setting expt2 WITH (NOLOCK)
				WHERE b.winlostdate BETWEEN expt2.FromDate AND expt2.ToDate
						AND tbl.ProductID = expt2.ProductID
						AND b.srecommend = expt2.SuperId 
						AND ISNULL(expt2.SubProduct,'') = ''
						AND expt2.Sporttype = 0
			) AS t
			OUTER APPLY 
			(
				SELECT f.Bettype
				FROM bodb02.dbo.f_BettypePrizeGroup() f
				WHERE f.BettypeGroup = 'Contribution'
					AND f.Bettype = b.bettype
			) AS cont
		),
		sum_winloss_tmp AS (
			SELECT b.rowId 
			   ,b.transid
			   ,b.custid, b.recommend, b.mrecommend, b.srecommend
			   ,b.winlostdate
			   ,tbl.productId
			   ,ck.sporttype
			   ,b.bettype
			   ,CASE WHEN betdaqid <> -2 THEN ISNULL(l.LeagueGroupID,0) ELSE 0 END AS LeagueGroupID
			   ,CASE WHEN b.betdaqid = -2 THEN 1 ELSE 0 END ticketType
			   ,b.cmdType, b.cmdId, b.cmdTxn
			   ,b.statusID
			   ,ABS(stake) Turnover
			   ,IIF(b.statusId IN(0,1), 0, (winlost - actual_stake)) winlost
			   ,IIF(b.statusId IN(0,1), 0, awinlost) awinlost
			   ,IIF(b.statusId IN(0,1), 0, mwinlost) mwinlost
			   ,IIF(b.statusId IN(0,1), 0, ISNULL(swinlost, 0)) swinlost
			   ,IIF(b.statusId IN(0,1), 0, playercomm) playercomm
			   ,IIF(b.statusId IN(0,1), 0, comm) comm
			   ,IIF(b.statusId IN(0,1), 0, acomm) acomm
			   ,IIF(b.statusId IN(0,1), 0, ISNULL(scomm, 0)) scomm
			   ,(1) BetCount
			   ,(CASE
					WHEN statusId IN(0,1) THEN 0
					WHEN tbl.RefTable IN (1, 2) THEN 0
					WHEN apositiontaking = 1 THEN 0
					ELSE ISNULL(comm / (1 - apositiontaking), 0)
				END) grosscomm
				,(CASE
					WHEN statusId IN(0,1) THEN 0
					WHEN tbl.RefTable IN (1, 2) THEN 0
					WHEN apositiontaking + mpositiontaking = 1 THEN 0
					ELSE ISNULL(acomm / (1 - apositiontaking - mpositiontaking), 0)
				END) agrosscomm
				,(CASE
					WHEN statusId IN(0,1) THEN 0
					WHEN tbl.RefTable IN (1, 2) THEN 0
					WHEN tpositiontaking = 1 THEN 0
					ELSE scomm / (1 - tpositiontaking)
				END) mgrosscomm
				,(CASE
					WHEN statusId IN(0,1) THEN 0
					WHEN tbl.RefTable IN (1, 2) THEN 0
					WHEN tpositiontaking = 1 THEN 0
					ELSE scomm / (1 - tpositiontaking)
				END) sgrosscomm
	  
			   ,0 AS netTurnover
			   ,(ABS(stake) * apositiontaking) AS anetTurnover
			   ,(ABS(stake) * mpositiontaking) AS mnetTurnover
			   ,(ABS(stake) * spositiontaking) AS snetTurnover
			   ,(CASE
					when statusID in (0,1,101,102,103) then 0
					WHEN statusID IN (112, 113) AND
						modds IN (-0.25, 0.25)
						---- Sportsbook
						AND (b.bettype < 999 OR
						b.bettype BETWEEN 1301 AND 1399 OR--Sporting Solution
						b.bettype BETWEEN 9001 AND 9399 OR--E-Sports
						b.bettype BETWEEN 9400 AND 9998) AND --Cricket AIO
						b.bettype NOT IN (71, 72) AND
						b.bettype NOT BETWEEN 81 AND 120 THEN ABS(stake) / 2
					WHEN statusID = 111 AND
						(
						---- Sportsbook
						(b.bettype < 999 OR
						b.bettype BETWEEN 1301 AND 1399 OR--Sporting Solution
						b.bettype BETWEEN 9001 AND 9399 OR--E-Sports
						b.bettype BETWEEN 9400 AND 9998) AND--Cricket AIO
						b.bettype NOT IN (71, 72) AND
						b.bettype NOT BETWEEN 81 AND 120
						) THEN 0
					WHEN tbl.productId = 47 THEN b.oddsspread -- BBIN
					WHEN tbl.RefTable IN (1, 2) THEN 0
					WHEN tbl.RefTable IN (1, 2) THEN
						CASE WHEN tbl.IsContributionBettype = 0 THEN b.oddsspread ELSE 0 END
					ELSE ABS(stake)
				END) AS TurnoverNoDraw,
				-1 * (
						CASE
							WHEN statusId IN(0,1) THEN 0
							-- Jackpot
							WHEN b.bettype IN (2198, 2398, 2998, 4297, 4599) THEN
								CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE ISNULL(b.betid/CONVERT(DECIMAL(19,8), 100000000), 0) END
							WHEN b.bettype IN (2199, 2399, 2999, 4298, 4600) THEN 0
							ELSE CASE WHEN b.tpositiontaking = 1 THEN 0 ELSE b.winlost - b.actual_stake END
						END * IIF(tbl.ExtraPT IS NOT NULL, tbl.ExtraPT, ISNULL(b.epositiontaking, 0)) 
					) AS ExtraWinloss,
				-1 * (CASE 
							WHEN statusId IN(0,1) THEN 0
							/*IBCBet Live Casino*/
							WHEN b.bettype BETWEEN 3201 AND 3299 THEN b.scomm
							WHEN b.bettype IN (2198, 2398, 2998, 2199, 2399, 2999, 4297, 4298, 4599, 4600) THEN 0
							ELSE 
								CASE 
									WHEN b.tpositiontaking = 1 THEN 0 
									ELSE b.scomm / (1 - b.tpositiontaking)
								END * IIF(tbl.ExtraPT IS NOT NULL, tbl.ExtraPT, ISNULL(b.epositiontaking, 0)) 
						END
					) AS ExtraComm
		  
			FROM dbo.cdc_bettrans_batch b WITH(ROWLOCK)
			INNER JOIN SuperExtraPT tbl ON b.srecommend = tbl.srecommend AND b.bettype = tbl.bettype and b.winlostdate = tbl.winlostdate
			LEFT JOIN bodb02.dbo.match m WITH(NOLOCK) ON b.matchid = m.matchid
			LEFT JOIN bodb02.dbo.League l WITH(NOLOCK) ON m.leagueid=l.leagueid AND l.LeagueGroupID IN (42,74,108,113,122,151)
			CROSS APPLY (
				SELECT 
					CASE WHEN ( 
						(l.LeagueGroupID IN (42,74,108,113) AND m.sporttype = 1 ) 
							OR (l.LeagueGroupID IN (122, 42) AND m.sporttype = 2 )
							OR (l.LeagueGroupID = 42 AND m.sporttype = 50)
							OR (l.LeagueGroupID = 42 AND m.sporttype = 5) --SabaTennis
							OR (l.LeagueGroupID = 151 AND m.sporttype = 43)
						) AND betdaqid <> -2 THEN m.sporttype
					WHEN b.bettype BETWEEN 81 AND 120 OR -- Number Game 
						b.bettype BETWEEN 8101 AND 8120 OR -- Happy 5 
						b.bettype BETWEEN 3601 AND 3610 THEN 161 -- Happy 5 Linked Games
					WHEN b.bettype BETWEEN 1201 AND 1299 THEN 180 -- Virtual Sport
					WHEN b.bettype BETWEEN 2700 AND 2899 THEN 190 -- Betradar Virtual Sport
					WHEN b.bettype IN (71, 72) THEN 251
					WHEN b.bettype BETWEEN 1501 AND 1599 THEN 202 -- Keno
					WHEN b.bettype BETWEEN 1021 AND 1099 THEN 220 -- Keno Lottery
					WHEN b.bettype BETWEEN 1700 AND 1799 THEN 255 -- Gold Deluxe
					WHEN b.bettype BETWEEN 1800 AND 1899 THEN 250 --- AG Casino 
					WHEN b.bettype = 1900 THEN 249 --- Vegas Games 
					WHEN b.bettype BETWEEN 18000 AND 18099 THEN 204 --- Colossus Bets
					WHEN b.bettype BETWEEN 2101 AND 2199 THEN 208
					WHEN b.bettype BETWEEN 2201 AND 2299 THEN 209
					WHEN b.bettype BETWEEN 2301 AND 2399 OR
						b.bettype BETWEEN 2901 AND 2999 THEN 210
					WHEN b.bettype BETWEEN 2401 AND 2499 THEN 211 --- Allbet
					WHEN b.bettype BETWEEN 4001 AND 4100 OR 
						b.bettype BETWEEN 5800 AND 5999 THEN 212 -- Voidbridge
					WHEN b.bettype BETWEEN 4101 AND 4300 OR 
						b.bettype BETWEEN 6701 AND 7000 THEN 248 -- Pragmatic
					WHEN b.bettype BETWEEN 2501 AND 2699 THEN 213 --NG2 -
					WHEN b.bettype BETWEEN 1011 AND 1020 THEN 219 --Fishing World -
					WHEN b.bettype BETWEEN 8000 AND 8099 THEN 221 -- Exchange
					WHEN b.bettype BETWEEN 1901 AND 1999 THEN 165 -- Card Club
					WHEN b.bettype BETWEEN 4301 AND 4600 THEN 247 -- Spadegaming
					WHEN b.bettype BETWEEN 4601 AND 4900 THEN 245 -- Virtual Games
					WHEN b.bettype BETWEEN 1611 AND 1699 THEN 200 -- Saba.Club
					WHEN b.bettype BETWEEN 3001 AND 3099 THEN 244 -- SA Gaming
					WHEN b.bettype BETWEEN 3101 AND 3150 THEN 243 -- AE Casino
					WHEN b.bettype BETWEEN 5001 AND 5099 THEN 223 -- Indo 4D
					WHEN b.bettype BETWEEN 4901 AND 5000 THEN 222 -- Table Games	
					WHEN b.bettype BETWEEN 3300 AND 3399 THEN 241 -- BBIN	
					WHEN b.bettype BETWEEN 3201 AND 3299 THEN 242 -- IBCBet Live Casino		
					WHEN b.bettype BETWEEN 5601 AND 5699 THEN 225 -- ION					
					WHEN b.bettype BETWEEN 5500 AND 5599 THEN 224 -- RNG War		
					WHEN b.bettype BETWEEN 6001 AND 6300 THEN 232 -- PG Soft
					WHEN b.bettype BETWEEN 6401 AND 6700 THEN 234-- Joker
					WHEN b.bettype BETWEEN 3401 AND 3499 THEN 233 -- WM
					WHEN b.bettype BETWEEN 5701 AND 5799 THEN 236 -- GDG
					WHEN b.bettype = 5301 THEN 231 -- Virtual Sports 3
					WHEN b.bettype BETWEEN 3501 AND 3599 THEN 239 -- BG
					WHEN b.bettype BETWEEN 5401 AND 5499 THEN 237 -- MaxGame
					WHEN b.bettype BETWEEN 17000 AND 17030 THEN 246 -- Saba promotion
					WHEN b.bettype BETWEEN 3611 AND 3620 THEN 169 -- Sports Lottery
					WHEN b.bettype BETWEEN 3701 AND 3799 THEN 170 -- PP Live Casino
					WHEN b.bettype BETWEEN 7001 AND 7300 THEN 238 -- Habanero
					WHEN b.bettype BETWEEN 7301 AND 7600 THEN 167 -- Creative Gaming
					WHEN b.bettype BETWEEN 3801 AND 3899 THEN 171 -- VGaming 
					WHEN b.bettype BETWEEN 7801 AND 7899 THEN 174 -- AdvantPlay Mini
					WHEN b.bettype BETWEEN 7701 AND 7799 THEN 172 -- AdvantPlay Product
					WHEN b.bettype BETWEEN 7901 AND 7999 THEN 175 -- Bitcoin Product
					WHEN b.bettype BETWEEN 8201 AND 8299 THEN 176 -- FGG Product
					WHEN b.bettype BETWEEN 8900 AND 8999 THEN 156 -- SEAL Entertainment
					WHEN b.bettype BETWEEN 8400 AND 8699 THEN 155 -- Microgaming
					WHEN b.bettype BETWEEN 5100 AND 5299 THEN 158 -- Jili
					WHEN b.bettype BETWEEN 3151 AND 3200 THEN 159 -- YeeBet
					WHEN b.bettype BETWEEN 5302 AND 5399 THEN 178 -- VS3-LeapGaming(New)
					ELSE 0
				END AS sporttype
			) AS ck
		)
		INSERT INTO #bettrans_compact_tmp
		SELECT cal.custid, pre.winlostdate, tmp.productId, tmp.sporttype, tmp.bettype, tmp.leagueGroupID, tmp.ticketType
			,SUM(cal.betcount) AS betcount
			,SUM(cal.turnover) AS turnover
			,SUM(cal.netTurnover) AS netTurnover
			,SUM(cal.TurnoverNoDraw) AS TurnoverNoDraw
			,SUM(cal.winlost) AS winlost
			,SUM(cal.awinlost) AS awinlost
			,SUM(cal.mwinlost) AS mwinlost
			,SUM(cal.swinlost) AS swinlost
			,SUM(cal.playercomm) AS playercomm
			,SUM(cal.comm) AS comm
			,SUM(cal.acomm) AS acomm
			,SUM(cal.scomm) AS scomm
			,SUM(cal.grosscomm) AS grosscomm
			,SUM(cal.ExtraWinloss) AS extraWinloss
			,SUM(cal.ExtraComm) AS extraComm
		FROM sum_winloss_tmp AS tmp
		LEFT JOIN sum_winloss_tmp AS old ON old.transid = tmp.transid and old.cmdId = tmp.cmdId and old.rowId < tmp.rowId AND old.cmdType IN (3) and old.cmdTxn =  tmp.cmdTxn
		CROSS APPLY (
			SELECT tmp.winlostdate, tmp.BetCount, tmp.turnover, tmp.netTurnover, tmp.anetTurnover, tmp.mnetTurnover, tmp.snetTurnover, tmp.TurnoverNoDraw, tmp.winlost, tmp.awinlost, tmp.mwinlost, tmp.swinlost
				, tmp.playercomm, tmp.comm, tmp.acomm, tmp.scomm, tmp.grosscomm, tmp.agrosscomm, tmp.mgrosscomm, tmp.sgrosscomm, tmp.ExtraWinloss, tmp.ExtraComm
				, CASE WHEN old.transid > 0 AND old.winlostdate <> tmp.winlostdate THEN 2 ELSE tmp.cmdType END AS cmdType, tmp.statusID
			UNION ALL
			SELECT old.winlostdate, old.BetCount, old.turnover, old.netTurnover, old.anetTurnover, old.mnetTurnover, old.snetTurnover, old.TurnoverNoDraw, old.winlost, old.awinlost, old.mwinlost, old.swinlost
				, old.playercomm, old.comm, old.acomm, old.scomm, old.grosscomm, old.agrosscomm, old.mgrosscomm, old.sgrosscomm, old.ExtraWinloss, old.ExtraComm
				, 1 AS cmdType, old.statusID
			WHERE old.transid > 0 AND old.winlostdate <> tmp.winlostdate
		) AS pre
		CROSS APPLY (
			SELECT 
				case 
					when pre.cmdType IN (1) and pre.statusID in (111,112,113) then -1 -- delete
					when pre.cmdType IN (2) and pre.statusID in (111,112,113) then 1 -- insert as settled
					when pre.cmdType IN (4) and pre.statusID in (0,1,101,102,103) and old.statusID in (0,1,101,102,103) then 0 
					when pre.cmdType IN (4) and pre.statusID in (111,112,113) and old.statusID in (111,112,113) then 0
					when pre.cmdType IN (4) and pre.statusID in (0,1,101,102,103)  and old.statusID in (111,112,113) then -1
					when pre.cmdType IN (4) and pre.statusID in (111,112,113) and old.statusID in (0,1,101,102,103) then 1
					else 0
				end as preCal
		) AS ck
		CROSS APPLY (
			SELECT tmp.custid, 1, pre.BetCount*ck.preCal
				, (pre.turnover*ck.preCal)
				, (pre.netTurnover*ck.preCal)
				, IIF(pre.cmdType IN(1,2), pre.TurnoverNoDraw*ck.preCal,(pre.TurnoverNoDraw-ISNULL(old.TurnoverNoDraw,0)))
				, IIF(pre.cmdType IN(1,2), pre.winlost*ck.preCal,(pre.winlost-ISNULL(old.winlost,0)))
				, IIF(pre.cmdType IN(1,2), pre.awinlost*ck.preCal,(pre.awinlost-ISNULL(old.awinlost,0)))
				, IIF(pre.cmdType IN(1,2), pre.mwinlost*ck.preCal,(pre.mwinlost-ISNULL(old.mwinlost,0)))
				, IIF(pre.cmdType IN(1,2), pre.swinlost*ck.preCal,(pre.swinlost-ISNULL(old.swinlost,0)))
				, IIF(pre.cmdType IN(1,2), pre.playercomm*ck.preCal,(pre.playercomm-ISNULL(old.playercomm,0)))
				, IIF(pre.cmdType IN(1,2), pre.comm*ck.preCal,(pre.comm-ISNULL(old.comm,0)))
				, IIF(pre.cmdType IN(1,2), pre.acomm*ck.preCal,(pre.acomm-ISNULL(old.acomm,0)))
				, IIF(pre.cmdType IN(1,2), pre.scomm*ck.preCal,(pre.scomm-ISNULL(old.scomm,0)))
				, IIF(pre.cmdType IN(1,2), pre.grosscomm*ck.preCal,(pre.grosscomm-ISNULL(old.grosscomm,0)))
				, IIF(pre.cmdType IN(1,2), pre.ExtraWinloss*ck.preCal,(pre.ExtraWinloss-ISNULL(old.ExtraWinloss,0)))
				, IIF(pre.cmdType IN(1,2), pre.ExtraComm*ck.preCal,(pre.ExtraComm-ISNULL(old.ExtraComm,0)))
			UNION ALL
			SELECT tmp.recommend, 2, pre.BetCount*ck.preCal
				, (pre.turnover*ck.preCal)
				, (pre.anetTurnover*ck.preCal)
				, IIF(pre.cmdType IN(1,2), pre.TurnoverNoDraw*ck.preCal,(pre.TurnoverNoDraw-ISNULL(old.TurnoverNoDraw,0)))
				, IIF(pre.cmdType IN(1,2), pre.winlost*ck.preCal,(pre.winlost-ISNULL(old.winlost,0)))
				, IIF(pre.cmdType IN(1,2), pre.awinlost*ck.preCal,(pre.awinlost-ISNULL(old.awinlost,0)))
				, IIF(pre.cmdType IN(1,2), pre.mwinlost*ck.preCal,(pre.mwinlost-ISNULL(old.mwinlost,0)))
				, IIF(pre.cmdType IN(1,2), pre.swinlost*ck.preCal,(pre.swinlost-ISNULL(old.swinlost,0)))
				, IIF(pre.cmdType IN(1,2), pre.playercomm*ck.preCal,(pre.playercomm-ISNULL(old.playercomm,0)))
				, IIF(pre.cmdType IN(1,2), pre.comm*ck.preCal,(pre.comm-ISNULL(old.comm,0)))
				, IIF(pre.cmdType IN(1,2), pre.acomm*ck.preCal,(pre.acomm-ISNULL(old.acomm,0)))
				, IIF(pre.cmdType IN(1,2), pre.scomm*ck.preCal,(pre.scomm-ISNULL(old.scomm,0)))
				, IIF(pre.cmdType IN(1,2), pre.agrosscomm*ck.preCal,(pre.agrosscomm-ISNULL(old.agrosscomm,0)))
				, IIF(pre.cmdType IN(1,2), pre.ExtraWinloss*ck.preCal,(pre.ExtraWinloss-ISNULL(old.ExtraWinloss,0)))
				, IIF(pre.cmdType IN(1,2), pre.ExtraComm*ck.preCal,(pre.ExtraComm-ISNULL(old.ExtraComm,0)))
			UNION ALL
			SELECT tmp.mrecommend, 3, pre.BetCount*ck.preCal
				, (pre.turnover*ck.preCal)
				, (pre.mnetTurnover*ck.preCal)
				, IIF(pre.cmdType IN(1,2), pre.TurnoverNoDraw*ck.preCal,(pre.TurnoverNoDraw-ISNULL(old.TurnoverNoDraw,0)))
				, IIF(pre.cmdType IN(1,2), pre.winlost*ck.preCal,(pre.winlost-ISNULL(old.winlost,0)))
				, IIF(pre.cmdType IN(1,2), pre.awinlost*ck.preCal,(pre.awinlost-ISNULL(old.awinlost,0)))
				, IIF(pre.cmdType IN(1,2), pre.mwinlost*ck.preCal,(pre.mwinlost-ISNULL(old.mwinlost,0)))
				, IIF(pre.cmdType IN(1,2), pre.swinlost*ck.preCal,(pre.swinlost-ISNULL(old.swinlost,0)))
				, IIF(pre.cmdType IN(1,2), pre.playercomm*ck.preCal,(pre.playercomm-ISNULL(old.playercomm,0)))
				, IIF(pre.cmdType IN(1,2), pre.comm*ck.preCal,(pre.comm-ISNULL(old.comm,0)))
				, IIF(pre.cmdType IN(1,2), pre.acomm*ck.preCal,(pre.acomm-ISNULL(old.acomm,0)))
				, IIF(pre.cmdType IN(1,2), pre.scomm*ck.preCal,(pre.scomm-ISNULL(old.scomm,0)))
				, IIF(pre.cmdType IN(1,2), pre.mgrosscomm*ck.preCal,(pre.mgrosscomm-ISNULL(old.mgrosscomm,0)))
				, IIF(pre.cmdType IN(1,2), pre.ExtraWinloss*ck.preCal,(pre.ExtraWinloss-ISNULL(old.ExtraWinloss,0)))
				, IIF(pre.cmdType IN(1,2), pre.ExtraComm*ck.preCal,(pre.ExtraComm-ISNULL(old.ExtraComm,0)))
			UNION ALL
			SELECT tmp.srecommend, 4, pre.BetCount*ck.preCal
				, (pre.turnover*ck.preCal)
				, (pre.snetTurnover*ck.preCal)
				, IIF(pre.cmdType IN(1,2), pre.TurnoverNoDraw*ck.preCal,(pre.TurnoverNoDraw-ISNULL(old.TurnoverNoDraw,0)))
				, IIF(pre.cmdType IN(1,2), pre.winlost*ck.preCal,(pre.winlost-ISNULL(old.winlost,0)))
				, IIF(pre.cmdType IN(1,2), pre.awinlost*ck.preCal,(pre.awinlost-ISNULL(old.awinlost,0)))
				, IIF(pre.cmdType IN(1,2), pre.mwinlost*ck.preCal,(pre.mwinlost-ISNULL(old.mwinlost,0)))
				, IIF(pre.cmdType IN(1,2), pre.swinlost*ck.preCal,(pre.swinlost-ISNULL(old.swinlost,0)))
				, IIF(pre.cmdType IN(1,2), pre.playercomm*ck.preCal,(pre.playercomm-ISNULL(old.playercomm,0)))
				, IIF(pre.cmdType IN(1,2), pre.comm*ck.preCal,(pre.comm-ISNULL(old.comm,0)))
				, IIF(pre.cmdType IN(1,2), pre.acomm*ck.preCal,(pre.acomm-ISNULL(old.acomm,0)))
				, IIF(pre.cmdType IN(1,2), pre.scomm*ck.preCal,(pre.scomm-ISNULL(old.scomm,0)))
				, IIF(pre.cmdType IN(1,2), pre.sgrosscomm*ck.preCal,(pre.sgrosscomm-ISNULL(old.sgrosscomm,0)))
				, IIF(pre.cmdType IN(1,2), pre.ExtraWinloss*ck.preCal,(pre.ExtraWinloss-ISNULL(old.ExtraWinloss,0)))
				, IIF(pre.cmdType IN(1,2), pre.ExtraComm*ck.preCal,(pre.ExtraComm-ISNULL(old.ExtraComm,0)))
		) AS cal (custid, roleId, betCount, turnover, netTurnover, turnoverNoDraw
				, winlost, awinlost, mwinlost, swinlost
				, playercomm, comm, acomm, scomm, grosscomm, extraWinloss, extraComm)
		WHERE tmp.cmdType IN (1,2,4)
		GROUP BY cal.custid
			,pre.winlostdate
			,tmp.productId
			,tmp.sporttype
			,tmp.bettype
			,tmp.leagueGroupID
			,tmp.ticketType

		--TODO: Accum #bettrans_compact_tmp
		UPDATE up
		SET up.[betcount] += tmp.[betcount]
           ,up.[turnover] += tmp.[turnover]
           ,up.[netTurnover] += tmp.[netTurnover]
           ,up.[TurnoverNoDraw] += tmp.[TurnoverNoDraw]
           ,up.[winlost] += tmp.[winlost]
           ,up.[awinlost] += tmp.[awinlost]
           ,up.[mwinlost] += tmp.[mwinlost]
           ,up.[swinlost] += tmp.[swinlost]
           ,up.[playercomm] += tmp.[playercomm]
           ,up.[comm] += tmp.[comm]
           ,up.[acomm] += tmp.[acomm]
           ,up.[scomm] += tmp.[scomm]
           ,up.[grosscomm] += tmp.[grosscomm]
           ,up.[extraWinloss] += tmp.[extraWinloss]
           ,up.[extraComm] += tmp.[extraComm]
		OUTPUT inserted.[custid]
           ,inserted.[winlostdate]
           ,inserted.[productId]
           ,inserted.[sporttype]
           ,inserted.[bettype]
           ,inserted.[leagueGroupID]
           ,inserted.[ticketType]
		INTO #merge_update_tmp (
			[custid]
           ,[winlostdate]
           ,[productId]
           ,[sporttype]
           ,[bettype]
           ,[leagueGroupID]
           ,[ticketType]
		)
		FROM [dbo].[bettrans_compact] up
		INNER JOIN #bettrans_compact_tmp tmp ON up.[custid] = tmp.[custid]
           AND up.[winlostdate] = tmp.[winlostdate]
           AND up.[productId] = tmp.[productId]
           AND up.[sporttype] = tmp.[sporttype]
           AND up.[bettype] = tmp.[bettype]
           AND up.[leagueGroupID] = tmp.[leagueGroupID]
           AND up.[ticketType] = tmp.[ticketType]

		--TODO: INSERT if Any
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
		LEFT JOIN #merge_update_tmp up ON up.[custid] = tmp.[custid]
           AND up.[winlostdate] = tmp.[winlostdate]
           AND up.[productId] = tmp.[productId]
           AND up.[sporttype] = tmp.[sporttype]
           AND up.[bettype] = tmp.[bettype]
           AND up.[leagueGroupID] = tmp.[leagueGroupID]
           AND up.[ticketType] = tmp.[ticketType]
		WHERE up.custid IS NULL


		-- RESET: @lastRowId
		SELECT @lastRowId = MAX(rowId)
			, @minActiondate = MAX(Actiondate)
		FROM dbo.cdc_bettrans_batch WITH(NOLOCK)
		WHERE cmdType in (1,2,4);

		UPDATE s
		SET s.VValue = CONCAT('{"lastRowId":', @lastRowId, ',"delayTime":', DATEDIFF(SECOND, @minActiondate, @maxActiondate), '}')
		FROM dbo.SystemSettings s WITH(ROWLOCK)
		WHERE VName = @sysVName;

		set @message = concat('Age_cdc_bettrans_lastRowId: ', @lastRowId, ', loop count: ', @loopCnt);
		RAISERROR (@message, 0, 1) WITH NOWAIT;

		--GOTO END_PROCESS;
		--RETURN;
		SET @loopCnt += 1;
		
	END

	END_PROCESS:
	SELECT DATEDIFF(MILLISECOND, @startTime, CURRENT_TIMESTAMP) AS duration
		, @loopCnt AS totalBatch
		, DATEDIFF(MILLISECOND, @startTime, CURRENT_TIMESTAMP) / @loopCnt AS durationBatch
END
GO