/*<info serverAlias="DBAGE-bodb_AGE" isNested="0"></info>*/
/*
	Created by: 20240405@Bobby
	Task: 201044 - Move SMA lines
	DB: DBAGE.bodb_AGE
		
*/

--TODO: Run script after moving SMA done on bettrans COMPLETED
USE bodb_AGE;
GO
BEGIN

	SET NOCOUNT ON;

	DECLARE @CurrentBU_Date SMALLDATETIME
		,@CurrentMB_Date	SMALLDATETIME
		,@Today				SMALLDATETIME
		,@_Winlostdate		SMALLDATETIME

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

	DROP TABLE IF EXISTS #affectedCustTmp;
	CREATE TABLE #affectedCustTmp(CustId INT, RoleId TINYINT, recommend INT, mrecommend INT, srecommend INT);

	INSERT #affectedCustTmp(custid, roleid, recommend, mrecommend, srecommend)
	SELECT DISTINCT custid, roleid, recommend, mrecommend, srecommend
	FROM bodb02.dbo.Customer c WITH(NOLOCK)
	WHERE username IN ('SA-HK$', 'mhk', '6666AHK', 'SH-HK$', 'MH-HK$', 'SH-RMB', 'MH-RMB', 'AH-RMB', '230RMB', '231RMB', 'SS-RMB', 'MS-RMB', 'wsrmb')

	-- GET BU & MB Dates
	DECLARE @BalanceUpDays AS TABLE (BalanceUpDay DATE, MoveBetDay DATE)
	INSERT INTO @BalanceUpDays (BalanceUpDay, MoveBetDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay

	SELECT @CurrentBU_Date	= BalanceUpDay
		,@CurrentMB_Date	= MoveBetDay
		,@Today				= CAST(GETDATE() AS DATE)
	FROM @BalanceUpDays;

	--TODO: filter by super
	WITH CTE_Winlostdate AS (
		SELECT DATEADD(DAY, 1, @CurrentMB_Date) AS Winlostdate
		UNION ALL
		SELECT DATEADD(DAY, 1, Winlostdate)
		FROM CTE_Winlostdate
		WHERE Winlostdate < @Today
	)
	INSERT INTO #diffSuperWinlostdate(Winlostdate, SuperIds)
	SELECT wld.Winlostdate, ck.SuperIds
	FROM CTE_Winlostdate wld
	CROSS APPLY (
		SELECT SuperIds = STRING_AGG(custid, ',') 
		FROM #affectedCustTmp WHERE roleid = 4
	) AS ck
	ORDER BY wld.Winlostdate;

	IF @@ROWCOUNT = 0 RETURN;

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

	--TODO: process Correct data
	DECLARE @rCont INT = 1, @superIds VARCHAR(MAX), @startTime DATETIME;
	WHILE EXISTS (SELECT 1 FROM #diffSuperWinlostdate WHERE rIdx = @rCont)
	BEGIN
		SET @startTime = CURRENT_TIMESTAMP;
		TRUNCATE TABLE #__SuperExtraPT;
		TRUNCATE TABLE #__SuperProcess;
		TRUNCATE TABLE #checkCorrectData;

		SELECT @_Winlostdate = Winlostdate 
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
				b.winlostdate = @_Winlostdate
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
				WHERE @_Winlostdate BETWEEN expt2.FromDate AND expt2.ToDate
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
					LEFT JOIN bodb02.dbo.[match] m WITH(NOLOCK) ON bettrans.matchid = m.matchid AND m.sporttype IN (1, 2, 5, 43, 50, 4)
					LEFT JOIN bodb02.dbo.League l WITH(NOLOCK) ON m.leagueid=l.leagueid AND l.LeagueGroupID IN (42,74,108,113,122,151)
					CROSS APPLY (
						SELECT 
							CASE WHEN  bettrans.betdaqid <> -2 AND l.LeagueGroupID > 0 THEN ISNULL(m.sporttype, 0) ELSE 0 END AS sporttype
							,CASE WHEN bettrans.betdaqid <> -2 AND m.sporttype > 0 THEN ISNULL(l.LeagueGroupID,0) ELSE 0 END AS LeagueGroupID
							,CASE WHEN bettrans.betdaqid = -2 THEN 1 ELSE 0 END ticketType
					) AS ck
				WHERE 
					bettrans.winlostdate = @_Winlostdate
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
		INNER JOIN #affectedCustTmp ck ON ck.custid = bt.custid

		--TODO: DELETE/INSERT rptStatement
		DELETE TGR WITH(ROWLOCK)
		FROM dbo.bettrans_compact TGR
		INNER JOIN #affectedCustTmp c ON c.custid = TGR.custid
		WHERE TGR.Winlostdate = @_Winlostdate

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
		FROM #checkCorrectData tmp
		WHERE tmp.[betcount] > 0
		;

		PRINT CONCAT('running bettrans_compact ------> @_Winlostdate=', FORMAT(@_Winlostdate, 'yyyy-MM-dd'), ', @Duration=', DATEDIFF(SECOND, @startTime, GETDATE()));
		SELECT @_Winlostdate = DATEADD(DAY, 1, @_Winlostdate)
			,@rCont += 1;
	END
END
