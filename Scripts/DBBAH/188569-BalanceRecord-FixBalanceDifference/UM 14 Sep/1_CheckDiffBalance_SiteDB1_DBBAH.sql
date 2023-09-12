/*<info serverAlias="DBBAH-bodb02" executers="" isFunction="0"></info>*/
/*
    Created: 20230905@Louisa
	Task: Check diff balance - SiteDB1 [Redmine: #188569]
	DB:DBBAH/bodb02

*/


----Run on DB05 AND DB05BK1

USE bodb02
GO


	--select count(1) as cnt_CustId from BalanceRecordDiff_SiteDB1_Order4 with(nolock) --709258
	--select count(1) as cnt_CustId from BalanceRecordDiff_SiteDB1_Order5 with(nolock) --29581
	--select count(1) as cnt_CustId from BalanceRecordDiff_SiteDB1_Order6 with(nolock) --409097
	
	IF EXISTS ( SELECT TOP 1 1 from sys.objects WHERE name = 'BalanceRecord_Diff_Site1_20230914_tmp' )
	BEGIN
		DROP TABLE BalanceRecord_Diff_Site1_20230914_tmp
	END

	CREATE TABLE BalanceRecord_Diff_Site1_20230914_tmp (ID INT IDENTITY(1,1) PRIMARY KEY , custid INT , OrderNo SMALLINT )
	
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

		INSERT INTO BalanceRecord_Diff_Site1_20230914_tmp (custid, OrderNo)
		SELECT  m.custid, 4
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

		INSERT INTO BalanceRecord_Diff_Site1_20230914_tmp (custid, OrderNo)
		SELECT  m.custid, 5
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
		INSERT INTO BalanceRecord_Diff_Site1_20230914_tmp (custid, OrderNo)
		SELECT  m.custid, 6
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




	  