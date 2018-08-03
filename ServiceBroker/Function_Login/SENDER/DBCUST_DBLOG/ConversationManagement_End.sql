ALTER PROC [Sb].[ConversationManagement_End]
(
	@functionName VARCHAR(100) = 'Login'
	, @ContractName VARCHAR(200) = ''
)
AS
/*
	Create By: Kent
	Created Date: 20161028
	Task: Apply Service Broker for Writing Log - [Redmine: 65806]
	DB: DBCUST/bodb_CustomerLog; DBLOG/bodb_CustomerLog
	
	Para's explaination
*/
BEGIN
	SET NOCOUNT ON 

	DECLARE @Conversation_tmp AS TABLE (ID INT IDENTITY(1,1), handle UNIQUEIDENTIFIER)	
	DECLARE @max_conversation INT, @min_Conversation INT = 1, @cnt INT, @handle UNIQUEIDENTIFIER
	
	SELECT @cnt = Cnt
	FROM sb.ConversationCount WITH (NOLOCK)
	WHERE FunctionName = @functionName AND ContractName = @ContractName
	
	INSERT INTO @Conversation_tmp (handle)
	SELECT ConversationHandle
	FROM sb.ConversationManagement WITH (NOLOCK)
	WHERE FunctionName = @functionName AND ContractName = @ContractName AND ConversationNo > @cnt 
	
	IF EXISTS (SELECT 1 FROM @Conversation_tmp)
	BEGIN
		SET @max_conversation = (SELECT MAX(ID) FROM @Conversation_tmp)
		WHILE @min_Conversation <= @max_conversation
		BEGIN
			SELECT @handle = handle
			FROM @Conversation_tmp
			WHERE ID = @min_Conversation
			
			BEGIN TRY
				END CONVERSATION @handle
			END TRY
			
			BEGIN CATCH
				PRINT ' Invalid Handle'
			END CATCH
			SET @min_Conversation = @min_Conversation + 1
		END
		
		DELETE FROM sb.ConversationManagement WITH(ROWLOCK)
		WHERE FunctionName = @functionName
			  AND ContractName = @ContractName
			  AND ConversationNo > @cnt 
	END	
	
	SET NOCOUNT OFF
	
END
GO


