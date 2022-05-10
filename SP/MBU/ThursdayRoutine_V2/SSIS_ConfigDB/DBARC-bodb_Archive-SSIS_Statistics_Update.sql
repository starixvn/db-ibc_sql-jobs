/*<info serverAlias="DBARC-bodb_archive,DBARC-bodb_report,DBAGE-bodb_summary" executers="" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[SSIS_Statistics_Update]
AS
/*
	Created by:	20220506@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]				
	Database:	DBARC-bodb_archive,DBRPT-bodb_report,DBSUM-bodb_summary
	Revisions:
		- 20130831@Bobby: Init
*/
BEGIN
	SET NOCOUNT ON;
	declare @tempStatsCmd TABLE(Idx INT IDENTITY(1,1), TableName VARCHAR(100), StatsCmd VARCHAR(1000));
	;
	with cte_server_dict AS (
		SELECT Alias
		FROM (
			SELECT 'DBSUM' AS Alias, 'DB052' AS [ServerName]
			UNION ALL
			SELECT 'DBSUM' AS Alias, 'DB053' AS [ServerName]
			UNION ALL
			SELECT 'DBRPT' AS Alias, 'DB061' AS [ServerName]
			UNION ALL
			SELECT 'DBRPT' AS Alias, 'DB062' AS [ServerName]
			UNION ALL
			SELECT 'DBARC' AS Alias, 'DB061' AS [ServerName]
			UNION ALL
			SELECT 'DBARC' AS Alias, 'DB062' AS [ServerName]
		) AS s
		WHERE s.ServerName = @@SERVERNAME
	)
	,cte_ssis_table as (
		select * 
			from (
			values 
			('DBSUM','bodb_summary','sum_winloss_old'),
			('DBRPT','bodb_report','Statement'),
			('DBRPT','bodb_report','Statement_Accum'),
			('DBARC','bodb_archive','bettransm'),
			('DBARC','bodb_archive','bettrans_bk'),
			('DBARC','bodb_archive','transfer_bk'),
			('DBARC','bodb_archive','bettransLC_bk'),
			('DBARC','bodb_archive','bettransRnG_bk'),
			('DBARC','bodb_archive','translog_bk'),
			('DBARC','bodb_archive','bettransG'),
			('DBARC','bodb_archive','SettlementNG2_Message_bk'),
			('DBARC','bodb_archive','bettrans_Staging_bk'),
			('DBARC','bodb_archive','transfer_fi'),
			('DBARC','bodb_archive','Transfer_Coll_bk'),
			('DBARC','bodb_archive','BetParlayResult'),
			('DBARC','bodb_archive','TicketVoiding_RequestDetail_bk'),
			('DBARC','bodb_archive','TicketVoiding_Request_bk'),
			('DBARC','bodb_archive','TicketVoiding_AutoVoidRequest_Queue_bk'),
			('DBARC','bodb_archive','TicketVoiding_AutoUnmarkSetting_bk'),
			('DBARC','bodb_archive','TicketVoiding_OperatorInfo_bk'),
			('DBARC','bodb_archive','TicketVoiding_Queue_bk'),
			('DBARC','bodb_archive','TicketVoiding_VoidingHistory_bk'),
			('DBARC','bodb_archive','TicketVoiding_RequestDetailTicket_Single_bk'),
			('DBARC','bodb_archive','TicketVoiding_RequestDetailTicket_SubParlay_bk'),
			('DBARC','bodb_archive','TicketVoiding_Reason_bk'),
			('DBARC','bodb_archive','zzzbettransM_bk'),
			('DBARC','bodb_archive','TicketVoiding_VoidedTransaction_bk'),
			('DBARC','bodb_archive','zzzbettrans_bk'),
			('DBARC','bodb_archive','odds_bk'),
			('DBARC','bodb_archive','match_bk'),
			('DBARC','bodb_archive','bingoBall_bk'),
			('DBARC','bodb_archive','outright_bk'),
			('DBARC','bodb_archive','VSOutright_bk'),
			('DBARC','bodb_archive','match_remark'),
			('DBARC','bodb_archive','MatchMaxbet_bk'),
			('DBARC','bodb_archive','ResultDetail_bk'),
			('DBARC','bodb_archive','ResultDetail3rd_bk'),
			('DBARC','bodb_archive','EventInfo3rd_bk'),
			('DBARC','bodb_archive','AutoPayoutResult_bk'),
			('DBARC','bodb_archive','ProviderResultDetail_bk'),
			('DBARC','bodb_archive','Odds3rd_bk'),
			('DBARC','bodb_archive','Intg_OddsFeed_SettlementAction_bk'),
			('DBARC','bodb_archive','Intg_OddsFeed_SettlementAction_Outright_bk'),
			('DBARC','bodb_archive','Match3rd_bk'),
			('DBARC','bodb_archive','oddsES_bk'),
			('DBARC','bodb_archive','ResultDetailES_bk'),
			('DBARC','bodb_archive','SMP_Market_bk'),
			('DBARC','bodb_archive','SMP_MarketSelection_bk'),
			('DBARC','bodb_archive','Dot_Admin_Assignment_Trader_bk'),
			('DBARC','bodb_archive','oddsOS_bk'),
			('DBARC','bodb_archive','ResultDetailOS_bk'),
			('DBARC','bodb_archive','VSRaceInfo_bk'),
			('DBARC','bodb_archive','ProviderExternalResultDetailES_bk'),
			('DBARC','bodb_archive','ProviderExternalResultDetailOS_bk'),
			('DBARC','bodb_archive','ProviderExternalResultDetail_bk'),
			('DBARC','bodb_archive','AutoRefundResult_bk'),
			('DBARC','bodb_archive','TOControl_Setting_bk'),
			('DBARC','bodb_archive','CashOutSelling_bk')
		) as t(Alias, dbname, name)
	)
	INSERT INTO @tempStatsCmd(TableName, StatsCmd)
	select [Table Name], [CMD]
	FROM (
		SELECT DISTINCT
			t.name AS [Table Name]
				--, i.name as [Index Name], i.type_desc--, i.data_space_id
				, s.name AS [Partition Scheme], p.partition_number, pv.value as range_value ,c.pdate,c.cdate
				--, ROW_NUMBER() OVER(partition by t.name, i.name order by i.type, p.partition_number asc) as pNUM
				, ROW_NUMBER() OVER(partition by t.name ORDER BY p.partition_number asc) as pNUM
		FROM sys.tables t
		inner join cte_ssis_table cte on cte.name = t.name
		inner join cte_server_dict dict ON dict.Alias = cte.Alias
		inner JOIN sys.indexes i ON i.object_id = t.object_id 
		inner join sys.partitions p ON p.index_id = i.index_id and p.object_id = i.object_id
		left JOIN sys.partition_schemes s ON i.data_space_id = s.data_space_id
		left JOIN sys.partition_functions f ON f.function_id = s.function_id
		left JOIN sys.partition_range_values pv ON pv.function_id = f.function_id and pv.boundary_id = p.partition_number
		outer apply (
			select cast(pv.value as date) as pdate, cast(dateadd(DAY,-12,getdate()) as date) as cdate 
		) as c
		where i.type in(1,2)
		and (c.pdate >= c.cdate OR c.pdate IS NULL)
	) as t
	cross apply (
		--select 'UPDATE STATISTICS dbo.' + t.[Table Name]+'(' + t.[Index Name] + ') WITH RESAMPLE' + case when t.[Partition Scheme] is null then ';' else ' ON PARTITIONS('+cast(t.partition_number as varchar(10))+');' end
		select 'UPDATE STATISTICS dbo.' + t.[Table Name]+ ' WITH RESAMPLE' + case when t.[Partition Scheme] is null then ';' else ' ON PARTITIONS('+cast(t.partition_number as varchar(10))+');' end
			--, 'select count(1) from dbo.' + t.[Table Name]+ ' WITH(nolock);'
	) as c(CMD)--, CNT)
	where t.pNUM=1

	--select * from @tempStatsCmd;

	declare @tableName VARCHAR(100), @statsCmd VARCHAR(1000), @idxCnt INT = 1;
	WHILE EXISTS(select 1 FROM @tempStatsCmd WHERE Idx = @idxCnt)
	begin
		select @tableName	= TableName
			,@statsCmd		= StatsCmd
		FROM @tempStatsCmd 
		WHERE Idx = @idxCnt

		EXEC (@statsCmd);

		--select @statsCmd AS [@statsCmd]

		SET @idxCnt += 1;
	end
END
GO
