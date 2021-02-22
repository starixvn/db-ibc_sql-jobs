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
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @FDate DATETIME, @TDate DATETIME
	SELECT  @FDate = DATEADD(HOUR, 4, @WinlostDate), @TDate = DATEADD(DAY, 1, @FDate)

	-- Get data
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
			,BetCount		INT
			,StatusId		TINYINT
			,DataType		TINYINT
		)

		INSERT INTO #__N88_SumWinloss (CustId, UserName, IsTest, Currency, SiteId, GameType, TransTime, SettledTime, TurnOver, ValidBet, Winloss, BetCount, StatusId)
		SELECT
			t.CustId, t.UserName, 0 AS IsTest, t.CurrencyId, t.SiteId, t.GameType
			,DATEADD(HOUR, DATEPART(HOUR, t.TransTime), CONVERT(VARCHAR(10), t.TransTime, 120)) -- date & hour
			,DATEADD(HOUR, DATEPART(HOUR, t.SettledTime), CONVERT(VARCHAR(10), t.SettledTime, 120)) -- date & hour
			,SUM(t.Stake / CASE WHEN t.CurrencyId IN (15, 51) THEN 1000.0 ELSE 1.0 END) AS TurnOver
			,SUM(ISNULL(t.ValidBet, t.Stake) / CASE WHEN t.CurrencyId IN (15, 51) THEN 1000.0 ELSE 1.0 END) AS ValidBet
			,SUM(t.WinlostAmount / CASE WHEN t.CurrencyId IN (15, 51) THEN 1000.0 ELSE 1.0 END) AS Winloss
			,COUNT(1) AS BetCount
			,t.TicketStatus
		FROM dbo.TpBetRecord t WITH (NOLOCK)
		WHERE t.WinlostDate BETWEEN DATEADD(DAY, -1, @WinlostDate) AND DATEADD(DAY, 1, @WinlostDate)
			AND t.SettledTime >= @FDate AND t.SettledTime < @TDate
		GROUP BY
			t.CustId, t.UserName, t.CurrencyId, t.SiteId, t.GameType
			,DATEADD(HOUR, DATEPART(HOUR, t.TransTime), CONVERT(VARCHAR(10), t.TransTime, 120)) -- date & hour
			,DATEADD(HOUR, DATEPART(HOUR, t.SettledTime), CONVERT(VARCHAR(10), t.SettledTime, 120)) -- date & hour
			,t.TicketStatus

		UPDATE t
		SET t.IsTest = c.IsTest
		FROM #__N88_SumWinloss t
			INNER JOIN dbo.Customer c WITH (NOLOCK) ON t.CustId = c.CustId
		WHERE c.IsTest = 1
	END

	-- Gen data into N88_RptWinloss
	BEGIN
		WITH CTE_N88_SumWinloss AS
		(
			SELECT CustId, UserName, IsTest, Currency, SiteId, GameType, TransTime, SettledTime, TurnOver, ValidBet, Winloss, BetCount, StatusId
			FROM dbo.N88_SumWinloss WITH (NOLOCK)
			WHERE SettledTime >= @FDate AND SettledTime < @TDate
		)
		UPDATE t
		SET t.DataType = CASE	WHEN t.SettledTime IS NULL THEN -1 -- delete
								WHEN c.SettledTime IS NULL THEN 1 -- insert
								ELSE 0 END -- update
		FROM #__N88_SumWinloss t
			FULL OUTER JOIN CTE_N88_SumWinloss c
				ON		t.SettledTime	= c.SettledTime
					AND t.SiteId		= c.SiteId
					AND t.CustId		= c.CustId
					AND t.UserName		= c.UserName
					AND t.Currency		= c.Currency
					AND t.GameType		= c.GameType
					AND t.TransTime		= c.TransTime
					AND t.SettledTime	= c.SettledTime
					AND t.StatusId		= c.StatusId
		WHERE t.SettledTime IS NULL
			OR c.SettledTime IS NULL
			OR ISNULL(t.TurnOver, 0)	<> ISNULL(c.TurnOver, 0)
			OR ISNULL(t.ValidBet, 0)	<> ISNULL(c.ValidBet, 0)
			OR ISNULL(t.Winloss, 0)		<> ISNULL(c.Winloss, 0)
			OR ISNULL(t.BetCount, 0)	<> ISNULL(c.BetCount, 0)

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
						AND s.SettledTime	= t.SettledTime
						AND s.StatusId		= t.StatusId
			WHERE t.DataType = -1

		-- Update
		IF EXISTS (SELECT 1 FROM #__N88_SumWinloss WHERE DataType = 0)
			UPDATE s WITH (ROWLOCK)
			SET s.TurnOver		= t.TurnOver
				,s.ValidBet		= t.ValidBet
				,s.Winloss		= t.Winloss
				,s.BetCount		= t.BetCount
			FROM dbo.N88_SumWinloss s
				INNER JOIN #__N88_SumWinloss t
					ON		s.SettledTime	= t.SettledTime
						AND s.SiteId		= t.SiteId
						AND s.CustId		= t.CustId
						AND s.UserName		= t.UserName
						AND s.Currency		= t.Currency
						AND s.GameType		= t.GameType
						AND s.TransTime		= t.TransTime
						AND s.SettledTime	= t.SettledTime
						AND s.StatusId		= t.StatusId
			WHERE t.DataType = 0

		-- Insert
		IF EXISTS (SELECT 1 FROM #__N88_SumWinloss WHERE DataType = 1)
			INSERT INTO dbo.N88_SumWinloss (CustId, UserName, IsTest, Currency, SiteId, GameType, TransTime, SettledTime, TurnOver, ValidBet, Winloss, BetCount, StatusId)
			SELECT CustId, UserName, IsTest, Currency, SiteId, GameType, TransTime, SettledTime, TurnOver, ValidBet, Winloss, BetCount, StatusId
			FROM #__N88_SumWinloss
			WHERE DataType = 1
	END

	DROP TABLE #__N88_SumWinloss
END
GO