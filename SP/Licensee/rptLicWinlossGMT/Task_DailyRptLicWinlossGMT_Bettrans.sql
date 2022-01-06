/*<info serverAlias="DBLIC-bodb_LicenseeReport,DBBAL-bodb_LicenseeReport" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Task_DailyRptLicWinlossGMT_Bettrans] 
	@FromDate	SMALLDATETIME,
	@ToDate		SMALLDATETIME	= NULL,
	@TimeZone	SMALLINT		= NULL
AS

/*
	Created: 20171130@Sophia
	Task: Daily summary for RptLicWinlossGMT from bettrans
	DB: DBLIC.bodb_LicenseeReport

	Revisions:
		- 20171130@Sophia: initial data. Apply for Sportsbook first [redmine: #84932]
		- 20180806@Amanda: support GMT +7 [redmine: #95878]
		- 20181019@Amanda: Add new bet types for E-Sports 2.0 [RedmineID: #100721]
		- 20181113@Joseph: New betfrom Mobile App (o) [RedmineID: #104587]
		- 20181211@Joseph: New betfrom Mobile China View (c) [RedmineID: #106088]
		- 20190311@Parsons: Implement BetBuilder [Redmine: #108995]
		- 20190903@Amanda: Add platform Deep Link(t) [RedmineID: #119010]
		- 20190910@Amanda: Add bet types that support Half Won/ Half Lose [RedmineID: #118300]
		- 20190923@Amanda: Change the way to handle Half Won/ Half Lose bet types [RedmineID: #119879]
		- 20191010@Percy: Replace LicenseeBATransaction to LicenseeBATransaction_active [RedmineID: #103656]
		- 20191219@Amanda: Add betfrom v [RedmineID: #125553]
		- 20191226@Vickie: Add platform 0 [RedmineID: #125824]
		- 20200228@Vickie: Integrate 3 new betfrom [Redmine: #129253]
		- 20200508@Vickie: Add new bet types for E-Sports 2.0 [RedmineID: #132548]
		- 20200622@Hogan: Integrate 3 new betfrom 4, 5, 6 [Redmine: #136107]
		- 20201001@Louis: Licensee Spread Setting [RedmineID: #142532]
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
*/

