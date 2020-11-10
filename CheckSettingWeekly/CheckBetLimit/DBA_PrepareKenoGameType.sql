/*<info serverAlias="DBCHECK-CheckResultDB" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_PrepareKenoGameType]
AS 
	/*
	Created: 20180817@Johnson
	Task: Prepare GameType table for keno - [Redmine:73556]
	DB: DB054.CheckResultDB
	Revisions:
		- 09112020@Winfred : Modify table GameType for Keno - [Redmine:145003]
	Param's Explanation: 

	*/
BEGIN
	IF Object_ID('CheckCustDB..GameType') IS NOT NULL
		DROP TABLE CheckCustDB..GameType
		
	SELECT 202 as sportType, GameTypeID as GameTypeID,IsDisabled,IBCBetTypeID 
	INTO CheckCustDB.dbo.GameType
	FROM KBTDB061.bodb02.dbo.GameType WITH(NOLOCK)	
	WHERE IsDisabled = 0 AND GameTypeID BETWEEN 1 AND 99
END	