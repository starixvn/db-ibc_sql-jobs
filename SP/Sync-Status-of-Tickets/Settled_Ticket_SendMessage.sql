/*<info serverAlias="DBAGE-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [sb].[Settled_Ticket_SendMessage]
(	
		@Xml XML = NULL
	,	@FunctionName VARCHAR(100) = 'BETRUNNING'
	,	@ContractName VARCHAR(100) = ''
	,	@SB_error BIT = 0 OUTPUT
)
AS
/*
	Create By: 20180625@Patrick
	Task: Apply Service Broker for Bet Running function
	DB: DBAGE.bodb02 
		
	Revision
		- 20180508@Helen: Hardcode messagetype to have better performance [Redmine: N/A]
		-20191127@Patrick: Setup sync status ticket on DB052 -> DB054 - [Redmine: #124482]
		
	Para's explaination
*/

BEGIN
	
	SET NOCOUNT ON
	DECLARE @Handle UNIQUEIDENTIFIER, @MessageType VARCHAR (200)
	DECLARE @ErrorCode INT = 0, @ErrorMessage VARCHAR(MAX) = ''
	
	IF @ContractName = 'Contract_Settled_Ticket' 
		SET @MessageType = 'MessageType_Settled_Ticket'
	
	EXEC sb.ConversationPick @FunctionName = @FunctionName, @ContractName = @ContractName, @Handle = @Handle OUT
	
	IF @Handle IS NULL
	BEGIN
		SET @SB_error = 1
		RETURN
	END
	ELSE
	BEGIN
		EXEC sb.MsgSent @Handle = @Handle, @Xml = @Xml, @MessageType = @MessageType , @ErrorCode = @ErrorCode OUT, @ErrorMessage =  @ErrorMessage OUT
		IF @ErrorCode <> 0
			SET @SB_error = 1
		ELSE 
			SET @SB_error = 0	
	END
	
END

GO
