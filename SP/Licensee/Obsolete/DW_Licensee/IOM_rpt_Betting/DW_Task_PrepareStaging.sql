USE [bodb_Licensee]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DW_Task_PrepareStaging]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[DW_Task_PrepareStaging]
GO

CREATE PROC [dbo].[DW_Task_PrepareStaging]  
    @datefrom smalldatetime=null
    ,@dateto smalldatetime=null
WITH RECOMPILE
AS  
/*
Created: 20120712@Don
Task: 
DB: bodb_Licensee

Revisions:
    
Param's Explanation:

*/
BEGIN
	
	DECLARE @today datetime, @thedaybefore datetime
	SELECT @today=@dateto, @thedaybefore=@datefrom
	
    IF (NOT (@today IS NULL OR @thedaybefore IS NULL))
        SELECT @today=CONVERT(varchar(10),DATEADD(day,1,@today),120), @thedaybefore=CONVERT(varchar(10),@thedaybefore,120)
    ELSE
        SELECT @today=CONVERT(varchar(10),current_timestamp,120), @thedaybefore=DATEADD(day,-3,@today)
    
	---------PROCESS OUTRIGHT DATA--------------------------------------------------------------------------------------------  
	TRUNCATE TABLE dbo.outright  
	
    INSERT INTO dbo.outright(matchid, leagueid)
	    SELECT orid AS matchid, leagueid
        FROM bodb02.dbo.outright (NOLOCK)
        WHERE eventdate>=@thedaybefore AND eventdate<@today

	---------PROCESS MATCH DATA--------------------------------------------------------------------------------------------  
	TRUNCATE TABLE dbo.match  
	
    INSERT INTO dbo.match(matchid, leagueid)
	    SELECT matchid, leagueid
        FROM bodb02.dbo.match (NOLOCK)
        WHERE eventdate>=@thedaybefore AND eventdate<@today
	  
	---------PROCESS BETTRANS DATA--------------------------------------------------------------------------------------------  
	TRUNCATE TABLE dbo.[bettrans]  
	
	DECLARE @Recommend_List TABLE (t_recommend int PRIMARY KEY)
    CREATE TABLE #Customer (t_custid int PRIMARY KEY)
    
    DECLARE @count int,@movebetdate smalldatetime,@tmpDate smalldatetime
	SELECT @count=DATEDIFF(DAY,@thedaybefore,@today) - 1
	
    INSERT INTO @Recommend_List
        SELECT custid FROM bodb02.dbo.Customer (NOLOCK) WHERE roleid = 2

	WHILE (@count>=0)
	BEGIN
		SELECT @tmpDate=DATEADD(DAY,@count,@thedaybefore)
		
		--Copy LIVE data (bettrans) 
		INSERT INTO dbo.bettrans
		    ([transid]
            ,winlostdate
            ,liveindicator
            ,bettype
            ,[custid]
            ,[stake]
            ,actual_stake
            ,[winlost],[awinlost],[mwinlost],swinlost
            ,acomm,scomm,playercomm,comm
            ,matchid
            ,[srecommend]
            ,currency
            ,recommend,mrecommend
            ,statusid
            ,tpositiontaking)
		SELECT 
		    b.transid,
            b.winlostdate,
            b.liveindicator,
            b.bettype,
            b.custid,
            ABS(b.stake) stake,
            b.actual_stake,
            b.winlost,b.awinlost,b.mwinlost,b.swinlost,
            b.acomm, b.scomm, b.playercomm, b.comm,
            b.matchid,
            b.srecommend, 
            b.currency, 
            b.recommend,b.mrecommend,
            CASE 
                WHEN (b.bettype IN (1, 3, 7, 8, 17, 18, 124, 125) AND ABS(b.modds) = 0.25 AND [statusid] = 112) THEN 114
                WHEN (b.bettype IN (1, 3, 7, 8, 17, 18, 124, 125) AND ABS(b.modds) = 0.25 AND [statusid] = 113) THEN 115
                WHEN (b.bettype = 33 AND [statusid] <> 103 AND b.liveawayscore = 0 AND [statusid] = 112) THEN 114
                WHEN (b.bettype = 33 AND [statusid] <> 103 AND b.liveawayscore = 0 AND [statusid] = 113) THEN 115
                ELSE b.statusid
            END AS [statusid],
            b.tpositiontaking
		FROM bodb02.dbo.bettrans b (NOLOCK)
		    INNER JOIN @Recommend_List r ON b.recommend=r.t_recommend
		WHERE b.bettype<19000
            AND b.winlostdate=@tmpDate
            AND b.custid>0
            
        DELETE dbo.bettrans WHERE winlostdate=@tmpDate AND statusid IN (0,101,102,121) -- 'void', 'reject', 'running','done'

		SELECT @count = @count - 1
	END
	  
END



GO
GRANT VIEW DEFINITION ON [dbo].[DW_Task_PrepareStaging] TO [VNTeam]  