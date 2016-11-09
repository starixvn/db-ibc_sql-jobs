ALTER PROC [Sb].[MsgSent]
(
	@xml xml
	, @handle uniqueidentifier
	, @MessageType VARCHAR(200)
	, @errorCode INT = 0  OUT
	, @ErrorMessage VARCHAR(MAX) = '' OUT
)
AS
/*
	Create By: Helen
	Created Date: 20161028
	Task: Apply Service Broker for Writing Log - [Redmine: 65806]
	DB: DBCUST/bodb_CustomerLog; DBLOG/bodb_CustomerLog
	
	Para's explaination
*/

BEGIN
	
	SET NOCOUNT ON
	-- Send message 
	DECLARE @sql_string NVARCHAR(MAX) = ''
	SET @sql_string='SEND ON CONVERSATION @handle
					 MESSAGE TYPE ' + @MessageType + '(@xml)'
	BEGIN TRY
			EXEC SP_EXECUTESQL @sql_string,N'@handle uniqueidentifier, @xml xml', @handle, @xml
		PRINT @sql_string
	END TRY
	
	BEGIN CATCH
		SET @errorCode = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE()
	END CATCH
	
	SET NOCOUNT OFF
	
END

GO
GRANT EXECUTE ON [Sb].[MsgSent] TO [bodbRMSNet]
GO
GRANT EXECUTE ON [Sb].[MsgSent] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [Sb].[MsgSent] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [Sb].[MsgSent] TO [bodbExtAccNet]
GO
GRANT EXECUTE ON [Sb].[MsgSent] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [Sb].[MsgSent] TO [vnteam] AS [dbo]
