/*<info serverAlias="DBRPT-bodb_Report" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_DailyRptStatement]
	@Winlostdate SMALLDATETIME
AS
/*
Created by:[Cody]
Date: 20141216
Task: insert/ update data on rptStatement
DB: DBRPT.bodb_Report
Revisions:
	- 20150727@Sophia: Apply Bettrade, exclude ticket Bettrade Comm (903) for Void/reject [#36905]
	- 20150901@Sophia: Apply Colossus Bets [#42428]  
	- 20151113@Sophia: Apply Grand Prize for Microgaming - RNG casino [RedmineId: #46450] 
	- 20160204@Sophia: Apply Cricket - betcount exclude Bettype 500 [Redmine: #50028]
	- 20160328@Sophia: Check status Of PayOutTrans, get status Completed and Expired [Redmine: #54643]
	- 20170323@Percy: Apply Cash Out [RedmineID: #72164]
	- 20190507@Sophia: Add new column OpeningTotalBalance for Credit Collection report use [Redmine: #109293]
	- 20190912@Bobby: Implement headline - Statement [Redmine: #119289]
 */
BEGIN

	SET NOCOUNT ON

	DECLARE @CurrentBU_Date SMALLDATETIME
		,@_Winlostdate		SMALLDATETIME

	CREATE TABLE #rptStatementTable (
		Custid				INT
		,OpeningBalance		MONEY	NULL
		,VoidAmt			MONEY	NULL
		,Turnover			MONEY	NULL
		,netTurnover		MONEY	NULL
		,TransferAmt		MONEY	NULL
		,Winlost			MONEY	NULL
		,Comm				MONEY	NULL
		,ClosingBalance		MONEY	NULL
		,BetCount			INT		DEFAULT 0
		,TransCount			INT		DEFAULT 0
		,VoidCount			INT		DEFAULT 0
		,GrandPrize			MONEY	NULL
	)
	CREATE CLUSTERED INDEX CIX_rptStatementTable_custid ON #rptStatementTable(custid)

	-- GET the current BU day
	SELECT TOP 1 @CurrentBU_Date = winlostdate
	FROM bodb02.dbo.bettrans WITH(NOLOCK) 
	WHERE matchid = 0 AND bettype = 20000

	SELECT @_Winlostdate = @Winlostdate

	-- 1: get SUM data from Bettrans into rptStatement
	;
	WITH bettrans_temp AS (
		SELECT b.custid,b.recommend,b.mrecommend,b.srecommend
			,SUM(bet.stake) AS stake
			,SUM(b.winlost-b.actual_stake) as winlost
			,SUM(b.playercomm) AS playercomm
			,SUM(b.comm) AS comm
			,SUM(b.acomm) AS acomm
			,SUM(b.scomm) AS scomm
			,SUM(b.awinlost) AS awinlost
			,SUM(b.mwinlost) AS mwinlost
			,SUM(b.swinlost) AS swinlost
			,SUM(bet.stake*b.apositiontaking) AS anet_stake
			,SUM(bet.stake*b.mpositiontaking) AS mnet_stake
			,SUM(bet.stake*b.spositiontaking) AS snet_stake
			,SUM(CASE WHEN b.bettype = 300 THEN 0 ELSE 1 END) AS betcount
		FROM
			bodb02.dbo.bettrans b WITH(NOLOCK)
		OUTER APPLY (
			SELECT CASE 
				WHEN b.statusID NOT IN(103) THEN -- Refund
					CASE 
						WHEN b.liveawayscore = 0 AND b.bettype IN(33,43) THEN ABS(b.stake)/2 
						ELSE ABS(b.stake) 
					END 
				ELSE 0 END AS stake
		) AS bet
		WHERE
			b.winlostdate = @_Winlostdate
			AND b.statusID NOT IN (0,1,102,101) -- 'running','waiting','VOID','REJECT'
			AND b.bettype <= 19999
			AND b.ruben = 1
		GROUP BY b.custid,b.recommend,b.mrecommend,b.srecommend
	)
	INSERT INTO #rptStatementTable(
		Custid
		,Turnover
		,netTurnover
		,Winlost
		,Comm
		,BetCount
	)
	SELECT
		c.custid
		,SUM(b.stake) AS Turnover
		,SUM(c.net_stake) AS netTurnover
		,SUM(c.winlost) AS winlost
		,SUM(c.comm) AS comm
		,SUM(b.betcount) AS betcount
	FROM
		bettrans_temp b
	OUTER APPLY (
		SELECT b.custid, 0 AS net_stake, winlost, playercomm AS comm
		UNION ALL
		SELECT b.recommend, anet_stake, awinlost, comm - playercomm
		UNION ALL
		SELECT b.mrecommend, mnet_stake, mwinlost, acomm - comm
		UNION ALL
		SELECT b.srecommend, snet_stake, swinlost, scomm -acomm
	) AS c
	GROUP BY
		c.custid

	--2: void/ Cancelled Bet - get data from bettrans with status = 102
	-- Member
	INSERT INTO #rptStatementTable(
		Custid
		,VoidAmt
		,VoidCount
	)
	SELECT 
		custid
		,SUM(CASE WHEN liveawayscore = 0 AND bettype IN(33,43) THEN ABS(stake)/2 ELSE ABS(stake) END) AS VoidAmt
		,COUNT(transid) AS VoidCount
	FROM 
		bodb02.dbo.Bettrans WITH(NOLOCK)
	WHERE 
		statusID in (101, 102) -- 'VOID','REJECT'
		AND bettype <= 19999
		AND Bettype NOT IN (903, 500, 913, 914)
		AND winlostdate = @_Winlostdate
	GROUP BY 
		custid    
	    
	--3: Transfer rptStatement	
	INSERT INTO #rptStatementTable(
		Custid
		,TransferAmt
		,TransCount
	)
	SELECT 
		custid
		,SUM(winlost - actual_stake) AS TransferAmt
		,COUNT(transid) AS TransCount
	FROM  
		bodb02.dbo.bettrans WITH(NOLOCK)
	WHERE  
		matchid = 0 
		AND bettype > 20000  
		AND bettype NOT IN (23001,23002,23101,23102,23201,23202)
		AND winlostdate = @_Winlostdate  
	GROUP BY 
		custid
			
	--4: Opening Balance for rptStatement
	IF (@_Winlostdate = @CurrentBU_Date)
	BEGIN
		--get Opening Balance with bettype = 20000 from bettrans
		INSERT INTO #rptStatementTable(
			Custid
			,OpeningBalance
		)
		SELECT
			custid
			,SUM(winlost - actual_stake) AS OpeningBalance
		FROM 
			bodb02.dbo.bettrans WITH(NOLOCK)
		WHERE 
			winlostdate = @_Winlostdate
			AND bettype = 20000
		GROUP BY custid
	END
	ELSE -- winlostdate > CurrentBU_Date
	BEGIN
		-- AIO - Openning balance	
		-- transfer: Healine, Member & SMA
		-- bet: member
		;
		WITH cte_bettrans AS (
			SELECT
				b.custid,b.recommend,b.mrecommend,b.srecommend
				,SUM(b.winlost - b.actual_stake) AS winlost
				,SUM(b.playercomm) AS playercomm
				,SUM(b.comm) AS comm
				,SUM(b.acomm) AS acomm
				,SUM(b.scomm) AS scomm
				,SUM(b.awinlost) AS awinlost
				,SUM(b.mwinlost) AS mwinlost
				,SUM(b.swinlost) AS swinlost

			FROM
				bodb02.dbo.bettrans b WITH(NOLOCK)

			WHERE
				b.winlostdate >= @CurrentBU_Date 
				AND b.winlostdate < @_Winlostdate
				AND b.ruben = 1
			GROUP BY b.custid,b.recommend,b.mrecommend,b.srecommend
		)
		INSERT INTO #rptStatementTable(
				custid
				,OpeningBalance
			)
		SELECT
			c.custid
			,SUM(CASE 
					WHEN b.custid = c.custid THEN c.owner_winlost + c.owner_comm 
					ELSE c.sma_winlost + c.sma_comm 
				END) AS OpeningBalance
		FROM
			cte_bettrans b
		OUTER APPLY (
			SELECT b.custid, playercomm AS owner_comm, winlost AS owner_winlost, 0 AS sma_winlost, 0 AS sma_comm
			UNION
			SELECT b.recommend, 0, winlost, awinlost, comm - playercomm
			UNION
			SELECT b.mrecommend, 0, winlost, mwinlost, acomm - comm
			UNION
			SELECT b.srecommend, 0, winlost, swinlost, scomm - acomm
		) AS c
		GROUP BY c.custid
	END
	
	--5: Headline's openning balance per super
	;
	WITH CTE_Headline AS (
		SELECT DISTINCT cs.custid, cs.UplineID 
		FROM bodb02.dbo.CustSuper cs WITH (NOLOCK)
		WHERE cs.UplineID > 0
	)
	, CTE_HeadlineBalance AS (
		SELECT h.UplineID AS custid, SUM(OpeningBalance) AS OpeningBalance
		FROM #rptStatementTable b
		INNER JOIN CTE_Headline h ON b.custid = h.custid
		GROUP BY h.UplineID
	)
	INSERT INTO #rptStatementTable(
		custid
		,OpeningBalance
	)
	SELECT custid,OpeningBalance
	FROM CTE_HeadlineBalance
		
	--6: Grand Prize
	INSERT INTO #rptStatementTable(
		custid
		,GrandPrize
	)				
	SELECT custid
		,SUM(WinAmount) AS GrandPrize
	FROM
		DBACC.bodb02.dbo.PayoutTrans WITH(NOLOCK) 
	WHERE
		winlostdate = @_Winlostdate			
		AND PayoutStatusId IN (4, 5)  ----- 'Completed', 'Expired'

	GROUP BY custid

	-- UPDATE data rptStatement
	IF EXISTS(SELECT TOP 1 * FROM dbo.rptStatement WITH(NOLOCK) WHERE winlostdate = @_Winlostdate)
	BEGIN
		DELETE 
			dbo.rptStatement 
		WHERE 
			winlostdate = @_Winlostdate
	END

	--INSERT INTO rptStatement
	INSERT INTO dbo.rptStatement(
		Winlostdate
		,Custid
		,OpeningBalance
		,VoidAmt
		,Turnover
		,NetTurnover
		,TransferAmt
		,Winlost
		,Comm
		,ClosingBalance
		,GrandPrize
	)
	SELECT 
		@_Winlostdate AS Winlostdate
		,tmp.Custid
		,SUM(ISNULL(tmp.Openingbalance, 0)) AS [OpeningBalance]
		,SUM(tmp.Voidamt) AS [VoidAmt]
		,SUM(CASE WHEN tmp.BetCount > 0 THEN tmp.Turnover ELSE NULL END) AS [Turnover]
		,SUM(CASE WHEN tmp.BetCount > 0 THEN tmp.NetTurnover ELSE NULL END) AS [NetTurnover]
		,SUM(tmp.Transferamt) AS [TransferAmt]
		,SUM(CASE WHEN tmp.BetCount > 0 THEN tmp.Winlost ELSE NULL END) AS [Winlost]
		,SUM(CASE WHEN tmp.BetCount > 0 THEN tmp.Comm ELSE NULL END) AS [Comm]
		,SUM(ISNULL(tmp.Openingbalance, 0) + ISNULL(tmp.[Winlost], 0) + ISNULL(tmp.[Comm], 0) + ISNULL(tmp.[TransferAmt], 0)) AS ClosingBalance
		,SUM(tmp.GrandPrize) AS GrandPrize
	FROM 
		#rptStatementTable tmp
	GROUP BY 
		tmp.Custid
	HAVING
		DATEPART(DW,@_Winlostdate)=7
		OR
		(SUM(tmp.BetCount) 
		+ SUM(tmp.VoidCount)
		+ SUM(tmp.TransCount)) <> 0		

	--- UPDATE New column TotalBalance from rptTotalBalance_Active ------------
	UPDATE 	s
	SET 	s.OpeningTotalBalance = t.OpeningTotalBalance
	FROM 	dbo.rptStatement s WITH (ROWLOCK)
	INNER JOIN dbo.rptTotalBalance_Active t WITH (NOLOCK) 
		ON 	t.CustID = s.CustID
			AND s.Winlostdate = t.Winlostdate
	WHERE s.WinlostDate = @_Winlostdate
		
	------ Delete from rptTotalBalance_Active		

	DECLARE @OldDate DATE 
	SELECT @OldDate = DATEADD(DD, -3, @_Winlostdate)
	 
		
	DELETE  dbo.rptTotalBalance_Active WITH (ROWLOCK)
	WHERE 	WinlostDate <= @OldDate

	DROP TABLE #rptStatementTable
END
GO