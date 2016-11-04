ALTER PROC [Sb].[ConversationPick]
( 
	@functionName VARCHAR(100)
  , @handle UNIQUEIDENTIFIER OUT
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
	DECLARE @ConversationNo INT
		  , @Cnt INT
			  
	SELECT @Cnt = Cnt
	FROM sb.ConversationCount WITH (NOLOCK)
	WHERE FunctionName = @functionName
		
	IF @Cnt = 0
	BEGIN
		SET @handle = NULL
		RETURN
	END
	
	SET @ConversationNo = @@SPID % @Cnt + 1
	
	SELECT @handle = ConversationHandle
	FROM sb.ConversationManagement WITH (NOLOCK)
	WHERE FunctionName = @functionName
			AND ConversationNo = @ConversationNo  AND IsValid = 1	  	  
	  
	SET NOCOUNT OFF  
	  
END
GO

