/*<info serverAlias="DBCUST-bodb_CustomerLog" executers="" viewers="" isNested="0"></info>*/
CREATE proc [dbo].[Task_DBA_Monitor_ServiceBroker] @IsDebug bit = 0
/* 
	Created:20170418@Patrick
    Task: this sp used to monitor service broker for writing log
		- check message enqueu in transmission queue
		- check conversation has been cleanup
		- check conversation enpoint has been closed or error
		- check queue disable or not
    DB: DB054/DB053.bodb02
	Revision:
		- 20171204@Patrick: Ingore check state in ('CD', 'ER', 'DI', 'DO') for settlement service ('//Service/Calculation_receive', '//Service/Calculation_send') - [Redmine: #000000]
		- 20190524@Billy:	Change Letstalk linked server - [Redmine: #113125]
		- 20201022@Patrick: Change email to starixvn [Redmine: #143607]

	Description:
		
    Param's Explaination:    
	
*/
as
begin
	set nocount on
	--check message inqueue greater than 10 minutes
	declare @errCount int, @interval int
	set @interval = 239
	select @errCount = count(1)
	from sys.transmission_queue with(nolock)
	where enqueue_time < dateadd(minute, @interval, getdate())

	declare @table1 varchar(max), @table2 varchar(max), @table3 varchar(max), @table4 varchar(max), @hasError bit
	select @table1 = '', @table2 = '', @table3 = '', @table4 = '', @hasError = 0

	if @errCount > 0
	begin
		declare @rowData varchar(max)
		set @table1 = '<p>Having {errCount} messages enqueue in transmission queue greater than 10 minutes.</p>
		<table>
		  <tr>
			<th style="text-align:center" nowrap>Transmission Status</th>
			<th style="text-align:center" nowrap>Enqueue Time</th>
			<th style="text-align:center" nowrap>Message Type Name</th>
			<th style="text-align:center" nowrap>Service Contract Name</th>
			<th style="text-align:center" nowrap>From Service Name</th>
			<th style="text-align:center" nowrap>To Service Name</th>
		  </tr>
		  {<row>}
		</table>'

		set @rowData = convert(varchar(max), (select transmission_status as 'td1'
													, enqueue_time as 'td2'
													, message_type_name as 'td1'
													, service_contract_name as 'td2'
													, from_service_name as 'td1'
													, to_service_name as 'td2'
												from sys.transmission_queue with(nolock)
												where enqueue_time < dateadd(minute, @interval, getdate())
												order by enqueue_time
												for xml path('tr'), type
												))
		set @rowData = replace(replace(@rowData, 'td1>', 'td>'), 'td2>', 'td>')
		set @table1 = replace(@table1, '{<row>}', @rowData)
		set @table1 = replace(@table1, '{errCount}', @errCount);
	
		set @hasError = 1
	end

	--check conversation has been cleanup
	set @errCount = 0
	select @errCount = count(1)
	from sb.ConversationManagement m with(nolock)
	where not exists (select top 1 1 
						from sys.conversation_endpoints e with(nolock)
						where e.conversation_handle = m.ConversationHandle and e.is_initiator = 1)
	if @errCount > 0
	begin
		declare @rowData2 varchar(max)
		set @table2 = '<hr />
		<p>Having {errCount} conversation has been cleanup.</p>
		<table>
		  <tr>
			<th style="text-align:center" nowrap>Function Name</th>
			<th style="text-align:center" nowrap>Contract Name</th>
			<th style="text-align:center" nowrap>Conversation Handle</th>
			<th style="text-align:center" nowrap>Conversation No</th>
		  </tr>
		  {<row>}
		</table>'

		set @rowData2 = convert(varchar(max), (select ISNULL(FunctionName, '-') as 'td1'
													, ISNULL(ContractName, '-') as 'td2'
													, ISNULL(cast(ConversationHandle as varchar(50)), '-') as 'td1'
													, ISNULL(ConversationNo, '-') as 'td2'
												from sb.ConversationManagement m with(nolock)
												where not exists (select top 1 1 
																	from sys.conversation_endpoints e with(nolock)
																	where e.conversation_handle = m.ConversationHandle and e.is_initiator = 1)
												order by ConversationNo
												for xml path('tr'), type
												))
		set @rowData2 = replace(replace(@rowData2, 'td1>', 'td>'), 'td2>', 'td>')
		set @table2 = replace(@table2, '{<row>}', @rowData2)
		set @table2 = replace(@table2, '{errCount}', @errCount);
	
		set @hasError = 1
	end

	--check conversation endpoint has been closed or error
	set @errCount = 0
	select @errCount = count(1)
	from sys.conversation_endpoints e with(nolock)
	where state in ('CD', 'ER', 'DI', 'DO') and e.far_service not in ('//Service/Calculation_receive', '//Service/Calculation_send')
	and conversation_handle in (select handle from sb.DialogPool) --- lukas comment out to avoid fake alarm


	if @errCount > 0
	begin
		declare @rowData3 varchar(max)
		set @table3 = '<hr />
		<p>Having {errCount} conversation endpoint has been closed or error.</p>
		<table>
		  <tr>
			<th style="text-align:center" nowrap>State Desc</th>
			<th style="text-align:center" nowrap>Conversation Handle</th>
			<th style="text-align:center" nowrap>Message Type Name</th>
			<th style="text-align:center" nowrap>Contract Name</th>
			<th style="text-align:center" nowrap>Service Name</th>
			<th style="text-align:center" nowrap>Far Service Name</th>
		  </tr>
		  {<row>}
		</table>'

		set @rowData3 = convert(varchar(max), (select state_desc as 'td1'
													, conversation_handle as 'td2'
													, isnull(smt.name, '-') as 'td1' --as message_type_name
													, isnull(sc.name, '-') as 'td2' --as [contract_name]
													, isnull(s.name, '-') as 'td1' --as [service_name]
													, e.far_service as 'td2' --as 'far_service_name'
												from sys.conversation_endpoints e with(nolock)
													left join sys.service_contract_message_usages scmu with(nolock) on e.service_contract_id = scmu.service_contract_id
													left join sys.service_contracts sc with(nolock) on scmu.service_contract_id = sc.service_contract_id
													left join sys.service_message_types smt with(nolock) on scmu.message_type_id = smt.message_type_id
													left join sys.services s with(nolock) on e.service_id = s.service_id
												where e.state in ('CD', 'ER', 'DI', 'DO') and e.far_service not in ('//Service/Calculation_receive', '//Service/Calculation_send')
												for xml path('tr'), type
												))
		set @rowData3 = replace(replace(@rowData3, 'td1>', 'td>'), 'td2>', 'td>')
		set @table3 = replace(@table3, '{<row>}', @rowData3)
		set @table3 = replace(@table3, '{errCount}', @errCount);
		--select @rowData3 as '@rowData3', @table3 as '@table3'
		set @hasError = 1
	end

	--check queue disable or not
	set @errCount = 0
	select @errCount = count(1)
	from sys.service_queues e with(nolock)
	where is_receive_enabled = 0

	if @errCount > 0
	begin
		declare @rowData4 varchar(max)
		set @table4 = '<hr />
		<p>Having {errCount} queue disabled.</p>
		<table>
		  <tr>
			<th style="text-align:center" nowrap>Queue Name</th>
		  </tr>
		  {<row>}
		</table>'

		set @rowData4 = convert(varchar(max), (select name as 'td1'
												from sys.service_queues with(nolock)
												where is_receive_enabled = 0
												order by name
												for xml path('tr'), type
												))
		set @rowData4 = replace(replace(@rowData4, 'td1>', 'td>'), 'td2>', 'td>')
		set @table4 = replace(@table4, '{<row>}', @rowData4)
		set @table4 = replace(@table4, '{errCount}', @errCount);
		--select @rowData3 as '@rowData3', @table3 as '@table3'
		set @hasError = 1
	end

	declare @email_body nvarchar(max), @subject nvarchar(200)
	select @subject	= N'DBA - Monitoring service broker objects - KBT@' + @@SERVERNAME
	set @email_body = '
		<html>
			<body>
  			<style>
				table {border-collapse: collapse;}
				table, td, th {border: 1px solid black;}
				/*tr:nth-child(even) {background-color: #f2f2f2}*/
				th {text-align: left; padding: 8px;}
				/*th {background-color: #4CAF50; color: white;}*/
			</style>

			<h1>DBA - Monitoring service broker objects!</h1>
			<p><b>Check time: ' + convert(varchar(50), getdate(), 121) + '</p>
			<div style="background-color:red;color:white;text-align:center">Failure</div>
    
			<p></p>
			{<table1>}
			{<table2>}
			{<table3>}
			{<table4>}
			</body>
		</html>'
	--select @email_body as '@email_body1', @table1 as '@table1', @table2 as '@table2', @table3 as '@table3'
	set @email_body = replace(@email_body, '{<table1>}', @table1)
	set @email_body = replace(@email_body, '{<table2>}', @table2)
	set @email_body = replace(@email_body, '{<table3>}', @table3)
	set @email_body = replace(@email_body, '{<table4>}', @table4)

	if @IsDebug = 0 and @hasError = 1
	begin
		execute msdb.dbo.sp_send_dbmail @profile_name	= DEFAULT
			, @recipients			 = 'pontus@starixvn.com'
			, @copy_recipients		 = ''
			, @blind_copy_recipients = ''
			, @subject				 = @subject
			, @body					 = @email_body
			, @body_format			 = 'HTML';
		
		--send message to lestalk
		declare @lestalkMessage varchar(200)
		set @lestalkMessage = 'wake up,..wake up! Service broker of Settlement/TOControl on ['+ @@SERVERNAME +'].['+ DB_NAME() +'] database got problem.'
		EXECUTE	DBNOTI.NotificationDB.dbo.DBA_Letstalk_NewJobMessage @ServerName = 'PONTUS'
			  , @JobId  = NULL
			  , @JobName = 'Custom Message'
			  , @Message = @lestalkMessage

	end

	if @IsDebug = 1
	begin
		select @email_body as '@email_body'
	end
end
GO


