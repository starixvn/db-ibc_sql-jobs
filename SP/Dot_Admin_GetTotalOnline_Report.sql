USE [ON_USER]
GO

/****** Object:  StoredProcedure [dbo].[Dot_Admin_GetTotalOnline_Report]    Script Date: 01/28/2015 04:33:20 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE[dbo].[Dot_Admin_GetTotalOnline_Report]
	@Date datetime
AS
/*
								add ServerID:206000 207000 208000 209000 210000    
20110802@Eric(DB03.ON_USER)	  :	add Haifa site 
20110920@Sylvia(DB03.ON_USER) : add bodog site
20111213@Ava(DB03.ON_USER) : add IBCSmart site
20111226@Ava(DB03.ON_USER) : Remove White Label Site 'Bezbet' (ServerID = 210000,ServerGrp = 210)
20120222@Ava(DB03.ON_USER) : add SunGame(4201000)/Tycoon(4201200)/SilverGoose8(4201500)/Vwin(4201100)
20120307@Ava(DB03.ON_USER) : Modify ServerID => Tycoon(215001)/SilverGoose8,SG8(214001)/Vwin(213001)
							 and rename Suncity to Sungame 
20120601@Daisy(DB03.ON_USER): add Macaubet site and Modify @nvDate nvarchar(10),@psDate nvarchar(10) to smalldatetime
20120626@Daisy(DB03.ON_USER): 1. Add IBOBet.
							  2. Reset ServerGrp.
							  3. remove [933].
20120822@Daisy(DB03.ON_USER): Add VCBET.
20120828@Daisy(DB03.ON_USER): Add AonCash.
20121121@Daisy(DB03.ON_USER): Add Bwinning, ITCbet, LiveBet365.
20130315@Daisy(DB03.ON_USER): Add i668bet , i228bet.
20130322@Daisy(DB03.ON_USER): Add yq355 , bcr999, lebao8888.
20130322@Daisy(DB03.ON_USER): Add wplace , mymbet.
20130729@Daisy(DB03.ON_USER): Add Avia.
20130805@Daisy(DB03.ON_USER): Add 9Bet.
20130814@Daisy(DB03.ON_USER): Add bet2day.
20130816@Daisy(DB03.ON_USER): Add W88.
20130923@Daisy(DB03.ON_USER): Add 3star88, 67Bet, SLC88.
20131108@Daisy(DB03.ON_USER): Add JIBC.
20131122@Daisy(DB05.ON_USER): Add livebetIDR .
20140107@Daisy(DB05.ON_USER): 1. Add K8, 88Macao, Boma365, XTD1, Ole777, Salon365, Saloncs
							  2. Remove i228bet, wplace (make mark)	 
20140206@Daisy(DB05.ON_USER): Add Wawabet, 368Cash 
20140319@Daisy(DB05.ON_USER): 1. Add 88Macao,XTD2,Mgm88,Hbobet,Winner99,Ae88,HengCai88,Happy1668,Senibet,Royalebet,UUSS
							  2. change Wawabet id
20140324@Daisy(DB05.ON_USER): Add 18bbSmart and modify IBCSmart range
20140416@Daisy(DB05.ON_USER): Add BlueOcean,Allbetclub,Royal,AG,M8Bola
20140515@Daisy(DB05.ON_USER): Add THBET,Livv88,9Club,XTD3,28bet
20140606@Daisy(DB05.ON_USER): Add LivebetKR,HONBET,Q8Bola,BE7,iBET
20140611@Daisy(DB05.ON_USER): Add IIBC
*/
SET NOCOUNT ON
Declare @nvDate smalldatetime, @psDate smalldatetime
SET @nvDate = CONVERT(char(8), @Date, 112)
SET @psDate = CONVERT(char(8), CURRENT_TIMESTAMP, 112)

INSERT INTO TotalOnline_BK
SELECT * FROM TotalOnline WHERE LogDate < DATEADD(month,-1,@psDate)
DELETE TotalOnline WHERE LogDate < DATEADD(month,-1,@psDate)

