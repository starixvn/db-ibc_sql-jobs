/*<info serverAlias="DBBAH-bodb02" executers="" isFunction="0"></info>*/
/*
    Created: 20230629@Louisa
	Task: Correct balance for SiteDB2 again - after correct on June 2023 [Redmine: #188569]
	DB:DBBAH/bodb02

*/

----Notes: run on db05bk1 

USE bodb02
GO

	CREATE TABLE #temp_MemberInput(
		ID INT PRIMARY KEY,
		custid INT
	)

	CREATE TABLE #tempMember (custid INT)

	DECLARE @batchInsert int = 100000  
			, @StartRowInsert INT = 1 
			, @StartRowCorrect INT = 1
			, @batchCorrect int = 250
			, @retrycnt INT = 0 
			, @isSuccess BIT = 0
			, @StartTime DATETIME  =  GETDATE()
			, @DuringTime INT = 30 ---- process data over 30 mins then break out loop
			, @debug_message VARCHAR(MAX) = ''

	DECLARE  @ExecuteSQL NVARCHAR(MAX) = ''
			, @query NVARCHAR(MAX) = ''
			, @ExecuteSQL_balance NVARCHAR(MAX) = ''
			, @query_balance NVARCHAR(MAX) = ''
			, @SiteDBAlias VARCHAR(200) ='DBSIG02'
			, @CustidList VARCHAR(MAX) = ''

	DECLARE @CustidBalanceList VARCHAR(MAX) = ''
	DECLARE @xml XML = NULL
		
	SELECT	@query = @query + N'EXEC SiteDB_BalanceRecord_DeleteBalanceTrigger_tmp @CustidList'
	SELECT	@ExecuteSQL = N'EXECUTE '+ @SiteDBAlias +'.bodb02.dbo.sp_executesql @query, N''@CustidList VARCHAR(MAX)'',@CustidList' 	
	SELECT	@query_balance = @query_balance + N'EXEC SiteDB_BalanceRecord_InsertBalanceRecord_tmp @CustidBalanceList'
	SELECT	@ExecuteSQL_balance = N'EXECUTE DB05.bodb02.dbo.sp_executesql @query_balance, N''@CustidBalanceList VARCHAR(MAX)'',@CustidBalanceList'

	DECLARE @StartRow INT 
		, @StopRow INT 
		, @MaxRow INT  -- Keep the total row of your data
		, @Threshold INT  -- the number of each batch

----1. Check and correct for BalanceRecordDiff_SiteDB2_Order1--------------------------------------------
	SET @MaxRow = (SELECT MAX(ID) FROM BalanceRecordDiff_SiteDB2_Order1 with (nolock))
	SET @Threshold = 100000

	IF @Threshold >= @MaxRow
		SET @Threshold = @MaxRow

	-- SET for first batch
	SELECT @StartRow = 1, @StopRow = @Threshold
	TRUNCATE TABLE #temp_MemberInput
		
	WHILE (@MaxRow IS NOT NULL)
	BEGIN
		INSERT INTO #temp_MemberInput (ID, custid)
		SELECT ID, CustId
		FROM BalanceRecordDiff_SiteDB2_Order1 m WITH(NOLOCK)
			CROSS APPLY (		
						SELECT TOP 1 Balance		
						FROM DBSIG02.bodb02.dbo.v_BalanceTable b WITH(NOLOCK) -- v_BalanceTable: this is a view, get data from 8 balance tables		
						WHERE b.custid = m.custid
				) AS b1		
				CROSS APPLY (		
						SELECT TOP 1 newbalance AS balance		
						FROM bodb02.dbo.balancerecord b WITH(NOLOCK) 	
						WHERE b.custid = m.custid		
						ORDER BY rowid DESC
				) as b2		
		WHERE ID BETWEEN @StartRow AND @StopRow
			and b2.balance  <> b1.balance
		ORDER BY ID

		IF @StopRow = @MaxRow 
		BREAK

		SET @StartRow = @StopRow + 1
		SET @StopRow = @StopRow + @Threshold

		IF @StopRow >= @MaxRow
			SET @StopRow = @MaxRow

	END


	WHILE (1=1)
	BEGIN	
		TRUNCATE TABLE #tempMember

		INSERT INTO #tempMember(custid)
		SELECT custid
		FROM #temp_MemberInput 
		WHERE ID >= @StartRowCorrect AND ID  < @StartRowCorrect + @batchCorrect

		SET @CustidList = ''
		SET @CustidList = STUFF((SELECT ',' + CONVERT(VARCHAR(20), custid)
					 FROM #tempMember 
					 FOR XML PATH ('')
						),1,1,'')	
					
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
	
		-- insert balancerecord db05bk1
		INSERT INTO BalanceRecord (custid, transid, bettype, actual_stake, winlost, playercomm, balancechanged, newbalance, actionDate, actionID, [action])
		SELECT	t.c.value('@c','int') AS custid, 0, 0, 0, 0, 0, 0, t.c.value('@b','MONEY') AS balance,CURRENT_TIMESTAMP, 255, 'Balance : Re-Init'
		FROM @xml.nodes('root/r') t(c)
		OPTION (OPTIMIZE FOR (@xml = NULL))	

		-- insert balancerecord db05
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

		SET @debug_message = CONCAT(CONVERT(VARCHAR(50), GETDATE(), 121), ', processing for SiteDB2_Order1 StartRow: ', @StartRowCorrect, ' EndRow: ', @StartRowCorrect  + @batchInsert)
		RAISERROR (@debug_message, 0, 1) WITH NOWAIT

		IF DATEDIFF(MINUTE, @StartTime, GETDATE() ) >= @DuringTime
		BEGIN
			INSERT INTO BalanceRecord_Config_tmp  (SiteDBGroupID , OrderNo, StartRow, EndRow)
			SELECT 2 AS SiteDBGroupID, 1 AS OrderNo, @StartRowCorrect AS StartRow, @StartRowCorrect + @batchCorrect AS EndRow ----SiteDB1_Order2
			FROM #tempMember m  ---keep this value for next time run

			BREAK
		END

		IF @@ROWCOUNT < @batchCorrect
		BREAK

		SET @StartRowCorrect = @StartRowCorrect + @batchInsert

	END

