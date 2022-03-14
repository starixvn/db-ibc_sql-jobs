/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
/*
	Created: 20220310@July
	Task: Check Data Consistency - Apply for all products in bettransRNG, bettransLC - [Redmine:#169699]
	DB: DBCONSISTENCY-bodb_Consistency

*/
DECLARE	@ruleId_s34 INT
SET @ruleId_s34 = (SELECT RuleId FROM dbo.DBA_Rules WHERE Name LIKE '%Checking data of swinlost, mwinlost, swinlost in settled ticket%')

UPDATE dbo.DBA_Tasks WITH(ROWLOCK,UPDLOCK)
SET command = N'EXEC dbo.DBA_Consistency_CheckWinlost3rd @tablename = ''bettransRNG'', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT '
WHERE [RuleId] = @ruleId_s34 AND command LIKE '%171%'

UPDATE dbo.DBA_Tasks WITH(ROWLOCK,UPDLOCK)
SET command = N'EXEC dbo.DBA_Consistency_CheckWinlost3rd @tablename = ''bettransLC'', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT '
WHERE [RuleId] = @ruleId_s34 AND command LIKE '%200%'

