/*<info serverAlias="DBRMS-bodb_RMS"></info>*/
/*	
	Created: 20231228@Cherry
	DB: DBRMS-bodb_RMS
	Task: New table rmSumByEventBettype
	RedmineID: #197684 - Report by Bettype

	Step 2: Create new table
*/

USE bodb_RMS
GO

CREATE TABLE dbo.rmSumByEventBettype
(
	winlostdate			DATE
	,Bettype			SMALLINT
	,ParlayType			TINYINT
	,LeagueId			INT
	,MatchId			INT
	,Betteam			NVARCHAR(10)
	,IsDeposit			BIT
	,TransList			NVARCHAR(MAX)
	,BetCount			INT
	,WonCount			INT
	,DrawCount			INT
	,LoseCount			INT
	,MainBetCount		INT
	,MainWonCount		INT
	,MainLoseCount		INT
	,MainDrawCount		INT
	,MainStake			MONEY
	,MainTurnover		MONEY
	,MainTurnoverNoDraw	MONEY
	,MainMemberWinloss	MONEY
	,MainMemberComm		MONEY
	,MainHouseWinloss	MONEY
) ON PS_rmSumByEventBettype_Monthly (winlostdate)
GO

CREATE CLUSTERED INDEX CIX_rmSumByEventBettype ON dbo.rmSumByEventBettype
	(winlostdate, Bettype, ParlayType, LeagueId) ON PS_rmSumByEventBettype_Monthly (winlostdate)
GO