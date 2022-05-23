/*<info serverAlias="DBLIC-bodb_LicenseeReport,DBBAL-bodb_LicenseeReport" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Task_rptLicWinlossGMT_CheckData]
	@WinLostDate SMALLDATETIME
AS

/*
	Created: 20171130@Sophia
	Task: Check sum for RptLicWinlossGMT vs bettrans14
	DB: DBLIC.bodb_LicenseeReport
	
	Revisions:
		- 20171130@Sophia: initial data. Apply for Sportsbook first [redmine: #84932]
		- 20180830@Amanda: support GMT +7 [redmine: #95878]
		- 20181019@Amanda: Add new bet types for E-Sports 2.0 [RedmineID: #100721]
		- 20181113@Joseph: New betfrom Mobile App (o) [RedmineID: #104587]
		- 20181211@Joseph: New betfrom Mobile China View (c) [RedmineID: #106088]
		- 20190311@Parsons: Implement BetBuilder [Redmine: #108995]
		- 20190903@Amanda: Add betfrom Deep Link(t) [RedmineID: #119010]
		- 20190910@Amanda: Add bet types that support Half Won/ Half Lose [RedmineID: #118300]
		- 20190923@Amanda: Change the way to handle Half Won/ Half Lose bet types [RedmineID: #119879]
		- 20191010@Percy: Replace LicenseeBATransaction to LicenseeBATransaction_bk [RedmineID: #103656]
		- 20191219@Amanda: Add betfrom v [RedmineID: #125553]
		- 20191226@Vickie: Add platform 0 [RedmineID: #125824]
		- 20200228@Vickie: Integrate 3 new betfrom [Redmine: #129253]
		- 20200508@Vickie: Add new bet types for E-Sports 2.0 [RedmineID: #132548]
		- 20200622@Hogan: Integrate 3 new betfrom 4, 5, 6 [Redmine: #136107]
		- 20210120@Mark: Integrate new betfrom 7 [Redmine: #149108]
		- 20210305@Mark: Integrate new betfrom _, @, %(Mobile Euro) [Redmine: #151019]
		- 20210315@Hogan: Integrate Cricket AIO [RedmineID: #150386]
		- 20210412@Mark: Support Add New Betfrom 8 9 [RedmineID: #152158]
		- 20210507@Mark: Support new betfrom and multiple selection on Platform filter [Redmine: #153102]
		- 20210527@Hogan: Support Add 2 New Betfroms # $ [RedmineID: #155922]
		- 20210816@Sophia: add DBBAL [Redmine: #154300] 
		- 20211014@Hogan: Support Add 2 New Betfroms [ ] [RedmineID: #162388]
		- 20211117@Kos: Merge Sports Lottery into Sportsbook [RedmineID: #163191]
		- 20211231@Hogan: Using betfrom '.' instead of betfrom '#' [RedmineID: #166689]
		- 20220211@Kos: Integrate Cricket phase 2 [RedmineID: #168034]
		- 20220513@Hogan: Integrate BitCoin [RedmineID: #160160]

	EXEC Task_rptLicWinlossGMT_CheckData '2017-11-30'
*/