CREATE TABLE #Report (KeyID int IDENTITY(1,1), LogHour tinyint PRIMARY KEY, TimeRange nvarchar(20), LocalTimeRange nvarchar(20), 
	IBC int NOT NULL default 0, 
	INDO int NOT NULL default 0, 
	[789y] int NOT NULL default 0, 
	XYZ int NOT NULL default 0,
	king int NOT NULL default 0, --king and 933
	trojan int NOT NULL default 0,
	[611] int NOT NULL default 0, 
	[822] int NOT NULL default 0, 
	[722] int NOT NULL default 0, 
	[733] int NOT NULL default 0, 
	[755] int NOT NULL default 0,
	[12Bet] int NOT NULL default 0,
	[A88] int NOT NULL default 0, 
	[IBCWAP] int NOT NULL default 0,
	[IBCMobile] int NOT NULL default 0, 
	[IBCSmart] int NOT NULL default 0, --101103,101104,101105,101106,101109
	[18bbSmart] int NOT NULL default 0, --101107,101108,101110
	Total int NOT NULL default 0, 
	others int NOT NULL default 0,
	[Admin] int NOT NULL default 0, 
	Agent int NOT NULL default 0,
	TotalGames int NOT NULL default 0, 
	TodayGames int NOT NULL default 0,
	LiveGames int NOT NULL default 0,
	MaxTotal int NOT NULL default 0,
	[M88] int NOT NULL default 0,
	[ALog] int NOT NULL default 0,
	[KORIBC] int NOT NULL default 0,	--121000 (serverid)
	[TLC] int NOT NULL default 0,
	[spondemo] int NOT NULL default 0,	--204000 - 204101
	[Dela] int NOT NULL default 0,		--206000 - 206103
	[Sungame] int NOT NULL default 0,	--207000 - 207103
	[Mayfair] int NOT NULL default 0,	--208000 - 208103
	[Zzun88] int NOT NULL default 0,	--209000 - 209103
	[Haifa] int NOT NULL default 0,		--211001 
	[bodog] int NOT NULL default 0,		--212000 - 212103
	[Tycoon] int NOT NULL default 0,	--215001 - 215103
	[SG8] int NOT NULL default 0,		--214001 - 214103
	[Vwin] int NOT NULL default 0,      --213001 
	[Macaubet] int NOT NULL default 0,  --217001 - 217103
	[IBOBet] int NOT NULL default 0,	--216001 - 216103
    [VCBET] int NOT NULL default 0,		--218001 - 218003
    [AonCash] int NOT NULL default 0,	--219001 - 219103
	[Bwinning] int NOT NULL default 0,	--220001 - 220103
	[ITCbet] int NOT NULL default 0,	--221001 - 221103
	[LiveBet365] int NOT NULL default 0,--222001 - 222103
	[i668bet] int NOT NULL default 0,	--228001
	[i228bet] int NOT NULL default 0,	--229001
	[yq355] int NOT NULL default 0,		--225001
	[bcr999] int NOT NULL default 0,	--226001
	[lebao8888] int NOT NULL default 0,	--227001
	[wplace] int NOT NULL default 0,	--223001
	[mymbet] int NOT NULL default 0,	--258001
	[Avia] int NOT NULL default 0,		--256001
	[9Bet] int NOT NULL default 0,		--260001 - 260103
	[bet2day] int NOT NULL default 0,	--265001 - 265103
	[W88] int NOT NULL default 0,		--257001
	[3star88] int NOT NULL default 0,	--263001 - 263103
	[67Bet] int NOT NULL default 0,		--262001 - 262103
	[SLC88] int NOT NULL default 0,		--264001
	[JIBC] int NOT NULL default 0,		--133000 
	[livebetIDR] int NOT NULL default 0,--270001 - 270103
	[K8] int NOT NULL default 0,		--273001  
	[88Macao] int NOT NULL default 0,	--272001 - 272103
	[Boma365] int NOT NULL default 0,	--271001
	[XTD1] int NOT NULL default 0,		--267001
	[Ole777] int NOT NULL default 0,	--266001
	[Salon365] int NOT NULL default 0,	--276001
	[Saloncs] int NOT NULL default 0,	--277001
	[Wawabet] int NOT NULL default 0,	--278001 - 278103
	[368Cash] int NOT NULL default 0,	--283001 - 283103 
	[XTD2] int NOT NULL default 0,		--269001 - 269103
	[Mgm88] int NOT NULL default 0,		--279001 - 279103
	[Hbobet] int NOT NULL default 0,	--280001 - 280103
	[Winner99] int NOT NULL default 0,	--268001 - 268103
	[Ae88] int NOT NULL default 0,		--281001 - 281103
	[HengCai88] int NOT NULL default 0,	--282001 - 282103
	[Happy1668] int NOT NULL default 0,	--284001 - 284103
	[Senibet] int NOT NULL default 0,	--286001 - 286103
	[Royalebet] int NOT NULL default 0,	--285001 - 285103
	[UUSS] int NOT NULL default 0,		--287001 - 287103
	[BlueOcean] int NOT NULL default 0, --288001 
	[Allbetclub] int NOT NULL default 0,--289001
	[Royal] int NOT NULL default 0,		--290001
	[AG] int NOT NULL default 0,		--291001
	[M8Bola] int NOT NULL default 0,	--292001
	[THBET] int NOT NULL default 0,		--293
	[Livv88] int NOT NULL default 0,	--294    rename :KeenOcean
	[9Club] int NOT NULL default 0,		--295
	[XTD3] int NOT NULL default 0,		--296
	[28bet] int NOT NULL default 0,		--297
	[LivebetKR] int NOT NULL default 0,	--298
	[HONBET] int NOT NULL default 0,	--299
	[Q8Bola] int NOT NULL default 0,	--300
	[BE7] int NOT NULL default 0,		--301
	[iBET] int NOT NULL default 0,		--302
	[IIBC] int NOT NULL default 0		--134
	)


