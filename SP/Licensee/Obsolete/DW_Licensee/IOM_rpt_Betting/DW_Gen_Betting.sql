USE [bodb_Licensee]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DW_Gen_Betting]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[DW_Gen_Betting]
GO

CREATE PROCEDURE [dbo].[DW_Gen_Betting]
AS
/*
Created: 20120712@Don
Task: 
DB: bodb_Licensee

Revisions:

*/ 

DECLARE 
    @rptDateStart datetime,
    @strDateStart varchar(10),
    @rptDateEnd datetime,
    @strDateEnd varchar(10)


-- ****** Betting ******
SELECT 
    @rptDateStart = MIN(b.winlostdate), 
    @rptDateEnd = MAX(b.winlostdate)
FROM dbo.bettrans b WITH(NOLOCK)

SELECT 
    @strDateStart = CONVERT(varchar(10),@rptDateStart,120),
    @strDateEnd = CONVERT(varchar(10),@rptDateEnd,120)

PRINT 'DW_Gen_rpt_Betting ' + CAST(@strDateStart as varchar) + ', ' + CAST(@strDateEnd as varchar)
EXECUTE dbo.DW_Gen_rpt_Betting @strDateStart, @strDateEnd



GO
GRANT VIEW DEFINITION ON [dbo].[DW_Gen_Betting] TO [VNTeam] 