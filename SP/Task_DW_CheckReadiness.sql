USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Task_DW_CheckReadiness]    Script Date: 01/19/2015 03:30:32 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.Task_DW_CheckReadiness    Script Date: 5/28/2014 2:35:00 AM ******/
/****** Object:  Stored Procedure dbo.Task_DW_CheckReadiness    Script Date: 12/27/2011 1:18:35 PM ******/


CREATE PROCEDURE [dbo].[Task_DW_CheckReadiness]  
AS  
/*
Created: ?
Task : Generate data for Customer Account
DB: DB052.bodb_licensee

Revisions:
    20111129@Don: Enhance performance
        - New way to check 'Running bets present.'
        - New way to check 'duplicate bets present.'
        - No check of missing match/outright
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
	--if (1=2)  
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
    	  
            --if (@n = 0)  
            if (1=2)  
            begin  
                RAISERROR('bodb02 does not have data on every day! --WARNING--',16,1)  
            end  
            
            drop table #tmpMatch

            /*if exists(select 1 
                        from dbo.bettrans b (nolock)  
		                    left join dbo.match m (nolock) on b.matchid = m.matchid  
	                    where winlostdate < @today  
		                    and [statusid] not in (0,101,102) 
		                    and b.bettype<31 and b.bettype not in (9,10,29) 
		                    and b.currency <> 20
		                    and m.matchid is null  
	        )  
	        begin  
		        RAISERROR('bodb02 is missing match --WARNING--',16,1)  
	        end  
    	  
            if exists(select 1 
                        from dbo.bettrans b (nolock)  
		                    left join dbo.outright o (nolock) on b.matchid = o.orid  
	                    where winlostdate < @today  
		                    and [statusid] not in (0,101,102) 
		                    and b.bettype in (10,31,32,33) 
		                    and b.currency <> 20
		                    and o.orid is null   
	        )  
	        begin  
		        RAISERROR('bodb02 is missing outright --WARNING--',16,1)  
	        end  */
        end  
    end  
	
	SET NOCOUNT OFF
END
GO

GRANT EXECUTE ON [dbo].[Task_DW_CheckReadiness] TO [vnteam] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[Task_DW_CheckReadiness] TO [vnteam] AS [dbo]
GO


