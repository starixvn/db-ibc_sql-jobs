/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_DailySummary]
	@winlostdate datetime,
	@TestMode tinyint = 0
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
	- 20200326@Sophia: Add Saba.Club [RedmineID: #130781]
	- 20200309@Sophia: integrate SA Gaming [RedmineID: #128057]
	
*/

SET NOCOUNT ON

Declare @Doing nvarchar(300)
SET @Doing = 'call Task_DailySummary @winlostdate = ' + CONVERT(nvarchar(10), @winlostdate, 120) + ', @TestMode = ' + CAST(@TestMode as nvarchar(2))
EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing  

-- update ticket (if any) which winlostdate is not synced with eventdate 
DECLARE @transTable TABLE (transid bigint primary key, winlostdate datetime)

--UPDATE b SET winlostdate = o.eventdate
INSERT INTO @transTable
SELECT b.transid, o.eventdate
FROM dbo.bettrans b with (nolock)
	INNER JOIN dbo.outright o witH(nolock) ON b.matchid = o.orid
WHERE b.winlostdate <> o.eventdate 
	--and b.bettype NOT BETWEEN 1501 AND 1599 --no need to move keno bettype because orid <> keno.eventid
	AND b.bettype = 10
	
--UPDATE b SET winlostdate = m.eventdate
INSERT INTO @transTable
SELECT b.transid, m.eventdate
FROM dbo.bettrans b with (nolock)
	INNER JOIN dbo.match m witH(nolock) ON b.matchid = m.matchid
WHERE b.winlostdate <> m.eventdate
	AND b.bettype NOT IN (1231,1232,1233,1237,1238) -- exclude vsoutright
	AND b.bettype <> 10 -- exclude outright 
	AND b.bettype NOT BETWEEN 1501 AND 1599  --- exclude keno
	AND b.bettype NOT BETWEEN 1021 AND 1049  --- exclude lottery
	
--UPDATE b SET winlostdate = o.eventdate
INSERT INTO @transTable
SELECT b.transid, o.EventDate
FROM dbo.bettrans b with (nolock)
	INNER JOIN dbo.VSOutright o witH(nolocK) ON b.matchid = o.EventID AND b.oddsid = o.Orid
WHERE b.winlostdate <> o.eventdate
	--and b.bettype NOT BETWEEN 1501 AND 1599 --no need to move keno bettype because orid <> keno.eventid
	and b.bettype IN (1231,1232,1233,1237,1238)
	
IF EXISTS (SELECT * FROM @transTable)
BEGIN
	UPDATE b
	SET b.winlostdate = t.winlostdate,
		b.actualrate = ISNULL(ex.actualrate,b.actualrate)
	FROM dbo.bettrans b with (rowlock)
		INNER JOIN @transTable t ON b.transid = t.transid
		INNER JOIN CustDB.dbo.ExchangeDailyOanda ex WITH(NOLOCK) ON b.currency = ex.exchangeid and ex.exchangeDate = t.winlostdate 
	
	SET @Doing = 'DONE : update winlostdate -vs- eventdate'
	EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing  
END


DECLARE @transid bigint
-- ====================
-- DATA VERIFICATION
-- ====================
IF EXISTS (
	SELECT transid FROM bettrans with (nolock)
	WHERE	--[status] = 'running' 
			statusID = 0
			AND custid <> 0
			AND bettype <=19000 AND bettype <> 10 AND winlostdate <= @winlostdate
			AND currency <> 20
)
BEGIN
	SELECT DISTINCT matchid, bettype, 'EXEC DBA_MatchName ' + CAST(matchid as nvarchar(20)) cmd FROM bettrans (nolock)
	WHERE	winlostdate <= @winlostdate 
			--AND [status] = 'running'
			AND statusID = 0 
			AND bettype <=19000 and bettype NOT IN (9, 10, 29, 2799)
			AND currency <> 20

	SELECT DISTINCT 'EXEC DBA_matchname ' + CAST(bm.matchid as varchar(10)) matchid, m.eventdate, bm.matchid, ',' [Comma]
	FROM dbo.bettrans b (nolock)
		INNER JOIN dbo.bettransm bm (nolock) ON b.refno = bm.refno
		INNER JOIN dbo.match m (nolock) ON bm.matchid = m.matchid
	WHERE	b.winlostdate <= @winlostdate 
			--AND b.[status] = 'running' AND bm.[status] = 'running'
			AND b.statusID = 0 AND bm.statusID = 0 
			AND b.bettype in (9,29,2799)
			--AND b.matchid = 0
			AND b.matchID in (9,29,2799)
			AND b.currency <> 20
	ORDER BY m.eventdate

	IF @@ROWCOUNT > 0
	BEGIN
		PRINT '--'
		PRINT '--SELECT * FROM bettrans (nolock) WHERE status = ''running'' AND matchid IN (9,29,2799) AND bettype IN (9,29,2799) AND winlostdate <= ''' + CONVERT(varchar(10), @winlostdate, 120) + ''''
		PRINT '--UPDATE dbo.bettrans SET winlostdate = ''' + CONVERT(varchar(10), DATEADD(day,1,@winlostdate), 120) + ''' WHERE transid IN ( xxxxx )'
		PRINT '--'
	END

	RAISERROR ('FAILED: Have running tickets', 16, 1)
	RETURN
END
-- ========================================
-- DATA VERIFICATION - Translog
-- ========================================
IF EXISTS (
	SELECT translogid FROM translog with (nolock)
	WHERE	statusID IN (0, 1) --[status] IN ('running' , 'waiting')
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
	SELECT 1 FROM bettransRNG with (nolock)
	WHERE	(statusID = 0 OR isSum = 0)
			AND winlostdate <= @winlostdate
			AND currency <> 20
)
BEGIN
	RAISERROR ('FAILED: bettransRNG have running tickets or not summed to bettrans yet', 16, 1)
	RETURN
END

IF EXISTS (
	SELECT 1 FROM bettransLC with (nolock)
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
	SELECT transid FROM bettrans with (nolock)
	WHERE srecommend <= 100 AND (scomm <> acomm OR swinlost <> 0)
	AND bettype <=19000 AND winlostdate = @winlostdate
)
BEGIN
	RAISERROR ('FAILED: Incorrect Company SuperAgent setting', 16, 1)
	RETURN
END
-- ====================
IF EXISTS (
	SELECT transid FROM bettrans with (nolock)
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
	FROM bettrans (nolock)
	WHERE bettype <=19000 AND winlostdate = @winlostdate
	AND NOT (bettype = 10 and statusID = 0) -- exclude running outright
	GROUP BY currency
	HAVING COUNT(DISTINCT actualrate) > 1
)
BEGIN
	RAISERROR ('FAILED: Multiple Exchange Rate', 16, 1)
	RETURN
END
-- ====================

IF @TestMode = 1
BEGIN
	PRINT 'DATA OK'

	IF EXISTS (SELECT 1 FROM bettrans with (nolock)
		WHERE bettype = 10 
			--AND [status] = 'running'
			AND statusID = 0 
			AND winlostdate = @winlostdate)
		PRINT 'Some Outright need to moved : Run with parameter = 2'

	IF EXISTS (SELECT 1 FROM bettrans with (nolock)
		WHERE currency = 20
			AND winlostdate = @winlostdate
			AND bettype <=19000
			AND statusID = 0)
		PRINT 'Some TEST Ticket need to Refund : Run with parameter = 2'

	SET @Doing = 'Task_DailySummary : End Test'
	EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing  

	RETURN
END
 
-- =====================
-- OUTRIGHT WINLOST MOVE
-- =====================

SELECT	TOP 1 @transid = transid FROM bettrans with (nolock)
WHERE	bettype = 10 
		--AND [status] = 'running'
		AND statusID = 0 
		AND winlostdate = @winlostdate

IF @@ROWCOUNT > 0
BEGIN
	Declare @outright TABLE (orid int)
	INSERT INTO @outright SELECT distinct matchid FROM bettrans with (nolock)
	WHERE	bettype = 10 
			--AND [status] = 'running' 
			AND statusID = 0 
			AND winlostdate <= @winlostdate

	UPDATE O
	SET eventdate = DATEADD(day, 1, @winlostdate), changeTime = GETDATE()
	FROM DBPRO.bodb02.dbo.outright O WITH (UPDLOCK, ROWLOCK)
	WHERE orid IN (SELECT orid FROM @outright)

	UPDATE bettrans WITH (UPDLOCK, ROWLOCK) SET winlostdate = DATEADD(day, 1, @winlostdate)
	WHERE bettype = 10 AND matchid IN (SELECT orid FROM @outright)
END

-- =====================
-- AUTO VOID TEST TICKET
-- =====================
	IF EXISTS (
		SELECT 1 FROM dbo.bettrans with (nolock)
		where currency = 20 AND winlostdate = @winlostdate AND bettype <=19000
		AND statusID = 0
	)
	BEGIN
		Declare @custs TABLE (custid int)
		
		CREATE TABLE #__AutoVoid_TransList(TransId BIGINT PRIMARY KEY)
		INSERT INTO #__AutoVoid_TransList(TransId)
		SELECT TransId
		FROM dbo.bettrans b WITH(NOLOCK)
		WHERE b.currency = 20 AND winlostdate = @winlostdate 
			AND bettype <= 19000 AND statusID IN (0, 1)

		UPDATE b
		SET winlost=actual_stake,ruben=1,statuswinlost=6, status = 'Void', statusid = 102
			, awinlost = 0, mwinlost = 0, swinlost = 0, playercomm = 0, comm  = 0, acomm = 0
			, scomm = 0, transdesc = '[AutoVoid]' + transdesc
		OUTPUT deleted.custid INTO @custs
		FROM #__AutoVoid_TransList t
			INNER JOIN dbo.bettrans b WITH (ROWLOCK, UPDLOCK) ON t.TransId = b.transid
		OPTION (FORCE ORDER) --hint for case bad plan
		
		INSERT INTO dbo.Task_Cust_CheckBalanceVerify (custid)
		SELECT DISTINCT custid
		FROM @custs
		
		EXEC dbo.[Task_CheckBalance] @step = 33, @Action = 'JustFix'

		DROP TABLE #__AutoVoid_TransList

	END

IF @TestMode <> 0 -- @TestMode = 2
BEGIN
	SET @Doing = 'Task_DailySummary : End Test (with Outright update)'
	EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing  


	PRINT 'DATA OK && Outright Update : done'
	RETURN
END

-- =====================
-- Daily Summary Process
-- =====================
-- Re-Summary WinLost Report : Added on 2007-03-16 (Joe)
EXEC DBACC.bodb02.dbo.Task_rptWinLost_UpdateTable @winlostdate
WAITFOR DELAY '000:00:30'
-- Clear deleted/cancel record (custid = 0)
DELETE FROM bettrans WHERE winlostdate=@winlostdate AND custid = 0

DELETE FROM bettranssum WHERE winlostdate=@winlostdate

-- Get Exchange Rate
DECLARE @Exchange TABLE (currency tinyint, actualrate float, CurrencyName nvarchar(50))
INSERT INTO @Exchange (currency, actualrate)
SELECT DISTINCT currency, actualrate
FROM dbo.bettrans with (nolock)
WHERE winlostdate = @winlostdate AND bettype <=19000

UPDATE @Exchange
SET CurrencyName = e.currency
FROM @Exchange ex, CustDB.dbo.exchange e with (nolock)
WHERE ex.currency = e.exchangeid

-- Generate SUM record
INSERT INTO dbo.bettranssum
	(custid, currency, recommend, mrecommend, srecommend,
	winlostdate, stake, actual_stake,
	winlost, awinlost, mwinlost, swinlost,
	playercomm, comm, acomm, scomm)
SELECT
	custid, currency, recommend, mrecommend, srecommend,
	winlostdate, sum(stake) stake, sum(actual_stake) actual_stake,
	sum(winlost) winlost, sum(awinlost) awinlost, sum(mwinlost) mwinlost, sum(swinlost) swinlost,
	sum(playercomm) playercomm, sum(comm) comm, sum(acomm) acomm, sum(scomm) scomm
FROM
	bettrans with (paglock)
WHERE
	winlostdate=@winlostdate and
	bettype <=19000 and 
	--[status] NOT IN ('VOID', 'REJECT')
	statusID NOT IN (101,102)
GROUP BY
	custid, currency, recommend, mrecommend, srecommend, winlostdate


-- move match/odds/outright into [14] table
	UPDATE O
	SET eventdate = @winlostdate, changeTime = GETDATE()
	FROM DBPRO.bodb02.dbo.Outright O WITH (UPDLOCK, ROWLOCK)
	WHERE orid IN 
		(SELECT distinct matchid 
		FROM bettrans with (nolock) 
		WHERE bettype = 10 AND winlostdate = @winlostdate AND statusID <> 0 --AND status <> 'running'
		)
		 
EXEC DBPRO.bodb02.dbo.Task_DailySummary_DB02_Copy @winlostdate

EXEC dbo.Task_BalanceCheck @winlostdate, 1

-- viet ----
EXEC dbo.Task_UpdSystemSetting @VValue = '1', @VName = 'isMovingBet'
EXEC DBACC.bodb02.dbo.Task_UpdSystemSetting @VValue = '1', @VName = 'isMovingBet'


-- =====================
SET @Doing = 'Task_DailySummary : MoveBet start.1'
EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing  

SET NOCOUNT ON
SET DEADLOCK_PRIORITY HIGH
-- =====================
--//create a sum record for Bonus
EXEC dbo.Task_Bonus_DailySummary @WinlostDate = @WinlostDate

-- Copy bettransm/bettransg -> bettransm14/bettransg14 for whole day of @winlostdate
EXEC dbo.ExecRep_08 @recommend =  0, @winlostdate = @winlostdate, @parlay = 1

EXEC dbo.Task_DailySummary_Delete_Bet @winlostdate = @winlostdate, @tableName = 'bettransm'

-- Delete bettransG for whole day of @winlostdate
EXEC dbo.ExecRep_09 @recommend =  0, @winlostdate = @winlostdate, @parlay = 2

SET @Doing = 'Task_DailySummary : MoveBet start.2'
EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing  

--//remove all data in processing list
DELETE FROM dbo.ProcessingCustList WITH(ROWLOCK)

DECLARE @RowDeleted INT SET @rowDeleted = 1
DECLARE @rec_cnt int SET @rec_cnt = 0
DECLARE @recommend_List TABLE (recommend int PRIMARY KEY)
INSERT INTO @recommend_List
SELECT DISTINCT recommend FROM bettrans (nolock) WHERE winlostdate = @winlostdate AND bettype < 19999
UNION 
SELECT DISTINCT recommend FROM translog (nolock) WHERE winlostdate = @winlostdate

DECLARE @recommend int
DECLARE CS_recommend
	CURSOR FOR
	SELECT recommend FROM @recommend_List

OPEN CS_recommend
FETCH NEXT FROM CS_recommend INTO @recommend

WHILE @@FETCH_STATUS = 0
BEGIN
	
	DECLARE @strRecommend VARCHAR(50), @delayTimeValue VARCHAR(20)
	SELECT @strRecommend = CAST(@recommend AS VARCHAR(50)), @delayTimeValue = '00:00:00:020'
	
	--insert processing list
	EXEC dbo.Task_Core_ProcessingCustListIns @CustIds = @strRecommend

	SELECT @delayTimeValue = dbo.f_BU_GetDelayTime('Key6')
	WAITFOR DELAY @delayTimeValue

	BEGIN TRANSACTION
		EXEC dbo.ExecRep_08 @recommend, @winlostdate /* copy ticket from [active] to [14] for bettrans */
	COMMIT TRANSACTION

	--//bettransLC
	--//for first round
	BEGIN TRANSACTION
		EXEC dbo.ExecRep_09 @recommend = @recommend, @winlostdate = @winlostdate, @parlay = 0, @tableName = 'bettransLC', @firstRound = 1
	COMMIT TRANSACTION

	--//delete data on DBTrans
	SET @RowDeleted = 1	WHILE @RowDeleted > 0
	BEGIN
		BEGIN TRANSACTION
			EXEC dbo.ExecRep_09 @recommend = @recommend, @winlostdate = @winlostdate, @parlay = 0, @tableName = 'bettransLC', @RowDeleted = @RowDeleted OUTPUT
		COMMIT TRANSACTION
	END
	
	--//bettransRNG
	--//for first round
	BEGIN TRANSACTION
		EXEC dbo.ExecRep_09 @recommend = @recommend, @winlostdate = @winlostdate, @parlay = 0, @tableName = 'bettransRNG', @firstRound = 1
	COMMIT TRANSACTION

	--//delete data on DBTrans
	SET @RowDeleted = 1	WHILE @RowDeleted > 0
	BEGIN
		BEGIN TRANSACTION
			EXEC dbo.ExecRep_09 @recommend = @recommend, @winlostdate = @winlostdate, @parlay = 0, @tableName = 'bettransRNG', @RowDeleted = @RowDeleted OUTPUT
		COMMIT TRANSACTION
	END

	--//translog
	--//for first round
	BEGIN TRANSACTION
		EXEC dbo.ExecRep_09 @recommend = @recommend, @winlostdate = @winlostdate, @parlay = 0, @tableName = 'translog', @firstRound = 1
	COMMIT TRANSACTION

	--//delete data on DBTrans
	SET @RowDeleted = 1	WHILE @RowDeleted > 0
	BEGIN
		BEGIN TRANSACTION
			EXEC dbo.ExecRep_09 @recommend = @recommend, @winlostdate = @winlostdate, @parlay = 0, @tableName = 'translog', @RowDeleted = @RowDeleted OUTPUT
		COMMIT TRANSACTION
	END

	--//bettrans
	--//for first round
	BEGIN TRANSACTION
		EXEC dbo.ExecRep_09 @recommend = @recommend, @winlostdate = @winlostdate, @parlay = 0, @tableName = 'bettrans', @firstRound = 1
	COMMIT TRANSACTION

	--//delete data on DBTrans
	SET @RowDeleted = 1	WHILE @RowDeleted > 0
	BEGIN
		BEGIN TRANSACTION
			EXEC dbo.ExecRep_09 @recommend = @recommend, @winlostdate = @winlostdate, @parlay = 0, @tableName = 'bettrans', @RowDeleted = @RowDeleted OUTPUT
		COMMIT TRANSACTION
	END

	BEGIN TRANSACTION
		insert into bettrans
			(ruben, [status], statusID, matchid, bettype, refno, creator, transdate,
			custid, currency, recommend, mrecommend, srecommend,
			winlostdate, stake, winlost, awinlost, mwinlost, swinlost,
			actual_stake, playercomm, comm, acomm, scomm, 
			apositiontaking, mpositiontaking, spositiontaking, tpositiontaking,
			actualrate, virtualrate, Username, CurrencyName, comstatus, checktime)
		select
			1, 'SUM', 142, 0, 19999, refno, 8, winlostdate, --99
			b.custid, b.currency, b.recommend, b.mrecommend, b.srecommend,
			winlostdate, stake, winlost, awinlost, mwinlost, swinlost,
			actual_stake, playercomm, comm, acomm, scomm,
			0, 0, 0, 0,
			e.actualrate, e.actualrate, c.username, e.CurrencyName, '0', getdate()
		from 
			bettranssum b with (nolock)
			INNER JOIN @Exchange e ON b.currency = e.currency
			INNER JOIN CustDB.dbo.custinfo c with (nolock) ON b.custid = c.custid AND c.roleid = 1
		where
			winlostdate=@winlostdate
			AND b.recommend = @recommend

	COMMIT TRANSACTION

/*
	SET @rec_cnt = @rec_cnt + 1
	IF @rec_cnt = 10
	BEGIN
		SET @rec_cnt = 0
		
		SET @Doing = 'Task_DailySummary : MoveBet ' + CAST(@recommend as varchar(20))
		--EXEC dbo.WriteLog_UserLog @UserID = 25521, @Doing = @Doing 
	END
*/
	--delete processing list
	EXEC dbo.Task_Core_ProcessingCustListDel @CustIds = @strRecommend

	--WAITFOR DELAY '00:00:00:020'
	FETCH NEXT FROM CS_recommend INTO @recommend
END

CLOSE CS_recommend
DEALLOCATE CS_recommend

--//remove all data in processing list
DELETE FROM dbo.ProcessingCustList WITH(ROWLOCK)

-- =====================
SET DEADLOCK_PRIORITY NORMAL
SET NOCOUNT OFF

SET @Doing = 'Task_DailySummary : MoveBet done'
EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing 

-- viet ----
EXEC dbo.Task_UpdSystemSetting @VValue = '0', @VName = 'isMovingBet'
EXEC DBACC.bodb02.dbo.Task_UpdSystemSetting @VValue = '0', @VName = 'isMovingBet'
 
-- =====================
EXEC Task_BalanceCheck @winlostdate, 3
-- =====================

-- =====================
-- 20100914@Jamie: Modify for Bingo and Number Game 
INSERT INTO dbo.sum_winloss_tmp
	(winlostdate, roleid, custid, recommend, mrecommend, srecommend, username,
	turnover, winlost, awinlost, mwinlost, swinlost,
	playercomm, comm, acomm, scomm, betcount, grosscomm,
	sporttype, bettype, netTurnover, TunroverNoDraw)
	SELECT @winlostdate, 1,
		customer.custid, customer.recommend, customer.mrecommend, customer.srecommend, customer.username,
		sum(ABS(stake)) TurnOver,
		sum(winlost-actual_stake)  winlost,
		sum(awinlost) awinlost,
		sum(mwinlost) mwinlost,
		sum(IsNull(swinlost,0)) swinlost,
		sum(playercomm) playercomm,
		sum(comm) comm,
		sum(acomm) acomm,
		sum(IsNull(scomm,0)) scomm,
		COUNT(1) BetCount,
		SUM(CASE WHEN apositiontaking = 1 THEN 0 ELSE ISNULL(comm/(1-apositiontaking),0) END) grosscomm, 
		CASE
			WHEN bettype BETWEEN 81 AND 120 OR bettype BETWEEN 8101 AND 8120 THEN 161 -- Number Game 
			WHEN bettype BETWEEN 1201 AND 1299 THEN 180 -- Virtual Sport
			WHEN bettype BETWEEN 2700 AND 2899 THEN 190 -- Betradar Virtual Sport
			WHEN bettype IN (71,72) THEN 251
			WHEN bettype BETWEEN 1501 AND 1599 THEN 202 -- Keno
			WHEN bettype BETWEEN 1021 AND 1049 THEN 220 -- Keno Lottery
			WHEN bettype BETWEEN 1700 AND 1799 THEN 255 -- Gold Deluxe
			WHEN Bettype BETWEEN 1800 AND 1899 THEN 250 --- AG Casino 
			WHEN Bettype = 1900 THEN 249 --- Vegas Games 
			WHEN Bettype BETWEEN  18000 AND 18099 THEN 204 --- Colossus Bets
			WHEN Bettype BETWEEN 2101 AND 2199 THEN 208
			WHEN Bettype BETWEEN 2201 AND 2299 THEN 209
			WHEN Bettype BETWEEN 2301 AND 2399 OR Bettype BETWEEN 2901 AND 2999 THEN 210
			WHEN Bettype BETWEEN 2401 AND 2499 THEN 211 --- Allbet
			WHEN Bettype BETWEEN 4001 AND 4100 THEN 212 --Voidbridge
			WHEN Bettype BETWEEN 4101 AND 4300 THEN 248 --Pragmatic
			WHEN Bettype BETWEEN 2501 AND 2699 THEN 213 --NG2 -
			WHEN Bettype BETWEEN 1011 AND 1020 THEN 219 --Fishing World -
			WHEN Bettype BETWEEN 8000 AND 8099 THEN 221 -- Exchange
			WHEN Bettype BETWEEN 1901 AND 1999 THEN 165 -- Card Club
			WHEN Bettype BETWEEN 4301 AND 4600 THEN 247 -- Spadegaming
			WHEN Bettype BETWEEN 4601 AND 4900 THEN 245 -- Virtual Games
			WHEN Bettype BETWEEN 1611 AND 1699 THEN 200 -- Saba.Club
			WHEN Bettype BETWEEN 3001 AND 3099 THEN 244 -- SA Gaming
			ELSE 0 END sporttype,
		CASE WHEN bettype IN (71,72) THEN bettype ELSE 0 END bettype, 
		0 AS netTurnover,
		SUM( CASE	WHEN StatusID IN (112,113) AND MOdds IN (-0.25, 0.25) 
						---- Sportsbook
						AND (Bettype < 999 OR bettype BETWEEN 1301 AND 1399 OR bettype BETWEEN 9001 AND 9399)
						AND Bettype NOT IN (71,72)
						AND Bettype NOT BETWEEN 81 AND 120			
						THEN ABS(stake)/2
					WHEN StatusID = 111  
						AND (
							---- Sportsbook
								(Bettype < 999 OR bettype BETWEEN 1301 AND 1399 OR bettype BETWEEN 9001 AND 9399)
								AND Bettype NOT IN (71,72)
								AND Bettype NOT BETWEEN 81 AND 120
						)
						THEN 0
					WHEN bettype BETWEEN 2401 AND 2499 THEN oddsspread -- Allbet
					ELSE ABS(stake) 
				END) AS TurnoverNoDraw
	FROM
		CustDB.dbo.customer with (nolock),
		dbo.bettrans14 bettrans with (nolock)
	WHERE
		bettrans.custid=customer.custid and 
		bettrans.winlostdate = @winlostdate and
		--bettrans.status not in ('running','waiting','VOID','REJECT','REFUND') and
		bettrans.statusID NOT IN (0,1,102,101,103) and 
		bettrans.bettype <=19000
	GROUP BY
		customer.custid, customer.recommend, customer.mrecommend, customer.srecommend,
		customer.username,
		CASE
			WHEN bettype BETWEEN 81 AND 120 OR bettype BETWEEN 8101 AND 8120 THEN 161 -- Number Game 
			WHEN bettype BETWEEN 1201 AND 1299 THEN 180 -- Virtual Sports
			WHEN bettype BETWEEN 2700 AND 2899 THEN 190 -- Betradar Virtual Sports
			WHEN bettype IN (71,72) THEN 251
			WHEN bettype BETWEEN 1501 AND 1599 THEN 202 -- Keno
			WHEN bettype BETWEEN 1021 AND 1049 THEN 220 -- Keno Lottery
			WHEN bettype BETWEEN 1700 AND 1799 THEN 255 -- Gold Deluxe
			WHEN Bettype BETWEEN 1800 AND 1899 THEN 250 --- AG Casino 
			WHEN Bettype = 1900 THEN 249 --- Vegas Games 
			WHEN Bettype BETWEEN  18000 AND 18099 THEN 204 --- Colossus Bets
			WHEN Bettype BETWEEN 2101 AND 2199 THEN 208
			WHEN Bettype BETWEEN 2201 AND 2299 THEN 209
			WHEN Bettype BETWEEN 2301 AND 2399 OR Bettype BETWEEN 2901 AND 2999 THEN 210
			WHEN Bettype BETWEEN 2401 AND 2499 THEN 211 --- Allbet
			WHEN Bettype BETWEEN 4001 AND 4100 THEN 212 --Voidbridge
			WHEN Bettype BETWEEN 4101 AND 4300 THEN 248 --Pragmatic
			WHEN Bettype BETWEEN 2501 AND 2699 THEN 213 --NG2 -
			WHEN Bettype BETWEEN 1011 AND 1020 THEN 219 --Fishing World -
			WHEN Bettype BETWEEN 8000 AND 8099 THEN 221 -- Exchange
			WHEN Bettype BETWEEN 1901 AND 1999 THEN 165 -- Card Club
			WHEN Bettype BETWEEN 4301 AND 4600 THEN 247 -- Spadegaming
			WHEN Bettype BETWEEN 4601 AND 4900 THEN 245 -- Virtual Games
			WHEN Bettype BETWEEN 1611 AND 1699 THEN 200 -- Saba.Club
			WHEN Bettype BETWEEN 3001 AND 3099 THEN 244 -- SA Gaming
			ELSE 0 END,
		CASE WHEN bettype IN (71,72) THEN bettype ELSE 0 END


INSERT INTO dbo.sum_winloss_tmp
	(winlostdate, roleid, custid, recommend, mrecommend, srecommend, username,
	turnover, winlost, awinlost, mwinlost, swinlost,
	playercomm, comm, acomm, scomm, betcount, grosscomm,
	sporttype, bettype, netTurnover, TunroverNoDraw)
	SELECT @winlostdate, 2,
		ag.custid, customer.recommend, customer.mrecommend, customer.srecommend, ag.username,
		sum(ABS(stake)) TurnOver,
		sum(winlost-actual_stake)  winlost,
		sum(awinlost) awinlost,
		sum(mwinlost) mwinlost,
		sum(IsNull(swinlost,0)) swinlost,
		sum(playercomm) playercomm,
		sum(comm) comm,
		sum(acomm) acomm,
		sum(IsNull(scomm,0)) scomm,
		COUNT(1) BetCount,
		SUM(CASE WHEN apositiontaking+mpositiontaking = 1 THEN 0 ELSE ISNULL(acomm/(1-apositiontaking-mpositiontaking), 0) END) grosscomm, 
		CASE
			WHEN bettype BETWEEN 81 AND 120 OR bettype BETWEEN 8101 AND 8120 THEN 161 -- Number Game 
			WHEN bettype BETWEEN 1201 AND 1299 THEN 180 -- Virtual Sports
			WHEN bettype BETWEEN 2700 AND 2899 THEN 190 -- Betradar Virtual Sports
			WHEN bettype IN (71,72) THEN 251
			WHEN bettype BETWEEN 1501 AND 1599 THEN 202 -- Keno
			WHEN bettype BETWEEN 1021 AND 1049 THEN 220 -- Keno Lottery
			WHEN bettype BETWEEN 1700 AND 1799 THEN 255 -- Gold Deluxe
			WHEN Bettype BETWEEN 1800 AND 1899 THEN 250 --- AG Casino 
			WHEN Bettype = 1900 THEN 249 --- Vegas Games 
			WHEN Bettype BETWEEN  18000 AND 18099 THEN 204 --- Colossus Bets
			WHEN Bettype BETWEEN 2101 AND 2199 THEN 208
			WHEN Bettype BETWEEN 2201 AND 2299 THEN 209
			WHEN Bettype BETWEEN 2301 AND 2399 OR Bettype BETWEEN 2901 AND 2999 THEN 210			
			WHEN Bettype BETWEEN 2401 AND 2499 THEN 211 --- Allbet
			WHEN Bettype BETWEEN 4001 AND 4100 THEN 212 --Voidbridge
			WHEN Bettype BETWEEN 4101 AND 4300 THEN 248 --Pragmatic
			WHEN Bettype BETWEEN 2501 AND 2699 THEN 213 --NG2 -
			WHEN Bettype BETWEEN 1011 AND 1020 THEN 219 --Fishing World -
			WHEN Bettype BETWEEN 8000 AND 8099 THEN 221 -- Exchange
			WHEN Bettype BETWEEN 1901 AND 1999 THEN 165 -- Card Club
			WHEN Bettype BETWEEN 4301 AND 4600 THEN 247 -- Spadegaming
			WHEN Bettype BETWEEN 4601 AND 4900 THEN 245 -- Virtual Games
			WHEN Bettype BETWEEN 1611 AND 1699 THEN 200 -- Saba.Club
			WHEN Bettype BETWEEN 3001 AND 3099 THEN 244 -- SA Gaming
			ELSE 0 END sporttype,
		CASE WHEN bettype IN (71,72) THEN bettype ELSE 0 END bettype,
		sum(ABS(stake*apositiontaking)) AS netTurnover,
		SUM( CASE	WHEN StatusID IN (112,113) AND MOdds IN (-0.25, 0.25) 
						---- Sportsbook
						AND (Bettype < 999 OR bettype BETWEEN 1301 AND 1399 OR bettype BETWEEN 9001 AND 9399)
						AND Bettype NOT IN (71,72)
						AND Bettype NOT BETWEEN 81 AND 120			
						THEN ABS(stake)/2
					WHEN StatusID = 111  
						AND (
							---- Sportsbook
								(Bettype < 999 OR bettype BETWEEN 1301 AND 1399 OR bettype BETWEEN 9001 AND 9399)
								AND Bettype NOT IN (71,72)
								AND Bettype NOT BETWEEN 81 AND 120
						)
						THEN 0
					WHEN bettype BETWEEN 2401 AND 2499 THEN oddsspread -- Allbet
					ELSE ABS(stake) 
				END) AS TurnoverNoDraw
	FROM
		CustDB.dbo.customer with (nolock),
		CustDB.dbo.customer ag with (nolock),
		dbo.bettrans14 bettrans with (nolock)
	WHERE
		bettrans.custid=customer.custid and 
		bettrans.winlostdate = @winlostdate and
		--bettrans.status not in ('running','waiting','VOID','REJECT','REFUND')  and
		bettrans.statusID NOT IN (0,1,101,102,103) and 
		ag.custid=customer.recommend and customer.roleid=1 and ag.roleid=2 and
		bettrans.bettype <=19000
	GROUP BY
		ag.custid, customer.recommend, customer.mrecommend, customer.srecommend,
		ag.username,
		CASE
			WHEN bettype BETWEEN 81 AND 120 OR bettype BETWEEN 8101 AND 8120 THEN 161 -- Number Game 
			WHEN bettype BETWEEN 1201 AND 1299 THEN 180 -- Virtual Sports
			WHEN bettype BETWEEN 2700 AND 2899 THEN 190 -- Betradar Virtual Sports
			WHEN bettype IN (71,72) THEN 251
			WHEN bettype BETWEEN 1501 AND 1599 THEN 202 -- Keno
			WHEN bettype BETWEEN 1021 AND 1049 THEN 220 -- Keno Lottery
			WHEN bettype BETWEEN 1700 AND 1799 THEN 255 -- Gold Deluxe
			WHEN Bettype BETWEEN 1800 AND 1899 THEN 250 --- AG Casino 
			WHEN Bettype = 1900 THEN 249 --- Vegas Games 
			WHEN Bettype BETWEEN  18000 AND 18099 THEN 204 --- Colossus Bets
			WHEN Bettype BETWEEN 2101 AND 2199 THEN 208
			WHEN Bettype BETWEEN 2201 AND 2299 THEN 209
			WHEN Bettype BETWEEN 2301 AND 2399 OR Bettype BETWEEN 2901 AND 2999 THEN 210
			WHEN Bettype BETWEEN 2401 AND 2499 THEN 211 --- Allbet
			WHEN Bettype BETWEEN 4001 AND 4100 THEN 212 --Voidbridge
			WHEN Bettype BETWEEN 4101 AND 4300 THEN 248 --Pragmatic
			WHEN Bettype BETWEEN 2501 AND 2699 THEN 213 --NG2 -
			WHEN Bettype BETWEEN 1011 AND 1020 THEN 219 --Fishing World -
			WHEN Bettype BETWEEN 8000 AND 8099 THEN 221 -- Exchange
			WHEN Bettype BETWEEN 1901 AND 1999 THEN 165 -- Card Club
			WHEN Bettype BETWEEN 4301 AND 4600 THEN 247 -- Spadegaming
			WHEN Bettype BETWEEN 4601 AND 4900 THEN 245 -- Virtual Games
			WHEN Bettype BETWEEN 1611 AND 1699 THEN 200 -- Saba.Club
			WHEN Bettype BETWEEN 3001 AND 3099 THEN 244 -- SA Gaming
			ELSE 0 END,
		CASE WHEN bettype IN (71,72) THEN bettype ELSE 0 END


INSERT INTO dbo.sum_winloss_tmp
	(winlostdate, roleid, custid, recommend, mrecommend, srecommend, username,
	turnover, winlost, awinlost, mwinlost, swinlost,
	playercomm, comm, acomm, scomm, betcount, grosscomm,
	sporttype, bettype, netTurnover, TunroverNoDraw)
	SELECT @winlostdate, 3,
		ma.custid, 0 recommend, customer.mrecommend, customer.srecommend, ma.username,
		sum(ABS(stake)) TurnOver,
		sum(winlost-actual_stake)  winlost,
		sum(awinlost) awinlost,
		sum(mwinlost) mwinlost,
		sum(IsNull(swinlost,0)) swinlost,
		sum(playercomm) playercomm,
		sum(comm) comm,
		sum(acomm) acomm,
		sum(IsNull(scomm,0)) scomm,
		COUNT(1) BetCount,
		SUM(CASE WHEN tpositiontaking = 1 THEN 0 ELSE scomm / (1-tpositiontaking) END) grosscomm,
		CASE
			WHEN bettype BETWEEN 81 AND 120 OR bettype BETWEEN 8101 AND 8120 THEN 161 -- Number Game 
			WHEN bettype BETWEEN 1201 AND 1299 THEN 180 -- Virtual Sports
			WHEN bettype BETWEEN 2700 AND 2899 THEN 190 -- Betradar Virtual Sports
			WHEN bettype IN (71,72) THEN 251
			WHEN bettype BETWEEN 1501 AND 1599 THEN 202 -- Keno
			WHEN bettype BETWEEN 1021 AND 1049 THEN 220 -- Keno Lottery
			WHEN bettype BETWEEN 1700 AND 1799 THEN 255 -- Gold Deluxe
			WHEN Bettype BETWEEN 1800 AND 1899 THEN 250 --- AG Casino 
			WHEN Bettype = 1900 THEN 249 --- Vegas Games 
			WHEN Bettype BETWEEN  18000 AND 18099 THEN 204 --- Colossus Bets
			WHEN Bettype BETWEEN 2101 AND 2199 THEN 208
			WHEN Bettype BETWEEN 2201 AND 2299 THEN 209
			WHEN Bettype BETWEEN 2301 AND 2399 OR Bettype BETWEEN 2901 AND 2999 THEN 210
			WHEN Bettype BETWEEN 2401 AND 2499 THEN 211 --- Allbet
			WHEN Bettype BETWEEN 4001 AND 4100 THEN 212 --Voidbridge
			WHEN Bettype BETWEEN 4101 AND 4300 THEN 248 --Pragmatic
			WHEN Bettype BETWEEN 2501 AND 2699 THEN 213 --NG2 -
			WHEN Bettype BETWEEN 1011 AND 1020 THEN 219 --Fishing World -
			WHEN Bettype BETWEEN 8000 AND 8099 THEN 221 -- Exchange
			WHEN Bettype BETWEEN 1901 AND 1999 THEN 165 -- Card Club
			WHEN Bettype BETWEEN 4301 AND 4600 THEN 247 -- Spadegaming
			WHEN Bettype BETWEEN 4601 AND 4900 THEN 245 -- Virtual Games
			WHEN Bettype BETWEEN 1611 AND 1699 THEN 200 -- Saba.Club
			WHEN Bettype BETWEEN 3001 AND 3099 THEN 244 -- SA Gaming
			ELSE 0 END sporttype,
		CASE WHEN bettype IN (71,72) THEN bettype ELSE 0 END bettype,
		sum(ABS(stake*mpositiontaking)) AS netTurnover,
		SUM( CASE	WHEN StatusID IN (112,113) AND MOdds IN (-0.25, 0.25) 
						---- Sportsbook
						AND (Bettype < 999 OR bettype BETWEEN 1301 AND 1399 OR bettype BETWEEN 9001 AND 9399)
						AND Bettype NOT IN (71,72)
						AND Bettype NOT BETWEEN 81 AND 120			
						THEN ABS(stake)/2
					WHEN StatusID = 111  
						AND (
							---- Sportsbook
								(Bettype < 999 OR bettype BETWEEN 1301 AND 1399 OR bettype BETWEEN 9001 AND 9399)
								AND Bettype NOT IN (71,72)
								AND Bettype NOT BETWEEN 81 AND 120
						)
						THEN 0
					WHEN bettype BETWEEN 2401 AND 2499 THEN oddsspread -- Allbet
					ELSE ABS(stake) 
				END) AS TurnoverNoDraw
	FROM
		CustDB.dbo.customer with (nolock),
		CustDB.dbo.customer ma with (nolock),
		dbo.bettrans14 bettrans with (nolock)
	WHERE
		bettrans.custid=customer.custid and 
		bettrans.winlostdate = @winlostdate and
		--bettrans.status not in ('running','waiting','VOID','REJECT','REFUND')  and
		bettrans.statusID NOT IN (0,1,101,102,103) and
		ma.custid=customer.mrecommend and customer.roleid=1 and ma.roleid=3 and
		bettrans.bettype <=19000
	GROUP BY
		ma.custid, customer.mrecommend, customer.srecommend, 
		ma.username,
		CASE
			WHEN bettype BETWEEN 81 AND 120 OR bettype BETWEEN 8101 AND 8120 THEN 161 -- Number Game 
			WHEN bettype BETWEEN 1201 AND 1299 THEN 180 -- Virtual Sports
			WHEN bettype BETWEEN 2700 AND 2899 THEN 190 -- Betradar Virtual Sports
			WHEN bettype IN (71,72) THEN 251
			WHEN bettype BETWEEN 1501 AND 1599 THEN 202 -- Keno
			WHEN bettype BETWEEN 1021 AND 1049 THEN 220 -- Keno Lottery
			WHEN bettype BETWEEN 1700 AND 1799 THEN 255 -- Gold Deluxe
			WHEN Bettype BETWEEN 1800 AND 1899 THEN 250 --- AG Casino 
			WHEN Bettype = 1900 THEN 249 --- Vegas Games 
			WHEN Bettype BETWEEN  18000 AND 18099 THEN 204 --- Colossus Bets
			WHEN Bettype BETWEEN 2101 AND 2199 THEN 208
			WHEN Bettype BETWEEN 2201 AND 2299 THEN 209
			WHEN Bettype BETWEEN 2301 AND 2399 OR Bettype BETWEEN 2901 AND 2999 THEN 210
			WHEN Bettype BETWEEN 2401 AND 2499 THEN 211 --- Allbet
			WHEN Bettype BETWEEN 4001 AND 4100 THEN 212 --Voidbridge
			WHEN Bettype BETWEEN 4101 AND 4300 THEN 248 --Pragmatic
			WHEN Bettype BETWEEN 2501 AND 2699 THEN 213 --NG2 -
			WHEN Bettype BETWEEN 1011 AND 1020 THEN 219 --Fishing World -
			WHEN Bettype BETWEEN 8000 AND 8099 THEN 221 -- Exchange
			WHEN Bettype BETWEEN 1901 AND 1999 THEN 165 -- Card Club
			WHEN Bettype BETWEEN 4301 AND 4600 THEN 247 -- Spadegaming
			WHEN Bettype BETWEEN 4601 AND 4900 THEN 245 -- Virtual Games
			WHEN Bettype BETWEEN 1611 AND 1699 THEN 200 -- Saba.Club
			WHEN Bettype BETWEEN 3001 AND 3099 THEN 244 -- SA Gaming
			ELSE 0 END,
		CASE WHEN bettype IN (71,72) THEN bettype ELSE 0 END

--20100601: Arrange sum_winloss data for Super Level.
INSERT INTO dbo.sum_winloss_tmp
	(winlostdate, roleid, custid, recommend, mrecommend, srecommend, username,
	turnover, winlost, awinlost, mwinlost, swinlost,
	playercomm, comm, acomm, scomm, betcount, grosscomm,
	sporttype, bettype, netTurnover, TunroverNoDraw)
	SELECT @winlostdate, 4,
		sa.custid, 0 recommend, 0 mrecommend, customer.srecommend, sa.username,
		sum(ABS(stake))  TurnOver,
		sum(winlost-actual_stake)  winlost,
		sum(awinlost) awinlost,
		sum(mwinlost) mwinlost,
		sum(IsNull(swinlost,0)) swinlost,
		sum(playercomm) playercomm,
		sum(comm) comm,
		sum(acomm) acomm,
		sum(IsNull(scomm,0)) scomm,
		COUNT(1) BetCount,
		SUM(CASE WHEN tpositiontaking = 1 THEN 0 ELSE scomm / (1-tpositiontaking) END) grosscomm,
		CASE
			WHEN bettype BETWEEN 81 AND 120 OR bettype BETWEEN 8101 AND 8120 THEN 161 -- Number Game 
			WHEN bettype BETWEEN 1201 AND 1299 THEN 180 -- Virtual Sports
			WHEN bettype BETWEEN 2700 AND 2899 THEN 190 -- Betradar Virtual Sports
			WHEN bettype IN (71,72) THEN 251
			WHEN bettype BETWEEN 1501 AND 1599 THEN 202 -- Keno
			WHEN bettype BETWEEN 1021 AND 1049 THEN 220 -- Keno Lottery
			WHEN bettype BETWEEN 1700 AND 1799 THEN 255 -- Gold Deluxe
			WHEN Bettype BETWEEN 1800 AND 1899 THEN 250 --- AG Casino 
			WHEN Bettype = 1900 THEN 249 --- Vegas Games 
			WHEN Bettype BETWEEN  18000 AND 18099 THEN 204 --- Colossus Bets
			WHEN Bettype BETWEEN 2101 AND 2199 THEN 208
			WHEN Bettype BETWEEN 2201 AND 2299 THEN 209
			WHEN Bettype BETWEEN 2301 AND 2399 OR Bettype BETWEEN 2901 AND 2999 THEN 210
			WHEN Bettype BETWEEN 2401 AND 2499 THEN 211 --- Allbet
			WHEN Bettype BETWEEN 4001 AND 4100 THEN 212 --Voidbridge
			WHEN Bettype BETWEEN 4101 AND 4300 THEN 248 --Pragmatic
			WHEN Bettype BETWEEN 2501 AND 2699 THEN 213 --NG2 -
			WHEN Bettype BETWEEN 1011 AND 1020 THEN 219 --Fishing World -
			WHEN Bettype BETWEEN 8000 AND 8099 THEN 221 -- Exchange
			WHEN Bettype BETWEEN 1901 AND 1999 THEN 165 -- Card Club
			WHEN Bettype BETWEEN 4301 AND 4600 THEN 247 -- Spadegaming
			WHEN Bettype BETWEEN 4601 AND 4900 THEN 245 -- Virtual Games
			WHEN Bettype BETWEEN 1611 AND 1699 THEN 200 -- Saba.Club
			WHEN Bettype BETWEEN 3001 AND 3099 THEN 244 -- SA Gaming
			ELSE 0 END sporttype,
		CASE WHEN bettype IN (71,72) THEN bettype ELSE 0 END bettype,
		sum(ABS(stake*spositiontaking)) AS netTurnover,
		SUM( CASE	WHEN StatusID IN (112,113) AND MOdds IN (-0.25, 0.25) 
						---- Sportsbook
						AND (Bettype < 999 OR bettype BETWEEN 1301 AND 1399 OR bettype BETWEEN 9001 AND 9399)
						AND Bettype NOT IN (71,72)
						AND Bettype NOT BETWEEN 81 AND 120			
						THEN ABS(stake)/2
					WHEN StatusID = 111  
						AND (
							---- Sportsbook
								(Bettype < 999 OR bettype BETWEEN 1301 AND 1399 OR bettype BETWEEN 9001 AND 9399)
								AND Bettype NOT IN (71,72)
								AND Bettype NOT BETWEEN 81 AND 120
						)
						THEN 0
					WHEN bettype BETWEEN 2401 AND 2499 THEN oddsspread -- Allbet
					ELSE ABS(stake) 
				END) AS TurnoverNoDraw
	FROM
		CustDB.dbo.customer with (nolock),
		CustDB.dbo.customer sa with (nolock),
		dbo.bettrans14 bettrans with (nolock)
	WHERE
		bettrans.custid=customer.custid and 
		bettrans.winlostdate = @winlostdate and
		--bettrans.status not in ('running','waiting','VOID','REJECT','REFUND')  and
		bettrans.statusID NOT IN (0,1,101,102,103) and
		sa.custid=customer.srecommend and customer.roleid=1 and sa.roleid=4 and
		bettrans.bettype <=19000
	GROUP BY
		sa.custid, customer.srecommend, 
		sa.username,
		CASE
			WHEN bettype BETWEEN 81 AND 120 OR bettype BETWEEN 8101 AND 8120 THEN 161 -- Number Game 
			WHEN bettype BETWEEN 1201 AND 1299 THEN 180 -- Virtual Sports
			WHEN bettype BETWEEN 2700 AND 2899 THEN 190 -- Betradar Virtual Sports
			WHEN bettype IN (71,72) THEN 251
			WHEN bettype BETWEEN 1501 AND 1599 THEN 202 -- Keno
			WHEN bettype BETWEEN 1021 AND 1049 THEN 220 -- Keno Lottery
			WHEN bettype BETWEEN 1700 AND 1799 THEN 255 -- Gold Deluxe
			WHEN Bettype BETWEEN 1800 AND 1899 THEN 250 --- AG Casino 
			WHEN Bettype = 1900 THEN 249 --- Vegas Games 
			WHEN Bettype BETWEEN  18000 AND 18099 THEN 204 --- Colossus Bets
			WHEN Bettype BETWEEN 2101 AND 2199 THEN 208
			WHEN Bettype BETWEEN 2201 AND 2299 THEN 209
			WHEN Bettype BETWEEN 2301 AND 2399 OR Bettype BETWEEN 2901 AND 2999 THEN 210
			WHEN Bettype BETWEEN 2401 AND 2499 THEN 211 --- Allbet
			WHEN Bettype BETWEEN 4001 AND 4100 THEN 212 --Voidbridge
			WHEN Bettype BETWEEN 4101 AND 4300 THEN 248 --Pragmatic
			WHEN Bettype BETWEEN 2501 AND 2699 THEN 213 --NG2 -
			WHEN Bettype BETWEEN 1011 AND 1020 THEN 219 --Fishing World -
			WHEN Bettype BETWEEN 8000 AND 8099 THEN 221 -- Exchange
			WHEN Bettype BETWEEN 1901 AND 1999 THEN 165 -- Card Club
			WHEN Bettype BETWEEN 4301 AND 4600 THEN 247 -- Spadegaming
			WHEN Bettype BETWEEN 4601 AND 4900 THEN 245 -- Virtual Games
			WHEN Bettype BETWEEN 1611 AND 1699 THEN 200 -- Saba.Club
			WHEN Bettype BETWEEN 3001 AND 3099 THEN 244 -- SA Gaming
			ELSE 0 END,
		CASE WHEN bettype IN (71,72) THEN bettype ELSE 0 END


-- =====================
SET @Doing = 'Task_DailySummary : SumWinlost start insert'
EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing  

Declare @loop varchar(1)

SET NOCOUNT ON
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

	WAITFOR DELAY '000:00:01.4'
END

SET NOCOUNT OFF

-- =====================
Delete Match_Log where matchID IN (Select matchID From Match WITH (NOLOCK) Where eventdate=@winlostdate)

Delete from outright_log
where orid in (select orid from outright where eventdate = @winlostdate AND oddsstatus = 'Completed')

-- =====================
EXEC DBPRO.bodb02.dbo.Task_DailySummary_DB02_Delete @winlostdate

SET @Doing = 'Task_DailySummary : End (with Finish)'
EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing  

WAITFOR DELAY '00:02:00' --- add this wait to make sure the delete event part run completely before start next day

PRINT CONVERT(varchar(10), @winlostdate, 120)

GO