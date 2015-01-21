USE [serviceBrokerDB]
GO

/****** Object:  StoredProcedure [sb].[SBDeleteTempData]    Script Date: 01/21/2015 00:11:31 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [sb].[SBDeleteTempData]  	
AS
/*  Created: Viet @ 20140210
	Task : delete temp data
	DB: bodb02 @ DB052/DB053/DB054/DB06
	Revisions:  
			
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @yesterday datetime, @twoHoursAgo datetime	
	SET @yesterday = DATEADD(dd, DATEDIFF(d, 0, CURRENT_TIMESTAMP)-1, 0)
	SET @twoHoursAgo = DATEADD(hh, -2, CURRENT_TIMESTAMP)	
	
	DELETE sb.logs WHERE creationTime < @twoHoursAgo
	DELETE bodb02.dbo.bettransDEP WHERE winlostdate < @yesterday			
END

GO