INSERT INTO #Report (LogHour, TimeRange, LocalTimeRange) VALUES (0, '24:00-01:00','11:00-12:00')
INSERT INTO #Report (LogHour, TimeRange, LocalTimeRange) VALUES (1, '01:00-02:00','12:00-13:00')
INSERT INTO #Report (LogHour, TimeRange, LocalTimeRange) VALUES (2, '02:00-03:00','13:00-14:00')
INSERT INTO #Report (LogHour, TimeRange, LocalTimeRange) VALUES (3, '03:00-04:00','14:00-15:00')
INSERT INTO #Report (LogHour, TimeRange, LocalTimeRange) VALUES (4, '04:00-05:00','15:00-16:00')
INSERT INTO #Report (LogHour, TimeRange, LocalTimeRange) VALUES (5, '05:00-06:00','16:00-17:00')
INSERT INTO #Report (LogHour, TimeRange, LocalTimeRange) VALUES (6, '06:00-07:00','17:00-18:00')
INSERT INTO #Report (LogHour, TimeRange, LocalTimeRange) VALUES (7, '07:00-08:00','18:00-19:00')
INSERT INTO #Report (LogHour, TimeRange, LocalTimeRange) VALUES (8, '08:00-09:00','19:00-20:00')
INSERT INTO #Report (LogHour, TimeRange, LocalTimeRange) VALUES (9, '09:00-10:00','20:00-21:00')
INSERT INTO #Report (LogHour, TimeRange, LocalTimeRange) VALUES (10, '10:00-11:00','21:00-22:00')
INSERT INTO #Report (LogHour, TimeRange, LocalTimeRange) VALUES (11, '11:00-12:00','22:00-23:00')
INSERT INTO #Report (LogHour, TimeRange, LocalTimeRange) VALUES (12, '12:00-13:00','23:00-24:00')
INSERT INTO #Report (LogHour, TimeRange, LocalTimeRange) VALUES (13, '13:00-14:00','24:00-01:00')
INSERT INTO #Report (LogHour, TimeRange, LocalTimeRange) VALUES (14, '14:00-15:00','01:00-02:00')
INSERT INTO #Report (LogHour, TimeRange, LocalTimeRange) VALUES (15, '15:00-16:00','02:00-03:00')
INSERT INTO #Report (LogHour, TimeRange, LocalTimeRange) VALUES (16, '16:00-17:00','03:00-04:00')
INSERT INTO #Report (LogHour, TimeRange, LocalTimeRange) VALUES (17, '17:00-18:00','04:00-05:00')
INSERT INTO #Report (LogHour, TimeRange, LocalTimeRange) VALUES (18, '18:00-19:00','05:00-06:00')
INSERT INTO #Report (LogHour, TimeRange, LocalTimeRange) VALUES (19, '19:00-20:00','06:00-07:00')
INSERT INTO #Report (LogHour, TimeRange, LocalTimeRange) VALUES (20, '20:00-21:00','07:00-08:00')
INSERT INTO #Report (LogHour, TimeRange, LocalTimeRange) VALUES (21, '21:00-22:00','08:00-09:00')
INSERT INTO #Report (LogHour, TimeRange, LocalTimeRange) VALUES (22, '22:00-23:00','09:00-10:00')
INSERT INTO #Report (LogHour, TimeRange, LocalTimeRange) VALUES (23, '23:00-24:00','10:00-11:00')


