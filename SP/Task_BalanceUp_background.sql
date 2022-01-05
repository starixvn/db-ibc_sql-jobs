/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_BalanceUp_background]
	@fdate as datetime = NULL,
	@step as tinyint = 1
--	@continue as bit = 0
AS

Declare @Doing nvarchar(300)

/*
Created: 
Task : 

DB: DBTXN/bodb02
Original:

Revisions:
	- 20110523@Henry: change bettype to new range
	- 20130603@Sophia: Put the deleting-match code into [Acc_Apl_ExecRep_03]
	- 20131108@Elodie: Splitting bodb02 into CustDB (call custinfo, Customer, Exchange, ExchangeDailyOanda, by link database)		
					   Use DBACC instead of DB06
    - 20150702@Daniel: Separated custDB to server DBCUST					   
	- 20160909@Patrick: Record EndTime & IsArchiving to systemsettings table on DBTXN.bodb02
	- 20170511@patrick: Set deadlock_priority high
	- 20170915@Patrick: Update code for:
			+ Output a signal when processing itself and upline's
			+ Add more signal to replicated servers when MB/BU starting or done
	- 20180329@Percy: Add Bet_ExecRep_09 [RedmineID: #92391]
	- 20181002@Dominic: Get username from archived DB  [Redmine:99882]
	- 20190327@Helen: Calculating value of @fdate of step #6 is incorrect  [Redmine:110974]
	- 20190417@Patrick: Ignore verify data for roleid = 0 [Redmine:#112050]
	- 201900816@Patrick: Implement BU for custid have roleid = 0 [Redmine:#118818]
	- 20200814@Joe : Improve process of filter Invalid Balance (from BalanceTable_tmp_cal) [RedmineId :#139959]
	- 20220118@July: MBU - Timeout due to add full backup for custdb [Redmine:#167669]
	- 20220301@July: Comment code delete for livescore [Redmine:#169201]
	- 20220307@Bobby: Re-commit (Comment code delete for livescore [Redmine:#169201])
	- 20211214@Kathy: Separate Transfer Tickets[Redmine:#164197]

Param's Explanation: 

*/

IF @fdate IS NULL
BEGIN
	SELECT TOP(1) @fdate = DATEADD(day, 7, winlostdate)
	FROM	dbo.Transfer WITH(NOLOCK) --dbo.bettrans with (nolock)
	WHERE	bettype = 20000
	ORDER BY transid
	
	IF @fdate > CURRENT_TIMESTAMP
		SET @fdate = DATEADD(day, -7, @fdate)
END

PRINT '@fdate = ' + CONVERT(varchar(10), @fdate, 120)

-- verify @fdate
Declare @testdate datetime
SET @testdate = CONVERT(varchar(10), @fdate, 120)
IF @testdate <> @fdate
BEGIN
--	SELECT 'ERROR: Input parameter is DATE value with TIME.' Result
--	RETURN
-- raiserror here to continue to next step of jobs
	RAISERROR ('ERROR: Input parameter is DATE value with TIME.', -- Message text.
               16, -- Severity.
               1 -- State.
               );
END

/*
SET @fdate = CONVERT(nvarchar(10), @fdate, 120)
IF (DATEPART(weekday, @fdate) <> 2) AND (@continue = 0)
BEGIN
	PRINT 'Input date is not Monday'
	PRINT 'If you really want to continue, call with @continue = 1'
	RETURN
END
*/

SET @Doing = 'call Task_BalanceUp_background @fdate = ' + CONVERT(nvarchar(10), @fdate, 120) + ', @step = ' + CAST(@step as nvarchar(2))
EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing  

