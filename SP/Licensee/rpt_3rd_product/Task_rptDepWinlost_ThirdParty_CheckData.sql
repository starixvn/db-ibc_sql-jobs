USE [bodb_LicenseeReport]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Task_rptDepWinlost_ThirdParty_CheckData]
	@WinlostDate		SMALLDATETIME,
	@HasDataMismatch	BIT OUTPUT
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
	SELECT	TOP(@S_Count + 1) custid,
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

	IF @S_Count <> @T_Count
	BEGIN
		SET @HasDataMismatch = 1;

		RETURN;
	END

	SELECT TOP(1) @i = 1
	FROM #Source s
	WHERE NOT EXISTS (
		SELECT 1
		FROM #Target t
		WHERE s.custid = t.custid AND s.currency = t.currency AND s.turnover = t.turnover AND s.winlost = t.winlost
			AND s.drawTO = t.drawTO AND s.drawBetCount = t.drawBetCount AND s.betCount = t.betCount);

	SET @T_Count = @@ROWCOUNT;

	IF @T_Count = 1
	BEGIN
		SET @HasDataMismatch = 1;
	END

	SET NOCOUNT OFF;
END