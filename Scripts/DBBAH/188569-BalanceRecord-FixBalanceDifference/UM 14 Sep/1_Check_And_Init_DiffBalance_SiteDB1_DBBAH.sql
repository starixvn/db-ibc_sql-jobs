/*<info serverAlias="DBBAH-bodb02" executers="" isFunction="0"></info>*/
/*
    Created: 20230905@Louisa
	Task: Check diff and init balance - SiteDB1 [Redmine: #188569]
	DB:DB05BK1/bodb02

*/


----Run on DB05 AND DB05BK1

USE bodb02
GO

	--select count(1) as cnt_CustId from BalanceRecordDiff_SiteDB1_Order4 with(nolock) --709258
	--select count(1) as cnt_CustId from BalanceRecordDiff_SiteDB1_Order5 with(nolock) --29581
	--select count(1) as cnt_CustId from BalanceRecordDiff_SiteDB1_Order6 with(nolock) --409097

----- 1. CHECK DIFF BALANCE

	IF EXISTS ( SELECT TOP 1 1 from sys.objects WHERE name = 'BalanceRecord_Diff_Site1_20230914_tmp' )
	BEGIN
		DROP TABLE BalanceRecord_Diff_Site1_20230914_tmp
	END

	CREATE TABLE BalanceRecord_Diff_Site1_20230914_tmp (ID INT IDENTITY(1,1) PRIMARY KEY , custid INT, Balance MONEY )
	
	DECLARE @batch INT = 100000 
	DECLARE @StartRow INT = 1 
	DECLARE @debug_message VARCHAR(MAX) = ''
			,@loop_cnt INT = 1

	----BalanceRecordDiff_SiteDB1_Order4
	SET @StartRow = 1
	WHILE (1=1)
	BEGIN
		SET @debug_message = CONCAT(CONVERT(VARCHAR(50), GETDATE(), 121), ', Start processing for SiteDB1_Order4, round:',  @loop_cnt, ' ,StartRow:', @StartRow, ' ,StopRow:',@StartRow+@batch-1)
		RAISERROR (@debug_message, 0, 1) WITH NOWAIT

		INSERT INTO BalanceRecord_Diff_Site1_20230914_tmp (custid, Balance)
		SELECT  m.custid, b1.Balance
		FROM  BalanceRecordDiff_SiteDB1_Order4 m WITH(NOLOCK)
			CROSS APPLY (		
					SELECT TOP 1 Balance		
					FROM DBSIG01.bodb02.dbo.v_BalanceTable b WITH(NOLOCK) -- data from 8 balance tables		
					WHERE b.custid = m.custid
			) AS b1		
			CROSS APPLY (		
					SELECT TOP 1 newbalance AS balance		
					FROM bodb02.dbo.balancerecord b WITH(NOLOCK) 	
					WHERE b.custid = m.custid		
					ORDER BY rowid DESC
			) as b2		
		WHERE m.ID  >= @StartRow AND m.ID  < @StartRow + @batch
			AND b2.balance  <> b1.balance

		IF @@ROWCOUNT < @batch
		BREAK
	
		SET @StartRow = @StartRow + @batch
		SELECT  @loop_cnt += 1

	END

	---- BalanceRecordDiff_SiteDB1_Order5
	SET @StartRow = 1
	SET @loop_cnt = 1
	WHILE (1=1)
	BEGIN
		SET @debug_message = CONCAT(CONVERT(VARCHAR(50), GETDATE(), 121), ', Start processing for SiteDB1_Order5, round:',  @loop_cnt, ' ,StartRow:', @StartRow, ' ,StopRow:',@StartRow+@batch-1)
		RAISERROR (@debug_message, 0, 1) WITH NOWAIT

		INSERT INTO BalanceRecord_Diff_Site1_20230914_tmp (custid, Balance)
		SELECT  m.custid, b1.Balance
		FROM  BalanceRecordDiff_SiteDB1_Order5 m WITH(NOLOCK)
			CROSS APPLY (		
					SELECT TOP 1 Balance		
					FROM DBSIG01.bodb02.dbo.v_BalanceTable b WITH(NOLOCK) -- data from 8 balance tables		
					WHERE b.custid = m.custid
			) AS b1		
			CROSS APPLY (		
					SELECT TOP 1 newbalance AS balance		
					FROM bodb02.dbo.balancerecord b WITH(NOLOCK) 	
					WHERE b.custid = m.custid		
					ORDER BY rowid DESC
			) as b2		
		WHERE m.ID  >= @StartRow AND m.ID  < @StartRow + @batch 
			and b2.balance  <> b1.balance

		IF @@ROWCOUNT < @batch
		BREAK
	
		SET @StartRow = @StartRow + @batch
		SELECT  @loop_cnt += 1

	END

	---- BalanceRecordDiff_SiteDB1_Order6
	SET @StartRow = 1
	SET @loop_cnt = 1
	WHILE (1=1)
	BEGIN
		SET @debug_message = CONCAT(CONVERT(VARCHAR(50), GETDATE(), 121), ', Start processing for SiteDB1_Order6, round:',  @loop_cnt, ' ,StartRow:', @StartRow, ' ,StopRow:',@StartRow+@batch-1)
		RAISERROR (@debug_message, 0, 1) WITH NOWAIT
		INSERT INTO BalanceRecord_Diff_Site1_20230914_tmp (custid, Balance)
		SELECT  m.custid, b1.Balance
		FROM  BalanceRecordDiff_SiteDB1_Order6 m WITH(NOLOCK)
			CROSS APPLY (		
					SELECT TOP 1 Balance		
					FROM DBSIG01.bodb02.dbo.v_BalanceTable b WITH(NOLOCK) -- data from 8 balance tables		
					WHERE b.custid = m.custid
			) AS b1		
			CROSS APPLY (		
					SELECT TOP 1 newbalance AS balance		
					FROM bodb02.dbo.balancerecord b WITH(NOLOCK) 	
					WHERE b.custid = m.custid		
					ORDER BY rowid DESC
			) as b2		
		WHERE m.ID  >= @StartRow AND m.ID  < @StartRow + @batch 
			and b2.balance  <> b1.balance

		IF @@ROWCOUNT < @batch
		BREAK
	
		SET @StartRow = @StartRow + @batch
		SELECT  @loop_cnt += 1

	END


