/*<info serverAlias="DBBAH-bodb02" executers="" isFunction="0"></info>*/
/*
     Created: 20230522@Louisa
	Task: Detail Transaction - Re-init balance for the rest of licensees [Redmine: #188569]
	DB:DBBAH/bodb02

	Notes: run on db05bk1 only
*/

USE bodb02
GO

--- proccess data for SiteDBGroupID = 2

------- 1. Inputparam and init data:  Required input @Order and @strCustList
		---- @strCustList: list custid need to correct data again after execute

	DECLARE @strCustList VARCHAR(MAX) 
			,@Order TINYINT


	IF @Order IS NULL OR @strCustList
	RETURN

	--------------DECLARE temporary tables ------------------
	CREATE TABLE #temp_MemberInput(
		ID INT PRIMARY KEY,
		custid INT
	)

	CREATE TABLE #tempMember (custid INT)


	-------------- GET members needs to process ------------------
	IF @Order = 1
	BEGIN
		INSERT INTO #temp_MemberInput (ID, custid)
		SELECT ID, CustId
		FROM BalanceRecordDiff_SiteDB2_Order1 WITH (NOLOCK)
		WHERE CustId IN ( SELECT CAST([value] AS INT) FROM STRING_SPLIT(ISNULL(@strCustList,''), ','))
		ORDER BY ID
	END
	IF @Order = 5
	BEGIN
		INSERT INTO #temp_MemberInput (ID, custid)
		SELECT ID, CustId
		FROM BalanceRecordDiff_SiteDB2_Order5 WITH (NOLOCK)
		WHERE CustId IN ( SELECT CAST([value] AS INT) FROM STRING_SPLIT(ISNULL(@strCustList,''), ','))
		ORDER BY ID
	END
	IF @Order = 6
	BEGIN
		INSERT INTO #temp_MemberInput (ID, custid)
		SELECT ID, CustId
		FROM BalanceRecordDiff_SiteDB2_Order6 WITH (NOLOCK)
		WHERE CustId IN ( SELECT CAST([value] AS INT) FROM STRING_SPLIT(ISNULL(@strCustList,''), ','))
		ORDER BY ID
	END

	SELECT count(1) AS [custid_Count] FROM #temp_MemberInput

------- 2. Check data [dbo].[BalanceTrigger_ProcessData] on DB05/DB05BK1 until it's no data
	--DB05BK1:
	SELECT TOP 1 1
	FROM BalanceTrigger_ProcessData b WITH (NOLOCK)
		INNER JOIN #temp_MemberInput m ON b.custid = m.custid

	---DB05:
	--SELECT TOP 1 1
	--FROM bodb02.dbo.BalanceTrigger_ProcessData b WITH (NOLOCK)
	--	INNER JOIN BalanceRecordDiff_SiteDBX_OrderX m ON b.custid = m.custid

