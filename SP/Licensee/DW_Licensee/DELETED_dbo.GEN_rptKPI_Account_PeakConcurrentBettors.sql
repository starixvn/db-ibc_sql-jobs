SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DELETED_GEN_rptKPI_Account_PeakConcurrentBettors]
    @date datetime
AS
/*
Created: 20111125@Don
Task: Generate data into rptKPI_Account for Peak concurrent bettors
DB: DB052.bodb_Licensee

Revisions:
    
Param's Explanation:

*/

DECLARE @nvDate nvarchar(10)
SET @nvDate = CONVERT(nvarchar(10), @date, 120)

CREATE TABLE #TotalOnline (KeyID int IDENTITY(1,1), LogHour tinyint, LogMinute tinyint, ServerGrp int, ServerID int, Users int)

IF (EXISTS (SELECT * FROM DB03.ON_USER.dbo.TotalOnline WITH(NOLOCK) WHERE LogDate BETWEEN @nvDate + ' 00:00' AND DATEADD(day, 1, @nvDate + ' 00:00')))
	INSERT INTO #TotalOnline
	    SELECT CAST(RIGHT(CONVERT(nvarchar(13),LogDate, 120),2) as tinyint) LogHour, CAST(RIGHT(CONVERT(nvarchar(16),LogDate, 120),2) as tinyint) LogMinute, 
	    CASE
		    WHEN ServerID BETWEEN 101050 AND 101059 THEN 1011 --INDO
		    WHEN ServerID = 200002 THEN 201 --A88
		    WHEN ServerID = 201101 THEN 201101 --A88 WAP
		    WHEN ServerID = 101101 THEN 101101 --IBCWAP
		    WHEN ServerID = 101102 THEN 101102 --IBCMobile
		    WHEN ServerID = 100001 THEN 900	--Admin
		    WHEN ServerID BETWEEN 90 AND 92 THEN 911	--Agent web
		    WHEN ServerID BETWEEN 93 AND 95 THEN 912	--Agent wap
		    WHEN ServerID BETWEEN 96 AND 98 THEN 913	--Agent iphone
		    WHEN ServerID = 100091 THEN 991
		    WHEN ServerID = 100092 THEN 992
		    WHEN ServerID = 100093 THEN 993
		    WHEN ServerID = 205000 THEN 205 --TLC		
		    WHEN ServerID = 204000 THEN 204 --spondemo
		    WHEN ServerID = 206000 THEN 206 --Dela
		    WHEN ServerID = 207000 THEN 207 --Suncity
		    WHEN ServerID = 208000 THEN 208 --Mayfair
		    WHEN ServerID = 209000 THEN 209 --Zzun88
		    WHEN ServerID = 210000 THEN 210 --Bezbet
		    WHEN ServerID = 211001 THEN 211 --Haifa
		    WHEN ServerID = 212000 THEN 212 --bodog
		    ELSE FLOOR(ServerID/1000)
	    END ServerGrp, ServerID, Users
	    FROM DB03.ON_USER.dbo.TotalOnline WITH(NOLOCK)
	    WHERE LogDate BETWEEN @nvDate + ' 00:00' AND DATEADD(day, 1, @nvDate + ' 00:00')
ELSE
	INSERT INTO #TotalOnline
	    SELECT CAST(RIGHT(CONVERT(nvarchar(13),LogDate, 120),2) as tinyint) LogHour, CAST(RIGHT(CONVERT(nvarchar(16),LogDate, 120),2) as tinyint) LogMinute, 
	    CASE 
		    WHEN ServerID BETWEEN 101050 AND 101059 THEN 1011 --INDO
		    WHEN ServerID = 200002 THEN 201 --A88
		    WHEN ServerID = 201101 THEN 201101 --A88 WAP
		    WHEN ServerID = 101101 THEN 101101 --IBCWAP
		    WHEN ServerID = 101102 THEN 101102 --IBCMobile
		    WHEN ServerID = 100001 THEN 900	--Admin
		    WHEN ServerID BETWEEN 90 AND 92 THEN 911	--Agent web
		    WHEN ServerID BETWEEN 93 AND 95 THEN 912	--Agent wap
		    WHEN ServerID BETWEEN 96 AND 98 THEN 913	--Agent iphone
		    WHEN ServerID = 100091 THEN 991
		    WHEN ServerID = 100092 THEN 992
		    WHEN ServerID = 100093 THEN 993
		    WHEN ServerID = 205000 THEN 205 --TLC			
		    WHEN ServerID = 204000 THEN 204 --spondemo
		    WHEN ServerID = 206000 THEN 206 --Dela
		    WHEN ServerID = 207000 THEN 207 --Suncity
		    WHEN ServerID = 208000 THEN 208 --Mayfair
		    WHEN ServerID = 209000 THEN 209 --Zzun88
		    WHEN ServerID = 210000 THEN 210 --Bezbet
		    WHEN ServerID = 211001 THEN 211 --Haifa	
		    WHEN ServerID = 212000 THEN 212 --bodog
		    ELSE FLOOR(ServerID/1000)
	    END ServerGrp, ServerID, Users
	    FROM DB03.ON_USER.dbo.TotalOnline_BK WITH(NOLOCK)
	    WHERE LogDate BETWEEN @nvDate + ' 00:00' AND DATEADD(day, 1, @nvDate + ' 00:00')

CREATE TABLE #tmp1 (LogHour tinyint, LogMinute tinyint, ServerGrp int, Users int)
INSERT INTO #tmp1
    SELECT LogHour, LogMinute, ServerGrp, SUM(Users) Users FROM #TotalOnline GROUP BY LogHour, LogMinute, ServerGrp

CREATE TABLE #tmp2 (LogHour tinyint, LogMinute tinyint, Users int, IsMax bit default 0)INSERT INTO #tmp2 (LogHour, LogMinute, Users)    SELECT LogHour, LogMinute, SUM(Users) users FROM #tmp1 WHERE ServerGrp < 900 GROUP BY LogHour, LogMinuteUPDATE #tmp2SET IsMax = 1FROM (SELECT LogHour, MAX(Users) Users FROM #tmp2 GROUP BY LogHour) XWHERE X.LogHour = #tmp2.LogHour AND X.Users = #tmp2.Users
CREATE TABLE #AvgUser (LogHour tinyint, ServerGrp int, Users int)
INSERT INTO #AvgUser
    SELECT a.LogHour, a.ServerGrp, a.Users
    FROM #tmp1 a INNER JOIN #tmp2 b ON a.LogHour = b.LogHour AND a.LogMinute = b.LogMinute
    WHERE b.IsMax = 1

DROP TABLE #TotalOnline
DROP TABLE #tmp1
DROP TABLE #tmp2

UPDATE acc
SET acc.PeakBettorCount = u.Users
FROM dbo.rptKPI_Account acc
    INNER JOIN dbo.view_site_servergroup srv ON acc.SiteID = srv.siteid 
    INNER JOIN #AvgUser u ON acc.Hour = u.LogHour AND srv.ServerGrp = u.ServerGrp
--WHERE acc.rptDate BETWEEN @nvDate + ' 00:00' AND DATEADD(day, 1, @nvDate + ' 00:00')
WHERE acc.rptDate = (@nvDate + ' 00:00')

DROP TABLE #AvgUser

GO
GRANT EXECUTE ON [dbo].[GEN_rptKPI_Account_PeakConcurrentBettors] TO [bodbLicenseeNet] 
GO
GRANT VIEW DEFINITION ON [dbo].[GEN_rptKPI_Account_PeakConcurrentBettors] TO [VNTeam]