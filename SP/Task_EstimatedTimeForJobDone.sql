USE bodb02
GO

ALTER PROCEDURE dbo.Task_EstimatedTimeForJobDone @IsMoveBet BIT
	, @CurrentDateTime DATETIME
	, @TotalMoveBetDays TINYINT = 1
AS
/*
	Created: 20160908@Patrick
	Task: Task - Record endtime for MovingBet & ArchivingBet Jobs
	DB: DBTXN/bodb02
	Revisions:

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
