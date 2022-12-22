SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE	[dbo].[Task_EstimatedTimeForJobDone] @IsMoveBet BIT
	, @CurrentDateTime DATETIME
	, @TotalMoveBetDays TINYINT = 1
AS
/*
	Created: 20160908@Patrick
	Task: Task - Record endtime for MovingBet & ArchivingBet Jobs
	DB: DBTXN/bodb02

	Revisions:
		- 20160908@Patrick:	Initialize - [Redmine: #000000]
		- 20221216@Patrick: Balance-Up support transfer 247 [RedmineID: #173554]
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @Duration INT, @EndTime DATETIME--, @TotalDays TINYINT
	SELECT @Duration = 0
	
	IF @IsMoveBet = 0 --BU
	BEGIN
		--get BU's duration from config
		SELECT @Duration = CAST(ISNULL(VValue, '240') AS INT)
		FROM dbo.MBUSettings WITH(NOLOCK)
		WHERE VName = 'schMovingArchivingBetDuration'

		--set default value if null
		IF ISNULL(@Duration, 0) = 0
			SET @Duration = 240

		SELECT @EndTime = DATEADD(MINUTE, @Duration, @CurrentDateTime)

		UPDATE dbo.MBUSettings WITH(ROWLOCK, UPDLOCK)
		SET VValue = CONVERT(VARCHAR(50), @EndTime, 121)
		WHERE VName = 'schDataProcessingEndTime'
		
	END
	ELSE --incase moving bet
	BEGIN

		--get MB's duration from config
		SELECT @Duration = CAST(ISNULL(VValue, '60') AS INT)
		FROM dbo.SystemSettings WITH(NOLOCK)
		WHERE VName = 'schMovingBetDuration'

		--set default value if null
		IF ISNULL(@Duration, 0) = 0
			SET @Duration = 60

		SELECT @Duration = @TotalMoveBetDays * @Duration

		SELECT @EndTime = DATEADD(MINUTE, @Duration, @CurrentDateTime)

		UPDATE dbo.SystemSettings WITH(ROWLOCK, UPDLOCK)
		SET VValue = CONVERT(VARCHAR(50), @EndTime, 121)
		WHERE VName = 'schDataProcessingEndTime'

	END
	
END
GO
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/