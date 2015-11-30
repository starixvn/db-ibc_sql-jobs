USE [bodb_Licensee]
GO

/****** Object:  StoredProcedure [dbo].[GEN_Betting]    Script Date: 01/19/2015 03:39:45 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GEN_Betting]
    @isBA bit = null
AS
/*
    Created: 20111021@Don
    Task: 
    DB: DB052.bodb_Licensee

    Revisions:

*/ 

    declare 
        @rptDateStart datetime,
        @strDateStart varchar(10),
        @rptDateEnd datetime,
        @strDateEnd varchar(10)
    
    
    -- ****** Betting ******
    select 
        @rptDateStart = min(b.winlostdate), 
        @strDateStart = CONVERT(varchar(10),@rptDateStart,120),
        --@rptDateEnd = DATEADD(day,-1,CURRENT_TIMESTAMP),
        @rptDateEnd = max(b.winlostdate),
        @strDateEnd = CONVERT(varchar(10),@rptDateEnd,120)
    from dbo.bettrans b with(nolock)

    if (@isBA is null)
    begin
        print 'GEN_rptBetting ' + cast(@strDateStart as varchar) + ', ' + cast(@strDateEnd as varchar)
        EXECUTE dbo.GEN_rptBetting @strDateStart, @strDateEnd
        
        print 'GEN_rptBetting_BA ' + cast(@strDateStart as varchar) + ', ' + cast(@strDateEnd as varchar)
        EXECUTE dbo.GEN_rptBetting_BA @strDateStart, @strDateEnd
    end
    else if (@isBA = 1)
    begin
        print 'GEN_rptBetting_BA ' + cast(@strDateStart as varchar) + ', ' + cast(@strDateEnd as varchar)
        EXECUTE dbo.GEN_rptBetting_BA @strDateStart, @strDateEnd
    end
    else
    begin
        print 'GEN_rptBetting ' + cast(@strDateStart as varchar) + ', ' + cast(@strDateEnd as varchar)
        EXECUTE dbo.GEN_rptBetting @strDateStart, @strDateEnd
    end
    


GO

GRANT EXECUTE ON [dbo].[GEN_Betting] TO [bodbLicenseeNet] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[GEN_Betting] TO [vnteam] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[GEN_Betting] TO [vnteam] AS [dbo]
GO


