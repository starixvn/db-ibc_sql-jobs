/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_Consistency_CheckWinlosDate]
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
		- 20210524@July: Check winlostdate to current date [Redmine:#98064]
	
	Param's Expanation:
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @transId_112 VARCHAR(MAX),  @transId_113 VARCHAR(MAX)
			,@Today DATETIME 

	DECLARE @tmpMatchIds TABLE (MatchId INT)
	
	SET @transId_112 = ''
	SET @transId_113 = ''
	SET @Today = CAST(GETDATE() AS DATE)

	IF @ProductId = 200 -- Saba.Club
	BEGIN
		SELECT TOP (100) @transId_112 = @transId_112 + ',' + CAST(transId AS VARCHAR)
		FROM bodb02.dbo.bettransRNG WITH(NOLOCK) 
		WHERE
			((aWinLost <> (winlost - actual_stake) * -apositiontaking) or (mWinLost <> (winlost - actual_stake) * -mpositiontaking) or (sWinLost <> (winlost - actual_stake) * -spositiontaking)) 
			AND statusid = 112
			AND productid = @ProductId
			AND winlostdate = @Today

		SELECT TOP (100) @transId_113 = @transId_113 + ',' + CAST(transId AS VARCHAR)
		FROM bodb02.dbo.bettransRNG WITH(NOLOCK) 
		WHERE
			((aWinLost <> -(winlost-actual_stake) * apositiontaking) or (mWinLost <> -(winlost-actual_stake) * mpositiontaking) or (sWinLost <> -(winlost-actual_stake) * spositiontaking)) 
			AND statusid = 113
			AND productid = @ProductId
			AND winlostdate = @Today

	END
	
	IF @transId_112 <> '' OR @transId_112 <> ''
	BEGIN
		IF @transId_112 <> ''
			SET @transId_112= SUBSTRING(@transId_112, 2, LEN(@transId_112) - 1)
		IF @transId_113 <> ''
			SET @transId_113= SUBSTRING(@transId_113, 2, LEN(@transId_113) - 1)

		SELECT	 @ErrCode = 100
				,@ErrMsg = 'Checking winlostdate in settled ticket on product ' + CAST(@ProductId AS VARCHAR)
				,@SampleData = case when @transId_112 <> '' then  'bettransRNG.TransId (status=112)= ' + @transId_112 else '' end + ' ' 
							+ case when @transId_113 <> '' then  'bettransRNG.TransId (status=113)= ' + @transId_113 else '' end
	END

END
GO