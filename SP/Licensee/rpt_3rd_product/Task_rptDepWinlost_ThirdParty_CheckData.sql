USE [bodb_LicenseeReport]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Task_rptDepWinlost_ThirdParty_CheckData]
	@WinlostDate		SMALLDATETIME,
	@HasDataMismatch	TINYINT OUTPUT --0: No mismatch; 1: Has real currencies; 2: UUS only
AS

/*
	Created: 20170530@Paul
	Task : Check & correct data of rptDepWinlost_ThirdParty - GD
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
		turnover		MONEY,							
		winlost			MONEY,	
		drawTO			MONEY,	
		drawBetCount	INT,						
		betCount		INT
	);

	CREATE TABLE #Target
	(
		custid			INT,								
		currency		INT,							
		turnover		MONEY,							
		winlost			MONEY,	
		drawTO			MONEY,	
		drawBetCount	INT,						
		betCount		INT
	);

	DECLARE @S_Count INT, @T_Count INT,
			@i INT;

	INSERT INTO #Source(custid, currency, turnover, winlost, drawTO, drawBetCount, betCount)
	SELECT	b.CustID, 		
			b.currency,				
			ISNULL(SUM(b.Stake),0) AS Turnover,			
			ISNULL(SUM(b.Winlost - b.Stake),0) AS Winlost,	
			ISNULL(SUM(CASE WHEN b.StatusID = 111 THEN b.Stake ELSE 0 END),0) AS DrawTO,	
			ISNULL(SUM(CASE WHEN b.StatusID = 111 THEN 1 ELSE 0 END),0) AS DrawBetCount,	
			ISNULL(COUNT(b.TicketId),0) AS Betcount	
	FROM bodb_PlaytechCS.dbo.bettrans_GoldDeluxe b WITH (ROWLOCK)
	WHERE Winlostdate = @winlostdate
		AND StatusId IN (111,112,113)
	GROUP BY b.CustID, b.currency;

	SET @S_Count = @@ROWCOUNT;
	
	INSERT INTO #Target(custid, currency, turnover, winlost, drawTO, drawBetCount, betCount)
	SELECT	custid,
			currency,
			turnover,
			winlost,
			drawTO,
			drawBetCount,
			betCount
	FROM dbo.rptDepWinlost_ThirdParty WITH(NOLOCK)
	WHERE winlostdate = @WinlostDate
		AND ProductId = 11;

	SET @T_Count = @@ROWCOUNT;

	IF @S_Count = 0 AND @T_Count = 0
	BEGIN
		RETURN;
	END

	CREATE TABLE #Log(TableName VARCHAR(100), IsSource BIT, CurrencyId INT, Turnover MONEY, Winloss MONEY, BetCount INT, ExtraInfo VARCHAR(MAX));

	INSERT INTO #Log(TableName, IsSource, CurrencyId, Turnover, Winloss, BetCount, ExtraInfo)
	SELECT 'bettrans_GoldDeluxe', 1, Currency, SUM(turnover), SUM(winlost), SUM(betCount),
			(
				SELECT SUM(drawTO) AS drawTO, SUM(drawBetCount) AS drawBetCnt
				FROM #Source s1
				WHERE s1.currency = s.currency
				FOR XML PATH('')
			) AS ExtraInfo
	FROM #Source s
	WHERE NOT EXISTS (
		SELECT 1
		FROM #Target t
		WHERE s.custid = t.custid AND s.currency = t.currency AND s.turnover = t.turnover AND s.winlost = t.winlost
			AND s.drawTO = t.drawTO AND s.drawBetCount = t.drawBetCount AND s.betCount = t.betCount)
	GROUP BY currency
	
	UNION ALL
	
	SELECT 'rptDepWinlost_ThirdParty', 0, Currency, SUM(turnover), SUM(winlost), SUM(betCount),
			(
				SELECT SUM(drawTO) AS drawTO, SUM(drawBetCount) AS drawBetCnt
				FROM #Target t1
				WHERE t1.currency = t.currency
				FOR XML PATH('')
			) AS ExtraInfo
	FROM #Target t
	WHERE NOT EXISTS (
		SELECT 1
		FROM #Source s
		WHERE s.custid = t.custid AND s.currency = t.currency AND s.turnover = t.turnover AND s.winlost = t.winlost
			AND s.drawTO = t.drawTO AND s.drawBetCount = t.drawBetCount AND s.betCount = t.betCount)
	GROUP BY currency;

	SET @T_Count = @@ROWCOUNT;

	IF @T_Count = 0
	BEGIN
		RETURN;
	END

	IF EXISTS (SELECT 1 FROM #Log WHERE CurrencyId <> 20)
	BEGIN
		SET @HasDataMismatch = 1;
	END
	ELSE
	BEGIN
		SET @HasDataMismatch = 2;
	END

	INSERT INTO dbo.DataCheckingLog(WinlostDate, SPName, TableName, IsSource, CurrencyId, Turnover, Winloss, BetCount, ExtraInfo)
	SELECT	@WinlostDate, 
			'Task_rptDepWinlost_ThirdParty_CheckData', 
			TableName, 
			IsSource,
			CurrencyId, 
			Turnover, 
			Winloss,
			BetCount,
			ExtraInfo
	FROM #Log;

	DROP TABLE #Log;
	DROP TABLE #Source;
	DROP TABLE #Target;

	SET NOCOUNT OFF;
END