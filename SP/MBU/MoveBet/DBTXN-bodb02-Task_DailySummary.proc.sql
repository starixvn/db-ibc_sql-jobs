/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_DailySummary]
(
	@winlostdate SMALLDATETIME,
	@step TINYINT = 0
)
AS

-- Run on TransDB
-- update outright on DB02 via linksed server
-- called DB02 : Task_DailySummary_DB02_Copy/Delete via linked server

/*
Created by:[]
Date:
Task: daily summary
DB: DBTXN/BODB02
Revisions:
    - 20100825@Lukas: Update last time modify (changetime column) for Outright table
	- 20100914@Jamie: Modify Bingo and Number Game
	- 20101007@Henry: Change column transid from INT to BIGINT
	- 20101229@Viet: Add moving for data from BingoBall table
	- 20110523@Jamie: Re-arrange bet type : 1 - 19000 : used for bet tickets
	- 20110803@Henry: expand bettype Number Game from 81 to 120
    - 20110910@Viet: Check running tickets of MP combination
    - 20110822@Sophia: Count Negative stake as positive turnover
    - 20111005@Tom: 1. Edit bet type of P2P: 72->1000
					2. Remove parameter @ABSDate '2011-09-01'      
	- 20120206@Sophia: Add Sporttype for Live Casino    
	- 20120807@Sophia: Add Virtual Sports (sporttype = 180 for representing)
	- 20120927@Sophia: Add column comstatus when insert into bettrans tabble
	- 20130313@Viet: add netTurnover
	- 20130520@Victor: add VSOutright
	- 20130715@Dan: delete match_log, outright_log
	- 20131108@Elodie: Splitting bodb02 into CustDB (call custinfo, Customer, Exchange by link database)
					   Use DBPRO instead of DB02, DBACC instead of DB06
	- 20140305@Vivi: add move translog to translog14
	- 20140313@Elodie: Add Keno product in sum_winloss table
	- 20150511@Sophia: Add Gold Deluxe in sum_winloss table
    - 20150617@Daniel: Linked server update permission restrict: Call nested SP update syssetting in DBACC
	- 20150619@Sophia: Add 1 more bettype for Gold Deluxe, AG Casino and Vegas Game [#37683]
	- 20150721@Sophia: Apply Microgaming product in sum_winloss table [#39772]
	- 20150914@Sophia: Apply Colosuss Bets and expand the range of AG Casino product in sum_winloss table [#39772]
	- 20151118@Sophia: Apply Microgaming - RNG Casino [RedmineId: #46450]
	- 20160105@Sophia: Apply Cockfighting [Redmine: #48601]
	- 20160114@Daniel: Data verification: check table bettransRNG & bettransLC
	- 20160125@Sophia: Apply OW RNG Casino[Redmine: #49297]
	- 20160203@Sophia: Apply Cricket - exclude betcount of bettype 500 [Redmine: #50027]
	- 20160204@Sophia: Apply Allbet [Redmine: #50605]
	- 20160225@Sophia: Add new column TurnoverNoDraw [Redmine: #51427]
	- 20160426@Sophia: Apply Voidbridge [Redmine: #55259]
	- 20160704@Lukas: add waittime to wait for completely done whole move events before start next day
	- 20160909@Patrick: Record IsMovingBet value to systemsettings table on dbtrans.bodb02
	- 20160809@Percy: Modify Net Turnover for Allbet [RedmineID: #60501]
	- 20161010@Patrick: Apply NG2 [Redmine: #65460]
	- 20170105@Percy: Apply Fishing World [RedmineID: #65731]
	- 20170530@Patrick: Modify Auto Void block code to prevent deadlock
	- 20170710@Percy: Apply Betradar Virtual Sport [RedmineID: #78339]
	- 20170710@Percy: Apply Keno Lottery [RedmineID: #78064]
	- 20170726@Percy: Expand bettype range of OneRnG Casino - Tablet Game [RedmineID: #78424]
	- 20170906@Percy: Apply Lucky 3 [RedmineID: #76770]
	- 20170915@Patrick: Update code for:
			+ Delete data bettrans/translog/bettransRnG/bettransLC/bettransG batch by batch
			+ Add more signal to replicated servers when MB/BU starting or done
			+ Set current datetime value to checktime field when insert ticket 19999
			+ When processing a line then insert itself and upline's to [List]
	- 20171010@Percy: Apply Bullfighting [RedmineID: #84690]
	- 20171225@Sophia: Integrate CitiBet Exchange Products [Redmine: #82408]
	- 20180117@Patrick: Integrate with Bonus project
	- 20180420@Alvin: Incorporate Pragmatic - change bettype range for Macau Games & add bettype range for Pragmatic [Redmine: #92647]
	- 20180424@Percy: Check condition of GrossComm formula to prevent case division zero [RedmineID: #94234]
	- 20180904@Sophia: Add product Poker Games [Redmine: #93050]
	- 20180912@Percy: Bullfighting - Add data into TurnoverNoDraw column [RedmineID: #101288]
	- 20180914@Percy: Poker Games - Modify GrossComm [RedmineID: #101550]
	- 20181023@Percy: Expand bettype range of Sportsbook [RedmineID: #102924]
	- 20181126@Percy: Incorporate Happy 5 into Number Game [RedmineID: #104283]
	- 20190131@Patrick: Delete bettransm batch by batch at replicated servers to reduce lock escalation [RedmineID: #108581]
	- 20190701@Percy: Add Card Club [RedmineID: #115611]
	- 20190826@Percy: Remove inactive products [RedmineID: #118699]
	- 20191029@Percy: Add Spadegaming [RedmineID: #122353]
	- 20191224@Percy: Add Virtual Games [RedmineID: #124906]
	- 20200211@Lukas: update actualrate on tickets when sync winlostdate vs eventdate
	- 20200309@Sophia: integrate SA Gaming [RedmineID: #128057]
	- 20200326@Sophia: Add Saba.Club [RedmineID: #130781]	
	- 20200326@Sophia: Add SexyGame [RedmineID: #130670]
	- 20200326@Sophia: Add Indo 4D [RedmineID: #130236]
	- 20200408@Sophia: Add Table Games [RedmineId: #129438]
	- 20200410@Sophia: Add BBIN [RedmineId: #131358]
	- 20200410@Sophia: Add BBIN, Sexy Gaming, SA Gaming for TurnoverNoDraw[RedmineId: #131358]	
	- 20200422@Sophia: Add IBCBet Live Casino [RedmineId: #130693]
	- 20200527@Sophia: Add ION [Redmine: #132325]
	- 20200528@Sophia: Add RNG War [Redmine: #132013]
	- 20200713@Sophia: Expand Bettype range of Lottery [Redmine: #137542]
	- 20200708@Sol: Generate data for sum_winloss table - Redmine: [#136320]
	- 20200820@Sol: enhence performance when statistics are not updated yet - Redmine: [#136320]
	- 202010316@Patrick: Revise Movebet flow to support transfer 247 - Redmine: [#149927]
	- 20211203@Helen: Movebet failed by deadlock - Redmine: [#165705]
*/
BEGIN
	SET NOCOUNT ON


	DECLARE @Doing NVARCHAR(300) = ''
		, @__index INT = 0
		, @__recommend INT
		, @__delayTimeValue VARCHAR(20) = '00:00:00:020'
		, @__rowAffected INT = 0

	SET @Doing = 'Task_DailySummary : MoveBet step ' + CAST(@step AS VARCHAR(20)) + ' start, on wld: ' + CONVERT(VARCHAR(10), @winlostdate, 121)
	EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

	IF @step = 1--update ticket (if any) which winlostdate is not synced with eventdate 
	BEGIN
		SET @Doing = 'Task_DailySummary : MoveBet step 1.01 - start updating BeingMovebetDate flag, on wld: ' + CONVERT(VARCHAR(10), @winlostdate, 121)
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

		--**update being movebet date flag ==> the purpose of this step is that does not allow for settle tickets which has winlostdate smaller than beingMovebet date
		EXEC dbo.ExecRep_09 @recommend = 0, @winlostdate = @winlostdate, @parlay = 9, @tableName = 'SystemSettings'

		SET @Doing = 'Task_DailySummary : MoveBet step 1.01 - end updating BeingMovebetDate flag, on wld: ' + CONVERT(VARCHAR(10), @winlostdate, 121)
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

		--//
		SELECT @__delayTimeValue = dbo.f_BU_GetDelayTime('BeforeMB')
		WAITFOR DELAY @__delayTimeValue --waitfor all settle running commands can be done to start MB

		-- update ticket (if any) which winlostdate is not synced with eventdate 
		DECLARE @transTable TABLE (transid BIGINT PRIMARY KEY, winlostdate SMALLDATETIME)

		--==sync winlostdate for outright
		INSERT INTO @transTable
		SELECT b.transid, o.eventdate
		FROM dbo.bettrans b WITH (NOLOCK)
			INNER JOIN dbo.outright o WITH(NOLOCK) ON b.matchid = o.orid
		WHERE b.winlostdate <> o.eventdate 
			AND b.bettype = 10
	
		--==sync winlostdate for match
		INSERT INTO @transTable
		SELECT b.transid, m.eventdate
		FROM dbo.bettrans b WITH (NOLOCK)
			INNER JOIN dbo.match m WITH(NOLOCK) ON b.matchid = m.matchid
		WHERE b.winlostdate <> m.eventdate
			AND b.bettype NOT IN (1231,1232,1233,1237,1238) -- exclude vsoutright
			AND b.bettype <> 10 -- exclude outright 
			AND b.bettype NOT BETWEEN 1501 AND 1599  --- exclude keno
			AND b.bettype NOT BETWEEN 1021 AND 1099  --- exclude lottery
	
		--==sync winlostdate for VSOutright
		INSERT INTO @transTable
		SELECT b.transid, o.EventDate
		FROM dbo.bettrans b WITH(NOLOCK)
			INNER JOIN dbo.VSOutright o WITH(NOLOCK) ON b.matchid = o.EventID AND b.oddsid = o.Orid
		WHERE b.winlostdate <> o.eventdate
			AND b.bettype IN (1231,1232,1233,1237,1238)
	
		IF EXISTS (SELECT TOP 1 1 FROM @transTable)
		BEGIN
			UPDATE b WITH(ROWLOCK, UPDLOCK)
			SET b.winlostdate = t.winlostdate,
				b.actualrate = ISNULL(ex.actualrate, b.actualrate)
			FROM dbo.bettrans b
				INNER JOIN @transTable t ON b.transid = t.transid
				INNER JOIN CustDB.dbo.ExchangeDailyOanda ex WITH(NOLOCK) ON b.currency = ex.exchangeid AND ex.exchangeDate = t.winlostdate 
	
			SET @Doing = 'DONE : update winlostdate -vs- eventdate'
			EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing  
		END

		RETURN
	END

	IF @step = 2 -- check qualify data && void UUS tickets
	BEGIN
		DECLARE @transid BIGINT
		-- ====================
		-- DATA VERIFICATION
		-- ====================
		IF EXISTS (
			SELECT transid FROM dbo.bettrans WITH (NOLOCK)
			WHERE statusID = 0
				AND custid <> 0
				AND bettype <=19000 AND bettype <> 10 AND winlostdate <= @winlostdate
				AND currency <> 20
		)
		BEGIN
			SELECT DISTINCT matchid, bettype, 'EXEC DBA_MatchName ' + CAST(matchid AS NVARCHAR(20)) cmd FROM bettrans (nolock)
			WHERE	winlostdate <= @winlostdate 
					AND statusID = 0 
					AND bettype <= 19000 AND bettype NOT IN (9, 10, 29, 2799)
					AND currency <> 20

			SELECT DISTINCT 'EXEC DBA_matchname ' + CAST(bm.matchid AS VARCHAR(10)) matchid, m.eventdate, bm.matchid, ',' [Comma]
			FROM dbo.bettrans b WITH(NOLOCK)
				INNER JOIN dbo.bettransm bm WITH(NOLOCK) ON b.refno = bm.refno
				INNER JOIN dbo.match m WITH(NOLOCK) ON bm.matchid = m.matchid
			WHERE	b.winlostdate <= @winlostdate 
					AND b.statusID = 0 AND bm.statusID = 0 
					AND b.bettype IN (9,29,2799)
					AND b.matchID IN (9,29,2799)
					AND b.currency <> 20
			ORDER BY m.eventdate

			IF @@ROWCOUNT > 0
			BEGIN
				PRINT '--'
				PRINT '--SELECT * FROM bettrans WITH(NOLOCK) WHERE status = ''running'' AND matchid IN (9,29,2799) AND bettype IN (9,29,2799) AND winlostdate <= ''' + CONVERT(VARCHAR(10), @winlostdate, 120) + ''''
				PRINT '--UPDATE dbo.bettrans SET winlostdate = ''' + CONVERT(VARCHAR(10), DATEADD(DAY, 1, @winlostdate), 120) + ''' WHERE transid IN ( xxxxx )'
				PRINT '--'
			END

			RAISERROR ('FAILED: Have running tickets', 16, 1)
			RETURN
		END

		-- ========================================
		-- DATA VERIFICATION - Translog
		-- ========================================
		IF EXISTS (
			SELECT TOP 1 1 FROM translog WITH (NOLOCK)
			WHERE	statusID IN (0, 1)
					AND winlostdate <= @winlostdate
					AND currency <> 20
		)
		BEGIN
			RAISERROR ('FAILED: translog have running/waiting tickets', 16, 1)
			RETURN
		END
		-- ====================

		-- ============================================
		-- DATA VERIFICATION - bettransRNG & bettransLC
		-- ============================================
		IF EXISTS (
			SELECT TOP 1 1 FROM dbo.bettransRNG WITH (NOLOCK)
			WHERE	(statusID = 0 OR isSum = 0)
					AND winlostdate <= @winlostdate
					AND currency <> 20
		)
		BEGIN
			RAISERROR ('FAILED: bettransRNG have running tickets or not summed to bettrans yet', 16, 1)
			RETURN
		END

		IF EXISTS (
			SELECT TOP 1 1 FROM dbo.bettransLC WITH (NOLOCK)
			WHERE	(statusID = 0 OR isSum = 0)
					AND winlostdate <= @winlostdate
					AND currency <> 20
		)
		BEGIN
			RAISERROR ('FAILED: bettransLC have running tickets or not summed to bettrans yet', 16, 1)
			RETURN
		END
		-- ============================================

		IF EXISTS (
			SELECT transid FROM dbo.bettrans WITH (NOLOCK)
			WHERE srecommend <= 100 
				AND (scomm <> acomm OR swinlost <> 0)
				AND bettype <=19000 AND winlostdate = @winlostdate
		)
		BEGIN
			RAISERROR ('FAILED: Incorrect Company SuperAgent setting', 16, 1)
			RETURN
		END
		-- ====================

		IF EXISTS (
			SELECT transid FROM bettrans WITH (NOLOCK)
			WHERE (scomm IS NULL OR acomm IS NULL OR comm IS NULL OR playercomm IS NULL
					OR swinlost IS NULL OR mwinlost IS NULL OR awinlost IS NULL OR winlost IS NULL)
				AND bettype <=19000 AND winlostdate = @winlostdate
		)
		BEGIN
			RAISERROR ('FAILED: Null Commission/WinLost', 16, 1)
			RETURN
		END
		-- ====================

		IF EXISTS (
			SELECT currency
			FROM dbo.bettrans WITH(NOLOCK)
			WHERE bettype <= 19000 AND winlostdate = @winlostdate
				AND NOT (bettype = 10 AND statusID = 0) -- exclude running outright
			GROUP BY currency
			HAVING COUNT(DISTINCT actualrate) > 1
		)
		BEGIN
			RAISERROR ('FAILED: Multiple Exchange Rate', 16, 1)
			RETURN
		END
		-- ====================

		-- =====================
		-- OUTRIGHT WINLOST MOVE
		-- =====================

		SELECT TOP 1 @transid = transid 
		FROM dbo.bettrans WITH (NOLOCK)
		WHERE	bettype = 10 
				AND statusID = 0 
				AND winlostdate = @winlostdate

		IF @@ROWCOUNT > 0
		BEGIN
			DECLARE @outright TABLE (orid INT)

			INSERT INTO @outright 
			SELECT DISTINCT matchid 
			FROM dbo.bettrans WITH (NOLOCK)
			WHERE bettype = 10 
				AND statusID = 0 
				AND winlostdate <= @winlostdate

			UPDATE O
			SET eventdate = DATEADD(DAY, 1, @winlostdate), changeTime = GETDATE()
			FROM DBPRO.bodb02.dbo.outright O WITH (UPDLOCK, ROWLOCK)
			WHERE orid IN (SELECT orid FROM @outright)

			UPDATE bettrans WITH (UPDLOCK, ROWLOCK) 
			SET winlostdate = DATEADD(DAY, 1, @winlostdate)
			WHERE bettype = 10 AND matchid IN (SELECT orid FROM @outright)
		END

		-- =====================
		-- AUTO VOID TEST TICKET
		-- =====================
		IF EXISTS (
			SELECT TOP 1 1 FROM dbo.bettrans WITH (NOLOCK)
			WHERE currency = 20 AND winlostdate = @winlostdate AND bettype <= 19000 AND statusID = 0
		)
		BEGIN
			DECLARE @custs TABLE (custid INT)
		
			CREATE TABLE #__AutoVoid_TransList(TransId BIGINT PRIMARY KEY)
			INSERT INTO #__AutoVoid_TransList(TransId)
			SELECT TransId
			FROM dbo.bettrans b WITH(NOLOCK)
			WHERE b.currency = 20 AND winlostdate = @winlostdate 
				AND bettype <= 19000 AND statusID IN (0, 1)

			DECLARE @__transIdsUUS VARCHAR(MAX), @ErrMsgAutoVoid VARCHAR(200)
			SELECT @__transIdsUUS = COALESCE(@__transIdsUUS + ',' + CAST(transid AS VARCHAR(50)), CAST(transid AS VARCHAR(50)))
			FROM #__AutoVoid_TransList

			EXEC dbo.NAP_SpecialDelete_VoidBetId_UUS @TransIds = @__transIdsUUS
				, @ErrMsg = @ErrMsgAutoVoid OUTPUT

			IF ISNULL(@ErrMsgAutoVoid, '') <> ''
			BEGIN
				PRINT @ErrMsgAutoVoid
			END

			DROP TABLE #__AutoVoid_TransList

		END

		RETURN
	END

	IF @step = 3 -- generate sum tickets
	BEGIN
		-- Clear deleted/cancel record (custid = 0)
		DELETE FROM bettrans WHERE winlostdate = @winlostdate AND custid = 0

		DELETE FROM bettranssum WHERE winlostdate = @winlostdate

		-- Get Recommend
		--reset before start
		TRUNCATE TABLE dbo.Task_Movebet_RecommendList

		--get list of recommend.
		INSERT INTO dbo.Task_Movebet_RecommendList(Recommend, StatusId)
		SELECT DISTINCT recommend, 0 AS SattusId 
		FROM dbo.bettrans WITH(NOLOCK) WHERE winlostdate = @winlostdate AND bettype < 19999 
		UNION 
		SELECT DISTINCT recommend, 0 AS SattusId 
		FROM dbo.translog WITH(NOLOCK) WHERE winlostdate = @winlostdate 

		WAITFOR DELAY '00:00:01'

		-- do double check list of recommend if missing
		INSERT INTO Task_Movebet_RecommendList (recommend,StatusId)
		SELECT b.recommend, 0 AS SattusId
		FROM dbo.bettrans b WITH (NOLOCK)
		WHERE b.winlostdate = @winlostdate AND b.bettype <= 19000
			AND NOT EXISTS (SELECT TOP 1 1 FROM Task_Movebet_RecommendList r WITH (NOLOCK) WHERE r.recommend = b.recommend)
		GROUP BY recommend 

		INSERT INTO Task_Movebet_RecommendList (recommend, StatusId)
		SELECT tl.recommend, 0 AS SattusId 
		FROM dbo.translog tl WITH(NOLOCK) WHERE tl.winlostdate = @winlostdate
			AND NOT EXISTS (SELECT TOP 1 1 FROM Task_Movebet_RecommendList r WITH (NOLOCK) WHERE r.recommend = tl.recommend)
		GROUP BY recommend 

		-- Get Exchange Rate
		DECLARE @Exchange TABLE (currency TINYINT, actualrate FLOAT, CurrencyName NVARCHAR(50))
		INSERT INTO @Exchange (currency, actualrate)
		SELECT DISTINCT currency, actualrate
		FROM dbo.bettrans WITH (NOLOCK)
		WHERE winlostdate = @winlostdate AND bettype <= 19000

		UPDATE @Exchange
			SET CurrencyName = e.currency
		FROM @Exchange ex, CustDB.dbo.exchange e WITH (NOLOCK)
		WHERE ex.currency = e.exchangeid

		-- Generate SUM record
		INSERT INTO dbo.bettranssum
			(custid
			, winlostdate
			, stake, actual_stake
			, winlost, awinlost, mwinlost, swinlost
			, playercomm, comm, acomm, scomm)
		SELECT 
			custid
			, @winlostdate winlostdate
			, SUM(stake) stake, SUM(actual_stake) actual_stake,
			SUM(winlost) winlost, SUM(awinlost) awinlost, SUM(mwinlost) mwinlost, SUM(swinlost) swinlost,
			SUM(playercomm) playercomm, SUM(comm) comm, SUM(acomm) acomm, SUM(scomm) scomm
		FROM dbo.Task_Movebet_RecommendList r WITH (NOLOCK)
			INNER JOIN dbo.bettrans b WITH (INDEX = IX_recommend) ON r.recommend = b.recommend 
		WHERE b.winlostdate = @winlostdate AND b.bettype <= 19000 AND b.statusID NOT IN (101,102)
		GROUP BY custid

		UPDATE s
			SET actualrate = e.actualrate
				, username = c.username
				, currencyname = e.CurrencyName
				, currency = c.currency
				, recommend = c.recommend
				, mrecommend = c.mrecommend
				, srecommend = c.srecommend
		FROM dbo.bettranssum s
			INNER JOIN CustDB.dbo.custinfo c WITH (NOLOCK) ON s.custid = c.custid AND c.roleid = 1
			INNER JOIN @Exchange e ON c.currency = e.currency
		WHERE winlostdate = @winlostdate

		EXEC dbo.Task_BalanceCheck @winlostdate, 1

		RETURN
	END

	IF @step = 4 --copy event | bet data to [14]
	BEGIN
		SET @Doing = 'Task_DailySummary : MoveBet step 4.02 - start turn on MB_DoneCopy_Local | MB_SWinloss_Local | MB_Sum19999_Local flags, on wld: ' + CONVERT(VARCHAR(10), @winlostdate, 121)
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

		--**turn on flag for starting copy to [14]
		--pub SP ExcepRep
		EXEC dbo.ExecRep_09 @recommend = 0, @winlostdate = null, @parlay = 7, @tableName = 'SystemSettings'
		--pub bet
		EXEC dbo.Bet_ExecRep_09	@mode = 7
		--pub bet14
		EXEC dbo.Bet_ExecRep14_01 @Mode = 1, @TableName = 'SystemSettings'

		SET @Doing = 'Task_DailySummary : MoveBet step 4.02 - end turn on MB_DoneCopy_Local | MB_SWinloss_Local | MB_Sum19999_Local flags, on wld: ' + CONVERT(VARCHAR(10), @winlostdate, 121)
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing
	
		-- viet ----
		EXEC dbo.Task_UpdSystemSetting @VValue = '1', @VName = 'isMovingBet'

		--
		EXEC DBACC.bodb02.dbo.Task_UpdSystemSetting @VValue = '1', @VName = 'isMovingBet'

		--copy event to [14]
		EXEC DBPRO.bodb02.dbo.Task_DailySummary_DB02_Copy @winlostdate

		-- Copy bettransm/bettransg -> bettransm14/bettransg14 for whole day of @winlostdate
		EXEC dbo.ExecRep_08 @recommend = 0, @winlostdate = @winlostdate, @parlay = 1

		SET @Doing = 'Task_DailySummary : MoveBet step 4.20 - start copy bettrans | bettransLC | bettransRnG | translog, on wld: ' + CONVERT(VARCHAR(10), @winlostdate, 121) + ', total recommend: ' + CAST(@@ROWCOUNT AS varchar(10))
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

		SELECT @__index = 1, @__recommend = NULL, @__rowAffected = 0
		WHILE EXISTS (
			SELECT TOP 1 1 FROM dbo.Task_Movebet_RecommendList WHERE RowId >= @__index
		)
		BEGIN
		
			UPDATE TOP(1) ls 
			SET @__recommend = Recommend
				, StatusId = 1 -- copying done
			FROM dbo.Task_Movebet_RecommendList ls WHERE RowId = @__index

			SET @__rowAffected = @@ROWCOUNT
			SET @__index += 1

			IF @__rowAffected = 0
				CONTINUE

			BEGIN TRANSACTION
				--copy ticket from [active] to [14] for bettrans | bettransInfo | translog | bettransLC | bettransRnG
				EXEC dbo.ExecRep_08 @recommend = @__recommend
					, @winlostdate = @winlostdate

			COMMIT TRANSACTION
		
			--waitfor delay on each batch.
			IF @__index % 10 = 0
			BEGIN
				SELECT @__delayTimeValue = dbo.f_BU_GetDelayTime('Key6')
				WAITFOR DELAY @__delayTimeValue --waitfor copying...
			END
		
		END
	
		SET @Doing = 'Task_DailySummary : MoveBet step 4.20 - end copy bettrans | bettransLC | bettransRnG | translog, on wld: ' + CONVERT(VARCHAR(10), @winlostdate, 121)
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

		SET @Doing = 'Task_DailySummary : MoveBet step 4.30 - start turn off MB_DoneCopy_Local flag, on wld: ' + CONVERT(VARCHAR(10), @winlostdate, 121)
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

		--==turn off flag MB_DoneCopy_Local
		EXEC dbo.ExecRep_09 @recommend = 0, @winlostdate = null, @parlay = 8, @tableName = 'SystemSettings'

		SET @Doing = 'Task_DailySummary : MoveBet step 4.30 - end turn off MB_DoneCopy_Local flag, on wld: ' + CONVERT(VARCHAR(10), @winlostdate, 121)
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

		RETURN

	END

	IF @step = 5 --insert data for sum_winloss
	BEGIN
		--//create a sum record for Bonus
		EXEC dbo.Task_Bonus_DailySummary @WinlostDate = @WinlostDate
		-- Insert data of SMA, member to sum_winloss_tmp
		EXEC dbo.Task_Sum_Winloss @winlostdate

		DECLARE @loop VARCHAR(1)
		SET @loop = 'y'
		WHILE @loop = 'y'
		BEGIN
			BEGIN TRANSACTION
			DELETE TOP(2800) FROM dbo.sum_winloss
			WHERE winlostdate = @winlostdate

			IF @@ROWCOUNT = 0 SET @loop = 'n'
				COMMIT TRANSACTION

			WAITFOR DELAY '000:00:01.4'
		END

		SET @loop = 'y'
		WHILE @loop = 'y'
		BEGIN
			BEGIN TRANSACTION
			DELETE TOP(6000) FROM dbo.sum_winloss_tmp
			WHERE winlostdate = @winlostdate
	
			IF @@ROWCOUNT = 0 SET @loop = 'n'
				COMMIT TRANSACTION

			WAITFOR DELAY '000:00:01.4' --waitfor inserting sum_winloss...
		END
	
	
		SET @Doing = 'Task_DailySummary : MoveBet step 5.30 - start turn off MB_SWinloss_Local flag, on wld: ' + CONVERT(VARCHAR(10), @winlostdate, 121)
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

		--==turn off flag MB_SWinloss_Local
		EXEC dbo.Bet_ExecRep14_01 @Mode = 2, @tableName = 'SystemSettings'

		SET @Doing = 'Task_DailySummary : MoveBet step 5.30 - end turn off MB_SWinloss_Local flag, on wld: ' + CONVERT(VARCHAR(10), @winlostdate, 121)
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

		RETURN
	END

	IF @step = 6 --==insert sum ticket 19999
	BEGIN
		SET DEADLOCK_PRIORITY HIGH

		CREATE TABLE #__temp (recommend INT, custid INT PRIMARY KEY (recommend, custid))

		INSERT #__temp (recommend, custid)
		SELECT recommend, custid
		FROM dbo.bettranssum b
		WHERE winlostdate = @winlostdate
		GROUP BY recommend, custid
		ORDER BY recommend, custid

		DECLARE @__runningCust TABLE(recommend INT, custid INT PRIMARY KEY (recommend, custid))
		WHILE 1 = 1
		BEGIN
		
			DELETE FROM @__runningCust

			DELETE TOP(1000) FROM #__temp
			OUTPUT deleted.recommend, deleted.custid INTO @__runningCust(recommend, custid)

			IF @@ROWCOUNT = 0
				BREAK

			BEGIN TRANSACTION
		
				INSERT INTO dbo.bettrans
					(ruben, [status], statusID, matchid, bettype, refno, creator, transdate,
					custid, currency, recommend, mrecommend, srecommend,
					winlostdate, stake, winlost, awinlost, mwinlost, swinlost,
					actual_stake, playercomm, comm, acomm, scomm, 
					apositiontaking, mpositiontaking, spositiontaking, tpositiontaking,
					actualrate, virtualrate, Username, CurrencyName, comstatus, checktime)
				SELECT 1, 'SUM', 142, 0, 19999, refno, 8, winlostdate, --99
					b.custid, b.currency, b.recommend, b.mrecommend, b.srecommend,
					winlostdate, stake, winlost, awinlost, mwinlost, swinlost,
					actual_stake, playercomm, comm, acomm, scomm,
					0, 0, 0, 0,
					actualrate, actualrate, username, CurrencyName, '0', getdate()
				FROM dbo.bettranssum b
				WHERE EXISTS (
						SELECT TOP 1 1 
						FROM @__runningCust t 
						WHERE t.recommend = b.recommend AND t.custid = b.custid AND b.winlostdate = @winlostdate
					)

			COMMIT TRANSACTION
		
			--waitfor delay on each batch.
			SELECT @__delayTimeValue = dbo.f_BU_GetDelayTime('Key11')
			WAITFOR DELAY @__delayTimeValue --waitfor inserting sum 19999...
		
		END

		SET DEADLOCK_PRIORITY NORMAL

		SET @Doing = 'Task_DailySummary : MoveBet step 6.30 - start turn off MB_Sum19999_Local flag, on wld: ' + CONVERT(VARCHAR(10), @winlostdate, 121)
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

		--==turn off flag MB_SWinloss_Local
		EXEC dbo.Bet_ExecRep_09 @Mode = 8

		SET @Doing = 'Task_DailySummary : MoveBet step 6.30 - done turn off MB_Sum19999_Local flag, on wld: ' + CONVERT(VARCHAR(10), @winlostdate, 121)
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

		RETURN
	END

	IF @step = 7 --wait for replicated servers perform done and then go to update movebetdate flag
	BEGIN
		DECLARE @__start DATETIME
		SET @__start = GETDATE()
		WHILE EXISTS (
			SELECT TOP 1 1 FROM dbo.SystemSettings WHERE VName = 'MB_ReadyUpdMBDate' AND VValue <> '0'
		)
		BEGIN
			WAITFOR DELAY '00:00:30:000' --waitfor MB done...
			IF DATEDIFF(MINUTE, @__start, GETDATE()) > 30
			BEGIN
				--send out message for DBA to check...
				PRINT 'hey guys, please check...'
				EXECUTE	DBNOTI.NotificationDB.dbo.DBA_Letstalk_NewJobMessage @ServerName = N'PONTUS', 
					@JobId = NULL, @JobName = N'Custom Message', 
					@Message = 'Urgently!!! Movebet - hey guys, Movebet run long time at step 7. Please check!!!', @CaseId = 1;

				EXECUTE msdb.dbo.sp_send_dbmail @profile_name	= DEFAULT
				   , @recipients			 = 'pontus@starixvn.com' --will replace email address later
				   , @copy_recipients		 = ''
				   , @blind_copy_recipients	 = ''
				   , @subject				 = 'Urgently!!! Movebet - Notification'
				   , @body					 = 'Please call DBA to check since Movebet run long time at step 7.'
				   , @body_format			 = 'HTML';

			END
		END

		--update Movebetdate flag
		EXEC dbo.ExecRep_09 @recommend = 0, @winlostdate = @winlostdate, @parlay = 10, @tableName = 'SystemSettings'

		--//
		SELECT @__delayTimeValue = dbo.f_BU_GetDelayTime('AfterUpdMBD')
		WAITFOR DELAY @__delayTimeValue --waitfor go to delete step...

		RETURN
	END

	IF @step = 8 -- remove bet tickets
	BEGIN
		DELETE dbo.Match_Log 
		WHERE matchID IN (SELECT matchID FROM dbo.match WITH (NOLOCK) WHERE eventdate = @winlostdate)

		DELETE FROM dbo.outright_log
		WHERE orid IN (SELECT orid FROM dbo.outright WHERE eventdate = @winlostdate AND oddsstatus = 'Completed')

		--remove event
		EXEC DBPRO.bodb02.dbo.Task_DailySummary_DB02_Delete @winlostdate

		SET DEADLOCK_PRIORITY HIGH

		--remove ticket on bettransM for whole day of winlostdate
		EXEC dbo.Task_DailySummary_Delete_Bet @winlostdate = @winlostdate, @tableName = 'bettransm'

		-- Delete bettransG for whole day of @winlostdate
		EXEC dbo.ExecRep_09 @recommend = 0, @winlostdate = @winlostdate, @parlay = 2

		DECLARE @__rowDeleted INT
		SELECT @__index = 1, @__recommend = NULL, @__rowDeleted = 1, @__rowAffected = 0
		WHILE EXISTS (
			SELECT TOP 1 1 
			FROM dbo.Task_Movebet_RecommendList WHERE RowId >= @__index
		)
		BEGIN
		
			UPDATE TOP(1) ls 
			SET @__recommend = Recommend
				, StatusId = 3 -- deleting bet ticket done
			FROM dbo.Task_Movebet_RecommendList ls WHERE RowId = @__index
		
			SET @__rowAffected = @@ROWCOUNT
			SET @__index += 1

			IF @__rowAffected = 0
				CONTINUE

			--remove bet ticket on bettransLC by @recommend
			SET @__rowDeleted = 1	
			WHILE @__rowDeleted > 0
			BEGIN
				BEGIN TRANSACTION
					EXEC dbo.ExecRep_09 @recommend = @__recommend
						, @winlostdate = @winlostdate
						, @parlay = 0
						, @tableName = 'bettransLC'
						, @RowDeleted = @__rowDeleted OUTPUT
				COMMIT TRANSACTION
			END

			--remove bet ticket on bettransRNG by @recommend
			SET @__rowDeleted = 1	
			WHILE @__rowDeleted > 0
			BEGIN
				BEGIN TRANSACTION
					EXEC dbo.ExecRep_09 @recommend = @__recommend
						, @winlostdate = @winlostdate
						, @parlay = 0
						, @tableName = 'bettransRNG'
						, @RowDeleted = @__rowDeleted OUTPUT
				COMMIT TRANSACTION
			END

			--remove bet ticket on translog by @recommend
			SET @__rowDeleted = 1	
			WHILE @__rowDeleted > 0
			BEGIN
				BEGIN TRANSACTION
					EXEC dbo.ExecRep_09 @recommend = @__recommend
						, @winlostdate = @winlostdate
						, @parlay = 0
						, @tableName = 'translog'
						, @RowDeleted = @__rowDeleted OUTPUT
				COMMIT TRANSACTION
			END

			--remove bet ticket on bettrans by @recommend
			SET @__rowDeleted = 1	
			WHILE @__rowDeleted > 0
			BEGIN
				BEGIN TRANSACTION
					EXEC dbo.ExecRep_09 @recommend = @__recommend
						, @winlostdate = @winlostdate
						, @parlay = 0
						, @tableName = 'bettrans'
						, @RowDeleted = @__rowDeleted OUTPUT
				COMMIT TRANSACTION
			END

			--waitfor delay on each batch.
			IF @__index % 10 = 0
			BEGIN
				SELECT @__delayTimeValue = dbo.f_BU_GetDelayTime('Key6')
				WAITFOR DELAY @__delayTimeValue --waitfor deleting...
			END
		
		END
	
		SET DEADLOCK_PRIORITY NORMAL
	
		RETURN
	END

	IF @step = 9 -- movebet done
	BEGIN
		SET @Doing = 'Task_DailySummary : MoveBet done'
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

		-- viet ----
		EXEC dbo.Task_UpdSystemSetting @VValue = '0', @VName = 'isMovingBet'
		EXEC DBACC.bodb02.dbo.Task_UpdSystemSetting @VValue = '0', @VName = 'isMovingBet'

		SET @Doing = 'Task_DailySummary : MoveBet step 9.30 - start off BeingMovebetDate flag, on wld: ' + CONVERT(VARCHAR(10), @winlostdate, 121)
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

		--reset being move bet date
		EXEC dbo.ExecRep_09 @recommend = 0, @winlostdate = NULL, @parlay = 9, @tableName = 'SystemSettings'

		SET @Doing = 'Task_DailySummary : MoveBet step 9.30 - end off BeingMovebetDate flag, on wld: ' + CONVERT(VARCHAR(10), @winlostdate, 121)
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing
 
		-- =====================
		EXEC Task_BalanceCheck @winlostdate, 3
		-- =====================

		--//can add more check here...

		SET @Doing = 'Task_DailySummary : End (with Finish)'
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

		PRINT CONVERT(VARCHAR(10), @winlostdate, 120)
	
		RETURN
	END
END
GO