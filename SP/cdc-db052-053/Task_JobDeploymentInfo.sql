/*<info serverAlias="DBAGE-bodb_age" executers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_JobDeploymentInfo]
	@JobName		VARCHAR(100)
	,@WaitingTime	VARCHAR(10) 	OUTPUT
	,@IsWaiting		BIT		OUTPUT
AS
/*
	Task: implement cdc for sum winloss
	DB: DBAGE-bodb_age
	Revision:
		20231201@Patrick: implement cdc for sum winloss [Redmine: #195357]
*/
BEGIN
	SET NOCOUNT ON

	SET @WaitingTime = '00:01:00'
	SET @IsWaiting = 0
	 
	;WITH __deployment_job AS (
		SELECT 'bodb_age : pull data 4 bettrans' AS JobName, '00:01:00' AS WaitingTime, 0 AS IsWaiting   
		UNION
		SELECT 'bodb_Age: Age process bettrans_compact' AS JobName, '00:01:00' AS WaitingTime, 0 AS IsWaiting
		--add more job here
	)
	SELECT @WaitingTime = WaitingTime, @IsWaiting = IsWaiting
	FROM __deployment_job
	WHERE JobName = @JobName
END
