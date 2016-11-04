ALTER PROC [Sb].[ConversationDel]
(
	@functionName VARCHAR(100) = 'Login',
	@handle  UNIQUEIDENTIFIER = null 
	
)
AS
/*
	Create By: Kent
	Created Date: 20161028
	Task: Apply Service Broker for Writing Log - [Redmine: 65806]
	
	Para's explaination
*/
BEGIN
	SET NOCOUNT ON 

	DECLARE @Conversation_tmp AS TABLE (ID INT IDENTITY(1,1), handle UNIQUEIDENTIFIER)	
	DECLARE @max_conversation INT, @min_Conversation INT = 1, @cnt INT
	
	SELECT @cnt = Cnt
	FROM sb.ConversationCount WITH (NOLOCK)
	WHERE FunctionName = @functionName
	
	INSERT INTO @Conversation_tmp (handle)
	SELECT ConversationHandle
	FROM sb.ConversationManagement WITH (NOLOCK)
	WHERE FunctionName = @functionName AND ConversationNo >= @cnt 
	
	IF EXISTS (SELECT 1 FROM @Conversation_tmp)
	BEGIN
		
		SET @max_conversation = (SELECT MAX(ID) FROM @Conversation_tmp)
				
		WHILE @min_Conversation <= @max_conversation
		BEGIN
			SELECT @handle = handle
			FROM @Conversation_tmp
			WHERE ID = @min_Conversation
			
			BEGIN TRY
				END CONVERSATION @handle --WITH CLEANUP
			END TRY
			
			BEGIN CATCH
				PRINT ' Invalid Handle'
			END CATCH
			SET @min_Conversation = @min_Conversation + 1
		END
		
		DELETE FROM sb.ConversationManagement
		WHERE FunctionName = @functionName
			  AND ConversationNo >= @cnt 
	END	
	
	SET NOCOUNT OFF
	
END
GO


