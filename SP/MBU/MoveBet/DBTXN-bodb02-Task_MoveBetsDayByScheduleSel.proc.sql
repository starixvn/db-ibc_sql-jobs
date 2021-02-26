/*<info serverAlias="DBTRANS-bodb02"></info>*/
USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Task_MoveBetsDayByScheduleSel]    Script Date: 11/16/2020 10:26:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
ALTER PROCEDURE [dbo].[Task_MoveBetsDayByScheduleSel]  
AS    
  
/*    
 Creator:20150807@Sophia  
 Task: Get Move bets day by Schedule   
 DB: DBTXN/bodb02  
    
 Revisions:     
  20150925@Harris: skip move bet for Balance Issue  
  20160129@Harris: Skip move bet for One RNG settle issue  
  20160201@Harris: Skip move bet for 27Jan again  
  20160517@Harris: #57686 change move bet for 13May to 20160518 morning(gmt+7)    
  20160614@Harris: #59313 change move bet in period 15-19Jun    
  20160615@Harris: #59317 Modify for EC schedule  
  20160815@Harris: #62474 Modify for Aug 10 / Hold move bet as CSD requested  
  20160831@Harris: #63383 Modify for Aug 28 / Hold move bet as CSD requested for matchid = 19603626
  20180617@Harris: #97040  Modify for WC2018
  20180626@Harris: #97040  Modify for WC2018 v3
  20180709@Harris: #97040  Modify for WC2018 v4
  20200330@Gary: #131466  Skip move bet on 20200330 (Tuesday morning)
  20200624@Gary: #136338  Move bet 2 days on 20200624 (Thursday morning)
  20201116@Gary: #145497  Move bet 1 days on 20201116 (Tuesday morning)
  20210205@Danny: Change logic get MB date [Redmine: #150053]
 
*/  

BEGIN   
 SET NOCOUNT ON    
    

 DECLARE @Today DATETIME  
   ,@Todaym1 DATETIME  
   ,@Todaym2 DATETIME  
   ,@Todaym3 DATETIME  
   ,@Todaym4 DATETIME  
   ,@WeekDay TINYINT  
 --IF ISNULL(@today,'') = ''  
 SET @Today = CURRENT_TIMESTAMP  

   
 --select  cast (@today as DATE)  
 SET @WeekDay = DATEPART(WEEKDAY, @Today)

  
 SET @Todaym1 = DATEADD(day, - 1, CONVERT(VARCHAR(10), @Today, 120))  
 SET @Todaym2 = DATEADD(day, - 1, @Todaym1)  
 SET @Todaym3 = DATEADD(day, - 1, @Todaym2)  
 SET @Todaym4 = DATEADD(day, - 1, @Todaym3)  
   
  
 DECLARE @Schedule AS TABLE (ScheduleId TINYINT, WeekDay TINYINT, RunningDay DATETIME, ManualDay DATETIME, IsManual BIT)  
 INSERT INTO @Schedule (ScheduleId, WeekDay, RunningDay, ManualDay, IsManual)    
 VALUES   (1, 2, @Todaym4, NULL , 0 ) --- Thursday  
   , (2, 2, @Todaym3, NULL , 0 ) --- Friday   
   , (3, 3, @Todaym3, NULL , 0 ) --- Saturday  
   , (4, 4, @Todaym3, NULL , 0 ) --- Sunday  
   , (5, 6, @Todaym4, NULL , 0 ) --- Monday  
   , (6, 6, @Todaym3, NULL , 0 ) --- Tuesday  
   , (7, 7, @Todaym3, NULL , 0 ) --- Wednesday  
   

 --- Update schedule manually  
 -- 20160614@Harris: #59313 change move bet in period 15-19Jun    
 --  20160815@Harris: #62474 Modify for Aug 10 / Hold move bet as CSD requested  
 -- 20180617@Harris: #97040  Modify for WC2018
 -- 20180626@Harris: #97040  Modify for WC2018 v3

