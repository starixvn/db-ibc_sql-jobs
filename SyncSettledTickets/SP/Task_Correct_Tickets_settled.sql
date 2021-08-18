/*<info serverAlias="DB042-ServiceBrokerDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_Correct_Tickets_settled]
AS
/*
	20180621 @ Patrick
	DB: DB042/ServiceBrokerDB
	Revisions: 
		-20191127@Patrick: Setup sync status ticket on DB052 -> DB054 - [Redmine: #124482]
*/
BEGIN
	SET NOCOUNT ON

	CREATE TABLE #__RowIds([Id] [uniqueidentifier], message_body NVARCHAR(MAX), RowId INT IDENTITY(1,1))
	INSERT INTO #__RowIds(Id, message_body)
	SELECT Id, CAST(message_body AS NVARCHAR(MAX))
	from sb.[SettedTicketLogs] WITH(NOLOCK)
	where creationTime > DATEADD(DAY, -1, GETDATE()) AND creationTime < DATEADD(MINUTE, -1, GETDATE())
		AND message_error IS NOT NULL
		AND message_error <> ''
		AND ISNULL(try_count, 0) < 1

	IF @@ROWCOUNT = 0
		RETURN

	DECLARE @RowId INT = 1, @Id UNIQUEIDENTIFIER, @message_body NVARCHAR(MAX), @ErrorCode INT = 0

	WHILE EXISTS (SELECT TOP 1 1 FROM #__RowIds WHERE RowId = @RowId)
	BEGIN
		SELECT @Id = Id, @message_body = message_body FROM #__RowIds WHERE RowId = @RowId
		SET @RowId = @RowId + 1

		EXEC bodb02.[sb].[Task_Update_SettleTickets] @TransIDs = @message_body, @ErrorCode = @ErrorCode OUTPUT

		--if @ErrorCode = 0 OR @ErrorCode = 114
		BEGIN
			UPDATE sb.SettedTicketLogs with(rowlock, updlock)
			SET  message_error = '', try_count = ISNULL(try_count, 0) + 1
			WHERE Id = @Id and message_error IS NOT NULL
		END
	END
	DROP TABLE #__RowIds
END

GO


