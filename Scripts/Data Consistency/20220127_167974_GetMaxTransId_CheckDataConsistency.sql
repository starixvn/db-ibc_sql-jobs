/*<info serverAlias="DBCONSISTENCY-bodb_Consistency" executers="" viewers="" isFunction="0"></info>*/
/*
	Created: 20220127@July
	Task: Get maxtransid  [Redmine:#167974]
	DB: DBCONSISTENCY-bodb_Consistency

	Note: Run before UM
*/
DECLARE @maxTransID BIGINT
SELECT @maxTransID = MAX(transid) FROM bodb02.dbo.bettrans WITH(NOLOCK) 

SELECT @maxTransID AS maxTransID