BEGIN
	SET NOCOUNT ON;

	DECLARE @SportBettype TABLE(ProductId TINYINT, BetType SMALLINT, EventType TINYINT)

	INSERT INTO @SportBettype
	SELECT ProductID, BetType, EventType
	FROM bodb02.dbo.f_SportBettypeMatrix_Sel (0, 0, 0, 2, '', '', 1)
	WHERE ProductID IN (1, 63, 69)
		AND BetType NOT BETWEEN 901 AND 904

	CREATE TABLE #Source
	(
		TimeZone SMALLINT,
		RptDate SMALLDATETIME,
		RptDateGMT SMALLDATETIME,
		Custid INT,
		Bettype SMALLINT,
		Sporttype SMALLINT,
		ProductId SMALLINT,
		Turnover MONEY,
		Winlost MONEY,
		AWinlost MONEY,
		MWinlost MONEY,
		SWinlost MONEY,
		PlayerComm MONEY,
		Comm MONEY,
		AComm MONEY,
		SComm MONEY,
		BetEffective MONEY,
		BetCount INT,
		Currency SMALLINT,
		StatusID SMALLINT,
		IsBA BIT,
		IsMobile BIT,
		Betfrom NVARCHAR(1) 
	);

	CREATE TABLE #Target
	(
		TimeZone SMALLINT,
		RptDate SMALLDATETIME,
		RptDateGMT SMALLDATETIME,
		Custid INT,
		Bettype SMALLINT,
		Sporttype SMALLINT,
		ProductId SMALLINT,
		Turnover MONEY,
		Winlost MONEY,
		AWinlost MONEY,
		MWinlost MONEY,
		SWinlost MONEY,
		PlayerComm MONEY,
		Comm MONEY,
		AComm MONEY,
		SComm MONEY,
		BetEffective MONEY,
		BetCount INT,
		Currency SMALLINT,
		StatusID SMALLINT,
		IsBA BIT,
		IsMobile BIT,
		Betfrom NVARCHAR(1) 
	);

	DECLARE @HWHLCutDate SMALLDATETIME = '2019-10-01' -- half won/ half lose cut date
	DECLARE @TimeZones TABLE (RecordID TINYINT IDENTITY(1, 1), TimeZone SMALLINT);

	INSERT INTO @TimeZones(TimeZone)
	VALUES(8),(7);

	DECLARE
		@S_Count INT = 0,
		@T_Count INT = 0,
		@i INT,
		@RecordID TINYINT = 1,
		@ProcessingTimeZone SMALLINT;

	WHILE EXISTS (SELECT 1 FROM @TimeZones WHERE RecordID = @RecordID)
	BEGIN
		SELECT @ProcessingTimeZone = TimeZone
		FROM @TimeZones
		WHERE RecordID = @RecordID

		INSERT INTO #Source (
			TimeZone, RptDate, RptDateGMT, Custid, Bettype, Sporttype, ProductId,
			Turnover, Winlost, AWinlost, MWinlost, SWinlost,
			PlayerComm, Comm, AComm, SComm,
			BetEffective, BetCount,
			Currency, StatusID, IsBA, IsMobile, Betfrom
		)
		SELECT
			@ProcessingTimeZone AS TimeZone
			,b.winlostdate
			,CONVERT(DATE, DATEADD(HOUR, @ProcessingTimeZone + 4, CASE
																		WHEN sbt.ProductId = 69 THEN ISNULL(m3rd.StartTime, b.Winlostdate)
																		WHEN sbt.ProductId = 63 THEN b.transdate
																		ELSE ISNULL(m.GlobalShowTime, b.winlostdate)
																	END)) AS RptDateGMT
			,b.custid
			,0
			,0
			,0
			,SUM(ABS(b.stake)) AS TurnOver
			,SUM(b.winlost - b.actual_stake) AS winlost
			,SUM(b.awinlost) AS awinlost
			,SUM(b.mwinlost) AS mwinlost
			,SUM(ISNULL(b.swinlost, 0)) AS swinlost
			,SUM(b.playercomm) AS playercomm
			,SUM(b.comm) AS comm
			,SUM(b.acomm) AS acomm
			,SUM(ISNULL(b.scomm, 0)) AS scomm
			,CASE
				WHEN b.statusID IN (112, 113) THEN SUM(ABS(b.winlost - b.actual_stake))
				ELSE 0
			END AS BetEffective
			,COUNT(b.transid) AS BetCount
			,b.currency
			--114: half win, 115: half lose
			,CASE
				WHEN b.winlostdate >= @HWHLCutDate
					AND b.statusID IN (112, 113)
					AND b.modds IN (-0.25, 0.25)
					AND b.bettype NOT IN (29, 38)
					THEN CASE WHEN b.statusID = 112 THEN 114 ELSE 115 END 
				WHEN b.winlostdate < @HWHLCutDate
					AND b.statusID IN (112, 113)
					AND b.bettype IN (1,3,7,8,17,18,124,125,482,483,484,485)
					AND ABS(b.modds) = 0.25
					THEN CASE WHEN b.statusID = 112 THEN 114 ELSE 115 END
				ELSE b.statusID
			END AS statusID
			,CASE
				WHEN BA.transid IS NULL THEN 0
				WHEN BA.transid IS NOT NULL THEN 1
			END AS isBA
			,CASE
				WHEN b.betfrom IN ('s','m','l','r','o','c','2','5','_','@','%','7','8','~','.','$',']') THEN 1
				ELSE 0
			END AS isMobile
			,CASE
				WHEN b.betfrom IN ('a','d','e','u','s','m','l','g','r','x','y','z','o','c','t','v','0','1','2','3','4','5','6','7','_','@','%','8','9','>','~','^','.','$','[',']') THEN b.betfrom
				ELSE ''
			END AS betfrom
		FROM bodb02.dbo.bettrans14 AS b WITH (NOLOCK)
			INNER JOIN @SportBettype AS sbt ON sbt.BetType = b.bettype
			LEFT JOIN bodb02.dbo.match14 AS m WITH (NOLOCK) ON m.matchid = b.MatchId
			INNER JOIN bodb02.dbo.Dep_CustSuper AS s WITH (NOLOCK) ON b.srecommend = s.CustId
			LEFT JOIN bodb_Licensee.dbo.LicenseeBATransaction_bk AS BA WITH (NOLOCK) ON b.transid = BA.transid
			LEFT JOIN bodb02.dbo.Match3rd14 AS m3rd WITH (NOLOCK)
				ON b.matchid = m3rd.match3rdId
		WHERE b.Winlostdate = @WinlostDate
			AND b.statusID IN (101, 111, 112, 113)		--REJECT, DRAW, WON, LOSE
			AND b.bettype <= 19999
		GROUP BY
			b.winlostdate
			,CONVERT(DATE, DATEADD(HOUR, @ProcessingTimeZone + 4, CASE
																		WHEN sbt.ProductId = 69 THEN ISNULL(m3rd.StartTime, b.Winlostdate)
																		WHEN sbt.ProductId = 63 THEN b.transdate
																		ELSE ISNULL(m.GlobalShowTime, b.winlostdate)
																	END))
			,b.custid
			,b.currency
			,b.StatusId
			--114: half win, 115: half lose
			,CASE
				WHEN b.winlostdate >= @HWHLCutDate
					AND b.statusID IN (112, 113)
					AND b.modds IN (-0.25, 0.25)
					AND b.bettype NOT IN (29,38)
					THEN CASE WHEN b.statusID = 112 THEN 114 ELSE 115 END
				WHEN b.winlostdate < @HWHLCutDate
					AND b.statusID IN (112, 113)
					AND b.bettype IN (1,3,7,8,17,18,124,125,482,483,484,485)
					AND ABS(b.modds) = 0.25
					THEN CASE WHEN b.statusID = 112 THEN 114 ELSE 115 END 
				ELSE b.statusID
			END
			,CASE
				WHEN BA.transid IS NULL THEN 0
				WHEN BA.transid IS NOT NULL THEN 1
			END
			,CASE
				WHEN b.betfrom IN ('s','m','l','r','o','c','2','5','_','@','%','7','8','~','.','$',']') THEN 1
				ELSE 0
			END
			,CASE
				WHEN b.betfrom IN ('a','d','e','u','s','m','l','g','r','x','y','z', 'o','c','t','v','0','1','2','3','4','5','6','7','_','@','%','8','9','>','~','^','.','$','[',']') THEN b.betfrom
				ELSE ''
			END;

		SET @S_Count = @S_Count + @@ROWCOUNT;

		SET @RecordID = @RecordID + 1;
	END

	INSERT INTO #Target (
		TimeZone, RptDate, RptDateGMT, Custid, Bettype, Sporttype, ProductId,
		Turnover, Winlost, AWinlost, MWinlost, SWinlost,
		PlayerComm, Comm, AComm, SComm,
		BetEffective, BetCount,
		Currency, StatusID, IsBA, IsMobile, Betfrom
	)
	SELECT
		TimeZone, RptDate, RptDateGMT, Custid, Bettype, Sporttype, ProductId,
		ISNULL(SUM(Turnover), 0), ISNULL(SUM(Winlost), 0), ISNULL(SUM(AWinlost), 0), ISNULL(SUM(MWinlost), 0), ISNULL(SUM(SWinlost), 0),
		ISNULL(SUM(PlayerComm), 0), ISNULL(SUM(Comm), 0), ISNULL(SUM(AComm), 0), ISNULL(SUM(SComm), 0),
		ISNULL(SUM(BetEffective), 0), ISNULL(SUM(BetCount), 0),
		Currency, StatusID, IsBA, IsMobile, Betfrom
	FROM dbo.rptLicWinlossGMT WITH(NOLOCK)
	WHERE RptDate = @WinlostDate
		AND Roleid = 1
	GROUP BY TimeZone, RptDate, RptDateGMT, Custid, Bettype, Sporttype, ProductId,
		Currency, StatusID, IsBA, IsMobile, Betfrom;

	SET @T_Count = @@ROWCOUNT;

	IF @S_Count = 0 AND @T_Count = 0
	BEGIN
		RETURN;
	END

	CREATE TABLE #Log(TableName VARCHAR(100), IsSource BIT, BetTypeId INT, CurrencyId INT, Turnover MONEY, Winloss MONEY, BetCount INT, ExtraInfo VARCHAR(MAX));

	INSERT INTO #Log(TableName, IsSource, BetTypeId, CurrencyId, Turnover, Winloss, BetCount, ExtraInfo)
	SELECT 'bettrans14', 1, Bettype, Currency, SUM(Turnover), SUM(Winlost), SUM(BetCount),
		(
			SELECT	TimeZone AS TZ, RptDateGMT AS GMT, ProductId AS PID, Custid AS CID,
					SUM(AWinlost) AS WLA, SUM(MWinlost) AS WLM, SUM(SWinlost) AS WLS, 
					SUM(PlayerComm) AS CommP, SUM(Comm) AS CommA, SUM(AComm) AS CommM, SUM(SComm) AS CommS,
					SUM(BetEffective) AS BetEff
			FROM #Source s1
			WHERE s1.Bettype = s.Bettype
				AND s1.Currency = s.Currency
			GROUP BY TimeZone, RptDateGMT, Custid, ProductId
			FOR XML PATH('')
		) AS ExtraInfo
	FROM #Source s
	WHERE NOT EXISTS (
		SELECT 1
		FROM #Target t 
		WHERE s.TimeZone = t.TimeZone AND s.RptDate = t.RptDate AND s.RptDateGMT = t.RptDateGMT
			AND s.Custid = t.Custid AND s.Bettype = t.Bettype AND s.Sporttype = t.Sporttype
			AND s.ProductId = t.ProductId AND s.Currency = t.Currency AND s.StatusID = t.StatusID 
			AND s.IsBA = t.IsBA AND s.IsMobile = t.IsMobile AND s.Betfrom = t.Betfrom
			AND s.Turnover = t.Turnover AND s.Winlost = t.Winlost AND s.AWinlost = t.AWinlost
			AND s.MWinlost = t.MWinlost AND s.SWinlost = t.SWinlost AND s.PlayerComm = t.PlayerComm
			AND s.Comm = t.Comm AND s.AComm = t.AComm AND s.SComm = t.SComm 
			AND s.BetEffective = t.BetEffective
			AND s.BetCount = t.BetCount)
	GROUP BY Bettype, Currency

	UNION ALL

	SELECT 'rptLicWinlossGMT', 0, Bettype, Currency, SUM(Turnover), SUM(Winlost), SUM(BetCount),
		(
			SELECT	TimeZone AS TZ, RptDateGMT AS GMT, ProductId AS PID, Custid AS CID,
					SUM(AWinlost) AS WLA, SUM(MWinlost) AS WLM, SUM(SWinlost) AS WLS, 
					SUM(PlayerComm) AS CommP, SUM(Comm) AS CommA, SUM(AComm) AS CommM, SUM(SComm) AS CommS,
					SUM(BetEffective) AS BetEff
			FROM #Target t1
			WHERE t1.Bettype = t.Bettype
				AND t1.Currency = t.Currency
			GROUP BY TimeZone, RptDateGMT, Custid, ProductId
			FOR XML PATH('')
		) AS ExtraInfo
	FROM #Target t
	WHERE NOT EXISTS (
		SELECT 1
		FROM #Source s 
		WHERE s.TimeZone = t.TimeZone AND s.RptDate = t.RptDate AND s.RptDateGMT = t.RptDateGMT
			AND s.Custid = t.Custid AND s.Bettype = t.Bettype AND s.Sporttype = t.Sporttype
			AND s.ProductId = t.ProductId AND s.Currency = t.Currency AND s.StatusID = t.StatusID 
			AND s.IsBA = t.IsBA AND s.IsMobile = t.IsMobile AND s.Betfrom = t.Betfrom
			AND s.Turnover = t.Turnover AND s.Winlost = t.Winlost AND s.AWinlost = t.AWinlost
			AND s.MWinlost = t.MWinlost AND s.SWinlost = t.SWinlost AND s.PlayerComm = t.PlayerComm
			AND s.Comm = t.Comm AND s.AComm = t.AComm AND s.SComm = t.SComm 
			AND s.BetEffective = t.BetEffective
			AND s.BetCount = t.BetCount)
	GROUP BY Bettype, Currency;

	SET @T_Count = @@ROWCOUNT;

	IF @T_Count = 0
	BEGIN
		RETURN;
	END

	INSERT INTO dbo.DataCheckingLog(WinlostDate, SPName, TableName, IsSource, BetTypeId, CurrencyId, Turnover, Winloss, BetCount, ExtraInfo)
	SELECT
		@WinlostDate, 
		'Task_rptLicWinlossGMT_CheckData', 
		TableName, 
		IsSource,
		BetTypeId, 
		CurrencyId, 
		Turnover, 
		Winloss,
		BetCount,
		ExtraInfo
	FROM #Log;

	EXEC dbo.Task_DailyRptLicWinlossGMT_Bettrans14 @FromDate = @winlostdate;

	DROP TABLE #Log;
	DROP TABLE #Source;
	DROP TABLE #Target;
END
GO
