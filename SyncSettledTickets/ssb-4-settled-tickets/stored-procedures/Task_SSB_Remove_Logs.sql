USE [ServiceBrokerDB]
GO
/****** Object:  StoredProcedure [dbo].[Task_SSB_Remove_Logs]    Script Date: 7/22/2018 11:23:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Task_SSB_Remove_Logs]
AS
/*
	20180621 @ Patrick
	DB042.bodb02
*/
BEGIN
	SET NOCOUNT ON

	declare @datetimeTmp datetime 
	set @datetimeTmp = dateadd(hour, -2, getdate())

	--for case retry 5 times for the same message_body
	declare @__archive table (message_body nvarchar(max))
	insert into @__archive(message_body)
	select message_body
	from sb.[SettedTicketLogs] with(nolock)
	where creationTime > @datetimeTmp
	group by message_body
	having count(1) > 5

	update t
	set message_error = '', try_count = 5
	from sb.[SettedTicketLogs] t with(rowlock, updlock)
	where creationTime > @datetimeTmp
		and message_body in (select tt.message_body from @__archive tt)
		
	delete from sb.[SettedTicketLogs] with(rowlock)
	where creationTime < dateadd(day, -3, getdate())
		and (message_error is null or message_error = '')

END
