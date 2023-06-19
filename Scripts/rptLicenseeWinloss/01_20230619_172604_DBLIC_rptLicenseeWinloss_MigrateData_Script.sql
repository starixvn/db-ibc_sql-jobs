/*<info serverAlias="DBLIC-bodb_LicenseeReport"></info>*/
/*
	Created: 20230619@Bobby
	Task: 172604 - LAP - Winloss Analysis - Migrate data
	DB: DBLIC.bodb_LicenseeReport
	Remark: 
		- Step 1: Import data from DB053 to DB052
		- Step 2: Run Re-index on both servers
*/
USE bodb_LicenseeReport;
GO
/**
Step 1: Import data from DB053 to DB052 by using import wizard
	- From DB052.bodb_LicenseeReport -> TRUNCATE TABLE rptLicenseeWinloss
	- From DB052.bodb_LicenseeReport -> Task -> Import Data wizard
	- Source: DB053.bodb_LicenseeReport
	- Target: DB052.bodb_LicenseeReport 
	- Chose the option "Write a query to specify the data to transfer"
		-> Paste SELECT * FROM dbo.rptLicenseeWinloss WITH(NOLOCK) WHERE Winlostdate <= '2023-06-14'
	- Chose destination table is rptLicenseeWinloss with "Append rows"
	- Check mapping columns
	- Run import wizard
**/

---------------------------------------
/**
- Step 2: Run Re-index on both servers
**/

--select cmd.*
--from sys.column_store_row_groups rg
--inner join sys.indexes i on i.object_id = rg.object_id and i.index_id = rg.index_id
--cross apply (
--	SELECT  CONCAT('ALTER INDEX ', i.name, ' ON dbo.', OBJECT_NAME(rg.object_id), ' REORGANIZE PARTITION=', rg.partition_number, ' WITH(COMPRESS_ALL_ROW_GROUPS = ON);') AS Command
--	UNION ALL
--	SELECT 'GO'
--) as cmd
--where state = 1
--order by partition_number desc --> the current is the 1st partition

--Command
-- Ignore the current one
--ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=42 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
--GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=41 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=40 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=39 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=38 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=37 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=36 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=35 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=34 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=33 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=32 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=31 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=30 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=29 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=28 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=27 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=26 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=25 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=24 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=23 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=22 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=21 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=20 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=19 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=18 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=17 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=16 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=15 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=14 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=13 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=12 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=11 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=10 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=9 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=8 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=7 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=6 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=5 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=4 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=3 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=2 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO
ALTER INDEX CCI_rptLicenseeWinloss ON dbo.rptLicenseeWinloss REORGANIZE PARTITION=1 WITH(COMPRESS_ALL_ROW_GROUPS = ON);
GO