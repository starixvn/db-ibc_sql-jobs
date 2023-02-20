/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[UserLog_Process_Message]
AS
/*  
	Create: Patrick@20230317
	Task: Write logs UserLog data via ssb service
	DB: DBLOG/bodb_CustomerLog
	
	Para's explaination
	
	Revision:
		- 20230317@Patrick: Init [redmine: #139238]
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @__messageBody xml, @__tableName varchar(200)
	WHILE 1 = 1
	BEGIN
		WAITFOR (RECEIVE TOP(1) @__messageBody = CAST(message_body AS XML)
			FROM dbo.queue_UserLog
		), TIMEOUT 100

		IF @@ROWCOUNT = 0
			RETURN

		EXEC dbo.UserLog_Process_Message_Wrapper @MessageBody = @__messageBody
	END
END
