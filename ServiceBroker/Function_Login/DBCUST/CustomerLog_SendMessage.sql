ALTER PROC sb.CustomerLog_SendMessage 
(	
	@xml xml = null
	, @functionName VARCHAR(100) = 'Login'
	, @MessageType VARCHAR(200) ='MessageType_CustomerLog_UserLog_Login'
	, @SB_error BIT = 0 OUTPUT
)
AS
/*
	Created By: Helen
	Created Date: 20161102
	Task: Apply Service broker - [Redmine: 65806]
	DB: DBCUST/ CUSTDB
		
	Revision:
	
	-- For testing
	SET @xml = '<row UserID="0" RoleID="0" SubAccID="0" ServerID="0" IP="10.19.10.112" LogDate="2012-04-16T09:32:18.123" ActionID="1310" Doing="Account:12BETRMB01 - Login Result:Failed (User_Not_Found)" DomainName="10.18.200.201" BrowserName="Firefox 3.6" Platform="Windows NT" CountryCode="-" Duration="423" />'
*/

BEGIN
	DECLARE @handle UNIQUEIDENTIFIER
	
	EXEC [Sb].[ConversationPick] @functionName = @functionName,@handle = @handle  out
	
	IF @handle IS NULL
	BEGIN
		SET @SB_error = 1
		RETURN
	END
	ELSE 
	BEGIN
		EXEC [sb].MsgSent @handle = @handle, @xml = @xml,@MessageType = @MessageType
		SET @SB_error = 0
	END
END