-- ================== STEP : 1 
IF @step = 1
BEGIN
-- ================== DATA VERIFY

	--- DATA VERIFY
	IF EXISTS (SELECT * FROM CustDB.dbo.Customer with (nolock) WHERE (recommend is null or mrecommend is null or srecommend is null) AND roleid IN (2,1))
	BEGIN
	--	SELECT 'Some Customer/Agent records have NULL AgentID' Result
	--	SELECT custid, username, roleid, recommend, mrecommend, srecommend, currency
	--		FROM customer with (nolock)
	--		WHERE roleid <= 2
	--		AND (recommend is NULL or mrecommend is NULL or srecommend is NULL)
	--	RETURN
	-- raiserror here to continue to next step of jobs
		RAISERROR ('Some Customer/Agent records have NULL AgentID', -- Message text.
				   16, -- Severity.
				   1 -- State.
				   );
	END

	IF EXISTS (SELECT * FROM CustDB.dbo.customer with (nolock) WHERE (recommend is NULL or mrecommend is null or srecommend is null) AND roleid = 3)
	BEGIN
	--	SELECT 'Some Master records have NULL AgentID' Result
	--	SELECT custid, username, roleid, recommend, mrecommend, srecommend, currency
	--		FROM customer with (nolock)
	--		WHERE roleid = 3
	--		AND (recommend is NULL or mrecommend is NULL or srecommend is NULL)
	--	RETURN
	-- raiserror here to continue to next step of jobs
		RAISERROR ('Some Master records have NULL AgentID', -- Message text.
				   16, -- Severity.
				   1 -- State.
				   );
	END

	IF EXISTS (SELECT * FROM CustDB.dbo.customer with (nolock) WHERE (recommend is NULL or mrecommend is null or srecommend is null) AND roleid = 4)
	BEGIN
	--	SELECT 'Some SuperAgent records have NULL AgentID' Result
	--	SELECT custid, username, roleid, recommend, mrecommend, srecommend, currency
	--		FROM customer with (nolock)
	--		WHERE roleid = 4
	--		AND (recommend is NULL or mrecommend is NULL or srecommend is NULL)
	--	RETURN
	-- raiserror here to continue to next step of jobs
		RAISERROR ('Some SuperAgent records have NULL AgentID', -- Message text.
				   16, -- Severity.
				   1 -- State.
				   );
	END

	IF EXISTS (SELECT * FROM dbo.Transfer with (nolock) WHERE winlostdate < @fdate AND (
			srecommend is null or mrecommend is null or recommend is null
		OR swinlost is null or mwinlost is null or awinlost is null or winlost is null
		OR scomm is null or acomm is null or comm is null or playercomm is null
		OR ((scomm <> acomm OR swinlost <> 0) AND srecommend <= 100)
		) )
	BEGIN
	--	SELECT 'Some records in BetTrans have NULL AgentID/NULL winlost/NULL commission/incorrect Company SuperAgent setting' Result
	--	RETURN
	-- raiserror here to continue to next step of jobs
		RAISERROR ('Some records in Transfer have NULL AgentID/NULL winlost/NULL commission/incorrect Company SuperAgent setting', -- Message text.
				   16, -- Severity.
				   1 -- State.
				   );
	END
	

-- ================== END STEP : 1 
END
-- ================== DATA VERIFY

--IF @check = 1
--	RETURN


--- START --- START --- START ---
--- START --- START --- START ---
--- START --- START --- START ---


-- ================== STEP : 2
IF @step = 2
BEGIN
-- ================== Clear BalanceTable and Perform Backup
	
	--record endtime
	DECLARE @CurrentDateTime DATETIME
	SELECT @CurrentDateTime = GETDATE()

	EXEC dbo.Task_EstimatedTimeForJobDone @IsMoveBet = 0
		, @CurrentDateTime = @CurrentDateTime
		, @TotalMoveBetDays = NULL

	-- UPDATE DBACC.bodb02.dbo.SystemSettings
	-- SET VValue = '1'
	-- WHERE VName = 'isArchivingBet' 
	EXEC dbo.Task_UpdSystemSetting @VValue = '1', @VName = 'isArchivingBet'
	EXEC DBACC.bodb02.dbo.Task_UpdSystemSetting @VValue = '1', @VName = 'isArchivingBet'

	--//turn on isArchivingBet_Local flag
	--EXEC dbo.Bet_ExecRep_09 @mode = 5
	EXEC dbo.Transfer_ExecRep_02 @Mode = 5
	EXEC dbo.ExecRep_09 @recommend = 0, @winlostdate = NULL, @parlay = 5, @tableName = 'SystemSettings'

	-- for safety, shutdown trigger in balanceTable_tmp
	EXEC dbo.Task_BalanceUp_TriggerControl @step = 1, @on = 0
	EXEC dbo.Task_BalanceUp_TriggerControl @step = 2, @on = 0

	truncate table dbo.balanceTable;
	truncate table dbo.balanceTable_tmp


		EXEC dbo.balancecheck @fdate, 11
	-- doing backup
	Declare @suffix varchar(10)
	SET @suffix = 'bbu' + RIGHT(CONVERT(varchar(10), @fdate,120),5)
	EXEC DBCUST.msdb.dbo.sp_start_job N'BalanceUPBackground_BackupFull_Cust'
	EXEC dbo.Task_BackupFULL @suffix
	EXEC DB02.bodb02.dbo.Task_BackupFULL @suffix
	--EXEC DBCUST.custDB.dbo.Task_BackupFull_Cust @suffix = 'FULL' -- Viet: add full backup for custdb also
	-- doing backup : end

