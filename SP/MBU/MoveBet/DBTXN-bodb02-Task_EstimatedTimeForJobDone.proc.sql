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
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @Duration INT, @EndTime DATETIME--, @TotalDays TINYINT
	SELECT @Duration = 0
	
	IF @IsMoveBet = 0 --BU
	BEGIN
		--get BU's duration from config
		SELECT @Duration = CAST(ISNULL(VValue, '240') AS INT)
		FROM dbo.SystemSettings WITH(NOLOCK)
		WHERE VName = 'schMovingArchivingBetDuration'

		--set default value if null
		IF ISNULL(@Duration, 0) = 0
			SET @Duration = 240
		
	END
	ELSE --incase moving bet
	BEGIN
		--DECLARE @MoveBetSchedule TABLE(ScheduleId TINYINT, MoveBetDay SMALLDATETIME)
		--INSERT INTO @MoveBetSchedule(ScheduleId, MoveBetDay)
		--EXEC dbo.Task_MoveBetsDayByScheduleSel

		--SELECT @TotalDays = COUNT(1)
		--FROM @MoveBetSchedule

		--SET @TotalDays = ISNULL(@TotalDays, 0)
		--IF @TotalDays = 0 --no move bet on that day
		--BEGIN
		--	RETURN
		--END

		--get MB's duration from config
		SELECT @Duration = CAST(ISNULL(VValue, '60') AS INT)
		FROM dbo.SystemSettings WITH(NOLOCK)
		WHERE VName = 'schMovingBetDuration'

		--set default value if null
		IF ISNULL(@Duration, 0) = 0
			SET @Duration = 60

		SELECT @Duration = @TotalMoveBetDays * @Duration

	END

	SELECT @EndTime = DATEADD(MINUTE, @Duration, @CurrentDateTime)

	UPDATE dbo.SystemSettings WITH(ROWLOCK, UPDLOCK)
	SET VValue = CONVERT(VARCHAR(50), @EndTime, 121)
	WHERE VName = 'schDataProcessingEndTime'
	
END
GO
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="1"></info>*/