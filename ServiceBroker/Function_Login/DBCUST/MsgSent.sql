ALTER PROC [Sb].[MsgSent]
(
	@xml xml
	, @handle uniqueidentifier
	, @MessageType VARCHAR(200)
)
AS
/*
	Create By: Helen
	Created Date: 20161028
	Task: Apply Service Broker for Writing Log - [Redmine: 65806]
	DB: DBCUST/CUSTDB & DBLOG/bodb_CustomerLog 
	
	Para's explaination
*/

BEGIN
	
	SET NOCOUNT ON
	-- Send message 
	DECLARE @sql_string NVARCHAR(MAX) = ''
	SET @sql_string='SEND ON CONVERSATION @handle
					 MESSAGE TYPE ' + @MessageType + '(@xml)'
	
	
	exec sp_executesql @sql_string,N'@handle uniqueidentifier, @xml xml', @handle, @xml
	print @sql_string
	
	SET NOCOUNT OFF
	
END