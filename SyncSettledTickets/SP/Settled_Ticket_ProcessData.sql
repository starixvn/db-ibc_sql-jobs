/*<info serverAlias="DB042-ServiceBrokerDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [sb].[Settled_Ticket_ProcessData]
AS
/*
	Create By: 20180625@Patrick
	Task: Apply Service Broker for Bet Running
	DB: DB042/ServiceBrokerDB
	Revision: 
		-20191127@Patrick: Setup sync status ticket on DB052 -> DB054 - [Redmine: #124482]

	Para's explaination
*/
BEGIN
	DECLARE @conversation_handle UNIQUEIDENTIFIER
	DECLARE @message_type SYSNAME
	DECLARE @message_body NVARCHAR(MAX)
	DECLARE @ErrorCode INT = 0
	DECLARE @error_message VARCHAR(4000)

	WAITFOR (
		RECEIVE TOP (1)		   
			@conversation_handle = [conversation_handle],
			@message_type = [message_type_name],
			@message_body = CONVERT(nvarchar(max),[message_body])
		FROM [dbo].[Queue_Settled_Ticket_BETRUNNING]
		), TIMEOUT 100 -- if the queue is empty for 100 miliseconds, give up and go away
					
	IF @@ROWCOUNT = 0
		RETURN
		
	BEGIN TRY
		IF @message_type IN ('MessageType_Settled_Ticket')
		BEGIN	
			DECLARE @starttime datetime
					,@duration int
					,@Id uniqueidentifier

			SET @starttime = CURRENT_TIMESTAMP
			SET @Id = NEWID()
			-- put your code here	
					
			INSERT INTO sb.SettedTicketLogs (Id, message_type, message_body, duration, message_error)
			VALUES (@Id, @message_type, @message_body, NULL, NULL)								
					
			EXEC bodb02.[sb].[Task_Update_SettleTickets] @TransIDs = @message_body, @ErrorCode = @ErrorCode OUTPUT
			IF @ErrorCode > 0
				RAISERROR('Missing data', 16, 1)

			SET @duration = DATEDIFF(MILLISECOND, @starttime, CURRENT_TIMESTAMP)

			INSERT INTO sb.SettedTicketLogs(Id, message_type, message_body, duration, message_error)
			VALUES (@Id, @message_type, @message_body, @duration, NULL)
		END
		ELSE IF @message_type IN ('http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
							  , 'http://schemas.microsoft.com/SQL/ServiceBroker/Error')	
		BEGIN
			END CONVERSATION @conversation_handle
		END
	END TRY
	BEGIN CATCH
		SET @error_message = ERROR_MESSAGE()

		IF XACT_STATE() = -1
		BEGIN
			-- The transaction is doomed. Only rollback possible.
			-- This could disable the queue if done 5 times consecutively!
			ROLLBACK TRANSACTION
		END

		INSERT INTO sb.SettedTicketLogs(Id, message_type, message_body, duration, message_error)
		VALUES (@Id, @message_type, @message_body, NULL, @error_message)

		DECLARE @isQueueEnabled BIT
		SELECT @isQueueEnabled = is_enqueue_enabled
		FROM sys.service_queues WITH(NOLOCK)
		WHERE name = 'Queue_Settled_Ticket_BETRUNNING'

		IF @isQueueEnabled = 0 
			ALTER QUEUE Queue_Settled_Ticket_BETRUNNING WITH STATUS = ON;

	END CATCH	

END
GO