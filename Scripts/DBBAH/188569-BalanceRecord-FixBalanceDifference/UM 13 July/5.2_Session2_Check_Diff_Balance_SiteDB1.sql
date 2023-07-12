/*<info serverAlias="DBBAH-bodb02" executers="" isFunction="0"></info>*/
/*
    Created: 20230629@Louisa
	Task: Correct balance again - after correct on July 2023 [Redmine: #188569]
	DB:DBBAH/bodb02

*/


----Notes: run on db05bk1 

USE bodb02
GO

	---select count(1) as cnt_CustId from BalanceRecordDiff_SiteDB1_Order3 with(nolock)	
	---select count(1) as cnt_CustId from BalanceRecordDiff_SiteDB1_Order4 with(nolock) 
	---truncate table BalanceRecord_Diff_20230713_tmp

--- checking diff balance for SiteDB1_Order3, SiteDB1_Order3 ( 1,448,473 rows )
--- session 2:
	
	IF NOT EXISTS ( select top 1 1 from sys.objects where name = 'BalanceRecord_Diff_20230713_tmp' )
	BEGIN
		CREATE TABLE BalanceRecord_Diff_20230713_tmp (ID INT IDENTITY(1,1) PRIMARY KEY , custid INT , SiteDBGroupID SMALLINT )
	END
	
	DECLARE @batch int = 100000 
	DECLARE @StartRow INT = 1 

	----BalanceRecordDiff_SiteDB1_Order3
	SET @StartRow = 1
	WHILE (1=1)
	BEGIN
		INSERT INTO BalanceRecord_Diff_20230713_tmp (custid, SiteDBGroupID)
		SELECT  m.custid, 1
		FROM  BalanceRecordDiff_SiteDB1_Order3  (NOLOCK) m	
			CROSS APPLY (		
					SELECT TOP 1 Balance		
					FROM DBSIG01.bodb02.dbo.v_BalanceTable b WITH(NOLOCK) -- v_BalanceTable: this is a view, get data from 8 balance tables		
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

	END

	---- BalanceRecordDiff_SiteDB1_Order4
	SET @StartRow = 1
	WHILE (1=1)
	BEGIN
		INSERT INTO BalanceRecord_Diff_20230713_tmp (custid, SiteDBGroupID)
		SELECT  m.custid, 1
		FROM  BalanceRecordDiff_SiteDB1_Order4  (NOLOCK) m	
			CROSS APPLY (		
					SELECT TOP 1 Balance		
					FROM DBSIG01.bodb02.dbo.v_BalanceTable b WITH(NOLOCK) -- v_BalanceTable: this is a view, get data from 8 balance tables		
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

	END





	  