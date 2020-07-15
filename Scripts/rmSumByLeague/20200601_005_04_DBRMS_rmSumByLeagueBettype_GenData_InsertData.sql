/*<info serverAlias="DBRMS-bodb_RMS"></info>*/
USE bodb_Archive
GO

/*
	Created: 20200601@Percy
	DB: DBRMS-bodb_RMS
	Task: Gen data for new tables rmSumByLeague, rmSumByBettype

	Insert data from temp table
*/
DECLARE @WLDate SMALLDATETIME = '2020-04-01'
DECLARE @ErrMsg VARCHAR(200)

WHILE @WLDate <= '2020-06-04'
BEGIN
	SET @ErrMsg = 'Start date = ' + CONVERT(VARCHAR(10), @WLDate, 120)
	RAISERROR (@ErrMsg, 0, 0) WITH NOWAIT

	INSERT INTO dbo.rmSumByBettype (winlostdate,bettype,ParlayType,IsDeposit,leagueIds,BetCount,WonCount,DrawCount,LoseCount,MainBetCount,MainWonCount,MainLoseCount,MainDrawCount,MainStake,MainTurnover,MainTurnoverNoDraw,MainMemberWinloss,MainMemberComm,MainHouseWinloss)
	SELECT winlostdate,bettype,ParlayType,IsDeposit,leagueIds,BetCount,WonCount,DrawCount,LoseCount,MainBetCount,MainWonCount,MainLoseCount,MainDrawCount,MainStake,MainTurnover,MainTurnoverNoDraw,MainMemberWinloss,MainMemberComm,MainHouseWinloss
	FROM DBARC.bodb_Archive.dbo.rmSumByBettype_xtest WITH (NOLOCK)
	WHERE winlostdate = @WLDate

	INSERT INTO dbo.rmSumByLeague (winlostdate,leagueId,ParlayType,IsDeposit,BetCount,WonCount,DrawCount,LoseCount,MainBetCount,MainWonCount,MainLoseCount,MainDrawCount,MainStake,MainTurnover,MainTurnoverNoDraw,MainMemberWinloss,MainMemberComm,MainHouseWinloss)
	SELECT winlostdate,leagueId,ParlayType,IsDeposit,BetCount,WonCount,DrawCount,LoseCount,MainBetCount,MainWonCount,MainLoseCount,MainDrawCount,MainStake,MainTurnover,MainTurnoverNoDraw,MainMemberWinloss,MainMemberComm,MainHouseWinloss
	FROM DBARC.bodb_Archive.dbo.rmSumByLeague_xtest WITH (NOLOCK)
	WHERE winlostdate = @WLDate

	SELECT @WLDate = DATEADD(DAY, 1, @WLDate)
	
	WAITFOR DELAY '00:00:00.280'
END
GO