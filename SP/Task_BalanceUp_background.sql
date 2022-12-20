/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_BalanceUp_background]
	@fdate SMALLDATETIME = NULL,
	@step TINYINT = 1,
	@errCode INT = 0
AS
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
	- 20220727@Patrick: Support new transid [Redmine: #175666]
	- 20220804@Patrick: Support scale-out for deposit site Redmine: [#175602]
	- 20221216@Patrick: Balance-Up support transfer 247 [RedmineID: #173554]

Param's Explanation: 

*/
BEGIN
	SET NOCOUNT ON
	DECLARE @__delayTimeValue VARCHAR(50), @Doing VARCHAR(300)
		, @__rowId INT, @__errorMessage VARCHAR(300)
		, @__rowcount INT = 0, @__aliasServer VARCHAR(128) = ''

	IF @fdate IS NULL
	BEGIN
		SELECT @errCode = 1000
			, @__errorMessage = 'ERROR: Please check a balance-up date value. @fdate = null, @step: ' + CAST(@step AS VARCHAR(10))
		RAISERROR (@__errorMessage, 16, 1);
		RETURN
	END

	SET @Doing = 'Task_BalanceUp_background: Starting step: ' + CAST(@step AS VARCHAR(10))
	EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

	IF @step = 1 -- update being balance-up date
	BEGIN
		--turn on starting BU process
		SET @Doing = 'Task_BalanceUp_background: BU step 1.01 - Starting update BeingBalanceUpDate flag, @fdate: ' + CONVERT(VARCHAR(10), @fdate, 121)
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

		--**update being balanceUp date flag ==> the purpose for which process need to check balanceUp processing
		EXEC dbo.ExecRep_09 @recommend = 0, @winlostdate = @fdate, @keyFlag = 11, @tableName = 'MBUSettings'

		SET @Doing = 'Task_BalanceUp_background: BU step 1.01 - Ending update BeingBalanceUpDate flag, @fdate: ' + CONVERT(VARCHAR(10), @fdate, 121)
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

		SET @Doing = 'call Task_BalanceUp_background @fdate = ' + CONVERT(nvarchar(10), @fdate, 120) + ', @step = ' + CAST(@step as nvarchar(2)) + ', start turn on flag 20k'
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing  

		--**turn on copy 20k flag
		EXEC dbo.Transfer_ExecRep_02 @Mode = 7, @TableName = 'MBUSettings'

		SET @Doing = 'call Task_BalanceUp_background @fdate = ' + CONVERT(nvarchar(10), @fdate, 120) + ', @step = ' + CAST(@step as nvarchar(2)) + ', end turn on flag 20k'
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing  

		--//
		SELECT @__delayTimeValue = dbo.f_BU_GetDelayTime('BeforeBU')
		WAITFOR DELAY @__delayTimeValue --waitfor a seconds to start balanceUp process

		SET @Doing = 'Task_BalanceUp_background: Ending step: ' + CAST(@step AS VARCHAR(10))
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

		RETURN
	END
	ELSE IF @step = 2 --data verify
	BEGIN
		SET @Doing = 'Task_BalanceUp_background: BU step 2.00 - Verify data, @fdate: ' + CONVERT(VARCHAR(10), @fdate, 121)
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

		--- DATA VERIFY
		IF EXISTS (
			SELECT TOP 1 1 
			FROM CustDB.dbo.Customer WITH (NOLOCK) 
			WHERE (recommend IS NULL OR mrecommend IS NULL OR srecommend IS NULL) 
				AND roleid IN (2,1)
		)
		BEGIN
			SELECT @errCode = 221
			RAISERROR ('Some Customer/Agent records have NULL AgentID', 16, 1)
			RETURN
		END

		IF EXISTS (
			SELECT TOP 1 1 
			FROM CustDB.dbo.customer WITH (NOLOCK) 
			WHERE (recommend IS NULL OR mrecommend IS NULL OR srecommend IS NULL) 
				AND roleid = 3
		)
		BEGIN
			SELECT @errCode = 222
			RAISERROR ('Some Master records have NULL AgentID', 16, 1)
			RETURN
		END

		IF EXISTS (
			SELECT TOP 1 1 
			FROM CustDB.dbo.customer WITH (NOLOCK) 
			WHERE (recommend IS NULL OR mrecommend IS NULL OR srecommend IS NULL) 
				AND roleid = 4
		)
		BEGIN
			SELECT @errCode = 223
			RAISERROR ('Some SuperAgent records have NULL AgentID', 16, 1)
			RETURN
		END

		IF EXISTS (
			SELECT TOP 1 1
			FROM dbo.Transfer WITH (NOLOCK) 
			WHERE winlostdate < @fdate 
				AND (srecommend IS NULL OR mrecommend IS NULL OR recommend IS NULL
					OR swinlost IS NULL OR mwinlost IS NULL OR awinlost IS NULL OR winlost IS NULL
					OR scomm IS NULL OR acomm IS NULL OR comm IS NULL OR playercomm IS NULL
					OR ((scomm <> acomm OR swinlost <> 0) AND srecommend <= 100))
		)
		BEGIN
			SELECT @errCode = 224
			RAISERROR ('Some records in Transfer have NULL AgentID/NULL winlost/NULL commission/incorrect Company SuperAgent setting', 16, 1)
			RETURN
		END

		SET @Doing = 'Task_BalanceUp_background : Ending step: ' + CAST(@step AS VARCHAR(10))
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing
	END
	ELSE IF @step = 3 -- backup dbs
	BEGIN
		DECLARE @CurrentDateTime DATETIME
		SELECT @CurrentDateTime = GETDATE()

		EXEC dbo.Task_EstimatedTimeForJobDone @IsMoveBet = 0
			, @CurrentDateTime = @CurrentDateTime
			, @TotalMoveBetDays = NULL

		EXEC dbo.Task_MBUSettingsUpd @VValue = '1', @VName = 'isArchivingBet', @Mode = 0

		--//turn on isArchivingBet_Local flag
		EXEC dbo.Transfer_ExecRep_02 @Mode = 5, @TableName = 'MBUSettings'
		EXEC dbo.ExecRep_09 @recommend = 0, @winlostdate = NULL, @keyFlag = 5, @tableName = 'MBUSettings'

		-- for safety, shutdown trigger in balanceTable_tmp
		EXEC dbo.Task_BalanceUp_TriggerControl @step = 1, @on = 0
		EXEC dbo.Task_BalanceUp_TriggerControl @step = 2, @on = 0

		TRUNCATE TABLE dbo.balanceTable
		TRUNCATE TABLE dbo.balanceTable_tmp

		EXEC dbo.balancecheck @fdate, 11
		EXEC dbo.ExecRep_10 @FunctionName = 'ScaleOut', @AliasServer = @__aliasServer OUTPUT
		
		SET @Doing = 'Task_BalanceUp_background: BU step 3.03 - backup database: custdb, @fdate: ' + CONVERT(VARCHAR(10), @fdate, 121)
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing
		--//only central server can run backup DBCUST.custdb
		IF @__aliasServer = 'DBCTG' --only run that command at central server
		BEGIN
			EXEC DBCUST.msdb.dbo.sp_start_job N'BalanceUPBackground_BackupFull_Cust'
		END

		SET @Doing = 'Task_BalanceUp_background: BU step 3.04 - backup database: bodb02 @dbtrans | grpX, @fdate: ' + CONVERT(VARCHAR(10), @fdate, 121)
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing
		-- doing backup
		Declare @suffix varchar(10)
		SET @suffix = 'bbu' + RIGHT(CONVERT(varchar(10), @fdate,120),5)
		--//backup bodb02@dbtrans
		EXEC dbo.Task_BackupFULL @suffix
	
		SET @Doing = 'Task_BalanceUp_background: BU step 3.05 - backup database: bodb02 @prod, @fdate: ' + CONVERT(VARCHAR(10), @fdate, 121)
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing
		
		--//only central server can run backup DB02.bodb02
		IF @__aliasServer = 'DBCTG' --only run that command at central server
		BEGIN
			EXEC DB02.bodb02.dbo.Task_BackupFULL @suffix
		END

		SET @Doing = 'Task_BalanceUp_background : Ending step: ' + CAST(@step AS VARCHAR(10))
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing
		
		RETURN
	END
	ELSE IF @step = 4
	BEGIN
		-- =====================
		--   CALCULATE BALANCE
		-- =====================
		/*
		BalanceTable_tmp_cal will got data insert (almost) daily from job "DBTRANS : Balance Up (Cal_Balance)"
		data will uses to help verify value which calculate from below query while using lockhint NOLOCK
		for custid which data is not valid, then we calculate again using lockhint ROWLOCK
		*/
		SET @Doing = 'Task_BalanceUp_background: BU step 4.01 - Starting insert data into BalanceTable_tmp_cal, @fdate: ' + CONVERT(VARCHAR(10), @fdate, 121)
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

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
		FROM dbo.transfer with (nolock)
		WHERE winlostdate < @fdate
		GROUP BY custid, recommend, mrecommend, srecommend

		SET @Doing = 'Task_BalanceUp_background: BU step 4.02 - Starting insert data into #balance_cal, @fdate: ' + CONVERT(VARCHAR(10), @fdate, 121)
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

		CREATE TABLE #balance_cal (roleid tinyint, 
			custid int, recommend int, mrecommend int, srecommend int, 
			amt1 money, amt2 money, amt3 money, amt4 money, cnt int default(0),
			tcnt1 int default(0), tcnt2 int default(0), tcnt3 int default(0), tcnt4 int default(0)
		)
		CREATE CLUSTERED INDEX IX_custid ON #balance_cal (custid)

		--due to IX_roleId index does not help so removing statement create non clustered to avoid transaction log growth
		--CREATE INDEX IX_roleid ON #balance_cal (roleid)
	
		CREATE TABLE #filtered (fcustid int PRIMARY KEY)
		;WITH q_distinct AS (
			SELECT roleid, custid, recommend, mrecommend, srecommend, amt1, amt2, amt3, amt4, COUNT(*) cnt
			FROM dbo.BalanceTable_tmp_cal WITH (PAGLOCK)
			GROUP BY roleid, custid, recommend, mrecommend, srecommend, amt1, amt2, amt3, amt4
		), q_tcnt AS (
			SELECT custid fcustid, MAX(tcnt1) as tcnt1, MAX(tcnt2) as tcnt2, MAX(tcnt3) as tcnt3, MAX(tcnt4) AS tcnt4
			FROM dbo.BalanceTable_tmp_cal WITH (PAGLOCK)
			GROUP BY custid
		)
		INSERT INTO #balance_cal ( 
			roleid, custid, recommend, mrecommend, srecommend, amt1, amt2, amt3, amt4, cnt, 
			tcnt1, tcnt2, tcnt3, tcnt4 
		)
		SELECT q_distinct.* , f.tcnt1, f.tcnt2, f.tcnt3, f.tcnt4
		FROM q_distinct INNER JOIN q_tcnt f ON q_distinct.custid = f.fcustid

		SET @Doing = 'Task_BalanceUp_background: BU step 4.03 - Starting adjust data into #balance_cal, @fdate: ' + CONVERT(VARCHAR(10), @fdate, 121)
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

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
		FROM dbo.Transfer t with (rowlock)
			INNER JOIN #filtered f ON t.custid = f.fcustid
		WHERE winlostdate < @fdate
		GROUP BY custid, recommend, mrecommend, srecommend		
		
		SET @__rowcount = @@ROWCOUNT
		SET @Doing = 'Task_BalanceUp_background: BU step 4.03 - Ending adjust data into #balance_cal, @fdate: ' + CONVERT(VARCHAR(10), @fdate, 121) + ', @__rowcount: ' + CAST(@__rowcount AS VARCHAR(20))
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

		SET @Doing = 'Task_BalanceUp_background: BU step 4.04 - Starting insert data into BalanceTable, @fdate: ' + CONVERT(VARCHAR(10), @fdate, 121)
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

		INSERT INTO dbo.BalanceTable (custid, amount, TicketCount, balTicketCount) SELECT custid, amt1, tcnt1, 0			   FROM #balance_cal WHERE roleid = 1
		INSERT INTO dbo.BalanceTable (custid, amount, TicketCount, balTicketCount) SELECT recommend , SUM(amt2), SUM(tcnt2), 0 FROM #balance_cal GROUP BY recommend
		INSERT INTO dbo.BalanceTable (custid, amount, TicketCount, balTicketCount) SELECT mrecommend, SUM(amt3), SUM(tcnt3), 0 FROM #balance_cal GROUP BY mrecommend
		INSERT INTO dbo.BalanceTable (custid, amount, TicketCount, balTicketCount) SELECT srecommend, SUM(amt4), SUM(tcnt4), 0 FROM #balance_cal GROUP BY srecommend

		DROP TABLE #balance_cal
		DROP TABLE #filtered

		DELETE FROM dbo.balanceTable
		WHERE custid = 0

		SET @Doing = 'Task_BalanceUp_background: BU step 4.05 - Starting update sma | actualrate data on BalanceTable (1), @fdate: ' + CONVERT(VARCHAR(10), @fdate, 121)
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

		UPDATE b
		SET roleid = c.roleid,
			recommend = c.recommend,
			mrecommend= c.mrecommend,
			srecommend= c.srecommend,
			currency  = c.currency,
			UserName  = c.username,
			CurrencyName = e.currency,
			actualrate = IsNull(ed.ActualRate, e.ActualRate)
		FROM dbo.balancetable b
			INNER JOIN CustDB.dbo.custinfo c ON b.custid = c.custid
			INNER JOIN CustDB.dbo.exchange e ON c.currency = e.exchangeid
			LEFT OUTER JOIN CustDB.dbo.ExchangeDailyOanda ed ON c.currency = ed.ExchangeId AND ed.ExchangeDate = DATEADD(day, -1, @fdate)

		SET @Doing = 'Task_BalanceUp_background: BU step 4.06 - Starting update sma | actualrate data on BalanceTable (2), @fdate: ' + CONVERT(VARCHAR(10), @fdate, 121)
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

		UPDATE b
		SET roleid = 1,
			recommend = c.recommend,
			mrecommend= ag.mrecommend,
			srecommend= ag.srecommend,
			currency  = ag.currency,
			UserName  = c.username,
			CurrencyName = e.currency,
			actualrate = IsNull(ed.ActualRate, e.ActualRate)
		FROM dbo.balancetable b
			INNER JOIN CustDB.dbo.Dep_Customer_Archived c ON b.custid = c.custid
			INNER JOIN CustDB.dbo.custinfo ag ON ag.custid = c.Recommend
			INNER JOIN CustDB.dbo.exchange e ON ag.currency = e.exchangeid
			LEFT OUTER JOIN CustDB.dbo.ExchangeDailyOanda ed ON ag.currency = ed.ExchangeId AND ed.ExchangeDate = DATEADD(day, -1, @fdate)

		SET @Doing = 'Task_BalanceUp_background: BU step 4.07 - Starting insert data into balancetable_tmp, @fdate: ' + CONVERT(VARCHAR(10), @fdate, 121)
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

		-- copy data, ready for insertion
		INSERT INTO dbo.balancetable_tmp
		SELECT @fdate, * FROM dbo.balancetable
		
		SET @__rowcount = @@ROWCOUNT
		SET @Doing = 'Task_BalanceUp_background: BU step 4.07 - Ending insert data into balancetable_tmp, @fdate: ' + CONVERT(VARCHAR(10), @fdate, 121) + ', @__rowcount: ' + CAST(@__rowcount AS VARCHAR(20))
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

		EXEC dbo.ExecRep_10 @FunctionName = 'ScaleOut', @AliasServer = @__aliasServer OUTPUT
		--//only central server can run backup DBCUST.custdb
		IF @__aliasServer = 'DBCTG' --only run that command at central server
		BEGIN
			EXEC Acc_Apl_ExecRep_03 @fdate 
		END

		EXEC dbo.Task_BalanceUp_TriggerControl @step = 2, @on = 1
	
		--//remove all data in processing list
		DELETE FROM dbo.ProcessingCustList WITH(ROWLOCK)

		SET @Doing = 'Task_BalanceUp_background : Ending step: ' + CAST(@step AS VARCHAR(10))
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

		RETURN
	END
	ELSE IF @step = 5 --insert new 20k
	BEGIN
		DECLARE @__tryCnt INT = 0, @__errorCode INT
		SET DEADLOCK_PRIORITY HIGH

		WHILE 1 = 1
		BEGIN
			BEGIN TRY
				
				__retry_when_duplicated_pk:
				--//insert new 20k
				DELETE TOP(1000) bal FROM dbo.balanceTable_tmp bal

				IF @@ROWCOUNT = 0
					BREAK

				SELECT @__delayTimeValue = dbo.f_BU_GetDelayTime('Key1') --default 700ms
				WAITFOR DELAY @__delayTimeValue --Task_BalanceUp_background: waitfor insert new 20k
				
				--reset try cnt for next times
				SET @__tryCnt = 1

			END TRY
			BEGIN CATCH
				SELECT @__errorCode = @@ERROR, @__errorMessage = ERROR_MESSAGE(), @__tryCnt = @__tryCnt + 1
				IF @@TRANCOUNT > 0
				BEGIN
					ROLLBACK
				END

				--write logs:
				SET @Doing = CONCAT(@@SERVERNAME, ' | Task_BalanceUp_background: duplicated transid (1). Err: ', @__errorMessage)
				EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

				IF @__errorCode = 2627 --Violation of PRIMARY KEY constraint
				BEGIN
					IF @__tryCnt = 5
					BEGIN
						--Send notification to dba
						EXEC dbo.DBA_Task_Send_SimpleNotifyMessageToDBA
							@SubjectName = 'Urgently!!! BU - Notification',
							@MessageName = @Doing

						SELECT @errCode = 551
						--duplicated PK reach to limitation then throw error and quit job
						RAISERROR(@__errorMessage, 16, 1)
						RETURN
					END

					WAITFOR DELAY '00:00:01:333' -- Task_BalanceUp_background: duplicated transid then waitfor to retry
					GOTO __retry_when_duplicated_pk
				END
				ELSE
				BEGIN
					SELECT @errCode = 552
					--other exception then throw error and quit job
					RAISERROR(@__errorMessage, 16, 1)
					RETURN
				END
			END CATCH
		END

		SET DEADLOCK_PRIORITY NORMAL
		
		SET @Doing = 'Task_BalanceUp_background BU step 6.01 - Starting turn off BU_DoneSum20k flag ' + CAST(@step AS VARCHAR(10))
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

		--//turn off BU_DoneSum20k flag
		EXEC dbo.Transfer_ExecRep_02 @Mode = 8, @TableName = 'MBUSettings'

		SET @Doing = 'Task_BalanceUp_background BU step 6.01 - Ending turn off BU_DoneSum20k flag ' + CAST(@step AS VARCHAR(10))
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

		SET @Doing = 'Task_BalanceUp_background : Ending step: ' + CAST(@step AS VARCHAR(10))
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

		RETURN

	END
	ELSE IF @step = 6--wait for replicated servers and sietdbs perform done and then go to update balanceUp date flag
	BEGIN

		DECLARE @__start DATETIME
		SET @__start = GETDATE()
		WHILE EXISTS (
			SELECT TOP 1 1 FROM dbo.MBUSettings WHERE VName = 'BU_ReadyUpdBUDate' AND VValue <> '0'
		)
		BEGIN
			WAITFOR DELAY '00:01:00:000' --waitfor BU_ReadyUpdBUDate done...
			IF DATEDIFF(MINUTE, @__start, GETDATE()) > 120
			BEGIN
				--Send notification to dba
				SET @Doing = 'Urgently!!! BalanceUp - hey guys, BalanceUp background run long time at step 6 (1). Please check!!!'
				EXEC dbo.DBA_Task_Send_SimpleNotifyMessageToDBA
					@SubjectName = 'Urgently!!! BalanceUp - Notification',
					@MessageName = @Doing

			END
		END

		--//turn on BU_UpdBUDate_Local flag ==> to determine a pub update data already throughput 
		EXEC dbo.ExecRep_09 @recommend = 0, @winlostdate = @fdate, @keyFlag = 13, @tableName = 'MBUSettings'
		
		SET @Doing = 'Task_BalanceUp_background BU step 6.02 - Starting update BalanceUpDate flag ' + CAST(@step AS VARCHAR(10))
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

		--//**update BalanceUpDate value
		EXEC dbo.ExecRep_09 @recommend = 0, @winlostdate = @fdate, @keyFlag = 12, @tableName = 'MBUSettings'

		SET @Doing = 'Task_BalanceUp_background BU step 6.02 - Ending update BalanceUpDate flag' + CAST(@step AS VARCHAR(10))
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

		--//turn off BU_UpdBalDate_Local flag
		EXEC dbo.ExecRep_09 @recommend = 0, @winlostdate = @fdate, @keyFlag = 14, @tableName = 'MBUSettings'

		--//whether update balanceup date has done on replicated | sitedbs servers yet?
		SET @__start = GETDATE()
		WHILE EXISTS (
			SELECT TOP 1 1 FROM dbo.MBUSettings WHERE VName = 'BU_ReadyToDelete' AND VValue <> '0'
		)
		BEGIN
			WAITFOR DELAY '00:01:00:000' --waitfor BU_ReadyToDelete done...
			IF DATEDIFF(MINUTE, @__start, GETDATE()) > 30
			BEGIN
				--Send notification to dba
				SET @Doing = 'Urgently!!! BalanceUp - hey guys, BalanceUp background run long time at step 6 (1). Please check!!!'
				EXEC dbo.DBA_Task_Send_SimpleNotifyMessageToDBA
					@SubjectName = 'Urgently!!! BalanceUp - Notification',
					@MessageName = @Doing

			END
		END

		--//
		SELECT @__delayTimeValue = dbo.f_BU_GetDelayTime('AfterUpdBUD')
		WAITFOR DELAY @__delayTimeValue --Task_BalanceUp_background: waitfor go to delete step...
		
		SET @Doing = 'Task_BalanceUp_background : Ending step: ' + CAST(@step AS VARCHAR(10))
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

		RETURN

	END
	ELSE IF @step = 7 --delete old data: old 20k, sum 19999 and transfer
	BEGIN
		
		SET DEADLOCK_PRIORITY HIGH

		SELECT @__rowId  = 0, @__rowcount = 0
		CREATE TABLE #__transIds(rowId INT IDENTITY(1,1) PRIMARY KEY, transId BIGINT)

		DECLARE @__strTransIds NVARCHAR(MAX), @__rowcounttemp INT = 0
		
		WHILE 1 = 1
		BEGIN
			TRUNCATE TABLE #__transIds
			SELECT @__rowId = 1, @__rowcounttemp = 0

			INSERT INTO #__transIds(transId)
			SELECT TOP(50000) transid
			FROM dbo.Transfer WITH(NOLOCK)
			WHERE winlostdate < @fdate

			SET @__rowcounttemp = @@ROWCOUNT
			IF @__rowcounttemp = 0
				BREAK

			SET @__rowcount += @__rowcounttemp
				
			WHILE 1 = 1
			BEGIN
				SET @__strTransIds = NULL

				SELECT @__strTransIds = COALESCE(@__strTransIds + '^' + CAST(transid AS VARCHAR(50)), CAST(transid AS VARCHAR(50)))
				FROM #__transIds WHERE rowId >= @__rowId AND rowId < @__rowId + 2000

				IF @@ROWCOUNT = 0
					BREAK

				EXEC dbo.ExecRep_07 @custids = '', @custid = 0, @roleid = 111, @winlostdate = @fdate, @transIds = @__strTransIds
				
				SET @__rowId += 2000
			END

			--waitfor delay on each batch 50k.
			SELECT @__delayTimeValue = dbo.f_BU_GetDelayTime('DeleteBU') --default 280ms
			WAITFOR DELAY @__delayTimeValue --waitfor deleting data BU...

		END

		SET @Doing = 'Task_BalanceUp_background : Ending step: ' + CAST(@step AS VARCHAR(10)) + ', @__rowcount: ' + CAST(@__rowcount AS VARCHAR(20))
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

		SET DEADLOCK_PRIORITY NORMAL
		RETURN

	END
	ELSE IF @step = 8 --turn off trigger | flag and completed balanceUP
	BEGIN
		SET @Doing = 'Task_BalanceUp_background : Starting step: ' + CAST(@step AS VARCHAR(10))
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

		EXEC dbo.Task_BalanceUp_TriggerControl @step = 2, @on = 0

		EXEC dbo.balancecheck @fdate, 21

		EXEC dbo.Task_MBUSettingsUpd @VValue = '0', @VName = 'isArchivingBet', @Mode = 0

		--reset being balanceup date
		EXEC dbo.ExecRep_09 @recommend = 0, @winlostdate = null, @keyFlag = 11, @tableName = 'MBUSettings'

		--//turn off isArchivingBet_Local flag
		EXEC dbo.Transfer_ExecRep_02 @Mode = 6, @TableName = 'MBUSettings'
		EXEC dbo.ExecRep_09 @recommend = 0, @winlostdate = NULL, @keyFlag = 6, @tableName = 'MBUSettings'

		SET @Doing = 'Task_BalanceUp_background : Ending step: ' + CAST(@step AS VARCHAR(10))
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

		SET @Doing = 'Task_BalanceUp_background : Done'
		EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing

		RETURN
	END
END