CREATE TABLE #TotalOnline (KeyID int IDENTITY(1,1), LogHour tinyint, LogMinute tinyint, ServerGrp int, ServerID int, Users int)
IF @nvDate >= DATEADD(month,-1,@psDate)
	INSERT INTO #TotalOnline
	SELECT CAST(RIGHT(CONVERT(nvarchar(13),LogDate, 120),2) as tinyint) LogHour, CAST(RIGHT(CONVERT(nvarchar(16),LogDate, 120),2) as tinyint) LogMinute, 
		CASE
			WHEN ServerID BETWEEN 101050 AND 101059 THEN 1011 --INDO
			WHEN ServerID = 101101 THEN 101101 --IBCWAP
			WHEN ServerID = 101102 THEN 101102 --IBCMobile
			WHEN ServerID IN (101103,101104,101105,101106,101109) THEN 101103 --IBCSmart 
			WHEN ServerID IN (101107,101108,101110) THEN 101107 --18bbSmart 
			WHEN ServerID = 100001 THEN 900	--Admin
			WHEN ServerID BETWEEN 90 AND 92 THEN 911	--Agent web
			WHEN ServerID BETWEEN 93 AND 95 THEN 912	--Agent wap
			WHEN ServerID BETWEEN 96 AND 98 THEN 913	--Agent iphone
			WHEN ServerID = 100091 THEN 991	--GameServer
			WHEN ServerID = 100092 THEN 992
			WHEN ServerID = 100093 THEN 993
			ELSE FLOOR(ServerID/1000) --EX: ServerID = 205000, ServerGrp = 205.  ServerID = 201101, ServerGrp = 201. 
		END AS ServerGrp, ServerID, Users
	FROM TotalOnline WITH (NOLOCK)
	WHERE LogDate >= @nvDate AND LogDate < DATEADD(day, 1, @nvDate)
ELSE
	INSERT INTO #TotalOnline
	SELECT CAST(RIGHT(CONVERT(nvarchar(13),LogDate, 120),2) as tinyint) LogHour, CAST(RIGHT(CONVERT(nvarchar(16),LogDate, 120),2) as tinyint) LogMinute, 
		CASE 
			WHEN ServerID BETWEEN 101050 AND 101059 THEN 1011 --INDO
			WHEN ServerID = 101101 THEN 101101 --IBCWAP
			WHEN ServerID = 101102 THEN 101102 --IBCMobile
			WHEN ServerID IN (101103,101104,101105,101106,101109) THEN 101103 --IBCSmart 
			WHEN ServerID IN (101107,101108,101110) THEN 101107 --18bbSmart 
			WHEN ServerID = 100001 THEN 900	--Admin
			WHEN ServerID BETWEEN 90 AND 92 THEN 911	--Agent web
			WHEN ServerID BETWEEN 93 AND 95 THEN 912	--Agent wap
			WHEN ServerID BETWEEN 96 AND 98 THEN 913	--Agent iphone
			WHEN ServerID = 100091 THEN 991	--GameServer
			WHEN ServerID = 100092 THEN 992
			WHEN ServerID = 100093 THEN 993
			ELSE FLOOR(ServerID/1000) --EX: ServerID = 205000, ServerGrp = 205.  ServerID = 216101, ServerGrp = 216. 
		END AS ServerGrp, ServerID, Users
	FROM TotalOnline_BK WITH (NOLOCK)
	WHERE LogDate >= @nvDate AND LogDate < DATEADD(day, 1, @nvDate )