----2. Check and correct for BalanceRecordDiff_SiteDB2_Order5--------------------------------------------
	TRUNCATE TABLE #temp_MemberInput
	SET @StartRowInsert = 1
	SET @StartRowCorrect = 1

	WHILE (1=1)
	BEGIN
		INSERT INTO #temp_MemberInput (ID, custid)
		SELECT ID, CustId
		FROM BalanceRecordDiff_SiteDB2_Order5 m WITH(NOLOCK)
			CROSS APPLY (		
						SELECT TOP 1 Balance		
						FROM DBSIG02.bodb02.dbo.v_BalanceTable b WITH(NOLOCK) -- v_BalanceTable: this is a view, get data from 8 balance tables		
						WHERE b.custid = m.custid
				) AS b1		
				CROSS APPLY (		
						SELECT TOP 1 newbalance AS balance		
						FROM bodb02.dbo.balancerecord b WITH(NOLOCK) 	
						WHERE b.custid = m.custid		
						ORDER BY rowid DESC
				) as b2		
		WHERE m.ID  >= @StartRowInsert AND m.ID  < @StartRowInsert + @batchInsert 
			and b2.balance  <> b1.balance
		ORDER BY ID

		IF @@ROWCOUNT < @batchInsert
		BREAK
	
		SET @StartRowInsert = @StartRowInsert + @batchInsert

	END

	WHILE (1=1)
	BEGIN
		TRUNCATE TABLE #tempMember

		INSERT INTO #tempMember(custid)
		SELECT custid
		FROM #temp_MemberInput 
		WHERE ID >= @StartRowCorrect AND ID  < @StartRowCorrect + @batchCorrect

		SET @CustidList = ''
		SET @CustidList = STUFF((SELECT ',' + CONVERT(VARCHAR(20), custid)
					 FROM #tempMember 
					 FOR XML PATH ('')
						),1,1,'')	
					
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
	
		-- insert balancerecord db05bk1
		INSERT INTO BalanceRecord (custid, transid, bettype, actual_stake, winlost, playercomm, balancechanged, newbalance, actionDate, actionID, [action])
		SELECT	t.c.value('@c','int') AS custid, 0, 0, 0, 0, 0, 0, t.c.value('@b','MONEY') AS balance,CURRENT_TIMESTAMP, 255, 'Balance : Re-Init'
		FROM @xml.nodes('root/r') t(c)
		OPTION (OPTIMIZE FOR (@xml = NULL))	

		-- insert balancerecord db05
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

		SET @debug_message = CONCAT(CONVERT(VARCHAR(50), GETDATE(), 121), ', processing for SiteDB2_Order5 StartRow: ', @StartRowCorrect, ' EndRow: ', @StartRowCorrect  + @batchInsert)
		RAISERROR (@debug_message, 0, 1) WITH NOWAIT

		IF DATEDIFF(MINUTE, @StartTime, GETDATE() ) >= @DuringTime
		BEGIN
			INSERT INTO BalanceRecord_Config_tmp  (SiteDBGroupID , OrderNo, StartRow, EndRow)
			SELECT 2 AS SiteDBGroupID, 5 AS OrderNo, @StartRowCorrect AS StartRow, @StartRowCorrect + @batchCorrect AS EndRow ----SiteDB1_Order2
			FROM #tempMember m  ---keep this value for next time run

			BREAK
		END

		IF @@ROWCOUNT < @batchCorrect
		BREAK

		SET @StartRowCorrect = @StartRowCorrect + @batchInsert

	END

