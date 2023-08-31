/*<info serverAlias="DBLIC-bodb_LicenseeReport,DBBAL-bodb_LicenseeReport" isFunction="0" isNested="1"></info>*/
USE bodb_LicenseeReport
GO

ALTER PROCEDURE [dbo].[Task_PrepareStaging_Bettrans]
	@WinLostDate	SMALLDATETIME
	,@ErrorMsg		VARCHAR(MAX) = '' OUTPUT
	,@ProductCodes	VARCHAR(1000) = ''
AS

/*
	Created: 20191205@Percy
	Task: Gen data for bettrans staging
	DB: DBLIC.bodb_LicenseeReport, DBBAL-bodb_LicenseeReport

	Revisions:
		- 20191205@Percy: Split code from Task_PrepareStaging and Enhance performance [RedmineID: #125028]
		- 20200102@Percy: Wrong update BA tickets [RedmineID: #126419]
		- 20201005@Parsons: Saba.club - Offer Free Bets tickets [RedmineID: #141423]
		- 20201029@Parsons: Add ExtraPT in Number Game Win Loss Report [RedmineID: #142969]
		- 20210315@Hogan: Integrate Cricket AIO [RedmineID: #150386]
		- 20210514@Danny: Integrate Vgaming [#154080]
		- 20210518@Percy: Change code to get MoveBetsDay [RedmineID: #154866]
		- 20210707@Danny: Vgaming - Free bets and Jackpot prize integration [Redmine: #156185]
		- 20210816@Sophia: add DBBAL [Redmine: #154300]
		- 20211215@Sophia: Change formula to get BA Transaction - use LicenseeBATransaction_active & LicenseeBATransaction_bk instead of TransID2 [RedmineID: #166077]
		- 20220218@Danny: Get Cricket bettype dynamically [RedmineID: #168802]
		- 20231215@Danny: enhance processing data and performance [Redmine: #190123]

*/

