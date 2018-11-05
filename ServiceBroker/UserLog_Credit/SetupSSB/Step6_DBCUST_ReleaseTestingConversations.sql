/*
	Create By: Johnson	
	Created Date: 20181102
	Task: release testing conversations for UserLog_Credit service
	DB: dblog/bodb_CustomerLog; dbcust/bodb_CustomerLog
	
*/

USE bodb_CustomerLog
GO
WHILE(1=1)
BEGIN
	RECEIVE TOP (1) * FROM dbo.Queue_UserLog_Credit
	IF @@ROWCOUNT = 0 BREAK;	
END

CREATE TABLE #sb_temp (ID INT IDENTITY (1,1), name VARCHAR(100),handle UNIQUEIDENTIFIER)

INSERT INTO #sb_temp (name,handle)
SELECT s.name, e.conversation_handle
from sys.conversation_endpoints e WITH(NOLOCK)
	inner join sys.services s WITH(NOLOCK) on e.service_id = s.service_id
WHERE e.far_service LIKE 'Service_UserLog_Credit_DBCUST' AND e.is_initiator = 1

SELECT * FROM #sb_temp

DECLARE @end INT, @start INT = 1, @handle UNIQUEIDENTIFIER

SET @end = (SELECT MAX(ID) FROM #sb_temp)
IF EXISTS (SELECT 1 FROM #sb_temp)
BEGIN
	WHILE @start <= @end
	BEGIN
		SET @handle = (SELECT handle FROM #sb_temp WHERE ID= @start)
		PRINT 'Deleted handle:' + CAST(@handle AS VARCHAR(MAX))
		END CONVERSATION @handle WITH CLEANUP
		
		SET @start = @start + 1 
	END
END	



DROP TABLE #sb_temp