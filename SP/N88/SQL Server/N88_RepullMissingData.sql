/*<info serverAlias="DBN88-bodb_N88" executers="bodbLicenseeNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[N88_RepullMissingData]
AS

/*
	Created: 20230424@Malcolm
	DB: DBN88-bodb_N88
	Task: MPA - Get Bonus Info

	Revisions:
		- 20230424@Malcolm: Initialize SP [RedmineID: #186979]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @BatchSize INT = 400

	DECLARE @Queue TABLE (QueueId INT PRIMARY KEY)

	INSERT INTO @Queue (QueueId)
	SELECT TOP(@BatchSize) QueueId
	FROM dbo.API_QueueTest WITH(NOLOCK)
	WHERE IsFinished = 0 
	ORDER BY QueueId ASC

	INSERT INTO dbo.API_QUEUE
	(
		CheckInTime
		,FinishedTime
		,IsFinished
		,XmlData
		,DataSource
		,LogDesc
	)
	SELECT 
		GETDATE()
		,NULL
		,IsFinished
		,XmlData
		,REPLACE(DataSource, 'Test', '') AS DataSource
		,NULL
	FROM dbo.API_QueueTest a WITH(NOLOCK)
	WHERE EXISTS (SELECT 1 FROM @Queue q WHERE q.QueueId = a.QueueId)

	UPDATE a WITH(ROWLOCK, UPDLOCK)
		SET a.IsFinished = 1
	FROM API_QueueTest a
		INNER JOIN @Queue q ON q.QueueId = a.QueueId

END
GO