BEGIN
	SET NOCOUNT ON
	
	DECLARE @MBBU TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)
	INSERT INTO @MBBU (BalanceUpDay, MoveBetsDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay
	
	DECLARE @MoveBetsDay SMALLDATETIME
	SELECT  @MoveBetsDay = MoveBetsDay FROM @MBBU

	DECLARE @__matchIds TABLE (rowId INT IDENTITY(1,1), matchid INT, cnt INT, UNIQUE CLUSTERED (rowId))
	DECLARE @__matchIdsByBatch TABLE (matchid INT, cnt INT)

	DECLARE @BettypeProductMapping TABLE (Bettype INT, ProductID INT)

	INSERT INTO @BettypeProductMapping (Bettype, ProductID)
	SELECT Bettype, ProductId FROM bodb_licensee.dbo.LA_f_BettypeProductMapping(0, @ProductCodes)

	DECLARE @batchCount INT = 200000
	
	DECLARE @SBBettype TABLE (Bettype INT)
	INSERT INTO @SBBettype (Bettype)
	SELECT DISTINCT bettype
	FROM bodb02.dbo.SportBettypeMatrix b WITH (NOLOCK)
	WHERE ProductID = 1 
	
	IF @WinlostDate > @MoveBetsDay
	BEGIN
		INSERT INTO @__matchIds (matchid, cnt)
		SELECT matchid, COUNT(transid) cnt
		FROM bodb02.dbo.bettrans WITH(NOLOCK)
		WHERE winlostdate = @winlostdate AND bettype < 19001
		GROUP BY matchid
		ORDER BY cnt ASC

		DECLARE @__rowIndex INT = 1, @__tempCount INT, @__rowCount INT

		WHILE EXISTS (SELECT TOP(1) 1 FROM @__matchIds WHERE rowId = @__rowIndex)
		BEGIN
			DELETE FROM @__matchIdsByBatch
			SET @__tempCount = 0

			AddMoreMatch:
			INSERT INTO @__matchIdsByBatch(matchid, cnt)
			SELECT matchId, cnt 
			FROM @__matchIds WHERE rowId = @__rowIndex

			SET @__rowCount = @@ROWCOUNT
			
			SELECT @__tempCount = SUM(cnt) FROM @__matchIdsByBatch

			SET @__rowIndex = @__rowIndex + 1
			
			IF @__tempCount < @batchCount AND @__rowCount > 0
				GOTO AddMoreMatch

			IF @ProductCodes = ''
			BEGIN
				INSERT INTO dbo.bettrans
				(
					transid,winlostdate,liveindicator,bettype,custid,stake,actual_stake,winlost,awinlost,mwinlost,swinlost,BetID,epositiontaking
					,acomm,scomm,playercomm,comm,matchid,status,statusid,srecommend,currency,recommend,mrecommend,transdate
					,virtualrate,discount,tpositiontaking,customercategory,isBA,refno,oddsspread,ExtraInfo,betdaqid,TicketType
					,CashOutAmount
				)
				SELECT 
					b.transid,b.winlostdate,b.liveindicator,b.bettype,b.custid,ABS(b.stake),b.actual_stake,b.winlost,b.awinlost,b.mwinlost,b.swinlost,b.BetID,b.epositiontaking
					,b.acomm,b.scomm,b.playercomm,b.comm,b.matchid
					,CASE
						WHEN b.modds IN (-0.25, 0.25) AND b.statusID IN (112, 113) -- won/lose
							THEN CASE WHEN b.isAllowHalfWonLose = 1 THEN 'HALF ' ELSE '' END
						ELSE ''
					END + b.status AS status
					,CASE
						WHEN b.modds IN (-0.25, 0.25) AND b.statusID IN (112, 113) -- won/lose
							THEN CASE WHEN b.isAllowHalfWonLose = 1 THEN CASE WHEN b.statusID = 112 THEN 114 ELSE 115 END 
									ELSE b.statusID END
						ELSE b.statusID
					END AS statusid
					,b.srecommend,b.currency,b.recommend,b.mrecommend,b.transdate
					,b.virtualrate,b.discount,b.tpositiontaking
					,CASE
						WHEN b.recommend = 52466 THEN 27 -- 8RM
						WHEN b.recommend = 5707545 THEN 28 -- BARM
						ELSE -1
					END AS customercategory
					,b.isBA
					,b.refno
					,b.oddsspread
					,CASE
						WHEN b.bettype BETWEEN 1401 AND 1499 THEN CAST(b.transid2 AS VARCHAR(50))
						ELSE b.ExtraInfo
					END -- poker games: gem & insurance
					,b.betdaqid
					,CASE
						WHEN m.matchid IN (150, 173) THEN 2 -- 150: Saba.club Free Bet, 173: VGA Free Bet
						WHEN m.matchid IN (200, 171) THEN 0 -- 200: Saba.club Normal Bet, 171  VGA Normal Bet
						ELSE ISNULL(b.currency2, 0) -- currency2 = 1 -> CB Free Play, = 0 -> Normal
					END AS TicketType
					,CASE WHEN b.bettype = 911 THEN b.actual_stake END AS CashOutAmount
				FROM @__matchIdsByBatch m
					CROSS APPLY (
						SELECT	b.transid,b.winlostdate,b.liveindicator,b.bettype,b.custid,b.stake,b.actual_stake,b.winlost,b.awinlost,b.mwinlost,b.swinlost,b.BetID,b.epositiontaking
								,b.acomm,b.scomm,b.playercomm,b.comm,b.matchid,b.status,b.statusid,b.srecommend,b.currency,b.recommend,b.mrecommend,b.transdate
								,b.virtualrate,b.discount,b.tpositiontaking,b.refno,b.oddsspread,b.ExtraInfo,b.betdaqid,b.modds,b.transid2,b.currency2
								,CASE WHEN BA.transid IS NOT NULL THEN 1 ELSE 0	END AS isBA, CASE WHEN bt.Bettype IS NULL OR bt.Bettype IN (29,38) THEN 0 ELSE 1 END isAllowHalfWonLose
						FROM bodb02.dbo.bettrans b (NOLOCK)	
							LEFT JOIN bodb_Licensee.dbo.LicenseeBATransaction_active AS BA WITH (NOLOCK) ON b.transid = BA.transid	
							LEFT JOIN @SBBettype bt ON b.bettype = bt.Bettype
						WHERE b.matchid = m.matchid
							AND b.bettype < 19001
							AND b.winlostdate = @WinlostDate
							AND b.custid > 0
							AND b.recommend > 0
							AND b.statusid NOT IN (0, 101, 102, 121) -- exclude waiting, reject, void ticket (statusID = 1)
								) b
					
			END
			ELSE
			BEGIN
				INSERT INTO dbo.bettrans
				(
					transid,winlostdate,liveindicator,bettype,custid,stake,actual_stake,winlost,awinlost,mwinlost,swinlost,BetID,epositiontaking
					,acomm,scomm,playercomm,comm,matchid,status,statusid,srecommend,currency,recommend,mrecommend,transdate
					,virtualrate,discount,tpositiontaking,customercategory,isBA,refno,oddsspread,ExtraInfo,betdaqid,TicketType
					,CashOutAmount
				)
				SELECT 
					b.transid,b.winlostdate,b.liveindicator,b.bettype,b.custid,ABS(b.stake),b.actual_stake,b.winlost,b.awinlost,b.mwinlost,b.swinlost,b.BetID,b.epositiontaking
					,b.acomm,b.scomm,b.playercomm,b.comm,b.matchid
					,CASE
						WHEN b.modds IN (-0.25, 0.25) AND b.statusID IN (112, 113) -- won/lose
							THEN CASE WHEN b.isAllowHalfWonLose = 1 THEN 'HALF ' ELSE '' END
						ELSE '' END + b.status AS status
					,CASE
						WHEN b.modds IN (-0.25, 0.25) AND b.statusID IN (112, 113) -- won/lose
							THEN CASE WHEN b.isAllowHalfWonLose = 1 THEN 
										CASE WHEN b.statusID = 112 THEN 114 ELSE 115 END
									  ELSE b.statusID END
						ELSE b.statusID
					 END AS statusid
					,b.srecommend,b.currency,b.recommend,b.mrecommend,b.transdate
					,b.virtualrate,b.discount,b.tpositiontaking
					,CASE
						WHEN b.recommend = 52466 THEN 27 -- 8RM
						WHEN b.recommend = 5707545 THEN 28 -- BARM
						ELSE -1
					END AS customercategory
					,b.isBA
					,b.refno
					,b.oddsspread
					,CASE
						WHEN b.bettype BETWEEN 1401 AND 1499 THEN CAST(b.transid2 AS VARCHAR(50))
						ELSE b.ExtraInfo
					END -- poker games: gem & insurance
					,b.betdaqid
					,CASE
						WHEN m.matchid IN (150, 173) THEN 2 -- 150: Saba.club Free Bet, 173: VGA Free Bet
						WHEN m.matchid IN (200, 171) THEN 0 -- 200: Saba.club Normal Bet, 171  VGA Normal Bet
						ELSE ISNULL(b.currency2, 0) -- currency2 = 1 -> CB Free Play, = 0 -> Normal
					 END AS TicketType
					,0 AS CashOutAmount
				FROM @__matchIdsByBatch m
					CROSS APPLY (
						SELECT	b.transid,b.winlostdate,b.liveindicator,b.bettype,b.custid,b.stake,b.actual_stake,b.winlost,b.awinlost,b.mwinlost,b.swinlost,b.BetID,b.epositiontaking
								,b.acomm,b.scomm,b.playercomm,b.comm,b.matchid,b.status,b.statusid,b.srecommend,b.currency,b.recommend,b.mrecommend,b.transdate
								,b.virtualrate,b.discount,b.tpositiontaking,b.refno,b.oddsspread,b.ExtraInfo,b.betdaqid,b.modds,b.transid2,b.currency2
								,CASE WHEN BA.transid IS NOT NULL THEN 1 ELSE 0	END AS isBA, CASE WHEN bt.Bettype IS NULL OR bt.Bettype IN (29,38)  THEN 0 ELSE 1 END isAllowHalfWonLose
						FROM bodb02.dbo.bettrans b (NOLOCK)
							LEFT JOIN bodb_Licensee.dbo.LicenseeBATransaction_active AS BA WITH (NOLOCK) ON b.transid = BA.transid	
							INNER JOIN @BettypeProductMapping bm ON b.bettype = bm.bettype
							LEFT JOIN @SBBettype bt ON b.bettype = bt.Bettype
						WHERE b.matchid = m.matchid
							AND b.bettype < 19001
							AND b.winlostdate = @WinlostDate
							AND b.custid > 0
							AND b.recommend > 0
							AND b.statusid NOT IN (0, 101, 102, 121) -- exclude waiting, reject, void ticket (statusID = 1)
					) b
			END

			WAITFOR DELAY '00:00:01:000'
		END

	END
	ELSE
	BEGIN

		IF @ProductCodes = ''
		BEGIN
			INSERT INTO dbo.bettrans
			(
				transid,winlostdate,liveindicator,bettype,custid,stake,actual_stake,winlost,awinlost,mwinlost,swinlost,BetID,epositiontaking
				,acomm,scomm,playercomm,comm,matchid,status,statusid,srecommend,currency,recommend,mrecommend,transdate
				,virtualrate,discount,tpositiontaking,customercategory,isBA,refno,oddsspread,ExtraInfo,betdaqid,TicketType
				,CashOutAmount,CashInAmount,WinPrizeAmount
			)
			SELECT 
				b.transid,b.winlostdate,b.liveindicator,b.bettype,b.custid,ABS(b.stake),b.actual_stake,b.winlost,b.awinlost,b.mwinlost,b.swinlost,b.BetID,b.epositiontaking
				,b.acomm,b.scomm,b.playercomm,b.comm,b.matchid
				,CASE
					WHEN b.modds IN (-0.25, 0.25) AND b.statusID IN (112, 113) -- won/lose
						THEN CASE WHEN bt.Bettype IS NOT NULL AND bt.Bettype NOT IN (29,38)  THEN 'HALF ' ELSE '' END
					ELSE ''
				END + b.status AS status
				,CASE
					WHEN b.modds IN (-0.25, 0.25) AND b.statusID IN (112, 113) -- won/lose
						THEN CASE WHEN bt.Bettype IS NOT NULL AND bt.Bettype NOT IN (29,38)  THEN CASE WHEN b.statusID = 112 THEN 114 ELSE 115 END
								ELSE b.statusID
							END
					ELSE b.statusID
				END AS statusid
				,b.srecommend,b.currency,b.recommend,b.mrecommend,b.transdate
				,b.virtualrate,b.discount,b.tpositiontaking
				,CASE
					WHEN b.recommend = 52466 THEN 27 -- 8RM
					WHEN b.recommend = 5707545 THEN 28 -- BARM
					WHEN b.bettype = 901 THEN CASE WHEN b.transid2 = 0 THEN 1001 ELSE 1002 END -- bettrade
					WHEN b.bettype = 911 THEN CASE WHEN b.transid2 = 0 THEN 1003 ELSE 1004 END -- cashout
					ELSE -1
				END AS customercategory
				,CASE WHEN BA.transid IS NOT NULL THEN 1 ELSE 0	END AS isBA
				,b.refno
				,b.oddsspread
				,CASE
					WHEN b.bettype BETWEEN 1401 AND 1499 THEN CAST(b.transid2 AS VARCHAR(50))
					ELSE b.ExtraInfo
				END -- poker games: gem & insurance
				,b.betdaqid
				,CASE
					WHEN b.matchid IN (150, 173) THEN 2 -- 150: Saba.club Free Bet, 173: VGA Free Bet
					WHEN b.matchid IN (200, 171) THEN 0 -- 200: Saba.club Normal Bet, 171  VGA Normal Bet
					ELSE ISNULL(b.currency2, 0) -- currency2 = 1 -> CB Free Play, = 0 -> Normal
				END AS TicketType
				,0 AS CashOutAmount
				,0 AS CashInAmount
				,0 AS WinPrizeAmount
			FROM bodb02.dbo.bettrans14 b WITH (NOLOCK)
				LEFT JOIN bodb_Licensee.dbo.LicenseeBATransaction_BK AS BA WITH (NOLOCK) ON b.transid = BA.transid	
				LEFT JOIN @SBBettype bt ON b.bettype = bt.Bettype
			WHERE b.statusid NOT IN (101, 102, 121)
				AND b.winlostdate = @WinlostDate
				AND b.custid > 0
		END
		ELSE
		BEGIN
			INSERT INTO dbo.bettrans
			(
				transid,winlostdate,liveindicator,bettype,custid,stake,actual_stake,winlost,awinlost,mwinlost,swinlost,BetID,epositiontaking
				,acomm,scomm,playercomm,comm,matchid,status,statusid,srecommend,currency,recommend,mrecommend,transdate
				,virtualrate,discount,tpositiontaking,customercategory,isBA,refno,oddsspread,ExtraInfo,betdaqid,TicketType
				,CashOutAmount,CashInAmount,WinPrizeAmount
			)
			SELECT 
				b.transid,b.winlostdate,b.liveindicator,b.bettype,b.custid,ABS(b.stake),b.actual_stake,b.winlost,b.awinlost,b.mwinlost,b.swinlost,b.BetID,b.epositiontaking
				,b.acomm,b.scomm,b.playercomm,b.comm,b.matchid
				,CASE
					WHEN b.modds IN (-0.25, 0.25) AND b.statusID IN (112, 113) -- won/lose
						THEN CASE WHEN bt.Bettype IS NOT NULL AND bt.Bettype NOT IN (29,38)  THEN 'HALF ' ELSE '' END
					ELSE ''
				END + b.status AS status
				,CASE
					WHEN b.modds IN (-0.25, 0.25) AND b.statusID IN (112, 113) -- won/lose
						THEN CASE WHEN bt.Bettype IS NOT NULL AND bt.Bettype NOT IN (29,38)  THEN CASE WHEN b.statusID = 112 THEN 114 ELSE 115 END
								ELSE b.statusID
							END
					ELSE b.statusID
				END AS statusid
				,b.srecommend,b.currency,b.recommend,b.mrecommend,b.transdate
				,b.virtualrate,b.discount,b.tpositiontaking
				,CASE
					WHEN b.recommend = 52466 THEN 27 -- 8RM
					WHEN b.recommend = 5707545 THEN 28 -- BARM
					WHEN b.bettype = 901 THEN CASE WHEN b.transid2 = 0 THEN 1001 ELSE 1002 END -- bettrade
					WHEN b.bettype = 911 THEN CASE WHEN b.transid2 = 0 THEN 1003 ELSE 1004 END -- cashout
					ELSE -1
				END AS customercategory
				,CASE WHEN BA.transid IS NOT NULL THEN 1 ELSE 0	END AS isBA
				,b.refno
				,b.oddsspread
				,CASE
					WHEN b.bettype BETWEEN 1401 AND 1499 THEN CAST(b.transid2 AS VARCHAR(50))
					ELSE b.ExtraInfo
				END -- poker games: gem & insurance
				,b.betdaqid
				,CASE
					WHEN b.matchid IN (150, 173) THEN 2 -- 150: Saba.club Free Bet, 173: VGA Free Bet
					WHEN b.matchid IN (200, 171) THEN 0 -- 200: Saba.club Normal Bet, 171  VGA Normal Bet
					ELSE ISNULL(b.currency2, 0) -- currency2 = 1 -> CB Free Play, = 0 -> Normal
				END AS TicketType
				,0 AS CashOutAmount
				,0 AS CashInAmount
				,0 AS WinPrizeAmount
			FROM bodb02.dbo.bettrans14 b WITH (NOLOCK)
				LEFT JOIN bodb_Licensee.dbo.LicenseeBATransaction_BK AS BA WITH (NOLOCK) ON b.transid = BA.transid	
				INNER JOIN @BettypeProductMapping bm ON b.bettype = bm.bettype
				LEFT JOIN @SBBettype bt ON b.bettype = bt.Bettype
			WHERE b.statusid NOT IN (101, 102, 121)
				AND b.winlostdate = @WinlostDate
				AND b.custid > 0
		END
	END

	-- For BA ticket
	CREATE TABLE #BATransids (transID BIGINT)

	DECLARE @CurrentDate DATETIME
	SELECT	@CurrentDate = current_timestamp

	INSERT #BATransids(transid)
	SELECT b.transid
	FROM dbo.bettrans b (NOLOCK)
		INNER JOIN bodb_Licensee.dbo.LicenseeBAHistory h (NOLOCK) ON b.custid = h.custid AND (transdate BETWEEN OnDate AND ISNULL(OffDate, @CurrentDate))
		INNER JOIN @SBBettype bt ON b.bettype = bt.Bettype
	WHERE tpositiontaking = 0 AND bt.Bettype NOT IN (999, 901, 902, 903, 904)

	UPDATE dbo.bettrans
	SET IsBA = 1
	WHERE transid IN (SELECT transid FROM #BATransids)

	DROP TABLE #BATransids
END
GO