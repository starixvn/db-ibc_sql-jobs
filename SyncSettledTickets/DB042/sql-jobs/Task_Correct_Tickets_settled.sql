USE [ServiceBrokerDB]
GO

ALTER PROCEDURE [dbo].[Task_Correct_Tickets_settled]
AS
/*
	20180621 @ Patrick
	DB042.bodb02
*/
BEGIN
	SET NOCOUNT ON

	create table #__RowIds([Id] [uniqueidentifier], message_body nvarchar(max), RowId int identity(1,1))
	insert into #__RowIds(Id, message_body)
	select Id, cast(message_body as nvarchar(max))
	from sb.[SettedTicketLogs] with(nolock)
	where creationTime > dateadd(day, -1, getdate()) AND creationTime < dateadd(minute, -1, getdate())
		and message_error is not null
		and message_error <> ''
		and isnull(try_count, 0) < 1

	if @@ROWCOUNT = 0
		return

	declare @RowId int = 1, @Id uniqueidentifier, @message_body nvarchar(max), @ErrorCode int = 0

	while exists (select top 1 1 from #__RowIds where RowId = @RowId)
	begin
		select @Id = Id, @message_body = message_body from #__RowIds where RowId = @RowId
		set @RowId = @RowId + 1

		exec bodb02.[sb].[Task_Update_SettleTickets] @TransIDs = @message_body, @ErrorCode = @ErrorCode OUTPUT

		--if @ErrorCode = 0 OR @ErrorCode = 114
		begin
			update sb.SettedTicketLogs with(rowlock, updlock)
			set  message_error = '', try_count = isnull(try_count, 0) + 1
			where Id = @Id and message_error is not null
		end
	end
	drop table #__RowIds
END
