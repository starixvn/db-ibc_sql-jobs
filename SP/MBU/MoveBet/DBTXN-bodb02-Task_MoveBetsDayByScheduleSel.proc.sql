/*<info serverAlias="DBTXN-bodb02"></info>*/
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
   ,@WeekDay TINYINT  

 SET @Today = CURRENT_TIMESTAMP  
 SET @WeekDay = DATEPART(WEEKDAY, @Today)

BEGIN
	 CREATE TABLE #DefaultMovebetConfig
	 (
		_weekDay SMALLINT, 
		IsBackDay1 BIT,  
		IsBackDay2 BIT,
		IsBackDay3 BIT,
		IsBackDay4 BIT,
		IsBackDay5 BIT,
		IsBackDay6 BIT,
		IsBackDay7 BIT  
	)
	--- Get default schedule
	Insert into #DefaultMovebetConfig(_weekDay,IsBackDay1, IsBackDay2, IsBackDay3,IsBackDay4, IsBackDay5,IsBackDay6,IsBackDay7)  VALUES (1, 0, 0, 0,0,0,0,0)
	Insert into #DefaultMovebetConfig(_weekDay,IsBackDay1, IsBackDay2, IsBackDay3,IsBackDay4, IsBackDay5,IsBackDay6,IsBackDay7)  VALUES (2, 0, 0, 1,1,0,0,0)
	Insert into #DefaultMovebetConfig(_weekDay,IsBackDay1, IsBackDay2, IsBackDay3,IsBackDay4, IsBackDay5,IsBackDay6,IsBackDay7)  VALUES (3, 0, 0, 1,0,0,0,0)
	Insert into #DefaultMovebetConfig(_weekDay,IsBackDay1, IsBackDay2, IsBackDay3,IsBackDay4, IsBackDay5,IsBackDay6,IsBackDay7)  VALUES (4, 0, 0, 1,0,0,0,0)
	Insert into #DefaultMovebetConfig(_weekDay,IsBackDay1, IsBackDay2, IsBackDay3,IsBackDay4, IsBackDay5,IsBackDay6,IsBackDay7)  VALUES (5, 0, 0, 0,0,0,0,0)
	Insert into #DefaultMovebetConfig(_weekDay,IsBackDay1, IsBackDay2, IsBackDay3,IsBackDay4, IsBackDay5,IsBackDay6,IsBackDay7)  VALUES (6, 0, 0, 1,1,0,0,0)
	Insert into #DefaultMovebetConfig(_weekDay,IsBackDay1, IsBackDay2, IsBackDay3,IsBackDay4, IsBackDay5,IsBackDay6,IsBackDay7)  VALUES (7, 0, 0, 1,0,0,0,0)
	--- End 

	CREATE TABLE #MBDetail (ScheduleId INT identity, MoveBetsDay SMALLDATETIME)

	DECLARE @CurrentDate SMALLDATETIME = CONVERT(VARCHAR(10), GETDATE(), 120)

	IF EXISTS (SELECT (1) FROM  dbo.Acc_ManualMovebetConfig WITH(NOLOCK) WHERE MBDate = @CurrentDate) -- Have a manual config
	BEGIN
		---------------
		TRUNCATE TABLE #MBDetail
		INSERT INTO #MBDetail (MoveBetsDay) SELECT  DATEADD(day, -7, MBDate) FROM dbo.Acc_ManualMovebetConfig WITH(ROWLOCK) where  IsBackDay7 = 1 AND MBDate = @CurrentDate
		INSERT INTO #MBDetail (MoveBetsDay) SELECT  DATEADD(day, -6, MBDate) FROM dbo.Acc_ManualMovebetConfig WITH(ROWLOCK) where  IsBackDay6 = 1 AND MBDate = @CurrentDate
		INSERT INTO #MBDetail (MoveBetsDay) SELECT  DATEADD(day, -5, MBDate) FROM dbo.Acc_ManualMovebetConfig WITH(ROWLOCK) where  IsBackDay5 = 1 AND MBDate = @CurrentDate
		INSERT INTO #MBDetail (MoveBetsDay) SELECT  DATEADD(day, -4, MBDate) FROM dbo.Acc_ManualMovebetConfig WITH(ROWLOCK) where  IsBackDay4 = 1 AND MBDate = @CurrentDate
		INSERT INTO #MBDetail (MoveBetsDay) SELECT  DATEADD(day, -3, MBDate) FROM dbo.Acc_ManualMovebetConfig WITH(ROWLOCK) where  IsBackDay3 = 1 AND MBDate = @CurrentDate
		INSERT INTO #MBDetail (MoveBetsDay) SELECT  DATEADD(day, -2, MBDate) FROM dbo.Acc_ManualMovebetConfig WITH(ROWLOCK) where  IsBackDay2 = 1 AND MBDate = @CurrentDate
		INSERT INTO #MBDetail (MoveBetsDay) SELECT  DATEADD(day, -1, MBDate) FROM dbo.Acc_ManualMovebetConfig WITH(ROWLOCK) where  IsBackDay1 = 1 AND MBDate = @CurrentDate
	
		SELECT ScheduleId, MoveBetsDay FROM #MBDetail ORDER BY ScheduleId

	END
	ELSE
	BEGIN
		TRUNCATE TABLE #MBDetail
		INSERT INTO #MBDetail (MoveBetsDay) SELECT  DATEADD(day, -7, @CurrentDate) FROM #DefaultMovebetConfig where  IsBackDay7 = 1 AND _weekDay = @WeekDay
		INSERT INTO #MBDetail (MoveBetsDay) SELECT  DATEADD(day, -6, @CurrentDate) FROM #DefaultMovebetConfig where  IsBackDay6 = 1 AND _weekDay = @WeekDay
		INSERT INTO #MBDetail (MoveBetsDay) SELECT  DATEADD(day, -5, @CurrentDate) FROM #DefaultMovebetConfig where  IsBackDay5 = 1 AND _weekDay = @WeekDay
		INSERT INTO #MBDetail (MoveBetsDay) SELECT  DATEADD(day, -4, @CurrentDate) FROM #DefaultMovebetConfig where  IsBackDay4 = 1 AND _weekDay = @WeekDay
		INSERT INTO #MBDetail (MoveBetsDay) SELECT  DATEADD(day, -3, @CurrentDate) FROM #DefaultMovebetConfig where  IsBackDay3 = 1 AND _weekDay = @WeekDay
		INSERT INTO #MBDetail (MoveBetsDay) SELECT  DATEADD(day, -2, @CurrentDate) FROM #DefaultMovebetConfig where  IsBackDay2 = 1 AND _weekDay = @WeekDay
		INSERT INTO #MBDetail (MoveBetsDay) SELECT  DATEADD(day, -1, @CurrentDate) FROM #DefaultMovebetConfig where  IsBackDay1 = 1 AND _weekDay = @WeekDay
	
		SELECT ScheduleId, MoveBetsDay FROM #MBDetail ORDER BY ScheduleId
	END

	DROP TABLE #MBDetail
	DROP TABLE #DefaultMovebetConfig
END


      
END  
