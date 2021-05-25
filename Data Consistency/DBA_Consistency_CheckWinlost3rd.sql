/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_CheckWinlost3rd]
	@ProductId		INT		
	,@ErrCode		INT				= 0		OUTPUT
	,@ErrMsg		VARCHAR(MAX)	= ''	OUTPUT 
	,@SampleData	VARCHAR(MAX)	= ''	OUTPUT
AS
/*
	Created: 20210524@July
	Task: Data consistency
	DB: DBCONSISTENCY-bodb_Consistency

	Revisions: 
		- 20210524@July: Saba.club - Check winlost - Check Data Consistency - [Redmine:#155714]
	
	Param's Expanation:
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @transId VARCHAR(MAX)
			,@Today DATETIME 

	DECLARE @tmpMatchIds TABLE (MatchId INT)
	
	SET @transId = ''
	SET @Today = CAST(GETDATE() AS DATE)

	IF @ProductId = 200 -- Saba.Club
	BEGIN
		SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM bodb02.dbo.bettransRNG WITH(NOLOCK) 
		WHERE
			((aWinLost <> (winlost - actual_stake) * -apositiontaking) or (mWinLost <> (winlost - actual_stake) * -mpositiontaking) or (sWinLost <> (winlost - actual_stake) * -spositiontaking)) 
			AND statusid = 112
			AND productid = @ProductId
			AND winlostdate = @Today

		SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM bodb02.dbo.bettransRNG WITH(NOLOCK) 
		WHERE
			((aWinLost <> -(winlost-actual_stake) * apositiontaking) or (mWinLost <> -(winlost-actual_stake) * mpositiontaking) or (sWinLost <> -(winlost-actual_stake) * spositiontaking)) 
			AND statusid = 113
			AND productid = @ProductId
			AND winlostdate = @Today

	END
	
	IF @transId <> ''
	BEGIN
		SELECT	 @transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
				,@ErrCode = 100
				,@ErrMsg = 'Checking data of swinlost, mwinlost, swinlost in settled ticket on product ' + CAST(@ProductId AS VARCHAR)
				,@SampleData =  'bettransRNG.TransId in (' + @transId + ')'
	END

END
GO