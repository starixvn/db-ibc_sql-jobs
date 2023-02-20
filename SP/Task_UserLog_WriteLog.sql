/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Task_UserLog_WriteLog]
	@MessageBody XML
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
	DECLARE @__errorMessage VARCHAR(2000)

	BEGIN TRY
		
		INSERT INTO dbo.Task_UserLog(userid, doing, logdate, servername)
		SELECT t.c.value('@userId','int') AS userId
			,t.c.value('@doing','nvarchar(512)') AS doing
			,t.c.value('@logdate','datetime') AS logdate
			,t.c.value('@servername','varchar(128)') AS servername
		FROM @MessageBody.nodes('Task_UserLog/r') t(c)
		OPTION (OPTIMIZE FOR (@MessageBody = NULL))

	END TRY
	BEGIN CATCH
		SELECT @__errorMessage = ERROR_MESSAGE()
			
		INSERT INTO sb.FailedMessageMonitoring(FunctionName, Message, ErrorMessage, TableName, MessageType, CreatedDate, IsResolved)
		VALUES ('UserLog', CAST(@MessageBody AS NVARCHAR(MAX)), @__errorMessage, 'Task_UserLog','MessageType_UserLog', GETDATE(), 0)
			
		--send email / notofication ==> let another job handle
	END CATCH

END