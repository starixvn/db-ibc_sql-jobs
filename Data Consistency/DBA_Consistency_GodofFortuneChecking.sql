/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_GodofFortuneChecking]
	@ProductId		INT		
	,@ErrCode		INT			 = 0	OUTPUT
	,@ErrMsg		VARCHAR(MAX) = ''	OUTPUT 
	,@SampleData	VARCHAR(MAX) = ''	OUTPUT
AS
/*
	Created: 20201221@July
	Task: Data consistency
	DB: DBCONSISTENCY-bodb_Consistency

	Revisions: 
		- 20201221@July: God of Fortune - Check Data Consistency [Redmine:#147246]
	
	Param's Expanation:
*/
BEGIN
	DECLARE @transId VARCHAR(MAX)
			,@Today DATETIME 

	SET @transId = ''
	SET @Today = CAST(GETDATE() AS DATE)

	IF @ProductId = 1
	BEGIN

		SELECT TOP (100) @transId = @transId + ',' + CAST(b.transId AS VARCHAR)
		FROM bodb02.dbo.bettrans b WITH(NOLOCK)
		WHERE b.matchid = 29 and b.bettype = 29
		AND b.oddsspread = 1
		AND b.actual_stake = b.stake
		AND b.winlostdate >= @Today
	END

	IF @transId <> ''
	BEGIN
		SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
				,@ErrCode = 100
				,@ErrMsg = 'Wrong God of Fortune actual_stake on product ' + CAST(@ProductId AS VARCHAR)
				,@SampleData = 'bettrans.TransId IN (' + @transId +' )'
	END

END
