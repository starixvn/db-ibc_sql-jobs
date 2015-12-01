
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.GEN_rptKPIReports    Script Date: 12/1/2015 2:38:01 AM ******/
CREATE PROCEDURE [dbo].[GEN_rptKPIReports]
    @genType tinyint = 0 
    ,@isBA bit = null
AS
/*
    Created: 20110519@Don
    Task: 
    DB: DBDW2.bodb_KPI

    Revisions:
        
    Param's Explanation:
        - @genType: 1 (generate transfer), 3 (generate account)

*/ 

    declare 
        @rptDateStart datetime,
        @strDateStart varchar(10),
        @rptDateEnd datetime,
        @strDateEnd varchar(10)
        
    if (@isBA is null)
    begin
        -- ****** Transfer ******
        if (@genType in (0,1))
        begin
            select 
                --@rptDateStart = DATEADD(day,-3,CURRENT_TIMESTAMP), 
                @rptDateStart = MIN(b.winlostdate), 
                @strDateStart = CONVERT(varchar(10),@rptDateStart,120),
                --@rptDateEnd = DATEADD(day,-1,CURRENT_TIMESTAMP),
                @rptDateEnd = MAX(b.winlostdate),
                @strDateEnd = CONVERT(varchar(10),@rptDateEnd,120)
            from dbo.bettrans b (nolock)

            print 'GEN_rptKPI_Transfer ' + cast(@strDateStart as varchar) + ', ' + cast(@strDateEnd as varchar)
            EXECUTE dbo.GEN_rptKPI_Transfer @strDateStart, @strDateEnd
        end
        
        
        -- ****** Account ******
        if (@genType in (0,3))
        begin
            select 
                @rptDateStart = MIN(b.winlostdate), 
                @strDateStart = CONVERT(varchar(10),@rptDateStart,120),
                @rptDateEnd = MAX(b.winlostdate),
                @strDateEnd = CONVERT(varchar(10),@rptDateEnd,120)
            from dbo.bettrans b (nolock)
            
            print 'GEN_rptKPI_Account ' + cast(@strDateStart as varchar) + ', ' + cast(@strDateEnd as varchar)
            EXECUTE dbo.GEN_rptKPI_Account @strDateStart, @strDateEnd
            
            print 'GEN_rptKPI_Account_BA ' + cast(@strDateStart as varchar) + ', ' + cast(@strDateEnd as varchar)
            EXECUTE dbo.GEN_rptKPI_Account_BA @strDateStart, @strDateEnd
        end
    end
    else if (@isBA = 1)
    begin
        -- ****** Account ******
        if (@genType in (0,3))
        begin
            select 
                @rptDateStart = MIN(b.winlostdate), 
                @strDateStart = CONVERT(varchar(10),@rptDateStart,120),
                @rptDateEnd = MAX(b.winlostdate),
                @strDateEnd = CONVERT(varchar(10),@rptDateEnd,120)
            from dbo.bettrans b (nolock)
            
            print 'GEN_rptKPI_Account_BA ' + cast(@strDateStart as varchar) + ', ' + cast(@strDateEnd as varchar)
            EXECUTE dbo.GEN_rptKPI_Account_BA @strDateStart, @strDateEnd
        end
    end
    else
    begin
        -- ****** Transfer ******
        if (@genType in (0,1))
        begin
            select 
                --@rptDateStart = DATEADD(day,-3,CURRENT_TIMESTAMP), 
                @rptDateStart = MIN(b.winlostdate), 
                @strDateStart = CONVERT(varchar(10),@rptDateStart,120),
                --@rptDateEnd = DATEADD(day,-1,CURRENT_TIMESTAMP),
                @rptDateEnd = MAX(b.winlostdate),
                @strDateEnd = CONVERT(varchar(10),@rptDateEnd,120)
            from dbo.bettrans b (nolock)

            print 'GEN_rptKPI_Transfer ' + cast(@strDateStart as varchar) + ', ' + cast(@strDateEnd as varchar)
            EXECUTE dbo.GEN_rptKPI_Transfer @strDateStart, @strDateEnd
        end
        
        
        -- ****** Account ******
        if (@genType in (0,3))
        begin
            select 
                @rptDateStart = MIN(b.winlostdate), 
                @strDateStart = CONVERT(varchar(10),@rptDateStart,120),
                @rptDateEnd = MAX(b.winlostdate),
                @strDateEnd = CONVERT(varchar(10),@rptDateEnd,120)
            from dbo.bettrans b (nolock)
            
            print 'GEN_rptKPI_Account ' + cast(@strDateStart as varchar) + ', ' + cast(@strDateEnd as varchar)
            EXECUTE dbo.GEN_rptKPI_Account @strDateStart, @strDateEnd
        end
    end



GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT EXECUTE ON [dbo].[GEN_rptKPIReports] TO [bodbLicenseeNet]
GO 
