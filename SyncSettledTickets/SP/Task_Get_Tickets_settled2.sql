/*<info serverAlias="DBAGE-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Get_Tickets_settled2]
	@batchSize int = 500
AS
/*
	20180621 @ Viet
	Task: Sync status of tickets
	DB: DBAGE.bodb02
	Revisions: 
		-20191127@Patrick: Setup sync status ticket on DB052 -> DB054 - [Redmine: #124482]
*/
BEGIN
	--RETURN
	SET NOCOUNT ON

	DECLARE @MaxRowId BIGINT, @LastRowId BIGINT, @TransIDs VARCHAR(MAX)
	
	SELECT @LastRowId = sValue
	FROM dbo.Tickets_settled_setting WITH(NOLOCK)
	WHERE sKey = 'TransitionId'
	
	SELECT @MaxRowId = MAX(RowId)
	FROM dbo.BetSettled_Transition WITH(NOLOCK)

	SELECT @LastRowId = ISNULL(@LastRowId, 0), @MaxRowId = ISNULL(@MaxRowId, 0)
	IF (@LastRowId = @MaxRowId) RETURN -- no row

	--wait for all trans can commit
	WAITFOR DELAY '00:00:00:280'

	DECLARE @RowIds TABLE (TransId BIGINT)

	INSERT INTO @RowIds(TransId)
	SELECT TransId
	FROM dbo.BetSettled_Transition WITH(NOLOCK)
	WHERE RowId > @LastRowId AND RowId <= @MaxRowId
	GROUP BY TransId
			
	DECLARE @__TmpIds TABLE(TransId BIGINT)
	DECLARE @MessageData NVARCHAR(MAX), @ErrorCode BIT = 0, @Retry INT = 0, @xml XML
	WHILE 1 = 1
	BEGIN
		DELETE @__TmpIds
		SELECT @TransIDs = NULL, @ErrorCode = 0, @Retry = 0, @xml = NULL

		DELETE TOP(@batchSize) @RowIds
		OUTPUT DELETED.TransId INTO @__TmpIds

		IF @@ROWCOUNT = 0
			BREAK

		SELECT @TransIDs = COALESCE(@TransIDs + ',' + CAST(TransId AS VARCHAR(50)), CAST(TransId AS VARCHAR(50)))
		FROM @__TmpIds

		SET @xml = N'<root><r>' + REPLACE(@TransIDs, ',', '</r><r>') + '</r></root>'
		
		Retry:
		EXEC sb.Settled_Ticket_SendMessage @xml = @xml, @ContractName = 'Contract_Settled_Ticket', @SB_error = @ErrorCode OUTPUT
		
		IF @ErrorCode > 0
		BEGIN

			SET @Retry = @Retry + 1
			IF @Retry > 10
				BREAK

			WAITFOR DELAY '00:00:00:280'
			GOTO Retry
			
		END
		--wait for all trans can commit
		WAITFOR DELAY '00:00:00:010'
	END

	IF @ErrorCode = 0
	BEGIN
		UPDATE dbo.Tickets_settled_setting WITH(ROWLOCK, UPDLOCK) 
		SET sValue = @MaxRowId
		WHERE sKey = 'TransitionId'
	END
END
GO
