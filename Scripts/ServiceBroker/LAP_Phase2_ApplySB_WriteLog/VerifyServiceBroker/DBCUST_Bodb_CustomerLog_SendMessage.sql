/*<info serverAlias="DBCUST-bodb_CustomerLog" executers="" viewers="" isFunction="0"></info>*/
/*
	Create By: Helen
	Created Date: 20200903
	Task: process message for userlog_RunSP [redmine: #139238]
	DB: DBCUST/bodb_CustomerLog

	
*/
--- send message to verify service broker set up
----------------- 1.1 Contract_CustomerLog_UserLog_RunSP ----------------------
DECLARE @SBDialog uniqueidentifier
DECLARE @Message NVARCHAR(128)

DECLARE @handle UNIQUEIDENTIFIER

SET @handle = (SELECT TOP 1 ConversationHandle
				FROM sb.ConversationManagement WITH (NOLOCK)
				WHERE FunctionName = 'UserLog_Others'
						AND contractName = 'Contract_CustomerLog_UserLog_RunSP'
						AND IsValid = 1
			)			

-- Send messages on Dialog
IF @handle IS NOT NULL
BEGIN
	SET @Message = N'Hello - LAP Phase 2';
	SEND ON CONVERSATION @handle
	MESSAGE TYPE MessageType_CustomerLog_UserLog_RunSP (@Message)

END
ELSE
	PRINT 'No conversation'
GO

