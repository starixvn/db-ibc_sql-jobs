USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Lrf_SelBalanceUpDay]    Script Date: 01/20/2015 01:48:18 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/****** Object:  Stored Procedure dbo.Lrf_SelBalanceUpDay    Script Date: 4/8/2013 10:42:23 PM ******/

/****** Object:  Stored Procedure dbo.Lrf_SelBalanceUpDay    Script Date: 5/4/2012 4:00:10 PM ******/
CREATE PROCEDURE  [dbo].[Lrf_SelBalanceUpDay]        
        
AS    
/*
Created: 20101210@Henry
Task : Get move bet day, balanceup day
DB: DB052.bodb02
Original: [Age_SelBalanceUpDay]

Revisions:
    20120504@Henry: temporary remove custid = 3
Param's Explanation:
*/

SET NOCOUNT ON
BEGIN
    DECLARE @BalanceUpDay smalldatetime, @MoveBetsDay smalldatetime
    SELECT 
        TOP 1 @BalanceUpDay = winlostdate
    FROM Bettrans WITH(NOLOCK)
    WHERE bettype = 20000 AND matchid = 0    
            AND custid = 3
    
    SELECT    
        @MoveBetsDay = MAX(eventdate)  
    FROM match14 WITH(NOLOCK)  

    SELECT @BalanceUpDay as BalanceUpDay, @MoveBetsDay as MoveBetsDay
END


GO

GRANT EXECUTE ON [dbo].[Lrf_SelBalanceUpDay] TO [bodbAdminNet] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[Lrf_SelBalanceUpDay] TO [bodbLicenseeNet] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[Lrf_SelBalanceUpDay] TO [vnteam] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[Lrf_SelBalanceUpDay] TO [vnteam] AS [dbo]
GO