-- ================== END STEP : 2
END
-- ================== Clear BalanceTable and Perform Backup


/*
-- ================== STEP : 3
IF @step = 33
BEGIN
-- ================== Calculate Balance


	--BEGIN TRANSACTION
		-- Member
		insert into dbo.balancetable(custid,  amount, TicketCount, balTicketCount)
		select 	bettrans.custid custid,
			sum(winlost-actual_stake + playercomm) amount,
			COUNT(*) TicketCount,
			sum(CASE bettype WHEN 20000 THEN 1 ELSE 0 END) balTicketCount
		from
			dbo.bettrans with (rowlock)
			--INNER JOIN dbo.custinfo c with (nolock) ON bettrans.custid = c.custid
		where
			ruben = 1 and
			winlostdate < @fdate and
			bettrans.custid <> bettrans.recommend and
			bettrans.custid <> bettrans.mrecommend and
			bettrans.custid <> bettrans.srecommend
		group by bettrans.custid;
	--COMMIT TRANSACTION

	--BEGIN TRANSACTION
		-- Agent
		insert into dbo.balancetable(custid, amount, TicketCount, balTicketCount)
		select	bettrans.recommend custid,
			sum(case
			when bettrans.custid=bettrans.recommend then winlost-actual_stake
			else awinlost+comm-playercomm
			end) amount,
			sum(CASE custid WHEN recommend THEN 1 ELSE 0 END) TicketCount,
			sum(CASE bettype WHEN 20000 THEN 1 ELSE 0 END) balTicketCount
		from
			dbo.bettrans with (rowlock)
			--INNER JOIN dbo.custinfo c with (nolock) ON bettrans.custid = c.custid
		where
			ruben=1 and 
			winlostdate < @fdate
		group by bettrans.recommend;

		-- Master
		insert into dbo.balancetable(custid, amount, TicketCount, balTicketCount)
		select	bettrans.mrecommend custid,
			sum(case
			when bettrans.custid=bettrans.mrecommend then winlost-actual_stake
			else mwinlost+acomm-comm
			end) amount,
			sum(CASE custid WHEN mrecommend THEN 1 ELSE 0 END) TicketCount,
			sum(CASE bettype WHEN 20000 THEN 1 ELSE 0 END) balTicketCount
		from
			dbo.bettrans with (rowlock)
			--INNER JOIN dbo.custinfo c with (nolock) ON bettrans.custid = c.custid
		where
			ruben=1 and 
			winlostdate < @fdate
		group by bettrans.mrecommend;

		-- Super
		insert into dbo.balancetable(custid, amount, TicketCount, balTicketCount)
		select	bettrans.srecommend custid, 
			sum(case
			when bettrans.custid=bettrans.srecommend then winlost-actual_stake
			else swinlost+scomm-acomm
			end) amount,
			sum(CASE custid WHEN srecommend THEN 1 ELSE 0 END) TicketCount,
			sum(CASE bettype WHEN 20000 THEN 1 ELSE 0 END) balTicketCount
		from
			dbo.bettrans with (rowlock)
			--INNER JOIN dbo.custinfo c with (nolock) ON bettrans.custid = c.custid
		where
			ruben=1 and 
			winlostdate < @fdate
		group by bettrans.srecommend;
	--COMMIT TRANSACTION

END
*/