CREATE TABLE #tmp1 (LogHour tinyint, LogMinute tinyint, ServerGrp int, Users int)
INSERT INTO #tmp1
SELECT LogHour, LogMinute, ServerGrp, SUM(Users) Users FROM #TotalOnline GROUP BY LogHour, LogMinute, ServerGrp

CREATE TABLE #tmp2 (LogHour tinyint, LogMinute tinyint, Users int, IsMax bit default 0)
INSERT INTO #tmp2 (LogHour, LogMinute, Users)
SELECT LogHour, LogMinute, SUM(Users) users FROM #tmp1 WHERE ServerGrp < 900 GROUP BY LogHour, LogMinute

UPDATE #tmp2
SET IsMax = 1
FROM (SELECT LogHour, MAX(Users) Users FROM #tmp2 GROUP BY LogHour) X
WHERE X.LogHour = #tmp2.LogHour AND X.Users = #tmp2.Users

CREATE TABLE #AvgUser (LogHour tinyint, ServerGrp int, Users int)
INSERT INTO #AvgUser
SELECT a.LogHour, a.ServerGrp, a.Users
FROM #tmp1 a INNER JOIN #tmp2 b ON a.LogHour = b.LogHour AND a.LogMinute = b.LogMinute
WHERE b.IsMax = 1

DROP TABLE #TotalOnline
DROP TABLE #tmp1
DROP TABLE #tmp2

UPDATE #Report SET	IBC	=  a.IBC,
					 [789y]	=  a.[789y],
					 XYZ	=  a.XYZ,
					 Trojan	=  a.Trojan,
					 king	=  a.king,
					 [611]	=  a.[611],
					 [822]	=  a.[822],
					 [INDO]	=  a.[INDO],
					 [722]	=  a.[722],
					 [733]	=  a.[733],
					 [755]	=  a.[755],
					 [12Bet]  = a.[12Bet], 
					 [IBCWAP] = a.[IBCWAP], 
					 [IBCMobile] =  a.[IBCMobile],
					 [IBCSmart] = a.[IBCSmart],
					 [18bbSmart] = a.[18bbSmart],	
					 [A88]	= a.[A88],
					 [M88]	= a.[M88],
					 [ALog]	= a.[ALog],
					 [KORIBC] =  a.[KORIBC],
					 [TLC]	= a.[TLC],
					 [spondemo] = a.[spondemo],
					 [Dela] = a.[Dela],
					 [Sungame]  = a.[Sungame],
					 [Mayfair]  = a.[Mayfair],
					 [Zzun88] = a.[Zzun88],
					 [Haifa] =  a.[Haifa],
					 [bodog] = a.[bodog],
					 [Tycoon] = a.[Tycoon],
					 [SG8] =  a.[SG8],
					 [Vwin] =  a.[Vwin],
					 [Macaubet] = a.[Macaubet], 
					 [IBOBet] = a.[IBOBet],
					 [VCBET] = a.[VCBET],
					 [AonCash] =  a.[AonCash],
					 [Bwinning] = a.[Bwinning],
					 [ITCbet] = a.[ITCbet],
					 [LiveBet365] = a.[LiveBet365],
					 [i668bet] = a.[i668bet],
					 [i228bet] = a.[i228bet],
					 [yq355] = a.[yq355],
					 [bcr999] =  a.[bcr999],
					 [lebao8888] = a.[lebao8888],
					 [wplace]  =  a.[wplace],
					 [mymbet]  = a.[mymbet],
					 [Avia]  = a.[Avia],
					 [9Bet]  = a.[9Bet],
					 [bet2day]  = a.[bet2day],
					 [W88] = a.[W88],
					 [3star88] = a.[3star88],
					 [67Bet] = a.[67Bet],
					 [SLC88] = a.[SLC88],
					 [JIBC] = a.[JIBC],
					 [livebetIDR] = a.[livebetIDR],
					 [K8] = a.[K8], 
					 [88Macao] =a.[88Macao], 
					 [Boma365] = a.[Boma365], 
					 [XTD1] = a.[XTD1], 
					 [Ole777] = a.[Ole777],
					 [Salon365] = a.[Salon365], 
					 [Saloncs] = a.[Saloncs],
					 [Wawabet] = a.[Wawabet], 
					 [368Cash] = a.[368Cash], 
					 [XTD2] = a.[XTD2],
					 [Mgm88] = a.[Mgm88],
					 [Hbobet] = a.[Hbobet],
					 [Winner99] = a.[Winner99],
					 [Ae88] = a.[Ae88],
					 [HengCai88] = a.[HengCai88], 
					 [Happy1668] = a.[Happy1668],
					 [Senibet] = a.[Senibet],
					 [Royalebet] = a.[Royalebet],
					 [UUSS] = a.[UUSS],
					 [BlueOcean] = a.[BlueOcean],
					 [Allbetclub] = a.[Allbetclub],
					 [Royal] = a.[Royal],
					 [AG] = a.[AG],
					 [M8Bola] = a.[M8Bola],
					 [THBET] = a.[THBET],
					 [Livv88] = a.[Livv88],    	-- rename : KeenOcean
					 [9Club] = a.[9Club],
					 [XTD3] = a.[XTD3],
					 [28bet] = a.[28bet],
					 [LivebetKR] = a.[LivebetKR],
					 [HONBET] = a.[HONBET] ,
					 [Q8Bola] = a.[Q8Bola],
					 [BE7] = a.[BE7],
					 [iBET] = a.[iBET],
					 [IIBC]= a.[IIBC]  	 		
FROM (
		select LogHour, 
		sum(case when servergrp = 101 then Users else 0 end) IBC,
		sum(case when servergrp = 104 then Users else 0 end) [789y], 
		sum(case when servergrp = 107 then Users else 0 end) XYZ, 
		sum(case when servergrp = -1 then Users else 0 end) Trojan, 
		sum(case when servergrp = 109 then Users else 0 end) king, 			--in (109,117)
		sum(case when servergrp = 115 then Users else 0 end) [611], 
		sum(case when servergrp = 116 then Users else 0 end) [822], 
		sum(case when servergrp = 1011 then Users else 0 end) [INDO], 
		sum(case when servergrp = 118 then Users else 0 end) [722], 
		sum(case when servergrp = 119 then Users else 0 end) [733], 
		sum(case when servergrp = 120 then Users else 0 end) [755], 
		sum(case when servergrp = 200 then Users else 0 end) [12Bet], 			
		sum(case when servergrp = 101101 then Users else 0 end) [IBCWAP], 
		sum(case when servergrp = 101102 then Users else 0 end) [IBCMobile], 
		sum(case when servergrp = 101103 then Users else 0 end) [IBCSmart], 
		sum(case when servergrp = 101107 then Users else 0 end) [18bbSmart], 
		sum(case when servergrp = 201 then Users else 0 end) [A88], 			
		sum(case when servergrp = 202 then Users else 0 end) [M88], 			
		sum(case when servergrp = 203 then Users else 0 end) [ALog], 			
		sum(case when servergrp = 121 then Users else 0 end) [KORIBC], 			
		sum(case when servergrp = 205 then Users else 0 end) [TLC], 			
		sum(case when servergrp = 204 then Users else 0 end) [spondemo], 			
		sum(case when servergrp = 206 then Users else 0 end) [Dela], 			
		sum(case when servergrp = 207 then Users else 0 end) [Sungame], 			
		sum(case when servergrp = 208 then Users else 0 end) [Mayfair], 			
		sum(case when servergrp = 209 then Users else 0 end) [Zzun88], 			
		sum(case when servergrp = 211 then Users else 0 end) [Haifa], 			
		sum(case when servergrp = 212 then Users else 0 end) [bodog], 			
		sum(case when servergrp = 215 then Users else 0 end) [Tycoon], 			
		sum(case when servergrp = 214 then Users else 0 end) [SG8], 			
		sum(case when servergrp = 213 then Users else 0 end) [Vwin], 			
		sum(case when servergrp = 217 then Users else 0 end) [Macaubet], 			
		sum(case when servergrp = 216 then Users else 0 end) [IBOBet], 			
		sum(case when servergrp = 218 then Users else 0 end) [VCBET], 			
		sum(case when servergrp = 219 then Users else 0 end) [AonCash], 			
		sum(case when servergrp = 220 then Users else 0 end) [Bwinning], 		  
		sum(case when servergrp = 221 then Users else 0 end) [ITCbet], 		
		sum(case when servergrp = 222 then Users else 0 end) [LiveBet365], 		
		sum(case when servergrp = 228 then Users else 0 end) [i668bet], 			
		sum(case when servergrp = 229 then Users else 0 end) [i228bet], 			
		sum(case when servergrp = 225 then Users else 0 end) [yq355], 			
		sum(case when servergrp = 226 then Users else 0 end) [bcr999], 			
		sum(case when servergrp = 227 then Users else 0 end) [lebao8888], 		
		sum(case when servergrp = 223 then Users else 0 end) [wplace], 			
		sum(case when servergrp = 258 then Users else 0 end) [mymbet], 			
		sum(case when servergrp = 256 then Users else 0 end) [Avia],
		sum(case when servergrp = 260 then Users else 0 end) [9Bet],
		sum(case when servergrp = 265 then Users else 0 end) [bet2day],
		sum(case when servergrp = 257 then Users else 0 end) [W88],
		sum(case when servergrp = 263 then Users else 0 end) [3star88],
		sum(case when servergrp = 262 then Users else 0 end) [67Bet],
		sum(case when servergrp = 264 then Users else 0 end) [SLC88],
		sum(case when servergrp = 133 then Users else 0 end) [JIBC],
		sum(case when servergrp = 270 then Users else 0 end) [livebetIDR],
		sum(case when servergrp = 273 then Users else 0 end) [K8], 
		sum(case when servergrp = 272 then Users else 0 end) [88Macao], 
		sum(case when servergrp = 271 then Users else 0 end) [Boma365], 
		sum(case when servergrp = 267 then Users else 0 end) [XTD1], 
		sum(case when servergrp = 266 then Users else 0 end) [Ole777], 
		sum(case when servergrp = 276 then Users else 0 end) [Salon365], 
		sum(case when servergrp = 277 then Users else 0 end) [Saloncs],
		sum(case when servergrp = 278 then Users else 0 end) [Wawabet], 
		sum(case when servergrp = 283 then Users else 0 end) [368Cash],
		sum(case when servergrp = 269 then Users else 0 end) [XTD2],
		sum(case when servergrp = 279 then Users else 0 end) [Mgm88],
		sum(case when servergrp = 280 then Users else 0 end) [Hbobet],
		sum(case when servergrp = 268 then Users else 0 end) [Winner99],
		sum(case when servergrp = 281 then Users else 0 end) [Ae88],
		sum(case when servergrp = 282 then Users else 0 end) [HengCai88], 
		sum(case when servergrp = 284 then Users else 0 end) [Happy1668],
		sum(case when servergrp = 286 then Users else 0 end) [Senibet],
		sum(case when servergrp = 285 then Users else 0 end) [Royalebet],
		sum(case when servergrp = 287 then Users else 0 end) [UUSS],
		sum(case when servergrp = 288 then Users else 0 end) [BlueOcean],
		sum(case when servergrp = 289 then Users else 0 end) [Allbetclub],
		sum(case when servergrp = 290 then Users else 0 end) [Royal],
		sum(case when servergrp = 291 then Users else 0 end) [AG],
		sum(case when servergrp = 292 then Users else 0 end) [M8Bola],
		sum(case when servergrp = 293 then Users else 0 end) [THBET],
		sum(case when servergrp = 294 then Users else 0 end) [Livv88],	-- rename : KeenOcean
		sum(case when servergrp = 295 then Users else 0 end) [9Club],
		sum(case when servergrp = 296 then Users else 0 end) [XTD3],
		sum(case when servergrp = 297 then Users else 0 end) [28bet],
		sum(case when servergrp = 298 then Users else 0 end) [LivebetKR],
		sum(case when servergrp = 299 then Users else 0 end) [HONBET],
		sum(case when servergrp = 300 then Users else 0 end) [Q8Bola],
		sum(case when servergrp = 301 then Users else 0 end) [BE7],
		sum(case when servergrp = 302 then Users else 0 end) [iBET],
		sum(case when servergrp = 134 then Users else 0 end) [IIBC]
		from #AvgUser 
		group by LogHour) a WHERE a.LogHour = #Report.LogHour 

UPDATE #Report SET king	= king + a.Users FROM #AvgUser a WHERE a.LogHour = #Report.LogHour AND a.ServerGrp = 117 --in (109,117)

UPDATE #Report SET others = a.Users FROM (
	SELECT LogHour, SUM(Users) Users 
	FROM #AvgUser 
	WHERE ServerGrp < 900 
	AND ServerGrp NOT IN (101,104,107,109,115,116,117,118,119,120,200,201,202,203,121,205,204,206,207,208,209,211,212,215,214,213,217,216,218,219,220,221,222,228,229,225,226,227,223,258,256,260,265,257,263,262,264,133,270,273,272,271,267,266,276,277,278,283,269,279,280,268,281,282,284,286,285,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301,302,134)
	GROUP BY LogHour
	) a WHERE a.LogHour = #Report.LogHour