/*
 IF CAST (@today as DATE) = '20180626' -- Wednesday morning // weekday = 3  
 BEGIN  
  UPDATE @Schedule
  SET WeekDay = 3, ManualDay = '20180624', IsManual = 1
  WHERE ScheduleId = 2
 END  
*/

      
 -- 20160615@Harris: #59317 Modify for EC schedule  
 -- 20160815@Harris: Comment below code for later big events  
  -- 20180617@Harris: #97040  Modify for WC2018
  -- 20180626@Harris: #97040  Modify for WC2018 v3
  -- 20180709@Harris: #97040  Modify for WC2018 v4

IF CAST(@today as date) between '20180709' and '20180718'-- one week after EC  
  BEGIN  
   DELETE @Schedule  
     
   INSERT INTO @Schedule (ScheduleId, WeekDay, RunningDay, ManualDay, IsManual)    
   VALUES   (1, 1, @Todaym2, NULL , 0 ) --- Friday  
     , (2, 2, @Todaym2, NULL , 0 ) --- Saturday   
     , (3, 3, @Todaym2, NULL , 0 ) --- Sunday  
     , (4, 4, @Todaym2, NULL , 0 ) --- Monday  
     , (5, 6, @Todaym3, NULL , 0 ) --- Tuesday  
     , (6, 6, @Todaym2, NULL , 0 ) --- Wednesday  
     , (7, 7, @Todaym2, NULL , 0 ) --- Thursday  
        
  END  

 
  IF CAST (@today as DATE) = '20200330' -- Tuesday morning // weekday = 2  -- skip move bet 
 BEGIN  
  UPDATE @Schedule
  SET WeekDay = 0
  WHERE ScheduleId in (1,2)
 END  
 
 IF CAST (@today as DATE) = '20200331' -- Wednesday morning // weekday = 3  -- Move bet Thu, Fri (26,27)
 BEGIN  
  UPDATE @Schedule
  SET WeekDay = 3, ManualDay = '20200326', IsManual = 1
  WHERE ScheduleId = 1

  UPDATE @Schedule
  SET WeekDay = 3, ManualDay = '20200327', IsManual = 1
  WHERE ScheduleId = 2

  UPDATE @Schedule
  SET WeekDay = 0
  WHERE ScheduleId = 3
 END   

 
 IF CAST (@today as DATE) = '20200401' -- Thursday morning // weekday = 4  -- Move bet Sat, Sun (28, 29)
 BEGIN  
  UPDATE @Schedule
  SET WeekDay = 4, ManualDay = '20200328', IsManual = 1
  WHERE ScheduleId = 3
 END   

 IF CAST (@today as DATE) = '20200624' -- Thursday morning // weekday = 4  -- Move bet Sat, Sun (20Jun, 21Jun)
 BEGIN  
  UPDATE @Schedule
  SET WeekDay = 4, ManualDay = '20200620', IsManual = 1
  WHERE ScheduleId = 3
 END  

  IF CAST (@today as DATE) = '20201116' -- Tuesday morning // weekday = 2  -- Move bet Thu (12Nov)
 BEGIN  
   delete @Schedule where WeekDay=2 and RunningDay='2020-11-13 00:00:00.000'
 END  

  IF CAST (@today as DATE) = '20201117' -- Wednesday morning // weekday = 3  -- Move bet Fri, Sat (13Nov, 14Nov)
 BEGIN  
  UPDATE @Schedule
  SET WeekDay = 3, ManualDay = '20201113', IsManual = 1
  WHERE ScheduleId = 2
 END  

 

 --SELECT ScheduleId, CASE WHEN IsManual = 0 THEN RunningDay ELSE ManualDay END AS MoveBetsDay  
 --FROM @Schedule   
 --WHERE WeekDay = @WeekDay  
 --ORDER BY ScheduleId  

 
