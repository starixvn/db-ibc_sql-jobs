/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[UserLog_Process_Message_Wrapper]
	@MessageBody XML
AS
/*  
	Create: Patrick@20230317
	Task: Write logs UserLog data via ssb service
	DB: DBLOG/bodb_CustomerLog
	
	Para's explaination
	
	Revision:
		- 20230317@Patrick: Init [redmine: #173554]
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @__tableName varchar(200)

	--get root node value
	SELECT @__tableName = CAST(c.query('local-name(/*[1])') AS VARCHAR(128))
	FROM @MessageBody.nodes('.') t(c)

	IF @__tableName = 'Task_UserLog'
	BEGIN
		EXEC dbo.Task_UserLog_WriteLog @MessageBody = @MessageBody
	END
	--add more table here...
END