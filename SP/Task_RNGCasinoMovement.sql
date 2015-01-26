USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Task_RNGCasinoMovement]    Script Date: 01/26/2015 04:39:51 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_RNGCasinoMovement]	
AS

/*
	Created by: Victor
	Date: 20140418
	Task: daily RNG Casino movement
	DB: DBTRANS.BODB02
	Revisions:
*/

SET NOCOUNT ON

DECLARE @winlostdate DATETIME
SELECT @winlostdate = DATEADD(dd, DATEDIFF(dd, 0, CURRENT_TIMESTAMP), 0)

IF DATEPART(HOUR, CURRENT_TIMESTAMP) < 4 RETURN
		
DECLARE @pendingticket TABLE (transid BIGINT)
	
INSERT INTO @pendingticket (transid)
SELECT transid
FROM dbo.bettrans b WITH(NOLOCK)
		INNER JOIN CustDB.dbo.Dep_CustSuper s WITH(NOLOCK) ON b.srecommend = s.custid
WHERE bettype = 23002 
	AND statusID = 0 
	AND winlostdate < @winlostdate
	
IF @@ROWCOUNT = 0 RETURN
	
UPDATE b
SET winlostdate = @winlostdate
FROM dbo.bettrans b WITH(UPDLOCK, ROWLOCK)
WHERE bettype = 23002 
	AND statusID = 0
	AND transid IN (SELECT transid FROM @pendingticket)
	
-- Write log
DECLARE @Doing varchar(4000)
SET @Doing = '[Task_RNGCasinoMovement] - updating winlostdate for RNG Casino pending tickets: ' + 
STUFF((
	SELECT ',' + cast(transid as varchar(12)) 
	FROM @pendingticket 
	FOR XML PATH('')
), 1,1,'')
	
EXEC dbo.WriteLog_UserLog @UserID = 862400, @Doing = @Doing
	

GO

GRANT VIEW DEFINITION ON [dbo].[Task_RNGCasinoMovement] TO [vnteam] AS [dbo]
GO


