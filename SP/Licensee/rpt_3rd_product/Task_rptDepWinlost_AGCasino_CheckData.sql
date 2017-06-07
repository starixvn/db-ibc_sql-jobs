USE [bodb_LicenseeReport]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Task_rptDepWinlost_AGCasino_CheckData]
	@WinlostDate		SMALLDATETIME,
	@HasDataMismatch	BIT OUTPUT
AS

/*
	Created: 20170530@Paul
	Task : Check & correct data of rptDepWinlost_AGCasino
	DB: DBLIC.bodb_LicenseeReport
	Original:
	Revisions:
*/

BEGIN
	SET NOCOUNT ON;

	SET @HasDataMismatch = 0;

	CREATE TABLE #Source
	(
		custid			INT,
		currency		INT,
		isVipGame		INT,
		turnover		MONEY,
		drawTO			MONEY,
		winlost			MONEY,
		betCount		INT,
		drawBetCount	INT
	);

	CREATE TABLE #Target
	(
		custid			INT,
		currency		INT,
		isVipGame		INT,
		turnover		MONEY,
		drawTO			MONEY,
		winlost			MONEY,
		betCount		INT,
		drawBetCount	INT
	);

	DECLARE @S_Count INT, @T_Count INT,
			@i INT;

	INSERT INTO #Source(custid, currency, isVipGame, turnover, drawTO, winlost, betCount, drawBetCount)
	SELECT b.CustID, 
		b.currency,
		isVIPGame,
		ISNULL(SUM(b.Stake),0) AS Turnover,
		ISNULL(SUM(CASE WHEN b.StatusID = 111 THEN b.Stake ELSE 0 END),0) AS DrawTO,
		ISNULL(SUM(b.Winlost - b.Actual_Stake),0) AS Winlost,
		ISNULL(COUNT(*),0) AS Betcount,
		ISNULL(SUM(CASE WHEN b.StatusID = 111 THEN 1 ELSE 0 END),0) AS DrawBetCount
	FROM bodb_PlaytechCS.dbo.bettrans_AGCasino b WITH (ROWLOCK)
	WHERE Winlostdate = @winlostdate
		AND StatusId IN (111, 112, 113)
	GROUP BY b.CustID, b.currency, isVIPGame;

	SET @S_Count = @@ROWCOUNT;
	
	INSERT INTO #Target(custid, currency, isVipGame, turnover, drawTO, winlost, BetCount, drawBetCount)
	SELECT	custid,
			currency,
			isVipGame,
			turnover,
			drawTO,
			winlost,
			BetCount,
			drawBetCount
	FROM DBACC.bodb_report.dbo.rptDepWinlost_AGCasino WITH(NOLOCK)
	WHERE winlostdate = @WinlostDate
		AND sporttype = 250;

	SET @T_Count = @@ROWCOUNT;

	IF @S_Count = 0 AND @T_Count = 0
	BEGIN
		RETURN;
	END

	CREATE TABLE #Log(TableName VARCHAR(100), CurrencyId INT, Turnover MONEY, Winloss MONEY);

	INSERT INTO #Log(TableName, CurrencyId, Turnover, Winloss)
	SELECT 'bettrans_AGCasino', Currency, SUM(turnover), SUM(winlost)
	FROM #Source s
	WHERE NOT EXISTS (
		SELECT 1
		FROM #Target t
		WHERE s.custid = t.custid AND s.currency = t.currency AND s.isVipGame = t.isVipGame AND s.turnover = t.turnover
			AND s.winlost = t.winlost AND s.drawTO = t.drawTO AND s.drawBetCount = t.drawBetCount AND s.betCount = t.betCount)
	GROUP BY currency
	
	UNION ALL 
	
	SELECT 'rptDepWinlost_AGCasino', Currency, SUM(turnover), SUM(winlost)
	FROM #Target t
	WHERE NOT EXISTS (
		SELECT 1
		FROM #Source s
		WHERE s.custid = t.custid AND s.currency = t.currency AND s.isVipGame = t.isVipGame AND s.turnover = t.turnover
			AND s.winlost = t.winlost AND s.drawTO = t.drawTO AND s.drawBetCount = t.drawBetCount AND s.betCount = t.betCount)
	GROUP BY currency;

	SET @T_Count = @@ROWCOUNT;

	IF @T_Count > 0
	BEGIN
		SET @HasDataMismatch = 1;
	END

	INSERT INTO dbo.DataCheckingLog(WinlostDate, SPName, TableName, CurrencyId, Turnover, Winloss)
	SELECT	@WinlostDate, 
			'Task_rptDepWinlost_AGCasino_CheckData', 
			TableName, 
			CurrencyId, 
			Turnover, 
			Winloss
	FROM #Log;

	DROP TABLE #Log;
	DROP TABLE #Source;
	DROP TABLE #Target;

	SET NOCOUNT OFF;
END