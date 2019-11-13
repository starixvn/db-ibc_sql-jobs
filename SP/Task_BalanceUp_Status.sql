/*<info serverAlias="DBEXT-bodb02,DBAGE-bodb02,DBACC-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_BalanceUp_Status]
	@StatusID TINYINT = 0 OUTPUT
AS

/*
	Created by: 20191111@Bobby
    Task: BU has done yet?
    DB: DBEXT-bodb02,DBAGE-bodb02,DBACC-bodb02

	Revisions:
		- 20191111@Bobby: Initialize SP [RedmineID: #83787]
	
	Parameters Explanations:
		@StatusID = 0 --> BU has commpleted
		@StatusID = 1 --> BU has not commpleted yet (is running)
		@StatusID = 2 --> BU has not START yet
		@StatusID = 99 --> BU Unknown Status

*/

BEGIN
	DECLARE @BUDate				DATE
		, @OldBUDate			DATE
		, @NextBUDate			DATE
		, @CheckDate			DATE
		, @CheckWeekday			TINYINT
		, @WeekdayRunBU			TINYINT
		, @diffDayWithBUDate	INT

	DECLARE @IsArchivingBetName	VARCHAR(50)
		, @IsArchivingBetValue	INT
		, @StartMovingName		VARCHAR(50)
		, @EndMovingName		VARCHAR(50)
		, @StartMovingTime		DATETIME
		, @EndMovingTime		DATETIME
		, @CheckTime			DATETIME
		
	-- the BU date - 6-Friday
	SELECT @BUDate				= MAX(winlostdate)
		,@OldBUDate				= MIN(winlostdate)
	FROM dbo.bettrans WITH(NOLOCK)
	WHERE matchid = 0 AND bettype = 20000
	
	SELECT @StatusID			= 1
		, @IsArchivingBetName	= 'isArchivingBet_Local'
		, @StartMovingName		= 'StartMoving_Local'
		, @EndMovingName		= 'EndMoving_Local'
		, @CheckTime			= GETDATE()
		, @CheckDate			= CAST(@CheckTime AS DATE)
		, @NextBUDate			= DATEADD(DD, 7, @OldBUDate)
		, @CheckWeekday			= DATEPART(WEEKDAY, @CheckDate)
		, @WeekdayRunBU			= DATEPART(WEEKDAY, @BUDate) - 1 -- current is 5-Thurday
		, @diffDayWithBUDate	= DATEDIFF(DD, @BUDate, @CheckDate)
	
	SELECT @IsArchivingBetValue	=  CASE 
								WHEN VName = @IsArchivingBetName THEN CAST(VValue AS INT) ELSE @IsArchivingBetValue END
		, @StartMovingTime		= CASE 
								WHEN VName = @StartMovingName THEN CAST(VValue AS DATETIME) ELSE @StartMovingTime END
		, @EndMovingTime		= CASE 
								WHEN VName = @EndMovingName THEN CAST(VValue AS DATETIME) ELSE @EndMovingTime END
	FROM dbo.SystemSettings WITH (NOLOCK)
	WHERE VName IN (@StartMovingName, @EndMovingName, @IsArchivingBetName)

	--- SET BU status
	SELECT @StatusID			= CASE 
									WHEN @CheckWeekday <> @WeekdayRunBU THEN 0 -- NOT BU day
									WHEN @CheckWeekday = @WeekdayRunBU THEN -- is BU Day
										CASE 
											WHEN @IsArchivingBetValue <> 0 OR @OldBUDate <> @BUDate THEN 1 -- BU is running
											WHEN @IsArchivingBetValue = 0 AND @diffDayWithBUDate > 10 AND @NextBUDate <> @BUDate THEN 2 -- BU has not started YET
											WHEN @IsArchivingBetValue = 0 
													AND @diffDayWithBUDate < 10
													AND @OldBUDate = @BUDate
													AND @CheckTime >= @StartMovingTime AND @StartMovingTime <= @EndMovingTime 
												THEN 0 -- BU has completed
											ELSE 99 -- BU unknown - DELAY
										END
									ELSE 99 -- BU unknown - DELAY
								END 
END
GO