----3. Check and correct for BalanceRecordDiff_SiteDB2_Order6--------------------------------------------
	TRUNCATE TABLE #temp_MemberInput
	SET @StartRowInsert = 1
	SET @StartRowCorrect = 1

	WHILE (1=1)
	BEGIN
		INSERT INTO #temp_MemberInput (ID, custid)
		SELECT ID, CustId
		FROM BalanceRecordDiff_SiteDB2_Order6 m WITH(NOLOCK)
			CROSS APPLY (		
						SELECT TOP 1 Balance		
						FROM DBSIG02.bodb02.dbo.v_BalanceTable b WITH(NOLOCK) -- v_BalanceTable: this is a view, get data from 8 balance tables		
						WHERE b.custid = m.custid
				) AS b1		
				CROSS APPLY (		
						SELECT TOP 1 newbalance AS balance		
						FROM bodb02.dbo.balancerecord b WITH(NOLOCK) 	
						WHERE b.custid = m.custid		
						ORDER BY rowid DESC
				) as b2		
		WHERE m.ID  >= @StartRowInsert AND m.ID  < @StartRowInsert + @batchInsert 
			AND b2.balance  <> b1.balance
		ORDER BY ID

		IF @@ROWCOUNT < @batchInsert
		BREAK
	
		SET @StartRowInsert = @StartRowInsert + @batchInsert

	END

	WHILE (1=1)
	BEGIN
		TRUNCATE TABLE #tempMember

		INSERT INTO #tempMember(custid)
		SELECT custid
		FROM #temp_MemberInput 
		WHERE ID >= @StartRowCorrect AND ID  < @StartRowCorrect + @batchCorrect

		SET @CustidList = ''
		SET @CustidList = STUFF((SELECT ',' + CONVERT(VARCHAR(20), custid)
					 FROM #tempMember 
					 FOR XML PATH ('')
						),1,1,'')	
					
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
	
		-- insert balancerecord db05bk1
		INSERT INTO BalanceRecord (custid, transid, bettype, actual_stake, winlost, playercomm, balancechanged, newbalance, actionDate, actionID, [action])
		SELECT	t.c.value('@c','int') AS custid, 0, 0, 0, 0, 0, 0, t.c.value('@b','MONEY') AS balance,CURRENT_TIMESTAMP, 255, 'Balance : Re-Init'
		FROM @xml.nodes('root/r') t(c)
		OPTION (OPTIMIZE FOR (@xml = NULL))	

		-- insert balancerecord db05
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

		SET @debug_message = CONCAT(CONVERT(VARCHAR(50), GETDATE(), 121), ', processing for SiteDB2_Order6 StartRow: ', @StartRowCorrect, ' EndRow: ', @StartRowCorrect  + @batchInsert)
		RAISERROR (@debug_message, 0, 1) WITH NOWAIT

		IF DATEDIFF(MINUTE, @StartTime, GETDATE() ) >= @DuringTime
		BEGIN
			INSERT INTO BalanceRecord_Config_tmp  (SiteDBGroupID , OrderNo, StartRow, EndRow)
			SELECT 2 AS SiteDBGroupID, 6 AS OrderNo, @StartRowCorrect AS StartRow, @StartRowCorrect + @batchCorrect AS EndRow ----SiteDB1_Order2
			FROM #tempMember m  ---keep this value for next time run

			BREAK
		END

		IF @@ROWCOUNT < @batchCorrect
		BREAK

		SET @StartRowCorrect = @StartRowCorrect + @batchInsert

	END

	DROP TABLE #temp_MemberInput
	DROP TABLE #tempMember