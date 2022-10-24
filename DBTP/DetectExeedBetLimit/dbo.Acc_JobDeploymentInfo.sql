/*<info serverAlias="DBTP-bodb02" executers="" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE dbo.Acc_JobDeploymentInfo
	@JobName		VARCHAR(100)
	,@WaitingTime	VARCHAR(10) 	OUTPUT
	,@IsWaiting		BIT		OUTPUT
AS
/*
	Created by: 20221024@July
	Task: Modify job DetectBet [Redmine:#177701]
	DB: DBTP/bodb02
	
	Revisions:
		- 20221024@July: Create new SP [Redmine:#177701]
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @tmpJobInfo TABLE (JobName VARCHAR(100), WaitingTime VARCHAR(10), IsWaiting BIT DEFAULT (0))

	SET @WaitingTime = '00:00:05'
	SET @IsWaiting = 0

	---1.
	INSERT INTO @tmpJobInfo (JobName, WaitingTime, IsWaiting)
	SELECT 'DBA: Task_DetectBet_TicketExceededBetLimit', '00:00:05', 0

	SELECT @WaitingTime = WaitingTime
			,@IsWaiting = IsWaiting
	FROM	@tmpJobInfo
	WHERE	JobName = @JobName

END
GO