/*
-- ================== STEP : 3
IF @step = 32
BEGIN
-- ================== Calculate Balance

	-- =====================
	--   CALCULATE BALANCE
	-- =====================
	SELECT
		CASE custid
		WHEN  recommend THEN 2
		WHEN mrecommend THEN 3
		WHEN srecommend THEN 4
		ELSE 1 END roleid, 
		custid, recommend, mrecommend, srecommend,
		SUM(CASE WHEN custid NOT IN (recommend, mrecommend, srecommend) THEN winlost-actual_stake + playercomm ELSE 0 END) amt1,
		SUM(CASE WHEN custid NOT IN (recommend, mrecommend, srecommend) THEN 1 ELSE 0 END) tcnt1,
		SUM(CASE WHEN custid =  recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END) amt2,
		SUM(CASE WHEN custid =  recommend THEN 1 ELSE 0 END) tcnt2,
		SUM(CASE WHEN custid = mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END) amt3,
		SUM(CASE WHEN custid = mrecommend THEN 1 ELSE 0 END) tcnt3,
		SUM(CASE WHEN custid = srecommend THEN winlost-actual_stake ELSE swinlost+scomm-acomm END) amt4,
		SUM(CASE WHEN custid = srecommend THEN 1 ELSE 0 END) tcnt4
	INTO #tempx
	FROM
		dbo.bettrans with (rowlock)
	WHERE
		ruben = 1
		AND winlostdate < @fdate
	GROUP BY
		custid, recommend, mrecommend, srecommend
		
	INSERT INTO dbo.BalanceTable (custid, amount, TicketCount, balTicketCount) SELECT custid, amt1, tcnt1, 0 FROM #tempx WHERE roleid = 1
	INSERT INTO dbo.BalanceTable (custid, amount, TicketCount, balTicketCount) SELECT recommend , SUM(amt2), SUM(tcnt2), 0 FROM #tempx GROUP BY recommend
	INSERT INTO dbo.BalanceTable (custid, amount, TicketCount, balTicketCount) SELECT mrecommend, SUM(amt3), SUM(tcnt3), 0 FROM #tempx GROUP BY mrecommend
	INSERT INTO dbo.BalanceTable (custid, amount, TicketCount, balTicketCount) SELECT srecommend, SUM(amt4), SUM(tcnt4), 0 FROM #tempx GROUP BY srecommend

	DROP TABLE #tempx


	--BEGIN TRANSACTION
		DELETE FROM dbo.balanceTable
		WHERE custid = 0

		update b
		set
			roleid = c.roleid,
			recommend = c.recommend,
			mrecommend= c.mrecommend,
			srecommend= c.srecommend,
			currency  = c.currency,
			UserName  = c.username,
			CurrencyName = e.currency,
			actualrate = IsNull(ed.ActualRate, e.ActualRate)
		from dbo.balancetable b
			INNER JOIN CustDB.dbo.custinfo c ON b.custid = c.custid
			INNER JOIN CustDB.dbo.exchange e ON c.currency = e.exchangeid
			LEFT OUTER JOIN CustDB.dbo.ExchangeDailyOanda ed ON c.currency = ed.ExchangeId AND ed.ExchangeDate = @fdate


		-- copy data, ready for insertion
		INSERT INTO dbo.balancetable_tmp
		SELECT @fdate, * FROM dbo.balancetable
	--COMMIT TRANSACTION

	-- =====================
	--   CLEAN OLD EVENTS
	-- =====================

		---- delete event/odds information

		--delete from DB02.bodb02.dbo.match
		--where matchid not in (select distinct matchid from bettrans where bettype <= 19000)
		--and kickofftime < @fdate

		-----> Put this code into [Acc_Apl_ExecRep_03]

		EXEC Acc_Apl_ExecRep_03 @fdate 

		EXEC DB02.bodb02.dbo.Task_BalanceUp_DB02 @fdate

	EXEC dbo.Task_BalanceUp_TriggerControl @step = 2, @on = 1

-- ================== END STEP : 3
END
-- ================== Calculate Balance
*/

