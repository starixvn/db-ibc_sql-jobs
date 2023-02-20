/*<info serverAlias="DBTXN-bodb_CustomerLog" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE dbo.Task_UserLog_SendMessage
	@userId INT,
	@doing nvarchar(512),
	@logdate datetime = null,
	@servername varchar(128) = null
/*
	Create: Patrick@20230317
	Task: Write logs UserLog data via ssb service
	DB: DBTXN/bodb_CustomerLog
	
	Para's explaination
	
	Revision:
		- 20230317@Patrick: Init [redmine: #139238]
		
*/
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @__xmlData XML, @__error BIT = 0

	IF @logdate IS NULL
	BEGIN
		SELECT @logdate = GETDATE()
	END

	IF @servername IS NULL
	BEGIN
		SELECT @servername = @@SERVERNAME
	END

	SELECT @__xmlData = (
		SELECT @userId AS '@userId'
			, @doing AS '@doing'
			, @logdate AS '@logdate'
			, @servername AS '@servername'
		FOR XML PATH('r'), ROOT('Task_UserLog')
	)

	--send data to ssb
	BEGIN TRY
		EXEC sb.CustomerLog_SendMessage @xml = @__xmlData
			, @functionName = 'UserLog'
			, @MessageType = 'MessageType_UserLog'
			, @SB_error = @__error OUTPUT
			
		IF @__error <> 0
		BEGIN
			INSERT INTO dbo.Task_UserLog(userid, doing, logdate, servername)
			VALUES(@userId, @doing, @logdate, @servername)
		END
	END TRY
	BEGIN CATCH
			INSERT INTO dbo.Task_UserLog(userid, doing, logdate, servername)
			VALUES(@userId, @doing, @logdate, @servername)
	END CATCH

END
GO