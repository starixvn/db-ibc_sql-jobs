USE [Affiliate_12BET]
GO

/****** Object:  StoredProcedure [dbo].[Task_Aff_ClearLogin_Loop]    Script Date: 01/19/2015 23:24:22 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.Task_Aff_ClearLogin_Loop    Script Date: 6/14/2011 10:18:14 AM ******/
CREATE PROCEDURE [dbo].[Task_Aff_ClearLogin_Loop]  
AS  
/*
	Created:  20110221@Jamie
	Task: Clear Login
	DB: DB052.Affiliate_12BET
	Original SP:
	
	Revisions:
		
*/
SET NOCOUNT ON
 Declare @start datetime  
 SELECT @start = CURRENT_TIMESTAMP  
  
 WHILE (1=1) AND (DATEDIFF(minute,@start, CURRENT_TIMESTAMP) < 20)  
 BEGIN  
    EXEC Task_Aff_ClearLogin  
  WAITFOR DELAY '00:00:30'  
 END
GO

GRANT VIEW DEFINITION ON [dbo].[Task_Aff_ClearLogin_Loop] TO [vnAffiliate] AS [dbo]
GO


