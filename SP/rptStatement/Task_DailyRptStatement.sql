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
		Custid				INT PRIMARY KEY
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
		,OpeningTotalBalance DECIMAL(37,4)	NULL
	)

	-- GET the current BU day
	SELECT TOP 1 @CurrentBU_Date = winlostdate
	FROM bodb02.dbo.bettrans WITH(NOLOCK) 
	WHERE matchid = 0 AND bettype = 20000

	SELECT @_Winlostdate = @Winlostdate

	-- 1. SUM BET/VOID/TRANSFER
	-- TRANSFER: Headline, Member & SMA
	-- BET/VOID: Member
	;
	WITH bettrans_temp AS (
		SELECT b.custid,b.recommend,b.mrecommend,b.srecommend
			,bet.transIndicator
			,bet.roleID
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
		FROM
			bodb02.dbo.bettrans b WITH(READPAST)
		OUTER APPLY (
			SELECT 
				CASE 
					WHEN b.statusID IN(103) THEN 0 -- Refund
					ELSE ABS(b.stake)
				END AS stake
				,CASE 
					WHEN b.bettype > 20000 AND b.bettype NOT IN (23001,23002,23101,23102,23201,23202) THEN POWER(2*1,1) --> transfer
					WHEN b.bettype <= 19999 AND b.statusID IN (101,102) AND b.bettype NOT IN (903, 500, 913, 914) THEN POWER(2*1,2) --> void bet
					WHEN b.bettype <= 19999 THEN POWER(2*1,3) --> normal bet
					ELSE 0
					END AS transIndicator
				,CASE 
					WHEN b.custid = b.recommend THEN 2 -- agent
					WHEN b.custid = b.mrecommend THEN 3 -- master
					WHEN b.custid = b.srecommend THEN 4 -- super
					ELSE 1 --member & headline
				END AS roleID
				
		) AS bet
		WHERE
			b.winlostdate = @_Winlostdate
			AND b.statusID NOT IN (0,1) -- 'running','waiting'
			AND bet.transIndicator > 0
		GROUP BY b.winlostdate,b.custid,b.recommend,b.mrecommend,b.srecommend
			,bet.transIndicator
			,bet.roleID
	)
	INSERT INTO #rptStatementTable(
		Custid
		,BetCount
		,Turnover
		,netTurnover
		,Winlost
		,Comm
		,VoidCount
		,VoidAmt
		,TransCount
		,TransferAmt
	)
	SELECT
		c.custid
		,SUM(bet.betIndicator) AS BetCount
		,SUM(b.stake * bet.betIndicator) AS Turnover
		,SUM(c.net_stake * bet.betIndicator) AS netTurnover
		,SUM(c.winlost * bet.betIndicator) AS winlost
		,SUM(c.comm * bet.betIndicator) AS comm
		,SUM(c.voidIndicator) AS VoidCount
		,SUM(b.stake * c.voidIndicator) AS VoidAmt
		,SUM(c.IsOwner * bet.transferIndicator) AS TransCount
		,SUM(c.IsOwner * b.winlost * bet.transferIndicator) AS TransferAmt
	FROM
		bettrans_temp b
	OUTER APPLY (
		SELECT (2 & transIndicator)/2 AS transferIndicator
			,(4 & transIndicator)/4 AS voidIndicator
			,(8 & transIndicator)/8 AS betIndicator
			,POWER(2*1,b.roleID) AS ownerIndicator
	) AS bet
	OUTER APPLY (
		SELECT b.custid						AS custid
			, 0								AS net_stake
			, b.winlost						AS winlost
			, b.playercomm					AS comm
			, bet.voidIndicator				AS voidIndicator
			, 1								AS levelID
			, ((bet.ownerIndicator & 2)/2)	AS IsOwner
		UNION ALL
		SELECT b.recommend, anet_stake, awinlost, comm - playercomm, 0, 2, ((bet.ownerIndicator & 4)/4)
		UNION ALL
		SELECT b.mrecommend, mnet_stake, mwinlost, acomm - comm, 0, 3, ((bet.ownerIndicator & 8)/8)
		UNION ALL
		SELECT b.srecommend, snet_stake, swinlost, scomm -acomm, 0, 4, ((bet.ownerIndicator & 16)/16)
	) AS c
	WHERE c.levelID >= b.roleID
		AND c.custid > 0
	GROUP BY
		c.custid
	
	-- 2. SUM Grand Prize
	;
	WITH CTE_GrandPrize	AS (
		SELECT custid
			,SUM(WinAmount) AS GrandPrize
		FROM
			DBACC.bodb02.dbo.PayoutTrans WITH(NOLOCK) 
		WHERE
			winlostdate = @_Winlostdate			
			AND PayoutStatusId IN (4, 5)  ----- 'Completed', 'Expired'

		GROUP BY custid
	)
	MERGE #rptStatementTable AS TGR
	USING CTE_GrandPrize AS SRC
	ON TGR.custid = SRC.custid
	WHEN MATCHED THEN
		UPDATE 
		SET GrandPrize = SRC.GrandPrize
	WHEN NOT MATCHED BY TARGET THEN
		INSERT (custid, GrandPrize)
		VALUES (
			SRC.custid
			, SRC.GrandPrize
		)
	;

	-- 3. SUM OPENNING [balance & total balance]
	;
	WITH cte_bettrans AS (
		SELECT
			b.custid,b.recommend,b.mrecommend,b.srecommend
			,bet.roleID
			,SUM(CASE WHEN bet.roleid = 1 THEN winlost-actual_stake + playercomm ELSE 0 END) Winlost1
			,SUM(CASE WHEN bet.roleid = 2 THEN winlost-actual_stake ELSE awinlost+comm-playercomm END) Winlost2
			,SUM(CASE WHEN bet.roleid = 3 THEN winlost-actual_stake ELSE mwinlost+acomm-comm END) Winlost3
			,SUM(CASE WHEN bet.roleid = 4 THEN winlost-actual_stake ELSE swinlost+scomm-acomm END) Winlost4
		FROM
			bodb02.dbo.bettrans b WITH(READPAST)
		OUTER APPLY (
			SELECT CASE 
				WHEN b.custid = b.recommend THEN 2 -- agent
				WHEN b.custid = b.mrecommend THEN 3 -- master
				WHEN b.custid = b.srecommend THEN 4 -- super
				ELSE 1 --member & headline
			END AS roleID
		) AS bet
		WHERE 
			b.winlostdate >= @CurrentBU_Date 
			AND b.winlostdate < @_Winlostdate
			AND b.statusID NOT IN (0, 1)
		GROUP BY b.custid,b.recommend,b.mrecommend,b.srecommend
			,bet.roleID
	)
	,CTE_Balance AS (
		SELECT
			c.custid
			,SUM(ISNULL(c.winlost,0)) AS OpeningBalance
			,SUM(ISNULL(c.totalWinlost,0)) AS OpeningTotalBalance
		FROM
			cte_bettrans b
		OUTER APPLY (
			SELECT b.custid, winlost1 AS winlost, 1 AS levelID, winlost1 AS totalWinlost
			UNION
			SELECT b.recommend, winlost2, 2, winlost1 + winlost2
			UNION
			SELECT b.mrecommend, winlost3, 3, winlost1 + winlost2 + winlost3
			UNION
			SELECT b.srecommend, winlost4, 4, winlost1 + winlost2 + winlost3 + winlost4
		) AS c
		WHERE c.levelID >= b.roleID
			AND c.custid > 0
		GROUP BY c.custid
	)
	MERGE #rptStatementTable AS TGR
	USING CTE_Balance AS SRC
	ON TGR.custid = SRC.custid
	WHEN MATCHED THEN
		UPDATE 
		SET OpeningBalance = SRC.OpeningBalance
		,OpeningTotalBalance = SRC.OpeningTotalBalance
	WHEN NOT MATCHED BY TARGET THEN
		INSERT (custid, OpeningBalance, OpeningTotalBalance)
		VALUES (SRC.custid, SRC.OpeningBalance, SRC.OpeningTotalBalance)
	;

	--5. Headline - Openning total balance
	;
	WITH CTE_HeadlineTotalBalance AS 
	(
		SELECT cs.UplineId, SUM(tmp.OpeningTotalBalance) AS OpeningTotalBalance
		FROM bodb02.dbo.CustSuper cs WITH(NOLOCK)
		INNER JOIN #rptStatementTable tmp ON cs.custid = tmp.Custid
		WHERE cs.UplineId > 0
		GROUP BY cs.UplineId
	)
	UPDATE tmp
	SET OpeningTotalBalance += bal.OpeningTotalBalance
	FROM #rptStatementTable tmp
	INNER JOIN CTE_HeadlineTotalBalance bal ON tmp.Custid = bal.UplineId
	
	-- 6.INSERT into rptStatement
	;
	WITH CTE_rptStatement AS (
		SELECT 
			@_Winlostdate AS Winlostdate
			,tmp.Custid
			,(ISNULL(tmp.Openingbalance, 0)) AS [OpeningBalance]
			,(CASE WHEN tmp.BetCount > 0 THEN tmp.Turnover ELSE NULL END) AS [Turnover]
			,(CASE WHEN tmp.BetCount > 0 THEN tmp.NetTurnover ELSE NULL END) AS [NetTurnover]
			,(CASE WHEN tmp.BetCount > 0 THEN tmp.Winlost ELSE NULL END) AS [Winlost]
			,(CASE WHEN tmp.BetCount > 0 THEN tmp.Comm ELSE NULL END) AS [Comm]
			,(CASE WHEN tmp.VoidCount > 0 THEN tmp.Voidamt ELSE NULL END) AS [VoidAmt]
			,(CASE WHEN tmp.TransCount > 0 THEN tmp.TransferAmt ELSE NULL END) AS [TransferAmt]
			,(tmp.GrandPrize) AS GrandPrize
			,(ISNULL(tmp.Openingbalance, 0) + ISNULL(tmp.[Winlost], 0) + ISNULL(tmp.[Comm], 0) + ISNULL(tmp.[TransferAmt], 0)) AS ClosingBalance
			,(ISNULL(OpeningTotalBalance,0)) AS OpeningTotalBalance
		FROM 
			#rptStatementTable tmp
		WHERE 
			DATEPART(DW, @_Winlostdate) = 7
			OR (
				(ISNULL(tmp.VoidCount, 0)) <> 0
				OR (ISNULL(tmp.BetCount, 0)) <> 0
				OR (ISNULL(tmp.TransCount, 0)) <> 0
				OR (ISNULL(tmp.GrandPrize, 0)) <> 0
			)
	)
	MERGE INTO dbo.rptStatement_xpre AS TGR
	USING CTE_rptStatement AS SRC
	ON TGR.Winlostdate = SRC.Winlostdate AND TGR.Custid = SRC.Custid
	WHEN MATCHED AND TGR.Winlostdate = @_Winlostdate THEN
	UPDATE 
		SET OpeningBalance = SRC.OpeningBalance
			,VoidAmt = SRC.VoidAmt
			,Turnover = SRC.Turnover
			,NetTurnover = SRC.NetTurnover
			,TransferAmt = SRC.TransferAmt
			,Winlost = SRC.Winlost
			,Comm = SRC.Comm
			,ClosingBalance = SRC.ClosingBalance
			,GrandPrize = SRC.GrandPrize
			,OpeningTotalBalance = SRC.OpeningTotalBalance

	WHEN NOT MATCHED BY TARGET THEN
	INSERT (
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
			,OpeningTotalBalance
		)
		VALUES (
			@_Winlostdate
			,SRC.Custid
			,SRC.OpeningBalance
			,SRC.VoidAmt
			,SRC.Turnover
			,SRC.NetTurnover
			,SRC.TransferAmt
			,SRC.Winlost
			,SRC.Comm
			,SRC.ClosingBalance
			,SRC.GrandPrize
			,SRC.OpeningTotalBalance
		) 
				
	WHEN NOT MATCHED BY SOURCE AND TGR.Winlostdate = @_Winlostdate THEN
		DELETE
	;

	DROP TABLE #rptStatementTable
END
GO