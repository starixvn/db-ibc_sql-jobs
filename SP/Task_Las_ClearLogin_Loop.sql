USE [LASDB]
GO

/****** Object:  StoredProcedure [dbo].[Task_Las_ClearLogin_Loop]    Script Date: 01/20/2015 00:14:52 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/****** Object:  Stored Procedure dbo.Lrf_CheckIn    Script Date: 6/15/2011 3:52:40 PM ******/
CREATE PROCEDURE [dbo].[Task_Las_ClearLogin_Loop]   
AS  
/*
	Created:  20131324
	Task: Clear Login
	DB: DBLAS.LASDB
	Original SP:
	
	Revisions:
		
*/
SET NOCOUNT ON
 Declare @start datetime  
 SELECT @start = CURRENT_TIMESTAMP  
  
 WHILE (1=1) AND (DATEDIFF(minute,@start, CURRENT_TIMESTAMP) < 20)  
 BEGIN  
  EXEC Task_Las_ClearLogin  
  WAITFOR DELAY '00:00:30'  
 END


GO


