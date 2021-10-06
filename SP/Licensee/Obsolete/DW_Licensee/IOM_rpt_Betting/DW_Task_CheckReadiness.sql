USE [bodb02]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DW_Task_CheckReadiness]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[DW_Task_CheckReadiness]
GO


CREATE PROC [dbo].[DW_Task_CheckReadiness]  
AS  
/*
Created: 20120712@Don
Task : Checking data in readiness
DB: bodb02

Revisions:
    
Param's Explanation:

*/
BEGIN
	SET NOCOUNT ON
	
	declare @n bigint  
	declare @StatusTime datetime  
	declare @Status int  
	declare @today datetime  
	  
	select @today = CONVERT(varchar(10),CURRENT_TIMESTAMP,120)  
	  
	select @n = isnull((max(case when m.eventstatus = 'running' then 1 else 0 end)),-1) --Running events among running bets 1 yes 0 no, -1 no running bets  
	from dbo.bettrans b (nolock)  
        inner join dbo.match m  (nolock) on b.matchid = m.matchid  
        left join dbo.league l (nolock) on m.leagueid = l.leagueid
	where winlostdate < @today  
	   and statusid = 0 
	   and b.bettype<19000 
	   and l.isTest = 0
	   and b.currency <> 20
	  
	if ((@n > -1) AND (datepart(hour,CURRENT_TIMESTAMP)<3))  
	begin  
        RAISERROR('Running bets present.',16,1)  
	end  
	else   
	begin  
        set @n = -1  

        declare @min smalldatetime, @max14 smalldatetime
        select @min = min(winlostdate) from dbo.bettrans (nolock) where bettype < 19000 and currency <> 20
        select @max14 = max(winlostdate) from dbo.bettrans14 (nolock) where currency <> 20
        
        if (@min <= @max14)  
        begin  
            RAISERROR('duplicate bets present.',16,1)  
        end  
	    else  
	    begin  
            select @n = -1   
            
            create table #tmpMatch(winlostdate smalldatetime, matchid int, bettype smallint, amount int)

            insert into #tmpMatch
	            select b.winlostdate,b.matchid,b.bettype,count(*)
	            from dbo.bettrans b (nolock)
		            inner join dbo.match m (nolock) on b.matchid = m.matchid
	            where b.winlostdate < @today
	            group by  b.winlostdate,b.matchid,b.bettype
            
            set @n = (select case when count(distinct winlostdate) = cast(dateadd(day,-1,@today)-min(winlostdate) as int) + 1 then 1 else 0 end DateCheck  
	                    from #tmpMatch (nolock))
    	  
            if (@n = 0)  
            begin  
                RAISERROR('bodb02 does not have data on every day! --WARNING--',16,1)  
            end  
            
            drop table #tmpMatch
        end  
    end  
	
	SET NOCOUNT OFF
END  



GO
GRANT VIEW DEFINITION ON [dbo].[DW_Task_CheckReadiness] TO [VNTeam] 