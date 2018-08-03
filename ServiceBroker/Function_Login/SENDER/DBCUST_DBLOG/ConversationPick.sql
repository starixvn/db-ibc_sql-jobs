ALTER PROC [Sb].[ConversationPick]
( 
	@functionName VARCHAR(100)
  , @ContractName VARCHAR(200)	
  , @handle UNIQUEIDENTIFIER OUT
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
	DECLARE @ConversationNo INT
		  , @Cnt INT
			  
	SELECT @Cnt = Cnt
	FROM sb.ConversationCount WITH (NOLOCK)
	WHERE FunctionName = @functionName AND contractName = @ContractName
	
	SET @Cnt = ISNULL(@Cnt, 0)
	
	IF @Cnt = 0
	BEGIN
		SET @handle = NULL
		RETURN
	END
	
	SET @ConversationNo = @@SPID % @Cnt + 1
	
	SELECT @handle = ConversationHandle
	FROM sb.ConversationManagement WITH (NOLOCK)
	WHERE FunctionName = @functionName
			AND contractName = @ContractName
			AND ConversationNo = @ConversationNo 
			AND IsValid = 1	  	  
	  
	SET NOCOUNT OFF  

		  
END
GO

GO
--GRANT EXECUTE ON [Sb].[ConversationPick] TO [bodbRMSNet]
GO
GRANT EXECUTE ON [Sb].[ConversationPick] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [Sb].[ConversationPick] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [Sb].[ConversationPick] TO [bodbExtAccNet]
GO
GRANT EXECUTE ON [Sb].[ConversationPick] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [Sb].[ConversationPick] TO [vnteam] AS [dbo]