-- ================== STEP : 3
IF @step = 3
BEGIN
-- ================== Calculate Balance

	-- =====================
	--   CALCULATE BALANCE
	-- =====================
	/*
	BalanceTable_tmp_cal will got data insert (almost) daily from job "DBTRANS : Balance Up (Cal_Balance)"
	data will uses to help verify value which calculate from below query while using lockhint NOLOCK
	for custid which data is not valid, then we calculate again using lockhint ROWLOCK
	*/
	INSERT INTO dbo.BalanceTable_tmp_cal
	SELECT
		DATEPART(dw, CURRENT_TIMESTAMP) dow,
		CASE custid
		WHEN  recommend THEN 2
		WHEN mrecommend THEN 3
		WHEN srecommend THEN 4
		ELSE 1 END roleid, 
		custid, recommend, mrecommend, srecommend,
		SUM(CASE WHEN custid NOT IN (recommend, mrecommend, srecommend) THEN winlost-actual_stake + playercomm ELSE 0 END) amt1,
		SUM(CASE WHEN custid NOT IN (recommend, mrecommend, srecommend) THEN 1 ELSE 0 END) tcnt1,
		SUM(CASE WHEN custid =  recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END) amt2,
		SUM(CASE WHEN custid =  recommend THEN 1 ELSE 0 END) tcnt2,
		SUM(CASE WHEN custid = mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END) amt3,
		SUM(CASE WHEN custid = mrecommend THEN 1 ELSE 0 END) tcnt3,
		SUM(CASE WHEN custid = srecommend THEN winlost-actual_stake ELSE swinlost+scomm-acomm END) amt4,
		SUM(CASE WHEN custid = srecommend THEN 1 ELSE 0 END) tcnt4
	FROM
		dbo.transfer with (nolock)
	WHERE winlostdate < @fdate
	GROUP BY
		custid, recommend, mrecommend, srecommend

	CREATE TABLE #balance_cal (roleid tinyint, 
		custid int, recommend int, mrecommend int, srecommend int, 
		amt1 money, amt2 money, amt3 money, amt4 money, cnt int default(0),
		tcnt1 int default(0), tcnt2 int default(0), tcnt3 int default(0), tcnt4 int default(0)
		)
		CREATE CLUSTERED INDEX IX_custid ON #balance_cal (custid)
		CREATE INDEX IX_roleid ON #balance_cal (roleid)
	CREATE TABLE #filtered (fcustid int PRIMARY KEY)

	;WITH q_distinct AS (
		SELECT roleid, custid, recommend, mrecommend, srecommend, amt1, amt2, amt3, amt4, COUNT(*) cnt
		FROM dbo.BalanceTable_tmp_cal WITH (PAGLOCK)
		GROUP BY roleid, custid, recommend, mrecommend, srecommend, amt1, amt2, amt3, amt4
		),
		q_tcnt AS (
		SELECT custid fcustid, MAX(tcnt1) as tcnt1, MAX(tcnt2) as tcnt2, MAX(tcnt3) as tcnt3, MAX(tcnt4) AS tcnt4
		FROM dbo.BalanceTable_tmp_cal WITH (PAGLOCK)
		GROUP BY custid
		)
	INSERT INTO #balance_cal ( 
		roleid, custid, recommend, mrecommend, srecommend, amt1, amt2, amt3, amt4, cnt, 
		tcnt1, tcnt2, tcnt3, tcnt4 
		)
		SELECT q_distinct.* , f.tcnt1, f.tcnt2, f.tcnt3, f.tcnt4
		FROM
			q_distinct INNER JOIN q_tcnt f ON q_distinct.custid = f.fcustid

	-- required to have at least 4 rows of matching data to consider valid	
	INSERT INTO #filtered
		SELECT DISTINCT custid FROM #balance_cal WITH (PAGLOCK) WHERE CNT <= 4

	-- remove invalid balance
	DELETE b
	FROM #balance_cal b INNER JOIN #filtered f ON b.custid = f.fcustid

	-- re-calculate balance for customer which got invalid balance
	INSERT INTO #balance_cal (roleid, custid, recommend, mrecommend, srecommend, amt1, tcnt1, amt2, tcnt2, amt3, tcnt3, amt4, tcnt4)
	SELECT
		CASE custid
		WHEN  recommend THEN 2
		WHEN mrecommend THEN 3
		WHEN srecommend THEN 4
		ELSE 1 END roleid, 
		custid, recommend, mrecommend, srecommend,
		SUM(CASE WHEN custid NOT IN (recommend, mrecommend, srecommend) THEN winlost-actual_stake + playercomm ELSE 0 END) amt1,
		SUM(CASE WHEN custid NOT IN (recommend, mrecommend, srecommend) THEN 1 ELSE 0 END) tcnt1,
		SUM(CASE WHEN custid =  recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END) amt2,
		SUM(CASE WHEN custid =  recommend THEN 1 ELSE 0 END) tcnt2,
		SUM(CASE WHEN custid = mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END) amt3,
		SUM(CASE WHEN custid = mrecommend THEN 1 ELSE 0 END) tcnt3,
		SUM(CASE WHEN custid = srecommend THEN winlost-actual_stake ELSE swinlost+scomm-acomm END) amt4,
		SUM(CASE WHEN custid = srecommend THEN 1 ELSE 0 END) tcnt4
	FROM
		dbo.Transfer t with (rowlock)
		INNER JOIN #filtered f ON t.custid = f.fcustid
	WHERE winlostdate < @fdate
	GROUP BY
		custid, recommend, mrecommend, srecommend		
		
	INSERT INTO dbo.BalanceTable (custid, amount, TicketCount, balTicketCount) SELECT custid, amt1, tcnt1, 0			   FROM #balance_cal WHERE roleid = 1
	INSERT INTO dbo.BalanceTable (custid, amount, TicketCount, balTicketCount) SELECT recommend , SUM(amt2), SUM(tcnt2), 0 FROM #balance_cal GROUP BY recommend
	INSERT INTO dbo.BalanceTable (custid, amount, TicketCount, balTicketCount) SELECT mrecommend, SUM(amt3), SUM(tcnt3), 0 FROM #balance_cal GROUP BY mrecommend
	INSERT INTO dbo.BalanceTable (custid, amount, TicketCount, balTicketCount) SELECT srecommend, SUM(amt4), SUM(tcnt4), 0 FROM #balance_cal GROUP BY srecommend

	DROP TABLE #balance_cal
	DROP TABLE #filtered

	--BEGIN TRANSACTION
		DELETE FROM dbo.balanceTable
		WHERE custid = 0

		update b
		set
			roleid = c.roleid,
			recommend = c.recommend,
			mrecommend= c.mrecommend,
			srecommend= c.srecommend,
			currency  = c.currency,
			UserName  = c.username,
			CurrencyName = e.currency,
			actualrate = IsNull(ed.ActualRate, e.ActualRate)
		from dbo.balancetable b
			INNER JOIN CustDB.dbo.custinfo c ON b.custid = c.custid
			INNER JOIN CustDB.dbo.exchange e ON c.currency = e.exchangeid
			LEFT OUTER JOIN CustDB.dbo.ExchangeDailyOanda ed ON c.currency = ed.ExchangeId AND ed.ExchangeDate = DATEADD(day, -1, @fdate)

		update b
		set
			roleid = 1,
			recommend = c.recommend,
			mrecommend= ag.mrecommend,
			srecommend= ag.srecommend,
			currency  = ag.currency,
			UserName  = c.username,
			CurrencyName = e.currency,
			actualrate = IsNull(ed.ActualRate, e.ActualRate)
		from dbo.balancetable b
			INNER JOIN CustDB.dbo.Dep_Customer_Archived c ON b.custid = c.custid
			INNER JOIN CustDB.dbo.custinfo ag ON ag.custid = c.Recommend
			INNER JOIN CustDB.dbo.exchange e ON ag.currency = e.exchangeid
			LEFT OUTER JOIN CustDB.dbo.ExchangeDailyOanda ed ON ag.currency = ed.ExchangeId AND ed.ExchangeDate = DATEADD(day, -1, @fdate)


		-- copy data, ready for insertion
		INSERT INTO dbo.balancetable_tmp
		SELECT @fdate, * FROM dbo.balancetable
	--COMMIT TRANSACTION

	-- =====================
	--   CLEAN OLD EVENTS
	-- =====================

		---- delete event/odds information

		--delete from DB02.bodb02.dbo.match
		--where matchid not in (select distinct matchid from bettrans where bettype <= 19000)
		--and kickofftime < @fdate

		-----> Put this code into [Acc_Apl_ExecRep_03]

		EXEC Acc_Apl_ExecRep_03 @fdate 

		--EXEC DB02.bodb02.dbo.Task_BalanceUp_DB02 @fdate

	EXEC dbo.Task_BalanceUp_TriggerControl @step = 2, @on = 1
	
	--//remove all data in processing list
	DELETE FROM dbo.ProcessingCustList WITH(ROWLOCK)

