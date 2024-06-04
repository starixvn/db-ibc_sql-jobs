/*<info serverAlias="DBAGE-bodb_AGE" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_CDC_Process_Bettrans_compact]
	@DebugMode TINYINT = 1
AS
/*
	Created by: 20231201@Bobby
	Task: 153357 - Alpha - CDC bettrans_compact
	DB: DBAGE.bodb_AGE
	Revisions:
		- 20231201@Bobby:  Implement bettrans_compact Redmine: [#153357]
		- 20240306@Lewis: Add Virtual Ice Hockey [RedmineID: #201129]
		- 20240515@Lewis: Add SABA Kabaddi [RedmineID: #203763]
		- 20240602@Bobby: Enhance check & correct process [RedmineID: #205973]
*/

BEGIN

	SET NOCOUNT ON;

	DECLARE @lastRowId	BIGINT = 0 --515426
		, @maxRowId		bigint = 0 --1070646
		, @batchSize	INT = 50000
		, @batchCount	INT
		, @sysVName		VARCHAR(200) = 'Age_cdc_bettrans_compact';

	DECLARE @startTime DATETIME, @loopCnt INT = 1, @message VARCHAR(500)
		,@lastActiondate DATETIME;
	
	--TODO: get lastRowId
	SELECT @lastRowId = CAST(JSON_VALUE(VValue, '$.lastRowId') AS BIGINT)
	FROM dbo.SystemSettings WITH(ROWLOCK)
	WHERE VName=@sysVName;

	--TODO: Capture maxRowId
	SELECT @maxRowId		= MAX(rowid)
	FROM dbo.cdc_bettrans WITH(ROWLOCK)
	WHERE rowid > @lastRowId;

	SELECT TOP(1) @maxRowId = IIF([__$operation] = 3, @maxRowId - 1, @maxRowId)
	FROM dbo.cdc_bettrans WITH(NOLOCK)
	WHERE rowid = @maxRowId;

	

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
		,[betcount] INT
	);


	DROP TABLE IF EXISTS #cdc_bettrans_batch;
	CREATE TABLE #cdc_bettrans_batch(
		[rowId] [bigint] NOT NULL,
		[cmdType] [int] NOT NULL,
		[cmdId] [int] NULL,
		[cmdTxn] [binary](10) NOT NULL,
		[transid] [bigint] NULL,
		[custid] [int] NULL,
		[recommend] [int] NULL,
		[mrecommend] [int] NULL,
		[srecommend] [int] NULL,
		[odds] [smallmoney] NULL,
		[winlostdate] [smalldatetime] NULL,
		[bettype] [smallint] NULL,
		[stake] [money] NULL,
		[actual_stake] [money] NULL,
		[winlost] [money] NULL,
		[awinlost] [money] NULL,
		[mwinlost] [money] NULL,
		[swinlost] [money] NULL,
		[playercomm] [money] NULL,
		[comm] [money] NULL,
		[acomm] [money] NULL,
		[scomm] [money] NULL,
		[apositiontaking] [smallmoney] NULL,
		[mpositiontaking] [smallmoney] NULL,
		[spositiontaking] [smallmoney] NULL,
		[tpositiontaking] [smallmoney] NULL,
		[epositiontaking] [smallmoney] NULL,
		[statusID] [tinyint] NULL,
		[modds] [smallmoney] NULL,
		[oddsspread] [money] NULL,
		[betid] [bigint] NULL,
		[betdaqid] [bigint] NULL,
		[matchid] [int] NULL,
		[actiondate] [datetime] NULL
	);
	CREATE CLUSTERED INDEX [CIX_#cdc_bettrans_batch] ON #cdc_bettrans_batch
	(
		[srecommend] ASC,
		[winlostdate] ASC,
		[bettype] ASC
	);

	SET @startTime = CURRENT_TIMESTAMP;
	DECLARE @batchTime DATETIME;

	WHILE (@lastRowId < @maxRowId)
	BEGIN
		
		TRUNCATE TABLE #cdc_bettrans_batch;
		TRUNCATE TABLE #merge_update_tmp;
		TRUNCATE TABLE #bettrans_compact_tmp;

		--- Batch time duration
		SET @batchTime = CURRENT_TIMESTAMP;
		
		INSERT INTO #cdc_bettrans_batch
		SELECT TOP (@batchSize)
		--SELECT
			[rowId]
			,[__$operation] AS cmdType
			,[__$command_id] AS cmdId
			,[__$start_lsn] AS cmdTxn
			,[transid]
			,b.[custid],b.[recommend],b.[mrecommend],b.[srecommend]
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
		FROM [dbo].[cdc_bettrans] b WITH(NOLOCK)
			LEFT JOIN bodb02.dbo.Dep_CustSuper cs WITH(NOLOCK) ON cs.custid = b.srecommend
		WHERE b.rowId > @lastRowId AND b.rowId <= @maxRowId
			AND cs.custid IS NULL
		ORDER BY b.rowId ASC;

		SET @batchCount = @@ROWCOUNT;
		IF (@batchCount = 0) BREAK;

		;WITH refSuper AS 
		(
			SELECT DISTINCT b.srecommend, b.winlostdate, b.bettype
			FROM #cdc_bettrans_batch b WITH(NOLOCK)
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
			   ,ck.LeagueGroupID
			   ,ck.ticketType
			   ,b.cmdType, b.cmdId, b.cmdTxn
			   ,b.statusID
			   ,CASE WHEN statusID IN (0,1,101,102,103) THEN 0 ELSE ABS(stake) END Turnover
			   ,0 AS netTurnover
			   ,CASE WHEN statusID IN (0,1,101,102,103) THEN 0 ELSE (ABS(stake) * apositiontaking) END AS anetTurnover
			   ,CASE WHEN statusID IN (0,1,101,102,103) THEN 0 ELSE (ABS(stake) * mpositiontaking) END AS mnetTurnover
			   ,CASE WHEN statusID IN (0,1,101,102,103) THEN 0 ELSE (ABS(stake) * spositiontaking) END AS snetTurnover
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
				,CHECKSUM(CONCAT_WS('|',b.custid,b.recommend,b.mrecommend,b.srecommend,b.winlostdate,tbl.productId,ck.sporttype,b.bettype,ck.LeagueGroupID,ck.ticketType)) AS ckKey
			FROM #cdc_bettrans_batch b
			INNER JOIN SuperExtraPT tbl ON b.srecommend = tbl.srecommend AND b.bettype = tbl.bettype and b.winlostdate = tbl.winlostdate
			LEFT JOIN bodb02.dbo.match m WITH(NOLOCK) ON b.matchid = m.matchid
			LEFT JOIN bodb02.dbo.League l WITH(NOLOCK) ON m.leagueid=l.leagueid
			LEFT JOIN dbo.Age_f_SabaSportRef() AS saba ON saba.SportType = l.sporttype AND saba.LeagueGroupId = l.LeagueGroupID
			CROSS APPLY (
				SELECT 
					CASE WHEN  b.betdaqid <> -2 AND saba.LeagueGroupID > 0 THEN ISNULL(saba.sporttype, 0) ELSE 0 END AS sporttype
					,CASE WHEN b.betdaqid <> -2 AND saba.sporttype > 0 THEN ISNULL(saba.LeagueGroupID, 0) ELSE 0 END AS LeagueGroupID
					,CASE WHEN b.betdaqid = -2 THEN 1 ELSE 0 END ticketType
			) AS ck
		)
		INSERT INTO #bettrans_compact_tmp
		SELECT cal.custid, pre.winlostdate, pre.productId, pre.sporttype, pre.bettype, pre.leagueGroupID, pre.ticketType
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
			SELECT tmp.custid, tmp.recommend, tmp.mrecommend, tmp.srecommend
				, tmp.winlostdate, tmp.productId, tmp.sporttype, tmp.bettype, tmp.leagueGroupID, tmp.ticketType
				, tmp.BetCount, tmp.turnover, tmp.netTurnover, tmp.anetTurnover, tmp.mnetTurnover, tmp.snetTurnover, tmp.TurnoverNoDraw, tmp.winlost, tmp.awinlost, tmp.mwinlost, tmp.swinlost
				, tmp.playercomm, tmp.comm, tmp.acomm, tmp.scomm, tmp.grosscomm, tmp.agrosscomm, tmp.mgrosscomm, tmp.sgrosscomm, tmp.ExtraWinloss, tmp.ExtraComm
				, CASE WHEN old.transid > 0 AND old.ckKey <> tmp.ckKey THEN 2 ELSE tmp.cmdType END AS cmdType, tmp.statusID
			UNION ALL
			SELECT old.custid, old.recommend, old.mrecommend, old.srecommend
				, old.winlostdate, old.productId, old.sporttype, old.bettype, old.leagueGroupID, old.ticketType
				, old.BetCount, old.turnover, old.netTurnover, old.anetTurnover, old.mnetTurnover, old.snetTurnover, old.TurnoverNoDraw, old.winlost, old.awinlost, old.mwinlost, old.swinlost
				, old.playercomm, old.comm, old.acomm, old.scomm, old.grosscomm, old.agrosscomm, old.mgrosscomm, old.sgrosscomm, old.ExtraWinloss, old.ExtraComm
				, 1 AS cmdType, old.statusID
			WHERE old.transid > 0 AND old.ckKey <> tmp.ckKey
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
			SELECT pre.custid, 1, pre.BetCount*ck.preCal
				, IIF(pre.cmdType IN(1,2), pre.turnover*ck.preCal, (pre.turnover-ISNULL(old.turnover,0)))
				, IIF(pre.cmdType IN(1,2), pre.netTurnover*ck.preCal, (pre.netTurnover-ISNULL(old.netTurnover,0)))
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
			SELECT pre.recommend, 2, pre.BetCount*ck.preCal
				, IIF(pre.cmdType IN(1,2), pre.turnover*ck.preCal, (pre.turnover-ISNULL(old.turnover,0)))
				, IIF(pre.cmdType IN(1,2), pre.anetTurnover*ck.preCal, (pre.anetTurnover-ISNULL(old.anetTurnover,0)))
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
			SELECT pre.mrecommend, 3, pre.BetCount*ck.preCal
				, IIF(pre.cmdType IN(1,2), pre.turnover*ck.preCal, (pre.turnover-ISNULL(old.turnover,0)))
				, IIF(pre.cmdType IN(1,2), pre.mnetTurnover*ck.preCal, (pre.mnetTurnover-ISNULL(old.mnetTurnover,0)))
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
			SELECT pre.srecommend, 4, pre.BetCount*ck.preCal
				, IIF(pre.cmdType IN(1,2), pre.turnover*ck.preCal, (pre.turnover-ISNULL(old.turnover,0)))
				, IIF(pre.cmdType IN(1,2), pre.snetTurnover*ck.preCal, (pre.snetTurnover-ISNULL(old.snetTurnover,0)))
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
			,pre.productId
			,pre.sporttype
			,pre.bettype
			,pre.leagueGroupID
			,pre.ticketType;

		IF (@@ROWCOUNT = 0) BREAK;

		--TODO: SUM accumulation
		UPDATE up WITH(ROWLOCK, UPDLOCK)
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
		   ,inserted.betcount
		INTO #merge_update_tmp (
			[custid]
           ,[winlostdate]
           ,[productId]
           ,[sporttype]
           ,[bettype]
           ,[leagueGroupID]
           ,[ticketType]
		   ,[betcount]
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
		LEFT JOIN #merge_update_tmp up ON up.[winlostdate] = tmp.[winlostdate]
           AND up.[custid] = tmp.[custid]
		   AND up.[bettype] = tmp.[bettype]
           AND up.[productId] = tmp.[productId]
           AND up.[sporttype] = tmp.[sporttype]
           AND up.[leagueGroupID] = tmp.[leagueGroupID]
           AND up.[ticketType] = tmp.[ticketType]
		WHERE up.custid IS NULL
			AND tmp.[betcount] > 0
		;

		--TODO: DELETE zero rows
		DELETE d WITH(ROWLOCK)
		FROM [dbo].[bettrans_compact] d
		INNER JOIN #merge_update_tmp up ON up.[winlostdate] = d.[winlostdate]
           AND up.[custid] = d.[custid]
		   AND up.[bettype] = d.[bettype]
           AND up.[productId] = d.[productId]
           AND up.[sporttype] = d.[sporttype]
           AND up.[leagueGroupID] = d.[leagueGroupID]
           AND up.[ticketType] = d.[ticketType]
		WHERE up.betcount <= 0

		-- RESET: @lastRowId
		SELECT @lastRowId = MAX(rowId)
			, @lastActiondate = MAX(actiondate)
		FROM #cdc_bettrans_batch;

		--SET @message = concat('lastRowId: ', @lastRowId, ', batch: ', @loopCnt,', count:', @batchCount ,', duration: ', DATEDIFF(MILLISECOND, @batchTime, CURRENT_TIMESTAMP));
		--RAISERROR (@message, 0, 1) WITH NOWAIT;

		SET @loopCnt += 1;
		
	END

	--TODO: Update setting
	UPDATE TOP(1) s WITH(ROWLOCK, UPDLOCK)
	SET s.VValue = CONCAT('{"lastRowId":', ISNULL(@maxRowId, @lastRowId), ',"delayTime":', DATEDIFF(SECOND, ISNULL(@lastActiondate, GETDATE()), GETDATE()), ', "lastRun":"', FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss'),'"}')
	FROM dbo.SystemSettings s
	WHERE s.VName = @sysVName;
	
	---CAPTURE: cdc_bettrans metric logs
	IF (@DebugMode = 1)
	BEGIN
		EXEC [dbo].[Task_CDC_bettrans_Metric_Capture]
	END
END
GO