BEGIN
	SET NOCOUNT ON

	IF @ToDate IS NULL
	BEGIN
		SET @ToDate = @FromDate
	END

	DECLARE @HWHLCutDate SMALLDATETIME = '2019-10-01' -- half won/ half lose cut date
	DECLARE @TimeZones TABLE (RecordID TINYINT IDENTITY(1, 1), TimeZone SMALLINT)

	IF @TimeZone IS NULL
	BEGIN
		INSERT INTO @TimeZones(TimeZone)
		VALUES (8),(7)
	END
	ELSE
	BEGIN
		INSERT INTO @TimeZones(TimeZone)
		VALUES (@TimeZone)
	END

	DECLARE @RecordID TINYINT = 1,
			@RptDate SMALLDATETIME,
			@ProcessingTimeZone SMALLINT

	WHILE EXISTS (SELECT 1 FROM @TimeZones WHERE RecordID = @RecordID)
	BEGIN
		SELECT @RptDate = @FromDate

		SELECT @ProcessingTimeZone = TimeZone
		FROM @TimeZones
		WHERE RecordID = @RecordID

		WHILE @RptDate <= @ToDate
		BEGIN
			DELETE FROM dbo.rptLicWinlossGMT WITH(ROWLOCK, UPDLOCK)
			WHERE RptDate = @RptDate AND TimeZone = @ProcessingTimeZone

			-- Member Level
			INSERT INTO dbo.rptLicWinlossGMT (
				TimeZone
				,RptDate
				,RptDateGMT
				,Username
				,Username2
				,Custid
				,Roleid
				,Recommend
				,Mrecommend
				,Srecommend
				,Bettype
				,Sporttype
				,ProductId
				,Turnover
				,Winlost
				,AWinlost
				,MWinlost
				,SWinlost
				,BetEffective
				,playercomm
				,Comm
				,AComm
				,SComm
				,WinlostVirtual
				,CommVirtual
				,BetCount
				,Currency
				,StatusID
				,IsBA
				,IsMobile
				,Betfrom
				)
			SELECT
				@ProcessingTimeZone AS TimeZone
				,b.winlostdate
				,CONVERT(DATE, DATEADD(HOUR, @ProcessingTimeZone + 4, CASE
																		WHEN b.bettype BETWEEN 3611 AND 3620 THEN b.transdate
																		ELSE ISNULL(m.GlobalShowTime, b.winlostdate)
																	END)) AS RptDateGMT
				,c.username
				,c.username2
				,c.custid
				,1
				,c.recommend
				,c.mrecommend
				,c.srecommend
				,CASE 
					WHEN b.betType = 999 THEN b.betType			--Licensee Spread Setting
					ELSE 0 
				END BetType
				,0 AS Sporttype
				,0 AS ProductId
				,SUM(ABS(b.stake)) AS TurnOver
				,SUM(b.winlost - b.actual_stake) AS winlost
				,SUM(b.awinlost) AS awinlost
				,SUM(b.mwinlost) AS mwinlost
				,SUM(ISNULL(b.swinlost, 0)) AS swinlost
				,CASE
					WHEN b.statusID IN (112, 113) THEN SUM(ABS(b.winlost - b.actual_stake))
					ELSE 0
				END AS BetEffective
				,SUM(b.playercomm) AS playercomm
				,SUM(b.comm) AS comm
				,SUM(b.acomm) AS acomm
				,SUM(ISNULL(b.scomm, 0)) AS scomm
				,SUM((b.winlost - b.actual_stake) * b.virtualrate) AS WinlostVirtual
				,SUM(b.comm * b.virtualrate) AS CommVirtual
				,COUNT(b.transid) AS BetCount
				,b.currency
				--114: half win, 115: half lose
				,CASE
					WHEN b.winlostdate >= @HWHLCutDate
						AND b.bettype IN (112, 113)
						AND b.modds IN (-0.25, 0.25)
						AND b.bettype NOT IN (29, 38)
						THEN CASE WHEN b.bettype = 112 THEN 114 ELSE 115 END
					WHEN b.winlostdate < @HWHLCutDate
						AND b.statusID IN (112,113)
						AND b.bettype IN (1,3,7,8,17,18,124,125,482,483,484,485)
						AND ABS(b.modds) = 0.25
						THEN CASE WHEN b.bettype = 112 THEN 114 ELSE 115 END
					ELSE b.statusID
				END AS statusID
				,CASE
					WHEN BA.transid IS NULL THEN 0
					WHEN BA.transid IS NOT NULL THEN 1 END AS isBA
				,CASE
					WHEN b.betfrom IN ('s','m','l','r','o','c','2','5','_','@','%','7','8','~','.','$',']') THEN 1
					ELSE 0
				END AS isMobile
				,CASE
					WHEN b.betfrom IN ('a','d','e','u','s','m','l','g','r','x','y','z','o','c','t','v','0','1','2','3','4','5','6','7','_','@','%','8','9','>','~','^','.','$','[',']') THEN b.betfrom
					ELSE ''
				END AS betfrom
			FROM bodb02.dbo.bettrans AS b WITH (NOLOCK)
				LEFT JOIN bodb02.dbo.Match AS m WITH (NOLOCK) ON m.matchid = b.matchid
				INNER JOIN bodb02.dbo.Dep_CustSuper AS s WITH (NOLOCK) ON b.srecommend = s.custid
				INNER JOIN bodb02.dbo.Customer AS c WITH (NOLOCK) ON b.custid = c.custid
				LEFT JOIN bodb_Licensee.dbo.LicenseeBATransaction_active AS BA WITH (NOLOCK) ON b.transid = BA.transid
			WHERE
				b.winlostdate = @RptDate
				AND b.statusID IN (101, 111, 112, 113)	--REJECT, DRAW, WON, LOSE
				AND b.bettype <= 19999
				AND c.roleid = 1
				AND (
						b.bettype < 31
						OR b.bettype BETWEEN 121 AND 999
						OR b.bettype BETWEEN 1301 and 1399		--new tennis's bettypes
						OR b.bettype BETWEEN 9001 and 9399		-- E-Sports 2.0
						OR b.bettype BETWEEN 9400 AND 9699		-- Cricket AIO
						OR b.bettype = 38 -- BetBuilder
						OR b.bettype BETWEEN 3611 AND 3620		-- Sports Lottery
					)
				AND (b.bettype < 901 OR b.bettype > 904)
				AND (b.bettype < 911 OR b.bettype > 914)
			GROUP BY 
				b.winlostdate
				,CONVERT(DATE, DATEADD(HOUR, @ProcessingTimeZone + 4, CASE
																		WHEN b.bettype BETWEEN 3611 AND 3620 THEN b.transdate
																		ELSE ISNULL(m.GlobalShowTime, b.winlostdate)
																	END))
				,c.username
				,c.username2
				,c.custid
				,c.recommend
				,c.mrecommend
				,c.srecommend
				,b.currency
				,b.StatusId
				--114: half win, 115: half lose
				,CASE
					WHEN b.winlostdate >= @HWHLCutDate
						AND b.bettype IN (112, 113)
						AND b.modds IN (-0.25, 0.25)
						AND b.bettype NOT IN (29, 38)
						THEN CASE WHEN b.bettype = 112 THEN 114 ELSE 115 END
					WHEN b.winlostdate < @HWHLCutDate
						AND b.statusID IN (112, 113)
						AND b.bettype IN(1,3,7,8,17,18,124,125,482,483,484,485)
						AND ABS(b.modds) = 0.25
						THEN CASE WHEN b.bettype = 112 THEN 114 ELSE 115 END
					ELSE b.statusID
				END
				,CASE
					WHEN BA.transid IS NULL THEN 0
					WHEN BA.transid IS NOT NULL THEN 1 END
				,CASE
					WHEN b.betfrom IN ('s','m','l','r','o','c','2','5','_','@','%','7','8','~','.','$',']') THEN 1 ELSE 0 END
				,CASE
					WHEN b.betfrom IN ('a','d','e','u','s','m','l','g','r','x','y','z','o','c','t','v','0','1','2','3','4','5','6','7','_','@','%','8','9','>','~','^','.','$','[',']') THEN b.betfrom ELSE '' END
				,CASE
					WHEN b.betType = 999 THEN b.betType			--Licensee Spread Setting
					ELSE 0
				END

			-- Agent Level (sum on member)
			INSERT INTO dbo.rptLicWinlossGMT (
				TimeZone
				,RptDate
				,RptDateGMT
				,Username
				,Username2
				,Custid
				,Roleid
				,Recommend
				,Mrecommend
				,Srecommend
				,Bettype
				,Sporttype
				,ProductId
				,Turnover
				,Winlost
				,AWinlost
				,MWinlost
				,SWinlost
				,BetEffective
				,playercomm
				,Comm
				,AComm
				,SComm
				,WinlostVirtual
				,CommVirtual
				,BetCount
				,Currency
				,StatusID
				,IsBA
				,IsMobile
				,Betfrom
			)
			SELECT
				b.TimeZone
				,b.RptDate
				,b.RptDateGMT
				,c.Username
				,c.Username2
				,c.Custid
				,2
				,c.Recommend
				,c.Mrecommend
				,c.Srecommend
				,b.Bettype
				,b.Sporttype
				,b.ProductId
				,SUM(b.Turnover)
				,SUM(b.Winlost)
				,SUM(b.AWinlost)
				,SUM(b.MWinlost)
				,SUM(b.SWinlost)
				,SUM(b.BetEffective)
				,SUM(b.playercomm)
				,SUM(b.Comm)
				,SUM(b.AComm)
				,SUM(b.SComm)
				,SUM(b.WinlostVirtual)
				,SUM(b.CommVirtual)
				,SUM(b.BetCount)
				,b.Currency
				,b.StatusID
				,b.IsBA
				,b.IsMobile
				,b.Betfrom
			FROM dbo.rptLicWinlossGMT AS b WITH (NOLOCK)
				INNER JOIN bodb02.dbo.Customer AS c WITH (NOLOCK) ON b.recommend = c.custid  
			WHERE b.RptDate = @RptDate
				AND b.TimeZone = @ProcessingTimeZone
				AND b.roleid = 1
				AND c.roleid = 2
			GROUP BY
				b.TimeZone
				,b.RptDate
				,b.RptDateGMT
				,c.Username
				,c.Username2
				,c.Custid
				,c.Recommend
				,c.Mrecommend
				,c.Srecommend
				,b.Bettype
				,b.Sporttype
				,b.ProductId 
				,b.Currency
				,b.StatusID
				,b.IsBA
				,b.IsMobile
				,b.Betfrom

			SET @RptDate = DATEADD(DAY, 1, @RptDate)
		END

		SET @RecordID = @RecordID + 1
	END
END
GO
