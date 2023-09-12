/*<info serverAlias="DBBAH-bodb02" executers="" isFunction="0"></info>*/
/*
    Created: 20230905@Louisa
	Task: Check diff balance - SiteDB1 [Redmine: #188569]
	DB:DBBAH/bodb02

*/

USE bodb02
GO

	--truncate table BalanceRecord_Diff_20230914_tmp
	 
	IF NOT EXISTS ( select top 1 1 from sys.objects where name = 'BalanceRecord_Diff_20230914_tmp' )
	BEGIN
		CREATE TABLE BalanceRecord_Diff_20230914_tmp (ID INT IDENTITY(1,1) PRIMARY KEY , custid INT , SiteDBGroupID SMALLINT, OrderNo SMALLINT )
	END
	
	DECLARE @batch int = 100000 
	DECLARE @StartRow INT = 1 

	----BalanceRecordDiff_SiteDB1_Order2
	SET @StartRow = 1
	WHILE (1=1)
	BEGIN
		INSERT INTO BalanceRecord_Diff_20230914_tmp (custid, SiteDBGroupID, OrderNo)
		SELECT  m.custid, 1, 2
		FROM  BalanceRecordDiff_SiteDB1_Order2 m WITH(NOLOCK)
			CROSS APPLY (	SELECT c.custid FROM vw_Customer c WITH(NOLOCK)
							WHERE c.custid = m.custid
								AND c.site IN ('AEUG','Wanbo','Yibo','ZhiFeng032','ig128','NukeGaming','SL88SW','SM88','GoldenF','JBO','KZSW','Diamond','ZhiFeng040','ZhiFeng147','WRServices','ZFRT129','ZFRT166','ZhiFeng009','V03')
						) c
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
			AND b2.balance  <> b1.balance

		IF @@ROWCOUNT < @batch
		BREAK
	
		SET @StartRow = @StartRow + @batch

	END

	---- BalanceRecordDiff_SiteDB1_Order3
	SET @StartRow = 1
	WHILE (1=1)
	BEGIN
		INSERT INTO BalanceRecord_Diff_20230914_tmp (custid, SiteDBGroupID, OrderNo)
		SELECT  m.custid, 1, 3
		FROM  BalanceRecordDiff_SiteDB1_Order3 m WITH(NOLOCK)
			CROSS APPLY (	SELECT c.custid FROM vw_Customer c WITH(NOLOCK)
							WHERE c.custid = m.custid
								AND c.site IN ('AEUG','Wanbo','Yibo','ZhiFeng032','ig128','NukeGaming','SL88SW','SM88','GoldenF','JBO','KZSW','Diamond','ZhiFeng040','ZhiFeng147','WRServices','ZFRT129','ZFRT166','ZhiFeng009','V03')
						) c
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




	  