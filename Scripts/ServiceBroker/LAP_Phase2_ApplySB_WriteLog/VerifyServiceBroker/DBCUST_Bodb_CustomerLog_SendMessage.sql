/*<info serverAlias="DBCUST-bodb_CustomerLog" executers="" viewers="" isFunction="0"></info>*/
/*
	Create By: Helen
	Created Date: 20200903
	Task: process message for userlog_RunSP [redmine: #139238]
	DB: DBCUST/bodb_CustomerLog

	
*/
--- send message to verify service broker set up
----------------- Step 1- Send sample message ----------------------
DECLARE @log xml, @SB_Error BIT = 0
SELECT @log = (SELECT 0 as '@UserID',
					2612 '@ActionID',
					'' AS '@TrackingValue',						
					'' AS '@TrackingValue2',
					GETDATE() AS '@LogDate',
					 0 AS '@Duration'
				FOR XML PATH('Row')	
			)
EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @log, 
												@MessageType='MessageType_CustomerLog_UserLog_RunSP', 
												@functionName = 'UserLog_Others',
												@SB_Error = @SB_Error out

SELECT @SB_Error

----------------- Step 1- heck data in dblog/bodb_CustomerLog ----------------------

SELECT TOP (1) * from dblog.bodb_CustomerLog.dbo.UserLog_RunSP WITH (NOLOCK)
WHERE ActionID = 2612 and userid = 0

/*
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
*/
