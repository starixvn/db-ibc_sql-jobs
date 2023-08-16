/*<info serverAlias="DBTEST-bodb02"></info>*/
/*
	Created: 20230816@Bobby
	Task: 182071 - Alpha - AutoJob ClearBalanceCust
	DB: DBTEST-bodb02
	Remark: Run on DBTEST
*/
USE [bodb02]
GO

ALTER PROCEDURE  [dbo].[Age_Transfer_Ins_MAg_xtest]
	@MasterID int,
	@ToCustIDs varchar(4000),
	@SuperIDsTransferTotal VARCHAR(50)='', 
	@creator int,
	@FullTransfer bit = 1,
	@AmtTrans money = 0,
	@Language varchar(2)= 'E',
	@SubAccID int = 0, --Sub-AccountID
	@IP varchar(45)='',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT,	
	@CustStatus varchar(50)='',
	@IsAutoTransfer BIT = 0
AS
/*
Created: 
Task: Transfer
DB: DBTXN/bodb02
Original: Age_Transfer_In

Revisions:
	- 20090318@Phuc: Korean language.
	- 20090417@PhuongDao: Allow some masters to transfer total balance including today balance 
	- 20090729@Phuc: Write log subaccname instead of subaccid.
	- 20090818@Phuc: check page access and check upline closed first(call Age_CustSubCheckPageAccess)
	- 20091003@Kiwi: Modify Write log function
	- 20091125@Kiwi: Remove comstatus because it's no used.
	- 20100424@Henry: insert data to column StatusID of Bettrans (StatusID = 131 for bettype 103)
	- 20100611@Henry: Write exact amount to log when transferring
	- 20101224@Johnson: Apply new arrange of bettype
	- 20120104@Lukas: modify to filter by 'enabled' status
	- 20120202@Jamie:Change transfer time to 12pm to 11:59pm instead of 12pm to 10pm ( 9h59pm)
	- 20121128@Elodie: Get an error message from f_Get_MsgNameByMsgID function by language
	- 20130201@Johnson: Write log into DBTXN if failure DBLOG server
	- 20131108@Elodie: Splitting bodb02 into CustDB (Call CustInfo, Exchange, Age_Transfer_CheckTransferOption by link database)
	- 20150606@Kathy: Migrate custDB to new server DBCust [Redmine:#36216]
	- 20160127@Kathy: get balance from bettransRNG & bettransLC [Redmine:#50674]
	- 20160815@Patrick: Allow SMA to transfer in 24 hours [Redmine:#61626]
	- 20170609@Percy:
		1. Re-check [Allow SMA to transfer in 24 hours]: apply general sp Acc_CheckProcessingData [RedmineID: #78487]
		2. Change way to calculate balance [RedmineID: #74291]
	- 20170831@Percy: Add SP Name into log [RedmineID: #80978]
	- 20200602@Percy: Separate PendingTransfer3rd from Cash and Balance [RedmineID: #135200]
	- 20200821@Sophia: prevent duplicated transfer [Redmine: #137141]
	- 20200821@Sophia: Check UM Transfer Function [Redmine: #136992]
	- 20201005@Danny: Convert Ipv6 to dummy IPv4 [Redmine: #142511]
	- 20201015@Malcolm : Add sub account information when transfering [RedmineId : #143478]
	- 20201228@Danny: Capture total cash before transfering  [Redmine: #146038]
	- 20210603@Sol: Alpha - All Sites - Lock account & indirect close account - [RedmineID: #148600]
	- 20210723@Evan: Transfer all pages work incorrect with disabled account [RedmineID: #158813]
	- 20210505@Sol: NAP - Alpha - Allow more time for transfer - [Redmine: #149927]
	- 20210817@Sophia: Fix overflow Refno [Redmine: #160262]
	- 20211111@Evan: Split transfer tickets out of bettrans - [Redmine: #164196]
	- 20220315@Evan: SQL Server Upgrade STRING_SPLIT [Redmine: #168783]
	- 20220721@Danny: get transid and refno with new generation [Redmine: #175670]
	- 20230227@Evan: Balance-Up support transfer 247 [Redmine: #173554] 
	- 20230523@Danny: support scale out credit [Redmine: #181595]
	- 20230227@Bobby: Auto Clear Balance/ Multiple Transfer	 [RedmineID: #182071]

Param's Explanation:
	• @AmtTrans: amount of money
	• @MasterID: from master
	• @ToCustIDs: list custid
	  @SuperIDsTransferTotal: Supers are allowed to tranfer total balance including today balance 

*/
BEGIN

	SET NOCOUNT ON;

	DECLARE @rCount INT, @FromCustID INT, @PairStatus VARCHAR(15), @Result nvarchar(4000);
	-- TODO: support auto clear balance
	DECLARE @tblResultMember TABLE(CustId INT PRIMARY KEY, UserName VARCHAR(50), MsgId INT, ErrType VARCHAR(50), ErrMsg NVARCHAR(4000), RefNo BIGINT);
	INSERT INTO @tblResultMember(CustId)
	SELECT DISTINCT t.value
	FROM STRING_SPLIT(@ToCustIDs, ',') AS t;

	SELECT @FromCustID = @MasterId;

	CREATE TABLE #Agent (
		rIdx		INT IDENTITY(1,1),
		custID		int PRIMARY KEY NONCLUSTERED, 
		amt			money DEFAULT 0, 
		agUser		nvarchar(50), 
		UNIQUE(amt,custID),
		INDEX CIX_AgentrIdx CLUSTERED (rIdx)
	)
					
	---- #1 CHECK UM TRANSFER FUNCTION
	DECLARE @ToTimeConfig DATETIME;
	EXEC DBCUST.CUSTDB.dbo.Acc_Transfer_CheckUM_xtest  
		@CustID = @MasterID
		,@Language = @Language
		,@ErrMsg = @ErrMsg OUTPUT 
		,@ErrCode = @ErrCode OUTPUT
		,@ToTimeConfig = @ToTimeConfig OUTPUT
	 
	IF @ErrCode <> 0  -- Function Transfer is under UM 
	BEGIN
		IF @IsAutoTransfer = 1
		BEGIN
			SET @Result = (SELECT 50024 AS MsgId, 'TransferUM' AS ErrType, @ErrMsg AS ErrMsg,
				@ToTimeConfig AS ToTime FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
			EXEC dbo.Age_ClearBalanceCust_Process_StatusUpd_xtest @FromCustID = @FromCustID, @ToCustIds = @ToCustIDs
				,@Status='Pending', @Result = @Result;
		END
		RETURN		
	END		

	---- #2 CHECK FLAG ISTRANSFERRING = 1 THEN RAISE ERROR
	EXEC DBCUST.CUSTDB.dbo.Acc_Transfer_CheckRunningByCust  
			@CustID = @MasterID
			,@Language = @Language
			,@ErrMsg = @ErrMsg OUTPUT 
			,@ErrCode = @ErrCode OUTPUT
		 
	IF @ErrCode <> 0  -- the auto transfer job is running this custid
	BEGIN
		IF @IsAutoTransfer = 1
		BEGIN
			SET @Result = (SELECT 50026 AS MsgId, 'AccTransfering' AS ErrType, @ErrMsg AS ErrMsg FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
			EXEC dbo.Age_ClearBalanceCust_Process_StatusUpd_xtest @FromCustID = @FromCustID, @ToCustIds = @ToCustIDs
				,@Status='Failed', @Result = @Result;
		END	
		RETURN
	END

	---- #2.1 CHECK Status is Waiting or Running THEN RAISE ERROR
	IF @IsAutoTransfer = 0
	BEGIN
		EXEC bodb02.dbo.Age_ClearBalanceCust_CheckRunning_xtest  
				@CustID = @FromCustID
				,@Language = @Language
				,@ErrMsg = @ErrMsg OUTPUT 
				,@ErrCode = @ErrCode OUTPUT
			 
		IF @ErrCode <> 0  -- the auto transfer job is running for this line
		BEGIN		
			RETURN		
		END	
	END

	----------------------------------------------------------------------
	--Check Transfer Condition
	--1		2		3		4		5		6		7		8
	--isSun	isMon	isTue	isWed	isThurs	isFri	isSat	isWeekly
	--0		1		0		0		1		0		1		1
	EXEC DBCUST.CustDB.dbo.Age_Transfer_CheckTransferOption
		@CustID = @MasterID,
		@ErrMsg = @ErrMsg OUTPUT,
		@ErrCode = @ErrCode OUTPUT,
		@Language = @Language
	
	 IF @ErrCode <> 0
	 BEGIN
		IF @IsAutoTransfer = 1
		BEGIN
			SET @Result = (SELECT 50023 AS MsgId, 'TransferOption' AS ErrType, @ErrMsg AS ErrMsg FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
			EXEC dbo.Age_ClearBalanceCust_Process_StatusUpd_xtest @FromCustID = @FromCustID, @ToCustIds = @ToCustIds
				,@Status='Failed', @Result = @Result;
		END
		RETURN
	 END

	-- get move bet date
	DECLARE @balanceUpDay SMALLDATETIME, @moveBetsDay SMALLDATETIME
	DECLARE @tblMoveBetBalanceUp AS TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)
	DECLARE @IsDiff	SMALLINT = 1, @NewMoveBetDate SMALLDATETIME = NULL,@NewBalanceUpDate SMALLDATETIME = NULL

	INSERT INTO @tblMoveBetBalanceUp(BalanceUpDay,MoveBetsDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay
	
	SELECT @balanceUpDay = BalanceUpDay, @moveBetsDay = MoveBetsDay FROM @tblMoveBetBalanceUp

	DECLARE @WinlostDate datetime
	SELECT  @WinlostDate = convert(varchar(10), CURRENT_TIMESTAMP, 120)
	DECLARE @yesterday SMALLDATETIME
	SELECT  @yesterday = '2023-08-12'
 
	DECLARE @tblCustIds TABLE (CustId INT)

	INSERT INTO @tblCustIds (CustId)
	select convert(int, value) 
	from STRING_SPLIT (@ToCustIDs, ',' ) 

	-- Get bettype --
	DECLARE @isTest BIT = 0
	SELECT  @isTest = dbo.f_CheckSPVersion(@@PROCID)
	
	CREATE TABLE #SportBettype (bettype INT, RefTable TINYINT)
	INSERT INTO #SportBettype (bettype, RefTable)
	SELECT bettype, RefTable FROM dbo.f_SportBettypeMatrix_Sel (0, 0, 0, 2, '', '', @isTest)

	CREATE TABLE #BalanceInfo (CustId INT, Balance MONEY, Outstanding MONEY, TableName VARCHAR(50))

	CREATE TABLE #recommend (CustId INT)
	IF (@CustStatus <> '' OR @CustStatus <> null)
	BEGIN
		INSERT INTO #recommend (CustId)
		SELECT c.custid  
		FROM CustDB.dbo.custInfo c WITH(NOLOCK,index=IX_custinfo)  
		INNER JOIN CustDB.dbo.CustProductStatus cs with(nolock) on c.custid=cs.CustID
		WHERE	mrecommend = @MasterID 
				AND c.roleid = 2   
				AND c.Enabled = case @CustStatus when 'All' then c.Enabled 
						else	case @CustStatus  
								when 'Disabled' then 0   
								else 1 end  
						end
				AND 1 =  case	when @CustStatus = 'Open' and cs.CloseInfo = 0 and cs.SuspendInfo = 0  then 1
									when @CustStatus = 'Suspended' and cs.CloseInfo = 0 and cs.SuspendInfo > 0 then 1
									when @CustStatus = 'Closed'	and cs.CloseInfo > 0  then 1
									when @CustStatus = 'Disabled' then 1
									when @CustStatus = 'All' then 1
									else 0 end
	END
	ELSE
	BEGIN
		INSERT INTO #recommend (CustId)
		SELECT CustId FROM @tblCustIds
	END
  
	 --MASTER IS ALLOWED TO TRANSFER TOTAL BALANCE INCLUDING TODAY BALANCE 
	 IF (SELECT srecommend FROM CustDB.dbo.custinfo (NOLOCK) WHERE custid = @MasterID AND ROLEid = 3 ) IN  (SELECT CONVERT(INT,value) FROM STRING_SPLIT(@SuperIDsTransferTotal, ','))
	BEGIN
		-- bettransRNG
		INSERT INTO #BalanceInfo (CustId, Balance)
		SELECT 
			recommend,
			ISNULL(SUM(awinlost+comm-playercomm), 0)
				+ ISNULL(SUM(winlost-actual_stake+playercomm), 0)
		FROM dbo.bettransRNG b WITH(NOLOCK)
		WHERE EXISTS (SELECT 1 FROM #recommend r WHERE b.recommend = r.CustId)
			AND statusID NOT IN (0,1)
			AND winlostdate >= @yesterday
		GROUP BY recommend

		-- bettransLC
		INSERT INTO #BalanceInfo (CustId, Balance)
		SELECT 
			recommend,
			ISNULL(SUM(awinlost+comm-playercomm), 0)
				+ ISNULL(SUM(winlost-actual_stake+playercomm), 0)
		FROM dbo.bettransLC b WITH(NOLOCK)
		WHERE EXISTS (SELECT 1 FROM #recommend r WHERE b.recommend = r.CustId)
			AND statusID NOT IN (0,1)
			AND winlostdate >= @yesterday
		GROUP BY recommend
	  
		WHILE (@IsDiff = 1)
		BEGIN

			DELETE FROM #BalanceInfo WHERE TableName IN ('tblBettrans','tblTransfer')
		
			-- bettrans
			INSERT INTO #BalanceInfo (CustId, Balance, TableName)
			SELECT 
				recommend,
				ISNULL(SUM(awinlost+comm-playercomm), 0)
					+ ISNULL(SUM(winlost-actual_stake+playercomm), 0),
				'tblBettrans'
			FROM dbo.bettrans b WITH(NOLOCK)
			WHERE EXISTS (SELECT 1 FROM #recommend r WHERE b.recommend = r.CustId)
				AND b.statusID IN (111, 112, 113)
				AND winlostdate > @moveBetsDay
				AND (
						b.winlostdate < @yesterday
						OR NOT EXISTS (SELECT TOP 1 1 FROM #SportBettype s WHERE s.Bettype = b.bettype AND s.RefTable IN (1, 2))
					)
			GROUP BY recommend

			-- Transfer
			INSERT INTO #BalanceInfo (CustId, Balance, TableName)
			SELECT 
				recommend,
				ISNULL(SUM(CASE WHEN custid = recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END), 0)
					+ ISNULL(SUM(CASE WHEN custid <> recommend THEN winlost-actual_stake+playercomm ELSE 0 END), 0),
				'tblTransfer'
			FROM dbo.Transfer b WITH(NOLOCK)
			WHERE EXISTS (SELECT 1 FROM #recommend r WHERE b.recommend = r.CustId)
						AND 1 = CASE WHEN bettype = 19999 AND winlostdate > @moveBetsDay THEN 0 --> new sum
													WHEN bettype = 20000 AND winlostdate > @balanceUpDay THEN 0 --> new bal
													WHEN winlostdate < @balanceUpDay THEN 0 --> old data
												ELSE 1 END
						AND bettype NOT IN (21008, 21009)
			GROUP BY recommend

			----check MB date, BU date again to make sure it is not changed
			SELECT @NewMoveBetDate = NULL, @NewBalanceUpDate = NULL
			EXEC dbo.Acc_ReCheck_MBUDate 
				@MBDate = @moveBetsDay,
				@BUDate = @balanceUpDay,
				@IsDiff = @IsDiff OUTPUT,
				@NewMBDate = @NewMoveBetDate OUTPUT,
				@NewBUDate = @NewBalanceUpDate OUTPUT
			IF @IsDiff = -1 
				BEGIN
					RETURN	
				END
			
			IF @IsDiff = 1 
			BEGIN
				SELECT @moveBetsDay = @NewMoveBetDate, @balanceUpDay = @NewBalanceUpDate
			END
		END
	END
	-- YESTERDAY TRANSFER
	ELSE
	BEGIN
		-- bettransRNG
		INSERT INTO #BalanceInfo (CustId, Balance)
		SELECT 
			recommend,
			ISNULL(SUM(awinlost+comm-playercomm), 0)
				+ ISNULL(SUM(winlost-actual_stake+playercomm), 0)
		FROM dbo.bettransRNG b WITH(NOLOCK)
		WHERE EXISTS (SELECT 1 FROM #recommend r WHERE b.recommend = r.CustId)
			AND statusID NOT IN (0,1)
			AND winlostdate = @yesterday
		GROUP BY recommend

		-- bettransLC
		INSERT INTO #BalanceInfo (CustId, Balance)
		SELECT 
			recommend,
			ISNULL(SUM(awinlost+comm-playercomm), 0)
				+ ISNULL(SUM(winlost-actual_stake+playercomm), 0)
		FROM dbo.bettransLC b WITH(NOLOCK)
		WHERE EXISTS (SELECT 1 FROM #recommend r WHERE b.recommend = r.CustId)
			AND statusID NOT IN (0,1)
			AND winlostdate = @yesterday
		GROUP BY recommend

		WHILE (@IsDiff = 1)
		BEGIN

			DELETE FROM #BalanceInfo WHERE TableName IN ('tblBettrans','tblTransfer')

			-- bettrans
			INSERT INTO #BalanceInfo (CustId, Balance, TableName)
			SELECT 
				recommend,
				ISNULL(SUM(CASE WHEN winlostdate <= @yesterday THEN awinlost+comm-playercomm ELSE 0 END), 0)
					+ ISNULL(SUM(CASE WHEN winlostdate <= @yesterday THEN winlost-actual_stake+playercomm ELSE 0 END), 0),
				'tblBettrans'
			FROM dbo.bettrans b WITH(NOLOCK)
			WHERE EXISTS (SELECT 1 FROM #recommend r WHERE b.recommend = r.CustId)
				AND b.statusID IN (111, 112, 113)
				AND winlostdate > @moveBetsDay
				AND (
						b.winlostdate < @yesterday
						OR NOT EXISTS (SELECT TOP 1 1 FROM #SportBettype s WHERE s.Bettype = b.bettype AND s.RefTable IN (1, 2))
					)
			GROUP BY recommend

				-- Transfer
			INSERT INTO #BalanceInfo (CustId, Balance, TableName)
			SELECT 
				recommend,
				ISNULL(SUM(CASE WHEN custid = recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END ), 0)
					+ ISNULL(SUM(CASE WHEN custid <> recommend THEN winlost-actual_stake+playercomm ELSE 0 END ), 0),
				'tblTransfer'
			FROM dbo.Transfer b WITH(NOLOCK)
			WHERE EXISTS (SELECT 1 FROM #recommend r WHERE b.recommend = r.CustId)
						AND 1 = CASE WHEN bettype = 19999 AND winlostdate > @moveBetsDay THEN 0 --> new sum
													WHEN bettype = 20000 AND winlostdate > @balanceUpDay THEN 0 --> new bal
													WHEN winlostdate < @balanceUpDay THEN 0 --> old data
												ELSE 1 END
						AND bettype NOT IN (21008, 21009)
			GROUP BY recommend

			----check MB date, BU date again to make sure it is not changed
			SELECT @NewMoveBetDate = NULL, @NewBalanceUpDate = NULL
			EXEC dbo.Acc_ReCheck_MBUDate 
				@MBDate = @moveBetsDay,
				@BUDate = @balanceUpDay,
				@IsDiff = @IsDiff OUTPUT,
				@NewMBDate = @NewMoveBetDate OUTPUT,
				@NewBUDate = @NewBalanceUpDate OUTPUT
			IF @IsDiff = -1 
				BEGIN
					RETURN	
				END
			
			IF @IsDiff = 1 
			BEGIN
				SELECT @moveBetsDay = @NewMoveBetDate, @balanceUpDay = @NewBalanceUpDate
			END
		END
	END

	-- Sum amount
	INSERT INTO #Agent (CustID, Amt, AgUser)
	SELECT r.CustId, SUM(ISNULL(bal.Balance,0)), ''
	FROM #recommend r
	LEFT JOIN #BalanceInfo bal ON bal.CustId = r.CustId
	GROUP BY r.CustId

	IF NOT EXISTS (SELECT 1 FROM #Agent WHERE amt <> 0)
	BEGIN
		Select @ErrMsg = case @Language   
			when 'E' then 'Cannot transfer because all downlines'' balance is 0!' 
			ELSE CustDB.dbo.f_Get_MsgNamebyMsgID_xtest(50002,@Language)
		end, @ErrCode = 103     
		
		IF @IsAutoTransfer = 1
		BEGIN
			SET @Result = (SELECT 50025 AS MsgId, 'BalanceZero' AS ErrType, @ErrMsg AS ErrMsg FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
			EXEC dbo.Age_ClearBalanceCust_Process_StatusUpd_xtest @FromCustID = @FromCustID, @ToCustIds = @ToCustIDs
				,@Status='Ignored', @Result = @Result;
		END
		RETURN	
	END
 
	 UPDATE #Agent SET agUser = ci.username 
	 FROM #Agent 
		INNER JOIN CustDB.dbo.custinfo ci with (NOLOCK) ON ci.custid = #Agent.custid 

	 DECLARE @currency int , @actualrate float, @currName nvarchar(10), @RefNo bigint, @amount money, @grefno BIGINT, @TransID BIGINT
	 DECLARE @srecommend int, @AgentID int , @MAUser nvarchar(50), @AgUser nvarchar(50)
	 DECLARE @LogData nvarchar(200), @SubAccName varchar(30)
 
	 --- 20150606@Kathy: Migrate custDB to new server DBCust(Get credit from DBCust.CustDB) [Redmine:#36216]
	 SELECT @SubAccName = username 
		FROM DBCUST.CustDB.dbo.custSub WITH(NOLOCK) 
		WHERE SubAccID = @SubAccID

	 SELECT @currency = ci.currency, @currName =e.currency, @maUser = ci.username, 
			@actualrate = e.actualrate, @srecommend = srecommend  
	 FROM CustDB.dbo.custinfo ci with (nolock) 
		INNER JOIN CustDB.dbo.Exchange e with (NOLOCK) ON ci.currency = e.exchangeid 
	 WHERE ci.custid = @masterid AND ci.roleid = 3

	 DECLARE @procName VARCHAR(100)
	 SELECT  @procName = OBJECT_NAME(@@PROCID)

	 SET @rCount = 1;
	 WHILE EXISTS (SELECT 1 FROM #Agent WHERE rIdx = @rCount)
	 BEGIN
		-- Reset error for each pair
		SELECT @ErrCode = 0,
			@ErrMsg = '';
		
		SELECT @AgentID = CustId, @Amount = Amt, @AgUser = agUser
		FROM #Agent 
		WHERE rIdx = @rCount;

		-- SET username
		UPDATE @tblResultMember
		SET UserName = @AgUser
		WHERE CustId = @AgentID;	

		IF (@Amount = 0)
		BEGIN
			UPDATE @tblResultMember
			SET MsgId = 50025, ErrType = 'BalanceZero', ErrMsg = 'Cannot transfer because balance is 0!'
			WHERE CustId = @AgentID;	
			GOTO NEXT_PAIR;
		END
	
		--AutoJob Transfer: START a Pair waiting to Processing
		IF @IsAutoTransfer = 1
		BEGIN
			EXEC dbo.Age_ClearBalanceCust_Process_StatusUpd_xtest @FromCustID = @FromCustID, @ToCustIds = @AgentID
				,@Status='Processing', @Amount=@Amount
				,@ErrCode = @ErrCode OUTPUT
				,@ErrMsg = @ErrMsg OUTPUT
			;
			-- CHECK: Cancelling
			IF @ErrCode > 0
			BEGIN
				UPDATE @tblResultMember
				SET MsgId = @ErrCode, ErrType = 'TransferStatus', ErrMsg = @ErrMsg
				WHERE CustId = @AgentID;	
				GOTO NEXT_PAIR;
			END
		END

		BEGIN TRY
	
			--CHECK FOR TRANSFER AMOUNT @Phuong20080916
			DECLARE @custBalance money 
			SELECT @custBalance = @Amount 

			if @FullTransfer = 0
			BEGIN
				IF @AmtTrans = 0
					OR (@CustBalance >= 0 AND (@AmtTrans <= 0 or @AmtTrans > @CustBalance))
					OR (@CustBalance < 0 AND (@AmtTrans >= 0 or @AmtTrans < @CustBalance))
					BEGIN
						SELECT @ErrMsg = CASE @Language 
										WHEN 'E' THEN 'Amount to transfer must be between 0 and' + ' ' + convert(VARCHAR(100), -@CustBalance, 2) +'.'
										ELSE CustDB.dbo.f_Get_MsgNamebyMsgID_xtest(50005,@Language) + ' ' + convert(VARCHAR(100), -@CustBalance, 2) + '.'
											end		
						select @ErrCode = 104
					
						UPDATE @tblResultMember
						SET MsgId = 50005, ErrType = 'FullTransfer', ErrMsg = @ErrMsg
						WHERE CustId = @AgentID;	
						GOTO NEXT_PAIR;
					END	
				-- INSERT AMOUNT INPUTED INTO BETTRANS 
				SET @amount = @AmtTrans	
			END 	

			SELECT @ErrMsg = CASE @Language 
								WHEN 'E' THEN 'Clear balance failed. Please try again.'
								ELSE CustDB.dbo.f_Get_MsgNamebyMsgID_xtest(50003,@Language)
						END
			------------------Gen refno--------------------------------------------------------------- 
			EXEC Get_Refno_Transid @RefNo = @RefNo OUTPUT

			-- TODO: AutoTransfer - Check cancelled
			IF @IsAutoTransfer = 1
			BEGIN
				EXEC dbo.Age_ClearBalanceCust_Process_StatusUpd_xtest @FromCustID = @FromCustID, @ToCustIds = @AgentID
					,@Status='Processing'
					,@ErrCode = @ErrCode OUTPUT
					,@ErrMsg = @ErrMsg OUTPUT
				;
				-- CHECK: Cancelling
				IF @ErrCode > 0
				BEGIN
					UPDATE @tblResultMember
					SET MsgId = @ErrCode, ErrType = 'TransferStatus', ErrMsg = @ErrMsg
					WHERE CustId = @AgentID;	
					GOTO NEXT_PAIR;
				END
			END

			------------------Insert trans into DB---------------------------------------------------------------
			IF @amount > 0
			BEGIN
				EXEC Get_Bettrans_TransID @TransID = @TransID OUTPUT
				INSERT INTO Transfer 
					(transid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
					winlostdate, currency, actualrate, currencyName, recommend, mrecommend, srecommend, 
					scomm, swinlost,ip,statusID, RepUpdateTime)
				VALUES 
					(@TransID ,@creator, @masterid, @maUser, @RefNo, current_timestamp, 21003, 'From Customer ::: ' + @agUser + CASE WHEN @SubAccID > 0 THEN ' (By ' + @SubAccName + ')' ELSE '' END, 
					@amount, 0, @WinlostDate, @currency, @actualrate, @currName, 0, @masterid, @srecommend, 
					0, 0,@ip,131,SYSDATETIME())
				IF @@Error <> 0
				BEGIN								
					SELECT @ErrCode = 102
					--Manually rollback
					UPDATE dbo.Transfer WITH(ROWLOCK)
					SET	 custid = 0, Winlost = 0, Actual_Stake = 0, RepUpdateTime = SYSDATETIME(), Recommend = 0, MRecommend = 0, SRecommend = 0	
					WHERE refno = @RefNo
				
					--AutoJob Transfer
					UPDATE @tblResultMember
					SET MsgId = 50027, ErrType = 'DBIssue', ErrMsg = ERROR_MESSAGE()
					WHERE CustID = @AgentID;

					GOTO NEXT_PAIR;
				END

				DECLARE @TotalCashAgent MONEY 
				EXEC Acc_CustomerSelCash_CaptureBalance @custid = @agentid, @TotalCash  = @TotalCashAgent OUTPUT

				EXEC Get_Bettrans_TransID @TransID = @TransID OUTPUT
				INSERT INTO Transfer
					(transid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
					winlostdate, currency, actualrate, currencyName, recommend, mrecommend, srecommend, scomm, swinlost,ip,statusID, balance, RepUpdateTime)
				VALUES 
					(@TransID, @creator, @agentid, @agUser, @RefNo, current_timestamp, 21003, 'To Customer ::: ' + @maUser + CASE WHEN @SubAccID > 0 THEN ' (By ' + @SubAccName + ')' ELSE '' END, 
					0, @amount, @WinlostDate, @currency, @actualrate,@currName, @agentid, @masterid, @srecommend, 
					0, 0,@ip,131, @TotalCashAgent,SYSDATETIME())
				IF @@Error <> 0
				BEGIN						
					SELECT @ErrCode = 103
					--Manually rollback
					UPDATE dbo.Transfer WITH(ROWLOCK)
					SET	 custid = 0, Winlost = 0, Actual_Stake = 0, RepUpdateTime = SYSDATETIME(), Recommend = 0, MRecommend = 0, SRecommend = 0	
					WHERE refno = @RefNo
				
					--AutoJob Transfer
					UPDATE @tblResultMember
					SET MsgId = 50027, ErrType = 'DBIssue', ErrMsg = ERROR_MESSAGE()
					WHERE CustID = @AgentID;

					GOTO NEXT_PAIR;
				END

				--Add writelog for each amt transfered - Vinh 20080629
				SELECT @LogData = 'Transfer from Agent ' + @agUser + ' to Master ' + @maUser + ' with amount ' + CONVERT(VARCHAR(20), @amount) + ' Ref.No ' + CONVERT(VARCHAR(20), @RefNo)
			
				--AutoJob Transfer: Completed
				UPDATE @tblResultMember
				SET RefNo = @RefNo
				WHERE CustID = @AgentID;

			END
			ELSE IF @amount<0
			BEGIN
				--SET @amount = abs(@amount)
				EXEC Get_Bettrans_TransID @TransID = @TransID OUTPUT
				INSERT INTO Transfer 
					(transid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
					winlostdate, currency, actualrate, currencyName, recommend, mrecommend, srecommend, 
					scomm, swinlost,ip,statusID, RepUpdateTime)
				VALUES 
					(@TransID, @creator, @masterid, @maUser, @RefNo, current_timestamp, 21003, 'To Customer ::: ' + @agUser + CASE WHEN @SubAccID > 0 THEN ' (By ' + @SubAccName + ')' ELSE '' END, 
					0, abs(@amount),  @WinlostDate, @currency, @actualrate, @currName, 0, @masterid, @srecommend, 
					0, 0,@ip,131,SYSDATETIME())
				if @@Error <> 0
				BEGIN						
					select @ErrCode = 107
					--Manually rollback
					UPDATE dbo.Transfer WITH(ROWLOCK)
					SET	 custid = 0, Winlost = 0, Actual_Stake = 0, RepUpdateTime = SYSDATETIME(), Recommend = 0, MRecommend = 0, SRecommend = 0	
					WHERE refno = @RefNo
				
					--AutoJob Transfer
					UPDATE @tblResultMember
					SET MsgId = 50027, ErrType = 'DBIssue', ErrMsg = ERROR_MESSAGE()
					WHERE CustID = @AgentID;

					GOTO NEXT_PAIR;
				END

				DECLARE @TotalCashAgentNev MONEY 
				EXEC Acc_CustomerSelCash_CaptureBalance @custid = @agentid, @TotalCash  = @TotalCashAgentNev OUTPUT

				EXEC Get_Bettrans_TransID @TransID = @TransID OUTPUT
				INSERT INTO Transfer
					(transid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
					winlostdate, currency,actualrate, currencyName, recommend, mrecommend, srecommend, 
					scomm, swinlost,ip,statusID, balance, RepUpdateTime)
				VALUES 
					(@TransID, @creator, @agentid, @agUser, @RefNo, current_timestamp, 21003, 'From Customer ::: ' + @maUser + CASE WHEN @SubAccID > 0 THEN ' (By ' + @SubAccName + ')' ELSE '' END, 
					abs(@amount), 0,@WinlostDate, @currency, @actualrate, @currName, @agentid, @masterid, @srecommend, 
					0, 0,@ip,131, @TotalCashAgentNev,SYSDATETIME())
				IF @@Error <> 0
				BEGIN
					SELECT @ErrCode = 104
					--Manually rollback
					UPDATE dbo.Transfer WITH(ROWLOCK)
					SET	 custid = 0, Winlost = 0, Actual_Stake = 0, RepUpdateTime = SYSDATETIME(), Recommend = 0, MRecommend = 0, SRecommend = 0	
					WHERE refno = @RefNo
				
					--AutoJob Transfer
					UPDATE @tblResultMember
					SET MsgId = 50027, ErrType = 'DBIssue', ErrMsg = ERROR_MESSAGE()
					WHERE CustID = @AgentID;

					GOTO NEXT_PAIR;
				END
			
				--Add writelog for each amt transfered - Vinh 20080629
				SELECT @LogData = 'Transfer from Master ' + @maUser + ' to Agent ' + @agUser + ' with amount ' + CONVERT(VARCHAR(20), @amount) + ' Ref.No ' + CONVERT(VARCHAR(20), @RefNo)
			
				--AutoJob Transfer: Completed
				UPDATE @tblResultMember
				SET RefNo = @RefNo
				WHERE CustID = @AgentID;
			END
			---------------------------------------------------------------------------------------------------
			SELECT @ErrMsg	= '',
				@ErrCode	= 0
	
			if @SubAccID > 0
			begin
				SET @LogData = 'SubAccount:' +  coalesce(cast(@SubAccName as varchar(30)),space(1)) + ' - ' + @LogData
			end

			SELECT @LogData = @LogData + ' SPName: ' + @procName

			BEGIN TRY			
				EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer 
										@UserID			= @creator, 
										@FromCustID		= @MasterID, 
										@ToCustID		= @AgentID, 
										@IP				= @IP, 
										@Doing			= @LogData
			END TRY
			BEGIN CATCH
				SELECT @LogData = @LogData + ' ErrMsg: ' + ERROR_MESSAGE()
	
				EXEC bodb_customerlog.dbo.WriteLog_UserLog_Transfer 
										@UserID			= @creator, 
										@FromCustID		= @MasterID, 
										@ToCustID		= @AgentID, 
										@IP				= @IP, 
										@Doing			= @LogData	
			END CATCH
		END TRY
		BEGIN CATCH
			--Exception
			UPDATE @tblResultMember
			SET MsgId = 50027, ErrType = 'DBIssue', ErrMsg = ERROR_MESSAGE()
			WHERE CustID = @AgentID;
		END CATCH

		NEXT_PAIR:
		IF @IsAutoTransfer = 1
		BEGIN
			SELECT @Result = (SELECT MsgId, ErrType, ErrMsg, RefNo FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
				@PairStatus = CASE WHEN RefNo > 0 THEN 'Completed' ELSE 
					CASE WHEN ErrType = 'BalanceZero' THEN 'Ignored' ELSE 'Failed' END 
				END
			FROM @tblResultMember 
			WHERE CustId=@AgentID
			;
			EXEC dbo.Age_ClearBalanceCust_Process_StatusUpd_xtest @FromCustID = @FromCustID, @ToCustIds = @AgentID
				,@Status=@PairStatus, @Result = @Result;
		END
		ELSE 
		BEGIN
			--TODO: Check FAILED break for MANUAL transfer
			IF @ErrCode > 0
				RETURN;
		END
		SET @rCount += 1;
	END
	DROP TABLE #Agent 
	DROP TABLE #SportBettype
	DROP TABLE #BalanceInfo
	DROP TABLE #recommend
END
GO


ALTER PROCEDURE  [dbo].[Age_Transfer_Ins_SAg_xtest]
	@SAgID int,
	@SuperIDsTransferTotal VARCHAR(50)='', 
	@ToCustIDs varchar(4000),
	@creator int,
	@FullTransfer bit = 1,
	@AmtTrans float = 0,
	@Language varchar(2)= 'E',
	@SubAccID int = 0, --Sub-AccountID
	@IP varchar(45)='',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT,	
	@CustStatus varchar(50)='',
	@IsAutoTransfer BIT = 0

AS
--AGENT SITE
--Multiple Transfer
/*
Created: 
Task: Transfer
DB: DBTXN/bodb02
Original: Age_Transfer_In

Revisions:
	- 20090318@Phuc: Korean language.
	- 20090416@PhuongDao: Allow some SuperIDs to transfer all balance including balance of today
	- 20090729@Phuc: Write log subaccname instead of subaccid.
	- 20090818@Phuc: check page access and check upline closed first(call Age_CustSubCheckPageAccess)
	- 20091003@Kiwi: Modify Write log function
	- 20091125@Kiwi: Remove comstatus because it's no used.
	- 20100424@Henry: insert data to column StatusID of Bettrans (StatusID = 131 for bettype 103)
	- 20100611@Henry: Write exact amount to log when transferring
	- 20101224@Johnson: Apply new arrange of bettype
	- 20120104@Lukas: modify to filter by 'enabled' status
	- 20120202@Jamie:Change transfer time to 12pm to 11:59pm instead of 12pm to 10pm ( 9h59pm)
	- 20121106@Viet: amend sp to reduce load for DBTRANS.
	- 20121128@Elodie: Get an error message from f_Get_MsgNameByMsgID function by language
	- 20130201@Johnson: write log into DBTXN if failure DBLOG server
	- 20131108@Elodie: Splitting bodb02 into CustDB (Call CustInfo, Exchange by link database)
	- 20150606@Kathy: Migrate custDB to new server DBCust [Redmine:#36216]
	- 20160127@Kathy: get balance from bettransRNG & bettransLC [Redmine:#50674]
	- 20160815@Patrick: Allow SMA to transfer in 24 hours [Redmine:#61626]
	- 20170609@Percy:
		1. Re-check [Allow SMA to transfer in 24 hours]: apply general sp Acc_CheckProcessingData [RedmineID: #78487]
		2. Change way to calculate balance [RedmineID: #74291]
	- 20170831@Percy: Add SP Name into log [RedmineID: #80978]
	- 20200602@Percy: Separate PendingTransfer3rd from Cash and Balance [RedmineID: #135200]
	- 20200821@Sophia: prevent duplicated transfer [Redmine: #137141]
	- 20200821@Sophia: Check UM Transfer Function [Redmine: #136992]
	- 20201005@Danny: Convert Ipv6 to dummy IPv4 [Redmine: #142511]
	- 20201015@Malcolm : Add sub account information when transfering [RedmineId : #143478]
	- 20201228@Danny: Capture total cash before transfering  [Redmine: #146038]
	- 20210603@Sol: Alpha - All Sites - Lock account & indirect close account - [RedmineID: #148600]
	- 20210723@Evan: Transfer all pages work incorrect with disabled account [RedmineID: #158813]
	- 20210505@Sol: NAP - Alpha - Allow more time for transfer - [Redmine: #149927]
	- 20210817@Sophia: Fix overflow Refno [Redmine: #160262]
	- 20211111@Evan: Split transfer tickets out of bettrans - [Redmine: #164196]
	- 20220315@Evan: SQL Server Upgrade STRING_SPLIT [Redmine: #168783]
	- 20220721@Danny: get transid and refno with new generation [Redmine: #175670]
	- 20230227@Evan: Balance-Up support transfer 247 [Redmine: #173554] 
	- 20230523@Danny: support scale out credit [Redmine: #181595]
	- 20230227@Bobby: Auto Clear Balance/ Multiple Transfer	 [RedmineID: #182071]
	
Param's Explanation:
	• @AmtTrans: amount of money
	• @SAgID: from master
	• @ToCustIDs: list custid
	  @SuperIDsTransferTotal: Super IDs can transfer total balance including today balance 

*/
BEGIN

	SET NOCOUNT ON;

	DECLARE @rCount INT, @FromCustID INT, @PairStatus VARCHAR(15), @Result nvarchar(4000);
	-- TODO: support auto clear balance
	DECLARE @tblResultMember TABLE(CustId INT PRIMARY KEY, UserName VARCHAR(50), MsgId INT, ErrType VARCHAR(50), ErrMsg NVARCHAR(4000), RefNo BIGINT);
	INSERT INTO @tblResultMember(CustId)
	SELECT DISTINCT t.value
	FROM STRING_SPLIT(@ToCustIDs, ',') AS t;

	SELECT @FromCustID = @SAgID;

	---------------------------
	--declare @ErrMsg varchar(200)
	 CREATE TABLE #Master (		
		rIdx	INT IDENTITY(1,1),
		custID	int PRIMARY KEY NONCLUSTERED, 
		Amt		money DEFAULT 0, 
		MAgUser nvarchar(50), 
		UNIQUE(Amt,custid),
		INDEX CIX_MasterrIdx CLUSTERED (rIdx)
	)
					 

	---- #1 CHECK UM TRANSFER FUNCTION
	DECLARE @ToTimeConfig DATETIME;
	EXEC DBCUST.CUSTDB.dbo.Acc_Transfer_CheckUM_xtest  
		@CustID = @SAgID
		,@Language = @Language
		,@ErrMsg = @ErrMsg OUTPUT 
		,@ErrCode = @ErrCode OUTPUT
		,@ToTimeConfig = @ToTimeConfig OUTPUT
	 
	IF @ErrCode <> 0  -- Function Transfer is under UM 
	BEGIN
		IF @IsAutoTransfer = 1
		BEGIN
			SET @Result = (SELECT 50024 AS MsgId, 'TransferUM' AS ErrType, @ErrMsg AS ErrMsg,
				@ToTimeConfig AS ToTime FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
			EXEC dbo.Age_ClearBalanceCust_Process_StatusUpd_xtest @FromCustID = @FromCustID, @ToCustIds = @ToCustIDs
				,@Status='Pending', @Result = @Result;
		END
		RETURN		
	END		

	---- #2 CHECK FLAG ISTRANSFERRING = 1 THEN RAISE ERROR
	EXEC DBCUST.CUSTDB.dbo.Acc_Transfer_CheckRunningByCust  
			@CustID = @SAgID
			,@Language = @Language
			,@ErrMsg = @ErrMsg OUTPUT 
			,@ErrCode = @ErrCode OUTPUT
		 
	IF @ErrCode <> 0  -- the auto transfer job is running this custid
	BEGIN		
		IF @IsAutoTransfer = 1
		BEGIN
			SET @Result = (SELECT 50026 AS MsgId, 'AccTransfering' AS ErrType, @ErrMsg AS ErrMsg FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
			EXEC dbo.Age_ClearBalanceCust_Process_StatusUpd_xtest @FromCustID = @FromCustID, @ToCustIds = @ToCustIDs
				,@Status='Failed', @Result = @Result;
		END	
		RETURN		
	END

	---- #2.1 CHECK Status is Waiting or Running THEN RAISE ERROR
	IF @IsAutoTransfer = 0
	BEGIN
		EXEC bodb02.dbo.Age_ClearBalanceCust_CheckRunning_xtest  
				@CustID = @FromCustID
				,@Language = @Language
				,@ErrMsg = @ErrMsg OUTPUT 
				,@ErrCode = @ErrCode OUTPUT
			 
		IF @ErrCode <> 0  -- the auto transfer job is running for this line
		BEGIN		
			RETURN		
		END	
	END

	-- get move bet date
	DECLARE @balanceUpDay SMALLDATETIME, @moveBetsDay SMALLDATETIME
	DECLARE @tblMoveBetBalanceUp AS TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)
	DECLARE @IsDiff	SMALLINT = 1, @NewMoveBetDate SMALLDATETIME = NULL,@NewBalanceUpDate SMALLDATETIME = NULL

	INSERT INTO @tblMoveBetBalanceUp(BalanceUpDay,MoveBetsDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay
	
	SELECT @balanceUpDay = BalanceUpDay, @moveBetsDay = MoveBetsDay FROM @tblMoveBetBalanceUp

	DECLARE @WinlostDate datetime
	SELECT  @WinlostDate = convert(varchar(10), CURRENT_TIMESTAMP, 120)

	DECLARE @yesterday SMALLDATETIME
	SELECT  @yesterday = '2023-08-12'

	DECLARE @tblCustIds TABLE (CustId INT)

	INSERT INTO @tblCustIds (CustId)
	SELECT CONVERT(INT, value) FROM STRING_SPLIT (@ToCustIDs, ',')

	-- Get bettype --
	DECLARE @isTest BIT = 0
	SELECT  @isTest = dbo.f_CheckSPVersion(@@PROCID)
	
	CREATE TABLE #SportBettype (bettype INT, RefTable TINYINT)
	INSERT INTO #SportBettype (bettype, RefTable)
	SELECT bettype, RefTable FROM dbo.f_SportBettypeMatrix_Sel (0, 0, 0, 2, '', '', @isTest)

	CREATE TABLE #BalanceInfo (CustId INT, Balance MONEY, Outstanding MONEY, TableName VARCHAR(50))

	CREATE TABLE #mrecommend (CustId INT)
	CREATE TABLE #recommend (CustId INT)

	IF (@CustStatus <> '' OR @CustStatus <> null)
	BEGIN
		INSERT INTO #mrecommend (CustId)
		SELECT c.custid  
		FROM CustDB.dbo.custInfo c WITH(NOLOCK)  
		INNER JOIN CustDB.dbo.CustProductStatus cs with(nolock) on c.custid=cs.CustID
		WHERE	srecommend = @SAgID 
				AND c.roleid = 3  
				AND c.Enabled = case @CustStatus when 'All' then c.Enabled 
						else	case @CustStatus  
								when 'Disabled' then 0   
								else 1 end  
						end
				AND 1 =  case	when @CustStatus = 'Open' and cs.CloseInfo = 0 and cs.SuspendInfo = 0  then 1
									when @CustStatus = 'Suspended' and cs.CloseInfo = 0 and cs.SuspendInfo > 0 then 1
									when @CustStatus = 'Closed'	and cs.CloseInfo > 0  then 1
									when @CustStatus = 'Disabled' then 1
									when @CustStatus = 'All' then 1
									else 0 end
	END
	ELSE
	BEGIN
		INSERT INTO #mrecommend (CustId)
		SELECT CustId FROM @tblCustIds
	END

	INSERT INTO #recommend (CustId)
	SELECT custid
	FROM CustDB.dbo.custInfo c WITH(NOLOCK)
	WHERE c.roleid = 2
		AND EXISTS (SELECT 1 FROM #mrecommend m WHERE c.mrecommend = m.CustId)

	 --Allow some IDs to transfer total balance including the balance of today
	 IF @SAgID IN (SELECT CONVERT(INT, value) from STRING_SPLIT(@SuperIDsTransferTotal, ','))
	 BEGIN 
		-- bettransRNG
		INSERT INTO #BalanceInfo (CustId, Balance)
		SELECT 
			mrecommend,
			ISNULL(SUM(mwinlost+acomm-comm), 0)
				+ ISNULL(SUM(awinlost+comm-playercomm), 0)
				+ ISNULL(SUM(winlost-actual_stake+playercomm), 0)
		FROM dbo.bettransRNG b WITH(NOLOCK)
		WHERE EXISTS (SELECT 1 FROM #recommend r WHERE b.recommend = r.CustId)
			AND statusID NOT IN (0,1)
			AND winlostdate >= @yesterday
		GROUP BY mrecommend

		-- bettransLC
		INSERT INTO #BalanceInfo (CustId, Balance)
		SELECT 
			mrecommend,
			ISNULL(SUM(mwinlost+acomm-comm), 0)
				+ ISNULL(SUM(awinlost+comm-playercomm), 0)
				+ ISNULL(SUM(winlost-actual_stake+playercomm), 0)
		FROM dbo.bettransLC b WITH(NOLOCK)
		WHERE EXISTS (SELECT 1 FROM #recommend r WHERE b.recommend = r.CustId)
			AND statusID NOT IN (0,1)
			AND winlostdate >= @yesterday
		GROUP BY mrecommend

		WHILE (@IsDiff = 1)
		BEGIN

			DELETE FROM #BalanceInfo WHERE TableName IN ('tblBettrans','tblTransfer')

			-- bettrans
			INSERT INTO #BalanceInfo (CustId, Balance, TableName)
			SELECT 
				mrecommend,
				ISNULL(SUM(mwinlost+acomm-comm), 0)
					+ ISNULL(SUM(awinlost+comm-playercomm), 0)
					+ ISNULL(SUM(winlost-actual_stake+playercomm), 0),
				'tblBettrans'
			FROM dbo.bettrans b WITH(NOLOCK)
			WHERE EXISTS (SELECT 1 FROM #recommend r WHERE b.recommend = r.CustId)
				AND b.statusID IN (111, 112, 113)
				AND winlostdate > @moveBetsDay
				AND (
						b.winlostdate < @yesterday
						OR NOT EXISTS (SELECT TOP 1 1 FROM #SportBettype s WHERE s.Bettype = b.bettype AND s.RefTable IN (1, 2))
					)
			GROUP BY mrecommend

			-- Transfer
			INSERT INTO #BalanceInfo (CustId, Balance, TableName)
			SELECT 
				mrecommend,
				ISNULL(SUM(mwinlost+acomm-comm), 0)
					+ ISNULL(SUM(CASE WHEN custid = recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END), 0)
					+ ISNULL(SUM(CASE WHEN custid <> recommend THEN winlost-actual_stake+playercomm ELSE 0 END), 0),
				'tblTransfer'
			FROM dbo.Transfer b WITH(NOLOCK)
			WHERE EXISTS (SELECT 1 FROM #recommend r WHERE b.recommend = r.CustId)
						AND 1 = CASE WHEN bettype = 19999 AND winlostdate > @moveBetsDay THEN 0 --> new sum
												WHEN bettype = 20000 AND winlostdate > @balanceUpDay THEN 0 --> new bal
												WHEN winlostdate < @balanceUpDay THEN 0 --> old data
										ELSE 1 END
						AND bettype NOT IN (21008, 21009)
			GROUP BY mrecommend
			
			INSERT INTO #BalanceInfo (CustId, Balance, TableName)
			SELECT 
				mrecommend,
				ISNULL(SUM(winlost-actual_stake), 0),
				'tblTransfer'
			FROM dbo.Transfer b WITH(NOLOCK)
			WHERE EXISTS (SELECT 1 FROM #mrecommend m WHERE b.custid = m.CustId)
						AND 1 = CASE WHEN bettype = 20000 AND winlostdate > @balanceUpDay THEN 0 --> new bal
													WHEN winlostdate < @balanceUpDay THEN 0 --> old data
											ELSE 1 END
						AND bettype NOT IN (21008, 21009)
			GROUP BY mrecommend


			----check MB date, BU date again to make sure it is not changed
			SELECT @NewMoveBetDate = NULL, @NewBalanceUpDate = NULL
			EXEC dbo.Acc_ReCheck_MBUDate 
				@MBDate = @moveBetsDay,
				@BUDate = @balanceUpDay,
				@IsDiff = @IsDiff OUTPUT,
				@NewMBDate = @NewMoveBetDate OUTPUT,
				@NewBUDate = @NewBalanceUpDate OUTPUT

			IF @IsDiff = -1 
				BEGIN
					RETURN	
				END
			
			IF @IsDiff = 1 
			BEGIN
				SELECT @moveBetsDay = @NewMoveBetDate, @balanceUpDay = @NewBalanceUpDate
			END
		END

	 END
	 -- YESTERDAY TRANSFER 
	 ELSE 
	 BEGIN 
 		 -- bettransRNG
		INSERT INTO #BalanceInfo (CustId, Balance)
		SELECT 
			mrecommend,
			ISNULL(SUM(mwinlost+acomm-comm), 0)
				+ ISNULL(SUM(awinlost+comm-playercomm), 0)
				+ ISNULL(SUM(winlost-actual_stake+playercomm), 0)
		FROM dbo.bettransRNG b WITH(NOLOCK)
		WHERE EXISTS (SELECT 1 FROM #recommend r WHERE b.recommend = r.CustId)
			AND statusID NOT IN (0,1)
			AND winlostdate = @yesterday
		GROUP BY mrecommend

		-- bettransLC
		INSERT INTO #BalanceInfo (CustId, Balance)
		SELECT 
			mrecommend,
			ISNULL(SUM(mwinlost+acomm-comm), 0)
				+ ISNULL(SUM(awinlost+comm-playercomm), 0)
				+ ISNULL(SUM(winlost-actual_stake+playercomm), 0)
		FROM dbo.bettransLC b WITH(NOLOCK)
		WHERE EXISTS (SELECT 1 FROM #recommend r WHERE b.recommend = r.CustId)
			AND statusID NOT IN (0,1)
			AND winlostdate = @yesterday
		GROUP BY mrecommend

		WHILE (@IsDiff = 1)
		BEGIN

			DELETE FROM #BalanceInfo WHERE TableName IN ('tblBettrans','tblTransfer')
		
			-- bettrans
			INSERT INTO #BalanceInfo (CustId, Balance, TableName)
			SELECT 
				mrecommend,
				ISNULL(SUM(CASE WHEN winlostdate <= @yesterday THEN mwinlost+acomm-comm ELSE 0 END), 0)
					+ ISNULL(SUM(CASE WHEN winlostdate <= @yesterday THEN awinlost+comm-playercomm ELSE 0 END), 0)
					+ ISNULL(SUM(CASE WHEN winlostdate <= @yesterday THEN winlost-actual_stake+playercomm ELSE 0 END), 0),
				'tblBettrans'
			FROM dbo.bettrans b WITH(NOLOCK)
			WHERE EXISTS (SELECT 1 FROM #recommend r WHERE b.recommend = r.CustId)
				AND b.statusID IN (111, 112, 113)
				AND winlostdate > @moveBetsDay
				AND (
						b.winlostdate < @yesterday
						OR NOT EXISTS (SELECT TOP 1 1 FROM #SportBettype s WHERE s.Bettype = b.bettype AND s.RefTable IN (1, 2))
					)
			GROUP BY mrecommend

			-- Transfer
			INSERT INTO #BalanceInfo (CustId, Balance, TableName)
			SELECT 
				mrecommend,
				ISNULL(SUM(CASE WHEN winlostdate <= @yesterday THEN mwinlost+acomm-comm ELSE 0 END), 0)
					+ ISNULL(SUM(CASE WHEN custid = recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END ), 0)
					+ ISNULL(SUM(CASE WHEN custid <> recommend THEN winlost-actual_stake+playercomm ELSE 0 END ), 0),
				'tblTransfer'
			FROM dbo.Transfer b WITH(NOLOCK)
			WHERE EXISTS (SELECT 1 FROM #recommend r WHERE b.recommend = r.CustId)
						AND 1 = CASE WHEN bettype = 19999 AND winlostdate > @moveBetsDay THEN 0 --> new sum
											WHEN bettype = 20000 AND winlostdate > @balanceUpDay THEN 0 --> new bal
											WHEN winlostdate < @balanceUpDay THEN 0 --> old data
									ELSE 1 END
						AND bettype NOT IN (21008, 21009)
			GROUP BY mrecommend

			INSERT INTO #BalanceInfo (CustId, Balance, TableName)
			SELECT 
				mrecommend,
				ISNULL(SUM(winlost-actual_stake), 0),
				'tblTransfer'
			FROM dbo.Transfer b WITH(NOLOCK)
			WHERE EXISTS (SELECT 1 FROM #mrecommend m WHERE b.custid = m.CustId)
				AND bettype NOT IN (21008, 21009)
				AND 1 = CASE WHEN bettype = 19999 AND winlostdate > @moveBetsDay THEN 0 --> new sum
							WHEN bettype = 20000 AND winlostdate > @balanceUpDay THEN 0 --> new bal
							WHEN winlostdate < @balanceUpDay THEN 0 --> old data
					ELSE 1 END
			GROUP BY mrecommend


			----check MB date, BU date again to make sure it is not changed
			SELECT @NewMoveBetDate = NULL, @NewBalanceUpDate = NULL
			EXEC dbo.Acc_ReCheck_MBUDate 
				@MBDate = @moveBetsDay,
				@BUDate = @balanceUpDay,
				@IsDiff = @IsDiff OUTPUT,
				@NewMBDate = @NewMoveBetDate OUTPUT,
				@NewBUDate = @NewBalanceUpDate OUTPUT

			IF @IsDiff = -1 
				BEGIN
					RETURN	
				END

			IF @IsDiff = 1 
			BEGIN
				SELECT @moveBetsDay = @NewMoveBetDate, @balanceUpDay = @NewBalanceUpDate
			END
		END

	 END

	-- sum amount
	INSERT INTO #Master (custID, Amt, MAgUser)
	SELECT m.custID, SUM(ISNULL(bal.Balance,0)), ''
	FROM #mrecommend m
	LEFT JOIN #BalanceInfo bal ON bal.CustId = m.CustId
	GROUP BY m.custID

	IF NOT EXISTS (SELECT 1 FROM #Master WHERE Amt <> 0)
	BEGIN
		Select @ErrMsg = case @Language   
			when 'E' then 'Cannot transfer because all downlines'' balance is 0!' 
			ELSE CustDB.dbo.f_Get_MsgNamebyMsgID_xtest(50002,@Language)
		end
			, @ErrCode = 103     
 
		IF @IsAutoTransfer = 1
		BEGIN
			SET @Result = (SELECT 50025 AS MsgId, 'BalanceZero' AS ErrType, @ErrMsg AS ErrMsg FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
			EXEC dbo.Age_ClearBalanceCust_Process_StatusUpd_xtest @FromCustID = @FromCustID, @ToCustIds = @ToCustIDs
				,@Status='Ignored', @Result = @Result;
		END
		RETURN	
	END
 
	 UPDATE #Master SET MAgUser = ci.username 
	 FROM #Master 
		INNER JOIN CustDB.dbo.custinfo ci with (NOLOCK) ON ci.custid = #Master.custid 
	
	 DECLARE @currency int, @actualrate float, @currName nvarchar(10),
	     @transcode bigint, @amount float, @grefno BIGINT, @transid BIGINT
 	 DECLARE @SAUser nvarchar(50), @MAgUser nvarchar(50), @MAgentID int
	 DECLARE @LogData nvarchar(300), @SubAccName varchar(30)
 
	 --- 20150606@Kathy: Migrate custDB to new server DBCust(Get credit from DBCust.CustDB) [Redmine:#36216]
	 SELECT @SubAccName = username 
	 FROM DBCUST.CustDB.dbo.custSub WITH(NOLOCK) 
	 WHERE SubAccID = @SubAccID

	 SELECT @currency = ci.currency, @currName = e.currency ,@SaUser = ci.username, 
			@actualrate = e.actualrate  
	 FROM CustDB.dbo.custinfo ci with (nolock) 
		INNER JOIN CustDB.dbo.Exchange e with (NOLOCK) on ci.currency = e.exchangeid  
	 WHERE custid = @SAgID

	 DECLARE @procName VARCHAR(100)
	 SELECT  @procName = OBJECT_NAME(@@PROCID)

	SET @rCount = 1;
	WHILE EXISTS(SELECT 1 FROM #Master WHERE rIdx = @rCount)
	BEGIN
		-- Reset error for each pair
		SELECT @ErrCode = 0,
			@ErrMsg = '';

		SELECT @MAgentID = custID, 
			@Amount = amt,
			@MAgUser = MAgUser
		FROM #Master 
		WHERE rIdx = @rCount;

		-- SET username
		UPDATE @tblResultMember
		SET UserName = @MAgUser
		WHERE CustId = @MAgentID;	

		IF (@Amount = 0)
		BEGIN
			UPDATE @tblResultMember
			SET MsgId = 50025, ErrType = 'BalanceZero', ErrMsg = 'Cannot transfer because balance is 0!'
			WHERE CustId = @MAgentID;	
			GOTO NEXT_PAIR;
		END
	
		--AutoJob Transfer: START a Pair waiting to Processing
		IF @IsAutoTransfer = 1
		BEGIN
			EXEC dbo.Age_ClearBalanceCust_Process_StatusUpd_xtest @FromCustID = @FromCustID, @ToCustIds = @MAgentID
				,@Status='Processing', @Amount=@Amount
				,@ErrCode = @ErrCode OUTPUT
				,@ErrMsg = @ErrMsg OUTPUT
			;
			-- CHECK: Cancelling
			IF @ErrCode > 0
			BEGIN
				UPDATE @tblResultMember
				SET MsgId = @ErrCode, ErrType = 'TransferStatus', ErrMsg = @ErrMsg
				WHERE CustId = @MAgentID;	
				GOTO NEXT_PAIR;
			END
		END

		BEGIN TRY
			--CHECK MASTER'S BALANCE
			DECLARE @custBalance money 
			SELECT @custBalance = @Amount 
			IF @FullTransfer = 0
			BEGIN
				IF @AmtTrans = 0
				OR (@CustBalance >= 0 AND (@AmtTrans <= 0 or @AmtTrans > @CustBalance))
				OR (@CustBalance < 0 AND (@AmtTrans >= 0 or @AmtTrans < @CustBalance))
					BEGIN
						SELECT @ErrMsg = CASE @Language 
										WHEN 'E' THEN 'Amount to transfer must be between 0 and' + ' ' + CONVERT(VARCHAR(100), -@CustBalance, 2) + '.'
										ELSE CustDB.dbo.f_Get_MsgNamebyMsgID_xtest(50005,@Language) + ' ' + CONVERT(VARCHAR(100), -@CustBalance, 2) + '.'
									END		
						SELECT @ErrCode = 104
						
						UPDATE @tblResultMember
						SET MsgId = 50005, ErrType = 'FullTransfer', ErrMsg = @ErrMsg
						WHERE CustId = @MAgentID;	
						GOTO NEXT_PAIR;
					END	
				-- INSERT AMOUNT INPUTED INTO BETTRANS 
				SET @amount = @AmtTrans	
			END 	

			SELECT @ErrMsg = CASE @Language 
								WHEN 'E' THEN 'Clear balance failed. Please try again.'
								ELSE CustDB.dbo.f_Get_MsgNamebyMsgID_xtest(50003,@Language)
								END
			------------------Gen refno--------------------------------------------------------------- 
			EXEC Get_Refno_Transid @RefNo = @transcode OUTPUT
			
			-- TODO: AutoTransfer - Check cancelled
			IF @IsAutoTransfer = 1
			BEGIN
				EXEC dbo.Age_ClearBalanceCust_Process_StatusUpd_xtest @FromCustID = @FromCustID, @ToCustIds = @MAgentID
					,@Status='Processing'
					,@ErrCode = @ErrCode OUTPUT
					,@ErrMsg = @ErrMsg OUTPUT
				;
				-- CHECK: Cancelling
				IF @ErrCode > 0
				BEGIN
					UPDATE @tblResultMember
					SET MsgId = @ErrCode, ErrType = 'TransferStatus', ErrMsg = @ErrMsg
					WHERE CustId = @MAgentID;	
					GOTO NEXT_PAIR;
				END
			END

			------------------Insert trans into transfer----------------------------------------------
			BEGIN TRANSACTION
			-- All error messages are the same, so we set it here
			Select @ErrMsg = case @Language 
							when 'E' then 'Clear balance failed. Please try again.'
							ELSE CustDB.[dbo].[f_Get_MsgNamebyMsgID_xtest](50003,@Language)
							end

			IF @amount >0
			BEGIN
				EXEC Get_Bettrans_TransID @TransID = @TransID OUTPUT
				INSERT INTO Transfer 
					(transid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
						winlostdate, currency, actualrate,currencyName, mrecommend, srecommend, scomm, swinlost, recommend,ip,statusID, RepUpdateTime)
				VALUES (@transid, @creator, @SAgID, @SAUser, @transcode, current_timestamp, 21003, 'From Customer ::: ' + @MagUser + CASE WHEN @SubAccID > 0 THEN ' (By ' + @SubAccName + ')' ELSE '' END,
					@amount, 0,@WinlostDate, @currency, @actualrate, @currName, 0, @SAgID, 0, 0, 0,@ip,131,SYSDATETIME())
				IF @@Error <> 0
				BEGIN
					SELECT @ErrCode = 103
					ROLLBACK TRANSACTION
						
					--AutoJob Transfer
					UPDATE @tblResultMember
					SET MsgId = 50027, ErrType = 'DBIssue', ErrMsg = ERROR_MESSAGE()
					WHERE CustID = @MAgentID;

					GOTO NEXT_PAIR;
				END

				DECLARE @TotalCashMaster MONEY 
				EXEC Acc_CustomerSelCash_CaptureBalance @custid = @Magentid, @TotalCash  = @TotalCashMaster OUTPUT

				EXEC Get_Bettrans_TransID @TransID = @TransID OUTPUT
				INSERT INTO Transfer
					(transid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
					winlostdate, currency, actualrate, currencyName, mrecommend, srecommend, scomm, swinlost, recommend,ip,statusID, balance, RepUpdateTime)
				VALUES (@TransID, @creator, @Magentid, @MAgUser, @transcode, current_timestamp, 21003, 'To Customer ::: ' + @saUser + CASE WHEN @SubAccID > 0 THEN ' (By ' + @SubAccName + ')' ELSE '' END, 0, 
					@amount, @WinlostDate, @currency, @actualrate, @currName, @Magentid, @SAgID, 0, 0, 0,@ip,131, @TotalCashMaster,SYSDATETIME())
				IF @@Error <> 0
				BEGIN
					select @ErrCode = 104
					ROLLBACK TRANSACTION
						
					--AutoJob Transfer
					UPDATE @tblResultMember
					SET MsgId = 50027, ErrType = 'DBIssue', ErrMsg = ERROR_MESSAGE()
					WHERE CustID = @MAgentID;

					GOTO NEXT_PAIR;
				END

				--Add writelog for each amt transfered - Vinh 20080629
				SELECT @LogData = 'Transfer from Master ' + @MagUser + ' to Super ' + @saUser + ' with amount ' + CONVERT(VARCHAR(20), @amount) + ' Ref.No ' + CONVERT(VARCHAR(20), @transcode)			
				--AutoJob Transfer: Completed
				UPDATE @tblResultMember
				SET RefNo = @transcode
				WHERE CustID = @MAgentID;

			END
			ELSE IF @amount<0
			BEGIN
				--SET @amount = abs(@amount)

				EXEC Get_Bettrans_TransID @TransID = @TransID OUTPUT
				INSERT INTO Transfer 
					(transid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
					winlostdate, currency, actualrate, currencyName, mrecommend, srecommend, scomm, swinlost, recommend,ip,statusID, RepUpdateTime)
				VALUES (@transid,@creator, @SAgID, @SAUser, @transcode, current_timestamp, 21003, 'To Customer ::: ' + @MagUser + CASE WHEN @SubAccID > 0 THEN ' (By ' + @SubAccName + ')' ELSE '' END, 0, 
					abs(@amount),@WinlostDate, @currency, @actualrate, @currName, 0, @SAgID, 0, 0, 0,@ip,131,SYSDATETIME())
				if @@Error <> 0
				BEGIN
					select @ErrCode = 105
					ROLLBACK TRANSACTION
						
					--AutoJob Transfer
					UPDATE @tblResultMember
					SET MsgId = 50027, ErrType = 'DBIssue', ErrMsg = ERROR_MESSAGE()
					WHERE CustID = @MAgentID;

					GOTO NEXT_PAIR;
				END

				DECLARE @TotalCashMasterNev MONEY 
				EXEC Acc_CustomerSelCash_CaptureBalance @custid = @Magentid, @TotalCash  = @TotalCashMasterNev OUTPUT

				EXEC Get_Bettrans_TransID @TransID = @TransID OUTPUT
				INSERT INTO Transfer
					(transid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
					winlostdate, currency,actualrate, currencyName, mrecommend, srecommend, scomm, swinlost, recommend,ip,statusID, balance, RepUpdateTime)
				VALUES (@transid, @creator, @Magentid, @MAgUser, @transcode, current_timestamp, 21003, 'From Customer ::: ' + @saUser + CASE WHEN @SubAccID > 0 THEN ' (By ' + @SubAccName + ')' ELSE '' END, 
					abs(@amount), 0, @WinlostDate, @currency, @actualrate, @currName, @Magentid, @SAgID, 0, 0, 0,@ip,131, @TotalCashMasterNev,SYSDATETIME())
				if @@Error <> 0
				BEGIN
					SELECT @ErrCode = 106
					ROLLBACK TRANSACTION
						
					--AutoJob Transfer
					UPDATE @tblResultMember
					SET MsgId = 50027, ErrType = 'DBIssue', ErrMsg = ERROR_MESSAGE()
					WHERE CustID = @MAgentID;

					GOTO NEXT_PAIR;
				END
			
				--Add writelog for each amt transfered - Vinh 20080629
				SELECT @LogData = 'Transfer from Super ' + @saUser + ' to Master ' + @MagUser + ' with amount ' + convert(varchar(20), @amount) + ' Ref.No ' + convert(varchar(20), @transcode)			
					
				--AutoJob Transfer: Completed
				UPDATE @tblResultMember
				SET RefNo = @transcode
				WHERE CustID = @MAgentID;
			END
			--
			COMMIT TRANSACTION

			SELECT @ErrCode = 0, 
				@ErrMsg		= ''
	
			IF @SubAccID > 0
				SET @LogData = 'SubAccount:' + coalesce(cast(@SubAccName as varchar(30)),space(1)) + ' - ' + @LogData

			SELECT @LogData = @LogData + ' SPName: ' + @procName

			BEGIN TRY
				EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer 
									@UserID		= @creator, 
									@FromCustID = @SAgID, 
									@ToCustID	=  @MAgentID, 
									@IP			= @IP, 
									@Doing		= @LogData
			END TRY
			BEGIN CATCH
				SELECT @LogData = @LogData + ' ErrMsg: ' + ERROR_MESSAGE()
	
				EXEC bodb_customerlog.dbo.WriteLog_UserLog_Transfer 
									@UserID		= @creator, 
									@FromCustID = @SAgID, 
									@ToCustID	=  @MAgentID, 
									@IP			= @IP, 
									@Doing		= @LogData
			END CATCH
		END TRY
		BEGIN CATCH
			--Exception
			UPDATE @tblResultMember
			SET MsgId = 50003, ErrType = 'DBIssue', ErrMsg = ERROR_MESSAGE()
			WHERE CustID = @MAgentID;
		END CATCH

		NEXT_PAIR:
		IF @IsAutoTransfer = 1
		BEGIN
			SELECT @Result = (SELECT MsgId, ErrType, ErrMsg, RefNo FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
				@PairStatus = CASE WHEN RefNo > 0 THEN 'Completed' ELSE 
					CASE WHEN ErrType = 'BalanceZero' THEN 'Ignored' ELSE 'Failed' END
				END
			FROM @tblResultMember 
			WHERE CustId=@MAgentID
			;
			EXEC dbo.Age_ClearBalanceCust_Process_StatusUpd_xtest @FromCustID = @FromCustID, @ToCustIds = @MAgentID
				,@Status=@PairStatus, @Result = @Result;
		END
		ELSE
		BEGIN
			--TODO: Check FAILED break for MANUAL transfer
			IF @ErrCode > 0
				RETURN
		END

		SET @rCount += 1;
	END
 
	DROP TABLE #Master
	DROP TABLE #BalanceInfo
	DROP TABLE #mrecommend
	DROP TABLE #recommend
	DROP TABLE #SportBettype
END
GO

ALTER PROCEDURE  [dbo].[Age_Transfer_InsClearBalance_Ag_xtest]
	@FromCustID int, --Agent ID here  
	@ToCustIDs varchar(4000),   
	@SuperIDsTransferTotal VARCHAR(50)='', 
	@creator int,  
	@Language varchar(2)= 'E',  
	@SubAccID int = 0, --Sub-AccountID  
	@IP varchar(45)='',
	@ErrCode int = 0 OUTPUT,  
	@ErrMsg nvarchar(4000) = '' OUTPUT,  
	@CustStatus varchar(50)='',
	@IsAllDayBalTransfer BIT = 0,
	@IsAutoTransfer BIT = 0
AS  
/*
Created: 
Task: Transfer/ Multiple Transfer	
DB: DBTXN/bodb02
Original: Age_Transfer_InsClearBalance_Ag_xtest

Revisions:
	- 20060225@: remove refno.
	- 20090318@Phuc: Korean language.
	- 20090417@PhuongDao: Allow some agents to transfer total balance including today balance 
	- 20090729@Phuc: Write log subaccname instead of subaccid.
	- 20090818@Phuc: check page access and check upline closed first(call Age_CustSubCheckPageAccess)
	- 20091003@Kiwi: Modify Write log function and remove CustBetCreditUpdResync
	- 20091209@Kiwi: Remove comstatus because it's no used.	
	- 20100424@Henry: insert data to column StatusID of Bettrans (StatusID = 131 for bettype 104)
	- 20100611@Henry: Write exact amount to log when transferring
	- 20101224@Johnson: Apply new arrange of bettype
	- 20110107@Henry: Notification feature when transfer
	- 20111024@Sophia: Update balance credit/debit for member
	- 20120104@Lukas: modify to filter by 'enabled' status
	- 20120202@Jamie: Change transfer time to 12pm to 11:59pm instead of 12pm to 10pm ( 9h59pm)
	- 20120412@Sophia: Revise update balance credit/debit for member
	- 20121011@Dan: reset yesterday balance for live casino
	- 20121128@Elodie: Get an error message from f_Get_MsgNameByMsgID function by language
	- 20121203@Dan: skip deleted transfer record when check existed transfer
	- 20130201@Johnson: write log into DBTXN if failure DBLOG server
	- 20131108@Elodie: Splitting bodb02 into CustDB (Call CustInfo, Exchange, Customer, Age_Transfer_CheckTransferOption by link database)
	- 20150606@Kathy: Change link server DBTXN.CustDB to DBCust.CustDB, get Credit directly from DBCust [Redmine:#36216]
	- 20150721@Patrick: Support Gold deluxe
	- 20150808@Elodie: Balance Improvement [Redmine:#40125]
	- 20151021@Elodie: Set @IsForce = 1 for updating balance debit [Redmine:#40125]
	- 20160126@Kathy: get balance from bettransRNG + bettransLC [Redmine:#50674]
	- 20160815@Patrick: Allow SMA to transfer in 24 hours [Redmine:#61626]
	- 20170609@Percy:
		1. Re-check [Allow SMA to transfer in 24 hours]: apply general sp Acc_CheckProcessingData [RedmineID: #78487]
		2. Change way to calculate balance [RedmineID: #74291]
	- 20170721@Percy: Enhance performance - Phase 1 [RedmineID: #80367]
	- 20170808@Percy: Enhance performance - Phase 2 [RedmineID: #81436]
	- 20170831@Percy: Add SP Name into log [RedmineID: #80978]
	- 20200602@Percy: Separate PendingTransfer3rd from Cash and Balance [RedmineID: #135200]
	- 20200821@Sophia: prevent duplicated transfer [Redmine: #137141]
	- 20200821@Sophia: Check UM Transfer Function [Redmine: #136992]
	- 20201005@Danny: Convert Ipv6 to dummy IPv4 [Redmine: #142511]
	- 20201015@Malcolm : Add sub account information when transfering [RedmineId : #143478]
	- 20201228@Danny: Capture total cash before transfering  [Redmine: #146038]
	- 20210603@Sol: Alpha - All Sites - Lock account & indirect close account - [RedmineID: #148600]
	- 20210726@Evan: Transfer all pages work incorrect with disabled account [RedmineID: #158813]
	- 20210505@Sol: NAP - Alpha - Allow more time for transfer - [Redmine: #149927]
	- 20210817@Sophia: Fix overflow Refno [Redmine: #160262]
	- 20211111@Evan: Split transfer tickets out of bettrans - [Redmine: #164196]
	- 20220315@Evan: SQL Server Upgrade STRING_SPLIT [Redmine: #168783]
	- 20220721@Danny: get transid and refno with new generation [Redmine: #175670]
	- 20230227@Evan: Balance-Up support transfer 247 [Redmine: #173554] 
	- 20230523@Danny: support scale out credit [Redmine: #181595]
	- 20230705@Lewis: Allow to transfer YTB many times [Redmine: #186078]
	- 20230227@Bobby: Auto Clear Balance/ Multiple Transfer	 [RedmineID: #182071]

Param's Explanation:
	• @FromCustID: list from custid
	• @ToCustIDs: list to custid
	  @SuperIDsTransferTotal: Supers are allowed to tranfer total balance including today balance 
	  @IsAllDayBalTransfer: allow transfer many times per day

*/
BEGIN
	SET NOCOUNT ON  

	DECLARE @LogData NVARCHAR(500), @PairStatus VARCHAR(15), @Result nvarchar(4000);
	DECLARE @agentid INT, @custid int  
	DECLARE @currency INT, @actualrate FLOAT, @currName NVARCHAR(10)    
	DECLARE @agUser NVARCHAR(50), @User NVARCHAR(50)  
	DECLARE @RefNo BIGINT, @ToCustID INT, @Amount FLOAT, @Recommend1 INT, @MRecommend1 INT, @Recommend2 INT, @MRecommend2 INT, @grefno BIGINT, @srecommend1 INT, @TransID BIGINT  
	DECLARE @Outstanding MONEY, @credit MONEY, @FutureBetCredit MONEY, @ABSamount MONEY, @PendingTransfer3rd MONEY

	-- TODO: support auto clear balance
	DECLARE @tblResultMember TABLE(CustId INT PRIMARY KEY, UserName VARCHAR(50), MsgId INT, ErrType VARCHAR(50), ErrMsg NVARCHAR(4000), RefNo BIGINT);
	INSERT INTO @tblResultMember(CustId)
	SELECT DISTINCT t.value
	FROM STRING_SPLIT(@ToCustIDs, ',') AS t;

	EXEC DBCUST.CustDB.dbo.Age_Transfer_CheckTransferOption   
		@CustID = @FromCustID,  
		@ErrMsg = @ErrMsg OUTPUT,  
		@ErrCode = @ErrCode OUTPUT,  
		@Language = @Language  
   
	IF @ErrCode > 0  
	BEGIN  
		IF @IsAutoTransfer = 1
		BEGIN
			SET @Result = (SELECT 50023 AS MsgId, 'TransferOption' AS ErrType, @ErrMsg AS ErrMsg FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
			EXEC dbo.Age_ClearBalanceCust_Process_StatusUpd_xtest @FromCustID = @FromCustID, @ToCustIds = @ToCustIds
				,@Status='Failed', @Result = @Result;
		END
		RETURN
	END

 	IF NOT EXISTS (SELECT 1 FROM CustDB.dbo.customer WITH (NOLOCK) WHERE custid = @FromCustID)  
	BEGIN  
		select @ErrCode = 102  
		Select @ErrMsg = case @Language   
			when 'E' then 'Customer does not exist.'  
		   ELSE CustDB.dbo.f_Get_MsgNamebyMsgID(40014,@Language)
			end    

		IF @IsAutoTransfer = 1
		BEGIN
			SET @Result = (SELECT 40014 AS MsgId, 'NotFound' AS ErrType, @ErrMsg AS ErrMsg FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
			EXEC dbo.Age_ClearBalanceCust_Process_StatusUpd_xtest @FromCustID = @FromCustID, @ToCustIds = @ToCustIDs
				,@Status='Failed', @Result = @Result;
		END
		RETURN
	END  
  
	SELECT @AgentID = @FromCustID  
 
	---- #1 CHECK UM TRANSFER FUNCTION
	DECLARE @ToTimeConfig DATETIME;
	EXEC DBCUST.CUSTDB.dbo.Acc_Transfer_CheckUM_xtest  
		@CustID = @AgentID
		,@Language = @Language
		,@ErrMsg = @ErrMsg OUTPUT 
		,@ErrCode = @ErrCode OUTPUT
		,@ToTimeConfig = @ToTimeConfig OUTPUT
	 
	IF @ErrCode <> 0  -- Function Transfer is under UM 
	BEGIN	
		IF @IsAutoTransfer = 1
		BEGIN
			SET @Result = (SELECT 50024 AS MsgId,'TransferUM' AS ErrType, @ErrMsg AS ErrMsg, 
				@ToTimeConfig AS ToTime FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
			EXEC dbo.Age_ClearBalanceCust_Process_StatusUpd_xtest @FromCustID = @FromCustID, @ToCustIds = @ToCustIDs
				,@Status='Pending', @Result = @Result;
		END
		RETURN
	END		

	---- #2 CHECK FLAG ISTRANSFERRING = 1 THEN RAISE ERROR
	EXEC DBCUST.CUSTDB.dbo.Acc_Transfer_CheckRunningByCust  
			@CustID = @AgentID
			,@Language = @Language
			,@ErrMsg = @ErrMsg OUTPUT 
			,@ErrCode = @ErrCode OUTPUT
		 
	IF @ErrCode <> 0  -- the auto transfer job is running this custid
	BEGIN
		IF @IsAutoTransfer = 1
		BEGIN
			SET @Result = (SELECT 50026 AS MsgId, 'AccTransfering' AS ErrType, @ErrMsg AS ErrMsg FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
			EXEC dbo.Age_ClearBalanceCust_Process_StatusUpd_xtest @FromCustID = @FromCustID, @ToCustIds = @ToCustIDs
				,@Status='Failed', @Result = @Result;
		END
		RETURN
	END

	---- #2.1 CHECK Status is Waiting or Running -- manual tranfer
	IF @IsAutoTransfer = 0
	BEGIN
		EXEC bodb02.dbo.Age_ClearBalanceCust_CheckRunning_xtest  
			@CustID = @AgentID
			,@Language = @Language
			,@ErrMsg = @ErrMsg OUTPUT 
			,@ErrCode = @ErrCode OUTPUT
			 
		IF @ErrCode <> 0  -- the auto transfer job is running for this line
		BEGIN		
			RETURN
		END	
	END


	-- get move bet date
	DECLARE @balanceUpDay SMALLDATETIME, @moveBetsDay SMALLDATETIME
	DECLARE @tblMoveBetBalanceUp AS TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)
	DECLARE @IsDiff	SMALLINT = 1, @NewMoveBetDate SMALLDATETIME = NULL,@NewBalanceUpDate SMALLDATETIME = NULL

	INSERT INTO @tblMoveBetBalanceUp(BalanceUpDay,MoveBetsDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay
	
	SELECT @balanceUpDay = BalanceUpDay, @moveBetsDay = MoveBetsDay FROM @tblMoveBetBalanceUp

	SELECT @currency = ci.currency, @actualrate = e.actualrate, @currName = e.currency, @agUser = ci.username, 
		@Recommend1 = ci.recommend, @MRecommend1 = ci.mrecommend, @srecommend1 = ci.srecommend  
	FROM CustDB.dbo.custinfo ci (nolock) 
	INNER JOIN CustDB.dbo.Exchange e with (NOLOCK) on ci.currency = e.exchangeid 
	WHERE custid = @agentid AND roleid = 2  
 
	---Calculated Balance saved in Temp Table  @Phuong09152008
	CREATE TABLE #Member (
						rIdx INT IDENTITY(1,1),
						custid int PRIMARY KEY NONCLUSTERED,
						memberName nvarchar(50),	
						memberBalance money DEFAULT 0,
						memberOutstanding money DEFAULT 0,
						memberCredit money DEFAULT 0,
						memberPendingTransfer3rd money DEFAULT 0,
						INDEX CIX_rIDx CLUSTERED (rIdx)
					); 
 
	DECLARE @WinlostDate datetime
	SELECT  @WinlostDate = convert(nvarchar(10), current_timestamp,120)

	DECLARE @yesterday SMALLDATETIME
	SELECT  @yesterday = '2023-08-12'
 
		-- Get bettype --
	DECLARE @isTest BIT = 0
	SELECT  @isTest = dbo.f_CheckSPVersion(@@PROCID)
	
	CREATE TABLE #SportBettype (bettype INT, RefTable TINYINT)
	INSERT INTO #SportBettype (bettype, RefTable)
	SELECT bettype, RefTable FROM dbo.f_SportBettypeMatrix_Sel (0, 0, 0, 2, '', '', @isTest)

	CREATE TABLE #BalanceInfo (CustId INT, Balance MONEY, Outstanding MONEY, PendingTransfer3rd MONEY, TableName VARCHAR(50))

	CREATE TABLE #custid (CustId INT)

	IF (@CustStatus <> '' OR @CustStatus <> null)
	BEGIN
		INSERT INTO #custid (CustId)
		SELECT c.custid
		FROM CustDB.dbo.custInfo c WITH(NOLOCK,index=IX_custinfo_1)  
		INNER JOIN CustDB.dbo.CustProductStatus cs with(nolock) on c.custid=cs.CustID
		WHERE	recommend = @AgentID 
				AND c.roleid = 1   
				AND c.Enabled = case @CustStatus when 'All' then c.Enabled 
						else	case @CustStatus  
								when 'Disabled' then 0   
								else 1 end  
						end
				AND 1 =  case	when @CustStatus = 'Open' and cs.CloseInfo = 0 and cs.SuspendInfo = 0  then 1
									when @CustStatus = 'Suspended' and cs.CloseInfo = 0 and cs.SuspendInfo > 0 then 1
									when @CustStatus = 'Closed'	and cs.CloseInfo > 0  then 1
									when @CustStatus = 'Disabled' then 1
									when @CustStatus = 'All' then 1
									else 0 end
	END
	ELSE
	BEGIN
		INSERT INTO #custid (CustId)
		SELECT CONVERT(INT, value) AS CustId
		FROM STRING_SPLIT(@ToCustIDs, ',')
	END

	/* *********** Calculating balance *********** */
	/* Note: using recommend = @AgentId on bettrans, bettransRnG, bettransLC, translog to using index on recommend column */

	--TOTAL BALANCE INCLUDING TODAY BALANCE 
	IF (SELECT srecommend FROM CustDB.dbo.custInfo (NOLOCK) WHERE custid = @AgentID AND roleid = 2) IN (SELECT CONVERT(INT,value) FROM STRING_SPLIT(@SuperIDsTransferTotal, ','))
	BEGIN 
		-- bettransRnG
		INSERT INTO #BalanceInfo (CustId, Balance, Outstanding)
		SELECT
			custid,
			ISNULL(SUM(CASE WHEN statusID IN (111, 112, 113) THEN winlost-actual_stake+playercomm ELSE 0 END), 0),
			ISNULL(SUM(CASE WHEN statusID IN (0, 1) THEN ABS(actual_stake) ELSE 0 END), 0)
		FROM dbo.bettransRnG b WITH (NOLOCK) 
		WHERE b.recommend = @AgentID
			AND (
				statusID IN (0, 1)
				OR winlostdate >= @yesterday
			)
		GROUP BY custid

		-- bettransLC
		INSERT INTO #BalanceInfo (CustId, Balance, Outstanding)
		SELECT
			custid,
			ISNULL(SUM(CASE WHEN statusID IN (111, 112, 113) THEN winlost-actual_stake+playercomm ELSE 0 END), 0),
			ISNULL(SUM(CASE WHEN statusID IN (0, 1) THEN ABS(actual_stake) ELSE 0 END), 0)
		FROM dbo.bettransLC b WITH (NOLOCK) 
		WHERE b.recommend = @AgentID
			AND (
				statusID IN (0, 1)
				OR winlostdate >= @yesterday
			)
		GROUP BY custid
	
		-- translog
		INSERT INTO #BalanceInfo (CustId, Balance, Outstanding)
		SELECT
			custid,
			0,
			ISNULL(SUM(ABS(actual_stake)), 0)
		FROM dbo.translog t WITH (NOLOCK) 
		WHERE t.recommend = @AgentID
			AND statusID IN (0, 1)
		GROUP BY custid

		-- bettrans
		INSERT INTO #BalanceInfo (CustId, Balance, Outstanding)
		SELECT
			custid,
			0,
			ISNULL(SUM(ABS(actual_stake)), 0)
		FROM dbo.bettrans b WITH(NOLOCK)
		WHERE b.recommend = @AgentID
			AND b.ruben = 0
			AND NOT EXISTS (SELECT TOP 1 1 FROM #SportBettype s WHERE s.Bettype = b.bettype AND s.RefTable <> 0)
		GROUP BY custid
	
		WHILE (@IsDiff = 1)
		BEGIN
			DELETE FROM #BalanceInfo WHERE TableName IN ('tblBettrans','tblTransfer')


				--tblBettrans
			INSERT INTO #BalanceInfo (CustId, Balance, Outstanding, PendingTransfer3rd, TableName)
			SELECT
				custid,
				ISNULL(SUM( winlost-actual_stake+playercomm ), 0),
				0,
				0,
				'tblBettrans'
			FROM dbo.bettrans b WITH(NOLOCK)
			WHERE b.recommend = @AgentID
				AND b.statusID IN (111, 112, 113)
				AND (
					b.winlostdate < @yesterday
					OR NOT EXISTS (SELECT TOP 1 1 FROM #SportBettype s WHERE s.Bettype = b.bettype AND s.RefTable IN (1, 2))
				)
				AND winlostdate > @moveBetsDay
			GROUP BY custid

				--tblTransfer
			INSERT INTO #BalanceInfo (CustId, Balance, Outstanding, PendingTransfer3rd, TableName)
			SELECT
				custid,
				ISNULL(SUM(CASE WHEN bettype IN (21008, 21009) THEN 0 ELSE winlost-actual_stake+playercomm END), 0),
				0,
				ISNULL(SUM(CASE WHEN bettype IN (21008, 21009) THEN -(winlost-actual_stake) ELSE 0 END), 0),
				'tblTransfer'
			FROM dbo.Transfer b WITH(NOLOCK)
			WHERE b.recommend = @AgentID
						AND 1 = CASE WHEN bettype = 19999 AND winlostdate > @moveBetsDay THEN 0 --> new sum
													WHEN bettype = 20000 AND winlostdate > @balanceUpDay THEN 0 --> new bal
													WHEN winlostdate < @balanceUpDay THEN 0 --> old data
											ELSE 1 END
			GROUP BY custid
		
			----check MB date, BU date again to make sure it is not changed
			SELECT @NewMoveBetDate = NULL, @NewBalanceUpDate = NULL
			EXEC dbo.Acc_ReCheck_MBUDate 
				@MBDate = @moveBetsDay,
				@BUDate = @balanceUpDay,
				@IsDiff = @IsDiff OUTPUT,
				@NewMBDate = @NewMoveBetDate OUTPUT,
				@NewBUDate = @NewBalanceUpDate OUTPUT
			IF @IsDiff = -1 
				BEGIN
					RETURN	
				END
				
			IF @IsDiff = 1 
			BEGIN
				SELECT @moveBetsDay = @NewMoveBetDate, @balanceUpDay = @NewBalanceUpDate
			END
		END
	END 
	--Yesterday Balance  
	ELSE 
	BEGIN 
		-- bettransRnG
		INSERT INTO #BalanceInfo (CustId, Balance, Outstanding)
		SELECT
			custid,
			ISNULL(SUM(CASE WHEN statusID IN (111, 112, 113) THEN winlost-actual_stake+playercomm ELSE 0 END), 0),
			ISNULL(SUM(CASE WHEN statusID IN (0, 1) THEN ABS(actual_stake) ELSE 0 END), 0)
		FROM dbo.bettransRnG b WITH (NOLOCK) 
		WHERE b.recommend = @AgentID
			AND (
				statusID IN (0, 1)
				OR winlostdate = @yesterday
			)
		GROUP BY custid

		-- bettransLC
		INSERT INTO #BalanceInfo (CustId, Balance, Outstanding)
		SELECT
			custid,
			ISNULL(SUM(CASE WHEN statusID IN (111, 112, 113) THEN winlost-actual_stake+playercomm ELSE 0 END), 0),
			ISNULL(SUM(CASE WHEN statusID IN (0, 1) THEN ABS(actual_stake) ELSE 0 END), 0)
		FROM dbo.bettransLC b WITH (NOLOCK) 
		WHERE b.recommend = @AgentID
			AND (
				statusID IN (0, 1)
				OR winlostdate = @yesterday
			)
		GROUP BY custid
	
		-- translog
		INSERT INTO #BalanceInfo (CustId, Balance, Outstanding)
		SELECT
			custid,
			0,
			ISNULL(SUM(ABS(actual_stake)), 0)
		FROM dbo.translog t WITH (NOLOCK) 
		WHERE t.recommend = @AgentID
			AND statusID IN (0, 1)
		GROUP BY custid

		-- bettrans
		INSERT INTO #BalanceInfo (CustId, Balance, Outstanding)
		SELECT
			custid,
			0,
			ISNULL(SUM(ABS(actual_stake)), 0)
		FROM dbo.bettrans b WITH(NOLOCK)
		WHERE b.recommend = @AgentID
			AND b.ruben = 0
			AND NOT EXISTS (SELECT TOP 1 1 FROM #SportBettype s WHERE s.Bettype = b.bettype AND s.RefTable <> 0)
		GROUP BY custid

		WHILE (@IsDiff = 1)
		BEGIN

			DELETE FROM #BalanceInfo WHERE TableName IN ('tblBettrans','tblTransfer')

				--tblBettrans
			INSERT INTO #BalanceInfo (CustId, Balance, Outstanding, PendingTransfer3rd, TableName)
			SELECT
				custid,
				ISNULL(SUM(winlost-actual_stake+playercomm ), 0),
				0,
				0,
				'tblBettrans'
			FROM dbo.bettrans b WITH(NOLOCK)
			WHERE b.recommend = @AgentID
				AND b.statusID IN (111, 112, 113)
				AND (
					b.winlostdate < @yesterday
					OR (
						winlostdate = @yesterday
						AND NOT EXISTS (SELECT TOP 1 1 FROM #SportBettype s WHERE s.Bettype = b.bettype AND s.RefTable IN (1, 2))
					)
				)
				AND winlostdate > @moveBetsDay
			GROUP BY custid
				
			--tblTransfer
			INSERT INTO #BalanceInfo (CustId, Balance, Outstanding, PendingTransfer3rd, TableName)
				SELECT
					custid,
					ISNULL(SUM(CASE WHEN bettype IN (21008, 21009) THEN 0 ELSE winlost-actual_stake+playercomm END), 0),
					0,
					ISNULL(SUM(CASE WHEN bettype IN (21008, 21009) THEN -(winlost-actual_stake) ELSE 0 END), 0),
					'tblTransfer'
				FROM dbo.Transfer b WITH(NOLOCK)
				WHERE b.recommend = @AgentID
					AND (
						b.winlostdate <= @yesterday
						OR b.bettype > 20000
					)
					AND 1 = CASE WHEN bettype = 19999 AND winlostdate > @moveBetsDay THEN 0 --> new sum
											WHEN bettype = 20000 AND winlostdate > @balanceUpDay THEN 0 --> new bal
											WHEN winlostdate < @balanceUpDay THEN 0 --> old data
									ELSE 1 END
				GROUP BY custid
		
			----check MB date, BU date again to make sure it is not changed
			SELECT @NewMoveBetDate = NULL, @NewBalanceUpDate = NULL
			EXEC dbo.Acc_ReCheck_MBUDate 
				@MBDate = @moveBetsDay,
				@BUDate = @balanceUpDay,
				@IsDiff = @IsDiff OUTPUT,
				@NewMBDate = @NewMoveBetDate OUTPUT,
				@NewBUDate = @NewBalanceUpDate OUTPUT
    
    		IF @IsDiff = -1 
			BEGIN
				RETURN	
			END
			
			IF @IsDiff = 1 
			BEGIN
				SELECT @moveBetsDay = @NewMoveBetDate, @balanceUpDay = @NewBalanceUpDate
			END
		END
	END
	/* *********** End Calculating balance *********** */

	/* Filtering input custids */
	INSERT INTO #Member (custid, memberName, memberBalance, memberOutstanding, memberCredit, memberPendingTransfer3rd)
	SELECT c.CustId, '', SUM(ISNULL(b.Balance,0)), SUM(ISNULL(b.Outstanding,0)), 0, SUM(ISNULL(PendingTransfer3rd, 0))
	FROM #custid c
	LEFT JOIN #BalanceInfo b ON b.CustId = c.CustId
	GROUP BY c.CustId
	/* End Filtering input custids */

	IF NOT EXISTS (SELECT 1 FROM #Member WHERE memberBalance <> 0)
	BEGIN
		SELECT @ErrMsg = CASE @Language   
							WHEN 'E' THEN 'Cannot transfer because all downlines'' balance is 0!' 
							ELSE CustDB.dbo.f_Get_MsgNamebyMsgID(50002,@Language)
							END, 
						@ErrCode = 103
			;
		IF @IsAutoTransfer = 1
		BEGIN
			SET @Result = (SELECT 50025 AS MsgId, 'BalanceZero' AS ErrType, @ErrMsg AS ErrMsg FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
			EXEC dbo.Age_ClearBalanceCust_Process_StatusUpd_xtest @FromCustID = @FromCustID, @ToCustIds = @ToCustIDs
				,@Status='Ignored', @Result = @Result;
		END
		RETURN
	END
 
	--Update member credit of table #Member
	UPDATE #Member 
	SET #Member.memberCredit = c.credit, #Member.memberName = c.username 
	FROM #Member 
	INNER JOIN DBCUST.CustDB.dbo.custinfo c WITH (NOLOCK) ON #Member.custid = c.custid
 
	DECLARE @procName VARCHAR(100)
	SELECT  @procName = OBJECT_NAME(@@PROCID)
 
	DECLARE @ErrItems nvarchar(4000);
	DECLARE @isSucc varchar(10), @SubAccName varchar(30)
 
	--- 20150606@Kathy: Migrate custDB to new server DBCust(Get credit from DBCust.CustDB) [Redmine:#36216]
	SELECT @SubAccName = username 
	FROM DBCUST.CustDB.dbo.custSub WITH(NOLOCK) 
	WHERE SubAccID = @SubAccID

    
	SELECT @isSucc='false'  
  
	DECLARE @rCount INT = 1;
	WHILE EXISTS(SELECT 1 FROM #Member WHERE rIdx = @rCount)
	BEGIN  
		/**
			custid int,
			memberName nvarchar(50),	
			memberBalance money DEFAULT 0,
			memberOutstanding money DEFAULT 0,
			memberCredit money DEFAULT 0,
			memberPendingTransfer3rd money DEFAULT 0,
		**/
		-- Reset error for each pair
		SELECT @ErrCode = 0,
			@ErrMsg = '';

		BEGIN TRY
			SELECT TOP(1)
				@custID					= custid
				, @user					= memberName			
				, @amount				= memberBalance
				, @Outstanding			= memberOutstanding
				, @credit				= memberCredit
				, @PendingTransfer3rd	= memberPendingTransfer3rd
			FROM #Member
			WHERE rIdx = @rCount

			-- SET username
			UPDATE @tblResultMember
			SET UserName = @User
			WHERE CustId = @custid;	

			IF (@amount = 0)
			BEGIN
				UPDATE @tblResultMember
				SET MsgId = 50025, ErrType = 'BalanceZero', ErrMsg = 'Cannot transfer because balance is 0!'
				WHERE CustId = @custid;
				GOTO NEXT_PAIR;
			END
	
			--AutoJob Transfer: START a Pair waiting to Processing
			IF @IsAutoTransfer = 1
			BEGIN
				EXEC dbo.Age_ClearBalanceCust_Process_StatusUpd_xtest @FromCustID = @FromCustID, @ToCustIds = @custid
					,@Status='Processing', @Amount=@Amount
					,@ErrCode = @ErrCode OUTPUT
					,@ErrMsg = @ErrMsg OUTPUT
				;
				-- CHECK: Cancelling
				IF @ErrCode > 0
				BEGIN
					UPDATE @tblResultMember
					SET MsgId = @ErrCode, ErrType = 'TransferStatus', ErrMsg = @ErrMsg
					WHERE CustId = @custid;	
					GOTO NEXT_PAIR;
				END
			END


			
			------------------Gen refno---------------------------------------------------------------  
			EXEC Get_Refno_Transid @RefNo = @RefNo OUTPUT

			-- TODO: AutoTransfer - Check cancelled
			IF @IsAutoTransfer = 1
			BEGIN
				EXEC dbo.Age_ClearBalanceCust_Process_StatusUpd_xtest @FromCustID = @FromCustID, @ToCustIds = @custid
					,@Status='Processing'
					,@ErrCode = @ErrCode OUTPUT
					,@ErrMsg = @ErrMsg OUTPUT
				;
				-- CHECK: Cancelling
				IF @ErrCode > 0
				BEGIN
					UPDATE @tblResultMember
					SET MsgId = @ErrCode, ErrType = 'TransferStatus', ErrMsg = @ErrMsg
					WHERE CustId = @custid;	
					GOTO NEXT_PAIR;
				END
			END
			
			--TODO: Set default ERROR for MANUAL transfer
			SELECT @ErrCode		= 105
					,@ErrMsg	= CASE @Language
									WHEN 'E'
										THEN 'Clear balance failed. Please try again.'
									ELSE CustDB.[dbo].[f_Get_MsgNamebyMsgID](50003, @Language)
								END
			------------------Insert trans into transfer---------------------------------------------------------------  
			IF (@amount > 0)  
			BEGIN  
				EXEC Get_Bettrans_TransID @TransID = @TransID OUTPUT
				INSERT INTO Transfer   
					(transid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake,   
						winlostdate, currency, actualrate, currencyName, recommend, mrecommend, srecommend, scomm, swinlost,ip,statusID, RepUpdateTime)  
				VALUES 
					(@TransID, @creator, @agentid, @agUser, @RefNo, CURRENT_TIMESTAMP, 21004, 'From Customer :: ' + @User + CASE WHEN @SubAccID > 0 THEN ' (By ' + @SubAccName + ')' ELSE '' END, 
						@amount, 0, @WinlostDate, @currency, @actualrate, @currName, @agentid, @MRecommend1, @srecommend1, 0, 0,@ip,131, SYSDATETIME())  
				IF @@Error <> 0  
				BEGIN  
					--Manually rollback
					UPDATE dbo.Transfer WITH(ROWLOCK)
					SET	 custid = 0, Winlost = 0, Actual_Stake = 0, RepUpdateTime = SYSDATETIME(), Recommend = 0, MRecommend = 0, SRecommend = 0	
					WHERE refno = @RefNo
			
				
					--AutoJob Transfer
					UPDATE @tblResultMember
					SET MsgId = 50027, ErrType = 'DBIssue', ErrMsg = ERROR_MESSAGE()
					WHERE CustID = @custid;

					GOTO NEXT_PAIR;
				END  
		
				---update debit balance
				--EXEC Dot_BalanceUpdDebit @CustID = @CustID, @balance = @amount  
				EXEC Dot_BalanceDebitUpd @CustID = @CustID, @balance = @amount, @type = 2, @IsForced = 1, @errCode = @ErrCode OUTPUT
				IF @ErrCode <> 0
				BEGIN
					--Manually rollback
					UPDATE dbo.Transfer WITH(ROWLOCK)
					SET	 custid = 0, Winlost = 0, Actual_Stake = 0, RepUpdateTime = SYSDATETIME(), Recommend = 0, MRecommend = 0, SRecommend = 0	
					WHERE refno = @RefNo
			

					--AutoJob Transfer
					UPDATE @tblResultMember
					SET MsgId = 50027, ErrType = 'DBIssue', ErrMsg = CONCAT('Dot_BalanceDebitUpd @ErrCode=', @ErrCode)
					WHERE CustID = @custid;

					GOTO NEXT_PAIR;
				END
		
				DECLARE @TotalCash1 MONEY 
				EXEC Acc_CustomerSelCash_CaptureBalance @custid = @custid, @TotalCash  = @TotalCash1 OUTPUT

				EXEC Get_Bettrans_TransID @TransID = @TransID OUTPUT
				INSERT INTO Transfer  
					(transid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake,   
						winlostdate, currency, actualrate,currencyName, recommend, mrecommend, srecommend, scomm, swinlost,ip,statusID, balance, RepUpdateTime)  
				VALUES 
					(@TransID, @creator, @custid, @User, @RefNo, CURRENT_TIMESTAMP, 21004, 'To Customer :: ' + @agUser + CASE WHEN @SubAccID > 0 THEN ' (By ' + @SubAccName + ')' ELSE '' END, 
						0, @amount,  @WinlostDate, @currency, @actualrate, @currName, @agentid, @MRecommend1, @srecommend1, 0, 0,@ip,131, @TotalCash1, SYSDATETIME())  
				IF @@Error <> 0  
				BEGIN  
					--Manually rollback
					UPDATE dbo.Transfer WITH(ROWLOCK)
					SET	 custid = 0, Winlost = 0, Actual_Stake = 0, RepUpdateTime = SYSDATETIME(), Recommend = 0, MRecommend = 0, SRecommend = 0	
					WHERE refno = @RefNo
					
					-- rollback balance
					--EXEC Dot_BalanceUpdCredit @CustID = @CustID, @balance = @amount  
					EXEC Dot_BalanceCreditUpd @CustID = @CustID, @balance = @amount, @type = 2;
				
					--AutoJob Transfer
					UPDATE @tblResultMember
					SET MsgId = 50027, ErrType = 'DBIssue', ErrMsg = ERROR_MESSAGE()
					WHERE CustID = @custid;

					GOTO NEXT_PAIR;
				END  						
				
				--AutoJob Transfer: Completed
				UPDATE @tblResultMember
				SET RefNo = @RefNo
				WHERE CustID = @custid;

				--Add writelog for each amt transfered - Vinh 20080629  
				SELECT @LogData = 'Transfer from Customer ' + @User + ' to Agent ' + @agUser + ' with amount ' + convert(varchar(20), @amount) + ' Ref.No ' + convert(varchar(20), @RefNo)
		
				SET @FutureBetCredit = @credit - @outstanding - @PendingTransfer3rd
		
				IF @FutureBetCredit < 0 
				SELECT @LogData = @LogData + '. The agent decided to transfer after the warning so the bet credit of this member turned to negative value (' + convert(varchar(100), @FutureBetCredit, 2) + ') caused by having outstanding balance value ('+ convert(varchar(100), @outstanding, 2) +')  '
			END  
			ELSE IF(@amount < 0)  
			BEGIN  

				--SET @amount = abs(@amount)    
				EXEC Get_Bettrans_TransID @TransID = @TransID OUTPUT
				INSERT INTO Transfer   
					(transid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake,   
						winlostdate, currency,actualrate, currencyName, recommend, mrecommend, srecommend, scomm, swinlost,ip,statusID, RepUpdateTime)  
				VALUES 
					(@TransID, @creator, @agentid, @agUser, @RefNo, CURRENT_TIMESTAMP, 21004, 'To Customer :: ' + @User + CASE WHEN @SubAccID > 0 THEN ' (By ' + @SubAccName + ')' ELSE '' END, 
						0, abs(@amount),@WinlostDate, @currency, @actualrate, @currName, @agentid, @MRecommend1, @srecommend1, 0, 0,@ip,131, SYSDATETIME())  
				IF @@Error <> 0  
				BEGIN  
					--Manually rollback
					UPDATE dbo.Transfer WITH(ROWLOCK)
					SET	 custid = 0, Winlost = 0, Actual_Stake = 0, RepUpdateTime = SYSDATETIME(), Recommend = 0, MRecommend = 0, SRecommend = 0	
					WHERE refno = @RefNo

				
					--AutoJob Transfer
					UPDATE @tblResultMember
					SET MsgId = 50027, ErrType = 'DBIssue', ErrMsg = ERROR_MESSAGE()
					WHERE CustID = @custid;

					GOTO NEXT_PAIR;
				END  

				DECLARE @TotalCash3 MONEY 
				EXEC Acc_CustomerSelCash_CaptureBalance @custid = @custid, @TotalCash  = @TotalCash3 OUTPUT

				EXEC Get_Bettrans_TransID @TransID = @TransID OUTPUT
				INSERT INTO Transfer  
					(transid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake,   
						winlostdate, currency, actualrate, currencyName, recommend, mrecommend, srecommend, scomm, swinlost,ip,statusID, balance, RepUpdateTime)  
				VALUES 
					(@TransID, @creator, @custid, @User, @RefNo, CURRENT_TIMESTAMP, 21004, 'From Customer :: ' + @agUser + CASE WHEN @SubAccID > 0 THEN ' (By ' + @SubAccName + ')' ELSE '' END, 
						abs(@amount), 0, @WinlostDate, @currency, @actualrate, @currName, @agentid, @MRecommend1, @srecommend1, 0, 0,@ip,131, @TotalCash3, SYSDATETIME())  
				IF @@Error <> 0  
				BEGIN  
					--Manually rollback
					UPDATE dbo.Transfer WITH(ROWLOCK)
					SET	 custid = 0, Winlost = 0, Actual_Stake = 0, RepUpdateTime = SYSDATETIME(), Recommend = 0, MRecommend = 0, SRecommend = 0	
					WHERE refno = @RefNo


					--AutoJob Transfer
					UPDATE @tblResultMember
					SET MsgId = 50027, ErrType = 'DBIssue', ErrMsg = ERROR_MESSAGE()
					WHERE CustID = @custid;

					GOTO NEXT_PAIR;
				END 
		
				--AutoJob Transfer: Completed
				UPDATE @tblResultMember
				SET RefNo = @RefNo
				WHERE CustID = @custid;

				---update credit balance 
				SELECT @ABSamount = abs(@amount)  
				--EXEC Dot_BalanceUpdCredit @CustID = @CustID, @balance = @ABSamount	
				EXEC Dot_BalanceCreditUpd @CustID = @CustID, @balance = @ABSamount, @type = 2
				--Add writelog for each amt transfered - Vinh 20080629  
				SELECT @LogData = 'Transfer from Agent ' + @agUser + ' to Customer ' + @User + ' with amount ' + convert(varchar(20), @amount) + ' Ref.No ' + convert(varchar(20), @RefNo) 
		
			END  
			---------------------------------------------------------------------------------------------------

			DECLARE @isResetYesterdayBalance BIT, @ErrCode_ResetYesterdayBalance BIT, @YesterdayBalance MONEY
			-- reset yesterday balance for live casino				
			EXEC Acc_BalanceGameResetYesterday @CustID = @CustID, @isResetYesterdayBalance = @isResetYesterdayBalance OUTPUT, @YesterdayBalance = @YesterdayBalance	 OUTPUT, @ErrCode = @ErrCode_ResetYesterdayBalance OUTPUT	
			Select @LogData = @LogData + CASE WHEN @isResetYesterdayBalance = 1 THEN 
												CASE WHEN @ErrCode_ResetYesterdayBalance = 0 THEN '. (ResetGameBalance = suscess, YesterdayBalance =' + CAST(@YesterdayBalance AS VARCHAR(50)) + ')' 
												ELSE '. (ResetGameBalance = fail)' END		
										ELSE '' END			
							
			SELECT @ErrCode = 0  
			SELECT @ErrMsg = ''  
     

			set @isSucc='true'
			--Select @LogData = @LogData + '[' + convert(varchar(20),@ToCustID) + ', ' + convert(varchar(20), @amount) + ']'      
			IF @SubAccID > 0  
				SET @LogData = 'SubAccount:' +  coalesce(cast(@SubAccName as varchar(30)),space(1)) + ' - ' + @LogData  

			SELECT @LogData = @LogData + ' SPName: ' + @procName
		
			BEGIN TRY	
				EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Transfer 
										@UserID		= @creator, 
										@FromCustID = @FromCustID, 
										@ToCustID	= @custID, 
										@IP			= @IP, 
										@Doing		= @LogData 
			END TRY
			BEGIN CATCH
				SELECT @LogData = @LogData + ' ErrMsg: ' + ERROR_MESSAGE()
			
				EXEC bodb_customerlog.dbo.WriteLog_UserLog_Transfer 
									@UserID		= @creator, 
									@FromCustID = @FromCustID, 
									@ToCustID	= @custID, 
									@IP			= @IP, 
									@Doing		= @LogData
			END CATCH
	  
		END TRY
		BEGIN CATCH
			--Exception
			UPDATE @tblResultMember
			SET MsgId = 50027, ErrType = 'DBIssue', ErrMsg = ERROR_MESSAGE()
			WHERE CustID = @custid;
		END CATCH

		NEXT_PAIR:
		IF @IsAutoTransfer = 1
		BEGIN
			SELECT @Result = (SELECT MsgId, ErrType, ErrMsg, RefNo FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
				@PairStatus = CASE WHEN RefNo > 0 THEN 'Completed' ELSE 
					CASE WHEN ErrType = 'BalanceZero' THEN 'Ignored' ELSE 'Failed' END 
				END
			FROM @tblResultMember 
			WHERE CustId=@CustId
			;
			EXEC dbo.Age_ClearBalanceCust_Process_StatusUpd_xtest @FromCustID = @FromCustID, @ToCustIds = @custid
				,@Status=@PairStatus, @Result = @Result;
		END
		ELSE 
		BEGIN
			--TODO: Check FAILED break for MANUAL transfer
			IF @ErrCode > 0
				RETURN;
		END
		SET @rCount += 1;
	END  
 
	DROP TABLE #Member  

END		
GO

USE CustDB;
GO
CREATE FUNCTION [dbo].[f_Age_ClearBalanceCust_Snapshot_xtest](@SiteDBGroupID SMALLINT) 
RETURNS TABLE
RETURN
/*
	Created:20230227@Bobby
	Task: 182071 - Auto Transfer/ Multiple Transfer	
	DB: DBCUST/CustDB

	Revisions:
		- 20230227@Bobby: AutoJob clear balance downlines [RedmineID: #182071]

*/
WITH CTE_Setting AS (
	SELECT DISTINCT c.roleid, s.FromCustID, CAST(GETDATE() AS DATE) AS SessionDate, cs.custid AS SuperId
	FROM CustDB.dbo.Age_ClearBalanceCust_Setting s WITH(NOLOCK)
		INNER JOIN CustDB.dbo.Customer c WITH(NOLOCK) ON c.custid =  s.FromCustId
		INNER JOIN CustDB.dbo.CustSuper cs WITH(NOLOCK) ON cs.custid = c.srecommend
	--WHERE cs.SiteDBGroupID = @SiteDBGroupID
),
CTE_SMASetting AS (
	SELECT tmp.SessionDate, ca.custid AS FromCustId, tmp.RoleId, ca.TransferOption,cm.IsAllDayBalTransfer, tmp.SuperId
	FROM CustDB.dbo.CustAgent ca WITH (NOLOCK)
		INNER JOIN CTE_Setting tmp ON tmp.FromCustId = ca.custid
		INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON c.custid = ca.custid
		INNER JOIN CustDB.dbo.CustMaster cm WITH (NOLOCK) ON cm.custid = c.mrecommend
	WHERE tmp.RoleId = 2

	UNION ALL
	SELECT tmp.SessionDate, cm.custid, tmp.RoleId, cm.TransferOption, cm.IsAllDayBalTransfer, tmp.SuperId
	FROM CustDB.dbo.CustMaster cm WITH (NOLOCK)
		INNER JOIN CTE_Setting tmp ON tmp.FromCustId = cm.custid
	WHERE tmp.RoleId = 3

	UNION ALL
	SELECT tmp.SessionDate, cs.custid, tmp.RoleId, cs.TransferOption, cs.IsAllDayBalTransfer, tmp.SuperId
	FROM CustDB.dbo.CustSuper cs WITH (NOLOCK)
		INNER JOIN CTE_Setting tmp ON tmp.FromCustId = cs.custid
	WHERE tmp.RoleId = 4
)
SELECT s.FromCustId, cs.ToCustID
	,s.roleid, ISNULL(s.IsAllDayBalTransfer, 0) AS IsAllDayBalTransfer, s.SuperId
	,s.TransferOption
FROM CTE_SMASetting s
	INNER JOIN CustDB.dbo.Age_ClearBalanceCust_Setting cs ON cs.FromCustID = s.FromCustId
	--CROSS APPLY (
	--		SELECT 
	--			--strTransferOption = dbo.f_Decimal_Binary(ISNULL(s.TransferOption,0))
	--			strTransferOption = CONCAT(
	--				(ISNULL(s.TransferOption,0)/POWER(2*1, 7)% 2) --SUN
	--				,(ISNULL(s.TransferOption,0)/POWER(2*1, 6)% 2) --MON
	--				,(ISNULL(s.TransferOption,0)/POWER(2*1, 5)% 2) --WEN
	--				,(ISNULL(s.TransferOption,0)/POWER(2*1, 4)% 2) --TUE
	--				,(ISNULL(s.TransferOption,0)/POWER(2*1, 3)% 2) --THUR
	--				,(ISNULL(s.TransferOption,0)/POWER(2*1, 2)% 2) --FRI
	--				,(ISNULL(s.TransferOption,0)/POWER(2*1, 1)% 2) --SAT
	--				,(ISNULL(s.TransferOption,0)/POWER(2*1, 0)% 2) --IsWeekly
	--			)
	--	) AS ck
--WHERE cs.EffectiveDate <= s.SessionDate
--	AND 1 = CASE 
--			WHEN s.RoleId = 4 THEN 1 -- by pass cheking super vs master 
--			WHEN ISNULL(s.TransferOption, 0) = 0 THEN 1 -- Daily mode
--			WHEN ((ISNULL(s.TransferOption,0)/POWER(2*1, 0))% 2) = 1 -- Weekly mode
--				AND ((ISNULL(s.TransferOption,0)/POWER(2*1, 8-DATEPART(WEEKDAY, CURRENT_TIMESTAMP)))% 2) = 1 THEN 1 -- WEEKDAY enabled
--			ELSE 0 
--		END
GO
