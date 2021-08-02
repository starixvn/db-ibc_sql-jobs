/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_OutrightChecking]
	@ProductId		INT		
	,@ErrCode		INT			 = 0	OUTPUT
	,@ErrMsg		VARCHAR(MAX) = ''	OUTPUT 
	,@SampleData	VARCHAR(MAX) = ''	OUTPUT
AS
/*
	Created: 20210729@July
	Task: Data consistency
	DB: DBCONSISTENCY-bodb_Consistency

	Revisions: 
		- 20210729@July: Data Consistency - Add new rule for Outright running's win/loss date [Redmine:#159092]
	
	Param's Expanation:
*/
BEGIN
	DECLARE @transId VARCHAR(MAX)
			,@yesterday DATETIME 

	SET @transId = ''
	SET @yesterday = DATEADD(DAY,-1,CAST(GETDATE() AS DATE))

	IF @ProductId = 1
	BEGIN
		SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM bodb02.dbo.bettrans WITH(NOLOCK)
		WHERE winlostdate < @yesterday
		    AND bettype = 10
			AND statusID = 0 --running
	END

	IF @transId <> ''
	BEGIN
		SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
				,@ErrCode = 100
				,@ErrMsg = 'Detect if outright ticket running with winlostdate < yesterday on product ' + CAST(@ProductId AS VARCHAR)
				,@SampleData = 'bettrans.TransId IN (' + @transId +' )'
	END
END
GO