-- ================== END STEP : 3
END
-- ================== Calculate Balance


-- ======================
--   INSERT NEW BALANCE
-- ======================
-- start remove transaction/insert balance

-- ================== STEP : 4
IF @step = 4
BEGIN

	SET DEADLOCK_PRIORITY HIGH

	--insert processing list
	EXEC dbo.Task_Core_ProcessingCustListIns @CustIds = '3'
	WAITFOR DELAY '00:00:03:000'

	BEGIN TRANSACTION

	DELETE FROM dbo.balanceTable_tmp
	WHERE srecommend = 3 AND recommend = 0

	EXEC dbo.ExecRep_07 3, 0, 44, @fdate

	COMMIT TRANSACTION

	--delete processing list
	EXEC dbo.Task_Core_ProcessingCustListDel @CustIds = '3'

-- ================== BalanceUp Agent
	SET NOCOUNT ON
	EXEC dbo.Task_BalanceUp_SubAgent @fdate
	SET NOCOUNT OFF
-- ================== END STEP : 4
	
	SET DEADLOCK_PRIORITY NORMAL

END
-- ================== BalanceUp Agent

-- ================== STEP : 5
IF @step = 5
BEGIN
	SET DEADLOCK_PRIORITY HIGH

-- ================== BalanceUp Super
	SET NOCOUNT ON
	EXEC dbo.Task_BalanceUp_SubSuper @fdate
	SET NOCOUNT OFF
