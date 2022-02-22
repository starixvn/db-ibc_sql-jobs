/*<info serverAlias="DBBAH-bodb02" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE dbo.Acc_JobDeploymentInfo
	@JobName		VARCHAR(100)
	,@WaitingTime	VARCHAR(10) 	OUTPUT
	,@IsWaiting		BIT		OUTPUT
AS
/*
	Created by: 20220217@Kathy
	Task: Set waiting time for deployment [Redmine:#167296]
	DB: DBBAH/bodb02
	
	Revisions:
		- 20220217@Kathy: Set waiting time for deployment [Redmine:#167296]

*/
BEGIN
	SET NOCOUNT ON

	DECLARE @tmpJobInfo TABLE (JobName VARCHAR(100), WaitingTime VARCHAR(10), IsWaiting BIT DEFAULT (0))

	SET @WaitingTime = '00:01:00'
	SET @IsWaiting = 0

	---1.
	INSERT INTO @tmpJobInfo (JobName, WaitingTime, IsWaiting)
	SELECT 'bodb02 : Task_BalanceRecord_Insert'		, '00:01:00', 0

	SELECT @WaitingTime = WaitingTime
			,@IsWaiting = IsWaiting
	FROM	@tmpJobInfo
	WHERE	JobName = @JobName

END
GO