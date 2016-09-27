USE [bodb_LicenseeReport]
GO
ALTER PROCEDURE [dbo].[GEN_Betting]
    @isBA bit = null
AS
/*
    Created: 20111021@Don
    Task: 
    DB: DBLIC.bodb_LicenseeReport

    Revisions:
    20160726@Francis: Move SP to bodb_LicenseeReport - [Redmine: #60449]

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