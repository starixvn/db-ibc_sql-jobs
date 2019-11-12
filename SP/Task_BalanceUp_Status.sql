/*<info serverAlias="DBEXT-bodb02,DBAGE-bodb02,DBACC-bodb02" executers="vnteam" viewers="" isFunction="0" isNested="1"></info>*/
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

*/

BEGIN
	DECLARE @OldBUDate			SMALLDATETIME
		, @NewBUDate			SMALLDATETIME
		, @MinArchiveDate		SMALLDATETIME
		, @MaxArchiveDate		SMALLDATETIME
	
	DECLARE @IsArchivingBetName	VARCHAR(50)
		, @IsArchivingBetValue	INT
		, @StartMovingName		VARCHAR(50)
		, @EndMovingName		VARCHAR(50)
		, @StartMovingTime		DATETIME
		, @EndMovingTime		DATETIME
		, @CheckTime			DATETIME
	
	-- the list of archiving date
	SELECT @MaxArchiveDate		= MAX(winlostdate)
		,@MinArchiveDate		= MIN(winlostdate)
	FROM DBTXN.bodb02.dbo.Task_ArchiveDate WITH(NOLOCK)

	-- the newest BU date
	SELECT @OldBUDate			= MIN(winlostdate)
		, @NewBUDate			= MAX(winlostdate)
	FROM dbo.bettrans WITH(NOLOCK)
	WHERE matchid = 0 AND bettype = 20000
	
	SELECT @StatusID			= 1
		, @IsArchivingBetName	= 'isArchivingBet_Local'
		, @StartMovingName		= 'StartMoving_Local'
		, @EndMovingName		= 'EndMoving_Local'
		, @CheckTime			= GETDATE()
	
	SELECT @IsArchivingBetValue	=  CASE 
								WHEN VName = @IsArchivingBetName THEN CAST(VValue AS INT) ELSE @IsArchivingBetValue END
		, @StartMovingTime		= CASE 
								WHEN VName = @StartMovingName THEN CAST(VValue AS DATETIME) ELSE @StartMovingTime END
		, @EndMovingTime		= CASE 
								WHEN VName = @EndMovingName THEN CAST(VValue AS DATETIME) ELSE @EndMovingTime END
	FROM dbo.SystemSettings WITH (NOLOCK)
	WHERE VName IN (@StartMovingName, @EndMovingName, @IsArchivingBetName)

	SELECT @StatusID			= CASE 
								WHEN @IsArchivingBetValue <> 0 OR @OldBUDate <> @NewBUDate THEN 1 -- BU is in progress
								WHEN @IsArchivingBetValue = 0 AND @NewBUDate <= @MinArchiveDate THEN 0 -- BU has not started YET
								WHEN @IsArchivingBetValue = 0 AND @CheckTime >= @StartMovingTime AND @StartMovingTime <= @EndMovingTime THEN 0 -- BU has completed

								ELSE 99 -- BU unknown
							END 
END
GO