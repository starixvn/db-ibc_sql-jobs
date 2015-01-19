USE [bodb_RMS]
GO

/****** Object:  StoredProcedure [dbo].[Task_RMS_CleanOLDdataBettransParlay]    Script Date: 01/19/2015 04:32:59 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_RMS_CleanOLDdataBettransParlay]
AS
/*   
 Task : remove before movebet data for bettransParlay
 DB: DBRMS/bodb_RMS
 Revisions:   
  - 20120913@viet: create SP  
  - 20130125@Johnson: move sp from DB054.bodb02 to DBRMS.bodb_RMS 
*/  
BEGIN
	SET NOCOUNT ON 
	DECLARE @MoveBetsDay smalldatetime

	SELECT @MoveBetsDay = max(eventdate)   
	FROM bodb02.dbo.match14 WITH(NOLOCK) 

	DELETE FROM dbo.rmBettrans WITH(rowlock) WHERE Winlostdate <= @MoveBetsDay
END

GO