----- 2. INIT BALANCE SITEDB1 ON DBBAH
	SELECT count(1) AS [custid_Count_diff] FROM BalanceRecord_Diff_Site1_20230914_tmp

	IF OBJECT_ID('tempdb..#tempMember') IS NOT NULL
	DROP TABLE #tempMember

	CREATE TABLE #tempMember (custid INT PRIMARY KEY, Balance MONEY)

	-- Check data [dbo].[BalanceTrigger_ProcessData] until it's no data
	SELECT TOP 1 1
	FROM BalanceTrigger_ProcessData b WITH (NOLOCK)
		INNER JOIN BalanceRecord_Diff_Site1_20230914_tmp m ON b.custid = m.custid

	--------------LOOP BY batch 500 of customers ------------------
	DECLARE @rid_loop INT
			, @rowCount int  =0
			, @StopRow INT

	SET @batch	= 500
	SET @StopRow = @batch
	SET @loop_cnt = 1
	SET @StartRow = 1
	SET @rid_loop = ((SELECT MAX(ID) FROM BalanceRecord_Diff_Site1_20230914_tmp)/@batch) + 1	
	SET @debug_message = ''

	WHILE (@loop_cnt <= @rid_loop)
	BEGIN
	
		TRUNCATE TABLE #tempMember

		SET @debug_message = CONCAT(CONVERT(VARCHAR(50), GETDATE(), 121), ', processing for round:',  @loop_cnt, '/', @rid_loop)
		RAISERROR (@debug_message, 0, 1) WITH NOWAIT

		INSERT INTO #tempMember(custid, Balance)
		SELECT custid, Balance
		FROM BalanceRecord_Diff_Site1_20230914_tmp
		WHERE ID BETWEEN @StartRow AND @StopRow

		IF @@ROWCOUNT = 0
			BREAK	
					
		INSERT INTO BalanceRecord (custid, transid, bettype, actual_stake, winlost, playercomm, balancechanged, newbalance, actionDate, actionID, [action])
		SELECT	custid, 0, 0, 0, 0, 0, 0, Balance ,CURRENT_TIMESTAMP, 255, 'Balance : Re-Init'
		FROM #tempMember m

		WAITFOR DELAY '00:00:00.020' --optional

		SET @StartRow = @StopRow + 1
		SET @StopRow = @StopRow + @batch

		SELECT  @loop_cnt += 1

	END