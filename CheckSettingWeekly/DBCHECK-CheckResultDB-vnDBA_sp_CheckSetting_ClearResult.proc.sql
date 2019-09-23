SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE		dbo.vnDBA_sp_CheckSetting_ClearResult
AS
/*
	Creator:	20180816@Billy
	Task:		Clean up last Check CustDB result - [Redmine: #99249]
	Database:	DBCHECK.CheckResultDB
	
	Revisions:
		- 20180816@Billy:	Initial - [Redmine: #99249]
		
	Developer's Notes:
		- @Example:			NULL		- Explaination [DEFAULT]
		
*/
BEGIN;
	SET NOCOUNT ON;
	
	-- PT --
	TRUNCATE TABLE	dbo.CheckPTResult_Credit;

	TRUNCATE TABLE	dbo.CheckPTResult_Deposit;


	-- Status --
	TRUNCATE TABLE	dbo.CheckStatusResult;

	TRUNCATE TABLE	dbo.CheckStatusResult_DCS;


	-- Commission --
	TRUNCATE TABLE	dbo.CheckCommResult_Credit;

	TRUNCATE TABLE	dbo.CheckCommResult_Deposit;


	-- Bet Limit --
	TRUNCATE TABLE	dbo.CheckBetLimitResult;

	TRUNCATE TABLE	dbo.CheckBetLimitResult_DCS;


	-- Stake Level --
	TRUNCATE TABLE	dbo.CheckResultStakeLevel_Credit;

	TRUNCATE TABLE	dbo.CheckResultStakeLevel_Deposit;
END;
GO
/*<info serverAlias="DBCHECK-CheckResultDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/