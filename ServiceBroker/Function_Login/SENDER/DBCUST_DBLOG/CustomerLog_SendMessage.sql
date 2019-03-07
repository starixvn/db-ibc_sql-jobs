/*<info serverAlias="DBCUST-bodb_CustomerLog,DBLOG-bodb_CustomerLog" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView,bodbExtAccNet" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROC sb.CustomerLog_SendMessage 
(	
	@xml xml = null
	, @functionName VARCHAR(100) = 'Login'
	, @MessageType VARCHAR (200) = ''
	, @SB_error BIT = 0 OUTPUT
)
AS
/*
	Created By: Helen
	Created Date: 20161102
	Task: Apply Service broker - [Redmine: 65806]
	DB: DBCUST/bodb_CustomerLog; DBLOG/bodb_CustomerLog
		
	Revision:
		- 20190222@Johnson: grant permission for bodbAdminNet [redmined: #103547]
	-- For testing
	SET @xml = '<row UserID="0" RoleID="0" SubAccID="0" ServerID="0" IP="10.19.10.112" LogDate="2012-04-16T09:32:18.123" ActionID="1310" Doing="Account:12BETRMB01 - Login Result:Failed (User_Not_Found)" DomainName="10.18.200.201" BrowserName="Firefox 3.6" Platform="Windows NT" CountryCode="-" Duration="423" />'
*/

BEGIN
	
	SET NOCOUNT ON
	DECLARE @handle UNIQUEIDENTIFIER,@contractName VARCHAR(200)
	DECLARE @errorCode INT = 0, @errorMessage VARCHAR(MAX) = ''
	
	SET @contractName = (SELECT TOP 1 ContractName FROM sb.ConfigurationReferenceDetail WITH (NOLOCK) WHERE FunctionName=@functionName AND MessageType = @MessageType)
	
	EXEC [Sb].[ConversationPick] @functionName = @functionName,@contractName=@contractName,@handle = @handle  out
	
	IF @handle IS NULL
	BEGIN
		SET @SB_error = 1
		RETURN
	END
	ELSE 
	BEGIN
		EXEC [sb].MsgSent @handle = @handle, @xml = @xml,@MessageType = @MessageType, @errorCode = @errorCode OUT, @errorMessage =  @errorMessage OUT
		IF @errorCode <> 0
			SET @SB_error = 1
		ELSE 
			SET @SB_error = 0	
	END
	
	SET NOCOUNT OFF
	
END
GO

