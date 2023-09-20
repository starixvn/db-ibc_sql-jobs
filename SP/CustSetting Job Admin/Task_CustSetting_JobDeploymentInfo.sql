/*<info serverAlias="DBTXN-bodb02, DBCUST-CustDB,DBAGE-bodb02" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE Task_CustSetting_JobDeploymentInfo
	@JobName		VARCHAR(100)
	,@WaitingTime	VARCHAR(10) OUTPUT
	,@IsWaiting		BIT	OUTPUT
AS
/*
	Created by: 20220406@Elodie
	Task: Set waiting time for Customer Setting's job deployment
	DB: DBTXN/bodb02, DBCUST/CustDB,DBAGE-bodb02
	
	Revisions:
		- 20220406@Elodie: Initial SP
		- 20220617@Elodie: Manage job on DBCUST
		- 20221013@Tacy: add delay time 3mins for Task_BalanceUpd [RedmineID: #178335]
		- 20221121@Eden: Enhance run time of trigger to capture data for Pending table [#180716]
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @tmpJobInfo TABLE (JobName VARCHAR(100), WaitingTime VARCHAR(10), IsWaiting BIT DEFAULT (0))

	SET @WaitingTime = '00:01:00'
	SET @IsWaiting = 0

	---1.bodb02 : Game : ResetYesterday
	INSERT INTO @tmpJobInfo (JobName, WaitingTime, IsWaiting)
	SELECT 'bodb02 : Game : ResetYesterday', '00:01:00', 0 

	--2.bodb02 : Game : Task_BalanceUpd
	UNION ALL
	SELECT 'bodb02 : Game : Task_BalanceUpd', '00:01:00', 0

	--3.dbcust - Winlimit Game - Task_block_member
	UNION ALL
	SELECT 'dbcust - Winlimit Game - Task_block_member', '00:01:00', 1

	--4.dbcust - Winlimit Game - Task_block_member
	UNION ALL
	SELECT 'CustDB: TOControl ProcessData', '00:01:00', 0

	--5.bodb02 - WLMonitored - SyncSetting
	UNION ALL
	SELECT 'bodb02 - WLMonitored - SyncSetting', '00:01:00', 0

	SELECT @WaitingTime = WaitingTime
			,@IsWaiting = IsWaiting
	FROM	@tmpJobInfo
	WHERE	JobName = @JobName

END
