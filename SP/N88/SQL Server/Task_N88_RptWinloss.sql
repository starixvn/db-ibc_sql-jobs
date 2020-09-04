/*<info serverAlias="DBN88-bodb_N88" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_N88_RptWinloss]
	@WinlostDate SMALLDATETIME
AS

/*
	Created: 20200506@Sol
	DB: DBN88-bodb_N88
	Task: Job - Import data of 3rd Products

	Revisions:
		- 20200506@Sol: Initialize SP [RedmineID: #133254]
		- 20200506@Sol: Remove IsTest column in N88_RptWinloss [RedmineID: #135372]
		- 20200710@Sol: Support multiple timezone in N88_RptWinloss [RedmineID: #137064]
		- 20200818@Percy: Add column ValidBet [RedmineID: #137395]
*/

BEGIN
	SET NOCOUNT ON

	-- Get data
	BEGIN

		CREATE TABLE #tmpN88_RptWinloss
		(
			WinlostDate		DATE NOT NULL,
			CustId			INT NOT NULL,
			GameType		INT NOT NULL,
			Currency		INT NOT NULL,
			TurnOver		MONEY NULL,
			ValidBet		MONEY NULL,
			Winloss			MONEY NULL,
			BetCount		INT NULL,
			LicenseeID		INT NOT NULL,
			StatusID		TINYINT NOT NULL,
			UserName		VARCHAR(30) NOT NULL,
			WinlostDateGMT	DATE NOT NULL,
			TimeZone		SMALLINT NOT NULL,
			TransDate		DATE NOT NULL,
			TransDateGMT	DATE NOT NULL
		)
		
		;WITH rs AS 
		(
			SELECT 
				CAST(DATEADD(hh, -4, transtime) AS DATE) transdate,
				CAST(DATEADD(hh, tz.timeZone, transtime) AS DATE) transdateGMT,
				CAST(DATEADD(hh, -4, SettledTime) AS DATE) WinlostDate,
				td.CustId, td.UserName, GameType, td.CurrencyId,
				CASE WHEN exCode.Code IN ('VND', 'IDR') THEN Stake/1000 ELSE Stake END Stake,
				CASE WHEN exCode.Code IN ('VND', 'IDR') THEN ISNULL(ValidBet, Stake)/1000 ELSE ISNULL(ValidBet, Stake) END ValidBet,
				CASE WHEN exCode.Code IN ('VND', 'IDR') THEN winlostamount/1000 ELSE winlostamount END winlostamount,
				transid, l.LicenseeID, TicketStatus,
				CAST(DATEADD(hh, tz.timeZone, SettledTime) AS DATE) WinlostDateGMT,
				tz.timeZone
			FROM dbo.TpBetRecord td WITH(NOLOCK)
				INNER JOIN bodb02.dbo.Exchange exCode WITH(NOLOCK)
					ON td.CurrencyId = exCode.exchangeid
				INNER JOIN dbo.ServerInfo s WITH(NOLOCK)
					ON td.SiteId = s.SiteId
				INNER JOIN bodb_licensee.dbo.Licensees l WITH(NOLOCK)
					ON l.LicenseeName = s.LicenseeName
				CROSS JOIN (VALUES (-4), (0), (8)) tz (timeZone)
			WHERE 
				WinlostDate BETWEEN DATEADD(DAY, -1, @WinlostDate) AND DATEADD(DAY, 1, @WinlostDate)
				AND CAST(DATEADD(hh, -4, SettledTime) as date) = @WinlostDate
		)

		INSERT INTO #tmpN88_RptWinloss 
		(
			TransDate, TransDateGMT, WinlostDate, WinlostDateGMT, CustId, UserName, GameType, 
			Currency, TurnOver, ValidBet, Winloss, BetCount, LicenseeID, TimeZone, StatusID
		)
		SELECT transdate, transdateGMT, WinlostDate ,WinlostDateGMT, CustId, UserName, GameType, CurrencyId, 
			SUM(stake) AS turnover, SUM(ValidBet) AS ValidBet, SUM(winlostamount) ggr, COUNT(transid) betcount, rs.LicenseeID, timezone
			,TicketStatus
		FROM rs
		GROUP BY transdate, transdateGMT, WinlostDate ,WinlostDateGMT, CustId, UserName, GameType, CurrencyId, LicenseeID, timezone, TicketStatus
	END

	-- Gen data into N88_RptWinloss
	MERGE dbo.N88_RptWinloss AS TARGET
	USING #tmpN88_RptWinloss AS SOURCE
	ON 
			TARGET.TransDate = SOURCE.TransDate
		AND TARGET.TransDateGMT = SOURCE.TransDateGMT
		AND TARGET.WinlostDate = SOURCE.WinlostDate
		AND TARGET.WinlostDateGMT = SOURCE.WinlostDateGMT
		AND TARGET.CustId = SOURCE.CustId
		AND TARGET.GameType = SOURCE.GameType
		AND TARGET.LicenseeID = SOURCE.LicenseeID
		AND TARGET.StatusID = SOURCE.StatusID
		AND TARGET.TimeZone	= SOURCE.TimeZone
	WHEN MATCHED THEN 
		UPDATE 
			SET
				TARGET.Currency			= SOURCE.Currency
				,TARGET.TurnOver		= SOURCE.TurnOver
				,TARGET.ValidBet		= SOURCE.ValidBet
				,TARGET.Winloss			= SOURCE.Winloss
				,TARGET.BetCount		= SOURCE.BetCount
				,TARGET.UserName		= SOURCE.UserName
	WHEN NOT MATCHED BY TARGET THEN 
		INSERT (TransDate, TransDateGMT, WinlostDate, WinlostDateGMT, CustId, UserName, GameType, Currency, TurnOver, ValidBet, Winloss, BetCount, LicenseeID, TimeZone, StatusID)
		VALUES 
		(
			SOURCE.TransDate,
			SOURCE.TransDateGMT,
			SOURCE.WinlostDate,
			SOURCE.WinlostDateGMT,
			SOURCE.CustId,
			SOURCE.UserName,
			SOURCE.GameType,
			SOURCE.Currency,
			SOURCE.TurnOver,
			SOURCE.ValidBet,
			SOURCE.Winloss,
			SOURCE.BetCount,
			SOURCE.LicenseeID,
			SOURCE.TimeZone,
			SOURCE.StatusID
		)
	WHEN NOT MATCHED BY SOURCE AND TARGET.WinlostDate = @Winlostdate THEN
		DELETE;

	DROP TABLE #tmpN88_RptWinloss
END
GO