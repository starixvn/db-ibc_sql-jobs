USE [bodb_Consistency]
GO
/*	
	Created:20180912@Kathy
	DB: DBTP/bodb_Consistency
	Task: Data consistency checking
*/

CREATE PROCEDURE [dbo].[DBA_Consistency_MessageReceive]
AS
BEGIN
	SET NOCOUNT ON
END
GO

CREATE MESSAGE TYPE [MessageType_DataConsistency] VALIDATION = NONE
GO

CREATE CONTRACT [Contract_DataConsistency] ([MessageType_DataConsistency] SENT BY ANY)
GO

ALTER AUTHORIZATION ON CONTRACT::[Contract_DataConsistency] TO [dbo] 

CREATE QUEUE [dbo].[Queue_DataConsistency] WITH STATUS = ON , RETENTION = OFF , ACTIVATION (  STATUS = ON , PROCEDURE_NAME = [dbo].[DBA_Consistency_MessageReceive] , MAX_QUEUE_READERS = 10 , EXECUTE AS OWNER  ), POISON_MESSAGE_HANDLING (STATUS = ON) 

CREATE SERVICE [Service_DataConsistency]  ON QUEUE [dbo].[Queue_DataConsistency]  ([Contract_DataConsistency])
