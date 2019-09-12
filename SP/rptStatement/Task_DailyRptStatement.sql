/*<info serverAlias="DBRPT-bodb_Report" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_DailyRptStatement]
	@Winlostdate DATE
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

	DECLARE @rptStatementTable TABLE(
		Winlostdate			DATE
		,Custid				INT
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
		,IsHeadline			BIT		DEFAULT 0
	)

	-- 1: get sum data from Bettrans into rptStatement
	-- Member
	INSERT INTO @rptStatementTable(
		Winlostdate
		,Custid
		,Turnover
		,netTurnover
		,Winlost
		,Comm
		,BetCount
	)
	SELECT
		winlostdate
		,custid
		,SUM(CASE WHEN statusID NOT IN(103) 
				THEN CASE WHEN liveawayscore = 0 AND bettype IN(33,43) THEN ABS(stake)/2 ELSE ABS(stake) END 
				ELSE 0 END) AS Turnover
		,0 AS netTurnover
		,SUM(winlost - actual_stake) AS winlost
		,SUM(playercomm) AS comm
		,COUNT(CASE WHEN Bettype = 500 THEN NULL ELSE transid END) AS betcount
	FROM
		bodb02.dbo.Bettrans WITH(NOLOCK)
	WHERE
		winlostdate = @Winlostdate
		AND statusID NOT IN (0,1,102,101) -- 'running','waiting','VOID','REJECT'
		AND bettype <= 19999
		AND ruben = 1
	GROUP BY
		winlostdate, custid
			
	-- Agent
	INSERT INTO @rptStatementTable(
		Winlostdate
		,Custid
		,Turnover
		,netTurnover
		,Winlost
		,Comm
		,BetCount
	)
	SELECT
		winlostdate
		,recommend
		,SUM(CASE WHEN statusID NOT IN(103) 
				THEN CASE WHEN liveawayscore = 0 AND bettype IN(33,43) THEN ABS(stake)/2 ELSE ABS(stake) END
				ELSE 0 END) AS Turnover
		,SUM(CASE WHEN statusID NOT IN(103) 
				THEN CASE WHEN liveawayscore = 0 AND bettype IN(33,43) THEN ABS(stake*apositiontaking)/2 ELSE ABS(stake*apositiontaking) END 
				ELSE 0 END) AS netTurnover
		,SUM(awinlost) AS winlost
		,SUM(comm - playercomm) AS comm
		,COUNT(CASE WHEN Bettype = 500 THEN NULL ELSE transid END) AS betcount
	FROM
		bodb02.dbo.Bettrans WITH(NOLOCK)
	WHERE
		winlostdate = @Winlostdate
		AND statusID NOT IN (0,1,102,101) -- 'running','waiting','VOID','REJECT'
		AND bettype <= 19999
		AND ruben = 1
	GROUP BY
		winlostdate, recommend
		
	-- Master
	INSERT INTO @rptStatementTable(
		Winlostdate
		,Custid
		,Turnover
		,netTurnover
		,Winlost
		,Comm
		,BetCount
	)
	SELECT
		winlostdate
		,mrecommend
		,SUM(CASE WHEN statusID NOT IN(103) 
				THEN CASE WHEN liveawayscore = 0 AND bettype IN(33,43) THEN ABS(stake)/2 ELSE ABS(stake) END 
				ELSE 0 END) AS Turnover
		,SUM(CASE WHEN statusID NOT IN(103) 
				THEN CASE WHEN liveawayscore = 0 AND bettype IN(33,43) THEN ABS(stake*mpositiontaking)/2 ELSE ABS(stake*mpositiontaking) END 
				ELSE 0 END) AS netTurnover
		,SUM(mwinlost) AS winlost
		,SUM(acomm - comm) AS comm
		,COUNT(CASE WHEN Bettype = 500 THEN NULL ELSE transid END) AS betcount
	FROM
		bodb02.dbo.Bettrans WITH(NOLOCK)
	WHERE
		winlostdate = @Winlostdate
		AND statusID NOT IN (0,1,102,101) -- 'running','waiting','VOID','REJECT'
		AND bettype <= 19999
		AND ruben = 1
	GROUP BY
		winlostdate, mrecommend
		
	-- Super
	INSERT INTO @rptStatementTable(
		Winlostdate
		,Custid
		,Turnover
		,netTurnover
		,Winlost
		,Comm
		,BetCount
	)
	SELECT
		winlostdate
		,srecommend
		,SUM(CASE WHEN statusID NOT IN(103) 
				THEN CASE WHEN liveawayscore = 0 AND bettype IN(33,43) THEN ABS(stake)/2 ELSE ABS(stake) END
				ELSE 0 END) AS Turnover
		,SUM(CASE WHEN statusID NOT IN(103) 
				THEN CASE WHEN liveawayscore = 0 AND bettype IN(33,43) THEN ABS(stake*spositiontaking)/2 ELSE ABS(stake*spositiontaking) END 
				ELSE 0 END) AS netTurnover
		,SUM(swinlost) AS winlost
		,SUM(scomm - acomm) AS comm
		,COUNT(CASE WHEN Bettype = 500 THEN NULL ELSE transid END) AS betcount
	FROM
		bodb02.dbo.Bettrans WITH(NOLOCK)
	WHERE
		winlostdate = @Winlostdate
		AND statusID NOT IN (0,1,102,101) -- 'running','waiting','VOID','REJECT'
		AND bettype <= 19999
		AND ruben = 1
	GROUP BY
		winlostdate, srecommend
		
	--2: void/ Cancelled Bet - get data from bettrans with status = 102
	-- Member
	INSERT INTO @rptStatementTable(
		Winlostdate
		,Custid
		,VoidAmt
		,VoidCount
	)
	SELECT 
		winlostdate
		,custid
		,SUM(CASE WHEN liveawayscore = 0 AND bettype IN(33,43) THEN ABS(stake)/2 ELSE ABS(stake) END) AS VoidAmt
		,COUNT(transid) AS VoidCount
	FROM 
		bodb02.dbo.Bettrans WITH(NOLOCK)
	WHERE 
		statusID in (101, 102) -- 'VOID','REJECT'
		AND bettype <= 19999
		AND Bettype NOT IN (903, 500, 913, 914)
		AND winlostdate = @Winlostdate
	GROUP BY 
		winlostdate, custid    
	    
	--3: Transfer rptStatement	
	INSERT INTO @rptStatementTable(
		Winlostdate
		,Custid
		,TransferAmt
		,TransCount
	)
	SELECT 
		winlostdate
		,custid
		,SUM(winlost - actual_stake) AS TransferAmt
		,COUNT(transid) AS TransCount
	FROM  
		bodb02.dbo.bettrans WITH(NOLOCK)
	WHERE  
		matchid = 0 
		AND bettype > 20000  
		AND bettype NOT IN (23001,23002,23101,23102,23201,23202)
		AND winlostdate = @Winlostdate  
	GROUP BY 
		winlostdate, custid
			
	--4: Opening Balance for rptStatement
	DECLARE @CurrentBU_Date DATETIME  

	SELECT TOP 1 @CurrentBU_Date = winlostdate
	FROM bodb02.dbo.bettrans WITH(NOLOCK) 
	WHERE matchid = 0 AND bettype = 20000

	IF (@Winlostdate = @CurrentBU_Date)
	BEGIN
		--get Opening Balance with bettype = 20000 from bettrans
		WITH CTE_SMABalance AS (
			SELECT
				@Winlostdate AS Winlostdate
				,custid
				,SUM(winlost - actual_stake) AS OpeningBalance
			FROM 
				bodb02.dbo.bettrans WITH(NOLOCK)
			WHERE 
				winlostdate = @CurrentBU_Date
				AND bettype = 20000
			GROUP BY custid
		), CTE_Headline AS (
			SELECT DISTINCT cs.custid, cs.UplineID 
			FROM bodb02.dbo.CustSuper cs WITH (NOLOCK)
			WHERE cs.UplineID > 0
		), CTE_HeadlineBalance AS (
			SELECT Winlostdate, h.UplineID as custid, SUM(OpeningBalance) AS OpeningBalance
			FROM CTE_SMABalance b
			INNER JOIN CTE_Headline h ON b.custid = h.custid
			GROUP BY b.Winlostdate, h.UplineID
		)
		INSERT INTO @rptStatementTable(
			Winlostdate
			,Custid
			,OpeningBalance
		)
		SELECT Winlostdate, custid, OpeningBalance
		FROM CTE_SMABalance

		UNION ALL 
		SELECT Winlostdate, custid, OpeningBalance
		FROM CTE_HeadlineBalance

			
	END
	ELSE -- winlostdate > CurrentBU_Date
	BEGIN
		-- Opening Balance for Member
		INSERT INTO @rptStatementTable(
			Winlostdate
			,custid
			,OpeningBalance
		)
		SELECT
			@Winlostdate
			,custid
			,SUM(winlost - actual_stake + playercomm) AS OpeningBalance
		FROM
			bodb02.dbo.bettrans WITH(NOLOCK)
		WHERE
			ruben = 1
			AND winlostdate >= @CurrentBU_Date 
			AND winlostdate < @Winlostdate 
			AND	custid <> recommend
			AND custid <> mrecommend
			AND custid <> srecommend
		GROUP BY custid
			
		-- Opening Balance for Agent
		INSERT INTO @rptStatementTable(
			Winlostdate
			,custid
			,OpeningBalance
		)
		SELECT	
			@Winlostdate
			,recommend
			,SUM(CASE WHEN custid = recommend THEN winlost - actual_stake ELSE awinlost + comm - playercomm END) AS OpeningBalance
		FROM
			bodb02.dbo.bettrans WITH(NOLOCK)
		WHERE
			ruben = 1 
			AND winlostdate >= @CurrentBU_Date 
			AND winlostdate < @Winlostdate 
		GROUP BY recommend

		-- Opening Balance for Master
		INSERT INTO @rptStatementTable(
			Winlostdate
			,custid
			,OpeningBalance
		)
		SELECT
			@Winlostdate	
			,mrecommend
			,SUM(CASE WHEN custid = mrecommend THEN winlost - actual_stake ELSE mwinlost + acomm - comm END) AS OpeningBalance
		FROM
			bodb02.dbo.bettrans WITH(NOLOCK)
		WHERE
			ruben = 1 
			AND winlostdate >= @CurrentBU_Date 
			AND winlostdate < @Winlostdate 
		GROUP BY mrecommend

		-- Opening Balance for Super & Headline
		;
		WITH CTE_SuperBalance AS (
			SELECT
				@Winlostdate AS Winlostdate
				,srecommend AS custid
				,SUM(CASE WHEN custid = srecommend THEN winlost - actual_stake ELSE swinlost + scomm - acomm END) AS OpeningBalance
			FROM
				bodb02.dbo.bettrans WITH(NOLOCK)
			WHERE
				ruben = 1 
				AND winlostdate >= @CurrentBU_Date 
				AND winlostdate < @Winlostdate
			GROUP BY srecommend
		)
		,CTE_Headline AS (
			SELECT DISTINCT cs.custid, cs.UplineID 
			FROM bodb02.dbo.CustSuper cs WITH (NOLOCK)
			WHERE cs.UplineID > 0
		), CTE_HeadlineBalance AS (
			SELECT Winlostdate, h.UplineID AS custid, SUM(OpeningBalance) AS OpeningBalance
			FROM CTE_SuperBalance b
			INNER JOIN CTE_Headline h ON b.custid = h.custid
			GROUP BY b.Winlostdate, h.UplineID
		)
		INSERT INTO @rptStatementTable(
			Winlostdate
			,custid
			,OpeningBalance
		)
		SELECT Winlostdate, custid, OpeningBalance
		FROM CTE_SuperBalance

		UNION ALL 
		SELECT Winlostdate, custid, OpeningBalance
		FROM CTE_HeadlineBalance
	END			
		
	--5: Grand Prize
	INSERT INTO @rptStatementTable(
			Winlostdate
			,custid
			,GrandPrize
	)	
	--SELECT 
	--	b.winlostdate
	--	,b.custid
	--	,SUM(bm.Winlost - bm.stake) AS GrandPrize 
	--FROM  
	--	bodb02.dbo.bettrans b WITH(NOLOCK)
	--	INNER JOIN bodb02.dbo.BettransM bm WITH (NOLOCK)
	--		ON b.RefNo = bm.RefNo
	--WHERE  
	--	b.winlostdate = @Winlostdate  
	--	AND b.bettype = 18000
	--	AND b.statusID NOT IN (102,101)
	--	AND b.ruben = 1 
	--	AND bm.statuswinlost <> 0
	--GROUP BY 
	--	b.winlostdate, b.custid

	--UNION ALL 		
				
	SELECT  winlostdate
			,custid
			,SUM(WinAmount) AS GrandPrize
	FROM	DBACC.bodb02.dbo.PayoutTrans WITH(NOLOCK) 
	WHERE	winlostdate = @Winlostdate			
			AND PayoutStatusId IN (4, 5)  ----- 'Completed', 'Expired'
	GROUP BY winlostdate, custid



	-- UPDATE data rptStatement
	IF EXISTS(SELECT TOP 1 * FROM rptStatement WITH(NOLOCK) WHERE winlostdate = @Winlostdate)
	BEGIN
		DELETE 
			dbo.rptStatement 
		WHERE 
			winlostdate = @Winlostdate
	END

	-- INSERT INTO rptStatement
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
		tmp.Winlostdate
		,tmp.Custid
		,SUM(ISNULL(tmp.Openingbalance, 0)) AS [OpeningBalance]
		,SUM(tmp.Voidamt) AS [VoidAmt]
		,SUM(CASE WHEN tmp.BetCount > 0 THEN tmp.Turnover ELSE NULL END) AS [Turnover]
		,SUM(CASE WHEN tmp.BetCount > 0 THEN tmp.Netturnover ELSE NULL END) AS [NetTurnover]
		,SUM(tmp.Transferamt) AS [TransferAmt]
		,SUM(CASE WHEN tmp.BetCount > 0 THEN tmp.Winlost ELSE NULL END) AS [Winlost]
		,SUM(CASE WHEN tmp.BetCount > 0 THEN tmp.Comm ELSE NULL END) AS [Comm]
		,SUM(ISNULL(tmp.Openingbalance, 0) + ISNULL(tmp.[Winlost], 0) + ISNULL(tmp.[Comm], 0) + ISNULL(tmp.[TransferAmt], 0)) AS ClosingBalance
		,SUM(tmp.GrandPrize) AS GrandPrize
	FROM 
		@rptStatementTable tmp
	GROUP BY 
		tmp.Winlostdate
		,tmp.Custid
		,tmp.IsHeadline
	HAVING
		DATEPART(DW,tmp.Winlostdate)=7
		OR
		(SUM(tmp.BetCount) 
		+ SUM(tmp.VoidCount)
		+ SUM(tmp.TransCount)) <> 0		

	----- UPDATE New column TotalBalance from rptTotalBalance_Active ------------
	UPDATE 	s
	SET 	s.OpeningTotalBalance = t.OpeningTotalBalance
	FROM 	dbo.rptStatement s WITH (ROWLOCK)
	INNER JOIN dbo.rptTotalBalance_Active t WITH (NOLOCK) 
		ON 	t.CustID = s.CustID
			AND s.Winlostdate = t.Winlostdate
	WHERE s.WinlostDate = @WinlostDate
		
	------ Delete from rptTotalBalance_Active		

	DECLARE @OldDate DATE 
	SELECT @OldDate = DATEADD(DD, -3, @Winlostdate)
	 
		
	DELETE  dbo.rptTotalBalance_Active WITH (ROWLOCK)
	WHERE 	WinlostDate <= @OldDate
END
GO