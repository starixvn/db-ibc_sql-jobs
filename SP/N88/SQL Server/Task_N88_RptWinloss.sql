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
		- 20210305@Percy: Separate merge statement to prevent scan table [RedmineID: #150398]
*/

BEGIN
	SET NOCOUNT ON

	-- Get data
	BEGIN
		CREATE TABLE #tmpData
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

		INSERT INTO #tmpData 
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
		TransDateGMT	DATE NOT NULL,
		DataType		SMALLINT
	)

	;WITH CTE_Source AS
	(
		SELECT WinlostDate,CustId,GameType,Currency,TurnOver,Winloss,BetCount,LicenseeID,StatusID,UserName,WinlostDateGMT,TimeZone,TransDate,TransDateGMT,ValidBet
		FROM dbo.N88_RptWinloss WITH (NOLOCK)
		WHERE WinlostDate = @WinlostDate
	)
	INSERT INTO #tmpN88_RptWinloss
	(
		WinlostDate
		,CustId
		,GameType
		,Currency
		,TurnOver
		,Winloss
		,BetCount
		,LicenseeID
		,StatusID
		,UserName
		,WinlostDateGMT
		,TimeZone
		,TransDate
		,TransDateGMT
		,ValidBet
		,DataType
	)
	SELECT
		ISNULL(d.WinlostDate, s.WinlostDate)
		,ISNULL(d.CustId, s.CustId)
		,ISNULL(d.GameType, s.GameType)
		,ISNULL(d.Currency, s.Currency)
		,ISNULL(d.TurnOver, s.TurnOver)
		,ISNULL(d.Winloss, s.Winloss)
		,ISNULL(d.BetCount, s.BetCount)
		,ISNULL(d.LicenseeID, s.LicenseeID)
		,ISNULL(d.StatusID, s.StatusID)
		,ISNULL(d.UserName, s.UserName)
		,ISNULL(d.WinlostDateGMT, s.WinlostDateGMT)
		,ISNULL(d.TimeZone, s.TimeZone)
		,ISNULL(d.TransDate, s.TransDate)
		,ISNULL(d.TransDateGMT, s.TransDateGMT)
		,ISNULL(d.ValidBet, s.ValidBet)
		,CASE
			WHEN d.WinlostDate IS NULL THEN -1 -- delete
			WHEN s.WinlostDate IS NULL THEN 1 -- insert
			ELSE 0 END -- update
	FROM #tmpData d
		FULL OUTER JOIN CTE_Source s
			ON		d.TransDate			= s.TransDate
				AND d.TransDateGMT		= s.TransDateGMT
				AND d.WinlostDate		= s.WinlostDate
				AND d.WinlostDateGMT	= s.WinlostDateGMT
				AND d.CustId			= s.CustId
				AND d.GameType			= s.GameType
				AND d.LicenseeID		= s.LicenseeID
				AND d.StatusID			= s.StatusID
				AND d.TimeZone			= s.TimeZone
	WHERE d.WinlostDate IS NULL
		OR s.WinlostDate IS NULL
		OR ISNULL(d.Currency, 0)	<> ISNULL(s.Currency, 0)
		OR ISNULL(d.TurnOver, 0)	<> ISNULL(s.TurnOver, 0)
		OR ISNULL(d.ValidBet, 0)	<> ISNULL(s.ValidBet, 0)
		OR ISNULL(d.Winloss, 0)		<> ISNULL(s.Winloss, 0)
		OR ISNULL(d.BetCount, 0)	<> ISNULL(s.BetCount, 0)
		OR ISNULL(d.UserName, '')	<> ISNULL(s.UserName, '')

	-- Delete
	IF EXISTS (SELECT 1 FROM #tmpN88_RptWinloss WHERE DataType = -1)
		DELETE r WITH (ROWLOCK, UPDLOCK)
		FROM dbo.N88_RptWinloss r
			INNER JOIN #tmpN88_RptWinloss t
				ON		r.TransDate			= t.TransDate
					AND r.TransDateGMT		= t.TransDateGMT
					AND r.WinlostDate		= t.WinlostDate
					AND r.WinlostDateGMT	= t.WinlostDateGMT
					AND r.CustId			= t.CustId
					AND r.GameType			= t.GameType
					AND r.LicenseeID		= t.LicenseeID
					AND r.StatusID			= t.StatusID
					AND r.TimeZone			= t.TimeZone
		WHERE t.DataType = -1

	-- Update
	IF EXISTS (SELECT 1 FROM #tmpN88_RptWinloss WHERE DataType = 0)
		UPDATE r WITH (ROWLOCK)
		SET r.Currency	= t.Currency
			,r.TurnOver	= t.TurnOver
			,r.ValidBet	= t.ValidBet
			,r.Winloss	= t.Winloss
			,r.BetCount	= t.BetCount
			,r.UserName	= t.UserName
		FROM dbo.N88_RptWinloss r
			INNER JOIN #tmpN88_RptWinloss t
				ON		r.TransDate			= t.TransDate
					AND r.TransDateGMT		= t.TransDateGMT
					AND r.WinlostDate		= t.WinlostDate
					AND r.WinlostDateGMT	= t.WinlostDateGMT
					AND r.CustId			= t.CustId
					AND r.GameType			= t.GameType
					AND r.LicenseeID		= t.LicenseeID
					AND r.StatusID			= t.StatusID
					AND r.TimeZone			= t.TimeZone
		WHERE t.DataType = 0

	-- Insert
	IF EXISTS (SELECT 1 FROM #tmpN88_RptWinloss WHERE DataType = 1)
		INSERT INTO dbo.N88_RptWinloss (WinlostDate, CustId, GameType, Currency, TurnOver, Winloss, BetCount, LicenseeID, StatusID, UserName, WinlostDateGMT, TimeZone, TransDate, TransDateGMT, ValidBet)
		SELECT WinlostDate, CustId, GameType, Currency, TurnOver, Winloss, BetCount, LicenseeID, StatusID, UserName, WinlostDateGMT, TimeZone, TransDate, TransDateGMT, ValidBet
		FROM #tmpN88_RptWinloss
		WHERE DataType = 1
	
	DROP TABLE #tmpN88_RptWinloss
END
GO