BEGIN
	 CREATE TABLE #DefaultMovebetConfig
	 (
		_weekDay SmallInt, 
		Isbackday1 BIT,  
		Isbackday2 BIT,
		Isbackday3 BIT,
		Isbackday4 BIT,
		Isbackday5 BIT,
		Isbackday6 BIT,
		Isbackday7 BIT,   
	)
	INSERT INTO #DefaultMovebetConfig (_weekDay,Isbackday1,Isbackday2,Isbackday3,Isbackday4,Isbackday5,Isbackday6,Isbackday7 )
	EXEC dbo.Acc_Manual_MoveBet_Sel @IsDefault = 1

	CREATE TABLE #MBDetail (ScheduleId INT identity, MoveBetsDay SMALLDATETIME)


	IF EXISTS (SELECT (1) FROM  dbo.Acc_ManualMovebetConfig WITH(NOLOCK) WHERE MBDate = @Today) -- Have a manual config
	BEGIN
		---------------
		TRUNCATE TABLE #MBDetail
		INSERT INTO #MBDetail (MoveBetsDay) SELECT  DATEADD(day, -7, MBDate) FROM dbo.Acc_ManualMovebetConfig WITH(ROWLOCK) where  Isbackday7 = 1 AND MBDate = @Today
		INSERT INTO #MBDetail (MoveBetsDay) SELECT  DATEADD(day, -6, MBDate) FROM dbo.Acc_ManualMovebetConfig WITH(ROWLOCK) where  Isbackday6 = 1 AND MBDate = @Today
		INSERT INTO #MBDetail (MoveBetsDay) SELECT  DATEADD(day, -5, MBDate) FROM dbo.Acc_ManualMovebetConfig WITH(ROWLOCK) where  Isbackday5 = 1 AND MBDate = @Today
		INSERT INTO #MBDetail (MoveBetsDay) SELECT  DATEADD(day, -4, MBDate) FROM dbo.Acc_ManualMovebetConfig WITH(ROWLOCK) where  Isbackday4 = 1 AND MBDate = @Today
		INSERT INTO #MBDetail (MoveBetsDay) SELECT  DATEADD(day, -3, MBDate) FROM dbo.Acc_ManualMovebetConfig WITH(ROWLOCK) where  Isbackday3 = 1 AND MBDate = @Today
		INSERT INTO #MBDetail (MoveBetsDay) SELECT  DATEADD(day, -2, MBDate) FROM dbo.Acc_ManualMovebetConfig WITH(ROWLOCK) where  Isbackday2 = 1 AND MBDate = @Today
		INSERT INTO #MBDetail (MoveBetsDay) SELECT  DATEADD(day, -1, MBDate) FROM dbo.Acc_ManualMovebetConfig WITH(ROWLOCK) where  Isbackday1 = 1 AND MBDate = @Today
	
		SELECT ScheduleId, MoveBetsDay FROM #MBDetail ORDER BY ScheduleId

	END
	ELSE
	BEGIN
		TRUNCATE TABLE #MBDetail
		INSERT INTO #MBDetail (MoveBetsDay) SELECT  DATEADD(day, -7, @Today) FROM #DefaultMovebetConfig where  Isbackday7 = 1 AND _weekDay = @WeekDay
		INSERT INTO #MBDetail (MoveBetsDay) SELECT  DATEADD(day, -6, @Today) FROM #DefaultMovebetConfig where  Isbackday6 = 1 AND _weekDay = @WeekDay
		INSERT INTO #MBDetail (MoveBetsDay) SELECT  DATEADD(day, -5, @Today) FROM #DefaultMovebetConfig where  Isbackday5 = 1 AND _weekDay = @WeekDay
		INSERT INTO #MBDetail (MoveBetsDay) SELECT  DATEADD(day, -4, @Today) FROM #DefaultMovebetConfig where  Isbackday4 = 1 AND _weekDay = @WeekDay
		INSERT INTO #MBDetail (MoveBetsDay) SELECT  DATEADD(day, -3, @Today) FROM #DefaultMovebetConfig where  Isbackday3 = 1 AND _weekDay = @WeekDay
		INSERT INTO #MBDetail (MoveBetsDay) SELECT  DATEADD(day, -2, @Today) FROM #DefaultMovebetConfig where  Isbackday2 = 1 AND _weekDay = @WeekDay
		INSERT INTO #MBDetail (MoveBetsDay) SELECT  DATEADD(day, -1, @Today) FROM #DefaultMovebetConfig where  Isbackday1 = 1 AND _weekDay = @WeekDay
	
		SELECT ScheduleId, MoveBetsDay FROM #MBDetail ORDER BY ScheduleId
	END

	DROP TABLE #MBDetail
	DROP TABLE #DefaultMovebetConfig
END


      
END  
