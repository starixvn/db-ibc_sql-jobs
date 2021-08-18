/*<info serverAlias="DB042-ServiceBrokerDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_SBQueueStatusCheck_EmailNofify]
AS
/*
	Task: Email admins to notify about Service Broker Calculation queue has been disable
	Created: 20150919@Daniel
	Original: 
	DB: DB042.ServiceBrokerDB
	Revision: 
		-20191127@Patrick: Setup sync status ticket on DB052 -> DB054 - [Redmine: #124482]

*/
BEGIN
	SET NOCOUNT ON
	-- SEND warning email to DBA
	DECLARE @body VARCHAR(2000), @profile_name SYSNAME

	SELECT 1 FROM sys.service_queues WHERE NAME = 'Queue_Settled_Ticket_BETRUNNING' AND is_receive_enabled = 0

	IF @@ROWCOUNT = 0 RETURN

	SET @body = '[Service Broker]@'+ @@Servername +': Sync Settled Ticket Queue from DBGAE to DB042''s status was DISABLED. Please check urgently!'

	--PRINT @body

	EXEC msdb.dbo.sp_send_dbmail
		@recipients = N'dbaadmin@starixsoft.com',
		@body = @body,
		@sensitivity = 'Personal',
		@importance = 'Normal',				
		@copy_recipients = 'dbaadmin@starixsoft.com',
		@subject = 'Service Broker Alert',
		@profile_name = @profile_name
END

GO