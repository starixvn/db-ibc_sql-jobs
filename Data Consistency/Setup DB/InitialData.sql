/*
	Created: 20180808@Kathy
	Task: Initial conversation 
	DB: DBTP/bodb_Consistency

	
*/
DECLARE @Id			INT = 1
	,@handle		UNIQUEIDENTIFIER

	,@fromService	SYSNAME = N'Service_DataConsistency'
	,@toService		SYSNAME = N'Service_DataConsistency'
	,@onContract	SYSNAME = N'Contract_DataConsistency'
	,@messageType	SYSNAME = N'MessageType_DataConsistency'

WHILE (1=1)
BEGIN
	BEGIN DIALOG @handle
	FROM SERVICE @fromService
	TO SERVICE @toService
	ON CONTRACT @onContract
	WITH ENCRYPTION=OFF;

	INSERT INTO DBA_ConversationHandle (id, ConversationHandle) VALUES (@Id, @handle)

	IF @Id = 5
		BREAK

	SET @Id = @Id + 1
END
