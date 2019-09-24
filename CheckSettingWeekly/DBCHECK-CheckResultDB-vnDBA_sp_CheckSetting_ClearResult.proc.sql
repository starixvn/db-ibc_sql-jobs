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
		- 20190923@Billy:	Add CN88 result tables - [Redmine: #120719]
		
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

	-- CN88 --
	TRUNCATE TABLE	dbo.CS_CheckBetLimitResult;
	TRUNCATE TABLE	dbo.CS_CheckCommResult;
	TRUNCATE TABLE	dbo.CS_CheckPTResult;
END;
GO
/*<info serverAlias="DBCHECK-CheckResultDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/