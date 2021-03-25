/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_TicketSettledSumChecking]
	@ProductId		INT
	,@Duration 		VARCHAR(50) 
	,@ErrCode		INT			 = 0	OUTPUT
	,@ErrMsg		VARCHAR(MAX) = ''	OUTPUT 
	,@SampleData	VARCHAR(MAX) = ''	OUTPUT
AS
/*
	Created: 20210324@July
	Task: Data consistency
	DB: DBCONSISTENCY-bodb_Consistency

	Revisions: 
		- 20210324@July: Check tickets in bettransRNG/BettransLC are sum to bettrans [Redmine:#151680]
	
	Param's Expanation:
		@Duration = 'hour', 'lastday'
*/
BEGIN
	DECLARE @transId	VARCHAR(MAX)
			,@Today		DATETIME 
			,@tablename	VARCHAR(50)	 = NULL

	SET @transId = ''
	SET @Today = CAST(GETDATE() AS DATE)

	IF @ProductId IN (170, 243) -- PP Live Casino, SexyGaming
	BEGIN
		SET @tablename = 'bettransLC'

		SELECT TOP (100) @transId = @transId + ',' + CAST(b.transId AS VARCHAR)
		FROM bodb02.dbo.bettransLC b WITH(NOLOCK)
		WHERE ProductID = @ProductId
			  AND b.IsSum = 1 
			  AND DATEDIFF(MINUTE,b.transdate,@Today) > 15 
	END

	IF @ProductId IN (238, 247)-- Habanero, SpadeGaming
	BEGIN
		SET @tablename = 'bettransRNG'

		SELECT TOP (100) @transId = @transId + ',' + CAST(b.transId AS VARCHAR)
		FROM bodb02.dbo.bettransRNG b WITH(NOLOCK)
		WHERE ProductID = @ProductId
			  AND b.IsSum = 1 
			  AND DATEDIFF(MINUTE,b.transdate, @Today) > 15
	END

	IF @transId <> ''
	BEGIN
		SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
				,@ErrCode = 100
				,@ErrMsg = 'Wrong check tickets in bettransRNG/BettransLC are sum to bettrans on product ' + CAST(@ProductId AS VARCHAR)
				,@SampleData = @tablename + '.TransId in (' + @transId + ')'
	END

END
