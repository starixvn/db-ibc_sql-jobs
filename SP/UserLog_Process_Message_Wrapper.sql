ALTER PROCEDURE [dbo].[UserLog_Process_Message_Wrapper]
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
	DECLARE @__tableName varchar(200)

	--get root node value
	SELECT @__tableName = c.query('local-name(/*[1])')
	FROM @MessageBody.nodes('.') t(c)

	IF @__tableName = 'UserLog'
	BEGIN
		EXEC dbo.Task_UserLog_WriteLog @MessageBody = @MessageBody
	END
	--add more table here...
END