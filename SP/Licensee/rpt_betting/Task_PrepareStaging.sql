/*<info serverAlias="DB053-bodb_LicenseeReport" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_PrepareStaging]
    @DateFrom		SMALLDATETIME = NULL
    ,@DateTo		SMALLDATETIME = NULL
	,@ErrorMsg		VARCHAR(MAX) = '' OUTPUT
	,@ProductCodes	VARCHAR(1000) = ''
AS

/*
Created:
Task:
DB: DBLIC.bodb_LicenseeReport

Revisions:
    -20120423@Jim: Add more information for BARM agent 
    -20120613@Don: Fixed bug 'custid=0'
    -20150127@Don: Expand bet type ranges for Sportbook when processing BA
	-20150324@Jim: exclude waiting ticket
	-20150623@Patrick: Support BetTrade
	-20150003@Patrick: #42910 (Exclude ticket 901 for BA ticket)
	-20150929@Patrick: Revise code of BetTrade
	-20160118@Patrick: Hotfix: #51053 for bettrade - turn off BA for ticket 901
	-20160318@Victor:  Support Colossus bet - [Redmine: #52575]
	-20160726@Francis: Move SP to bodb_LicenseeReport - [Redmine: #60449]
	-20160727@Jim: LRF - Commercial terms changed for Bet Trade [Redmine: #61342]
	-20160913@Jim: LRF - Implement Colossus Bets [Redmine: #63785 :fix refno issue]
	-20161121@Sophia: Correct formula CashOutAmount,WinPrizeAmount value [RedmineID : #67473]
	-20161205@Jim: LA - GD commercial terms changed for credit sites [RedmineID #67310]
	-20170323@Harper: LA - Implement Cashout Product [Redmine: #73310]
	-20170525@Paul: Check IsStagingBettrans flag before staging bettrans; insert sporttype, eventdate into staging match table [Redmine: #72914]
	-20170619@Harper: LA - Edit formula when cout CO ticket [Redmine: #78085]
	-20180316@Harper: LA - Colossus Bets Free Play Integration [RedmineID: #89768]
	-20180910@Bruce: LA - WL report for Poker Games & Bullfighting [#98487]
	-20181107@Patrick: DB052 Indexes Revolution [Redmine: #103572]
	-20181226@bruce: Implement E-sport 2 [Redmine: #105723]
	-20190306@Parsons: Implement BetBuilder [Redmine: #108995]
	-20190819@Parsons: Provide House Turnover In NG WL Report [Redmine: #117674]
	- 20190910@Amanda: Add bet types that support Half Won/ Half Lose [RedmineID: #118300]
	- 20190923@Amanda: Change the way to handle Half Won/ Half Lose bet types [RedmineID: #119879]
	- 20191205@Percy: Enhance performance [RedmineID: #125028]

Param's Explanation:
	EXEC Task_PrepareStaging '2018-02-01', '2018-02-28'
*/
BEGIN
	SET NOCOUNT ON;

	UPDATE bodb02.dbo.SystemSettings WITH(ROWLOCK, UPDLOCK)
	SET VValue = 1
	WHERE VName = 'IsStagingBettrans'
		AND VValue = 0

	IF @@ROWCOUNT = 0
	BEGIN
		SET @ErrorMsg = 'Another task is using staging bettrans';

		RAISERROR(@ErrorMsg, 16, 1)

		RETURN;
	END

	DECLARE @FromDate SMALLDATETIME, @ToDate SMALLDATETIME

	IF @DateFrom IS NOT NULL AND @DateTo IS NOT NULL
		SELECT @ToDate = CONVERT(VARCHAR(10), @DateTo, 120), @FromDate = CONVERT(VARCHAR(10), @DateFrom, 120)
	ELSE
		SELECT @ToDate = CONVERT(VARCHAR(10), DATEADD(DAY, -1, GETDATE()), 120), @FromDate = DATEADD(DAY, -3, @ToDate)

	-- outright --
	TRUNCATE TABLE dbo.outright
	
    INSERT INTO dbo.outright(matchid, leagueid)
	SELECT orid AS matchid, leagueid
    FROM bodb02.dbo.outright WITH (NOLOCK)
    WHERE eventdate BETWEEN @FromDate AND @ToDate
    UNION ALL
    SELECT orid AS matchid, leagueid
    FROM bodb02.dbo.outright14 WITH (NOLOCK)
    WHERE eventdate BETWEEN @FromDate AND @ToDate

	-- match --
	TRUNCATE TABLE dbo.match
	
    INSERT INTO dbo.match(matchid, leagueid, sporttype, eventdate)
	SELECT matchid, leagueid, sporttype, eventdate
    FROM bodb02.dbo.match (NOLOCK)
    WHERE eventdate BETWEEN @FromDate AND @ToDate
    UNION ALL
    SELECT matchid, leagueid, sporttype, eventdate
    FROM bodb02.dbo.match14 (NOLOCK)
    WHERE eventdate BETWEEN @FromDate AND @ToDate
	  
	-- bettrans --
	TRUNCATE TABLE dbo.bettrans
	
	DECLARE @__matchIds TABLE (matchid INT)
    
	CREATE TABLE #BetTradeCust (custid int PRIMARY KEY)
	CREATE TABLE #CashoutCust (CustId INT PRIMARY KEY)

	INSERT INTO #BetTradeCust(CustId)
	SELECT CustId FROM bodb02.dbo.f_GetBetTradeCustList('ALL')

	INSERT INTO #CashoutCust(CustId)
	SELECT CustId FROM bodb02.dbo.f_GetCashoutCustList('ALL', 14) -- 14: VendorID of Cashout
    
	DECLARE @BettypeProductMapping TABLE (Bettype INT, ProductID INT)
	INSERT INTO @BettypeProductMapping (Bettype, ProductID)
	SELECT Bettype, ProductId FROM bodb_licensee.dbo.LA_f_BettypeProductMapping(0, @ProductCodes)

	DECLARE @HasCBProduct BIT = 1
	IF(@ProductCodes <> '' AND NOT EXISTS (SELECT TOP 1 1 FROM @BettypeProductMapping WHERE ProductID = 15))
	BEGIN
		SET @HasCBProduct = 0
	END

	DECLARE @CBTicket TABLE (transid BIGINT, CashInAmount MONEY, CashOutAmount MONEY, WinPrizeAmount MONEY, transdesc VARCHAR(500))
	
	DECLARE @HWHLCutDate SMALLDATETIME = '2019-10-01' -- half won/ half lose cut date

	DECLARE @MoveBetsDay SMALLDATETIME
	SELECT  @MoveBetsDay = MAX(eventdate) FROM bodb02.dbo.match14 WITH (NOLOCK)

	DECLARE @tmpDate SMALLDATETIME
	SELECT  @tmpDate = @ToDate
	
	WHILE @tmpDate >= @FromDate
	BEGIN
		DELETE @__matchIds

		IF @tmpDate > @MoveBetsDay
		BEGIN
			IF @HasCBProduct = 1
			BEGIN
				INSERT INTO @CBTicket (transid, CashInAmount, CashOutAmount, WinPrizeAmount, transdesc)
				SELECT	b.transid
						,bm.CashInAmount
						,CASE WHEN b.statusID = 112 AND b.winlost - b.actual_stake < 0 THEN bm.CashOutAmount ELSE 0 END AS CashOutAmount
						,CASE WHEN b.statusID = 112 AND b.winlost - b.actual_stake < 0 THEN bm.WinPrizeAmount ELSE 0 END AS WinPrizeAmount
						,CONVERT(VARCHAR(500), bm.transdesc)
				FROM bodb02.dbo.bettrans b WITH (NOLOCK) 
					CROSS APPLY (
						SELECT
							SUM(CASE WHEN bm.bettype = 18002 THEN bm.oddsspread ELSE 0 END) AS CashInAmount
							,SUM(CASE WHEN bm.bettype = 18002 THEN bm.winlost - bm.stake ELSE 0 END) AS CashOutAmount
							,SUM(CASE WHEN bm.bettype IN (18004, 18005, 18006) THEN bm.winlost - bm.stake ELSE 0 END) AS WinPrizeAmount
							,SUM(CONVERT(MONEY, bm.transdesc)) AS transdesc
						FROM bodb02.dbo.bettransm bm WITH (NOLOCK)
						WHERE b.refno = bm.refno
							AND bm.bettype BETWEEN 18000 AND 18006
					) bm
				WHERE b.bettype = 18000
					AND b.winlostdate = @tmpDate
			END

		    INSERT INTO @__matchIds (matchid)
            SELECT matchid FROM bodb02.dbo.bettrans (NOLOCK) WHERE winlostdate = @tmpDate AND bettype < 19001 GROUP BY matchid

			IF @ProductCodes = ''
			BEGIN
				INSERT INTO dbo.bettrans
				(
					transid,winlostdate,liveindicator,bettype,custid,stake,actual_stake,winlost,awinlost,mwinlost,swinlost
					,acomm,scomm,playercomm,comm,matchid,status,statusid,srecommend,currency,recommend,mrecommend,transdate
					,virtualrate,discount,tpositiontaking,customercategory,isBA,refno,oddsspread,ExtraInfo,betdaqid,TicketType
					,CashOutAmount
				)
				SELECT 
					b.transid,b.winlostdate,b.liveindicator,b.bettype,b.custid,ABS(b.stake),b.actual_stake,b.winlost,b.awinlost,b.mwinlost,b.swinlost
					,b.acomm,b.scomm,b.playercomm,b.comm,b.matchid
					,CASE	WHEN b.modds IN (-0.25, 0.25) AND b.statusID IN (112, 113) -- won/lose
								THEN CASE	WHEN b.winlostdate >= @HWHLCutDate
												THEN CASE WHEN (b.bettype < 31 OR b.bettype BETWEEN 121 AND 999 OR b.bettype BETWEEN 9001 AND 9399)
																AND b.bettype NOT IN (29, 911, 912, 913, 914) THEN 'HALF ' ELSE '' END
											ELSE CASE WHEN b.bettype IN (1, 3, 7, 8, 17, 18, 124, 125, 482, 483, 484, 485) THEN 'HALF ' ELSE '' END END
							ELSE '' END + b.status AS status
					,CASE	WHEN b.modds IN (-0.25, 0.25) AND b.statusID IN (112, 113) -- won/lose
								THEN CASE	WHEN b.winlostdate >= @HWHLCutDate
												THEN CASE WHEN (b.bettype < 31 OR b.bettype BETWEEN 121 AND 999 OR b.bettype BETWEEN 9001 AND 9399)
																AND b.bettype NOT IN (29, 911, 912, 913, 914) THEN CASE WHEN b.statusID = 112 THEN 114 ELSE 115 END ELSE b.statusID END
											ELSE CASE WHEN b.bettype IN (1, 3, 7, 8, 17, 18, 124, 125, 482, 483, 484, 485) THEN CASE WHEN b.statusID = 112 THEN 114 ELSE 115 END ELSE b.statusID END END
							ELSE b.statusID END AS statusid
					,b.srecommend,b.currency,b.recommend,b.mrecommend,b.transdate
					,b.virtualrate,b.discount,b.tpositiontaking
					,CASE	WHEN b.recommend = 52466 THEN 27 -- 8RM
							WHEN b.recommend = 5707545 THEN 28 -- BARM
							WHEN b.bettype = 901 THEN CASE WHEN b.transid2 = 0 THEN 1001 ELSE 1002 END -- bettrade
							WHEN b.bettype = 911 THEN CASE WHEN b.transid2 = 0 THEN 1003 ELSE 1004 END -- cashout
							ELSE -1 END AS customercategory
					,CASE	WHEN b.transid2 = 1 AND b.bettype NOT IN (901, 911) AND (b.bettype NOT BETWEEN 1401 AND 1499) THEN 1 ELSE 0 END AS isBA
					,b.refno,b.oddsspread
					,CASE WHEN b.bettype BETWEEN 1401 AND 1499 THEN CAST(b.transid2 AS VARCHAR(50)) ELSE b.ExtraInfo END -- poker games: gem & insurance
					,b.betdaqid,ISNULL(b.currency2, 0) AS TicketType
					,CASE WHEN b.bettype = 911 THEN b.actual_stake END AS CashOutAmount
				FROM @__matchIds m
					CROSS APPLY (
						SELECT	b.transid,b.winlostdate,b.liveindicator,b.bettype,b.custid,b.stake,b.actual_stake,b.winlost,b.awinlost,b.mwinlost,b.swinlost
								,b.acomm,b.scomm,b.playercomm,b.comm,b.matchid,b.status,b.statusid,b.srecommend,b.currency,b.recommend,b.mrecommend,b.transdate
								,b.virtualrate,b.discount,b.tpositiontaking,b.refno,b.oddsspread,b.ExtraInfo,b.betdaqid,b.modds,b.transid2,b.currency2
						FROM bodb02.dbo.bettrans b (NOLOCK)
						WHERE b.matchid = m.matchid
							AND b.bettype < 19001
							AND b.winlostdate = @tmpDate
							AND b.custid > 0
							AND b.recommend > 0
							AND b.statusid NOT IN (0, 101, 102, 121) -- exclude waiting, reject, void ticket (statusID = 1)
					) b
			END
			ELSE
			BEGIN
				INSERT INTO dbo.bettrans
				(
					transid,winlostdate,liveindicator,bettype,custid,stake,actual_stake,winlost,awinlost,mwinlost,swinlost
					,acomm,scomm,playercomm,comm,matchid,status,statusid,srecommend,currency,recommend,mrecommend,transdate
					,virtualrate,discount,tpositiontaking,customercategory,isBA,refno,oddsspread,ExtraInfo,betdaqid,TicketType
					,CashOutAmount
				)
				SELECT 
					b.transid,b.winlostdate,b.liveindicator,b.bettype,b.custid,ABS(b.stake),b.actual_stake,b.winlost,b.awinlost,b.mwinlost,b.swinlost
					,b.acomm,b.scomm,b.playercomm,b.comm,b.matchid
					,CASE	WHEN b.modds IN (-0.25, 0.25) AND b.statusID IN (112, 113) -- won/lose
								THEN CASE	WHEN b.winlostdate >= @HWHLCutDate
												THEN CASE WHEN (b.bettype < 31 OR b.bettype BETWEEN 121 AND 999 OR b.bettype BETWEEN 9001 AND 9399)
																AND b.bettype NOT IN (29, 911, 912, 913, 914) THEN 'HALF ' ELSE '' END
											ELSE CASE WHEN b.bettype IN (1, 3, 7, 8, 17, 18, 124, 125, 482, 483, 484, 485) THEN 'HALF ' ELSE '' END END
							ELSE '' END + b.status AS status
					,CASE	WHEN b.modds IN (-0.25, 0.25) AND b.statusID IN (112, 113) -- won/lose
								THEN CASE	WHEN b.winlostdate >= @HWHLCutDate
												THEN CASE WHEN (b.bettype < 31 OR b.bettype BETWEEN 121 AND 999 OR b.bettype BETWEEN 9001 AND 9399)
																AND b.bettype NOT IN (29, 911, 912, 913, 914) THEN CASE WHEN b.statusID = 112 THEN 114 ELSE 115 END ELSE b.statusID END
											ELSE CASE WHEN b.bettype IN (1, 3, 7, 8, 17, 18, 124, 125, 482, 483, 484, 485) THEN CASE WHEN b.statusID = 112 THEN 114 ELSE 115 END ELSE b.statusID END END
							ELSE b.statusID END AS statusid
					,b.srecommend,b.currency,b.recommend,b.mrecommend,b.transdate
					,b.virtualrate,b.discount,b.tpositiontaking
					,CASE	WHEN b.recommend = 52466 THEN 27 -- 8RM
							WHEN b.recommend = 5707545 THEN 28 -- BARM
							WHEN b.bettype = 901 THEN CASE WHEN b.transid2 = 0 THEN 1001 ELSE 1002 END -- bettrade
							WHEN b.bettype = 911 THEN CASE WHEN b.transid2 = 0 THEN 1003 ELSE 1004 END -- cashout
							ELSE -1 END AS customercategory
					,CASE	WHEN b.transid2 = 1 AND b.bettype NOT IN (901, 911) AND (b.bettype NOT BETWEEN 1401 AND 1499) THEN 1 ELSE 0 END AS isBA
					,b.refno,b.oddsspread
					,CASE WHEN b.bettype BETWEEN 1401 AND 1499 THEN CAST(b.transid2 AS VARCHAR(50)) ELSE b.ExtraInfo END -- poker games: gem & insurance
					,b.betdaqid,ISNULL(b.currency2, 0) AS TicketType
					,CASE WHEN b.bettype = 911 THEN b.actual_stake END AS CashOutAmount
				FROM @__matchIds m
					CROSS APPLY (
						SELECT	b.transid,b.winlostdate,b.liveindicator,b.bettype,b.custid,b.stake,b.actual_stake,b.winlost,b.awinlost,b.mwinlost,b.swinlost
								,b.acomm,b.scomm,b.playercomm,b.comm,b.matchid,b.status,b.statusid,b.srecommend,b.currency,b.recommend,b.mrecommend,b.transdate
								,b.virtualrate,b.discount,b.tpositiontaking,b.refno,b.oddsspread,b.ExtraInfo,b.betdaqid,b.modds,b.transid2,b.currency2
						FROM bodb02.dbo.bettrans b (NOLOCK)
							INNER JOIN @BettypeProductMapping bm ON b.bettype = bm.bettype
						WHERE b.matchid = m.matchid
							AND b.bettype < 19001
							AND b.winlostdate = @tmpDate
							AND b.custid > 0
							AND b.recommend > 0
							AND b.statusid NOT IN (0, 101, 102, 121) -- exclude waiting, reject, void ticket (statusID = 1)
					) b
			END

			UPDATE b
			SET b.ExtraInfo			= cb.transdesc
				,b.CashOutAmount	= cb.CashOutAmount
				,b.CashInAmount		= cb.CashInAmount
				,b.WinPrizeAmount	= cb.WinPrizeAmount
			FROM dbo.bettrans b
				INNER JOIN @CBTicket cb ON b.transid = cb.transid AND b.bettype = 18000
        END
		ELSE
        BEGIN
			IF @HasCBProduct = 1
			BEGIN
				INSERT INTO @CBTicket (transid, CashInAmount, CashOutAmount, WinPrizeAmount, transdesc)
				SELECT	b.transid
						,bm.CashInAmount
						,CASE WHEN b.statusID = 112 AND b.winlost - b.actual_stake < 0 THEN bm.CashOutAmount ELSE 0 END AS CashOutAmount
						,CASE WHEN b.statusID = 112 AND b.winlost - b.actual_stake < 0 THEN bm.WinPrizeAmount ELSE 0 END AS WinPrizeAmount
						,CONVERT(VARCHAR(500), bm.transdesc)
				FROM bodb02.dbo.bettrans14 b WITH (NOLOCK) 
					CROSS APPLY (
						SELECT
							SUM(CASE WHEN bm.bettype = 18002 THEN bm.oddsspread ELSE 0 END) AS CashInAmount
							,SUM(CASE WHEN bm.bettype = 18002 THEN bm.winlost - bm.stake ELSE 0 END) AS CashOutAmount
							,SUM(CASE WHEN bm.bettype IN (18004, 18005, 18006) THEN bm.winlost - bm.stake ELSE 0 END) AS WinPrizeAmount
							,SUM(CONVERT(MONEY, bm.transdesc)) AS transdesc
						FROM bodb02.dbo.bettransm14 bm WITH (NOLOCK)
						WHERE b.refno = bm.refno
							AND bm.bettype BETWEEN 18000 AND 18006
					) bm
				WHERE b.bettype = 18000
					AND b.winlostdate = @tmpDate
			END

			INSERT INTO dbo.bettrans
			(
				transid,winlostdate,liveindicator,bettype,custid,stake,actual_stake,winlost,awinlost,mwinlost,swinlost
				,acomm,scomm,playercomm,comm,matchid,status,statusid,srecommend,currency,recommend,mrecommend,transdate
				,virtualrate,discount,tpositiontaking,customercategory,isBA,refno,oddsspread,ExtraInfo,betdaqid,TicketType
				,CashOutAmount,CashInAmount,WinPrizeAmount
			)
			SELECT 
			    b.transid,b.winlostdate,b.liveindicator,b.bettype,b.custid,ABS(b.stake),b.actual_stake,b.winlost,b.awinlost,b.mwinlost,b.swinlost
				,b.acomm,b.scomm,b.playercomm,b.comm,b.matchid
				,CASE	WHEN b.modds IN (-0.25, 0.25) AND b.statusID IN (112, 113) -- won/lose
							THEN CASE	WHEN b.winlostdate >= @HWHLCutDate
											THEN CASE WHEN (b.bettype < 31 OR b.bettype BETWEEN 121 AND 999 OR b.bettype BETWEEN 9001 AND 9399)
															AND b.bettype NOT IN (29, 911, 912, 913, 914) THEN 'HALF ' ELSE '' END
										ELSE CASE WHEN b.bettype IN (1, 3, 7, 8, 17, 18, 124, 125, 482, 483, 484, 485) THEN 'HALF ' ELSE '' END END
						ELSE '' END + b.status AS status
				,CASE	WHEN b.modds IN (-0.25, 0.25) AND b.statusID IN (112, 113) -- won/lose
							THEN CASE	WHEN b.winlostdate >= @HWHLCutDate
											THEN CASE WHEN (b.bettype < 31 OR b.bettype BETWEEN 121 AND 999 OR b.bettype BETWEEN 9001 AND 9399)
															AND b.bettype NOT IN (29, 911, 912, 913, 914) THEN CASE WHEN b.statusID = 112 THEN 114 ELSE 115 END ELSE b.statusID END
										ELSE CASE WHEN b.bettype IN (1, 3, 7, 8, 17, 18, 124, 125, 482, 483, 484, 485) THEN CASE WHEN b.statusID = 112 THEN 114 ELSE 115 END ELSE b.statusID END END
						ELSE b.statusID END AS statusid
				,b.srecommend,b.currency,b.recommend,b.mrecommend,b.transdate
				,b.virtualrate,b.discount,b.tpositiontaking
				,CASE	WHEN b.recommend = 52466 THEN 27 -- 8RM
						WHEN b.recommend = 5707545 THEN 28 -- BARM
						WHEN b.bettype = 901 THEN CASE WHEN b.transid2 = 0 THEN 1001 ELSE 1002 END -- bettrade
						WHEN b.bettype = 911 THEN CASE WHEN b.transid2 = 0 THEN 1003 ELSE 1004 END -- cashout
						ELSE -1 END AS customercategory
				,CASE	WHEN b.transid2 = 1 AND b.bettype NOT IN (901, 911) AND (b.bettype NOT BETWEEN 1401 AND 1499) THEN 1 ELSE 0 END AS isBA
				,b.refno,b.oddsspread
				,CASE WHEN b.bettype BETWEEN 1401 AND 1499 THEN CAST(b.transid2 AS VARCHAR(50)) WHEN b.bettype = 18000 THEN c.transdesc ELSE b.ExtraInfo END -- poker games: gem & insurance
				,b.betdaqid,ISNULL(b.currency2, 0) AS TicketType
				,CASE WHEN b.bettype = 911 THEN b.actual_stake ELSE c.CashOutAmount END AS CashOutAmount
				,c.CashInAmount,c.WinPrizeAmount
			FROM bodb02.dbo.bettrans14 b WITH (NOLOCK)
				LEFT JOIN @CBTicket c ON b.transid = c.transid AND b.bettype = 18000
			WHERE b.statusid NOT IN (101, 102, 121)
				AND b.winlostdate = @tmpDate
				AND b.custid > 0
				AND (@ProductCodes = '' OR b.bettype IN (SELECT Bettype FROM @BettypeProductMapping))
        END

		SELECT @tmpDate = DATEADD(DAY, -1, @tmpDate)
	END
	
	-- update BA ticket
	UPDATE b
	SET isBA = CASE WHEN isBA = 1 AND b.bettype NOT IN (912, 913, 914) THEN 1 ELSE 0 END
		,customercategory = CASE WHEN isBA = 0 THEN 1003 ELSE 1004 END -- Cashout
	FROM dbo.bettrans b
		INNER JOIN #CashoutCust ctc ON b.CustId = ctc.CustId
			
	UPDATE b
	SET isBA = CASE WHEN isBA = 1 AND b.bettype NOT IN (902, 903, 904) THEN 1 ELSE 0 END
		,customercategory = CASE WHEN isBA = 0 THEN 1001 ELSE 1002 END -- bettrade
	FROM dbo.bettrans b
		INNER JOIN #BetTradeCust btc ON b.CustId = btc.CustId

    CREATE TABLE #BATransids (transID bigint)

    SELECT @ToDate = current_timestamp

    INSERT #BATransids(transid)
    SELECT b.transid
    FROM dbo.bettrans b (NOLOCK)
	    INNER JOIN bodb_Licensee.dbo.LicenseeBAHistory h (NOLOCK) ON b.custid = h.custid AND (transdate BETWEEN OnDate AND ISNULL(OffDate, @ToDate))
    WHERE b.bettype < 31 OR (b.bettype BETWEEN 121 AND 999) OR (b.bettype BETWEEN 1301 AND 1399) OR (b.bettype BETWEEN 9001 AND 9399) OR b.bettype = 38
	    AND tpositiontaking = 0
		AND b.bettype NOT IN (901, 902, 903, 904, 911, 912, 913, 914)

    UPDATE dbo.bettrans
    SET IsBA = 1
    WHERE transid IN (SELECT transid FROM #BATransids)

	DROP TABLE #BATransids
	DROP TABLE #BetTradeCust
	DROP TABLE #CashoutCust
END
GO