-- ================== END STEP : 5

	SET DEADLOCK_PRIORITY NORMAL

END
-- ================== BalanceUp Super

-- ================== STEP : 6 BalanceUp Headline
IF @step = 6
BEGIN
	SET DEADLOCK_PRIORITY HIGH

	EXEC dbo.Task_BalanceUp_Headline @winlostdate = @fdate

	SET DEADLOCK_PRIORITY NORMAL

END
-- ================== BalanceUp headline (roleid = 0)


-- ================== STEP : 7
IF @step = 7
BEGIN
-- ================== Finishing
	SELECT TOP(1) @fdate = winlostdate
	FROM dbo.Transfer WITH (NOLOCK)
	WHERE bettype = 20000
	ORDER BY transid
		
	--//remove all data in processing list
	DELETE FROM dbo.ProcessingCustList WITH(ROWLOCK)

	EXEC dbo.Task_BalanceUp_TriggerControl @step = 2, @on = 0

	-- end comment

		EXEC dbo.balancecheck @fdate, 21

	-- UPDATE DBACC.bodb02.dbo.SystemSettings
	-- SET VValue = '0'
	-- WHERE VName = 'isArchivingBet' 
	EXEC dbo.Task_UpdSystemSetting @VValue = '0', @VName = 'isArchivingBet'
	EXEC DBACC.bodb02.dbo.Task_UpdSystemSetting @VValue = '0', @VName = 'isArchivingBet'

	--//turn off isArchivingBet_Local flag
	--EXEC dbo.Bet_ExecRep_09 @mode = 6
	EXEC dbo.Transfer_ExecRep_02 @Mode = 6
	EXEC dbo.ExecRep_09 @recommend = 0, @winlostdate = NULL, @parlay = 6, @tableName = 'SystemSettings'

	SET @Doing = 'Task_BalanceUp_background : Done'
	EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing
-- ================== END STEP : 7
END
-- ================== Finishing


