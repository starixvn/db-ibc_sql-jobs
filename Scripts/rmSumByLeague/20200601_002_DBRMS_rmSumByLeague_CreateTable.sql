/*<info serverAlias="DBRMS-bodb_RMS"></info>*/
/*	
	Created: 20200601@Percy
	DB: DBRMS-bodb_RMS
	Task: New table rmSumByLeague
	RedmineID: #135326 - Report by League and Bettype

	Step 2: Create new table
*/

USE bodb_RMS
GO

CREATE TABLE dbo.rmSumByLeague
(
	winlostdate			DATE
	,leagueId			INT
	,ParlayType			TINYINT
	,IsDeposit			BIT
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
) ON PS_rmSumByLeague_Monthly (winlostdate)
GO

CREATE CLUSTERED INDEX CIX_rmSumByLeague ON dbo.rmSumByLeague
	(winlostdate, leagueId, ParlayType) ON PS_rmSumByLeague_Monthly (winlostdate)
GO