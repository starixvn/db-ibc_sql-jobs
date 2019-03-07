/*
	Created By: Johnson
	Created Date: 20181031
	Task: Initial conversations for service UserLog_Credit
	DB: DBCUST/bodb_CustomerLog	
*/
USE bodb_CustomerLog
GO
DELETE FROM [sb].[ConfigurationReference] WHERE [FunctionName] = 'UserLog_Others'
GO
DELETE FROM [sb].[ConfigurationReferenceDetail] WHERE [FunctionName] = 'UserLog_Others'
GO
DELETE FROM [sb].[ConversationCount] WHERE [FunctionName] = 'UserLog_Others'
GO
DELETE FROM [sb].[ConversationManagement] WHERE [FunctionName] = 'UserLog_Others'
GO
INSERT INTO [sb].[ConfigurationReference]([FunctionName],[MaxReceiveMsg],[MaxReceiveTimeOut])
VALUES('UserLog_Others',100,200)
GO
--[sb].[ConfigurationReferenceDetail]

INSERT INTO [sb].[ConfigurationReferenceDetail]([FunctionName],[ContractName],[MessageType],[MinConversation],[MaxConversation])
VALUES ('UserLog_Others','Contract_CustomerLog_UserLog_Credit','MessageType_CustomerLog_UserLog_Credit',5,20)
	
GO

--grant permission for bodbAdminNet
GRANT EXECUTE ON sb.CustomerLog_SendMessage TO [bodbAdminNet] AS [dbo]
GO

--open conversations on DBCUST
EXEC [Sb].[ConversationManagement_Upd] 
		@functionName = 'UserLog_Others'
	  , @contractName = 'Contract_CustomerLog_UserLog_Credit'		  
	  , @fromService = 'Service_UserLog_Others_DBCUST'
	  , @toService = 'Service_UserLog_Others_DBLOG'
	  , @newCnt = 10
	  
GO

----- CHECKING DATA ------------------

SELECT * FROM [sb].[ConfigurationReference] WITH (NOLOCK) WHERE FunctionName = 'UserLog_Others'	  

SELECT * FROM [sb].[ConfigurationReferenceDetail] WITH (NOLOCK)	WHERE FunctionName = 'UserLog_Others'	 

SELECT * FROM [sb].[ConversationCount] WITH (NOLOCK) WHERE FunctionName = 'UserLog_Others'	 	 

SELECT * FROM [Sb].[ConversationManagement] WITH (NOLOCK) WHERE FunctionName = 'UserLog_Others'	 	 

SELECT s.name, e.far_service, e.is_initiator
			 , e.conversation_handle, e.conversation_id
			 , e.conversation_group_id, e.state, e.state_desc
			 , e.send_sequence
			 , e.system_sequence
FROM sys.conversation_endpoints e WITH(NOLOCK)
	INNER JOIN sys.services s WITH(NOLOCK) on e.service_id = s.service_id	
WHERE s.name like 'Service_UserLog_Others%'	

