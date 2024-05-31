/*<info serverAlias="DBAGE-bodb_AGE" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_CDC_bettrans_compact_CorrectData]
	@notifyTime DATETIME = NULL
AS
/*
	Created by: 20231201@Bobby
	Task: 153357 - Alpha - CDC bettrans_compact - check SUMDATA
	DB: DBAGE.bodb_AGE
	Revisions:
		- 20231201@Bobby:  Implement bettrans_compact Redmine: [#153357]
		- 20240306@Lewis: Add Virtual Ice Hockey [RedmineID: #201129]
		- 20240321@Bobby:  checkSum remove extraWinloss vs extraComm Redmine: [#200041]
		- 20240401@Bobby:  Fix bug checkNotify & Correct Redmine: [#202655]
		- 20240522@Bobby: Enhance checkSum process [RedmineID: #205378]
		- 20240515@Lewis: Add SABA Kabaddi [RedmineID: #203763]
*/
BEGIN

	SET NOCOUNT ON;

	DROP TABLE IF EXISTS #diffCustCheckSum;
	DROP TABLE IF EXISTS #diffSuperWinlostdate;
	DROP TABLE IF EXISTS #checkCorrectData;

	CREATE TABLE #diffSuperWinlostdate (rIdx INT IDENTITY(1,1), Winlostdate SMALLDATETIME, SuperIds VARCHAR(MAX));
	CREATE TABLE #checkCorrectData(
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
	CREATE TABLE #diffCustCheckSum (custid INT, winlostdate SMALLDATETIME, PRIMARY KEY(winlostdate, custid));

	-- TODO: get diff custid vs winlostdate
	INSERT INTO #diffCustCheckSum
	SELECT DISTINCT custid, winlostdate
	FROM (
		SELECT custid, winlostdate, ROW_NUMBER() OVER (PARTITION BY custid, winlostdate ORDER BY createdtime DESC) AS rIdx
		FROM dbo.bettrans_compact_checkSum WITH(NOLOCK)
		WHERE notifyStatus = 0
			AND createdTime = @notifyTime
	) AS t 
	WHERE t.rIdx = 1;

	--TODO: filter by super
	INSERT INTO #diffSuperWinlostdate(Winlostdate, SuperIds)
	SELECT c.Winlostdate, STRING_AGG(CAST(c.srecommend AS VARCHAR(MAX)), ',')
	FROM (
		SELECT DISTINCT ck.Winlostdate, c.srecommend
		FROM #diffCustCheckSum ck
		INNER JOIN bodb02.dbo.Customer c WITH(NOLOCK) ON c.custid = ck.custid --> reCal for whole line
	) AS c
	GROUP BY Winlostdate
	ORDER BY Winlostdate;

	IF @@ROWCOUNT = 0 RETURN;

	DECLARE @winlostdate SMALLDATETIME, @checkDate SMALLDATETIME, @toDay SMALLDATETIME;
	DECLARE @NetTO_CutOffDate SMALLDATETIME, @GrossComm_CutOffDate SMALLDATETIME, @SabaInfo_CutOffDate SMALLDATETIME

	SELECT  @NetTO_CutOffDate = CASE WHEN f.TypeName = 'NetTO' THEN f.CutoffDate ELSE @NetTO_CutOffDate END
			,@GrossComm_CutOffDate = CASE WHEN f.TypeName = 'GrossComm' THEN f.CutoffDate ELSE @NetTO_CutOffDate END
			,@SabaInfo_CutOffDate = CASE WHEN f.TypeName = 'SabaSport' THEN f.CutoffDate ELSE @SabaInfo_CutOffDate END
	FROM bodb02.dbo.f_GetCutOffDate() f
	WHERE f.TypeName IN ('NetTO', 'GrossComm','SabaSport')

	---- get extra PT from table setting
	DROP TABLE IF EXISTS #__SuperExtraPT
	CREATE TABLE #__SuperExtraPT(productId INT, bettypePT INT, SuperId INT, ExtraPT MONEY, RefTable TINYINT, IsUsingOddsSpread BIT, IsContributionBettype BIT)
	CREATE CLUSTERED INDEX CIX_#__SuperExtraPT ON #__SuperExtraPT(SuperId, bettypePT);

	DROP TABLE IF EXISTS #__SuperProcess;
	CREATE TABLE #__SuperProcess(srecommend INT PRIMARY KEY);

	--TODO: process Correct data
	DECLARE @rCont INT = 1, @superIds VARCHAR(MAX);
	WHILE EXISTS (SELECT 1 FROM #diffSuperWinlostdate WHERE rIdx = @rCont)
	BEGIN
		TRUNCATE TABLE #__SuperExtraPT;
		TRUNCATE TABLE #__SuperProcess;

		SELECT @winlostdate = Winlostdate 
			,@superIds = SuperIds
		FROM #diffSuperWinlostdate WHERE rIdx = @rCont;

		INSERT INTO #__SuperProcess(srecommend)
		SELECT DISTINCT [value] FROM STRING_SPLIT(@superIds, ',')
		
		;WITH rs AS 
		(
			SELECT DISTINCT b.bettype , b.srecommend
			FROM bodb02.dbo.bettrans b WITH(NOLOCK) 
			INNER JOIN #__SuperProcess cs ON cs.srecommend = b.srecommend
			WHERE 
				b.winlostdate = @winlostdate
				AND b.statusID IN (111,112,113)
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
			) cont;

		---- gen all data
		;WITH sum_winloss_CheckSum AS (
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
				FROM bodb02.dbo.bettrans bettrans WITH (NOLOCK)
					INNER JOIN #__SuperExtraPT tbl ON bettrans.srecommend = tbl.SuperId	AND bettrans.bettype = tbl.bettypePT
					LEFT JOIN bodb02.dbo.[match] m WITH(NOLOCK) ON bettrans.matchid = m.matchid AND m.sporttype IN (1, 2, 5, 43, 50, 4, 47)
					LEFT JOIN bodb02.dbo.League l WITH(NOLOCK) ON m.leagueid=l.leagueid AND l.LeagueGroupID IN (42,74,108,113,122,151)
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
		)
		INSERT INTO #checkCorrectData(custid,winlostdate,productid,sporttype,bettype,LeagueGroupID,ticketType
			,betcount,winlost,turnover,netTurnover,awinlost,mwinlost,swinlost,playercomm,comm,acomm,scomm,TurnoverNoDraw,grosscomm,ExtraComm,ExtraWinloss
		)
		SELECT bt.custid,bt.winlostdate,bt.productid,bt. sporttype,bt.bettype,bt.LeagueGroupID,bt.ticketType
			,bt.betcount,bt.winlost,bt.turnover,bt.netTurnover,bt.awinlost,bt.mwinlost,bt.swinlost,bt.playercomm,bt.comm,bt.acomm,bt.scomm,bt.TurnoverNoDraw,bt.grosscomm,bt.ExtraComm,bt.ExtraWinloss
		FROM sum_winloss_CheckSum bt
		INNER JOIN #diffCustCheckSum ck ON ck.custid = bt.custid AND ck.winlostdate = bt.winlostdate 
		WHERE ck.winlostdate = @winlostdate

		---MEGRE diff rows
		MERGE dbo.bettrans_compact up
		USING #checkCorrectData tmp ON (
			up.custid				= tmp.custid
			AND up.[winlostdate]	= tmp.[winlostdate]
			AND up.[productId]		= tmp.[productId]
			AND up.[sporttype]		= tmp.[sporttype]
			AND up.[bettype]		= tmp.[bettype]
			AND up.[leagueGroupID]	= tmp.[leagueGroupID]
			AND up.[ticketType]		= tmp.[ticketType]
		)
		WHEN MATCHED THEN 
			UPDATE
			SET up.[betcount]		= tmp.[betcount]
			   ,up.[turnover]		= tmp.[turnover]
			   ,up.[netTurnover]	= tmp.[netTurnover]
			   ,up.[TurnoverNoDraw] = tmp.[TurnoverNoDraw]
			   ,up.[winlost]		= tmp.[winlost]
			   ,up.[awinlost]		= tmp.[awinlost]
			   ,up.[mwinlost]		= tmp.[mwinlost]
			   ,up.[swinlost]		= tmp.[swinlost]
			   ,up.[playercomm]		= tmp.[playercomm]
			   ,up.[comm]			= tmp.[comm]
			   ,up.[acomm]			= tmp.[acomm]
			   ,up.[scomm]			= tmp.[scomm]
			   ,up.[grosscomm]		= tmp.[grosscomm]
			   ,up.[extraWinloss]	= tmp.[extraWinloss]
			   ,up.[extraComm]		= tmp.[extraComm]
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (
				[custid]
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
			   ,[extraComm]
			)
			VALUES(
				tmp.[custid]
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
		   )
		;

		--DELETE bettrans_compact
		;WITH CTE_CompactDiffCust AS (
			SELECT ck.[custid], ck.[winlostdate], ck.[productId], ck.[sporttype], ck.[bettype], ck.[leagueGroupID], ck.[ticketType]
			FROM dbo.bettrans_compact ck (NOLOCK)
			INNER JOIN #diffCustCheckSum diff ON diff.custid = ck.custid AND diff.winlostdate = ck.winlostdate
			WHERE diff.winlostdate = @winlostdate
		)
		DELETE up
		FROM dbo.bettrans_compact up
		INNER JOIN CTE_CompactDiffCust tmp ON (
			up.custid				= tmp.custid
			AND up.[winlostdate]	= tmp.[winlostdate]
			AND up.[productId]		= tmp.[productId]
			AND up.[sporttype]		= tmp.[sporttype]
			AND up.[bettype]		= tmp.[bettype]
			AND up.[leagueGroupID]	= tmp.[leagueGroupID]
			AND up.[ticketType]		= tmp.[ticketType]
		)
		LEFT JOIN #checkCorrectData ck ON (
			ck.custid				= tmp.custid
			AND ck.[winlostdate]	= tmp.[winlostdate]
			AND ck.[productId]		= tmp.[productId]
			AND ck.[sporttype]		= tmp.[sporttype]
			AND ck.[bettype]		= tmp.[bettype]
			AND ck.[leagueGroupID]	= tmp.[leagueGroupID]
			AND ck.[ticketType]		= tmp.[ticketType]
		)
		WHERE ck.custid IS NULL; -- NOT EXISTS in the SOURCE bettrans

		--- TODO: mark as fixed
		UPDATE up WITH(ROWLOCK, UPDLOCK)
		SET NotifyStatus = 2
		FROM dbo.bettrans_compact_checkSum up
		INNER JOIN #diffCustCheckSum ck ON ck.custid = up.custid 
				AND ck.winlostdate = up.winlostdate
		WHERE	
			ck.winlostdate		= @winlostdate
			AND up.notifyStatus = 0
			AND up.createdTime	= @notifyTime

		SET @rCont += 1;

	END
END
