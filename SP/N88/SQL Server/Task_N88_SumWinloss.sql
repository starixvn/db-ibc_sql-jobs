/*<info serverAlias="DBN88-bodb_N88" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_N88_SumWinloss]
	@WinlostDate SMALLDATETIME
AS

/*
	Created: 20210218@Percy
	DB: DBN88-bodb_N88
	Task: Job - Import data for N88_SumWinloss

	Revisions:
		- 20210218@Percy: Initialize SP [RedmineID: #150398]
		- 20210715@Percy: Add columns ProgressiveBet, ProgressiveWin [RedmineID: #158438]
		- 20211102@Percy: Add column BonusId [RedmineID: #164141]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @FDate DATETIME, @TDate DATETIME
	SELECT  @FDate = DATEADD(HOUR, 4, @WinlostDate), @TDate = DATEADD(DAY, 1, @FDate)

	-- Get data
	BEGIN
		CREATE TABLE #__TpBetRecord
		(
			CustId			INT
			,UserName		VARCHAR(50)
			,IsTest			BIT
			,Currency		INT
			,SiteId			INT
			,GameType		INT
			,TransTime		DATETIME
			,SettledTime	DATETIME
			,TurnOver		MONEY
			,ValidBet		MONEY
			,Winloss		MONEY
			,Revenue		MONEY
			,ProgressiveBet	MONEY
			,ProgressiveWin	MONEY
			,BetCount		INT
			,StatusId		TINYINT
			,BonusId		INT
		)

		INSERT INTO #__TpBetRecord (
			CustId, UserName, IsTest, Currency, SiteId, GameType, TransTime, SettledTime, StatusId, BonusId
			,BetCount, TurnOver, ValidBet, Winloss, Revenue, ProgressiveBet, ProgressiveWin)
		SELECT
			t.CustId, t.UserName, 0 AS IsTest, t.CurrencyId, t.SiteId, t.GameType
			,DATEADD(HOUR, DATEPART(HOUR, t.TransTime), CONVERT(VARCHAR(10), t.TransTime, 120)) -- date & hour
			,DATEADD(HOUR, DATEPART(HOUR, t.SettledTime), CONVERT(VARCHAR(10), t.SettledTime, 120)) -- date & hour
			,t.TicketStatus
			,ISNULL(t.BonusId, 0)
			,COUNT(1) AS BetCount
			,SUM(t.Stake / CASE WHEN t.CurrencyId IN (15, 51) THEN 1000.0 ELSE 1.0 END) AS TurnOver
			,SUM(ISNULL(t.ValidBet, t.Stake) / CASE WHEN t.CurrencyId IN (15, 51) THEN 1000.0 ELSE 1.0 END) AS ValidBet
			,SUM(t.WinlostAmount / CASE WHEN t.CurrencyId IN (15, 51) THEN 1000.0 ELSE 1.0 END) AS Winloss
			,SUM(ISNULL(t.Revenue, 0) / CASE WHEN t.CurrencyId IN (15, 51) THEN 1000.0 ELSE 1.0 END) AS Revenue
			,SUM(ISNULL(t.ProgressiveBet, 0) / CASE WHEN t.CurrencyId IN (15, 51) THEN 1000.0 ELSE 1.0 END) AS ProgressiveBet
			,SUM(ISNULL(t.ProgressiveWin, 0) / CASE WHEN t.CurrencyId IN (15, 51) THEN 1000.0 ELSE 1.0 END) AS ProgressiveWin
		FROM dbo.TpBetRecord t WITH (NOLOCK)
		WHERE t.WinlostDate BETWEEN DATEADD(DAY, -1, @WinlostDate) AND DATEADD(DAY, 1, @WinlostDate)
			AND t.SettledTime >= @FDate AND t.SettledTime < @TDate
		GROUP BY
			t.CustId, t.UserName, t.CurrencyId, t.SiteId, t.GameType
			,DATEADD(HOUR, DATEPART(HOUR, t.TransTime), CONVERT(VARCHAR(10), t.TransTime, 120)) -- date & hour
			,DATEADD(HOUR, DATEPART(HOUR, t.SettledTime), CONVERT(VARCHAR(10), t.SettledTime, 120)) -- date & hour
			,t.TicketStatus
			,ISNULL(t.BonusId, 0)

		UPDATE t
		SET t.IsTest = c.IsTest
		FROM #__TpBetRecord t
			INNER JOIN dbo.Customer c WITH (NOLOCK) ON t.CustId = c.CustId
		WHERE c.IsTest = 1
	END

	-- Gen data into N88_RptWinloss
	BEGIN
		CREATE TABLE #__N88_SumWinloss
		(
			CustId			INT
			,UserName		VARCHAR(50)
			,IsTest			BIT
			,Currency		INT
			,SiteId			INT
			,GameType		INT
			,TransTime		DATETIME
			,SettledTime	DATETIME
			,TurnOver		MONEY
			,ValidBet		MONEY
			,Winloss		MONEY
			,Revenue		MONEY
			,ProgressiveBet	MONEY
			,ProgressiveWin	MONEY
			,BetCount		INT
			,StatusId		TINYINT
			,BonusId		INT
			,DataType		SMALLINT
		)
		;WITH CTE_N88_SumWinloss AS
		(
			SELECT
				CustId, UserName, IsTest, Currency, SiteId, GameType, TransTime, SettledTime, StatusId, BonusId
				,BetCount, TurnOver, ValidBet, Winloss, Revenue, ProgressiveBet, ProgressiveWin
			FROM dbo.N88_SumWinloss WITH (NOLOCK)
			WHERE SettledTime >= @FDate AND SettledTime < @TDate
		)
		INSERT INTO #__N88_SumWinloss (
			CustId, UserName, IsTest, Currency, SiteId, GameType, TransTime, SettledTime, StatusId, BonusId
			,BetCount, TurnOver, ValidBet, Winloss, Revenue, ProgressiveBet, ProgressiveWin, DataType)
		SELECT
			ISNULL(t.CustId, c.CustId)
			,ISNULL(t.UserName, c.UserName)
			,ISNULL(t.IsTest, c.IsTest)
			,ISNULL(t.Currency, c.Currency)
			,ISNULL(t.SiteId, c.SiteId)
			,ISNULL(t.GameType, c.GameType)
			,ISNULL(t.TransTime, c.TransTime)
			,ISNULL(t.SettledTime, c.SettledTime)
			,ISNULL(t.StatusId, c.StatusId)
			,ISNULL(t.BonusId, c.BonusId)
			,ISNULL(t.BetCount, c.BetCount)
			,ISNULL(t.TurnOver, c.TurnOver)
			,ISNULL(t.ValidBet, c.ValidBet)
			,ISNULL(t.Winloss, c.Winloss)
			,ISNULL(t.Revenue, c.Revenue)
			,ISNULL(t.ProgressiveBet, c.ProgressiveBet)
			,ISNULL(t.ProgressiveWin, c.ProgressiveWin)
			,DataType = CASE	WHEN t.SettledTime IS NULL THEN -1 -- delete
								WHEN c.SettledTime IS NULL THEN 1 -- insert
								ELSE 0 END -- update
		FROM #__TpBetRecord t
			FULL OUTER JOIN CTE_N88_SumWinloss c
				ON		t.SettledTime	= c.SettledTime
					AND t.SiteId		= c.SiteId
					AND t.CustId		= c.CustId
					AND t.UserName		= c.UserName
					AND t.Currency		= c.Currency
					AND t.GameType		= c.GameType
					AND t.TransTime		= c.TransTime
					AND t.StatusId		= c.StatusId
					AND ISNULL(t.BonusId, 0) = ISNULL(c.BonusId, 0)
		WHERE t.SettledTime IS NULL
			OR c.SettledTime IS NULL
			OR ISNULL(t.TurnOver, 0)		<> ISNULL(c.TurnOver, 0)
			OR ISNULL(t.ValidBet, 0)		<> ISNULL(c.ValidBet, 0)
			OR ISNULL(t.Winloss, 0)			<> ISNULL(c.Winloss, 0)
			OR ISNULL(t.Revenue, 0)			<> ISNULL(c.Revenue, 0)
			OR ISNULL(t.ProgressiveBet, 0)	<> ISNULL(c.ProgressiveBet, 0)
			OR ISNULL(t.ProgressiveWin, 0)	<> ISNULL(c.ProgressiveWin, 0)
			OR ISNULL(t.BetCount, 0)		<> ISNULL(c.BetCount, 0)

		-- Delete
		IF EXISTS (SELECT 1 FROM #__N88_SumWinloss WHERE DataType = -1)
			DELETE s WITH (ROWLOCK, UPDLOCK)
			FROM dbo.N88_SumWinloss s
				INNER JOIN #__N88_SumWinloss t
					ON		s.SettledTime	= t.SettledTime
						AND s.SiteId		= t.SiteId
						AND s.CustId		= t.CustId
						AND s.UserName		= t.UserName
						AND s.Currency		= t.Currency
						AND s.GameType		= t.GameType
						AND s.TransTime		= t.TransTime
						AND s.StatusId		= t.StatusId
						AND ISNULL(s.BonusId, 0) = ISNULL(t.BonusId, 0)
			WHERE t.DataType = -1

		-- Update
		IF EXISTS (SELECT 1 FROM #__N88_SumWinloss WHERE DataType = 0)
			UPDATE s WITH (ROWLOCK)
			SET s.TurnOver			= t.TurnOver
				,s.ValidBet			= t.ValidBet
				,s.Winloss			= t.Winloss
				,s.Revenue			= t.Revenue
				,s.ProgressiveBet	= t.ProgressiveBet
				,s.ProgressiveWin	= t.ProgressiveWin
				,s.BetCount			= t.BetCount
			FROM dbo.N88_SumWinloss s
				INNER JOIN #__N88_SumWinloss t
					ON		s.SettledTime	= t.SettledTime
						AND s.SiteId		= t.SiteId
						AND s.CustId		= t.CustId
						AND s.UserName		= t.UserName
						AND s.Currency		= t.Currency
						AND s.GameType		= t.GameType
						AND s.TransTime		= t.TransTime
						AND s.StatusId		= t.StatusId
						AND ISNULL(s.BonusId, 0) = ISNULL(t.BonusId, 0)
			WHERE t.DataType = 0

		-- Insert
		IF EXISTS (SELECT 1 FROM #__N88_SumWinloss WHERE DataType = 1)
			INSERT INTO dbo.N88_SumWinloss (
				CustId, UserName, IsTest, Currency, SiteId, GameType, TransTime, SettledTime, StatusId, BonusId
				,BetCount, TurnOver, ValidBet, Winloss, Revenue, ProgressiveBet, ProgressiveWin
			)
			SELECT
				CustId, UserName, IsTest, Currency, SiteId, GameType, TransTime, SettledTime, StatusId, BonusId
				,BetCount, TurnOver, ValidBet, Winloss, Revenue, ProgressiveBet, ProgressiveWin
			FROM #__N88_SumWinloss
			WHERE DataType = 1
	END

	DROP TABLE #__N88_SumWinloss
	DROP TABLE #__TpBetRecord
END
GO