/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_CheckWinlost3rd]
	 @tablename		VARCHAR(50)		= NULL
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
		- 20210614@July: Saba.club - Missing wrong winlost of yesterday ticket - Check Data Consistency - [Redmine:#156865]
		- 20210924@July: Apply for VGaming product - [Redmine:#161760]
		- 20221003@July: Add new rule to detect bet ticket with draw status - [Redmine:#169699]
		- 20220418@July: Ignore ticket greater than 0.0002 - [Redmine:#169699]
		- 20221205@July: Modify rule #41 for BBIN & SA Gaming - [Redmine:#181299]

	Param's Expanation:
		Notes: For SAGaming(244), BBIN(241) check data in bettransG
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @transId VARCHAR(MAX)
			,@Today SMALLDATETIME
			,@yesterday SMALLDATETIME 

	SET @transId = ''
	SET @Today = CAST(GETDATE() AS DATE)
	SET @yesterday = DATEADD(DAY,-1,CAST(GETDATE() AS DATE))

	IF @tablename = 'bettransRNG'
	BEGIN
		SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM bodb02.dbo.bettransRNG WITH(NOLOCK) 
		WHERE
			(  ABS(aWinLost -(-(winlost-actual_stake) * apositiontaking)) > 0.0002 
			OR ABS(mWinLost -(-(winlost-actual_stake) * mpositiontaking)) > 0.0002
			OR ABS(sWinLost -(-(winlost-actual_stake) * spositiontaking)) > 0.0002
			) 
			AND statusid IN (111, 112, 113) --Draw/Won/Lose
			AND (winlostdate = @Today OR winlostdate = @yesterday) 
			AND gameID NOT IN (2198, 2398, 2998, 1698, 3898, 4297, 4599)
	END
	ELSE IF @tablename = 'bettransLC'
	BEGIN
		SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM bodb02.dbo.bettransLC WITH(NOLOCK) 
		WHERE
			(  ABS(aWinLost -(-(winlost-actual_stake) * apositiontaking)) > 0.0002 
			OR ABS(mWinLost -(-(winlost-actual_stake) * mpositiontaking)) > 0.0002
			OR ABS(sWinLost -(-(winlost-actual_stake) * spositiontaking)) > 0.0002
			) 
			AND statusid IN (111, 112, 113) --Draw/Won/Lose
			AND (winlostdate = @Today OR winlostdate = @yesterday)
			AND productID NOT IN (244)
	END
	ELSE IF @tablename = 'bettransG'
	BEGIN
		SELECT TOP (100) @transId = @transId + ',' + CAST(transId AS VARCHAR)
		FROM bodb02.dbo.bettransG WITH(NOLOCK) 
		WHERE
			(  ABS(aWinLost -(-(winlost-actual_stake) * apositiontaking)) > 0.0002 
			OR ABS(mWinLost -(-(winlost-actual_stake) * mpositiontaking)) > 0.0002
			OR ABS(sWinLost -(-(winlost-actual_stake) * spositiontaking)) > 0.0002
			) 
			AND statusid IN (111, 112, 113) --Draw/Won/Lose
			AND (winlostdate = @Today OR winlostdate = @yesterday)
			AND matchid IN (244, 241)
	END

	IF @transId <> ''
	BEGIN
		SELECT	 @transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
				,@ErrCode = 100
				,@ErrMsg = 'Checking data of swinlost, mwinlost, awinlost in settled ticket on table ' + @tablename
				,@SampleData =  @tablename + '.TransId in (' + @transId + ')'
	END

END
GO