/*<info serverAlias="DBLIC-bodb_LicenseeReport"></info>*/
/*	
	Created: 20200601@Percy
	DB: DBLIC-msdb
	Task: New table rpt_CustomerWL_ExtraGMT
	RedmineID: #134867 - Calculating pay to supplier for some special customers

	Step 5: Gen data from 6PM 26-Apr-2020 GMT+8
*/

-- bettrans_bk
BEGIN
	INSERT INTO dbo.rpt_CustomerWL_ExtraGMT
	(
		RptDate
		,RptDate3rd
		,CustId
		,SiteId
		,ProductId
		,BetTypeId
		,CurrencyId
		,StatusId
		,BetCount
		,Turnover
		,Winloss
		,AComm
		,PComm
		,ProgressiveContribution
		,ProgressivePayout
		,ValidBetAmount
	)
	SELECT
		RptDate		= CONVERT(DATE, b.winlostdate)
		,RptDate3rd = CONVERT(DATE, b.Transdate3rd)
		,CustId		= b.custid
		,SiteId		= 1021
		,ProductId	= 21
		,BetTypeId	= b.gameId
		,CurrencyId	= b.currency
		,StatusId	= b.statusId
		,BetCount	= COUNT(1)
		,Turnover	= SUM(ABS(b.stake))
		,Winloss	= SUM(b.winlost - b.actual_stake)
		,AComm		= SUM(b.comm)
		,PComm		= SUM(b.playercomm)
		,ProgressiveContribution	= 0
		,ProgressivePayout			= 0
		,ValidBetAmount				= SUM(b.NetStake)
	FROM DBARC.bodb_Archive.dbo.bettransLC_bk b WITH (NOLOCK)
	WHERE winlostdate BETWEEN '2020-04-25' AND '2020-05-21'
		AND transdate3rd >= '2020-04-26 18:00:00.000' -- from 6PM 26-Apr-2020 GMT+8
		AND gameId BETWEEN 2401 AND 2499 -- Allbet
		AND custid IN (33405559,42264449,42772152)
	GROUP BY
		CONVERT(DATE, b.winlostdate)
		,CONVERT(DATE, b.Transdate3rd)
		,b.custid
		,b.gameId
		,b.currency
		,b.statusId
END


-- bettrans14 & bettrans
BEGIN
	DECLARE @WinlostDate SMALLDATETIME, @ErrMsg VARCHAR(1000)
	SELECT  @WinlostDate = '2020-05-22' -- Current BU Date

	WHILE @WinlostDate < '2020-06-01'
	BEGIN
		SET @ErrMsg = 'Start winlostdate: ' + CONVERT(VARCHAR(10), @WinlostDate, 120)
		RAISERROR (@ErrMsg, 1, 0) WITH NOWAIT

		EXEC dbo.Task_rpt_CustomerWL_ExtraGMT @WinlostDate = @WinlostDate

		SELECT @WinlostDate = DATEADD(DAY, 1, @WinlostDate)

		WAITFOR DELAY '00:00:00.280'
	END
END