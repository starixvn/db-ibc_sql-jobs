/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_TicketSettledSumChecking]
	@Duration 		VARCHAR(50) 
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
	DECLARE @transId		VARCHAR(MAX) =''
			,@Today			DATETIME 
			,@WinlostDate	SMALLDATETIME
			,@message		VARCHAR(MAX) = '' 
			
	SELECT @SampleData  = '', @ErrMsg = ''

	SET @transId = ''
	SET @Today = CAST(GETDATE() AS DATETIME)

	IF @Duration = 'hour'
	BEGIN
		SELECT @Winlostdate = CONVERT (DATE, GETDATE())  
	END

	IF @Duration = 'lastday'
	BEGIN
		SELECT @Winlostdate = CONVERT (DATE, DATEADD(DAY, -1,GETDATE()))  
	END

	SELECT TOP (100) @transId = @transId + ',' + CAST(b.transId AS VARCHAR)
	FROM bodb02.dbo.bettransLC b WITH(NOLOCK)
	WHERE b.IsSum = 0
		  AND DATEDIFF(MINUTE,b.transdate,@Today) > 15
		  AND b.winlostdate = @WinlostDate
		  AND b.statusID IN (111,112,113) --Draw,won,lose

	SELECT @transId = CASE WHEN @transId <> '' THEN '(' + SUBSTRING(@transId, 2, LEN(@transId) - 1) + ') in bettransLC,' END
	IF @transId <> '' BEGIN  SET @message = @message + @transId END

	SET @transId = ''
	SELECT TOP (100) @transId = @transId + ',' + CAST(b.transId AS VARCHAR)
	FROM bodb02.dbo.bettransRNG b WITH(NOLOCK)
	WHERE b.IsSum = 0
		  AND DATEDIFF(MINUTE,b.transdate, @Today) > 15
		  AND b.winlostdate = @WinlostDate
		  AND b.statusID IN (111,112,113) --Draw,won,lose
	
	SELECT @transId = CASE WHEN @transId <> '' THEN '(' + SUBSTRING(@transId, 2, LEN(@transId) - 1) + ') in bettransRNG,' END
	IF @transId <> '' BEGIN  SET @message = @message + @transId END

	IF @message <> ''
	BEGIN
		SELECT	@transId = SUBSTRING(@transId, 2, LEN(@transId) - 1)
				,@ErrCode = 100
				,@ErrMsg = @ErrMsg + 'Settled ticket in bettransRNG/BettransLC are not yet summed to bettrans ' + Char(10) + Char(13)
				,@SampleData = @SampleData+ 'Settled ticket in bettransRNG/BettransLC are not yet summed to bettrans ' + @message + '. '+ Char(10) + Char(13)
	END
END

GO