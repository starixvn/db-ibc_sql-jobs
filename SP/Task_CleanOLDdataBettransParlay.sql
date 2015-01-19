USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Task_CleanOLDdataBettransParlay]    Script Date: 01/19/2015 04:19:02 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_CleanOLDdataBettransParlay]
AS
/*   
 Task : remove before movebet data for bettransParlay
 DB: DB054.bodb02  
 Revisions:   
  - 20120913@viet: create SP   
*/  
DECLARE @MoveBetsDay smalldatetime

SELECT @MoveBetsDay = max(eventdate)   
FROM match14 WITH(NOLOCK) 

DELETE FROM dbo.bettransParlay WITH(rowlock) WHERE Winlostdate <= @MoveBetsDay

GO


