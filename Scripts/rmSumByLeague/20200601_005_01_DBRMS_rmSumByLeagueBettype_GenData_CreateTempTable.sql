/*<info serverAlias="DBARC-bodb_Archive"></info>*/
USE bodb_Archive
GO

/*
	Created: 20200601@Percy
	DB: DBARC-bodb_Archive
	Task: Gen data for new tables rmSumByLeague, rmSumByBettype

	Create temp table
*/

CREATE TABLE dbo.rmSumByBettype_xtest
(
	winlostdate			SMALLDATETIME
	,bettype			SMALLINT
	,ParlayType			TINYINT
	,IsDeposit			BIT
	,leagueIds			VARCHAR(MAX)
	,BetCount			INT
	,WonCount			INT
	,LoseCount			INT
	,DrawCount			INT
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
)
GO
CREATE CLUSTERED INDEX CIX_rmSumByBettype ON dbo.rmSumByBettype_xtest (winlostdate, bettype, ParlayType)
GO

CREATE TABLE dbo.rmSumByLeague_xtest
(
	winlostdate			SMALLDATETIME
	,leagueId			INT
	,ParlayType			TINYINT
	,IsDeposit			BIT
	,BetCount			INT
	,WonCount			INT
	,LoseCount			INT
	,DrawCount			INT
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
)
GO
CREATE CLUSTERED INDEX CIX_rmSumByLeague ON dbo.rmSumByLeague_xtest (winlostdate, leagueId, ParlayType)
GO