------- 3. Insert BalanceRecord and Delete Balance Trigger

	------ info for deployer 
	DECLARE @debug_message VARCHAR(MAX) = ''
				,@OrderNo INT ----Input Order

	IF @OrderNo IS NULL
	RETURN
	--------------LOOP BY batch 250 of customers ------------------
	DECLARE @rid_loop INT, @rowCount int  = 0, @batch int = 250, @loop_cnt int = 1
	DECLARE @StartRow INT = 1
			, @StopRow INT 
			, @retrycnt INT = 0 
			, @isSuccess BIT = 0
			, @StartTime DATETIME  =  GETDATE()
			, @DuringTime INT = 420 ---- process data during 420 second (7 mins) then break out loop
	DECLARE  @ExecuteSQL NVARCHAR(MAX) = ''
			, @query NVARCHAR(MAX) = ''
			, @ExecuteSQL_balance NVARCHAR(MAX) = ''
			, @query_balance NVARCHAR(MAX) = ''
			, @SiteDBAlias VARCHAR(200) ='DBSIG02'
			, @CustidList VARCHAR(MAX) = ''

	DECLARE @CustidBalanceList VARCHAR(MAX) = ''
	DECLARE @xml XML = NULL

	SET @rid_loop = ((SELECT MAX(ID) FROM #temp_MemberInput)/@batch) + 1
	SET @StopRow = @batch

	SELECT  @query = N''		
	SELECT	@query = @query + N'EXEC SiteDB_BalanceRecord_DeleteBalanceTrigger_tmp @CustidList'
	SELECT	@ExecuteSQL = N'EXECUTE '+ @SiteDBAlias +'.bodb02.dbo.sp_executesql @query, N''@CustidList VARCHAR(MAX)'',@CustidList'

	-- RESET param to insert balance in db05
	SELECT  @query_balance = N'', @SiteDBAlias = 'DB05'		
	SELECT	@query_balance = @query_balance + N'EXEC SiteDB_BalanceRecord_InsertBalanceRecord_tmp @CustidBalanceList'
	SELECT	@ExecuteSQL_balance = N'EXECUTE '+ @SiteDBAlias +'.bodb02.dbo.sp_executesql @query_balance, N''@CustidBalanceList VARCHAR(MAX)'',@CustidBalanceList'

	WHILE (@loop_cnt <= @rid_loop)
	BEGIN
	
		TRUNCATE TABLE #tempMember

		SET @debug_message = CONCAT(CONVERT(VARCHAR(50), GETDATE(), 121), ', processing for round:',  @loop_cnt, '/', @rid_loop)
		RAISERROR (@debug_message, 0, 1) WITH NOWAIT

		INSERT INTO #tempMember(custid)
		SELECT custid
		FROM #temp_MemberInput 
		WHERE ID BETWEEN @StartRow AND @StopRow

		IF @@ROWCOUNT = 0
			BREAK

		SET @CustidList = ''
		SET @CustidList = STUFF((SELECT ',' + CONVERT(VARCHAR(20), custid)
					 FROM #tempMember 
					 FOR XML PATH ('')
						),1,1,'')	
					
		--- step 2 insert balance record to re-init
		SELECT @CustidBalanceList = (SELECT  m.custid AS '@c'
											,bal.Balance AS '@b'
									FROM #tempMember m
										CROSS APPLY (
													SELECT TOP 1 Balance 
													FROM DBSIG02.bodb02.dbo.v_BalanceTable b WITH(NOLOCK) -- v_BalanceTable: this is a view, get data from 8 balance tables
													WHERE b.custid = m.custid) AS bal
									FOR XML PATH('r'), ROOT('root')
									)
		SET @xml = CONVERT(XML, @CustidBalanceList)
	
		-- insert db05bk1 first
		INSERT INTO BalanceRecord (custid, transid, bettype, actual_stake, winlost, playercomm, balancechanged, newbalance, actionDate, actionID, [action])
		SELECT	t.c.value('@c','int') AS custid, 0, 0, 0, 0, 0, 0, t.c.value('@b','MONEY') AS balance,CURRENT_TIMESTAMP, 255, 'Balance : Re-Init'
		FROM @xml.nodes('root/r') t(c)
		OPTION (OPTIMIZE FOR (@xml = NULL))	

		-- insert db05
		EXECUTE	sys.sp_executesql @ExecuteSQL_balance, N'@query_balance NVARCHAR(MAX), @CustidBalanceList VARCHAR(MAX)', @query_balance, @CustidBalanceList

		-- step 3: delete balance trigger if exists
		WHILE (@isSuccess = 0)
		BEGIN
			BEGIN TRY

				EXECUTE	sys.sp_executesql @ExecuteSQL, N'@query NVARCHAR(MAX), @CustidList VARCHAR(MAX)', @query, @CustidList
				SET @isSuccess = 1

			END TRY
			BEGIN CATCH
				SET @retrycnt = @retrycnt + 1
				PRINT @retrycnt

			END CATCH
		END

		IF DATEDIFF(SECOND, @StartTime, GETDATE() ) >= @DuringTime
		BEGIN
			INSERT INTO BalanceRecord_Config_tmp  (SiteDBGroupID , OrderNo, StartRow, EndRow)
			SELECT 2 AS SiteDBGroupID, @OrderNo, @StartRow AS StartRow, @StopRow AS EndRow 
			FROM #tempMember m  ---keep this value for next time run

			BREAK
		END

		SET @StartRow = @StopRow + 1
		SET @StopRow = @StopRow + @batch

		SELECT  @loop_cnt += 1

	END

	--SELECT @rowCount

	DROP TABLE #temp_MemberInput
	DROP TABLE #tempMember
