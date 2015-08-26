USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Task_DailySummary_VerifyJob]    Script Date: 08/06/2015 02:04:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_DailySummary_VerifyJob]  
AS  
/* 
	Created by: unknown  
	Task: Job daily verify data before Move bets
	DB: DBEXT.bodb02/ DBACC.bodb02  

	Revision:  
		-20150806@Sophia: Control schedule by a new store procedure

*/
BEGIN 
	SET NOCOUNT ON 
	
	/*
		Declare @WeekDay tinyint  
      SET @WeekDay = DATEPART(weekday, CURRENT_TIMESTAMP)  
        
      Declare @Todaym1 datetime, @Todaym2 datetime, @Todaym3 datetime, @Todaym4 datetime  , @Todaym5 datetime
      SET @Todaym1 = DATEADD(day, -1, CONVERT(varchar(10), CURRENT_TIMESTAMP, 120))  
      SET @Todaym2 = DATEADD(day, -1, @Todaym1)  
      SET @Todaym3 = DATEADD(day, -1, @Todaym2)  
      SET @Todaym4 = DATEADD(day, -1, @Todaym3)
      SET @Todaym5 = DATEADD(day, -1, @Todaym4)
  
  
      -- Server Time : Monday morning (2)  
      -- Local Time  : Monday's afternoon  
      IF @WeekDay = 2  
      BEGIN  
            EXEC dbo.Task_DailySummary_Verify @Todaym4 -- Thursday  
      END  
      -- Server Time : Tuesday (3)  
      -- Local Time  : Tuesday's afternoon  
      ELSE IF @WeekDay = 3  
      BEGIN  
            EXEC dbo.Task_DailySummary_Verify @Todaym4 -- Friday  
            EXEC dbo.Task_DailySummary_Verify @Todaym3 -- Saturday  
      END  
      -- Server Time : Wednesday (4)  
      -- Local Time  : Wednesday's afternoon  
      ELSE IF @WeekDay = 4  
      BEGIN  
            EXEC dbo.Task_DailySummary_Verify @Todaym3 -- Sunday  
            EXEC dbo.Task_DailySummary_Verify @Todaym2 -- Monday  
      END  
      -- Server Time : Friday (6)  
      -- Local Time  : Friday's afternoon  
      ELSE IF @WeekDay = 6  
      BEGIN  
            EXEC dbo.Task_DailySummary_Verify @Todaym3 -- Tuesday  
            EXEC dbo.Task_DailySummary_Verify @Todaym2 -- Wednesday  
            --EXEC dbo.Task_DailySummary_Verify @Todaym1 -- Thursday  
      END
      ELSE  
      BEGIN  
            RETURN -1  
      END  
     */

	 
	
	DECLARE @Days AS TABLE (ScheduleId TINYINT, RunningDay DATETIME, IsFinish BIT DEFAULT (0))
	INSERT INTO @Days (ScheduleId, RunningDay)
	EXEC DBTXN.bodb02.dbo.Task_MoveBetsDayByScheduleSel 

	DECLARE @RunningDay DATETIME , @ScheduleId TINYINT
	
	IF NOT EXISTS (SELECT TOP 1 1 FROM @Days)
	BEGIN 
		RETURN -1
	END 
	ELSE
	BEGIN 
		WHILE 1 = 1 
		BEGIN 
			IF EXISTS (SELECT TOP 1 1 FROM @Days WHERE IsFinish = 0)
			BEGIN 
				SELECT  TOP 1 @RunningDay = RunningDay, @ScheduleId = ScheduleId
				FROM	@Days
				WHERE	IsFinish = 0
				ORDER BY ScheduleId 

				EXEC dbo.Task_DailySummary_Verify @RunningDay 
		
				UPDATE  @Days
				SET		IsFinish = 1
				WHERE	ScheduleId = @ScheduleId
						
			END
			ELSE 
				BREAK
		END	
	END



END
  

GO
GRANT EXECUTE ON [dbo].[Task_DailySummary_VerifyJob] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Task_DailySummary_VerifyJob] TO [vnteam] AS [dbo]