USE [bodb_Archive]
GO
/****** Object:  StoredProcedure [dbo].[TASK_PartionedTable_ArchivedData_Purge]    Script Date: 02/06/2015 05:48:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[TASK_PartionedTable_ArchivedData_Purge]


AS
/*
	Created by: Francis
	CreatedDate: 2014-12-11
	Task: Purge over-18-month data for non-partitioned tables in bodb_Archive 
	DB: DBTP.bodb_Archive

	Revisions:
*/
BEGIN
	set nocount on;
	
	if @@SERVERNAME <> 'DBTP'
		return
	
	declare @purgedTable varchar(255), @stagingTable varchar(255), @partitionNumber int
	declare @purgedDate smalldatetime, @purgedMonth int, @purgedYear int
	declare @sqlexec varchar (4000) = ''
	declare @tmpTable table (purgedTable varchar(255), stagingTable varchar(255), isfinished bit)
	
	--get the first day of the month that is 19-month-ago from the current time 
	select @purgedDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, DATEADD(MONTH,-18,GETDATE())), 0)
	
	select @purgedMonth = MONTH (@purgedDate)
	select @purgedYear = YEAR (@purgedDate)
	
	--Step 1: Create staging tables
	--bettrans_bk, bettransG, bettransm, transfer_bk
	exec DBA_CloneTableStructure
		@SourceSchema = 'dbo',
		@SourceTable = 'bettrans_bk',
		@DestinationTable = 'bettrans_bk_partition',
		@RecreateIfExists = 1,
		@FileGroup = '[ps_BETBK_monthly]([winlostdate])'
		
	exec DBA_CloneTableStructure
		@SourceSchema = 'dbo',
		@SourceTable = 'bettransG',
		@DestinationTable = 'bettransG_partition',
		@RecreateIfExists = 1,
		@FileGroup = '[ps_BETG_monthly]([winlostdate])'
		
	exec DBA_CloneTableStructure
		@SourceSchema = 'dbo',
		@SourceTable = 'bettransm',
		@DestinationTable = 'bettransm_partition',
		@RecreateIfExists = 1,
		@FileGroup = '[ps_BETM_monthly]([winlostdate])'
		
	exec DBA_CloneTableStructure
		@SourceSchema = 'dbo',
		@SourceTable = 'transfer_bk',
		@DestinationTable = 'transfer_bk_partition',
		@RecreateIfExists = 1,
		@FileGroup = '[ps_TRANSBK_monthly]([winlostdate])'
		
	if (select count(1) from sysobjects 
		where name in ('bettrans_bk_partition', 'bettransG_partition', 'bettransm_partition', 'transfer_bk_partition') 
			  and type = 'U') < 4
	begin
		raiserror ('Staging (4) tables have not existed',16,1);
		return
	end
	
	--Step 2: purge partitioned tables
	--bettrans_bk, bettransG, bettransm, transfer_bk
	insert into @tmpTable (purgedTable, stagingTable, isfinished)
		select 'bettrans_bk', 'bettrans_bk_partition', 0
		union all
		select 'bettransG', 'bettransG_partition', 0
		union all
		select 'bettransm', 'bettransm_partition', 0
		union all
		select 'transfer_bk', 'transfer_bk_partition', 0
	while (1=1)
	begin
		update top (1) @tmpTable
		set @purgedTable = purgedTable,
			@stagingTable = stagingTable,
			isfinished = 1
		where isfinished = 0
				
		if @@rowcount = 0
		break;
				
		select top 1 @partitionNumber = p.partition_number
		from sys.tables t
			 inner join sys.partitions p on t.object_id = p.object_id and p.index_id = 1
			 inner join sys.indexes i on p.object_id = i.object_id and p.index_id = i.index_id
			 inner join sys.data_spaces ds on i.data_space_id = ds.data_space_id
			 inner join sys.partition_schemes ps on ds.data_space_id = ps.data_space_id
			 inner join sys.partition_functions pf on ps.function_id = pf.function_id
			 left outer join sys.partition_range_values prv on pf.function_id = prv.function_id and p.partition_number = prv.boundary_id
		 where is_ms_shipped = 0  
			 and exists (select 1 from sys.partitions p2
				         where t.object_id = p2.object_id
					     and partition_number > 1)
			 and t.name = @purgedTable
			 and month(cast(prv.value as smalldatetime)) = @purgedMonth 
			 and year(cast(prv.value as smalldatetime)) = @purgedYear
		 order by p.partition_number
	
		 select @sqlexec = 'alter table ' + @purgedTable + ' switch partition ' + convert(varchar(255),@partitionNumber) 
			             + ' to ' + @stagingTable + ' partition ' + convert(varchar(255),@partitionNumber)
	
	 	 exec (@sqlexec)
	
		 select @sqlexec = 'if exists (select 1 from sys.tables where name = ''' + @stagingTable 
					   + ''') drop table ' + @stagingTable
	
	     exec (@sqlexec)
		
	end
END


GO
GRANT VIEW DEFINITION ON [dbo].[TASK_PartionedTable_ArchivedData_Purge] TO [vnteam] AS [dbo]