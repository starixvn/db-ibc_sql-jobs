/*<info serverAlias="DBRMS-bodb_RMS"></info>*/
/*	
	Created: 20200601@Percy
	DB: DBRMS-bodb_RMS
	Task: New table rmSumByBettype
	RedmineID: #135326 - Report by Bettype

	Step 2: Create new table
*/

USE bodb_RMS
GO

CREATE TABLE dbo.rmSumByBettype
(
	winlostdate			DATE
	,Bettype			SMALLINT
	,ParlayType			TINYINT
	,LeagueIds			VARCHAR(MAX)
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
) ON PS_rmSumByBettype_Monthly (winlostdate)
GO

CREATE CLUSTERED INDEX CIX_rmSumByBettype ON dbo.rmSumByBettype
	(winlostdate, Bettype, ParlayType) ON PS_rmSumByBettype_Monthly (winlostdate)
GO