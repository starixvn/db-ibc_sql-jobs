/*<info serverAlias="DBN88-bodb_N88"></info>*/
/*
	Created: 20200604@Percy
	DB: DBN88-bodb_N88
	Task: Add new columns TpUserName (Saba Username2), TpSystemUserName (Saba Username)

	Step 3: Initialize data
*/

DECLARE @QueueID INT
SELECT TOP 1 @QueueID = QueueID FROM dbo.API_Queue WITH (NOLOCK) WHERE DataSource = 'Customer'
ORDER BY QueueId DESC

DECLARE @p1 INT = 0, @p2 VARCHAR(1000) = ''
EXEC Task_API_Queue_Customer @QueueIDInput = @QueueID, @ErrCode = @p1 OUTPUT, @ErrMsg = @p2 OUTPUT
SELECT @p1, @p2
