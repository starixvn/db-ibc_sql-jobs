/*<info serverAlias="DBRMS-bodb_RMS"></info>*/
USE bodb_RMS
GO

/*
	Created: 20200831@Percy
	DB: DBRMS-bodb_RMS
	Task: Gen data for new tables rmSumByLeague, rmSumByBettype

	Insert data from temp table
*/
TRUNCATE TABLE dbo.rmSumByBettype
GO
TRUNCATE TABLE dbo.rmSumByLeague
GO

DECLARE @WLDate SMALLDATETIME = '2020-08-01'
DECLARE @ErrMsg VARCHAR(200)

WHILE @WLDate <= '2020-08-20'
BEGIN
	SET @ErrMsg = 'Start date = ' + CONVERT(VARCHAR(10), @WLDate, 120)
	RAISERROR (@ErrMsg, 0, 0) WITH NOWAIT

	INSERT INTO dbo.rmSumByBettype (winlostdate,bettype,ParlayType,IsDeposit,leagueId,BetCount,WonCount,DrawCount,LoseCount,MainBetCount,MainWonCount,MainLoseCount,MainDrawCount,MainStake,MainTurnover,MainTurnoverNoDraw,MainMemberWinloss,MainMemberComm,MainHouseWinloss)
	SELECT winlostdate,bettype,ParlayType,IsDeposit,leagueId,SUM(BetCount),SUM(WonCount),SUM(DrawCount),SUM(LoseCount),SUM(MainBetCount),SUM(MainWonCount),SUM(MainLoseCount),SUM(MainDrawCount),SUM(MainStake),SUM(MainTurnover),SUM(MainTurnoverNoDraw),SUM(MainMemberWinloss),SUM(MainMemberComm),SUM(MainHouseWinloss)
	FROM DBARC.bodb_Archive.dbo.rmSumByBettype_xtest WITH (NOLOCK)
	WHERE winlostdate = @WLDate
	GROUP BY winlostdate, bettype,ParlayType,IsDeposit,leagueId

	INSERT INTO dbo.rmSumByLeague (winlostdate,leagueId,ParlayType,IsDeposit,BetCount,WonCount,DrawCount,LoseCount,MainBetCount,MainWonCount,MainLoseCount,MainDrawCount,MainStake,MainTurnover,MainTurnoverNoDraw,MainMemberWinloss,MainMemberComm,MainHouseWinloss)
	SELECT winlostdate,leagueId,ParlayType,IsDeposit,SUM(BetCount),SUM(WonCount),SUM(DrawCount),SUM(LoseCount),SUM(MainBetCount),SUM(MainWonCount),SUM(MainLoseCount),SUM(MainDrawCount),SUM(MainStake),SUM(MainTurnover),SUM(MainTurnoverNoDraw),SUM(MainMemberWinloss),SUM(MainMemberComm),SUM(MainHouseWinloss)
	FROM DBARC.bodb_Archive.dbo.rmSumByLeague_xtest WITH (NOLOCK)
	WHERE winlostdate = @WLDate
	GROUP BY winlostdate, leagueId,ParlayType,IsDeposit

	SELECT @WLDate = DATEADD(DAY, 1, @WLDate)
	
	WAITFOR DELAY '00:00:00.280'
END
GO