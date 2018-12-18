/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_rptLicWinlossGMT_CheckData] 
	@WinlostDate SMALLDATETIME
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
	
	EXEC Task_rptLicWinlossGMT_CheckData '2017-11-30'

*/
BEGIN
	SET NOCOUNT ON;
	
	CREATE TABLE #Source
	(
		TimeZone smallint,
		RptDate smalldatetime,
		RptDateGMT smalldatetime,
		Custid int,
		Bettype smallint,
		Sporttype smallint,
		ProductId smallint,
		Turnover money,
		Winlost money,
		AWinlost money,
		MWinlost money,
		SWinlost money,
		PlayerComm money,
		Comm money,
		AComm money,
		SComm money,
		BetEffective money,
		BetCount int,
		Currency smallint,
		StatusID smallint,
		IsBA bit,
		IsMobile bit,
		Betfrom nvarchar(1) 
	);

	CREATE TABLE #Target
	(
		TimeZone smallint,
		RptDate smalldatetime,
		RptDateGMT smalldatetime,
		Custid int,
		Bettype smallint,
		Sporttype smallint,
		ProductId smallint,
		Turnover money,
		Winlost money,
		AWinlost money,
		MWinlost money,
		SWinlost money,
		PlayerComm money,
		Comm money,
		AComm money,
		SComm money,
		BetEffective money,
		BetCount int,
		Currency smallint,
		StatusID smallint,
		IsBA bit,
		IsMobile bit,
		Betfrom nvarchar(1) 
	);

	DECLARE @TimeZones TABLE (RecordID TINYINT IDENTITY(1, 1), TimeZone SMALLINT);

	INSERT INTO @TimeZones(TimeZone)
	VALUES(8),(7);

	DECLARE @S_Count INT = 0, @T_Count INT = 0,
			@i INT, @RecordID TINYINT = 1,
			@ProcessingTimeZone SMALLINT;

	WHILE EXISTS(SELECT 1 FROM @TimeZones WHERE RecordID = @RecordID)
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
		SELECT	@ProcessingTimeZone AS TimeZone	
				,b.winlostdate    
				,CONVERT(DATE, DATEADD(HOUR, @ProcessingTimeZone + 4, ISNULL(m.GlobalShowTime, b.Winlostdate))) AS RptDateGMT 
				,b.custid  
				,0
				,0
				,0
				,SUM(ABS(b.stake)) AS TurnOver  
				,SUM(winlost-actual_stake) winlost  		
				,SUM(awinlost) awinlost  
				,SUM(mwinlost) mwinlost  
				,SUM(ISNULL(swinlost,0)) swinlost    
				,SUM(playercomm) playercomm  
				,SUM(comm) comm  
				,SUM(acomm) acomm  
				,SUM(ISNULL(scomm,0)) scomm
				,CASE WHEN b.statusID IN (112,113)   
					THEN SUM(ABS(winlost-actual_stake))   
					ELSE 0  
					END BetEffective    
				,COUNT(b.transid) BetCount  
				,b.currency  
				--114: half win, 115: half lose  
				,CASE   
					WHEN b.statusID = 112 AND b.bettype IN(1,3,7,8,17,18) AND ABS(modds) = 0.25 THEN 114   
					WHEN b.statusID = 113 AND b.bettype IN(1,3,7,8,17,18) AND ABS(modds) = 0.25 THEN 115  
					ELSE b.statusID END AS statusID  
				,CASE   
					WHEN BA.transid IS NULL THEN 0  
					WHEN BA.transid IS NOT NULL THEN 1 END AS isBA  
				,CASE   
					WHEN b.betfrom IN ('s','m','l','r','o','c') THEN 1 ELSE 0 END AS isMobile   
				,CASE      
					WHEN b.betfrom IN ('a','d','e','u','s','m','l','g','r','x','y','z','o','c') THEN b.betfrom ELSE '' END AS betfrom   		
			FROM bodb02.dbo.bettrans14 b WITH (NOLOCK)
				LEFT JOIN bodb02.dbo.Match14 m WITH (NOLOCK)
					ON m.MatchId = b.MatchId
				INNER JOIN bodb02.dbo.Dep_CustSuper s WITH (NOLOCK) 
					ON b.srecommend = s.CustId
				LEFT JOIN bodb_Licensee.dbo.LicenseeBATransaction BA WITH (NOLOCK) 
					ON b.transid = BA.transid 	 
			WHERE  b.Winlostdate = @WinlostDate   
				AND b.statusID IN (101,111,112,113)  --REJECT, DRAW, WON, LOSE  
				AND b.bettype <= 19999   
				AND (
						b.bettype < 31
						OR b.bettype BETWEEN 121 AND 999
						OR b.Bettype BETWEEN 1301 and 1399 --new tennis's bettypes
						OR b.Bettype BETWEEN 9001 and 9086 -- E-Sports 2.0
					)
				AND (b.bettype < 901 OR b.bettype > 904)
				AND (b.bettype < 911 OR b.bettype > 914) 			 
			GROUP BY b.winlostdate
					,CONVERT(DATE, DATEADD(HOUR, @ProcessingTimeZone + 4, ISNULL(m.GlobalShowTime, b.Winlostdate)))
					,b.custid 
					,b.currency  
					,b.StatusId
					--114: half win, 115: half lose  
					,CASE   
						WHEN b.statusID = 112 AND b.bettype IN(1,3,7,8,17,18) AND ABS(modds) = 0.25 THEN 114   
						WHEN b.statusID = 113 AND b.bettype IN(1,3,7,8,17,18) AND ABS(modds) = 0.25 THEN 115  
						ELSE b.statusID END  
					,CASE   
						WHEN BA.transid IS NULL THEN 0  
						WHEN BA.transid IS NOT NULL THEN 1 END  
					,CASE   
						WHEN b.betfrom IN ('s','m','l','r','o','c') THEN 1 ELSE 0 END  
					,CASE      
						WHEN b.betfrom IN ('a','d','e','u','s','m','l','g','r','x','y','z', 'o','c') THEN b.betfrom ELSE '' END;

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
	SELECT	TimeZone, RptDate, RptDateGMT, Custid, Bettype, Sporttype, ProductId,
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
	SELECT	@WinlostDate, 
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