UPDATE #Report SET Total = IBC + [789y] + XYZ + Trojan + king + [611]+[822]+[INDO] + [722]+[733]+[755] + [12Bet] + [IBCWAP] + [IBCMobile]+ [IBCSmart] + [18bbSmart] +
						   [A88] + [M88] + [ALog] + [KORIBC] + [TLC]+ [spondemo] + [Dela] + [Sungame] + [Mayfair] + [Zzun88] + [Haifa] + [bodog] + 
						   [Tycoon]+ [SG8]+ [Vwin] + [Macaubet] + [IBOBet] + [VCBET] + [AonCash] + [Bwinning] + [ITCbet] + [LiveBet365] + [i668bet] + [i228bet] +
						   [yq355] + [bcr999] +	[lebao8888] + [wplace] + [mymbet] + [Avia] + [9Bet] + [bet2day] + [W88] + [3star88] + [67Bet] + [SLC88] + [JIBC] + 
						   [livebetIDR] + [K8] +[88Macao] +[Boma365] +[XTD1] +[Ole777] +[Salon365] +[Saloncs] + [Wawabet] + [368Cash] + 
						   [XTD2]+[Mgm88]+[Hbobet]+[Winner99]+[Ae88]+[HengCai88]+[Happy1668]+[Senibet]+[Royalebet]+[UUSS] + 
						   [BlueOcean] +[Allbetclub] +[Royal] +[AG] +[M8Bola] + [THBET]+ [Livv88]+ [9Club]+ [XTD3]+ [28bet]+ 
						   [LivebetKR]+ [HONBET] +[Q8Bola] + [BE7] + [iBET] + [IIBC] + Others
UPDATE #Report SET [Admin] = a.Users FROM #AvgUser a WHERE a.LogHour = #Report.LogHour AND a.ServerGrp = 900
UPDATE #Report SET Agent = a.Users FROM (SELECT LogHour, SUM(Users) Users FROM #AvgUser WHERE ServerGrp IN (911,912,913) GROUP BY LogHour) a WHERE a.LogHour = #Report.LogHour
UPDATE #Report SET TotalGames = a.Users FROM #AvgUser a WHERE a.LogHour = #Report.LogHour AND a.ServerGrp = 991
UPDATE #Report SET TodayGames = a.Users FROM #AvgUser a WHERE a.LogHour = #Report.LogHour AND a.ServerGrp = 992
UPDATE #Report SET LiveGames = a.Users FROM #AvgUser a WHERE a.LogHour = #Report.LogHour AND a.ServerGrp = 993

UPDATE #Report SET MaxTotal = 1 FROM #Report
WHERE KeyID IN (SELECT KeyID FROM #Report WHERE Total IN (SELECT max(Total) FROM #Report WHERE Total <> 0))

SELECT * FROM #Report ORDER BY KeyID

DROP TABLE #AvgUser
DROP TABLE #Report

GO

GRANT EXECUTE ON [dbo].[Dot_Admin_GetTotalOnline_Report] TO [Dot_Admin] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[Dot_Admin_GetTotalOnline_Report] TO [dwrs] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[Dot_Admin_GetTotalOnline_Report] TO [vnteam] AS [dbo]
GO


